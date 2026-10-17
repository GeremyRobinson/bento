import XCTest
@testable import ObentoCore

final class ConvertUnitsTests: XCTestCase {
    func type(_ l: inout LessonRun, _ s: String) { l.reset(); for c in s { l.type(String(c)) } }

    /// The web lesson's reference, 3 feet = ? inches, step by step.
    func testWalkThroughTheLesson() {
        let n = ConvertUnits.numbers("foot", 3)
        XCTAssertEqual(n, ["u": 0, "n": 3, "up": 0])
        var l = LessonRun(ConvertUnits.spec, numbers: n)
        XCTAssertEqual(l.display, [.num(3), .text("feet"), .op("="), .text("? inches")])
        XCTAssertEqual(ConvertUnits.spec.story?(n), "A rope is 3 feet long. How many inches long is it?")
        XCTAssertEqual(l.words.say, "How many inches is 3 feet?")
        XCTAssertEqual(l.picture, ["units": 3, "per": 12, "rows": 1, "fill": 0])
        XCTAssertEqual(l.go(), .moved(1))

        XCTAssertEqual(l.words.say, "1 foot = how many inches?")
        XCTAssertEqual(l.words.hint, "Start with just one foot.")
        XCTAssertEqual(l.picture["one"], 1); XCTAssertEqual(l.picture["fill"], 1)
        type(&l, "10")
        XCTAssertEqual(l.go(), .notYet("A foot is 12 inches, not 10. Look at a ruler: it goes up to 12."))
        type(&l, "3")
        XCTAssertEqual(l.go(), .notYet("3 is the feet in a yard. A foot is 12 inches."))
        type(&l, "11")
        XCTAssertEqual(l.go(), .notYet("Not quite. Think of one foot. How many inches fit in it?"))
        XCTAssertEqual(l.showAnswer(), "1 foot is 12 inches.")
        XCTAssertEqual(l.steps[1].answer?.work, [.num(12)])
        XCTAssertEqual(l.go(), .moved(2))

        XCTAssertEqual(l.words.say, "Will the answer be more or fewer inches than 3?")
        XCTAssertEqual(l.words.hint, "Inches are smaller, so there will be more of them than 3.")
        XCTAssertEqual(l.step.answer?.hint, "Which is bigger, a foot or an inch?")
        XCTAssertEqual(l.step.answer?.boxes, ["c"])
        XCTAssertEqual(l.picture["ask"], 1)
        XCTAssertEqual(l.step.answer?.choices, ["More inches", "Fewer inches"])
        l.choose(1) // Fewer
        XCTAssertEqual(l.go(), .notYet("Inches are smaller than feet, so you need more of them."))
        XCTAssertEqual(l.showAnswer(), "Inches are smaller, so it takes more of them.")
        XCTAssertEqual(l.typed["c"], "0", "More")
        XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.steps[2].answer?.work.last, .text("More inches"), "the finished line writes the choice")

        XCTAssertEqual(l.words.say, "Multiply")
        XCTAssertEqual(l.words.hint, "Every foot is another 12 inches, so multiply.")
        XCTAssertEqual(l.picture, ["units": 3, "per": 12, "rows": 1, "fill": 3, "total": 1])
        type(&l, "15")
        XCTAssertEqual(l.go(), .notYet("Each foot is 12 inches, so multiply."))
        type(&l, "0.25")
        XCTAssertEqual(l.go(), .notYet("Inches are smaller, so there are more of them: multiply."))
        type(&l, "35")
        XCTAssertEqual(l.go(), .notYet("Not quite. Every foot is 12 inches, and there are 3 of them."))
        XCTAssertEqual(l.showAnswer(), "3 × 12 = 36 inches.")
        XCTAssertEqual(l.steps[3].answer?.work, [.num(3), .op("×"), .num(12), .op("="), .num(36)])
        XCTAssertEqual(l.go(), .moved(4))

