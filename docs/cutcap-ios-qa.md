# iPhone quick-edit verification — 2026-10-20

Scope: modified Concat fork on branch `cutcap/ios-quick-edit`, baseline `79116bd0f9a103c633d888603ad27890e929dbdc`. Simulator only, iPhone 17 Pro / iOS 26.5. Synthetic media only.

## Checks

- Rust 1.93.1 build/type checking: development Simulator binary, engine optimized, UI opt-level 0 / 256 codegen units. Existing upstream warnings: three missing-doc fields in `platform.rs`, one unused-mut build warning in patched whisper-rs-sys.
- Domain tests: 284 passed, zero failed (core 60, effects 72, project 150, doctests 2). Those domain crates were not modified by this change. Coverage was not collected.
- Rust formatting, shell syntax, locale key inventory and Git whitespace checks passed. Locale inventory reports 799 existing/fallback lines identical to English; four new keys have English fallback outside English/Vietnamese.
- Changed-source secret-pattern scan found no matching credentials. New activity entries log counts only. Imported media is adopted from system-provided temporary copies into the app sandbox; same-name adoption is serialized. This is a scoped review, not a full upstream security audit.
- Photos source-choice cancellation and Photos picker cancellation left zero projects and zero imported files on the clean QA device.
- Ordered Photos selection of two same-name 2-second movies retained two distinct sandbox files and created a 360×640, 30 fps, 4-second sequence, blue then red.
- Split through the actual phone toolbar created three clips and saved their source ranges in draft JSON.
- Export through the actual phone export panel completed; add-to-Photos permission was accepted and publishing returned success. The resulting H.264 MP4 was decoded with AVFoundation: 4 seconds, 360×640, 30 fps; blue frame at 0.5 seconds and red frame at 2.5 seconds.

## Timeline regression

The initial quick-edit implementation inserted on T1, while phone tracks render in reverse order. The occupied track was below the viewport. A screenshot pixel check of the lane viewport failed with blue=0/red=0. Scrolling vertically revealed the clips and passed with blue=34530/red=21774, isolating the viewport problem from import/decoding. Quick edit now inserts onto the last stored track, which is the first displayed track.

Reproduction: on a clean home screen choose Edit video → Photos, select a blue and a red 2-second video in that order, choose Done. Both clips must be visible immediately without vertical scrolling. Select a clip, place the ruler playhead within it and choose Split. Export and inspect decoded frames, then close and reopen the draft.

## Limits

Physical-device signing, a fully optimized distribution build, App Store packaging, HDR/VFR/4K/long-video stress, audio/voiceover, AI models and the complete feature inventory are not verified. The original independent FrameCut app is unchanged; its Xcode tests are not evidence for this fork. No IPA or store release was published.

## Retained QA tools

These macOS tools inspect synthetic QA artifacts; they do not modify images or videos. The screenshot check is specific to the portrait phone editor layout and blue/red test clips. The export check expects a 4-second, 360×640, 30 fps sequence with blue before red.

```sh
swift scripts/qa/check-cutcap-timeline.swift /tmp/timeline.png
swift scripts/qa/inspect-cutcap-export.swift /tmp/export.mp4
rustc --edition 2024 --test src/crates/concat-host/src/ios_paths.rs -o /tmp/cutcap-ios-path-tests
/tmp/cutcap-ios-path-tests
```

The isolated path suite exercises the actual host module without linking the media stack. Five tests passed: device paths/project folders, Simulator paths, existing/missing files, invalid roots/traversal, and symlink escape. The complete host/native test suite, Clippy and fork coverage have not been run. New path recovery is iOS-only; desktop project behavior is preserved.

## Final native results

The final Simulator build with sandbox recovery passed in 5m03s; packaging and code-signature verification passed. After reinstalling over the existing app, all three prior projects displayed their thumbnails and durations again, including the oldest project that previously reported Folder not found. That oldest draft opened with its original three clips and played its blue source. Exporting it under a new filename completed and AVFoundation decoded the recovered MP4 as 4 seconds, 360×640, 30 fps, blue at 0.5 seconds and red at 2.5 seconds. No source file or earlier export was overwritten.

The newer top-track draft was reopened after the update: its blue clip remained split into approximately 1+1 seconds, followed by the 2-second red clip. All three clips appeared in the editor. Vietnamese language selection persisted across reinstall and the home action read Chỉnh sửa video. Existing projects keep their original track placement; the initial lower-track draft still needs vertical scrolling to reach T1.

With the two original fixtures, the immediate post-import screenshot check passed with blue=41415/red=27384 without scrolling. A separate reimport of the app's 4-second output plus a 2-second original also appeared immediately on T4. GitHub Issues was enabled on the fork so the modified report-problem link has a destination.

| Verification phase | Result |
| --- | --- |
| Build | PASS — development Simulator app and signed bundle |
| Types | PASS — Rust compiler, including iOS recovery integration |
| Lint | PASS — Rust format, shell syntax, locale keys, diff whitespace; translation warnings described above |
| Tests | PASS — 284 unchanged domain tests + 5 new isolated path tests, native import/split/export/reopen; coverage not collected |
| Security | PASS for scoped changed-code review and secret-pattern scan; full upstream audit not performed |
| Diff | Reviewed — branding, entry flow, sandbox recovery, packaging, QA tools and documentation |

Ready for branch review and further iPhone testing. Not a distribution or full feature-parity certification. Files-provider import and invalid-file UI paths remain unverified, along with the limits listed above.
