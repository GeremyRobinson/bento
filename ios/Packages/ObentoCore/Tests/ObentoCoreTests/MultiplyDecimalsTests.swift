import XCTest
@testable import ObentoCore

final class MultiplyDecimalsTests: XCTestCase {
    private func run(_ A: Int, _ B: Int, _ pa: Int = 1, _ pb: Int = 1) -> LessonRun {
        LessonRun(MultiplyDecimals.spec, numbers: MultiplyDecimals.numbers(A: A, B: B, pa: pa, pb: pb))
    }
    private func answer(_ l: inout LessonRun, _ s: String) -> LessonRun.Outcome {
        l.reset(); for c in s { l.type(String(c)) }; return l.go()
    }

    private func set(_ l: inout LessonRun, _ v: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, x) in v { l.set(k, x) }; return l.go()
    }

    /// The web lesson's reference, 2.4 × 0.3 = 0.72, on the paper: the strip dragged out, the pieces written, the point tapped.
    func testWalkThroughTheReference() {
        var l = run(24, 3)
        XCTAssertEqual(MultiplyDecimals.spec.master, "area-model")
        XCTAssertEqual(l.display, [.num(2.4), .op("×"), .num(0.3)])
        XCTAssertEqual(l.words.say, "Each bold square is one whole.")
        XCTAssertEqual(l.picture, ["at": 0])
        XCTAssertEqual(l.go(), .moved(1))

        XCTAssertEqual(l.words.say, "Drag the corner out to both marks.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(set(&l, ["a": 23, "b": 3]), .notYet("That’s 2.3 across. The mark is at 2.4."))
        XCTAssertEqual(set(&l, ["a": 24, "b": 4]), .notYet("That’s 0.4 up. The mark is at 0.3."))
        XCTAssertEqual(set(&l, ["a": 20, "b": 5]), .notYet("That’s 2 across and 0.5 up. Take the corner to both marks."))
        XCTAssertEqual(set(&l, ["a": 24, "b": 3]), .moved(2))

        XCTAssertEqual(l.words.say, "How many pieces in the strip? Write it.")
        XCTAssertEqual(l.words.hint, "Leave the points out and multiply.")
        XCTAssertEqual(answer(&l, "27"), .notYet("The sign is ×: 24 × 3."))
        XCTAssertEqual(answer(&l, "70"), .notYet("Not quite. Leave the points out for now: 2.4 has the same digits as 24."))
        XCTAssertEqual(l.showAnswer(), "Without the points it’s 24 × 3 = 72.")
        XCTAssertEqual(l.steps[2].answer?.work, [.num(24), .op("×"), .num(3), .op("="), .num(72)])
        XCTAssertEqual(l.go(), .moved(3))

        // the tap puts the point k places from the right of 72
        XCTAssertEqual(l.words.say, "Tap where the point goes.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(set(&l, ["x": MultiplyDecimals.pointed(72, 1)]), .notYet("7.2 is too big. 0.3 is less than 1, so the answer must be less than 2.4."))
        XCTAssertEqual(set(&l, ["x": MultiplyDecimals.pointed(72, 0)]), .notYet("Put the decimal point back, 2 places from the right."))
        XCTAssertEqual(l.showAnswer(), "Put the point 2 places from the right of 72: 0.72.")
        XCTAssertEqual(l.steps[3].answer?.hint, "The answer counts hundredths, so 2 places go after the point.")
        XCTAssertEqual(l.steps[3].answer?.work, [.num(2.4), .op("×"), .num(0.3), .op("="), .num(0.72)])
        XCTAssertEqual(set(&l, ["x": MultiplyDecimals.pointed(72, 2)]), .moved(4))

        XCTAssertEqual(l.words.say, "Tenths times tenths are hundredths: 2 places.")
        XCTAssertEqual(l.go(), .newProblem)
        XCTAssertEqual(MultiplyDecimals.spec.story?(l.numbers), "A garden bed is 2.4 m long and 0.3 m wide. What is its area in square meters?")
        XCTAssertEqual(MultiplyDecimals.spec.depends, ["g4-partial", "g4-dec"])
    }

    func testTenthsTimesAWholeAndHundredths() {
        var w = run(24, 3, 1, 0)
        XCTAssertEqual(w.display, [.num(2.4), .op("×"), .num(3)])
        XCTAssertEqual(w.steps[3].answer?.known.map(\.message), ["72 is too big. 2.4 × 3 is close to 2 × 3 = 6.",
                                                                 "0.72 is too small. Count the places again: 1 + 0 = 1."])
        XCTAssertEqual(w.steps[3].answer?.hint, "The answer counts tenths, so 1 place goes after the point.")
        XCTAssertEqual(w.steps.last?.words.say, "Tenths times wholes are tenths: 1 place.")
        _ = w.go()
        XCTAssertEqual(set(&w, ["a": 24, "b": 2]), .notYet("That’s 2 up. The mark is at 3."))
        var h = run(125, 4, 2, 1)
        XCTAssertEqual(h.steps[1].words.say, "Drag the strip up to its mark.")
        XCTAssertEqual(h.steps[3].answer?.expected["x"], 0.5)
        XCTAssertEqual(h.steps[3].answer?.known.map { $0.values["x"]! }, [5, 0.05, 500])
        XCTAssertEqual(h.steps.last?.words.say, "Hundredths times tenths are thousandths: 3 places.")
        // a tap one place off that no slip names is measured in places
        _ = h.go(); _ = set(&h, ["a": 125, "b": 4]); _ = answer(&h, "500")
        XCTAssertEqual(set(&h, ["x": MultiplyDecimals.pointed(500, 1)]), .notYet("That’s 1 place from the right. 1.25 and 0.4 have 3 places between them."))
    }

    /// The web's test: the places answer is 1, then 2, then 3, and a point one place off is a named slip.
    func testGeneratorKeepsTheWebRules() {
        var rng = SeededRandom(seed: 11)
        for index in 0..<9 {
            for _ in 0..<300 {
                let n = MultiplyDecimals.spec.generate(&rng, index), s = MultiplyDecimals.Parts(n)
                XCTAssertEqual(s.n, index < 3 ? 1 : index < 6 ? 2 : 3)
                XCTAssertNotEqual(s.A % 10, 0)
                XCTAssertTrue((2...9).contains(s.B))
                XCTAssertTrue(s.pa == 1 ? (11...99).contains(s.A) : (101...999).contains(s.A))
                let l = LessonRun(MultiplyDecimals.spec, numbers: n), place = l.steps[3].answer!
                XCTAssertEqual(l.steps.count, 5)
                XCTAssertEqual(place.expected["x"]!, (Double(s.A * s.B) / pow(10, Double(s.n)) * 1e6).rounded() / 1e6, accuracy: 1e-9)
                XCTAssertTrue(place.known.contains { abs($0.values["x"]! - place.expected["x"]! * 10) < 1e-9 }, "\(n)")
            }
        }
    }

    func testSkillCheckDraws() {
        var rng = SeededRandom(seed: 3)
        let items = MultiplyDecimals.spec.check
        XCTAssertEqual(items.map(\.index), [1, 4, 7, 5]); XCTAssertEqual(items.map(\.story), [false, false, false, true])
        for item in items { for _ in 0..<300 {
            let n = item.draw(MultiplyDecimals.spec, using: &rng)
            XCTAssertTrue(item.when?(n) ?? true)
        } }
    }
}
