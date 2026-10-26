#!/bin/zsh
# build.sh <derivedDataDir>: generate the project (XcodeGen) and build the app for the iOS simulator into that folder.
# Prints only errors and the result; exits non-zero when the build fails.
# Builds gently by default, to keep the Mac cool (G, 25 Oct): low priority (NICE, default 10) and 4 compile jobs at a
# time (JOBS, default 4). NICE=0 / JOBS=0 turn either off.
set -o pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodegen -q || exit 1
pre=(); (( ${NICE:-10} > 0 )) && pre=(nice -n ${NICE:-10}); jobs=(); (( ${JOBS:-4} > 0 )) && jobs=(-jobs ${JOBS:-4})
$pre xcodebuild $jobs -project Obento2.xcodeproj -scheme Obento2 -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "${1:?derived data folder}" CODE_SIGNING_ALLOWED=NO build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
exit ${pipestatus[1]}
