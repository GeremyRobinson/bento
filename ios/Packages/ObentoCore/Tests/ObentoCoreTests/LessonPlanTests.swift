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
        // what it keeps in mind is this problem's own advice, never the last problem's numbers
        let a9 = fmt(plan.items[9].numbers["a"] ?? 0), d9 = MultiplyTwoDigit.parts(Int(plan.items[9].numbers["b"] ?? 0))[0] / 10
        XCTAssertEqual(plan.items[9].focus?.said, "Do \(a9) × \(d9), then add a zero.")
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
        XCTAssertTrue(runs[4].isLast); XCTAssertFalse(runs[4].missedAny); XCTAssertFalse(plan.clean(4, runs[4]))
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
        XCTAssertNil(LessonPlan.hintsLeft(together, part: .together, left: 0), "free hints aren't counted")
        together.usedHint()
        XCTAssertEqual(LessonPlan.hint(together, part: .together, left: 5), .off, "one a step")
        XCTAssertNil(LessonPlan.noHint(together, part: .together, left: 5), "its hint is showing: nothing to say")

        var own = plan.run(spec, 3)
        XCTAssertEqual(LessonPlan.hint(own, part: .own, left: 5), .off, "no hint before a miss")
        XCTAssertNil(LessonPlan.hintsLeft(own, part: .own, left: 5), "no count standing there unusable before a miss")
        XCTAssertEqual(LessonPlan.noHint(own, part: .own, left: 5), "Have a go first. A hint comes after a miss.")
        XCTAssertEqual(LessonPlan.noHint(own, part: .own, left: 0), "This page's hints are used up.", "none would come after a miss either")
        type(&own, "1"); _ = own.go()
        XCTAssertEqual(LessonPlan.hint(own, part: .own, left: 5), .spend)
        XCTAssertNil(LessonPlan.noHint(own, part: .own, left: 5))
        XCTAssertEqual(LessonPlan.hint(own, part: .own, left: 0), .off, "the page's hints are used up")
        XCTAssertEqual(LessonPlan.noHint(own, part: .own, left: 0), "This page's hints are used up.")
        XCTAssertEqual(LessonPlan.hintsLeft(own, part: .own, left: 4), 4)
        XCTAssertEqual(LessonPlan.hintsLeft(plan.run(spec, 4), part: .own, left: 0), 0, "used up shows as none left, miss or not")
        own.usedHint()
        XCTAssertEqual(LessonPlan.hint(own, part: .own, left: 4), .off)

        var test = LessonPlan.testRuns(spec, using: &rng)[0]
        type(&test, "1")
        XCTAssertEqual(LessonPlan.hint(test, part: .own, left: 5), .off)
        XCTAssertNil(LessonPlan.hintsLeft(test, part: .own, left: 5))
        XCTAssertEqual(LessonPlan.noHint(test, part: nil, left: 5), "No hints in a test.")
        XCTAssertEqual(LessonPlan.hint(own, part: nil, left: 5), .off, "a test's question has no part")
    }

    /// The app's own teaching isn't Show me (G 20 Oct): a problem aimed at a slip made twice shows that step first, and
    /// the child then working it with no miss has it right on their own; nothing more is added for it. However the
    /// problem keeps the step it showed (as shown, the way a preview marks it), it's never held against them. Their own
    /// Show me, on any other step, still is.
    func testTheAppsOwnTeachingIsntShowMe() {
        var rng = SeededRandom(seed: 19)
        var plan = LessonPlan(spec, using: &rng)
        var runs = plan.items.indices.map { plan.run(spec, $0) }
        // the same slip twice: the tens strip's zero forgotten
        func slip(_ i: Int) -> [Int] {
            let a = Int(plan.items[i].numbers["a"] ?? 0), tens = MultiplyTwoDigit.parts(Int(plan.items[i].numbers["b"] ?? 0))[0] / 10
            var r = plan.run(spec, i); work(&r, wrong: [1: String(a * tens)])
            if runs.indices.contains(i) { runs[i] = r } else { runs.append(r) }
            return plan.solved(i, r, spec, using: &rng)
        }
        let first = slip(3)[0], taught = slip(first)[0]
        let focus = try! XCTUnwrap(plan.items[taught].focus)
        XCTAssertTrue(focus.teach)
        /// The taught problem, up to the step it's aimed at, where the app shows that step first and gives it back.
        func reachTaughtStep() -> LessonRun {
            var r = plan.run(spec, taught)
            while r.index - r.lead != focus.step { if let a = r.step.answer { type(&r, fmt(a.expected.values.first ?? 0)) }; _ = r.go() }
            XCTAssertNotNil(r.showAnswer())
            XCTAssertEqual(r.shown, [focus.step + r.lead], "the problem keeps the step as shown")
            r.reset()
            return r
        }
        var r = reachTaughtStep()
        work(&r)
        XCTAssertTrue(plan.clean(taught, r), "the app's teaching isn't their Show me")
        XCTAssertFalse(plan.usedShowMe(taught, r.shown, lead: r.lead))
        runs.append(r)
        XCTAssertEqual(plan.solved(taught, r, spec, using: &rng), [], "nothing more for a problem right on their own")
        XCTAssertEqual(plan.ownRight(runs), 1)
        XCTAssertTrue(plan.clean(taught, r.snapshot), "and the same from its save, as the map reads it")
        // their own Show me on another step of it still counts
        var asked = reachTaughtStep()
        // the taught step worked by the child, then Show me on the next step that asks for something
        if let a = asked.step.answer { type(&asked, fmt(a.expected.values.first ?? 0)) }
        XCTAssertEqual(asked.go(), .moved(focus.step + asked.lead + 1))
        while asked.step.answer == nil && !asked.isLast { _ = asked.go() }
        XCTAssertFalse(asked.isLast, "a step after the taught one asks for something")
        XCTAssertNotNil(asked.showAnswer())
        work(&asked)
        XCTAssertTrue(asked.isLast)
        XCTAssertFalse(plan.clean(taught, asked), "Show me asked for on another step")
        // and on a problem with no teaching, any step shown is Show me
        var helped = plan.run(spec, 4)
        _ = helped.showAnswer(); work(&helped)
        XCTAssertFalse(plan.clean(4, helped))
        XCTAssertFalse(plan.clean(4, helped.snapshot))
    }

    /// A recheck that comes back low (G 20 Oct): a fresh problem on the page for each one missed, aimed at its slip.
    func testARecheckThatComesBackLowPutsProblemsOnThePage() {
        var rng = SeededRandom(seed: 20)
        var plan = LessonPlan(spec, using: &rng)
        var check = LessonPlan.recheckRuns(spec, using: &rng)
        for i in check.indices { work(&check[i], wrong: i < 2 ? [1: "1"] : [:]) }
        XCTAssertLessThan(LessonPlan.recheckScore(check)?.level ?? 9, Mastery.pass)
        // the page as it was: every problem done, the test passed
        var runs = plan.items.indices.map { plan.run(spec, $0) }
        for i in runs.indices { work(&runs[i]) }
        var test = LessonPlan.testRuns(spec, using: &rng)
        for i in test.indices { work(&test[i]) }
        func standing() -> LessonPlan.Standing {
            plan.standing(solved: runs.map(\.isLast), clean: runs.indices.map { plan.clean($0, runs[$0]) }, test: test.map { $0.isLast ? !$0.missedAny : nil })
        }
        XCTAssertEqual(standing().words, "Test passed · 12 of 12")
        let added = plan.goOver(check, spec, using: &rng)
        XCTAssertEqual(added, [9, 10])
        XCTAssertTrue(added.allSatisfy { plan.items[$0].part == .own && plan.items[$0].focus?.step == 1 && plan.items[$0].focus?.teach == false })
        XCTAssertTrue(added.allSatisfy { plan.items[$0].goOver == true }); XCTAssertNil(plan.items[3].goOver)
        XCTAssertEqual(plan.items[9].focus?.said, LessonPlan.advice(spec, plan.items[9].numbers, step: 1), "advice for its own numbers")
        // the page says what there is to go over first, until it's done
        runs += added.map { plan.run(spec, $0) }
        XCTAssertEqual(standing().words, "Go over · 0 of 2 done"); XCTAssertEqual(standing().done, 0)
        work(&runs[9])
        XCTAssertEqual(standing().words, "Go over · 1 of 2 done")
        work(&runs[10])
        XCTAssertEqual(standing().words, "Test passed · 12 of 12")
        XCTAssertEqual(plan.goOver(Array(check[2...]), spec, using: &rng), [], "nothing missed, nothing added")
    }

    /// Where the page stands (G 20 Oct): the goal that opens the test, never a total that grows.
    func testThePageSaysTheGoalThatOpensTheTest() {
        var rng = SeededRandom(seed: 21)
        var plan = LessonPlan(spec, using: &rng)
        var runs = plan.items.indices.map { plan.run(spec, $0) }
        func standing(_ test: [LessonRun] = []) -> LessonPlan.Standing {
            plan.standing(solved: runs.map(\.isLast), clean: runs.indices.map { plan.clean($0, runs[$0]) }, test: test.map { $0.isLast ? !$0.missedAny : nil })
        }
        XCTAssertEqual(standing().words, "Together · 0 of 3 done"); XCTAssertEqual(standing().done, 0)
        work(&runs[0])
        XCTAssertEqual(standing().words, "Together · 1 of 3 done")
        work(&runs[1]); work(&runs[2])
        XCTAssertEqual(standing().words, "On your own · 0 of 6 right")
        // a miss adds a fresh problem, and the goal stays 6
        let a = Int(plan.items[3].numbers["a"] ?? 0), tens = MultiplyTwoDigit.parts(Int(plan.items[3].numbers["b"] ?? 0))[0] / 10
        work(&runs[3], wrong: [1: String(a * tens)])
        for i in plan.solved(3, runs[3], spec, using: &rng) { runs.insert(plan.run(spec, i), at: i) }
        XCTAssertEqual(plan.items.count, 10)
        for i in 4..<8 { work(&runs[i]) }
        XCTAssertEqual(standing().words, "On your own · 4 of 6 right")
        XCTAssertEqual(standing().done, 7.0 / 9, accuracy: 1e-9)
        work(&runs[8]); work(&runs[9])
        XCTAssertEqual(standing().words, "The lesson test is open"); XCTAssertEqual(standing().done, 1)
        var test = LessonPlan.testRuns(spec, using: &rng)
        for i in 0..<3 { work(&test[i]) }
        XCTAssertEqual(standing(test).words, "Lesson test · 3 of 12 done")
        for i in 3..<12 { work(&test[i], wrong: i < 6 ? [1: "1"] : [:]) }
        XCTAssertEqual(standing(test).words, "Test · 9 of 12 · Take it again")
        // and the same from the page as it was saved
        XCTAssertEqual(plan.standing(runs.map(\.snapshot), test: test.map(\.snapshot)), standing(test))
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

    /// No problem twice on a page (the review of 20 Oct: Together 1 and Together 2 were both 2 2/3). Mixed numbers' first
    /// three come from a small pool (1 or 2 wholes, halves to fifths: 18 problems), so plain draws repeat among them on
    /// about 1 page in 5, and on about 1 in 3 counting the How to's problem. Each problem is drawn again while the page
    /// has it already (the How to's too), and so is each one the page adds later, and each of a test's 12.
    func testNoProblemTwiceOnAPage() {
        let spec = MixedToImproper.spec
        var plainRepeats = 0
        for seed in 0..<300 {
            // the page as BarsPage makes it: the How to's problem, then the plan
            var rng = SeededRandom(seed: UInt64(seed))
            let howTo = spec.generate(&rng, 0)
            var plan = LessonPlan(spec, after: [howTo], using: &rng)
            // the same draws without drawing again: how often the page would have repeated itself
            var raw = SeededRandom(seed: UInt64(seed))
            let plain = [spec.generate(&raw, 0)] + (0..<3).map { spec.generate(&raw, $0) }
            if Set(plain).count < plain.count { plainRepeats += 1 }

            var seen = [howTo] + plan.items.map(\.numbers)
            XCTAssertEqual(Set(seen).count, seen.count, "seed \(seed): \(seen)")
            // what the page adds: a fourth together problem after Show me, a fresh own one for one Show me helped
            var runs = plan.items.indices.map { plan.run(spec, $0) }
            func showMe(_ i: Int) { while !runs[i].isLast { if runs[i].step.answer != nil { _ = runs[i].showAnswer() }; _ = runs[i].go() } }
            showMe(2)
            XCTAssertEqual(plan.solved(2, runs[2], spec, using: &rng), [3])
            runs = plan.items.indices.map { plan.run(spec, $0) }
            showMe(4)
            XCTAssertEqual(plan.solved(4, runs[4], spec, using: &rng), [10])
            plan.renew(5, spec, using: &rng)
            seen = plan.items.map(\.numbers)
            XCTAssertEqual(Set(seen).count, seen.count, "seed \(seed): \(seen)")
            // a test's 12
            let test = LessonPlan.testRuns(spec, using: &rng).map(\.numbers)
            XCTAssertEqual(Set(test).count, 12, "seed \(seed): \(test)")
        }
        XCTAssertGreaterThan(plainRepeats, 30, "plain draws repeat often enough that the test shows the redraw at work")
    }

    /// A problem aimed at a slip that's made again keeps its aim, with its advice for its fresh numbers.
    func testRenewKeepsTheAim() {
        var rng = SeededRandom(seed: 18)
        var plan = LessonPlan(spec, using: &rng)
        var runs = plan.items.indices.map { plan.run(spec, $0) }
        let a = Int(plan.items[3].numbers["a"] ?? 0), tens = MultiplyTwoDigit.parts(Int(plan.items[3].numbers["b"] ?? 0))[0] / 10
        work(&runs[3], wrong: [1: String(a * tens)])
        let i = plan.solved(3, runs[3], spec, using: &rng)[0]
        plan.renew(i, spec, using: &rng)
        let n = plan.items[i].numbers
        XCTAssertEqual(plan.items[i].focus?.step, 1)
        XCTAssertEqual(plan.items[i].focus?.said, "Do \(fmt(n["a"] ?? 0)) × \(MultiplyTwoDigit.parts(Int(n["b"] ?? 0))[0] / 10), then add a zero.")
    }
}
