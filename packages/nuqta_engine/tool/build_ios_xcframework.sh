#!/bin/bash
# Builds llama.xcframework (llama + ggml + mtmd, Metal, iOS device + simulator)
# into packages/nuqta_engine/ios/Frameworks. Needs macOS with Xcode and CMake.
# Takes 5-15 minutes the first time; later runs reuse the result.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=ios/Frameworks/llama.xcframework
STAMP=ios/Frameworks/.llama_commit
LLAMA_COMMIT=5aeac37a35b44fde4bdffaec9159f2fcb253b622
if [ -d "$OUT" ] && [ "$(cat "$STAMP" 2>/dev/null)" = "$LLAMA_COMMIT" ]; then
  echo "llama.xcframework is up to date"; exit 0
fi
command -v cmake >/dev/null || { echo "CMake is required (brew install cmake)" >&2; exit 1; }
xcrun --sdk iphoneos --show-sdk-path >/dev/null || { echo "Xcode with the iOS SDK is required" >&2; exit 1; }
tool/fetch_llama.sh
(cd third_party/llama.cpp && ./build-xcframework.sh ios-device ios-sim)
rm -rf "$OUT" && mkdir -p ios/Frameworks
cp -R third_party/llama.cpp/build-apple/llama.xcframework "$OUT"
echo "$LLAMA_COMMIT" > "$STAMP"
echo "built $OUT"
