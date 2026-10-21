import XCTest
@testable import ObentoCore

final class ConvertUnitsTests: XCTestCase {
    func type(_ l: inout LessonRun, _ s: String) { l.reset(); for c in s { l.type(String(c)) } }

    /// The web lesson's reference, 3 feet = ? inches, on the paper: the cut sets "1 ft = [12] in" from the move, the
    /// record's product is typed, the last words say why.
    func testWalkThroughTheLesson() {
        let n = ConvertUnits.numbers("foot", 3)
        XCTAssertEqual(n, ["u": 0, "n": 3, "up": 0])
        var l = LessonRun(ConvertUnits.spec, numbers: n)
        XCTAssertEqual(l.display, [.num(3), .text("feet"), .op("="), .text("? inches")])
        XCTAssertEqual(ConvertUnits.spec.story?(n), "A rope is 3 feet long. How many inches long is it?")
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "How many inches fit in one foot?", "the first words don't repeat the problem")
        XCTAssertEqual(l.go(), .moved(1))

        // the cut: by hand, its box the small units the ruler's pieces make
        XCTAssertEqual(l.words.say, "Drag the ruler to cut one foot into inches, then cut.")
        XCTAssertEqual(l.words.hint, "Start with just one foot.")
        XCTAssertEqual(l.step.answer?.byHand, true)
        XCTAssertEqual(l.picture, ["ruler": 1])
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
        l.set("x", 3)
        XCTAssertEqual(l.go(), .notYet("3 is the feet in a yard. A foot is 12 inches."), "the web's mix-up, a cut into 3")
        l.set("x", 8)
        XCTAssertEqual(l.go(), .notYet("One foot is more than 8 inches. Cut smaller pieces."))
        l.set("x", 24)
        XCTAssertEqual(l.go(), .notYet("One foot is less than 24 inches. Cut bigger pieces."))
        XCTAssertEqual(l.showAnswer(), "1 foot is 12 inches.")
        XCTAssertEqual(l.steps[1].answer?.work, [.num(1), .text("ft"), .op("="), .num(12), .text("in")])
        XCTAssertEqual(l.go(), .moved(2))

        // the record, the product typed
        XCTAssertEqual(l.words.say, "How many inches in all? Write it.")
        XCTAssertEqual(l.picture, ["cut": 1])
        XCTAssertEqual(l.steps[2].onMiss, ["last": 1])
        type(&l, "15")
        XCTAssertEqual(l.go(), .notYet("Each foot is 12 inches, so multiply."))
        type(&l, "0.25")
        XCTAssertEqual(l.go(), .notYet("Inches are smaller, so there are more of them: multiply."))
        type(&l, "35")
        XCTAssertEqual(l.go(), .notYet("Not quite. Every foot is 12 inches, and there are 3 of them."))
        XCTAssertEqual(l.showAnswer(), "3 × 12 = 36 inches.")
        XCTAssertEqual(l.steps[2].answer?.work, [.num(3), .text("ft"), .op("="), .num(3), .op("×"), .num(12), .op("="), .num(36), .text("in")])
        XCTAssertEqual(l.go(), .moved(3))

