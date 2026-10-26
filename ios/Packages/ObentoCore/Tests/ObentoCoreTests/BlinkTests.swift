import XCTest
@testable import ObentoCore

/// The answer box's cursor (Core/Blink.swift): when it shows, and when it next changes, so the paper's clock can wake
/// only then while a number is wanted.
final class BlinkTests: XCTestCase {
    func testItHoldsOnAfterAKeyThenBlinks() {
        XCTAssertTrue(Blink.on(since: 0))
        XCTAssertTrue(Blink.on(since: 0.59))
        XCTAssertTrue(Blink.on(since: 1.0))          // still the first on, after the hold
        XCTAssertFalse(Blink.on(since: 1.2))         // off
        XCTAssertTrue(Blink.on(since: 1.7))          // on again
        XCTAssertFalse(Blink.on(since: 2.3))
        XCTAssertTrue(Blink.on(since: -0.2))         // a moment before the key was seen: on
    }

    func testTheNextChangeIsWhereOnAndOffSwap() {
        XCTAssertEqual(Blink.nextChange(after: 0), 1.13, accuracy: 1e-9)
        XCTAssertEqual(Blink.nextChange(after: 0.6), 1.13, accuracy: 1e-9)
        XCTAssertEqual(Blink.nextChange(after: 1.13), 1.66, accuracy: 1e-9)
        XCTAssertEqual(Blink.nextChange(after: 1.5), 1.66, accuracy: 1e-9)
        XCTAssertEqual(Blink.nextChange(after: 100), 100.24, accuracy: 1e-6)   // 0.6 + 188 × 0.53
    }

    func testOnlyTheChangesMatter() {
        // between one change and the next the cursor stays as it is, so nothing needs drawing in between
        var s = 0.0
        for _ in 0..<40 {
            let next = Blink.nextChange(after: s)
            XCTAssertGreaterThan(next, s)
            let shown = Blink.on(since: s)
            for k in 1..<10 { XCTAssertEqual(Blink.on(since: s + (next - s) * Double(k) / 10 - 1e-6), shown) }
            XCTAssertNotEqual(Blink.on(since: next + 1e-6), shown)
            s = next + 1e-6
        }
    }
}
