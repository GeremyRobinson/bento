import XCTest
@testable import ObentoCore

final class RoundDecimalsTests: XCTestCase {
    private func run(_ N: Int, _ p: Int) -> LessonRun { LessonRun(RoundDecimals.spec, numbers: RoundDecimals.numbers(N: N, p: p)) }
    /// Clears the step's boxes, types `s` into the first one and checks.
    private func answer(_ l: inout LessonRun, _ s: String) -> LessonRun.Outcome {
        l.reset(); for c in s { l.type(String(c)) }; return l.go()
    }
    /// A hand move: its value in the box, checked at once (as the tap or the release does).
    private func move(_ l: inout LessonRun, _ v: Double) -> LessonRun.Outcome { l.set("x", v); return l.go() }
    /// The tap and the drag made right, to the record.
    private func toWrite(_ l: inout LessonRun) {
        let s = RoundDecimals.Parts(l.numbers)
        _ = l.go(); _ = move(&l, Double(s.digit)); _ = move(&l, s.roundsUp ? 10 : 0)
    }

    /// The test page's reference: 3.476 to the nearest hundredth.
    func testWalkThroughTheReference() {
        var l = run(3476, 2)
        let s = RoundDecimals.Parts(l.numbers)
        XCTAssertEqual(RoundDecimals.spec.master, "number-line")
        XCTAssertEqual(l.display, [.num(3.476), .op("≈"), .text("?"), .text("(nearest hundredth)")])
        XCTAssertEqual(l.words.say, "Round to the nearest hundredth.")
        XCTAssertEqual(l.words.action, "Let’s find out")
        XCTAssertEqual(l.picture["value"], 3.476); XCTAssertEqual(l.picture["lo"], 3.47); XCTAssertEqual(l.picture["hi"], 3.48)
        XCTAssertEqual(l.picture["half"], 3.475); XCTAssertEqual(l.picture["tick"]!, 0.001, accuracy: 1e-12)
        XCTAssertEqual(l.picture["at"], 0)
        // line 1 is the tenth it's in, in ten blocks of a hundredth; line 2 the hundredth, in ten steps
        XCTAssertEqual(s.lo1, 3.4); XCTAssertEqual(s.digit, 7); XCTAssertEqual(s.step, 6)
        XCTAssertEqual(l.go(), .moved(1))

        // tap the block it's in: the block's number is the hundredths digit
        XCTAssertEqual(l.words.say, "Round to the nearest hundredth. Tap the block the point is in.")
        XCTAssertEqual(l.step.answer?.byHand, true)
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(l.picture["at"], 1)
        XCTAssertEqual(move(&l, 2), .notYet("3.476 isn’t between 3.42 and 3.43. Find the point."))
        XCTAssertEqual(l.misses, 1)
        XCTAssertEqual(l.picture["ring"], 1, "a miss rings the point")
        XCTAssertEqual(move(&l, 0), .notYet("3.476 isn’t between 3.40 and 3.41. Find the point."))
        XCTAssertEqual(l.slips.last?.said, "3.476 isn’t between 3.40 and 3.41. Find the point.")
        XCTAssertEqual(move(&l, 7), .moved(2))

        // drag the point to the closer end: its steps from the lower end are the next digit
        XCTAssertEqual(l.words.say, "Drag the point to the end it’s closer to.")
        XCTAssertEqual(l.words.hint, "Count the steps to each end.")
        XCTAssertEqual(move(&l, 4), .notYet("Drag it all the way to one end."))
        XCTAssertEqual(l.misses, 0, "not at an end: a notice, not a miss")
        XCTAssertEqual(move(&l, 0), .notYet("That end is 6 steps away. The other end is 4."))
        XCTAssertEqual(l.misses, 1)
        XCTAssertEqual(l.picture["counts"], 1, "a miss counts the steps to each end")
        XCTAssertEqual(move(&l, 10), .moved(3))

        // the record: 3.476 ≈ [3.48], typed
        XCTAssertEqual(l.words.say, "Write the closer end.")
        XCTAssertFalse(l.handAnswered)
        XCTAssertEqual(answer(&l, "3.47"), .notYet("6 is 5 or more, so round up."))
        XCTAssertEqual(answer(&l, "3.5"), .notYet("Round to the hundredths: that’s 2 digits after the point."))
        XCTAssertEqual(answer(&l, "3.4"), .notYet("That’s not the end you dragged to. It was 3.48."))
        XCTAssertEqual(l.steps[3].answer?.work, [.num(3.476), .op("≈"), .num(3.48)])
        XCTAssertEqual(answer(&l, "3.48"), .moved(4))

        // done: why that end, and the rule under the record
        XCTAssertEqual(l.words.say, "6 steps from 3.47, 4 to 3.48. 3.48 is closer.")
        XCTAssertEqual(s.rule, "6 is 5 or more: round up")
        XCTAssertEqual(l.picture["at"], 4)
        XCTAssertEqual(l.go(), .newProblem)
        XCTAssertEqual(RoundDecimals.spec.idea(l.numbers), "Rounding picks the closer number, and the digit just to the right tells you which.")
        XCTAssertEqual(RoundDecimals.spec.depends, ["g4-placevalue", "g4-dec"])
    }

