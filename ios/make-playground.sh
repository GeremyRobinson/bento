#!/bin/bash
# Packs the app into Obento2.swiftpm, an app Swift Playgrounds can open and run on an iPad.
# Playgrounds can't use our local package, so the lesson logic is copied in beside the app code.
set -e
cd "$(dirname "$0")"
OUT=${1:-build/Obento2.swiftpm}
rm -rf "$OUT"; mkdir -p "$OUT"
for f in Obento2/*.swift Packages/ObentoCore/Sources/ObentoCore/*.swift; do
  sed -e '/^import ObentoCore$/d' -e 's/ObentoCore\.//g' "$f" > "$OUT/$(basename "$f")"
done
cp -R Obento2/Assets.xcassets "$OUT/"
cat > "$OUT/Package.swift" <<'SWIFT'
// swift-tools-version: 5.9
// Made by make-playground.sh from ios/. Edit the files in ios/, not here.
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Obento2",
    platforms: [.iOS("18.0")],
    products: [
        .iOSApplication(
            name: "Obento²",
            targets: ["AppModule"],
            bundleIdentifier: "education.bento.obento2",
            displayVersion: "0.1",
            bundleVersion: "1",
            supportedDeviceFamilies: [.pad, .phone],
            supportedInterfaceOrientations: [.portrait, .landscapeRight, .landscapeLeft, .portraitUpsideDown(.when(deviceFamilies: [.pad]))]
        )
    ],
    targets: [
        .executableTarget(name: "AppModule", path: ".")
    ]
)
SWIFT
echo "$OUT"
