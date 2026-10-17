# Obento² for iPad and iPhone (Swift)

The paper proof: the paper's grid, pan and zoom, the glide to a lesson, and Unit cubes in 3D.

**`Obento2.swiftpm` is the app.** Open it in Swift Playgrounds (Mac or iPad) and press Play.
- `App/` holds the screens: SwiftUI for the paper, RealityKit for 3D lessons.
- `Core/` holds the lesson logic and the camera maths, with no drawing in it.

`Packages/ObentoCore` runs Core's tests on any machine: `cd Packages/ObentoCore && swift test`. Its sources are a link to `Obento2.swiftpm/Core`.

`project.yml` builds the same files as a regular Xcode project (`brew install xcodegen && xcodegen`). CI uses it for simulator screenshots.

`-shot paper|selected|flat|cover|tilt|stacked|demo` opens the app on one moment. CI uses it for screenshots and the demo video in `shots/`.