    /// The web's own tests: the other place is named, and rolling a 9 over takes 5 as well as 5.0.
    func testWebAnswers() {
        var l = run(51647, 2); toWrite(&l)
        XCTAssertEqual(answer(&l, "51.6"), .notYet("Round to the hundredths: that’s 2 digits after the point."))
        XCTAssertEqual(answer(&l, "51.65"), .moved(4))
        // tenths use two decimals: 4.96 rolls a 9 over
        var roll = run(4960, 1)
        let s = RoundDecimals.Parts(roll.numbers)
        XCTAssertEqual(s.lo1, 4); XCTAssertEqual(s.digit, 9); XCTAssertEqual(s.step, 6); XCTAssertEqual(s.R, 5)
        XCTAssertEqual(RoundDecimals.written(s.R, 1), "5.0")
        toWrite(&roll)
        XCTAssertEqual(answer(&roll, "5"), .moved(4))
        XCTAssertEqual(roll.words.say, "6 steps from 4.9, 4 to 5.0. 5.0 is closer.")
        var roll2 = run(4960, 1); toWrite(&roll2)
        XCTAssertEqual(answer(&roll2, "5.0"), .moved(4))
        // the block a tenth is in: "4.96 isn't between 4.2 and 4.3"
        var t = run(4960, 1); _ = t.go()
        XCTAssertEqual(move(&t, 2), .notYet("4.96 isn’t between 4.2 and 4.3. Find the point."))
    }

    func testStaysAndHalfway() {
        // stays: the wrong end is the far one
        var l = run(3472, 2); _ = l.go(); _ = move(&l, 7)
        XCTAssertEqual(move(&l, 10), .notYet("That end is 8 steps away. The other end is 2."))
        XCTAssertEqual(move(&l, 0), .moved(3))
        XCTAssertEqual(answer(&l, "3.48"), .notYet("2 is 4 or less, so the digit stays the same."))
        XCTAssertEqual(answer(&l, "3.47"), .moved(4))
        XCTAssertEqual(l.words.say, "2 steps to 3.47, 8 to 3.48. 3.47 is closer.")
        XCTAssertEqual(RoundDecimals.Parts(l.numbers).rule, "2 is 4 or less: it stays")
        // exactly halfway rounds up, and the line says so
        var h = run(3475, 2); _ = h.go(); _ = move(&h, 7)
        XCTAssertEqual(move(&h, 0), .notYet("Exactly halfway rounds up."))
        XCTAssertEqual(move(&h, 10), .moved(3))
        XCTAssertEqual(answer(&h, "3.48"), .moved(4))
        XCTAssertEqual(h.words.say, "5 steps from 3.47, 5 to 3.48. Halfway rounds up.")
        // one step: "1 step"
        var one = run(5210, 1); _ = one.go(); _ = move(&one, 2)
        XCTAssertEqual(move(&one, 10), .notYet("That end is 9 steps away. The other end is 1."))
        // tenths: the hundredths are the steps of line 2
        let t = RoundDecimals.Parts(RoundDecimals.numbers(N: 5280, p: 1))
        XCTAssertEqual(t.lo1, 5); XCTAssertEqual(t.digit, 2); XCTAssertEqual(t.next, 8); XCTAssertEqual(t.step, 8)
        XCTAssertEqual(t.why, "8 steps from 5.2, 2 to 5.3. 5.3 is closer.")
        XCTAssertEqual(run(5280, 1).display.last, .text("(nearest tenth)"))
    }

