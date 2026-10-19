# Cutcap

Cutcap is a modified fork of [Concat](https://github.com/jub0t/Concat), based on commit `79116bd0f9a103c633d888603ad27890e929dbdc`.

Fork source: https://github.com/tpmK2015/cutcap

Modifications dated 2026-10-19:

- Cutcap display branding and an independently drawn icon.
- An iPhone home action that picks existing videos, validates them, creates a project using the first video's dimensions/rate and places the chosen videos on the timeline in selection order.
- Quick-edit clips start on the first displayed phone track, so they are visible immediately.
- iOS project/media/font paths are recovered inside the current Documents sandbox when an app update relocates the container; missing files and paths outside Documents are left unresolved.
- Ordered Photos selection and serialized adoption of imported files, preventing concurrent copies with the same suggested name from selecting the same destination.
- A separate iOS packaging script with bundle ID `com.tpmk2015.cutcap`, legal notices and app resources. The Rust crates, executable and project format retain their upstream names.

This fork is licensed under **AGPL-3.0-or-later**. Copyright 2026 Jareer and Concat contributors; modifications by Cutcap contributors. See [LICENSE](LICENSE) for the full terms, including the absence of warranty, and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for dependency and model licenses. The Concat name and logo remain governed by [TRADEMARK.md](TRADEMARK.md). This is not an official Concat build.

## iOS development

Follow `.github/workflows/mobile.yml` for the baseline build. The pinned toolchain is Rust 1.93.1. Prepare FFmpeg and the Sherpa ONNX framework using the existing scripts under `src/scripts/`.

For local Simulator development, the wrapper below keeps the engine optimized and compiles only the large UI crate at opt-level 0 with 256 codegen units. The binary is written under `release/` but is a development build. Use the unmodified upstream release command for a fully optimized distribution build.

```sh
bash scripts/cutcap-build-ios-simulator.sh
bash scripts/cutcap-ios.sh aarch64-apple-ios-sim release
```

The result is `src/target/aarch64-apple-ios-sim/release/Cutcap.app`, ad-hoc signed for Simulator. A physical device needs development signing and provisioning. No App Store readiness or complete desktop-to-iPhone feature parity is claimed.

The new entry strings are localized in English and Vietnamese. Other upstream locales currently use English fallback for these four added strings; their existing translations are preserved.
