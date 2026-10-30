import XCTest

/// A lesson's problem pinched in and out, as fingers do: filmed, to see what the zoom does to what's drawn (G 30 Oct:
/// the blocks drew themselves in again on every zoom).
final class PinchTests: XCTestCase {
    func testPinchingAProblem() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-landscape", "-shot", "page-g5-round-1", "-numbers", "value=5.53,place=1"]
        app.launch()
        sleep(9)
        func mark(_ s: String) { print("ISLAND-MARK \(Date().timeIntervalSince1970) \(s)") }
        let paper = app.windows.firstMatch
        mark("pinch-in"); paper.pinch(withScale: 1.6, velocity: 0.6); sleep(2)
        mark("pinch-out"); paper.pinch(withScale: 0.6, velocity: -0.6); sleep(2)
        mark("end")
    }
}
