import XCTest
@testable import ObentoCore

final class RoundDecimalsTests: XCTestCase {
    private func run(_ N: Int, _ p: Int) -> LessonRun { LessonRun(RoundDecimals.spec, numbers: RoundDecimals.numbers(N: N, p: p)) }
    /// Clears the step's boxes, types `s` into the first one and checks.
    private func answer(_ l: inout LessonRun, _ s: String) -> LessonRun.Outcome {
        l.reset(); for c in s { l.type(String(c)) }; return l.go()
    }
    /// Shows the answer on each step until the round step.
    private func toRound(_ l: inout LessonRun) { _ = l.go(); _ = l.showAnswer(); _ = l.go(); _ = l.showAnswer(); _ = l.go() }

    /// The web lesson's reference: 3.476 to the nearest hundredth.
    func testWalkThroughTheReference() {
        var l = run(3476, 2)
        XCTAssertEqual(RoundDecimals.spec.master, "number-line")
        XCTAssertEqual(l.display, [.num(3.476), .op("≈"), .text("?"), .text("(nearest hundredth)")])
        XCTAssertEqual(l.words.say, "Round to the nearest hundredth.")
        XCTAssertEqual(l.words.action, "Let’s find out")
        XCTAssertEqual(l.picture["value"], 3.476); XCTAssertEqual(l.picture["lo"], 3.47); XCTAssertEqual(l.picture["hi"], 3.48)
        XCTAssertEqual(l.picture["half"], 3.475); XCTAssertEqual(l.picture["tick"]!, 0.001, accuracy: 1e-12)
        XCTAssertEqual(l.go(), .moved(1))

        XCTAssertEqual(l.words.say, "Which digit is in the hundredths place?")
        XCTAssertEqual(l.words.hint, "3.476 sits between 3.47 and 3.48.")
        XCTAssertEqual(l.step.answer?.known.count, 1, "the tenths slip and the one-place-left slip are the same digit")
        XCTAssertEqual(answer(&l, "4"), .notYet("That’s the tenths digit. The hundredths place is 2 digits after the point."))
        XCTAssertEqual(answer(&l, "9"), .notYet("Not quite. The hundredths place is 2 digits after the point."))
        XCTAssertEqual(l.showAnswer(), "The hundredths place is 2 digits after the point. That makes 7.")
        XCTAssertEqual(l.picture["lit"], 0)
        XCTAssertEqual(l.go(), .moved(2))

        XCTAssertEqual(l.words.say, "Which digit comes right after it?")
        XCTAssertEqual(l.words.hint, "Halfway between them is 3.475.")
        XCTAssertEqual(answer(&l, "7"), .notYet("7 is the hundredths digit. The digit after it decides."))
        XCTAssertEqual(l.showAnswer(), "Look one place further right. That makes 6.")
        XCTAssertEqual(l.picture["halfway"], 1)
        XCTAssertEqual(l.go(), .moved(3))

        XCTAssertEqual(l.words.say, "5 or more rounds up. 4 or less stays the same.")
        XCTAssertEqual(l.words.hint, "6 is 5 or more, so round up.")
        XCTAssertEqual(answer(&l, "3.47"), .notYet("6 is 5 or more, so round up."))
        XCTAssertEqual(answer(&l, "3.5"), .notYet("Round to the hundredths: that’s 2 digits after the point."))
        XCTAssertEqual(l.showAnswer(), "The next digit is 6. That makes 3.48.")
        XCTAssertEqual(l.steps[3].answer?.work, [.num(3.476), .op("≈"), .num(3.48)])
        XCTAssertEqual(l.go(), .moved(4))

        XCTAssertEqual(l.words.say, "6 is 5 or more, so round up.")
        XCTAssertEqual(l.words.hint, "Rounding picks the closer number, and the digit just to the right tells you which.")
        XCTAssertEqual(l.picture["hop"], 1); XCTAssertEqual(l.picture["halfwayUp"], 0)
        XCTAssertEqual(l.go(), .newProblem)
        XCTAssertEqual(RoundDecimals.spec.idea(l.numbers), "Rounding picks the closer number, and the digit just to the right tells you which.")
        XCTAssertEqual(RoundDecimals.spec.depends, ["g4-placevalue", "g4-dec"])
    }

    /// The web's own tests: the other place is named, and rolling a 9 over takes 5 as well as 5.0.
    func testWebAnswers() {
        var l = run(51647, 2); toRound(&l)
        XCTAssertEqual(answer(&l, "51.6"), .notYet("Round to the hundredths: that’s 2 digits after the point."))
        XCTAssertEqual(answer(&l, "51.65"), .moved(4))
        var roll = run(4960, 1); toRound(&roll)
        XCTAssertEqual(answer(&roll, "5"), .moved(4))
        XCTAssertEqual(roll.words.say, "6 is 5 or more, so round up.")
        var roll2 = run(4960, 1); toRound(&roll2)
        XCTAssertEqual(answer(&roll2, "5.0"), .moved(4))
    }

    func testStaysAndHalfway() {
        var l = run(3472, 2); toRound(&l)
        XCTAssertEqual(l.words.hint, "2 is 4 or less, so the digit stays.")
        XCTAssertEqual(answer(&l, "3.48"), .notYet("2 is 4 or less, so the digit stays the same."))
        var h = run(3475, 2); toRound(&h)
        XCTAssertEqual(h.words.hint, "5 is 5 or more, so round up. Halfway rounds up.")
        _ = h.showAnswer(); _ = h.go()
        XCTAssertEqual(h.picture["halfwayUp"], 1)
        // tenths: the hundredths slip, and the ones digit one place too far left
        let t = run(5283, 1)
        XCTAssertEqual(t.steps[1].answer?.known.map(\.message), ["That’s the hundredths digit. The tenths place is 1 digit after the point.",
                                                                 "Start right after the point and count 1 digit."])
        XCTAssertEqual(t.steps[1].answer?.known.map { $0.values["x"]! }, [8, 5])
        XCTAssertEqual(t.display.last, .text("(nearest tenth)"))
    }

    func testGeneratorKeepsTheWebRules() {
        var rng = SeededRandom(seed: 11)
        for index in 0..<7 {
            for _ in 0..<300 {
                let n = RoundDecimals.spec.generate(&rng, index), s = RoundDecimals.Parts(n)
                XCTAssertTrue((1001...99999).contains(s.N) && (1...2).contains(s.p), "\(n)")
                XCTAssertNotEqual(s.N % s.unit, 0, "never already rounded: \(n)")
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

    func testAHandMoveSetsTheAnswer() {
        // a point placed or a length dragged puts its value in the box, as typing would, and can be taken out again
        var l = LessonRun(RoundDecimals.spec, numbers: RoundDecimals.numbers(N: 3476, p: 2))
        _ = l.go(); _ = l.go(); l.set("x", 7); _ = l.go(); l.set("x", 6); _ = l.go()
        l.set("x", 3.48)
        XCTAssertEqual(l.typed["x"], "3.48")
        l.set("y", 1)
        XCTAssertNil(l.typed["y"], "only the step's own boxes")
        l.set("x", nil)
        XCTAssertNil(l.typed["x"])
        l.set("x", 3.48)
        XCTAssertEqual(l.go(), .moved(4))
    }
}
