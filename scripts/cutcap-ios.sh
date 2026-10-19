#!/usr/bin/env bash
set -euo pipefail
target=${1:?Pass an iOS Rust target}
profile=${2:-release}
case "$target" in
  aarch64-apple-ios|aarch64-apple-ios-sim) ;;
  *) exit 2 ;;
esac
case "$profile" in
  debug|release|quick) ;;
  *) exit 2 ;;
esac
root=$(cd "$(dirname "$0")/.." && pwd)
export IPHONEOS_DEPLOYMENT_TARGET=26.0
bash "$root/src/scripts/ios-app.sh" "$target" "$profile"
source_app="$root/src/target/$target/$profile/Concat.app"
app="$root/src/target/$target/$profile/Cutcap.app"
ditto "$source_app" "$app"
cp "$root/assets/icons/cutcap_512.png" "$app/AppIcon.png"
python3 - "$app/Info.plist" <<'PY'
from pathlib import Path
import plistlib
import sys

path = Path(sys.argv[1])
with path.open('rb') as stream:
    data = plistlib.load(stream)
data['CFBundleName'] = 'Cutcap'
data['CFBundleDisplayName'] = 'Cutcap'
data['CFBundleIdentifier'] = 'com.tpmk2015.cutcap'
data['NSPhotoLibraryUsageDescription'] = 'Cutcap imports only the videos you select.'
data['NSPhotoLibraryAddUsageDescription'] = 'Cutcap saves your finished videos to Photos.'
data['NSMicrophoneUsageDescription'] = 'Cutcap records the voice-over you request.'
data['NSHumanReadableCopyright'] = 'Modified fork of Concat. AGPL-3.0-or-later. Copyright 2026 Jareer and Concat contributors.'
data['CFBundleIcons'] = {'CFBundlePrimaryIcon': {'CFBundleIconFiles': ['AppIcon'], 'UIPrerenderedIcon': True}}
data['CFBundleIcons~ipad'] = data['CFBundleIcons']
with path.open('wb') as stream:
    plistlib.dump(data, stream)
PY
mkdir -p "$app/Legal"
cp "$root/LICENSE" "$root/THIRD_PARTY_NOTICES.md" "$root/TRADEMARK.md" "$root/CUTCAP.md" "$app/Legal/"
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
echo "Bundled $app"
