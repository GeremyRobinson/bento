import XCTest
@testable import ObentoCore

final class HelpTests: XCTestCase {
    let p = AddFractions.Problem(a: 4, p: 3, b: 8, q: 1)

    /// Done together: the right pieces are outlined from the start, before any miss.
    func testTogetherPointsToTheMove() {
        var r = LessonRun(AddFractions.spec, numbers: p.numbers); r.guided = true; r.skipAsk()
        XCTAssertNotNil(r.step.task)
        XCTAssertEqual(r.picture["outline"], 1)
    }

    /// Less help: a miss brings the first hint only, never the outline or Show me.
    func testLessHelpStopsAtTheFirstHint() {
        var r = LessonRun(AddFractions.spec, numbers: p.numbers); r.hintCap = 1; r.skipAsk()
        for _ in 0..<3 { _ = r.go() }
        XCTAssertEqual(r.hintLevel, 1)
        XCTAssertNil(r.picture["outline"]); XCTAssertNil(r.picture["showMe"])
    }

    /// Final answer only: one step for the whole problem, then its answer; it takes the total.
    func testFinalAnswerOnly() {
        var r = LessonRun(AddFractions.spec, numbers: p.numbers, finalOnly: true); r.skipAsk()
        XCTAssertTrue(r.finalOnly)
        XCTAssertEqual(r.steps.count, 3)
        XCTAssertEqual(r.words.say, "3/4 + 1/8 is how many eighths?")
        for i in 0..<6 { r.tap(i) }
        XCTAssertEqual(r.go(), .notYet("Not yet. Let's do it step by step."))
        r.tap(6)
        XCTAssertEqual(r.go(), .moved(2))
        XCTAssertTrue(r.isLast)
        // and it keeps through saving
        XCTAssertTrue(LessonRun(AddFractions.spec, restoring: r.snapshot).finalOnly)
    }

    /// The web's step points: 1 first try, ½ after a hint or one miss, ¼ after more, 0 if shown.
    func testPoints() {
        var r = LessonRun(AddFractions.spec, numbers: p.numbers); r.skipAsk()
        for i in 0..<6 { r.tap(i) }; _ = r.go()                    // cover: first try → 1
        _ = r.go(); _ = r.go(); r.tap(6); _ = r.go()               // add: two misses → ¼
        XCTAssertEqual(r.points, 1.25, accuracy: 1e-9)
        var h = LessonRun(AddFractions.spec, numbers: p.numbers); h.skipAsk()
        h.usedHint(); for i in 0..<6 { h.tap(i) }; _ = h.go()      // a hint → ½
        _ = h.showMe(); _ = h.go()                                  // shown → 0
        XCTAssertEqual(h.points, 0.5, accuracy: 1e-9)
    }

    /// Wrong typed answers sorted into kinds, with the web's words.
    func testDiagnose() {
        XCTAssertEqual(Diagnose.kind(["x": -12], ["x": 12]), .sign)
        XCTAssertEqual(Diagnose.kind(["x": 120], ["x": 12]), .place)
        XCTAssertEqual(Diagnose.kind(["x": 13], ["x": 12]), .off1)
        XCTAssertEqual(Diagnose.kind(["x": 84], ["x": 48]), .digits)
        XCTAssertEqual(Diagnose.kind(["x": 205], ["x": 200]), .close)
        XCTAssertEqual(Diagnose.kind(["x": 7], ["x": 30], earlier: [7]), .reuse)
        XCTAssertEqual(Diagnose.kind(["a": 3, "b": 2], ["a": 2, "b": 3]), .swap)
        XCTAssertNil(Diagnose.kind(["x": 50], ["x": 12]))
        XCTAssertEqual(Diagnose.say(["x": 13], ["x": 12]), "You’re 1 away. Count again.".replacingOccurrences(of: "’", with: "'"))
    }
}
