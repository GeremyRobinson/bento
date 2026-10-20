#!/bin/zsh
# build.sh <derivedDataDir>: generate the project (XcodeGen) and build the app for the iOS simulator into that folder.
# Prints only errors and the result; exits non-zero when the build fails.
set -o pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodegen -q || exit 1
xcodebuild -project Obento2.xcodeproj -scheme Obento2 -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "${1:?derived data folder}" CODE_SIGNING_ALLOWED=NO build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
exit ${pipestatus[1]}
