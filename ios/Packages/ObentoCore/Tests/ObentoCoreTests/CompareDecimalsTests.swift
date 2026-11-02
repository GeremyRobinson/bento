import XCTest
@testable import ObentoCore

final class CompareDecimalsTests: XCTestCase {
    private func run(_ a: Int, _ la: Int, _ b: Int, _ lb: Int) -> LessonRun {
        LessonRun(CompareDecimals.spec, numbers: CompareDecimals.numbers(a: a, la: la, b: b, lb: lb))
    }
    /// A hand move: its boxes set (as the tap does), checked.
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }

    /// The design's own: 0.47 or 0.407? Both have 4 tenths; 7 hundredths are more than 0, and the shorter one is bigger.
    func testWalkThroughHundredths() {
        let spec = CompareDecimals.spec
        XCTAssertEqual(spec.id, "g5-compare"); XCTAssertEqual(spec.title, "Comparing decimals")
        XCTAssertEqual(spec.depends, ["g4-dec", "g4-placevalue"])
        var l = run(470, 2, 407, 3)
        let p = CompareDecimals.Parts(l.numbers)
        XCTAssertEqual(p.As, "0.47"); XCTAssertEqual(p.Bs, "0.407"); XCTAssertEqual(p.d, 2)
        XCTAssertTrue(p.aBigger); XCTAssertTrue(p.fewer); XCTAssertEqual(p.sign, ">")
        XCTAssertEqual(l.display, [.num(0.47), .text("or"), .num(0.407)])
        XCTAssertEqual(l.steps.count, 5, "ask, the tenth they share, each one's hundredth, the sign, done")
        XCTAssertEqual(l.words.say, "Which is bigger, 0.47 or 0.407?")
        XCTAssertEqual(l.picture, ["st": 0, "lv": 0])
        XCTAssertEqual(l.go(), .moved(1))

        // the tenth both are in: line 0 is 0 to 1, in tenths
        XCTAssertEqual(l.words.say, "Which is bigger, 0.47 or 0.407? Tap the tenth they’re both in.")
        XCTAssertEqual(l.words.hint, "Both have 4 in the tenths place.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(p.lineEnds(0).0, "0"); XCTAssertEqual(p.lineEnds(0).1, "1")
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("They aren’t between 0.3 and 0.4."))
        XCTAssertEqual(l.picture["ring"], 1, "a miss rings the place in the stacked numbers")
        XCTAssertEqual(move(&l, ["x": 0]), .notYet("They aren’t between 0 and 0.1."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(2))

        // it opens into hundredths: 0.4 to 0.5; each one's block
        XCTAssertEqual(p.lineEnds(1).0, "0.4"); XCTAssertEqual(p.lineEnds(1).1, "0.5")
        XCTAssertEqual(l.words.say, "Tap the hundredth each one is in. Their tenths match, so look closer.")
        XCTAssertEqual(l.words.hint, "0.47 has 7 hundredths. 0.407 has 0 hundredths.")
        XCTAssertEqual(l.picture, ["st": 2, "lv": 1])
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        XCTAssertEqual(l.misses, 0)
        // a block that holds neither: both boxes are set to it
        XCTAssertEqual(move(&l, ["a": 5, "b": 5]), .notYet("Neither number is between 0.45 and 0.46."))
        XCTAssertEqual(move(&l, ["a": 7, "b": 0]), .moved(3))

        // the sign: the open mouth faces the bigger one
        XCTAssertEqual(l.words.say, "Which is bigger? Tap < or >.")
        XCTAssertEqual(move(&l, ["s": 0]), .notYet("Look at the hundredths: 7 and 0. The open mouth faces the bigger one."))
        XCTAssertEqual(move(&l, ["s": 1]), .moved(4))

        // the last words say why
        XCTAssertEqual(l.words.say, "0.47 is bigger. Both have 4 tenths. 7 hundredths are more than 0. Fewer digits, still bigger.")
        XCTAssertEqual(l.words.action, "Next problem")
        XCTAssertEqual(l.go(), .newProblem)
    }

    /// Tenths decide at once: the tenths' line is the only line, and the split is the first step.
    func testTenthsAndWholes() {
        var l = run(3500, 1, 3490, 2)
        let p = CompareDecimals.Parts(l.numbers)
        XCTAssertEqual(p.As, "3.5"); XCTAssertEqual(p.Bs, "3.49"); XCTAssertEqual(p.d, 1); XCTAssertEqual(p.whole, 3)
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(p.lineEnds(0).0, "3"); XCTAssertEqual(p.lineEnds(0).1, "4")
        _ = l.go()
        XCTAssertEqual(l.words.say, "Which is bigger, 3.5 or 3.49? Tap the tenth each one is in.")
        XCTAssertEqual(move(&l, ["a": 2, "b": 2]), .notYet("Neither number is between 3.2 and 3.3."))
        XCTAssertEqual(move(&l, ["a": 5, "b": 4]), .moved(2))
        XCTAssertEqual(move(&l, ["s": 0]), .notYet("Look at the tenths: 5 and 4. The open mouth faces the bigger one."))
        XCTAssertEqual(move(&l, ["s": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "3.5 is bigger. Both have 3 wholes. 5 tenths are more than 4. Fewer digits, still bigger.")
        // one whole, one tenth: no plural
        XCTAssertEqual(CompareDecimals.Parts(CompareDecimals.numbers(a: 1200, la: 1, b: 1100, lb: 1)).why, "Both have 1 whole. 2 tenths are more than 1.")
        XCTAssertEqual(CompareDecimals.Parts(CompareDecimals.numbers(a: 100, la: 1, b: 200, lb: 1)).why, "2 tenths are more than 1.")
    }

    /// Thousandths: two shared lines, then the thousandths; the smaller one first gets <.
    func testThousandths() {
        var l = run(452, 3, 459, 3)
        let p = CompareDecimals.Parts(l.numbers)
        XCTAssertEqual(p.d, 3); XCTAssertEqual(p.sign, "<"); XCTAssertFalse(p.fewer)
        XCTAssertEqual(l.steps.count, 6)
        _ = l.go()
        XCTAssertEqual(l.words.say, "Which is bigger, 0.452 or 0.459? Tap the tenth they’re both in.")
        XCTAssertEqual(move(&l, ["x": 4]), .moved(2))
        XCTAssertEqual(l.words.say, "Which is bigger, 0.452 or 0.459? Tap the hundredth they’re both in.")
        XCTAssertEqual(l.picture, ["st": 1, "lv": 1])
        XCTAssertEqual(move(&l, ["x": 0]), .notYet("They aren’t between 0.4 and 0.41."))
        XCTAssertEqual(move(&l, ["x": 5]), .moved(3))
        XCTAssertEqual(l.words.say, "Tap the thousandth each one is in. Their hundredths match, so look closer.")
        XCTAssertEqual(p.lineEnds(2).0, "0.45"); XCTAssertEqual(p.lineEnds(2).1, "0.46")
        XCTAssertEqual(move(&l, ["a": 1, "b": 1]), .notYet("Neither number is between 0.451 and 0.452."))
        XCTAssertEqual(move(&l, ["a": 2, "b": 9]), .moved(4))
        XCTAssertEqual(move(&l, ["s": 1]), .notYet("Look at the thousandths: 2 and 9. The open mouth faces the bigger one."))
        XCTAssertEqual(move(&l, ["s": 0]), .moved(5))
        XCTAssertEqual(l.words.say, "0.459 is bigger. Both have 4 tenths and 5 hundredths. 9 thousandths are more than 2.")
    }

    /// The preview's generator: the same whole, first different in place d, no number ending in 0, never equal; the
    /// shorter one is often the bigger.
    func testGenerator() {
        var rng = SeededRandom(seed: 3)
        var places = Set<Int>(), wholes = Set<Int>(), shorterBigger = 0
        for i in 0..<400 {
            let n = CompareDecimals.spec.generate(&rng, i % 8)
            let p = CompareDecimals.Parts(n)
            XCTAssertNotEqual(p.NA, p.NB)
            XCTAssertEqual(p.NA / 1000, p.NB / 1000, "the same whole")
            XCTAssertLessThanOrEqual(p.whole, 9)
            XCTAssertTrue(p.la >= p.d && p.lb >= p.d, "both written to the place that decides")
            XCTAssertNotEqual(p.digitA(p.la - 1), 0); XCTAssertNotEqual(p.digitB(p.lb - 1), 0)
            for j in 0..<(p.d - 1) { XCTAssertEqual(p.digitA(j), p.digitB(j)) }
            XCTAssertNotEqual(p.digitA(p.d - 1), p.digitB(p.d - 1))
            // the digits past a number's length are 0
            XCTAssertEqual(p.NA % CompareDecimals.Parts.size(p.la), 0); XCTAssertEqual(p.NB % CompareDecimals.Parts.size(p.lb), 0)
            XCTAssertEqual(Double(p.As), Double(p.NA) / 1000); XCTAssertEqual(Double(p.Bs), Double(p.NB) / 1000)
            places.insert(p.d); wholes.insert(p.whole)
            if p.fewer { shorterBigger += 1 }
            // the steps follow: one tap per shared place, then each one's block, the sign and done
            let l = LessonRun(CompareDecimals.spec, numbers: n)
            XCTAssertEqual(l.steps.count, p.d + 3)
        }
        XCTAssertEqual(places, [1, 2, 3])
        XCTAssertTrue(wholes.contains(0) && wholes.count > 3)
        XCTAssertGreaterThan(shorterBigger, 100, "the trap comes up often")
        // the test's own: each place, and the trap
        for (k, item) in CompareDecimals.spec.check.enumerated() {
            var r = SeededRandom(seed: UInt64(k))
            let p = CompareDecimals.Parts(item.draw(CompareDecimals.spec, using: &r))
            if k < 3 { XCTAssertEqual(p.d, k + 1) } else { XCTAssertTrue(p.fewer) }
        }
    }

    /// Every step's right answers walk any problem to its end.
    func testRightAnswersWalkEveryProblem() {
        var rng = SeededRandom(seed: 8)
        for _ in 0..<60 {
            var l = LessonRun(CompareDecimals.spec, numbers: CompareDecimals.spec.generate(&rng, 3))
            _ = l.go()
            while !l.isLast {
                let a = try! XCTUnwrap(l.step.answer)
                for (k, v) in a.expected { l.set(k, v) }
                let next = l.index + 1
                XCTAssertEqual(l.go(), .moved(next))
            }
        }
    }
}