        XCTAssertEqual(l.words.say, "3 feet = 36 inches.")
        XCTAssertEqual(l.words.hint, "A big unit holds many small ones, so the same amount takes more small units.")
        XCTAssertEqual(l.go(), .newProblem)
    }

    /// The web test: 250 centimeters = 2.5 meters, divides, and "More" is the named slip.
    func testSmallToBigDivides() {
        var l = LessonRun(ConvertUnits.spec, numbers: ConvertUnits.numbers("meter", 250, up: true))
        XCTAssertEqual(l.steps.last?.words.say, "250 centimeters = 2.5 meters.")
        XCTAssertEqual(l.steps[3].answer?.expected["x"], 2.5)
        XCTAssertEqual(l.picture["rows"], 1); XCTAssertEqual(l.picture["units"], 2.5)
        _ = l.go(); type(&l, "100"); _ = l.go()
        XCTAssertEqual(l.words.hint, "Meters are bigger, so there will be fewer of them than 250.")
        l.choose(0)
        XCTAssertEqual(l.go(), .notYet("Meters are bigger than centimeters, so you need fewer of them."))
        l.choose(1); XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words.say, "Divide")
        XCTAssertEqual(l.words.hint, "Every 100 centimeters make one meter, so divide.")
        type(&l, "25000")
        XCTAssertEqual(l.go(), .notYet("Meters are bigger, so there are fewer of them: divide."))
        type(&l, "150")
        XCTAssertEqual(l.go(), .notYet("Take away 100 again and again, or divide: 250 ÷ 100."))
        XCTAssertEqual(l.showAnswer(), "250 ÷ 100 = 2.5 meters.")
        XCTAssertEqual(l.steps[3].answer?.work, [.num(250), .op("÷"), .num(100), .op("="), .num(2.5)])
    }

    func testWordsForEachUnit() {
        let hour = LessonRun(ConvertUnits.spec, numbers: ConvertUnits.numbers("hour", 4))
        XCTAssertEqual(hour.steps[2].answer?.hint, "Which is bigger, an hour or a minute?")
        XCTAssertEqual(ConvertUnits.spec.story?(hour.numbers), "A road trip takes 4 hours. How many minutes is that?")
        let kg = LessonRun(ConvertUnits.spec, numbers: ConvertUnits.numbers("kilogram", 3.5))
        XCTAssertEqual(kg.steps[0].words.say, "How many grams is 3.5 kilograms?")
        XCTAssertEqual(kg.steps[3].answer?.expected["x"], 3500)
        XCTAssertEqual(kg.picture["rows"], 2, "4 units stack in two rows")
        // kilogram's two mix-ups say the same thing, but both values are slips
        XCTAssertEqual(kg.steps[1].answer?.known.map(\.values), [["x": 100], ["x": 10]])
        XCTAssertEqual(ConvertUnits.spec.story?(ConvertUnits.numbers("gallon", 5)), "A fish tank holds 5 gallons of water. How many quarts is that?")
        XCTAssertEqual(ConvertUnits.spec.story?(ConvertUnits.numbers("pound", 16, up: true)), "A bag of flour weighs 16 ounces. How many pounds is that?")
        XCTAssertEqual(LessonRun(ConvertUnits.spec, numbers: ConvertUnits.numbers("pound", 2)).steps[2].answer?.hint, "Which is bigger, a pound or an ounce?")
    }

    func testSpecData() {
        let s = ConvertUnits.spec
        XCTAssertEqual(s.id, "g5-units"); XCTAssertEqual(s.master, "tape")
        XCTAssertEqual(s.depends, ["g4-convert", "g4-partial"])
        XCTAssertEqual(s.check.map(\.index), [1, 4, 5, 7])
    }

    /// The web's generator: indexes 0–2 big to small with 2–12 big units; 3–5 small to big with 2–9 big units;
    /// 6 on either way, halves only when the small units in one big unit are even.
    func testGeneratorKeepsTheWebRules() {
        var rng = SeededRandom(seed: 9)
        for index in [0, 1, 2, 3, 4, 5, 6, 7, 9] {
            var ups = 0, halves = 0
            for _ in 0..<300 {
                let n = ConvertUnits.spec.generate(&rng, index), u = Int(n["u"]!), f = ConvertUnits.units[u].per
                XCTAssertTrue((0..<ConvertUnits.units.count).contains(u))
                let up = n["up"] == 1, big = up ? n["n"]! / f : n["n"]!
                XCTAssertEqual((2 * big).rounded(), 2 * big, "a whole or a half of big units \(n)")
                XCTAssertEqual(n["n"]!.rounded(), up ? n["n"]! : n["n"]!.rounded(), "small units are whole")
                if index < 3 { XCTAssertFalse(up); XCTAssertTrue((2...12).contains(big) && big == big.rounded()) }
                else if index < 6 { XCTAssertTrue(up); XCTAssertTrue((2...9).contains(big) && big == big.rounded()) }
                else { XCTAssertTrue((2...9.5).contains(big)) }
                if big != big.rounded() { halves += 1; XCTAssertEqual(Int(f) % 2, 0) }
                if up { ups += 1 }
                let run = LessonRun(ConvertUnits.spec, numbers: n)
                XCTAssertEqual(run.steps.count, 5)
                XCTAssertEqual(run.steps[3].answer!.expected["x"]!, up ? n["n"]! / f : n["n"]! * f, accuracy: 1e-9)
                XCTAssertEqual(run.steps[2].answer?.expected["c"], up ? 1 : 0)
            }
            if index >= 6 { XCTAssertTrue(ups > 90 && ups < 210, "either way: \(ups)"); XCTAssertGreaterThan(halves, 0) }
        }
    }

    func testCheckDrawsFit() {
        var rng = SeededRandom(seed: 31)
        for item in ConvertUnits.spec.check {
            for _ in 0..<300 {
                let n = item.draw(ConvertUnits.spec, using: &rng)
                XCTAssertTrue(item.when?(n) ?? true, "\(item.index) \(n)")
            }
        }
    }
}
