use std::path::{Component, Path, PathBuf};

#[cfg(target_os = "ios")]
pub(crate) fn restore(path: &str) -> String {
    std::env::home_dir()
        .and_then(|home| relocated(path, &home))
        .map(|path| path.to_string_lossy().into_owned())
        .unwrap_or_else(|| path.to_owned())
}

fn relocated(path: &str, home: &Path) -> Option<PathBuf> {
    let path = Path::new(path);
    if !path.is_absolute() || path.exists() {
        return None;
    }
    let components: Vec<_> = path.components().collect();
    if components
        .iter()
        .any(|part| matches!(part, Component::ParentDir))
    {
        return None;
    }
    let start = components.windows(4).position(|parts| {
        parts[0].as_os_str() == "Containers"
            && parts[1].as_os_str() == "Data"
            && parts[2].as_os_str() == "Application"
            && parts[3].as_os_str().to_str().is_some_and(valid_identifier)
    })? + 4;
    if components.get(start)?.as_os_str() != "Documents" {
        return None;
    }
    let mut candidate = home.to_path_buf();
    for part in &components[start..] {
        candidate.push(part.as_os_str());
    }
    let documents = home.join("Documents").canonicalize().ok()?;
    let resolved = candidate.canonicalize().ok()?;
    resolved.starts_with(documents).then_some(candidate)
}

fn valid_identifier(value: &str) -> bool {
    value.len() == 36
        && value.bytes().enumerate().all(|(index, byte)| {
            if [8, 13, 18, 23].contains(&index) {
                byte == b'-'
            } else {
                byte.is_ascii_hexdigit()
            }
        })
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::atomic::{AtomicUsize, Ordering};

    struct Fixture(PathBuf);

    impl Fixture {
        fn new() -> Self {
            static NEXT: AtomicUsize = AtomicUsize::new(0);
            let root = std::env::temp_dir().join(format!(
                "cutcap-sandbox-{}-{}",
                std::process::id(),
                NEXT.fetch_add(1, Ordering::Relaxed)
            ));
            std::fs::create_dir(&root).unwrap();
            std::fs::create_dir_all(root.join("Documents/Imported")).unwrap();
            std::fs::write(root.join("Documents/Imported/clip.mov"), b"source").unwrap();
            Self(root)
        }
    }

    impl Drop for Fixture {
        fn drop(&mut self) {
            std::fs::remove_dir_all(&self.0).unwrap();
        }
    }

    const OLD: &str =
        "/var/mobile/Containers/Data/Application/11111111-2222-3333-4444-555555555555";

    #[test]
    fn restores_device_media_and_project_folders() {
        let fixture = Fixture::new();
        let recovered =
            relocated(&format!("{OLD}/Documents/Imported/clip.mov"), &fixture.0).unwrap();
        assert_eq!(std::fs::read(recovered).unwrap(), b"source");
        assert_eq!(
            relocated(&format!("{OLD}/Documents/Imported"), &fixture.0),
            Some(fixture.0.join("Documents/Imported"))
        );
    }

    #[test]
    fn restores_simulator_paths() {
        let fixture = Fixture::new();
        let old = "/Users/test/Library/Developer/CoreSimulator/Devices/device/data/Containers/Data/Application/11111111-2222-3333-4444-555555555555/Documents/Imported/clip.mov";
        assert_eq!(
            relocated(old, &fixture.0),
            Some(fixture.0.join("Documents/Imported/clip.mov"))
        );
    }

    #[test]
    fn leaves_existing_and_missing_files_unchanged() {
        let fixture = Fixture::new();
        assert!(
            relocated(
                fixture
                    .0
                    .join("Documents/Imported/clip.mov")
                    .to_str()
                    .unwrap(),
                &fixture.0
            )
            .is_none()
        );
        assert!(relocated(&format!("{OLD}/Documents/Imported/missing.mov"), &fixture.0).is_none());
    }

    #[test]
    fn rejects_other_roots_and_traversal() {
        let fixture = Fixture::new();
        for path in [
            format!("{OLD}/Documents/Imported/../Imported/clip.mov"),
            format!("{OLD}/Library/Imported/clip.mov"),
            "/elsewhere/Documents/Imported/clip.mov".into(),
            "Documents/Imported/clip.mov".into(),
            OLD.replace("11111111-2222-3333-4444-555555555555", "invalid")
                + "/Documents/Imported/clip.mov",
        ] {
            assert!(
                relocated(&path, &fixture.0).is_none(),
                "unexpected relocation"
            );
        }
    }

    #[cfg(unix)]
    #[test]
    fn rejects_symlinks_outside_documents() {
        let fixture = Fixture::new();
        std::fs::write(fixture.0.join("outside.mov"), b"outside").unwrap();
        std::os::unix::fs::symlink(
            fixture.0.join("outside.mov"),
            fixture.0.join("Documents/Imported/link.mov"),
        )
        .unwrap();
        assert!(relocated(&format!("{OLD}/Documents/Imported/link.mov"), &fixture.0).is_none());
    }
}
