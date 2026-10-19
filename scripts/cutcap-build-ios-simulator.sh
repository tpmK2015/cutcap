#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root/src"
if [ -d /opt/homebrew/opt/rustup/bin ]; then
  export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
fi
export FFMPEG_DIR="$PWD/vendor/ffmpeg/aarch64-apple-ios-sim"
export SHERPA_ONNX_LIB_DIR="$PWD/vendor/sherpa-onnx/ios/lib-sim"
export IPHONEOS_DEPLOYMENT_TARGET=${IPHONEOS_DEPLOYMENT_TARGET:-15.0}
export CMAKE_OSX_SYSROOT=iphonesimulator
export GGML_NATIVE=OFF
export CARGO_BUILD_JOBS=${CARGO_BUILD_JOBS:-4}
if [ ! -f "$FFMPEG_DIR/lib/libavcodec.a" ]; then
  echo 'Prepare FFmpeg with src/scripts/ffmpeg-mobile.sh aarch64-apple-ios-sim first.' >&2
  exit 1
fi
binary="$PWD/vendor/sherpa-onnx/ios/SherpaOnnxC.xcframework/ios-arm64_x86_64-simulator/SherpaOnnxC.framework/SherpaOnnxC"
if [ ! -f "$binary" ]; then
  echo 'Prepare Sherpa ONNX with src/scripts/sherpa-mobile.sh aarch64-apple-ios first.' >&2
  exit 1
fi
mkdir -p "$SHERPA_ONNX_LIB_DIR"
ln -sf "$binary" "$SHERPA_ONNX_LIB_DIR/libsherpa-onnx-c-api.dylib"
cargo build --locked --release -p concat --target aarch64-apple-ios-sim \
  --config 'profile.release.package.concat.opt-level=0' \
  --config 'profile.release.package.concat.codegen-units=256'