        XCTAssertEqual(l.words.say, "12 inches in every foot, so there are more inches.")
        XCTAssertEqual(l.picture, ["cut": 1, "done": 1])
        XCTAssertEqual(l.go(), .newProblem)
    }

    /// Minutes, centimeters and grams are cut in tens (or hundreds of grams): the cut's box is still the small units.
    func testTensCuts() {
        var l = LessonRun(ConvertUnits.spec, numbers: ConvertUnits.numbers("meter", 4))
        XCTAssertEqual(l.steps[1].words.say, "Drag the ruler to cut one meter into pieces of 10 centimeters, then cut.")
        XCTAssertEqual(ConvertUnits.bar(100).length, 40); XCTAssertEqual(ConvertUnits.bar(100).piece, 10)
        XCTAssertEqual(ConvertUnits.bar(1000).piece, 100); XCTAssertEqual(ConvertUnits.bar(60).piece, 10)
        XCTAssertEqual(ConvertUnits.bar(12).length, 48); XCTAssertEqual(ConvertUnits.bar(16).piece, 1)
        _ = l.go()
        l.set("x", 50)
        XCTAssertEqual(l.go(), .notYet("One meter is more than 50 centimeters. Cut smaller pieces."))
        l.set("x", 100); XCTAssertEqual(l.go(), .moved(2))
        // every unit's bar cuts into a whole number of squares a piece, and a half bar too
        for u in ConvertUnits.units {
            let b = ConvertUnits.bar(u.per), k = Int(u.per / b.piece)
            XCTAssertEqual(b.length % k, 0, u.one)
            if Int(u.per) % 2 == 0 { XCTAssertEqual(k % 2, 0, "a half bar is whole pieces: \(u.one)") }
        }
    }

    /// The web test: 250 centimeters = 2.5 meters. The hops set how many whole meters fit; the quotient is typed.
    func testSmallToBigHops() {
        var l = LessonRun(ConvertUnits.spec, numbers: ConvertUnits.numbers("meter", 250, up: true))
        XCTAssertEqual(l.steps.last?.words.say, "100 centimeters make every meter, so there are fewer meters.")
        XCTAssertEqual(l.words.say, "How many meters fit along the bar?")
        _ = l.go()
        XCTAssertEqual(l.words.say, "Hop the ruler along the bar, one meter at a time, as far as it goes.")
        XCTAssertEqual(l.picture, ["hops": 1]); XCTAssertEqual(l.step.answer?.byHand, true)
        l.set("h", 3)
        XCTAssertEqual(l.go(), .notYet("3 meters is 300 centimeters, more than 250. Hop back."))
        l.set("h", 1)
        XCTAssertEqual(l.go(), .notYet("1 meter is only 100 centimeters. Another meter fits in 250."))
        XCTAssertEqual(l.showAnswer(), "2 meters fit, and 50 centimeters are left: half a meter.")
        XCTAssertEqual(l.go(), .moved(2))
        XCTAssertEqual(l.words.say, "How many meters is that? Write it.")
        XCTAssertEqual(l.picture, ["hopped": 1])
        type(&l, "25000")
        XCTAssertEqual(l.go(), .notYet("Meters are bigger, so there are fewer of them: divide."))
        type(&l, "150")
        XCTAssertEqual(l.go(), .notYet("Take away 100 again and again, or divide: 250 ÷ 100."))
        XCTAssertEqual(l.showAnswer(), "250 ÷ 100 = 2.5 meters.")
        XCTAssertEqual(l.steps[2].answer?.work, [.num(250), .text("cm"), .op("="), .num(250), .op("÷"), .num(100), .op("="), .num(2.5), .text("m")])
        // a whole number of big units: nothing left
        let h = LessonRun(ConvertUnits.spec, numbers: ConvertUnits.numbers("hour", 180, up: true))
        XCTAssertEqual(h.steps[1].answer?.explain, "3 hours fit.")
        XCTAssertEqual(h.steps[1].answer?.expected, ["h": 3])
    }

    func testWordsForEachUnit() {
        let hour = LessonRun(ConvertUnits.spec, numbers: ConvertUnits.numbers("hour", 4))
        XCTAssertEqual(ConvertUnits.spec.story?(hour.numbers), "A road trip takes 4 hours. How many minutes is that?")
        XCTAssertEqual(hour.steps[1].words.say, "Drag the ruler to cut one hour into pieces of 10 minutes, then cut.")
        let kg = LessonRun(ConvertUnits.spec, numbers: ConvertUnits.numbers("kilogram", 3.5))
        XCTAssertEqual(kg.steps[2].answer?.expected["x"], 3500)
        // kilogram's two mix-ups say the same thing, but both values are slips
        XCTAssertEqual(kg.steps[1].answer?.known.map(\.values), [["x": 100], ["x": 10]])
        XCTAssertEqual(ConvertUnits.spec.story?(ConvertUnits.numbers("gallon", 5)), "A fish tank holds 5 gallons of water. How many quarts is that?")
        XCTAssertEqual(ConvertUnits.spec.story?(ConvertUnits.numbers("pound", 16, up: true)), "A bag of flour weighs 16 ounces. How many pounds is that?")
        let half = LessonRun(ConvertUnits.spec, numbers: ConvertUnits.numbers("hour", 150, up: true))
        XCTAssertEqual(half.steps[1].answer?.explain, "2 hours fit, and 30 minutes are left: half an hour.")
        // a story puts its operation first, then the lesson's own steps
        let told = LessonRun(ConvertUnits.spec, numbers: ConvertUnits.numbers("pound", 3), story: true)
        XCTAssertEqual(told.steps.count, 5); XCTAssertEqual(told.steps[0].answer?.expected["c"], 2, "×")
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
                XCTAssertEqual(run.steps.count, 4)
                XCTAssertEqual(run.steps[2].answer!.expected["x"]!, up ? n["n"]! / f : n["n"]! * f, accuracy: 1e-9)
                if up { XCTAssertEqual(run.steps[1].answer?.expected["h"], big.rounded(.down)) }
                else { XCTAssertEqual(run.steps[1].answer?.expected["x"], f) }
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
