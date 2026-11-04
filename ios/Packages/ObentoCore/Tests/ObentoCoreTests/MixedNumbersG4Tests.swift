import XCTest
@testable import ObentoCore

/// 4th grade, chapter 5: Mixed numbers (design/grade4.md, the preview design/prototype/grade4-ch5.html).
final class MixedNumbersG4Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(57 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(4)[4]
        XCTAssertEqual(ch.title, "Mixed numbers")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
        XCTAssertEqual(Mixed4.whole(5), 20)
        XCTAssertEqual(Mixed4.whole(7), 21)
        XCTAssertEqual(Mixed4.whole(8), 24)
        for d in 3...8 { XCTAssertEqual(Mixed4.whole(d) % d, 0) }
        XCTAssertEqual(Mixed4.text(4, 2, 5), "4 2/5")
        XCTAssertEqual(Mixed4.text(0, 3, 5), "3/5")
        XCTAssertEqual(Mixed4.text(3, 0, 4), "3")
    }

    // MARK: Adding mixed numbers

    func testAddWithTrade() {
        var l = LessonRun(AddMixed.spec, numbers: AddMixed.numbers(w1: 2, n1: 3, w2: 1, n2: 4, d: 5))
        XCTAssertEqual(l.steps.count, 6)
        XCTAssertEqual(l.words.say, "Put the wholes together. Slide the striped wholes under the left ones.")
        _ = l.go()
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["s": 0]), .notYet("Put them under the wholes on the left."))
        XCTAssertFalse(l.missedAny)
        XCTAssertEqual(move(&l, ["s": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Now put the fifths together. Slide the striped fifths into the left bar.")
        XCTAssertEqual(move(&l, ["s": 0]), .notYet("Slide them into the left bar."))
        XCTAssertEqual(move(&l, ["s": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "5 fifths fill a bar, so trade them for 1 whole. Tap the full bar.")
        XCTAssertEqual(move(&l, ["t": -1]), .notYet("That bar isn’t full. Tap the full bar."))
        XCTAssertEqual(move(&l, ["t": -2]), .notYet("That’s a whole already. Tap the full bar."))
        XCTAssertEqual(move(&l, ["t": 1]), .moved(4))
        XCTAssertEqual(l.words.say, "Add the new whole to the 3 wholes. Write the wholes, then the pieces.")
        XCTAssertEqual(move(&l, ["W": 3, "N": 7]), .notYet("7/5 is more than 1 whole. Trade 5 fifths for 1 whole first."))
        XCTAssertEqual(move(&l, ["W": 3, "N": 2]), .notYet("The 5 fifths you traded made 1 more whole. Add it: 3 + 1."))
        XCTAssertEqual(move(&l, ["W": 4, "N": 7]), .notYet("5 of the pieces became the whole, so take 5 away: 7 − 5 = 2."))
        XCTAssertEqual(move(&l, ["W": 4, "N": 1]), .notYet("Count the fifths in the last bar."))
        XCTAssertEqual(move(&l, ["W": 5, "N": 2]), .notYet("Count the whole bars on the left."))
        XCTAssertEqual(move(&l, ["W": 4, "N": 2]), .moved(5))
        XCTAssertEqual(l.words.say, "5 fifths make a whole, so 3 wholes become 4.")
    }

    func testAddWithoutTrade() {
        var l = LessonRun(AddMixed.spec, numbers: AddMixed.numbers(w1: 3, n1: 1, w2: 2, n2: 2, d: 4))
        XCTAssertEqual(l.steps.count, 5)
        _ = l.go(); _ = move(&l, ["s": 1]); _ = move(&l, ["s": 1])
        XCTAssertEqual(l.words.say, "Put the wholes and the pieces back together. Write the wholes, then the pieces.")
        XCTAssertEqual(move(&l, ["W": 6, "N": 3]), .notYet("3/4 is less than 1, so there’s no whole to trade."))
        XCTAssertEqual(move(&l, ["W": 7, "N": 3]), .notYet("Count the whole bars on the left."))
        XCTAssertEqual(move(&l, ["W": 5, "N": 3]), .moved(4))
        XCTAssertEqual(l.words.say, "Wholes go with wholes, and pieces with pieces.")
        // the wholes multiplied
        var m = LessonRun(AddMixed.spec, numbers: AddMixed.numbers(w1: 3, n1: 1, w2: 3, n2: 1, d: 3))
        _ = m.go(); _ = move(&m, ["s": 1]); _ = move(&m, ["s": 1])
        XCTAssertEqual(move(&m, ["W": 9, "N": 2]), .notYet("This is adding: 3 + 3."))
    }

    func testAddGenerator() {
        for i in 0..<8 {
            var trades = 0
            each(AddMixed.spec, i) { x in
                let s = AddMixed.Parts(x)
                XCTAssertTrue([3, 4, 5, 6, 8].contains(s.d))
                XCTAssertTrue((1...3).contains(s.w1) && (1...3).contains(s.w2))
                XCTAssertNotEqual(s.S, s.d); XCTAssertEqual(gcd(s.R, s.d), 1)
                if s.trade { trades += 1 }
            }
            if i < 3 { XCTAssertTrue((100...200).contains(trades), "\(trades)") } else { XCTAssertGreaterThan(trades, 190) }
        }
        let c = checks(AddMixed.spec).map(AddMixed.Parts.init)
        XCTAssertFalse(c[0].trade); XCTAssertTrue(c[1].trade); XCTAssertTrue(c[2].trade && c[2].d >= 6)
        XCTAssertTrue(AddMixed.spec.check[3].story)
        XCTAssertEqual(AddMixed.Parts(AddMixed.numbers(w1: 2, n1: 3, w2: 1, n2: 4, d: 5)).text,
                       "Mia walks 2 3/5 miles on Monday and 1 4/5 miles on Tuesday. How far does she walk in all?")
    }

    // MARK: Subtracting mixed numbers

    func testSubtractOpeningAWhole() {
        var l = LessonRun(SubtractMixed.spec, numbers: SubtractMixed.numbers(w1: 3, n1: 2, w2: 1, n2: 4, d: 5))
        XCTAssertEqual(l.steps.count, 7)
        XCTAssertEqual(l.words.say, "Take away the fifths first. Slide the striped fifths onto the shaded ones.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["s": 0]), .notYet("Slide them onto the shaded pieces."))
        // too few: the slide stops, and the next step says why
        XCTAssertEqual(move(&l, ["s": 2]), .moved(2))
        XCTAssertFalse(l.missedAny)
        XCTAssertEqual(l.words.say, "2 fifths can’t take away 4. Open a whole. Tap a whole bar.")
        XCTAssertEqual(move(&l, ["o": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "Now take away the fifths. Slide the striped fifths onto the shaded ones.")
        XCTAssertEqual(move(&l, ["s": 1]), .moved(4))
        XCTAssertEqual(l.words.say, "Now take away the wholes. Slide the striped wholes onto the shaded ones.")
        XCTAssertEqual(move(&l, ["s": 0]), .notYet("Slide them onto the shaded wholes."))
        XCTAssertEqual(move(&l, ["s": 1]), .moved(5))
        XCTAssertEqual(l.words.say, "Write what’s left. Count what isn’t crossed out.")
        XCTAssertEqual(l.step.answer?.boxes, ["W", "N"])
        XCTAssertEqual(move(&l, ["W": 2, "N": 2]), .notYet("You can’t take 4 fifths from 2. Open a whole first."))
        XCTAssertEqual(move(&l, ["W": 2, "N": 3]), .notYet("One whole became fifths, so 3 wholes are 2 now."))
        XCTAssertEqual(move(&l, ["W": 1, "N": 4]), .notYet("Count the fifths that aren’t crossed out."))
        XCTAssertEqual(move(&l, ["W": 1, "N": 3]), .moved(6))
        XCTAssertEqual(l.words.say, "A whole is 5 fifths, so it can be opened to take away.")
    }

    func testSubtractWithEnough() {
        var l = LessonRun(SubtractMixed.spec, numbers: SubtractMixed.numbers(w1: 4, n1: 5, w2: 2, n2: 2, d: 8))
        XCTAssertEqual(l.steps.count, 5)
        _ = l.go()
        XCTAssertEqual(move(&l, ["s": -1]), .notYet("There are enough eighths. Take away first."))
        XCTAssertTrue(l.missedAny)
        XCTAssertEqual(move(&l, ["s": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Now take away the wholes. Slide the striped wholes onto the shaded ones.")
        _ = move(&l, ["s": 1])
        XCTAssertEqual(move(&l, ["W": 2, "N": 3]), .moved(4))
        XCTAssertEqual(l.words.say, "Wholes from wholes, pieces from pieces.")
        // no wholes left: only the fraction is written
        var m = LessonRun(SubtractMixed.spec, numbers: SubtractMixed.numbers(w1: 2, n1: 1, w2: 1, n2: 2, d: 3))
        XCTAssertEqual(SubtractMixed.Parts(m.numbers).Wa, 0)
        _ = m.go(); _ = move(&m, ["s": 3])
        XCTAssertEqual(m.index, 2)
        _ = move(&m, ["o": 1]); _ = move(&m, ["s": 1]); _ = move(&m, ["s": 1])
        XCTAssertEqual(m.step.answer?.boxes, ["N"])
        XCTAssertEqual(move(&m, ["N": 2]), .moved(6))
    }

    func testSubtractGenerator() {
        for i in 0..<8 {
            var opens = 0
            each(SubtractMixed.spec, i) { x in
                let s = SubtractMixed.Parts(x)
                XCTAssertTrue((2...4).contains(s.w1)); XCTAssertTrue((1..<s.w1).contains(s.w2))
                XCTAssertNotEqual(s.n1, s.n2); XCTAssertGreaterThan(s.R, 0); XCTAssertEqual(gcd(s.R, s.d), 1)
                XCTAssertGreaterThanOrEqual(s.Wa, 0)
                if s.need { opens += 1 }
            }
            if i < 3 { XCTAssertTrue((100...200).contains(opens), "\(opens)") } else { XCTAssertGreaterThan(opens, 190) }
        }
        let c = checks(SubtractMixed.spec).map(SubtractMixed.Parts.init)
        XCTAssertFalse(c[0].need); XCTAssertTrue(c[1].need); XCTAssertTrue(c[2].need && c[2].d >= 6)
        XCTAssertEqual(SubtractMixed.Parts(SubtractMixed.numbers(w1: 3, n1: 2, w2: 1, n2: 4, d: 5, story: 0)).text,
                       "A ribbon is 3 2/5 m long. Mia cuts off 1 4/5 m. How much ribbon is left?")
    }

    // MARK: Fraction times a whole number

    func testTimesMixedAnswer() {
        var l = LessonRun(FracTimesWhole.spec, numbers: FracTimesWhole.numbers(n: 2, d: 5, W: 3))
        XCTAssertEqual(l.steps.count, 6)
        XCTAssertEqual(l.words.say, "Put all the groups together. Slide the bars into the answer bar.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["s": 0]), .notYet("Put them in the answer bar."))
        XCTAssertEqual(move(&l, ["s": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "How many fifths in all? The pieces stay the same size.")
        XCTAssertEqual(move(&l, ["T": 15]), .notYet("The pieces stay the same size. Only the number of pieces changes."))
        XCTAssertEqual(move(&l, ["T": 5]), .notYet("Count the fifths in the answer bars."))
        XCTAssertEqual(move(&l, ["T": 6]), .moved(3))
        XCTAssertEqual(l.words.say, "Every 5 fifths make one whole. Tap the full bar.")
        XCTAssertEqual(move(&l, ["t": -1]), .notYet("That bar isn’t full. Tap a full bar."))
        XCTAssertEqual(move(&l, ["t": 1]), .moved(4))
        XCTAssertEqual(l.words.say, "Write it as a mixed number.")
        XCTAssertEqual(l.step.answer?.boxes, ["W", "N", "D"])
        XCTAssertEqual(move(&l, ["W": 1, "N": 2, "D": 5]), .notYet("That’s not equal to 6/5. How many whole 5s fit into 6? That’s the whole number. What’s left over goes on top."))
        XCTAssertEqual(move(&l, ["W": 0, "N": 6, "D": 5]), .notYet("That’s the right amount. Now write it as a mixed number. How many whole 5s fit into 6?"))
        XCTAssertEqual(move(&l, ["W": 1, "N": 1, "D": 0]), .notYet("The bottom can’t be 0."))
        XCTAssertEqual(move(&l, ["W": 1, "N": 1, "D": 5]), .moved(5))
        XCTAssertEqual(l.words.say, "3 groups of 2 fifths make 6 fifths. The pieces stay fifths.")
    }

    func testTimesOtherForms() {
        // a remainder that simplifies: 18/8 = 2 2/8 = 2 1/4
        let r = FracTimesWhole.Parts(FracTimesWhole.numbers(n: 3, d: 8, W: 6))
        XCTAssertTrue(r.recut); XCTAssertEqual([r.whole, r.top, r.bottom], [2, 1, 4])
        var l = LessonRun(FracTimesWhole.spec, numbers: FracTimesWhole.numbers(n: 3, d: 8, W: 6))
        _ = l.go(); _ = move(&l, ["s": 1]); _ = move(&l, ["T": 18])
        XCTAssertEqual(l.words.say, "Every 8 eighths make one whole. Then simplify the 2/8. Tap each full bar, then the last bar.")
        _ = move(&l, ["t": 1])
        XCTAssertEqual(move(&l, ["W": 2, "N": 2, "D": 8]), .notYet("Same amount. 2/8 can still be simplified. Both 2 and 8 divide by 2."))
        XCTAssertEqual(move(&l, ["W": 2, "N": 1, "D": 4]), .moved(5))
        // a whole number: 4 × 3/4 = 3
        var w = LessonRun(FracTimesWhole.spec, numbers: FracTimesWhole.numbers(n: 3, d: 4, W: 4))
        _ = w.go(); _ = move(&w, ["s": 1]); _ = move(&w, ["T": 12])
        XCTAssertEqual(w.words.say, "Every 4 fourths make one whole. Tap each full bar.")
        _ = move(&w, ["t": 1])
        XCTAssertEqual(w.words.say, "Write it as a whole number.")
        XCTAssertEqual(w.step.answer?.boxes, ["W"])
        XCTAssertEqual(move(&w, ["W": 12]), .notYet("That’s not equal to 12/4. How many whole 4s fit into 12? That’s the whole number."))
        XCTAssertEqual(move(&w, ["W": 3]), .moved(5))
        // smaller than a whole that simplifies: 2 × 3/8 = 6/8 = 3/4
        var f = LessonRun(FracTimesWhole.spec, numbers: FracTimesWhole.numbers(n: 3, d: 8, W: 2))
        _ = f.go(); _ = move(&f, ["s": 1]); _ = move(&f, ["T": 6])
        XCTAssertEqual(f.words.say, "Divide the top and the bottom by 2. Tap the answer bar: 2 eighths make 1 fourth.")
        _ = move(&f, ["t": 1])
        XCTAssertEqual(f.words.say, "Write it with the bigger pieces.")
        XCTAssertEqual(f.step.answer?.boxes, ["N", "D"])
        XCTAssertEqual(move(&f, ["N": 2, "D": 4]), .notYet("That’s not equal to 6/8. Divide the top and the bottom by the same number."))
        XCTAssertEqual(move(&f, ["N": 3, "D": 4]), .moved(5))
        // nothing more to write: 2 × 1/5 = 2/5
        var p = LessonRun(FracTimesWhole.spec, numbers: FracTimesWhole.numbers(n: 1, d: 5, W: 2))
        XCTAssertEqual(p.steps.count, 4)
        _ = p.go(); _ = move(&p, ["s": 1])
        XCTAssertEqual(move(&p, ["T": 2]), .moved(3))
        XCTAssertTrue(p.isLast)
    }

    func testTimesGenerator() {
        each(FracTimesWhole.spec, 0) { x in
            let s = FracTimesWhole.Parts(x)
            XCTAssertTrue((3...8).contains(s.d)); XCTAssertTrue((2...6).contains(s.W)); XCTAssertEqual(gcd(s.n, s.d), 1)
            XCTAssertEqual(Mixed4.whole(s.d) % s.d, 0)
        }
        let c = checks(FracTimesWhole.spec).map(FracTimesWhole.Parts.init)
        XCTAssertLessThan(c[0].S, c[0].d); XCTAssertTrue(c[1].S > c[1].d && c[1].rem != 0); XCTAssertEqual(c[2].rem, 0)
        XCTAssertTrue(FracTimesWhole.spec.check[3].story)
    }
}
