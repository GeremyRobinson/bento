import XCTest

/// Real touches on the places around the lessons (G 20 Oct): the bar's Me, a card on Me opening its lesson and the bar
/// coming back to Me, the grown-ups' square held down for its 3 seconds, a tap on the map still choosing a lesson.
/// Screenshots are attached at each moment. Positions on the paper are worked out from where each page is framed.
final class PlacesTests: XCTestCase {
    func testMeTheGrownUpsHoldAndTheMap() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-landscape"]
        app.launch()
        sleep(6)
        attach(app, "1 map")
        let window = app.windows.firstMatch
        let size = window.frame.size
        /// A point on the screen, in points from its top-left.
        func at(_ x: Double, _ y: Double) -> XCUICoordinate { window.coordinate(withNormalizedOffset: CGVector(dx: x / size.width, dy: y / size.height)) }
        /// The middle of the room the paper is framed in (clear of the bar), where a framed page's middle lands.
        let mid = (x: size.width / 2, y: 24 + (size.height - 24 - 120) / 2)

        // Me, from the bar: a page on the paper
        let me = app.buttons["Me"]
        XCTAssertTrue(me.waitForExistence(timeout: 5))
        me.tap()
        sleep(3)
        attach(app, "2 me")

        // the grown-ups' page, from More, shut behind its square: held for 3.6 seconds, it opens
        app.buttons["More"].tap()
        sleep(1)
        let grownUps = app.buttons["For grown-ups"]
        XCTAssertTrue(grownUps.waitForExistence(timeout: 3))
        grownUps.tap()
        sleep(3)
        attach(app, "3 gate")
        // the gate is framed at 100%: its frame (6 blocks by 23 squares) centred; the square's middle is 2 blocks left of
        // that and 3.5 squares down
        at(mid.x - 200, mid.y + 70).press(forDuration: 1.2)
        sleep(1)
        attach(app, "4 let go too soon")
        at(mid.x - 200, mid.y + 70).press(forDuration: 3.6)
        sleep(2)
        attach(app, "5 grown-ups open")
        // the paper's colours, from the page (framed at 82%: its Colours blocks are 107 points under the screen's middle,
        // Dark 428 to the right of it, Match the iPad 198): dark, then as the iPad is set again
        at(mid.x + 428, mid.y + 107).tap()
        sleep(2)
        attach(app, "5b dark from the page")
        at(mid.x + 198, mid.y + 107).tap()
        sleep(2)
        attach(app, "5c as the iPad is set")

        // back to the map from the bar; a tap on a lesson there chooses it
        app.buttons["Lessons"].tap()
        sleep(3)
        attach(app, "6 map again")
        // the map frames today's chapter (Whole numbers, nothing learned) at 100% from its title down: Long division, its
        // second lesson, is the middle of the screen across and 264 points down
        at(size.width / 2, 264).tap()
        sleep(2)
        attach(app, "7 tapped on the map")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
}
