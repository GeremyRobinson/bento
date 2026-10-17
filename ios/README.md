# Obento² for iPad and iPhone (Swift)

The paper proof: the paper's grid, pan and zoom, the glide to a lesson, and Unit cubes in 3D.

- `Packages/ObentoCore` holds the lesson logic and the camera maths. No drawing, so it builds and tests anywhere: `swift test`.
- `Obento2/` is the app: SwiftUI for the paper, RealityKit for 3D lessons.
- `project.yml` makes the Xcode project: `brew install xcodegen && xcodegen`, then open `Obento2.xcodeproj`.

To put it on an iPad: open the project in Xcode, plug in the iPad, pick it as the destination, sign with your Apple ID
(Signing & Capabilities → Team), and press Run. With a free Apple ID the app needs reinstalling every 7 days.

`-shot paper|selected|flat|cover|tilt|stacked` opens the app on one moment; CI uses it for screenshots (see `shots/`).
