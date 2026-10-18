import XCTest

/// Real taps on the floating bar, as a finger makes them.
final class BarTests: XCTestCase {
    func testDarkFromTheMoreMenu() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-landscape"]
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

    private func attach(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
}
