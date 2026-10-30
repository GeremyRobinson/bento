import XCTest

/// Real taps on the floating bar, as a finger makes them.
final class BarTests: XCTestCase {
    func testDarkFromTheMoreMenu() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-landscape", "-set-up"]
        app.launch()
        sleep(3)
        attach(app, "before")
        let more = app.buttons["More"]
        XCTAssertTrue(more.waitForExistence(timeout: 5), "the ⋯ button is there")
        more.tap()
        sleep(1)
        attach(app, "menu")
        let dark = app.buttons.matching(NSPredicate(format: "label == 'Dark' OR label == 'Light'")).firstMatch
        XCTAssertTrue(dark.waitForExistence(timeout: 3), "the Dark row is there")
        dark.tap()
        sleep(2)
        attach(app, "after")
    }

    /// The paper flung with a finger coasts on and slows to a stop; dragged slowly and let go, it stops where it's
    /// left; the bar's Me and Lessons glide there and back (G 29 Oct: moves like real things). Filmed to be read frame
    /// by frame (each step's mark printed with the time).
    func testThePaperCoastsAndGlides() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-landscape", "-set-up"]
        app.launch()
        XCTAssertTrue(app.buttons["More"].waitForExistence(timeout: 8))
        sleep(2)
        let mid = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        func mark(_ s: String) { print("ISLAND-MARK \(Date().timeIntervalSince1970) \(s)") }
        mark("fling"); mid.press(forDuration: 0.02, thenDragTo: mid.withOffset(CGVector(dx: -260, dy: -60)), withVelocity: 1600, thenHoldForDuration: 0); sleep(3)
        mark("slow"); mid.press(forDuration: 0.3, thenDragTo: mid.withOffset(CGVector(dx: 200, dy: 40)), withVelocity: 60, thenHoldForDuration: 0.4); sleep(2)
        mark("me"); app.buttons["Me"].tap(); sleep(3)
        mark("lessons"); app.buttons["Lessons"].tap(); sleep(3)
        mark("end")
        XCTAssertTrue(app.buttons["More"].exists, "the bar is still there")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
}
