#!/bin/zsh
# build.sh <derivedDataDir>: generate the project (XcodeGen) and build the app for the iOS simulator into that folder.
# Prints only errors and the result; exits non-zero when the build fails.
# JOBS=n limits how many files compile at once and runs the build at low priority (nice), to keep the Mac cool.
set -o pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodegen -q || exit 1
LIGHT=() LIMIT=(); [[ -n $JOBS ]] && LIGHT=(nice -n 10) LIMIT=(-jobs $JOBS)
$LIGHT xcodebuild $LIMIT -project Obento2.xcodeproj -scheme Obento2 -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "${1:?derived data folder}" CODE_SIGNING_ALLOWED=NO build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
exit ${pipestatus[1]}
