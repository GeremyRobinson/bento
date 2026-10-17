// swift-tools-version: 5.9
// The Obento² app. Open this folder in Swift Playgrounds (Mac or iPad) and press Play.
// App/ is the screens; Core/ is the lesson logic and camera maths (tested by ios/Packages/ObentoCore).
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
