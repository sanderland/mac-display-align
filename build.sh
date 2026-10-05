#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

rm -rf dist
mkdir -p dist/build

for arch in arm64 x86_64; do
  swiftc -O -target "$arch-apple-macos13.0" align.swift -o "dist/build/align-$arch"
done

APP=dist/DisplayAlign.app
mkdir -p "$APP/Contents/MacOS"
lipo -create dist/build/align-arm64 dist/build/align-x86_64 -output "$APP/Contents/MacOS/align"
cp Info.plist "$APP/Contents/Info.plist"

# Ad-hoc signature: Apple Silicon refuses to run unsigned binaries.
codesign --force --sign - "$APP"
ditto -c -k --keepParent "$APP" dist/DisplayAlign.zip
