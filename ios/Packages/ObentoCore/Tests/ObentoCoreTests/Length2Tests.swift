import XCTest
@testable import ObentoCore

/// 2nd grade, chapter 4: Length (design/grade2.md, the preview design/prototype/grade2-ch4.html).
final class Length2Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(77 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }
    private func hop(_ a: Int, _ b: Int) -> Double { Double(Len2.code(a, b)) }

    func testOnTheMap() {
        let ch = Curriculum.chapters(2)[3]
        XCTAssertEqual(ch.title, "Length"); XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertTrue(Curriculum.voiced(l.id)) }
        XCTAssertEqual(Spoken.text("That's 44. The ribbon is 45 cm."), "That's 44. The ribbon is 45 centimeters.")
        XCTAssertEqual(Spoken.text("A square is 2 in."), "A square is 2 inches.")
        XCTAssertEqual(Spoken.text("4 in a row"), "4 in a row")
        XCTAssertEqual(Spoken.text("Leo has a rope 30 ft long."), "Leo has a rope 30 feet long.")
    }

    func testHops() {
        XCTAssertEqual(Len2.decode(Len2.code(12, 47)).from, 12); XCTAssertEqual(Len2.decode(Len2.code(12, 47)).to, 47)
        XCTAssertEqual(Len2.hops(45, 27, big: 10).count, 9)
        XCTAssertEqual(Len2.hops(0, 7, big: 3, restInOne: true).map { $0.1 }, [3, 6, 7])
        XCTAssertEqual(Len2.landings([1, 2, 3, 4, 5, 6, 7]), "1, 2, 3 … 7")
        XCTAssertEqual(Numline2.Parts.readout(from: 45, to: 27), "45 − 10 = 35 … 27")
    }

    func testMeasure() {
        var l = LessonRun(Measure2.spec, numbers: Measure2.numbers(unit: 1, th: 0, start: 2, end: 9))
        XCTAssertEqual(l.steps.count, 3)
        XCTAssertEqual(l.words.say, "Hop from end to end.")
        XCTAssertEqual(move(&l, ["h": hop(0, 9)]), .notYet("Start at the pencil's end."))
        XCTAssertEqual(move(&l, ["h": hop(2, 8)]), .notYet("That's 6. The pencil goes on to 9."))
        XCTAssertEqual(move(&l, ["h": hop(2, 9)]), .moved(1))
        XCTAssertEqual(l.words.say, "Write how long it is.")
        XCTAssertEqual(move(&l, ["x": 9]), .notYet("The pencil starts at 2, not 0. Count the spaces from 2 to 9."))
        XCTAssertEqual(move(&l, ["x": 8]), .notYet("Count the spaces between the marks, not the marks themselves."))
        XCTAssertEqual(move(&l, ["x": 11]), .notYet("Take away the start: the ruler before 2 is not part of the pencil."))
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("Count the hops from 2 to 9."))
        XCTAssertEqual(move(&l, ["x": 7]), .moved(2))
        XCTAssertEqual(l.words.say, "Each hop is one space, and the spaces are the length.")

        var z = LessonRun(Measure2.spec, numbers: Measure2.numbers(unit: 0, th: 1, start: 0, end: 5))
        _ = move(&z, ["h": hop(0, 5)])
        XCTAssertEqual(move(&z, ["x": 4]), .notYet("It starts at 0, so the end is the length."))

        var f = LessonRun(Measure2.spec, numbers: Measure2.fold(unit: 1, th: 2, th2: 0, long: 9, short: 6))
        XCTAssertEqual(f.words.say, "Hop the part sticking out.")
        XCTAssertEqual(move(&f, ["h": hop(0, 9)]), .notYet("Start at the pencil's end."))
        XCTAssertEqual(move(&f, ["h": hop(6, 9)]), .moved(1))
        XCTAssertEqual(move(&f, ["x": 9]), .notYet("That's the whole ribbon. Write the part sticking out."))
        XCTAssertEqual(move(&f, ["x": 6]), .notYet("That's the pencil. Write the part sticking out."))
        XCTAssertEqual(move(&f, ["x": 3]), .moved(2))
        XCTAssertEqual(f.words.say, "Lined up at 0, the part sticking out is how much longer.")

        for i in 0..<9 {
            each(Measure2.spec, i) { x in
                let P = Measure2.Parts(x)
                XCTAssertEqual(P.fold, i >= 4 && i % 4 == 0)
                XCTAssertTrue(P.to <= P.top && P.L >= 1)
                if !P.fold { XCTAssertEqual(P.from == 0, i < 3) } else { XCTAssertNotEqual(P.name, P.name2) }
            }
        }
        let c = checks(Measure2.spec).map(Measure2.Parts.init)
        XCTAssertEqual(c[1].u, "in"); XCTAssertEqual(c[2].u, "cm")
    }

    func testTwoUnits() {
        var l = LessonRun(TwoUnits2.spec, numbers: TwoUnits2.numbers(inches: 6))
        XCTAssertEqual(l.steps.count, 6)
        XCTAssertEqual(l.words.say, "Measure in inches.")
        XCTAssertEqual(move(&l, ["hi": hop(0, 5)]), .notYet("That's 5. The spoon goes on to 6."))
        XCTAssertEqual(move(&l, ["hi": hop(1, 6)]), .notYet("Start at the spoon's end."))
        XCTAssertEqual(move(&l, ["hi": hop(0, 6)]), .moved(1))
        XCTAssertEqual(l.words.say, "Write how many inches.")
        XCTAssertEqual(move(&l, ["in": 7]), .notYet("Count the spaces between the marks, not the marks themselves."))
        XCTAssertEqual(move(&l, ["in": 15]), .notYet("That's the centimeters. Count the inches."))
        XCTAssertEqual(move(&l, ["in": 6]), .moved(2))
        XCTAssertEqual(l.words.say, "Now in centimeters.")
        XCTAssertEqual(move(&l, ["hc": hop(0, 15)]), .moved(3))
        XCTAssertEqual(move(&l, ["cm": 6]), .notYet("That's the inches. Count the centimeters."))
        XCTAssertEqual(move(&l, ["cm": 2]), .notYet("Count the hops on the centimeter ruler."))
        XCTAssertEqual(move(&l, ["cm": 15]), .moved(4))
        XCTAssertEqual(l.words.say, "Tap the bigger unit.")
        XCTAssertEqual(move(&l, ["b": 2]), .notYet("15 is more, but each centimeter is smaller."))
        XCTAssertEqual(move(&l, ["b": 1]), .moved(5))
        XCTAssertEqual(l.words.say, "A centimeter is smaller, so more of them fit.")
        for i in 0..<6 {
            each(TwoUnits2.spec, i) { x in
                let P = TwoUnits2.Parts(x)
                XCTAssertTrue(i < 3 ? [2, 4, 6].contains(P.n) : (2...12).contains(P.n)); XCTAssertEqual(P.cm * 2, P.n * 5)
            }
        }
        XCTAssertTrue(TwoUnits2.Parts(checks(TwoUnits2.spec)[1]).n >= 8)
    }

    func testEstimate() {
        var l = LessonRun(Estimate2.spec, numbers: Estimate2.numbers(unit: 0, thing: 2, len: 6))
        XCTAssertEqual(l.steps.count, 4)
        let P = Estimate2.Parts(l.numbers)
        XCTAssertEqual(Set(P.guesses), [6, 2, 24])
        XCTAssertEqual(l.words.say, "Guess with the paper clip.")
        XCTAssertEqual(move(&l, ["g": 2]), .notYet("2 inches is about 2 paper clips. The pencil is much longer than that."))
        XCTAssertEqual(move(&l, ["g": 24]), .notYet("24 inches is longer than a whole ruler."))
        XCTAssertEqual(move(&l, ["g": 6]), .moved(1))
        XCTAssertEqual(l.words.say, "Now measure it.")
        XCTAssertEqual(move(&l, ["h": hop(0, 6)]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("Count the spaces between the marks, not the marks."))
        XCTAssertEqual(move(&l, ["x": 6]), .moved(3))
        XCTAssertEqual(l.words.say, "A paper clip is about an inch, and about 6 fit.")

        var c = LessonRun(Estimate2.spec, numbers: Estimate2.numbers(unit: 1, thing: 1, len: 9, start: 2))
        XCTAssertEqual(c.words.say, "Guess with the cube.")
        XCTAssertEqual(move(&c, ["g": 45]), .notYet("45 centimeters is longer than a whole ruler."))
        _ = move(&c, ["g": 9])
        XCTAssertEqual(move(&c, ["h": hop(0, 9)]), .notYet("Start at the crayon's end."))
        _ = move(&c, ["h": hop(2, 11)])
        XCTAssertEqual(move(&c, ["x": 11]), .notYet("The crayon starts at 2, not 0. Count the spaces from 2 to 11."))
        XCTAssertEqual(move(&c, ["x": 9]), .moved(3))
        XCTAssertEqual(c.words.say, "A cube is about a centimeter, and about 9 fit.")

        var f = LessonRun(Estimate2.spec, numbers: Estimate2.fold(meters: false, thing: 2, len: 7))
        let F = Estimate2.Parts(f.numbers)
        XCTAssertEqual(F.tool, "yard"); XCTAssertEqual(F.toolHops.map { $0.1 }, [3, 6, 7])
        XCTAssertEqual(f.words.say, "Guess with the foot ruler.")
        XCTAssertEqual(move(&f, ["g": Double(F.smallGuess)]), .notYet("2 feet is 2 foot rulers. The bed is much longer than that."))
        _ = move(&f, ["g": 7]); _ = move(&f, ["h": hop(0, 7)])
        XCTAssertEqual(move(&f, ["x": 8]), .notYet("Count the hops, not the marks."))
        XCTAssertEqual(move(&f, ["x": 7]), .moved(3))
        XCTAssertEqual(f.words.say, "A yardstick is 3 feet, so count by 3s, then the rest.")
        XCTAssertEqual(Estimate2.Parts(Estimate2.fold(meters: true, thing: 2, len: 4)).why, "A meter stick is one meter, and 4 fit along the car.")

        for i in 0..<10 {
            each(Estimate2.spec, i) { x in
                let P = Estimate2.Parts(x)
                XCTAssertEqual(P.fold, i >= 6 && i % 3 == 0)
                if i < 3 { XCTAssertEqual(P.u, "in"); XCTAssertEqual(P.start, 0) }
                XCTAssertEqual(Set(P.guesses).count, 3); XCTAssertTrue(P.end <= P.top)
            }
        }
        let k = checks(Estimate2.spec).map(Estimate2.Parts.init)
        XCTAssertEqual(k[1].u, "cm"); XCTAssertTrue(k[2].u == "in" && k[2].start > 0)
    }

    func testNumline() {
        var l = LessonRun(Numline2.spec, numbers: Numline2.numbers(kind: .cut, a: 45, b: 18, th: 0, who: 0, other: 1))
        let P = Numline2.Parts(l.numbers)
        XCTAssertEqual(P.lines, ["Mia has a ribbon 45 cm long.", "She cuts off 18 cm.", "How long is it now?"])
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Drag from 0 to 45.")
        XCTAssertEqual(move(&l, ["d0": 44]), .notYet("That's 44. The ribbon is 45 cm."))
        XCTAssertEqual(move(&l, ["d0": 45]), .moved(1))
        XCTAssertEqual(l.words.say, "Hop back 18.")
        XCTAssertEqual(move(&l, ["h": hop(45, 55)]), .notYet("She cut some off. Hop back."))
        XCTAssertEqual(move(&l, ["h": hop(45, 26)]), .notYet("That's 19 back. Hop 18."))
        XCTAssertEqual(move(&l, ["h": hop(40, 22)]), .notYet("Start at the ribbon's end."))
        XCTAssertEqual(move(&l, ["h": hop(45, 27)]), .moved(2))
        XCTAssertEqual(l.words.say, "Write the answer.")
        XCTAssertEqual(move(&l, ["x": 63]), .notYet("Some was cut off, so it's shorter."))
        XCTAssertEqual(move(&l, ["x": 37]), .notYet("Count the ten-hops again."))
        XCTAssertEqual(move(&l, ["x": 28]), .notYet("Count the hops, not the marks."))
        XCTAssertEqual(move(&l, ["x": 27]), .moved(3))
        XCTAssertEqual(l.words.say, "Every number is a length from 0, so hopping back takes length off.")

        var c = LessonRun(Numline2.spec, numbers: Numline2.numbers(kind: .cmp, a: 38, b: 20, th: 1, who: 1, other: 2))
        XCTAssertEqual(c.steps.count, 5)
        XCTAssertEqual(move(&c, ["d0": 38]), .moved(1))
        XCTAssertEqual(move(&c, ["d1": 21]), .notYet("That's 21. Ana's rope is 20 ft."))
        _ = move(&c, ["d1": 20])
        XCTAssertEqual(c.words.say, "Hop from 20 to 38.")
        XCTAssertEqual(move(&c, ["h": hop(38, 20)]), .notYet("Start at the end of Ana's rope."))
        XCTAssertEqual(move(&c, ["h": hop(20, 36)]), .notYet("That's 36. Hop on to 38."))
        _ = move(&c, ["h": hop(20, 38)])
        XCTAssertEqual(move(&c, ["x": 58]), .notYet("Take the shorter from the longer."))

        var p = LessonRun(Numline2.spec, numbers: Numline2.numbers(kind: .part, a: 60, b: 34, th: 3, who: 3, other: 0))
        XCTAssertEqual(Numline2.Parts(p.numbers).per, 2)
        XCTAssertEqual(p.words.say, "Drag from 0 to 34.")
        XCTAssertEqual(move(&p, ["d1": 30]), .notYet("That's 30. He has 34 m."))
        _ = move(&p, ["d1": 34])
        XCTAssertEqual(move(&p, ["h": hop(0, 60)]), .notYet("Start at the end of the fence he has."))
        _ = move(&p, ["h": hop(34, 60)])
        XCTAssertEqual(move(&p, ["x": 94]), .notYet("It's the part still needed, so it's less than 60."))
        XCTAssertEqual(move(&p, ["x": 26]), .moved(3))

        for i in 0..<10 {
            each(Numline2.spec, i) { x in
                let P = Numline2.Parts(x)
                if i < 3 { XCTAssertEqual(P.kind.rawValue, i); XCTAssertTrue(P.hi <= 50) }
                XCTAssertTrue((1...100).contains(P.ans)); XCTAssertTrue(P.hi <= 100)
                if P.per == 2 { XCTAssertTrue(P.a % 2 == 0 && P.b % 2 == 0) }
                XCTAssertNotEqual(P.N, P.M)
            }
        }
        let k = checks(Numline2.spec).map(Numline2.Parts.init)
        XCTAssertEqual(k[0].kind, .cut); XCTAssertEqual(k[1].kind, .cmp); XCTAssertEqual(k[2].kind, .part)
    }
}
