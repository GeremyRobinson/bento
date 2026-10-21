import XCTest
@testable import ObentoCore

final class DivideByDecimalTests: XCTestCase {
    private func run(_ d: Int, _ qt: Int) -> LessonRun { LessonRun(DivideByDecimal.spec, numbers: DivideByDecimal.numbers(d: d, qt: qt)) }
    private func answer(_ l: inout LessonRun, _ s: String) -> LessonRun.Outcome {
        l.reset(); for c in s { l.type(String(c)) }; return l.go()
    }

    private func set(_ l: inout LessonRun, _ v: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, x) in v { l.set(k, x) }; return l.go()
    }

    /// The web lesson's reference, 4.8 ÷ 0.6 = 8, on the paper: the hops laid along the line, then 48 ÷ 6 written.
    func testWalkThroughTheReference() {
        var l = run(6, 8)
        XCTAssertEqual(DivideByDecimal.spec.master, "double-line")
        XCTAssertEqual(l.display, [.num(4.8), .op("÷"), .num(0.6)])
        XCTAssertEqual(l.words.say, "Each square on the line is a tenth.")
        XCTAssertEqual(l.picture, ["at": 0])
        XCTAssertEqual(l.go(), .moved(1))

        // the hops, set from the hand: past the end and short of it are measured
        XCTAssertEqual(l.words.say, "Hop along the line from 0 to the end. Tap, or drag.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(set(&l, ["h": 9]), .notYet("9 hops of 0.6 reach 5.4. That’s past 4.8."))
        XCTAssertEqual(set(&l, ["h": 5]), .notYet("5 hops of 0.6 reach 3. Hop on to 4.8."))
        XCTAssertEqual(l.picture["ring"], 1, "a miss rings the end")
        XCTAssertEqual(l.showAnswer(), "8 hops of 0.6 reach 4.8.")
        XCTAssertEqual(set(&l, ["h": 8]), .moved(2))

        // the one number school writes: the web's divide step and its slips
        XCTAssertEqual(l.words.say, "Read the hops in tenths, under the line. Write the answer.")
        XCTAssertEqual(l.words.hint, "Now it’s whole numbers: divide.")
        XCTAssertEqual(answer(&l, "0.8"), .notYet("Both numbers got 10 times bigger, so the answer is the same. Don’t move the point back."))
        XCTAssertEqual(answer(&l, "288"), .notYet("How many 6s fit in 48? That’s dividing."))
        XCTAssertEqual(answer(&l, "7"), .notYet("Not quite. How many 6s make 48?"))
        XCTAssertEqual(l.showAnswer(), "How many 6s make 48? That makes 8.")
        XCTAssertEqual(l.steps[2].answer?.work, [.num(4.8), .op("÷"), .num(0.6), .op("="), .num(48), .op("÷"), .num(6), .op("="), .num(8)])
        XCTAssertEqual(l.go(), .moved(3))

        // the last words say why, not the sum again
        XCTAssertEqual(l.words.say, "The same hops in tenths: 48 ÷ 6.")
        XCTAssertEqual(l.words.hint, "Making both numbers ten times bigger doesn’t change how many times one fits in the other.")
        XCTAssertEqual(l.picture, ["at": 3])
        XCTAssertEqual(l.go(), .newProblem)
        XCTAssertEqual(DivideByDecimal.spec.story?(l.numbers), "You have 4.8 liters of juice. Each cup holds 0.6 liters. How many cups can you fill?")
        XCTAssertEqual(DivideByDecimal.spec.depends, ["g5-pow10", "g3-divfacts"])
    }

    func testHopsMeasuredOnTheLine() {
        let s = DivideByDecimal.Parts(DivideByDecimal.numbers(d: 9, qt: 12))
        XCTAssertEqual(DivideByDecimal.hopVerdict(nil, s), .soft("Tap the line to hop 0.9 from 0."))
        XCTAssertEqual(DivideByDecimal.hopVerdict(1, s), .wrong("1 hop of 0.9 reaches 0.9. Hop on to 10.8."))
        XCTAssertEqual(DivideByDecimal.hopVerdict(12, s), .right)
        XCTAssertEqual(DivideByDecimal.hopVerdict(13, s), .wrong("13 hops of 0.9 reach 11.7. That’s past 10.8."))
    }

    func testGeneratorKeepsTheWebRules() {
        var rng = SeededRandom(seed: 11)
        for _ in 0..<300 {
            let n = DivideByDecimal.spec.generate(&rng, 0), s = DivideByDecimal.Parts(n)
            XCTAssertTrue((2...9).contains(s.d) && (2...12).contains(s.qt))
            XCTAssertEqual(s.x / s.y, Double(s.qt), accuracy: 1e-9, "the answer is always the whole number qt")
            XCTAssertEqual(s.x * 10, Double(s.n), accuracy: 1e-9)
            XCTAssertEqual(LessonRun(DivideByDecimal.spec, numbers: n).steps[2].answer?.expected["x"], Double(s.qt))
        }
    }

    func testSkillCheckDraws() {
        var rng = SeededRandom(seed: 3)
        let items = DivideByDecimal.spec.check
        XCTAssertEqual(items.map(\.index), [0, 0, 0, 0]); XCTAssertEqual(items.map(\.story), [false, false, false, true])
        for item in items { for _ in 0..<300 {
            let n = item.draw(DivideByDecimal.spec, using: &rng)
            XCTAssertTrue(item.when?(n) ?? true, "\(n)")
        } }
    }
}
