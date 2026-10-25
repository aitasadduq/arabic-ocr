#!/bin/bash
# Fetches llama.cpp at the version the Nuqta GGUF files and the upstream apps were
# tested with, into packages/nuqta_engine/third_party/llama.cpp.
# (The Android/host CMake build fetches it by itself when this folder is missing.)
set -euo pipefail
cd "$(dirname "$0")/.."
LLAMA_COMMIT=5aeac37a35b44fde4bdffaec9159f2fcb253b622
DEST=third_party/llama.cpp
if [ -d "$DEST/.git" ] && [ "$(git -C "$DEST" rev-parse HEAD)" = "$LLAMA_COMMIT" ]; then exit 0; fi
rm -rf "$DEST" && mkdir -p "$DEST"
git -C "$DEST" init -q
git -C "$DEST" remote add origin https://github.com/ggml-org/llama.cpp.git
git -C "$DEST" fetch -q --depth 1 origin "$LLAMA_COMMIT"
git -C "$DEST" checkout -q FETCH_HEAD
echo "llama.cpp $LLAMA_COMMIT -> $DEST"
