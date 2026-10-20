import XCTest
@testable import ObentoCore

final class LessonPlanTests: XCTestCase {
    let spec = MultiplyTwoDigit.spec
    func type(_ l: inout LessonRun, _ s: String) { l.reset(); for ch in s { l.type(String(ch)) } }
    /// Works a problem to the end: each step right, except the steps given wrong answers, which are tried wrong first.
    func work(_ l: inout LessonRun, wrong: [Int: String] = [:], showMe: Bool = false) {
        while !l.isLast {
            if let a = l.step.answer {
                if showMe { _ = l.showAnswer() }
                else {
                    if let w = wrong[l.index - l.lead] { type(&l, w); _ = l.go() }
                    if a.choices != nil { l.choose(Int(a.expected["c"] ?? 0)) } else { type(&l, fmt(a.expected.values.first ?? 0)) }
                }
            }
            _ = l.go()
        }
    }

    func testThreeTogetherThenSixOnTheirOwn() {
        var rng = SeededRandom(seed: 5)
        let plan = LessonPlan(spec, using: &rng)
        XCTAssertEqual(plan.items.map(\.part), Array(repeating: .together, count: 3) + Array(repeating: .own, count: 6))
        let r0 = plan.run(spec, 0), r3 = plan.run(spec, 3)
        XCTAssertTrue(r0.guided); XCTAssertEqual(r0.hintCap, 3)
        XCTAssertFalse(r3.guided); XCTAssertEqual(r3.hintCap, 1)
        XCTAssertTrue(plan.items[5].story, "every third own problem is a story")
        // the together problems are the friendlier ones
        for i in 0..<3 { XCTAssertLessThanOrEqual(plan.items[i].numbers["b"]!, 29) }
    }

    func testAnotherTogetherWhenShowMeWasNeeded() {
        var rng = SeededRandom(seed: 6)
        var plan = LessonPlan(spec, using: &rng)
        var runs = plan.items.indices.map { plan.run(spec, $0) }
        work(&runs[0]); XCTAssertEqual(plan.solved(0, runs[0], spec, using: &rng), [])
        work(&runs[2], showMe: true)
        XCTAssertEqual(plan.solved(2, runs[2], spec, using: &rng), [3], "a fourth together problem, right after the third")
        XCTAssertEqual(plan.items[3].part, .together)
        XCTAssertEqual(plan.items.count, 10)
    }

    func testAMissIsReplacedAndTwiceIsTaught() {
        var rng = SeededRandom(seed: 7)
        var plan = LessonPlan(spec, using: &rng)
        var runs = plan.items.indices.map { plan.run(spec, $0) }
        // forgetting the tens strip's zero: 47 × 3 for 47 × 30
        let i = 3, a = Int(plan.items[i].numbers["a"]!), b = Int(plan.items[i].numbers["b"]!)
        let tens = MultiplyTwoDigit.parts(b)[0] / 10
        work(&runs[i], wrong: [1: String(a * tens)])
        let added = plan.solved(i, runs[i], spec, using: &rng)
        XCTAssertEqual(added, [9])
        XCTAssertEqual(plan.items[9].focus?.step, 1)
        XCTAssertEqual(plan.items[9].focus?.teach, false)
        XCTAssertTrue(plan.items[9].focus!.said.contains("add a zero"))
        XCTAssertFalse(plan.items[9].story)
        // the same slip again: that part is taught first next time
        var r = plan.run(spec, 9)
        let a2 = Int(plan.items[9].numbers["a"]!), t2 = MultiplyTwoDigit.parts(Int(plan.items[9].numbers["b"]!))[0] / 10
        work(&r, wrong: [1: String(a2 * t2)])
        XCTAssertEqual(plan.solved(9, r, spec, using: &rng), [10])
        XCTAssertEqual(plan.items[10].focus?.teach, true)
    }

    func testTheTestOpensAfterSixRight() {
        var rng = SeededRandom(seed: 8)
        let plan = LessonPlan(spec, using: &rng)
        var runs = plan.items.indices.map { plan.run(spec, $0) }
        for i in 3..<8 { work(&runs[i]) }
        XCTAssertEqual(plan.ownRight(runs), 5); XCTAssertFalse(plan.testOpen(runs))
        work(&runs[8])
        XCTAssertTrue(plan.testOpen(runs))
    }

    func testTheTestPassesAtTenOfTwelve() {
        var rng = SeededRandom(seed: 9)
        var test = LessonPlan.testRuns(spec, using: &rng)
        XCTAssertEqual(test.count, 12)
        XCTAssertTrue(test.allSatisfy { !$0.helps && $0.oneTry })
        XCTAssertNil(LessonPlan.testScore(test))
        for i in test.indices { work(&test[i], wrong: i < 2 ? [1: "1"] : [:]) }
        XCTAssertEqual(LessonPlan.testScore(test)?.right, 10)
        XCTAssertEqual(LessonPlan.testScore(test)?.level, 3)
        XCTAssertEqual(LessonPlan.level(12, of: 12), 4)
        XCTAssertEqual(LessonPlan.level(9, of: 12), 2)
        XCTAssertLessThan(LessonPlan.level(9, of: 12), Mastery.pass)
        XCTAssertGreaterThanOrEqual(LessonPlan.level(10, of: 12), Mastery.pass)
    }
}
