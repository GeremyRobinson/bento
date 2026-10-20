#!/bin/zsh
# playgrounds.sh: does the app still build in Swift Playgrounds? Swift Playgrounds compiles with an older Swift (4.7:
# Swift 6.2) than the Xcode here (27.1: Swift 6.4), so code that builds in Xcode can still fail for G. This type-checks
# every Swift file in App/ and Core/ with the Command Line Tools' Swift against Swift Playgrounds' own SDK, the way a Mac
# runs an iPad app (Mac Catalyst). Prints any errors, then "Swift Playgrounds: builds" or "Swift Playgrounds: FAILS";
# exits non-zero when it fails. Takes a few minutes. Needs Swift Playground.app and the Command Line Tools.
cd "$(dirname "$0")/../Obento2.swiftpm"
PG="/Applications/Swift Playground.app/Contents"
SDK="$PG/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
SWIFTC=/Library/Developer/CommandLineTools/usr/bin/swiftc
[[ -d $SDK ]] || { echo "playgrounds.sh: Swift Playground.app isn't in /Applications"; exit 2; }
[[ -x $SWIFTC ]] || { echo "playgrounds.sh: no Command Line Tools (xcode-select --install)"; exit 2; }
# the Swift Playgrounds compiles with, and the one used here: the same minor version, or the check is only close
want=$(strings -n 12 "$PG/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/PlaygroundCompiler.framework/Versions/A/PlaygroundCompiler" | grep -m1 -oE "swiftlang-[0-9]+\.[0-9]+")
have=$("$SWIFTC" --version 2>&1 | grep -m1 -oE "swiftlang-[0-9]+\.[0-9]+")
echo "Swift Playgrounds: ${want:-?}, checked with ${have:-?}"
[[ -n $want && $want == $have ]] || echo "playgrounds.sh: not the same Swift, so this is only close"
ios=$(plutil -extract Version raw "$SDK/SDKSettings.plist" 2>/dev/null || echo 26.0)
"$SWIFTC" -typecheck -parse-as-library -swift-version 5 -sdk "$SDK" -target "arm64-apple-ios$ios-macabi" \
  -Fsystem "$SDK/System/iOSSupport/System/Library/Frameworks" -I "$SDK/System/iOSSupport/usr/lib/swift" \
  App/**/*.swift Core/**/*.swift 2>&1 | grep -E "^[^ |].*: error:"
code=${pipestatus[1]}
(( code == 0 )) && echo "Swift Playgrounds: builds" || echo "Swift Playgrounds: FAILS"
exit $code
