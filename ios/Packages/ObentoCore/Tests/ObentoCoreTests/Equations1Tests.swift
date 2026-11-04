import XCTest
@testable import ObentoCore

/// 1st grade, chapter 2: Equations and stories (design/grade1.md, the preview design/prototype/grade1-ch2.html).
final class Equations1Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(23 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(1)[1]
        XCTAssertEqual(ch.title, "Equations and stories")
        XCTAssertEqual(ch.colour, "fractions")
        for l in ch.lessons where Curriculum.built(l.id) { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertTrue(Curriculum.voiced(l.id)) }
    }

    // MARK: Add to take away

    func testRelated() {
        var l = LessonRun(Related1.spec, numbers: Related1.numbers(c: 12, a: 8))
        XCTAssertEqual(l.words.say, "Drag the bottom row out to the end.")
        XCTAssertEqual(move(&l, ["k": 5]), .notYet("That's past 12."))
        XCTAssertEqual(move(&l, ["k": 2]), .notYet("It doesn't reach 12 yet."))
        XCTAssertEqual(move(&l, ["k": 4]), .moved(1))
        XCTAssertEqual(l.words.say, "Tap the number that goes in the box.")
        XCTAssertEqual(move(&l, ["x": 20]), .notYet("That's adding. Taking away leaves less than 12."))
        XCTAssertEqual(move(&l, ["x": 8]), .notYet("That's the part you take. Find the other part."))
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("Count the striped ones again."))
        XCTAssertEqual(move(&l, ["x": 11]), .notYet("The striped ones are the part left. Count them."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(2))
        XCTAssertEqual(l.words.say, "The part you add to 8 is the part left.")
    }

    func testRelatedGenerator() {
        for i in 0..<12 {
            each(Related1.spec, i) { x in
                let P = Related1.Parts(x)
                if i < 3 { XCTAssertTrue((6...10).contains(P.c)); XCTAssertGreaterThanOrEqual(P.a, 2); XCTAssertGreaterThanOrEqual(P.b, 2) }
                else { XCTAssertTrue((11...18).contains(P.c)); XCTAssertLessThanOrEqual(P.a, 9); XCTAssertLessThanOrEqual(P.b, 9) }
            }
        }
        let c = checks(Related1.spec).map(Related1.Parts.init)
        XCTAssertGreaterThanOrEqual(c[1].c, 15); XCTAssertLessThan(c[2].a, c[2].b)
    }

    // MARK: Missing numbers

    func testMissing() {
        var l = LessonRun(Missing1.spec, numbers: Missing1.numbers(a: 8, c: 13))
        XCTAssertEqual(l.words.say, "Hop up to 10.")
        XCTAssertEqual(move(&l, ["t": 12]), .notYet("Stop at 10 first."))
        XCTAssertEqual(move(&l, ["t": 9]), .notYet("Keep going to 10."))
        XCTAssertEqual(move(&l, ["t": 10]), .moved(1))
        XCTAssertEqual(l.words.say, "Now hop on to the flag.")
        XCTAssertEqual(move(&l, ["e": 12]), .notYet("Keep going to 13."))
        XCTAssertEqual(move(&l, ["e": 15]), .notYet("That's past 13."))
        XCTAssertEqual(move(&l, ["e": 13]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 13]), .notYet("13 is already there. The missing number is how far it is from 8 to 13."))
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("Add both hops: 2 to get to 10, and 3 more."))
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("Put the hops together: 2 and 3."))
        XCTAssertEqual(move(&l, ["x": 5]), .moved(3))
        XCTAssertEqual(l.words.say, "Count up from the number you know.")
    }

    func testMissingGenerator() {
        for i in 0..<12 {
            each(Missing1.spec, i) { x in
                let P = Missing1.Parts(x)
                XCTAssertTrue((i < 3 ? 6...9 : 2...9).contains(P.a)); XCTAssertTrue((11...18).contains(P.c)); XCTAssertLessThanOrEqual(P.ans, 9)
                if i < 3 { XCTAssertFalse(P.first) }
            }
        }
        XCTAssertTrue(Missing1.Parts(checks(Missing1.spec)[1]).first)
    }

    // MARK: True or false?

    func testEqualTrueFalse() {
        typealias S = Equal1.Side
        var l = LessonRun(Equal1.spec, numbers: Equal1.numbers(S(1, 4, 1), S(1, 5, 2)))
        XCTAssertEqual(l.words.say, "Slide each side into one row.")
        XCTAssertEqual(move(&l, ["j": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "Same amount? Tap True or False.")
        XCTAssertEqual(move(&l, ["tf": 1]), .notYet("Not the same: 5 and 7."))
        XCTAssertEqual(move(&l, ["tf": 0]), .moved(2))
        XCTAssertEqual(l.words.say, "= means both sides are the same amount.")
        // one number each side: no slide
        var m = LessonRun(Equal1.spec, numbers: Equal1.numbers(S(0, 6), S(0, 6)))
        XCTAssertEqual(m.words.say, "Same amount? Tap True or False.")
        XCTAssertEqual(move(&m, ["tf": 0]), .notYet("Both rows are 6. That's the same amount."))
        XCTAssertEqual(move(&m, ["tf": 1]), .moved(1))
    }

    func testEqualMake() {
        typealias S = Equal1.Side
        // 6 + 2 = [ ] + 3
        var l = LessonRun(Equal1.spec, numbers: Equal1.numbers(S(1, 6, 2), S(1, -1, 3), make: true))
        let P = Equal1.Parts(l.numbers)
        XCTAssertEqual(P.form, .boxPlus); XCTAssertEqual(P.x, 5); XCTAssertFalse(P.boxLeft)
        XCTAssertEqual(l.words.say, "Drag the striped row until the ends match.")
        XCTAssertEqual(move(&l, ["k": 6]), .notYet("That's past the other row's end."))
        XCTAssertEqual(move(&l, ["k": 4]), .notYet("It doesn't reach the other row's end yet."))
        XCTAssertEqual(move(&l, ["k": 5]), .moved(1))
        XCTAssertEqual(move(&l, ["x": 11]), .notYet("The box and 3 make 8 together."))
        XCTAssertEqual(move(&l, ["x": 8]), .notYet("6 + 2 is 8. The box goes with 3 to make 8."))
        XCTAssertEqual(move(&l, ["x": 5]), .moved(2))
        // 5 = [ ] − 3
        var b = LessonRun(Equal1.spec, numbers: Equal1.numbers(S(0, 5), S(2, -1, 3), make: true))
        XCTAssertEqual(Equal1.Parts(b.numbers).x, 8)
        XCTAssertEqual(move(&b, ["k": 8]), .moved(1))
        XCTAssertEqual(move(&b, ["x": 2]), .notYet("The box is the start. 3 go, 5 are left."))
        // 9 − [ ] = 6: the row's end dragged back
        let c = Equal1.Parts(Equal1.numbers(S(2, 9, -1), S(0, 6), make: true))
        XCTAssertEqual(c.form, .minusBox); XCTAssertEqual(c.x, 3); XCTAssertTrue(c.boxLeft)
        XCTAssertEqual(c.dragSay, "Drag the row's end back until they match.")
        XCTAssertEqual(c.dragged(1), "That's past the other row's end.")
    }

    func testEqualGenerator() {
        for i in 0..<12 {
            each(Equal1.spec, i) { x in
                let P = Equal1.Parts(x)
                XCTAssertEqual(P.make, i >= 6)
                if P.make {
                    XCTAssertTrue(P.B.box); XCTAssertFalse(P.K.box); XCTAssertEqual(P.bval(P.x), P.T)
                    XCTAssertTrue((1...18).contains(P.x)); XCTAssertLessThanOrEqual(P.K.count, 18); XCTAssertLessThanOrEqual(P.bval(0) >= 0 ? P.kmax : 0, 18)
                    XCTAssertTrue(P.x <= P.kmax)
                } else {
                    XCTAssertTrue(abs(P.vL - P.vR) <= 2); XCTAssertLessThanOrEqual(max(P.L.count, P.R.count), 12)
                    if i < 3 { XCTAssertTrue(P.L.t == 0 || P.R.t == 0); XCTAssertLessThanOrEqual(max(P.vL, P.vR), 10) }
                    else { XCTAssertTrue(P.L.t != 0 && P.R.t != 0) }
                    for s in P.sides { XCTAssertGreaterThan(s.value(), 0) }
                }
            }
        }
        let c = checks(Equal1.spec).map(Equal1.Parts.init)
        XCTAssertFalse(c[1].truth); XCTAssertTrue(c[2].boxLeft)
    }

    // MARK: Story problems

    func testStoryJoin() {
        var l = LessonRun(Story1.spec, numbers: Story1.numbers(.join, s: 5, ch: 3, e: 8, thing: 0, name: 0))
        XCTAssertEqual(l.words.say, "5 birds sit in a tree. 3 more fly in. How many birds now? Slide the new ones onto the row.")
        XCTAssertEqual(move(&l, ["m": 3]), .moved(1))
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("That's taking away. More came, so add."))
        XCTAssertEqual(move(&l, ["x": 9]), .notYet("Count them all: the row and the ones that came."))
        XCTAssertEqual(move(&l, ["x": 8]), .moved(2))
        XCTAssertEqual(l.words.say, "More came, so add.")
    }

    func testStoryKinds() {
        var t = LessonRun(Story1.spec, numbers: Story1.numbers(.takeChange, s: 9, ch: 4, e: 5, thing: 3, name: 1))
        XCTAssertEqual(t.words.say, "Leo has 9 apples. Leo eats some. Now there are 5. How many did Leo eat? Slide ones off down to the outline.")
        XCTAssertEqual(move(&t, ["m": 5]), .notYet("That leaves 4. 5 are left."))
        XCTAssertEqual(move(&t, ["m": 2]), .notYet("That leaves 7. Keep going to 5."))
        XCTAssertEqual(move(&t, ["m": 4]), .moved(1))
        XCTAssertEqual(move(&t, ["x": 5]), .notYet("5 are left. How many did Leo eat?"))
        XCTAssertEqual(move(&t, ["x": 14]), .notYet("Leo ate some, so there are fewer."))
        XCTAssertEqual(Story1.Parts(t.numbers).record, [.n(9), .op("−"), .box, .op("="), .n(5)])
        let s = Story1.Parts(Story1.numbers(.joinStart, s: 4, ch: 3, e: 7, thing: 1, name: 2))
        XCTAssertEqual(s.lines, ["Some frogs sit on a log.", "3 more hop on. Now there are 7.", "How many were there first?"])
        XCTAssertEqual(s.moved(-1), "Those were there at the start. Slide off the ones that came.")
        XCTAssertEqual(s.ans, 4)
        let a = Story1.Parts(Story1.numbers(.apart, s: 5, ch: 3, e: 8, thing: 4, name: 4))
        XCTAssertEqual(a.lines, ["Noor has 8 shells.", "5 are in a box. The rest are in a bag.", "How many are in the bag?"])
        XCTAssertEqual(a.ans, 3)
    }

    func testStoryGenerator() {
        for i in 0..<12 {
            each(Story1.spec, i) { x in
                let P = Story1.Parts(x)
                if i < 3 { XCTAssertEqual(P.kind, [Story1.Kind.join, .take, .together][i]); XCTAssertLessThanOrEqual(max(P.s, P.e), 10) }
                else if i < 6 { XCTAssertTrue([.joinChange, .takeChange, .apart].contains(P.kind)) }
                XCTAssertLessThanOrEqual(max(P.s, P.e), 18); XCTAssertGreaterThanOrEqual(P.ch, 2)
                switch P.kind {
                case .take, .takeChange, .takeStart: XCTAssertEqual(P.s - P.ch, P.e)
                default: XCTAssertEqual(P.s + P.ch, P.e)
                }
                XCTAssertTrue((0...20).contains(P.ans))
            }
        }
        let c = checks(Story1.spec).map(Story1.Parts.init)
        XCTAssertTrue([.joinChange, .takeChange].contains(c[1].kind)); XCTAssertTrue([.joinStart, .takeStart].contains(c[2].kind)); XCTAssertEqual(c[3].kind, .apart)
    }

    // MARK: How many more?

    func testMore() {
        var l = LessonRun(More1.spec, numbers: More1.numbers(kind: 0, big: 9, small: 5, bn: 0, sn: 1, thing: 0))
        XCTAssertEqual(l.words.say, "Maya has 9 shells. Leo has 5. How many more does Maya have? Tap the ones with no partner.")
        XCTAssertEqual(move(&l, ["m": -1]), .notYet("That one has a partner. Count the ones past Leo's row."))
        XCTAssertEqual(move(&l, ["m": 4]), .moved(1))
        XCTAssertEqual(move(&l, ["x": 14]), .notYet("How many more means the extra ones. Take away."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(2))
        XCTAssertEqual(l.words.say, "Line them up: the extra ones are how many more.")
        var b = LessonRun(More1.spec, numbers: More1.numbers(kind: 2, big: 9, small: 5, bn: 0, sn: 1))
        XCTAssertEqual(b.words.say, "Leo has 5 shells. Maya has 4 more. How many does Maya have? Drag Maya's row out.")
        XCTAssertEqual(move(&b, ["m": 3]), .notYet("That's 3 more. Maya has 4 more."))
        XCTAssertEqual(move(&b, ["m": 4]), .moved(1))
        XCTAssertEqual(move(&b, ["x": 1]), .notYet("Maya has more, so her row is longer."))
        var s = LessonRun(More1.spec, numbers: More1.numbers(kind: 3, big: 9, small: 5, bn: 0, sn: 1))
        XCTAssertEqual(move(&s, ["m": 4]), .moved(1))
        XCTAssertEqual(move(&s, ["x": 13]), .notYet("Leo has fewer, so his row is shorter."))
        XCTAssertEqual(move(&s, ["x": 5]), .moved(2))
    }

    func testMoreGenerator() {
        for i in 0..<12 {
            each(More1.spec, i) { x in
                let P = More1.Parts(x)
                XCTAssertNotEqual(P.Bg, P.Sm); XCTAssertGreaterThan(P.d, 0)
                XCTAssertLessThanOrEqual(P.big, i < 6 ? 10 : 16)
                if i < 3 { XCTAssertEqual(P.find, .diff) } else if i < 6 { XCTAssertNotEqual(P.find, .diff) }
            }
        }
        let c = checks(More1.spec).map(More1.Parts.init)
        XCTAssertEqual(c[1].find, .big); XCTAssertEqual(c[2].find, .small); XCTAssertGreaterThanOrEqual(c[3].kind, 4)
    }
}
