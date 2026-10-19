# Cutcap session handoff — 2026-10-20

Active branch: `cutcap/ios-quick-edit`. Full AGPL fork of jub0t/Concat at baseline `79116bd0f9a103c633d888603ad27890e929dbdc`; origin tpmK2015/cutcap. Main remains unchanged. The independent FrameCut workspace is a separate fallback.

Implemented Cutcap display branding, own icon, legal notice, simulator build/package wrappers, and an iPhone Edit video → Photos/Files entry. Probe before project creation; use the first video's dimensions/rate, preserve selection order, insert on the first displayed track and save. Photos adoption is serialized to avoid same-name copy collisions. iOS project/media/font references recover missing old-container Documents paths only when the corresponding current sandbox item exists; traversal and symlink escape are rejected.

Read [native QA report](cutcap-ios-qa.md) for evidence and limitations. Final build, signature, media decoding and post-update draft reopen passed. Five new path tests plus 284 unchanged domain tests passed. Coverage/full host suite/Clippy/physical-device/AI/distribution acceptance remain pending.

Local Simulator is Cutcap QA, iPhone 17 Pro / iOS 26.5, UDID `59E5E56D-92C0-4CEC-8C2E-228A283E5A63`. Only synthetic media was used. Do not touch the other shared iPhone Simulator. Scope Orca commands to this device and the Cutcap worktree, registered with repo ID `a5439ebf-565b-46d1-94e2-550f5c31cfd5`.

Artifact: `src/target/aarch64-apple-ios-sim/release/Cutcap.app`, bundle ID `com.tpmk2015.cutcap`. It is a development build: engine optimized, UI opt-level 0/256 codegen units despite the release output directory. Follow CUTCAP.md and scripts/cutcap-build-ios-simulator.sh; Rustup must be in PATH. Prepared FFmpeg and Sherpa vendors are ignored. Native logs/screenshots/exports stay in the local temporary QA directory and are not committed.

Next: open this checkout as the active workspace, verify Files/invalid-media flows, test real-device signing/media cases, then audit the advanced feature inventory. Do not claim every desktop feature works on iPhone or publish to a store from these checks.
