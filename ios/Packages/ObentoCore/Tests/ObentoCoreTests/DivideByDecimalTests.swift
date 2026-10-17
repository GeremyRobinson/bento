import XCTest
@testable import ObentoCore

final class DivideByDecimalTests: XCTestCase {
    private func run(_ d: Int, _ qt: Int) -> LessonRun { LessonRun(DivideByDecimal.spec, numbers: DivideByDecimal.numbers(d: d, qt: qt)) }
    private func answer(_ l: inout LessonRun, _ s: String) -> LessonRun.Outcome {
        l.reset(); for c in s { l.type(String(c)) }; return l.go()
    }

    /// The web lesson's reference: 4.8 ÷ 0.6 = 8.
    func testWalkThroughTheReference() {
        var l = run(6, 8)
        XCTAssertEqual(DivideByDecimal.spec.master, "double-line")
        XCTAssertEqual(l.display, [.num(4.8), .op("÷"), .num(0.6)])
        XCTAssertEqual(l.words.say, "What is 4.8 ÷ 0.6?")
        XCTAssertEqual(l.go(), .moved(1))

        XCTAssertEqual(l.words.say, "Make the divisor whole.")
        XCTAssertEqual(l.words.hint, "Make the divisor a whole number.")
        XCTAssertEqual(answer(&l, "60"), .notYet("Times 10 moves the point one place."))
        XCTAssertEqual(answer(&l, "0.06"), .notYet("Times 10 makes it bigger: the point moves right."))
        XCTAssertEqual(l.showAnswer(), "Move its decimal point one place right. That makes 6.")
        XCTAssertEqual(l.steps[1].answer?.work, [.num(0.6), .op("×"), .num(10), .op("="), .num(6)])
        XCTAssertEqual(l.go(), .moved(2))

        XCTAssertEqual(l.words.say, "Do the same to the other number.")
        XCTAssertEqual(l.words.hint, "Do the same to 4.8, so the answer doesn’t change.")
        XCTAssertEqual(answer(&l, "4.8"), .notYet("Multiply both numbers by 10."))
        XCTAssertEqual(l.showAnswer(), "Multiply it by 10 too, so the answer doesn’t change. That makes 48.")
        XCTAssertEqual(l.picture["one"], 1)
        XCTAssertEqual(l.go(), .moved(3))

        XCTAssertEqual(l.words.say, "Divide.")
        XCTAssertEqual(l.words.hint, "Now it’s whole numbers: divide.")
        XCTAssertEqual(answer(&l, "0.8"), .notYet("Both numbers got 10 times bigger, so the answer is the same. Don’t move the point back."))
        XCTAssertEqual(answer(&l, "288"), .notYet("How many 6s fit in 48? That’s dividing."))
        XCTAssertEqual(answer(&l, "7"), .notYet("Not quite. How many 6s make 48?"))
        XCTAssertEqual(l.showAnswer(), "How many 6s make 48? That makes 8.")
        XCTAssertEqual(l.steps[3].answer?.work, [.num(48), .op("÷"), .num(6), .op("="), .num(8)])
        XCTAssertEqual(l.go(), .moved(4))

        XCTAssertEqual(l.words.say, "4.8 ÷ 0.6 = 8.")
        XCTAssertEqual(l.words.hint, "Making both numbers ten times bigger doesn’t change how many times one fits in the other.")
        XCTAssertEqual(l.picture, ["lines": 1, "all": 1, "hops": 1])
        XCTAssertEqual(l.go(), .newProblem)
        XCTAssertEqual(DivideByDecimal.spec.story?(l.numbers), "You have 4.8 liters of juice. Each cup holds 0.6 liters. How many cups can you fill?")
        XCTAssertEqual(DivideByDecimal.spec.depends, ["g5-pow10", "g3-divfacts"])
    }

    func testGeneratorKeepsTheWebRules() {
        var rng = SeededRandom(seed: 11)
        for _ in 0..<300 {
            let n = DivideByDecimal.spec.generate(&rng, 0), s = DivideByDecimal.Parts(n)
            XCTAssertTrue((2...9).contains(s.d) && (2...12).contains(s.qt))
            XCTAssertEqual(s.x / s.y, Double(s.qt), accuracy: 1e-9, "the answer is always the whole number qt")
            XCTAssertEqual(s.x * 10, Double(s.n), accuracy: 1e-9)
            XCTAssertEqual(LessonRun(DivideByDecimal.spec, numbers: n).steps[3].answer?.expected["x"], Double(s.qt))
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
