// swift-tools-version:6.0
import PackageDescription

// The maths and the camera, with no drawing in it, so it builds and tests on any machine.
let package = Package(
    name: "ObentoCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [.library(name: "ObentoCore", targets: ["ObentoCore"])],
    targets: [
        .target(name: "ObentoCore"),
        .testTarget(name: "ObentoCoreTests", dependencies: ["ObentoCore"]),
    ]
)