    func testGeneratorKeepsTheWebRules() {
        var rng = SeededRandom(seed: 11)
        for index in 0..<7 {
            for _ in 0..<300 {
                let n = RoundDecimals.spec.generate(&rng, index), s = RoundDecimals.Parts(n)
                XCTAssertTrue((1001...99999).contains(s.N) && (1...2).contains(s.p), "\(n)")
                XCTAssertNotEqual(s.N % s.unit, 0, "never already rounded: \(n)")
                // one decimal past the place, so the number sits on a step of line 2
                XCTAssertEqual(s.N % (s.unit / 10), 0, "the point sits on a step: \(n)")
                XCTAssertEqual(s.step, Double(s.next), "\(n)")
                if index < 3 { XCTAssertEqual(s.p, 1); XCTAssertLessThan(s.N, 10000) }
                if index == 5 {
                    XCTAssertEqual((s.N / s.unit) % 10, 9, "\(n)")
                    XCTAssertEqual(((s.N + s.unit / 2) / s.unit) % 10, 0, "rolls a 9 over: \(n)")
                }
                XCTAssertEqual(s.R, (Double(s.N) / Double(s.unit)).rounded() / pow(10, Double(s.p)), accuracy: 1e-9)
                XCTAssertEqual(LessonRun(RoundDecimals.spec, numbers: n).steps.count, 5)
            }
        }
    }

    func testSkillCheckDraws() {
        var rng = SeededRandom(seed: 3)
        let items = RoundDecimals.spec.check
        XCTAssertEqual(items.map(\.index), [3, 3, 3, 5])
        for item in items { for _ in 0..<300 {
            let n = item.draw(RoundDecimals.spec, using: &rng)
            XCTAssertTrue(item.when?(n) ?? true, "\(n)")
        } }
    }

    func testHandMovesSetTheAnswer() {
        // a hand move puts its value in the box, as typing would, and can be taken out again
        var l = run(3476, 2)
        _ = l.go(); l.set("x", 7); _ = l.go(); l.set("x", 10); _ = l.go()
        l.set("x", 3.48)
        XCTAssertEqual(l.typed["x"], "3.48")
        l.set("y", 1)
        XCTAssertNil(l.typed["y"], "only the step's own boxes")
        l.set("x", nil)
        XCTAssertNil(l.typed["x"])
        l.set("x", 3.48)
        XCTAssertEqual(l.go(), .moved(4))
        // Show me is a preview: the step counts as shown, and nothing is written
        var m = run(3476, 2); _ = m.go()
        m.markShown()
        XCTAssertEqual(m.shown, [1]); XCTAssertTrue(m.typed.isEmpty)
        // a test (one try) shows the answer after a miss, so the picture can draw it before moving on
        var t = run(3476, 2); t.oneTry = true; t.helps = false; _ = t.go()
        XCTAssertEqual(move(&t, 3), .notYet("3.476 isn’t between 3.43 and 3.44. Find the point."))
        XCTAssertEqual(t.typed["x"], "7")
        t.markShown()
        XCTAssertTrue(t.shown.isEmpty, "a test never counts Show me")
    }
}
