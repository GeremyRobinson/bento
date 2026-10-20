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

    /// Show me on their own (G 20 Oct): the problem is done, but it isn't right on their own, and a fresh one takes
    /// its place so the test can still open.
    func testShowMeIsNotRightOnYourOwn() {
        var rng = SeededRandom(seed: 10)
        var plan = LessonPlan(spec, using: &rng)
        var runs = plan.items.indices.map { plan.run(spec, $0) }
        for i in 3..<9 { work(&runs[i], showMe: i == 4) }
        XCTAssertTrue(runs[4].isLast); XCTAssertFalse(runs[4].missedAny); XCTAssertFalse(runs[4].clean)
        XCTAssertEqual(plan.ownRight(runs), 5)
        XCTAssertFalse(plan.testOpen(runs), "5 right on their own, and one done with Show me")
        let added = plan.solved(4, runs[4], spec, using: &rng)
        XCTAssertEqual(added, [9]); XCTAssertEqual(plan.items[9].part, .own); XCTAssertNil(plan.items[9].focus)
        var fresh = plan.run(spec, 9); work(&fresh)
        runs.append(fresh)
        XCTAssertEqual(plan.ownRight(runs), 6); XCTAssertTrue(plan.testOpen(runs))
        // a clean problem adds nothing
        XCTAssertEqual(plan.solved(3, runs[3], spec, using: &rng), [])
    }

    /// Hints (G 20 Oct): together problems free up to their cap; on their own none until a miss on that step, then
    /// one of the page's; one a step; none in a test.
    func testHints() {
        var rng = SeededRandom(seed: 14)
        let plan = LessonPlan(spec, using: &rng)
        var together = plan.run(spec, 0)
        XCTAssertEqual(LessonPlan.hint(together, part: .together, left: 0), .free, "free, whatever the page has left")
        XCTAssertEqual(LessonPlan.hintsLeft(together, part: .together, left: 0), 3)
        together.usedHint()
        XCTAssertEqual(LessonPlan.hint(together, part: .together, left: 5), .off, "one a step")
        XCTAssertEqual(LessonPlan.hintsLeft(together, part: .together, left: 5), 2)

        var own = plan.run(spec, 3)
        XCTAssertEqual(LessonPlan.hint(own, part: .own, left: 5), .off, "no hint before a miss")
        type(&own, "1"); _ = own.go()
        XCTAssertEqual(LessonPlan.hint(own, part: .own, left: 5), .spend)
        XCTAssertEqual(LessonPlan.hint(own, part: .own, left: 0), .off, "the page's hints are used up")
        XCTAssertEqual(LessonPlan.hintsLeft(own, part: .own, left: 4), 4)
        own.usedHint()
        XCTAssertEqual(LessonPlan.hint(own, part: .own, left: 4), .off)

        var test = LessonPlan.testRuns(spec, using: &rng)[0]
        type(&test, "1")
        XCTAssertEqual(LessonPlan.hint(test, part: .own, left: 5), .off)
        XCTAssertNil(LessonPlan.hintsLeft(test, part: .own, left: 5))
        XCTAssertEqual(LessonPlan.hint(own, part: nil, left: 5), .off, "a test's question has no part")
    }

    /// Every test is scored one way (G 20 Oct): problems right, 12 of them, 10 to pass. A chapter's test takes its
    /// lessons in turn, each from its own check recipe.
    func testAChapterTestTakesItsLessonsInTurn() {
        var rng = SeededRandom(seed: 15)
        let specs = [MultiplyTwoDigit.spec, LongDivision.spec, OrderOfOperations.spec]
        var test = LessonPlan.testRuns(specs, using: &rng)
        XCTAssertEqual(test.count, 12)
        XCTAssertEqual(test.map(\.spec.id), Array(repeating: specs.map(\.id), count: 4).flatMap { $0 })
        XCTAssertTrue(test.allSatisfy { !$0.helps && $0.oneTry })
        for i in test.indices { work(&test[i], wrong: i == 0 || i == 3 ? [1: "1"] : [:]) }
        let score = LessonPlan.testScore(test)
        XCTAssertEqual(score?.right, 10); XCTAssertEqual(score?.level, 3)
        XCTAssertEqual(LessonPlan.passMark(12), 10)
        XCTAssertEqual(TestRecord(right: 11, of: 12, date: 0).level, 3)
        XCTAssertTrue(TestRecord(right: 10, of: 12, date: 0).passed)
        XCTAssertFalse(TestRecord(right: 9, of: 12, date: 0).passed)
    }

    /// A due lesson's recheck: its 4-problem skill check, no help and one try, scored by problems right.
    func testARecheckIsTheSkillCheck() {
        var rng = SeededRandom(seed: 16)
        var check = LessonPlan.recheckRuns(spec, using: &rng)
        XCTAssertEqual(check.count, 4)
        XCTAssertTrue(check.allSatisfy { !$0.helps && $0.oneTry })
        XCTAssertEqual(check[3].lead, 1, "the recipe's fourth is told as a story")
        XCTAssertNil(LessonPlan.recheckScore(check))
        for i in check.indices { work(&check[i], wrong: i == 2 ? [1: "1"] : [:]) }
        XCTAssertEqual(LessonPlan.recheckScore(check)?.right, 3)
        XCTAssertEqual(LessonPlan.recheckScore(check)?.level, 3, "3 of 4 keeps it learned")
        var low = LessonPlan.recheckRuns(spec, using: &rng)
        for i in low.indices { work(&low[i], wrong: i < 2 ? [1: "1"] : [:]) }
        XCTAssertEqual(LessonPlan.recheckScore(low)?.level, 2)
        XCTAssertLessThan(LessonPlan.recheckScore(low)?.level ?? 9, Mastery.pass)
    }

    /// A problem whose save no longer fits is made again with fresh numbers, in its part.
    func testRenew() {
        var rng = SeededRandom(seed: 17)
        var plan = LessonPlan(spec, using: &rng)
        let was = plan.items[4]
        plan.renew(4, spec, using: &rng)
        XCTAssertEqual(plan.items[4].part, .own); XCTAssertFalse(plan.items[4].story)
        XCTAssertNotEqual(plan.items[4].numbers, was.numbers)
        XCTAssertEqual(plan.items.count, 9)
    }
}
