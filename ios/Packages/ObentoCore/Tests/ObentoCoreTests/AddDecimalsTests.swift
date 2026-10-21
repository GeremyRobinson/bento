import XCTest
@testable import ObentoCore

final class AddDecimalsTests: XCTestCase {
    private func run(_ a: Double, _ b: Double) -> LessonRun { LessonRun(AddDecimals.spec, numbers: AddDecimals.numbers(a: a, b: b)) }
    private func parts(_ a: Double, _ b: Double) -> AddDecimals.Parts { AddDecimals.Parts(AddDecimals.numbers(a: a, b: b)) }
    /// Clears the step's boxes, types `s` into the first one and checks.
    private func answer(_ l: inout LessonRun, _ s: String) -> LessonRun.Outcome {
        l.reset(); for c in s { l.type(String(c)) }; return l.go()
    }
    /// A hand move: its value in the box, checked at once (as the last 0 written, the hundredths let go of, or the full
    /// grid tapped does).
    private func move(_ l: inout LessonRun, _ v: Double) -> LessonRun.Outcome { l.set("x", v); return l.go() }

    /// The web lesson's reference: 12.5 + 3.75 = 16.25, the hundredths making a whole.
    func testWalkThroughTheReference() {
        var l = run(12.5, 3.75)
        let s = AddDecimals.Parts(l.numbers)
        XCTAssertEqual(AddDecimals.spec.master, "columns")
        XCTAssertEqual(l.display, [.num(12.5), .op("+"), .num(3.75)])
        // the problem is the record: the first words say what to do with it, never the numbers again
        XCTAssertEqual(l.words.say, "Add the two numbers.")
        XCTAssertEqual(l.words.hint, "Write 12.5 as 12.50 so both numbers have hundredths.")
        XCTAssertEqual(l.picture, ["at": 0])
        XCTAssertEqual(s.na, 50); XCTAssertEqual(s.nb, 75); XCTAssertEqual(s.n, 125)
        XCTAssertTrue(s.carries); XCTAssertEqual(s.left, 25)
        XCTAssertEqual(l.steps.count, 6)
        XCTAssertEqual(l.go(), .moved(1))

        // the 0s: tap the empty place after the point; the last one written answers the step
        XCTAssertEqual(l.words.say, "Tap the empty place after the point to write a 0.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(l.picture["at"], 1)
        XCTAssertEqual(s.gaps, [AddDecimals.Gap(0, -2)])
        // a tap anywhere else on the record says what's there: a notice, not a miss
        XCTAssertEqual(move(&l, AddDecimals.tapCode(1, 1)), .notYet("No 0 is needed in front of the 3."))
        XCTAssertEqual(move(&l, AddDecimals.tapCode(0, -1)), .notYet("That place has a 5 in it."))
        XCTAssertEqual(move(&l, AddDecimals.tapCode(1, -2)), .notYet("That place has a 5 in it."))
        XCTAssertEqual(l.misses, 0)
        XCTAssertEqual(l.steps[1].answer?.explain, "12.5 is 12.50: the same number, with hundredths.")
        XCTAssertEqual(LessonPlan.advice(AddDecimals.spec, l.numbers, step: 1), "Write 12.5 as 12.50 so both numbers have hundredths.")
        XCTAssertEqual(move(&l, 1), .moved(2))

        // the slide: b's hundredths into a's grid; its box is the hundredths poured, as the web's decimal step has it
        XCTAssertEqual(l.words.say, "Slide the striped hundredths into the first grid.")
        XCTAssertEqual(l.words.hint, "Drag the striped hundredths onto the first grid.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(l.picture["at"], 2)
        XCTAssertEqual(s.pour, "50 + 75 = 125 hundredths")
        XCTAssertEqual(move(&l, 0), .notYet("They went back. Drop them on the first grid."))
        XCTAssertEqual(l.misses, 0, "dropped somewhere else: a notice, not a miss")
        XCTAssertEqual(l.steps[2].answer?.work, [.num(0.5), .op("+"), .num(0.75), .op("="), .num(1.25)])
        XCTAssertEqual(move(&l, 1.25), .moved(3))

        // a full grid is 1 whole: tap it to carry the 1 to the ones
        XCTAssertEqual(l.words.say, "A full grid is 1 whole. Tap it to carry the 1.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(l.picture["at"], 3)
        XCTAssertEqual(move(&l, 0), .notYet("That grid has 25 hundredths. Tap the full one."))
        XCTAssertEqual(l.misses, 1, "the grid that isn't full: a miss")
        XCTAssertEqual(l.picture["full"], 1, "a miss outlines the full grid")
        XCTAssertEqual(l.steps[3].answer?.work, [.num(1.25), .op("="), .num(1), .op("+"), .num(0.25)])
        XCTAssertEqual(move(&l, 1), .moved(4))

        // the record: the total, typed, as school writes it; the web's slips are said of the paper
        XCTAssertEqual(l.words.say, "Write the total.")
        XCTAssertEqual(l.words.hint, "The grid shows what goes after the point. Add the ones and the carried 1.")
        XCTAssertFalse(l.handAnswered)
        XCTAssertEqual(l.picture["at"], 4)
        XCTAssertEqual(answer(&l, "15.25"), .notYet("The full grid is 1 whole: that 1 goes with the whole numbers."))
        XCTAssertEqual(l.slips.last?.kind, "k0")
        XCTAssertEqual(l.picture["read"], 1, "a miss lights what the total is read from")
        XCTAssertEqual(answer(&l, "10.25"), .notYet("That takes away the whole numbers. This one adds."))
        XCTAssertEqual(l.slips.last?.kind, "k1")
        XCTAssertEqual(answer(&l, "15.8"), .notYet("0.5 means 5 tenths, which is 50 hundredths. Line up the points."))
        XCTAssertEqual(l.slips.last?.kind, "k2")
        XCTAssertEqual(answer(&l, "1625"), .notYet("The digits are right. The point goes under the points."))
        XCTAssertEqual(answer(&l, "162.5"), .notYet("The digits are right. The point goes under the points."))
        XCTAssertEqual(answer(&l, "16.3"), .notYet("Not quite. Add each column, right to left."))
        XCTAssertEqual(l.slips.last?.kind, "wrong")
        XCTAssertEqual(LessonPlan.advice(AddDecimals.spec, l.numbers, step: 4), "Add each column, right to left.")
        XCTAssertEqual(l.steps[4].answer?.work, [.num(12.5), .op("+"), .num(3.75), .op("="), .num(16.25)])
        XCTAssertEqual(answer(&l, "16.250"), .moved(5), "the same number, however it's written")

        // done: the last words say why
        XCTAssertEqual(l.words.say, "Points under points, so tenths add to tenths.")
        XCTAssertEqual(l.picture["at"], 5)
        XCTAssertEqual(l.go(), .newProblem)
        XCTAssertEqual(AddDecimals.spec.story?(l.numbers), "Maya biked 12.5 km on Saturday and 3.75 km on Sunday. How far did she bike in all?")
        XCTAssertEqual(AddDecimals.spec.idea(l.numbers), "Line up the points so tenths add to tenths and hundredths to hundredths.")
        XCTAssertEqual(AddDecimals.spec.depends, ["g4-dec", "g4-addsub"])
    }

    /// The hundredths that don't make a whole: no grid to carry, and the web's slips for that case.
    func testNoWholeToCarry() {
        var l = run(18.2, 5.31)
        let s = AddDecimals.Parts(l.numbers)
        XCTAssertFalse(s.carries); XCTAssertEqual(s.left, 51)
        XCTAssertEqual(l.steps.count, 5, "no full grid: no carry step")
        _ = l.go()
        XCTAssertEqual(move(&l, 1), .moved(2))
        XCTAssertEqual(s.pour, "20 + 31 = 51 hundredths")
        XCTAssertEqual(move(&l, 0.51), .moved(3))
        XCTAssertEqual(l.words.say, "Write the total.")
        XCTAssertEqual(l.words.hint, "The grid shows what goes after the point. Then add the whole numbers.")
        // the ones make 13 without the hundredths: the ten is carried (the web's whole-parts slip, on the total)
        XCTAssertEqual(s.ones, 13)
        XCTAssertEqual(answer(&l, "23"), .notYet("Keep the 0.51 after the point."))
        XCTAssertEqual(l.slips.last?.kind, "k0")
        XCTAssertEqual(answer(&l, "13.51"), .notYet("The ones make 13: carry the 1 ten."))
        XCTAssertEqual(l.slips.last?.kind, "k1")
        XCTAssertEqual(answer(&l, "23.33"), .notYet("0.2 means 2 tenths, which is 20 hundredths. Line up the points."))
        XCTAssertEqual(answer(&l, "23.51"), .moved(4))
        XCTAssertEqual(l.words.say, "Points under points, so tenths add to tenths.")
    }

    /// The ones carry a ten too: the carried 1 from the hundredths counts in the ones column.
    func testTheCarriedOneCountsInTheOnes() {
        let s = parts(18.7, 5.51)
        XCTAssertTrue(s.carries); XCTAssertEqual(s.ones, 14)
        XCTAssertEqual(run(18.7, 5.51).steps[4].answer?.known.map(\.message),
                       ["The full grid is 1 whole: that 1 goes with the whole numbers.", "The ones make 14: carry the 1 ten.",
                        "0.7 means 7 tenths, which is 70 hundredths. Line up the points."])
        XCTAssertEqual(run(18.7, 5.51).steps[4].answer?.known.map { $0.values["x"]! }, [23.21, 14.21, 23.58])
        // 4 + 5 doesn't carry, but with the carried 1 the ones make 10
        let t = parts(4.7, 5.51)
        XCTAssertEqual(t.ones, 10); XCTAssertEqual(t.sum, 10.21, accuracy: 1e-9)
        var l = run(4.7, 5.51); _ = l.go(); _ = move(&l, 1); _ = move(&l, 1.21); _ = move(&l, 1)
        XCTAssertEqual(answer(&l, "0.21"), .notYet("The ones make 10: carry the 1 ten."))
        XCTAssertEqual(answer(&l, "10.21"), .moved(5))
        // the biggest: every column carries, into the hundreds
        let big = parts(99.9, 99.99)
        XCTAssertEqual(big.sum, 199.89, accuracy: 1e-9); XCTAssertEqual(big.ones, 19); XCTAssertEqual(big.tens, 19)
        XCTAssertEqual(big.n, 189); XCTAssertEqual(big.left, 89)
        XCTAssertEqual(big.pour, "90 + 99 = 189 hundredths")
    }

    /// Exactly one whole: the grid fills with nothing left over.
    func testExactlyAWhole() {
        var l = run(12.3, 3.7)
        let s = AddDecimals.Parts(l.numbers)
        XCTAssertTrue(s.carries); XCTAssertEqual(s.left, 0)
        XCTAssertEqual(s.gaps, [AddDecimals.Gap(0, -2), AddDecimals.Gap(1, -2)], "both have tenths only")
        XCTAssertEqual(l.steps[0].words.hint, "Write 12.3 as 12.30 and 3.7 as 3.70 so both numbers have hundredths.")
        _ = l.go()
        XCTAssertEqual(l.words.say, "Tap each empty place after the point to write a 0.")
        XCTAssertEqual(l.steps[1].answer?.explain, "12.3 is 12.30 and 3.7 is 3.70: the same numbers, with hundredths.")
        XCTAssertEqual(move(&l, 2), .moved(2))
        XCTAssertEqual(move(&l, 1), .moved(3))
        XCTAssertEqual(move(&l, 1), .moved(4))
        XCTAssertEqual(l.words.hint, "Nothing is left after the point. Add the ones and the carried 1.")
        XCTAssertEqual(answer(&l, "15"), .notYet("The full grid is 1 whole: that 1 goes with the whole numbers."))
        XCTAssertEqual(answer(&l, "16.00"), .moved(5))
    }

    /// Whole numbers and numbers short of hundredths: the 0s go in every empty place after the point (a whole number's
    /// point is written with them), and a number with no hundredths has none to slide.
    func testZerosAndShortNumbers() {
        let s = parts(2, 1.1)
        XCTAssertEqual(s.gaps, [AddDecimals.Gap(0, -1), AddDecimals.Gap(0, -2), AddDecimals.Gap(1, -2)])
        XCTAssertEqual(s.lineUp, "Write 2 as 2.00 and 1.1 as 1.10 so both numbers have hundredths.")
        XCTAssertEqual(s.digit(0, 0), "2"); XCTAssertNil(s.digit(0, -1)); XCTAssertNil(s.digit(0, 1))
        XCTAssertEqual(s.tapped(0, 1), "No 0 is needed in front of the 2.")
        var l = run(2, 1.1)
        XCTAssertEqual(l.steps.count, 5)
        _ = l.go()
        XCTAssertEqual(l.words.say, "Tap each empty place after the point to write a 0.")
        XCTAssertEqual(move(&l, 3), .moved(2))
        XCTAssertEqual(move(&l, 0.1), .moved(3))
        // a has no tenths: adding them to b's hundredths would be the answer itself, so that slip isn't there
        XCTAssertEqual(l.step.answer?.known.map(\.message), ["Keep the 0.1 after the point.", "That takes away the whole numbers. This one adds."])
        XCTAssertEqual(answer(&l, "3.1"), .moved(4))

        // b a whole number: nothing to slide, so no slide step
        var w = run(4.1, 3)
        XCTAssertEqual(AddDecimals.Parts(w.numbers).gaps, [AddDecimals.Gap(0, -2), AddDecimals.Gap(1, -1), AddDecimals.Gap(1, -2)])
        XCTAssertEqual(w.steps.count, 4)
        _ = w.go(); _ = move(&w, 3)
        XCTAssertEqual(w.words.say, "Write the total.")
        XCTAssertEqual(answer(&w, "7.01"), .notYet("0.1 means 1 tenth, which is 10 hundredths. Line up the points."))
        XCTAssertEqual(answer(&w, "7.1"), .moved(3))
        // both whole: nothing after either point
        let both = run(2, 3)
        XCTAssertEqual(both.steps.count, 4)
        XCTAssertEqual(both.steps[2].answer?.known.map(\.message), ["That takes away the whole numbers. This one adds."])
        // b already has hundredths, and a's 0 is the only one
        XCTAssertEqual(parts(4.15, 2.35).lineUp, "Both already have hundredths, so the points line up.")
        XCTAssertEqual(parts(4.1, 2.35).lineUp, "Write 4.1 as 4.10 so both numbers have hundredths.")
        XCTAssertEqual(AddDecimals.Parts.part(0.5, 1), "0.5"); XCTAssertEqual(AddDecimals.Parts.part(0.5, 2), "0.50")
        XCTAssertEqual(AddDecimals.Parts.part(0, 0), "0"); XCTAssertEqual(AddDecimals.two(16), "16.00")
    }

    func testGeneratorKeepsTheWebRules() {
        var rng = SeededRandom(seed: 11)
        for index in [0, 1, 2, 3, 6] {
            for _ in 0..<300 {
                let n = AddDecimals.spec.generate(&rng, index), a = n["a"]!, b = n["b"]!
                XCTAssertEqual(a * 10, (a * 10).rounded(), accuracy: 1e-9); XCTAssertEqual(b * 100, (b * 100).rounded(), accuracy: 1e-9)
                XCTAssertTrue((1.1...99.9).contains(a) && (1.01...99.99).contains(b), "\(n)")
                if index < 3 { XCTAssertLessThan(a, 10); XCTAssertLessThan(b, 10) }
                let s = AddDecimals.Parts(n)
                XCTAssertEqual(Double(s.W) + s.D, s.sum, accuracy: 1e-9)
                XCTAssertEqual(Double(s.n) / 100, s.D, accuracy: 1e-9)
                XCTAssertEqual(s.na % 10, 0, "a has tenths only: its grid is whole columns")
                XCTAssertFalse(s.gaps.isEmpty, "a always has an empty hundredths place")
                let l = LessonRun(AddDecimals.spec, numbers: n)
                XCTAssertEqual(l.steps.count, 4 + (s.nb > 0 ? 1 : 0) + (s.carries ? 1 : 0))
                XCTAssertEqual(l.steps[1].answer!.expected["x"]!, Double(s.gaps.count))
                if s.nb > 0 { XCTAssertEqual(l.steps[2].answer!.expected["x"]!, s.D, accuracy: 1e-9) }
                let total = l.steps[l.steps.count - 2].answer!
                XCTAssertEqual(total.expected["x"]!, ((a + b) * 100).rounded() / 100, accuracy: 1e-9)
                // the slips: never the answer, never the same number twice, never a point moved (that's its own line)
                let values = total.known.map { $0.values["x"]! }
                XCTAssertFalse(values.contains { abs($0 - s.sum) < 1e-9 }, "\(n)")
                XCTAssertEqual(Set(values.map { ($0 * 100).rounded() }).count, values.count, "\(n)")
                // every step's picture names its stage
                XCTAssertEqual(l.steps.map { $0.picture["at"]! }, [0, 1] + (s.nb > 0 ? [2] : []) + (s.carries ? [3] : []) + [4, 5])
            }
        }
    }

    func testSkillCheckDraws() {
        var rng = SeededRandom(seed: 3)
        let items = AddDecimals.spec.check
        XCTAssertEqual(items.map(\.index), [3, 3, 3, 3]); XCTAssertEqual(items.map(\.story), [false, false, false, true])
        for item in items { for _ in 0..<300 {
            let n = item.draw(AddDecimals.spec, using: &rng)
            XCTAssertTrue(item.when?(n) ?? true, "\(n)")
        } }
    }

    func testTestsAndShowMe() {
        // a test (one try): a wrong move shows the answer, so the picture moves on with it
        var t = run(12.5, 3.75); t.oneTry = true; t.helps = false; _ = t.go(); _ = move(&t, 1); _ = move(&t, 1.25)
        XCTAssertEqual(move(&t, 0), .notYet("That grid has 25 hundredths. Tap the full one."))
        XCTAssertEqual(t.typed["x"], "1")
        XCTAssertEqual(t.go(), .moved(4))
        // Show me is a preview: the step counts as shown, and nothing is written
        var m = run(12.5, 3.75); _ = m.go()
        m.markShown()
        XCTAssertEqual(m.shown, [1]); XCTAssertTrue(m.typed.isEmpty)
        // a story: what to do is picked first, then the lesson's own steps
        let story = LessonRun(AddDecimals.spec, numbers: AddDecimals.numbers(a: 12.5, b: 3.75), story: true)
        XCTAssertEqual(story.steps.first?.answer?.choices?.first, "+ Add")
        XCTAssertEqual(story.steps.count, 7)
    }
}
