#!/bin/zsh
# shoot.sh <simulator udid> <derivedDataDir> <out.png> <shot name> [more launch arguments…]
# Installs the build from that derived data on that simulator (when it's newer than the last install), launches the app
# at one moment (`-shot <name>`, see App/Shots.swift), waits $WAIT seconds (default 8), and saves a screenshot.
# THEME=dark|light sets the simulator's appearance first. Each worker uses its own simulator and derived data.
UDID=${1:?udid} DD=${2:?derived data} OUT=${3:?out.png}; shift 3
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcrun simctl boot "$UDID" 2>/dev/null; xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1
[[ -n $THEME ]] && xcrun simctl ui "$UDID" appearance "$THEME"
APP="$DD/Build/Products/Debug-iphonesimulator/Obento2.app" STAMP="$DD/.installed-$UDID"
if [[ ! -f $STAMP || "$APP/Obento2" -nt $STAMP ]]; then xcrun simctl install "$UDID" "$APP" && touch "$STAMP"; fi
xcrun simctl terminate "$UDID" education.bento.obento2 2>/dev/null
xcrun simctl launch "$UDID" education.bento.obento2 -shot "$@" >/dev/null
sleep ${WAIT:-8}
mkdir -p "$(dirname "$OUT")"
xcrun simctl io "$UDID" screenshot "$OUT" >/dev/null 2>&1 && echo "$OUT"
# quit the app once it's photographed: a running app keeps the simulator (and the Mac) busy
xcrun simctl terminate "$UDID" education.bento.obento2 2>/dev/null
