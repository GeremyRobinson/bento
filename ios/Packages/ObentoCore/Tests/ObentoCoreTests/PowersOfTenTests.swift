import XCTest
@testable import ObentoCore

final class PowersOfTenTests: XCTestCase {
    private func run(_ x: Double, _ k: Int) -> LessonRun { LessonRun(PowersOfTen.spec, numbers: PowersOfTen.numbers(x: x, k: k)) }
    /// Clears the step's boxes, types `s` into the first one and checks.
    private func answer(_ l: inout LessonRun, _ s: String) -> LessonRun.Outcome {
        l.reset(); for c in s { l.type(String(c)) }; return l.go()
    }
    /// A hand move: its value in the box, checked at once (as letting go of the digits, or the last tap, does).
    private func move(_ l: inout LessonRun, _ v: Double) -> LessonRun.Outcome { l.set("x", v); return l.go() }

    /// The web's reference: 3.47 × 100 = 347, no empty place to fill.
    func testWalkThroughTheReference() {
        var l = run(3.47, 2)
        let s = PowersOfTen.Parts(l.numbers)
        XCTAssertEqual(PowersOfTen.spec.master, "shift")
        XCTAssertEqual(l.display, [.num(3.47), .op("×"), .num(100)])
        // the number is the chart's digits: the words only say what it's multiplied by
        XCTAssertEqual(l.words.say, "Multiply by 100.")
        XCTAssertEqual(l.words.action, "Let’s find out")
        XCTAssertEqual(l.picture["at"], 0)
        XCTAssertEqual(s.digits, ["3", "4", "7"]); XCTAssertEqual(s.whole, 1); XCTAssertEqual(s.decimals, 2)
        XCTAssertEqual(s.lead, 0); XCTAssertEqual(s.gaps, [])
        // the chart: the ten thousands to the hundredths, whatever it's multiplied by; the 3 can go 4 places, one too far
        XCTAssertEqual(s.columns, [4, 3, 2, 1, 0, -1, -2]); XCTAssertEqual(s.most, 4)
        XCTAssertEqual(l.steps.count, 4, "nothing to fill: no step for the 0s")
        XCTAssertEqual(l.go(), .moved(1))

        // drag the digits left: the places moved are the zeros counted
        XCTAssertEqual(l.words.say, "Multiply by 100. Drag the digits left.")
        XCTAssertEqual(l.words.hint, "Each zero moves every digit one place.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(l.picture["at"], 1)
        XCTAssertEqual(move(&l, 0), .notYet("They didn’t move. Drag them left."))
        XCTAssertEqual(l.misses, 0, "let go where they were: a notice, not a miss")
        XCTAssertEqual(move(&l, 3), .notYet("That’s × 1000. × 100 moves every digit 2 places."))
        XCTAssertEqual(l.misses, 1)
        XCTAssertEqual(l.slips.last?.kind, "k0", "the web's slip: one place too far, the 1 counted")
        XCTAssertEqual(l.picture["target"], 1, "a miss shows the hops the digits make")
        XCTAssertEqual(move(&l, 1), .notYet("That’s × 10. × 100 moves every digit 2 places."))
        XCTAssertEqual(l.slips.last?.kind, "wrong")
        XCTAssertEqual(move(&l, 2), .moved(2))

        // the record: 3.47 × 100 = [347], typed; the chart shows 347 by now, so a slip is said of the chart
        XCTAssertEqual(l.words.say, "Write the new number.")
        XCTAssertFalse(l.handAnswered)
        XCTAssertEqual(l.picture["at"], 3)
        XCTAssertEqual(answer(&l, "0.0347"), .notYet("Multiplying by 100 makes the number bigger, so the digits move left."))
        XCTAssertEqual(l.slips.last?.kind, "k0", "moving the wrong way: the first known slip on every problem")
        // no 0 written and no digit after the point: nothing on the chart was left out, so it just isn't its number
        XCTAssertEqual(answer(&l, "34.7"), .notYet("That’s not the number on the chart."))
        XCTAssertEqual(answer(&l, "3470"), .notYet("That’s not the number on the chart."))
        XCTAssertEqual(answer(&l, "348"), .notYet("That’s not the number on the chart."))
        XCTAssertEqual(l.slips.last?.kind, "wrong")
        XCTAssertEqual(l.picture["read"], 1, "a miss outlines the new number on the chart")
        XCTAssertEqual(l.steps[2].answer?.work, [.num(3.47), .op("×"), .num(100), .op("="), .num(347)])
        // a problem aimed at a slip here starts with what to keep in mind: the chart has the number
        XCTAssertEqual(LessonPlan.advice(PowersOfTen.spec, l.numbers, step: 2), "Write the number the chart shows.")
        XCTAssertEqual(LessonPlan.advice(PowersOfTen.spec, l.numbers, step: 1), "100 has 2 zeros: every digit moves 2 places.")
        XCTAssertEqual(answer(&l, "347.0"), .moved(3), "the same number, however it's written")

        // done: the last words say why, the rule under the record
        XCTAssertEqual(l.words.say, "Each zero moves every digit one place bigger.")
        XCTAssertEqual(l.picture["at"], 4)
        XCTAssertEqual(s.rule, "2 zeros: 2 places bigger")
        XCTAssertEqual(l.go(), .newProblem)
        XCTAssertEqual(PowersOfTen.spec.idea(l.numbers), "Times 100 makes each digit worth a hundred times more, so every digit moves two places left.")
        XCTAssertEqual(PowersOfTen.spec.depends, ["g4-dec", "g4-placevalue"])
    }

    /// The tricky part (the web's first problem): the digits run past the point, and each place left empty between
    /// them and the point gets a 0.
    func testZerosGoInTheGaps() {
        XCTAssertEqual(PowersOfTen.Parts(PowersOfTen.numbers(x: 4.7, k: 2)).gaps, [0])
        XCTAssertEqual(PowersOfTen.Parts(PowersOfTen.numbers(x: 3.4, k: 3)).gaps, [1, 0], "tens, then ones, as the chart has them")
        XCTAssertEqual(PowersOfTen.Parts(PowersOfTen.numbers(x: 5, k: 3)).gaps, [2, 1, 0])
        XCTAssertEqual(PowersOfTen.Parts(PowersOfTen.numbers(x: 3.47, k: 3)).gaps, [0])
        XCTAssertEqual(PowersOfTen.Parts(PowersOfTen.numbers(x: 3.47, k: 1)).gaps, [], "34.7: the point stays between the digits")

        var l = run(3.4, 3)
        let s = PowersOfTen.Parts(l.numbers)
        XCTAssertEqual(l.steps.count, 5)
        _ = l.go()
        XCTAssertEqual(move(&l, 3), .moved(2))
        XCTAssertEqual(l.words.say, "Tap each gap to write a 0.")
        XCTAssertEqual(l.words.hint, "Every place between the digits and the point needs a digit.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(l.picture["at"], 2)
        // moved, the 3 is in the thousands and the 4 in the hundreds
        XCTAssertEqual(s.digit(at: 3, by: 3), "3"); XCTAssertEqual(s.digit(at: 2, by: 3), "4"); XCTAssertNil(s.digit(at: 1, by: 3))
        // a tap that isn't on a gap says what's there, and isn't a miss
        XCTAssertEqual(move(&l, PowersOfTen.tapCode(2)), .notYet("That place has a 4 in it."))
        XCTAssertEqual(move(&l, PowersOfTen.tapCode(-1)), .notYet("No 0 is needed after the point."))
        XCTAssertEqual(move(&l, PowersOfTen.tapCode(4)), .notYet("No 0 is needed in front of the 3."))
        XCTAssertEqual(l.misses, 0)
        XCTAssertEqual(l.steps[2].answer?.explain, "The tens and ones places are empty: a 0 goes in each.")
        // the last gap filled answers it: how many 0s were written
        XCTAssertEqual(move(&l, 2), .moved(3))
        // the record: the 0s just written are on the chart, so leaving them out is said of them
        XCTAssertEqual(answer(&l, "340"), .notYet("The 0s in the tens and ones places are part of the number."))
        XCTAssertEqual(l.slips.last?.kind, "k1")
        XCTAssertEqual(answer(&l, "34"), .notYet("The 0s in the tens and ones places are part of the number."), "both left out")
        XCTAssertEqual(answer(&l, "34000"), .notYet("That’s not the number on the chart."))
        XCTAssertEqual(answer(&l, "3400"), .moved(4))
        XCTAssertEqual(s.rule, "3 zeros: 3 places bigger")

        // the first problem's kind: one gap, the ones
        var f = run(4.7, 2); _ = f.go(); _ = move(&f, 2)
        XCTAssertEqual(f.steps[2].answer?.explain, "The ones place is empty: a 0 goes in it.")
        XCTAssertEqual(move(&f, 1), .moved(3))
        XCTAssertEqual(answer(&f, "47"), .notYet("The 0 in the ones place is part of the number."), "the 0 left out: the tricky part")
        XCTAssertEqual(answer(&f, "470"), .moved(4))
    }

    /// How far the digits can go, and what each move says.
    func testMovesAndWhatTheySay() {
        let small = PowersOfTen.Parts(PowersOfTen.numbers(x: 1.01, k: 1)), big = PowersOfTen.Parts(PowersOfTen.numbers(x: 99.99, k: 3))
        XCTAssertEqual(small.columns, [4, 3, 2, 1, 0, -1, -2], "the ten thousands to the hundredths, times 10 as times 1000")
        XCTAssertEqual(small.most, 4, "a ones digit can go 4 places: one too far, even times 1000")
        XCTAssertEqual(big.columns, [4, 3, 2, 1, 0, -1, -2], "the same chart")
        XCTAssertEqual(big.most, 3, "a tens digit as far as the ten thousands")
        XCTAssertEqual(big.answer, 99990)
        XCTAssertEqual(big.digit(at: 4, by: 3), "9"); XCTAssertEqual(big.digit(at: 1, by: 3), "9"); XCTAssertNil(big.digit(at: 0, by: 3))
        XCTAssertEqual(big.gaps, [0], "99990: the ones get a 0")
        XCTAssertEqual(PowersOfTen.Parts.times(1), "× 10"); XCTAssertEqual(PowersOfTen.Parts.times(4), "× 10000")
        XCTAssertEqual(small.moved(2), "That’s × 100. × 10 moves every digit 1 place.")
        XCTAssertEqual(small.rule, "1 zero: 1 place bigger")
        XCTAssertEqual(PowersOfTen.placeName(4), "ten thousands"); XCTAssertEqual(PowersOfTen.placeName(-2), "hundredths")
        // a whole number: no point among its digits, but the chart's point is still there
        let whole = PowersOfTen.Parts(PowersOfTen.numbers(x: 12, k: 2))
        XCTAssertEqual(whole.decimals, 0); XCTAssertEqual(whole.gaps, [1, 0]); XCTAssertEqual(whole.answer, 1200)
        XCTAssertEqual(whole.columns, [4, 3, 2, 1, 0, -1], "the tenths too, so the point has a place each side")
        // times 10, a decimal answer: the point is still among the digits, and leaving it out is said of the chart
        var t = run(3.47, 1); _ = t.go()
        XCTAssertEqual(move(&t, 1), .moved(2))
        XCTAssertEqual(answer(&t, "347"), .notYet("The point stays where it is on the chart: the 7 is after it."))
        XCTAssertEqual(t.slips.last?.kind, "k1")
        XCTAssertEqual(answer(&t, "3.47"), .notYet("That’s not the number on the chart."), "the number as it was")
        XCTAssertEqual(answer(&t, "0.347"), .notYet("Multiplying by 10 makes the number bigger, so the digits move left."))
        XCTAssertEqual(answer(&t, "34.7"), .moved(3))
    }

    func testGeneratorKeepsTheWebRules() {
        var rng = SeededRandom(seed: 11)
        for index in 0..<7 {
            for _ in 0..<300 {
                let n = PowersOfTen.spec.generate(&rng, index), s = PowersOfTen.Parts(n)
                XCTAssertTrue((1.01...99.99).contains(s.x) && (1...3).contains(s.k), "\(n)")
                XCTAssertEqual(s.x * 100, (s.x * 100).rounded(), accuracy: 1e-9)
                if index == 0 {
                    // a one-digit whole part with tenths, times 100: one 0 to write
                    XCTAssertEqual(s.k, 2); XCTAssertEqual(s.whole, 1); XCTAssertEqual(s.decimals, 1, "\(n)"); XCTAssertEqual(s.gaps, [0])
                } else if index < 3 {
                    XCTAssertEqual(s.k, 1); XCTAssertLessThan(s.x, 10)
                }
                // every move fits the chart: the first digit lands by the ten thousands, and the chart has its place
                XCTAssertLessThanOrEqual(s.lead + s.k, 4)
                XCTAssertGreaterThanOrEqual(s.most, s.k)
                XCTAssertTrue(s.columns.count == 6 || s.columns.count == 7, "\(n)")
                // the chart never says how far to go: the same for × 10, × 100 and × 1000 of the number
                for other in 1...3 { XCTAssertEqual(PowersOfTen.Parts(PowersOfTen.numbers(x: s.x, k: other)).columns, s.columns, "\(n)") }
                // one place too far can always be dragged, but for a tens digit times 1000 (it lands on the chart's
                // first place, the ten thousands, the biggest any answer needs)
                XCTAssertTrue(s.most > s.k || (s.whole == 2 && s.k == 3), "\(n)")
                let l = LessonRun(PowersOfTen.spec, numbers: n)
                XCTAssertEqual(l.steps.count, s.gaps.isEmpty ? 4 : 5)
                XCTAssertEqual(l.steps.last(where: { $0.answer != nil })?.answer?.expected["x"] ?? 0, s.x * s.m, accuracy: 1e-9)
            }
        }
    }

    func testSkillCheckDraws() {
        var rng = SeededRandom(seed: 3)
        let items = PowersOfTen.spec.check
        XCTAssertEqual(items.map(\.index), [3, 3, 3, 3])
        for item in items { for _ in 0..<300 {
            let n = item.draw(PowersOfTen.spec, using: &rng)
            XCTAssertTrue(item.when?(n) ?? true, "\(n)")
        } }
    }

    /// At the record step the chart already shows the digits moved and the 0s written: the child is copying a number,
    /// so its slips are what can be left out of it (a 0 written in a gap, or the point), said of the chart.
    func testRecordSlipsAreSaidOfTheChart() {
        func parts(_ x: Double, _ k: Int) -> PowersOfTen.Parts { PowersOfTen.Parts(PowersOfTen.numbers(x: x, k: k)) }
        XCTAssertEqual(parts(4.7, 2).zerosLeftOut, "The 0 in the ones place is part of the number.")
        XCTAssertEqual(parts(3.4, 3).zerosLeftOut, "The 0s in the tens and ones places are part of the number.")
        XCTAssertEqual(parts(12, 3).zerosLeftOut, "The 0s in the hundreds, tens and ones places are part of the number.")
        XCTAssertNil(parts(3.47, 2).zerosLeftOut, "347: no gaps")
        XCTAssertEqual(parts(3.47, 1).pointLeftOut, "The point stays where it is on the chart: the 7 is after it.")
        XCTAssertEqual(parts(10.05, 1).pointLeftOut, "The point stays where it is on the chart: the 5 is after it.")
        XCTAssertNil(parts(4.7, 2).pointLeftOut, "470: a whole number")
        XCTAssertEqual(PowersOfTen.list(["tens", "ones"]), "tens and ones")
        XCTAssertEqual(PowersOfTen.list(["ones"]), "ones")

        // every problem: moving the wrong way is the first known slip; then a 0 left out (when 0s were written) or the
        // point left out (when the answer has decimals), never both
        var rng = SeededRandom(seed: 5)
        for index in 0..<7 { for _ in 0..<200 {
            let n = PowersOfTen.spec.generate(&rng, index), s = PowersOfTen.Parts(n)
            XCTAssertFalse(s.zerosLeftOut != nil && s.pointLeftOut != nil, "\(n)")
            let l = LessonRun(PowersOfTen.spec, numbers: n)
            guard let known = l.steps.first(where: { $0.answer?.prompt.contains(.op("=")) == true })?.answer?.known else { XCTFail("\(n)"); continue }
            XCTAssertEqual(known.first?.values["x"] ?? 0, s.x / s.m, accuracy: 1e-9)
            XCTAssertEqual(known.count, 1 + s.gaps.count + (s.pointLeftOut == nil ? 0 : 1), "\(n)")
            for slip in known.dropFirst() {
                let v = slip.values["x"] ?? 0
                XCTAssertNotEqual(v, s.answer, accuracy: 1e-9)
                XCTAssertEqual(slip.message, v < s.answer ? s.zerosLeftOut : s.pointLeftOut, "\(n)")
            }
        } }
    }

    func testTestsAndShowMe() {
        // a test (one try): a wrong move shows the answer, so the digits are drawn moved before it goes on
        var t = run(4.7, 2); t.oneTry = true; t.helps = false; _ = t.go()
        XCTAssertEqual(move(&t, 3), .notYet("That’s × 1000. × 100 moves every digit 2 places."))
        XCTAssertEqual(t.typed["x"], "2")
        XCTAssertEqual(t.go(), .moved(2))
        // Show me is a preview: the step counts as shown, and nothing is written
        var m = run(4.7, 2); _ = m.go()
        m.markShown()
        XCTAssertEqual(m.shown, [1]); XCTAssertTrue(m.typed.isEmpty)
        // typing in the record: a lone point gets its 0, and only one point
        var l = run(1.5, 3); _ = l.go(); _ = move(&l, 3); _ = move(&l, 2)
        XCTAssertEqual(l.words.say, "Write the new number.")
        l.reset(); l.type("."); l.type("5"); l.type(".")
        XCTAssertEqual(l.typed["x"], "0.5")
        XCTAssertEqual(PowersOfTen.digits(4.06).digits, "406")
        XCTAssertEqual(fmt(3.40), "3.4"); XCTAssertEqual(fmt(-2), "−2"); XCTAssertEqual(fmt(1500), "1500")
    }
}
