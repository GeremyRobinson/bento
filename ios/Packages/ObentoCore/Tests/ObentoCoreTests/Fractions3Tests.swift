import XCTest
@testable import ObentoCore

/// 3rd grade, chapter 5: Fractions (design/grade3.md, the preview design/prototype/grade3-ch5.html).
final class Fractions3Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 200, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(91 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(3)[4]
        XCTAssertEqual(ch.title, "Fractions")
        for l in ch.lessons where Curriculum.built(l.id) { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertFalse(Curriculum.voiced(l.id)) }
    }

    func testStrips() {
        let x = ShapeParts3.strips(W: 4, H: 6, b: 4), P = ShapeParts3.Parts(x)
        XCTAssertEqual(P.c, 4)
        XCTAssertEqual(P.cutText(2), "2 parts of 12")
        XCTAssertEqual(P.cutText(3), "1 part of 18, 1 of 6")
        XCTAssertEqual(P.cutDone, "fourths: 6 squares each")
        var l = LessonRun(ShapeParts3.spec, numbers: x)
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Cut it into 4 equal parts. 1 square unit is 4 × 4 squares here.")
        XCTAssertEqual(move(&l, ["k": 2]), .notYet("That's 2 equal parts. Cut 4."))
        XCTAssertEqual(move(&l, ["k": 3]), .notYet("The last part is 6 squares. The other is 18."))
        XCTAssertEqual(move(&l, ["k": 1]), .moved(1))
        XCTAssertEqual(move(&l, ["p": 3]), .moved(2))
        XCTAssertEqual(move(&l, ["t": 4, "b": 1]), .notYet("The bottom says how many equal parts make the whole: 4. The top says how many you take: 1."))
        XCTAssertEqual(move(&l, ["t": 1, "b": 3]), .notYet("There are 3 cuts, but 4 parts. Count the parts."))
        XCTAssertEqual(move(&l, ["t": 6, "b": 24]), .notYet("That's the same amount. Write it as 1 part of 4."))
        XCTAssertEqual(move(&l, ["t": 1, "b": 4]), .moved(3))
        XCTAssertEqual(l.words.say, "4 equal parts: each is 1/4 of it.")
    }

    func testShapes() {
        let x = ShapeParts3.shapes(W: 4, H: 3, b: 2, cols: false), P = ShapeParts3.Parts(x)
        XCTAssertEqual(P.regions, [[0, 0, 0, 0], [1, 1, 0, 0], [1, 1, 1, 1]])
        XCTAssertTrue(P.equal)
        var l = LessonRun(ShapeParts3.spec, numbers: x)
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(move(&l, ["n": 2]), .moved(1))
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("Each part is 6 squares: they're equal."))
        XCTAssertEqual(move(&l, ["c": 0]), .moved(2))
        XCTAssertEqual(move(&l, ["t": 1, "b": 2]), .moved(3))
        XCTAssertEqual(l.words.say, "Different shapes, same area: each is 1/2.")
        let y = ShapeParts3.shapes(W: 6, H: 2, b: 4, cols: false, bad: 1), Q = ShapeParts3.Parts(y)
        XCTAssertEqual(Q.sizes, [3, 2, 4, 3])
        var m = LessonRun(ShapeParts3.spec, numbers: y)
        XCTAssertEqual(m.steps.count, 3)
        _ = move(&m, ["n": 4])
        XCTAssertEqual(move(&m, ["c": 0]), .notYet("Not all the same: 3, 2, 4 and 3 squares."))
        XCTAssertEqual(move(&m, ["c": 1]), .moved(2))
        XCTAssertEqual(m.words.say, "3, 2, 4 and 3 squares: not fourths.")
    }

    func testShapePartsMake() {
        for i in 0..<12 {
            each(ShapeParts3.spec, i, 120) { n in
                let P = ShapeParts3.Parts(n)
                XCTAssertTrue(P.T >= 12 && P.T <= 48 && P.T % P.b == 0)
                XCTAssertEqual(P.sizes.reduce(0, +), P.T)
                XCTAssertEqual(P.c, P.H * 5 <= 25 ? 5 : 4)
                if i < 3 { XCTAssertTrue(P.strips && P.b <= 4) }
                if P.strips { XCTAssertEqual(P.W % P.b, 0) } else { XCTAssertTrue(i % 2 == 1 && i >= 3) }
            }
        }
    }

    func testUnitFractions() {
        var l = LessonRun(UnitFrac3.spec, numbers: UnitFrac3.numbers(b: 4, k: 3))
        XCTAssertEqual(l.steps.count, 6)
        XCTAssertEqual(l.words.say, "Tap each part to count it.")
        XCTAssertEqual(move(&l, ["n": 2]), .notYet("Count every part, shaded or not."))
        XCTAssertEqual(move(&l, ["n": 4]), .moved(1))
        XCTAssertEqual(move(&l, ["u": 2]), .moved(2))
        XCTAssertEqual(move(&l, ["t1": 1, "b1": 3]), .notYet("The bottom counts all 4 parts of the whole, not only the other 3."))
        XCTAssertEqual(move(&l, ["t1": 1, "b1": 4]), .moved(3))
        XCTAssertEqual(move(&l, ["h": 4]), .notYet("That's past the shading."))
        XCTAssertEqual(move(&l, ["h": 3]), .moved(4))
        XCTAssertEqual(move(&l, ["t2": 3, "b2": 1]), .notYet("The bottom counts all 4 parts of the whole, not only the 1 that is not shaded."))
        XCTAssertEqual(move(&l, ["t2": 1, "b2": 4]), .notYet("1 part is not shaded. Count the shaded parts for the top."))
        XCTAssertEqual(move(&l, ["t2": 6, "b2": 8]), .notYet("That's the same amount. Write it as 3 parts of 4."))
        XCTAssertEqual(move(&l, ["t2": 3, "b2": 4]), .moved(5))
        XCTAssertEqual(l.words.say, "3 pieces of 1/4 make 3/4.")
        let one = LessonRun(UnitFrac3.spec, numbers: UnitFrac3.numbers(b: 3, k: 1))
        XCTAssertEqual(one.steps.count, 4)
        for i in 0..<8 { each(UnitFrac3.spec, i) { n in let P = UnitFrac3.Parts(n); XCTAssertEqual(Fr3.whole % P.b, 0); if i < 3 { XCTAssertEqual(P.k, 1) } } }
    }

    func testFractionLine() {
        var l = LessonRun(FracLine3.spec, numbers: FracLine3.numbers(a: 3, b: 4))
        XCTAssertEqual(move(&l, ["s": 5]), .notYet("That's past 1."))
        XCTAssertEqual(move(&l, ["s": 2]), .notYet("Hop all the way to 1."))
        XCTAssertEqual(move(&l, ["s": 4]), .moved(1))
        XCTAssertEqual(move(&l, ["j": 4]), .notYet("That's past the point."))
        XCTAssertEqual(move(&l, ["j": 3]), .moved(2))
        XCTAssertEqual(move(&l, ["t": 3, "b": 5]), .notYet("The bottom counts spaces, not tick marks. One whole has 4 spaces."))
        XCTAssertEqual(move(&l, ["t": 4, "b": 3]), .notYet("The bottom is the number of spaces in one whole: 4. The top is the number of hops: 3."))
        XCTAssertEqual(move(&l, ["t": 3, "b": 4]), .moved(3))
        XCTAssertEqual(l.words.say, "3 hops of 1/4 land on 3/4.")
        let two = FracLine3.numbers(a: 5, b: 3, w: 2)
        var m = LessonRun(FracLine3.spec, numbers: two)
        XCTAssertEqual(FracLine3.Parts(two).ts, 8)
        _ = move(&m, ["s": 3]); _ = move(&m, ["j": 5])
        XCTAssertEqual(move(&m, ["t": 5, "b": 6]), .notYet("The bottom counts the spaces in one whole, 0 to 1. That's 3."))
        XCTAssertEqual(move(&m, ["t": 5, "b": 3]), .moved(3))
        XCTAssertEqual(m.words.say, "5 hops of 1/3: past 1, because 5 is more than 3.")
        for i in 0..<10 {
            each(FracLine3.spec, i) { n in
                let P = FracLine3.Parts(n)
                XCTAssertEqual(Fr3.whole % (P.w * P.b), 0)
                XCTAssertNotEqual(P.a % P.b, 0)
                if P.w == 2 { XCTAssertTrue(P.a > P.b && P.b <= 6) }
            }
        }
    }

    func testEqualFractions() {
        var l = LessonRun(Equiv3.spec, numbers: Equiv3.same(a: 3, b: 4, d: 8))
        XCTAssertEqual(l.words.say, "Drag the point under 3/4.")
        XCTAssertEqual(move(&l, ["m": 5]), .notYet("That's 5 eighths. 1 more."))
        XCTAssertEqual(move(&l, ["m": 7]), .notYet("That's past it."))
        XCTAssertEqual(move(&l, ["m": 6]), .moved(1))
        XCTAssertEqual(l.words.say, "Write 3/4 in eighths.")
        XCTAssertEqual(move(&l, ["t": 3, "b": 8]), .notYet("That's 3 eighths. Count the eighths to the point."))
        XCTAssertEqual(move(&l, ["t": 6, "b": 9]), .notYet("The bottom counts spaces, not tick marks. One whole has 8 spaces."))
        XCTAssertEqual(move(&l, ["t": 6, "b": 8]), .moved(2))
        XCTAssertEqual(l.words.say, "Same point, so they're the same amount.")
        var w = LessonRun(Equiv3.spec, numbers: Equiv3.wholes(n: 2, b: 4))
        XCTAssertEqual(move(&w, ["h": 9]), .notYet("That's past the point."))
        XCTAssertEqual(move(&w, ["h": 8]), .moved(1))
        XCTAssertEqual(w.words.say, "Write 2 in fourths.")
        XCTAssertEqual(move(&w, ["t": 2, "b": 4]), .notYet("That's 2 fourths. Count the hops to the point."))
        XCTAssertEqual(move(&w, ["t": 8, "b": 4]), .moved(2))
        XCTAssertEqual(w.words.say, "4 fourths make a whole, so 8 fourths make 2.")
        XCTAssertEqual(LessonRun(Equiv3.spec, numbers: Equiv3.wholes(n: 3, b: 1)).steps.last?.words.say, "1 piece makes a whole, so 3 pieces make 3.")
        for i in 0..<12 {
            each(Equiv3.spec, i) { n in
                let P = Equiv3.Parts(n)
                if P.kind == 1 { XCTAssertTrue(i == 6 || i == 10); XCTAssertEqual(Fr3.whole % (P.Lw * P.b), 0); return }
                XCTAssertEqual(P.a * P.d % P.b, 0)
                XCTAssertTrue(P.a < P.b && P.c >= 1 && P.c < P.d)
                if i < 3 { XCTAssertEqual(Set([P.b, P.d]), [2, 4]) }
            }
        }
    }

    func testComparing() {
        var l = LessonRun(Compare3.spec, numbers: Compare3.numbers(a: 3, b: 8, c: 5, d: 8))
        XCTAssertEqual(l.words.say, "Tap the one with more pieces.")
        XCTAssertEqual(move(&l, ["t": 0]), .notYet("3/8 is only 3 pieces. 5/8 is 5 of the same size."))
        XCTAssertEqual(move(&l, ["t": 1]), .moved(1))
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("Same size pieces, but 5/8 has more of them."))
        XCTAssertEqual(move(&l, ["c": 2]), .notYet("5/8 is the bigger amount. The open side of the sign faces the bigger fraction."))
        XCTAssertEqual(move(&l, ["c": 0]), .moved(2))
        XCTAssertEqual(l.words.say, "5/8 reaches further, so it's bigger.")
        var t = LessonRun(Compare3.spec, numbers: Compare3.numbers(a: 1, b: 4, c: 1, d: 8))
        XCTAssertEqual(move(&t, ["t": 1]), .notYet("8 is bigger than 4, but 8 pieces in a whole are smaller pieces."))
        XCTAssertEqual(move(&t, ["t": 0]), .moved(1))
        XCTAssertEqual(move(&t, ["c": 0]), .notYet("More pieces means smaller pieces. 1/4 is bigger, so the sign opens toward 1/4."))
        XCTAssertEqual(move(&t, ["c": 2]), .moved(2))
        var e = LessonRun(Compare3.spec, numbers: Compare3.numbers(a: 1, b: 2, c: 2, d: 4))
        let E = Compare3.Parts(Compare3.numbers(a: 1, b: 2, c: 2, d: 4))
        XCTAssertEqual(E.rulerText(4), "fourths: 2 in each half")
        XCTAssertEqual(e.words.say, "Drag the ruler to cut both into fourths.")
        XCTAssertEqual(move(&e, ["r": 8]), .notYet("That's eighths. Cut both into fourths."))
        XCTAssertEqual(move(&e, ["r": 4]), .moved(1))
        XCTAssertEqual(move(&e, ["c": 2]), .notYet("More pieces does not mean more. The shading lines up exactly, so they are equal."))
        XCTAssertEqual(move(&e, ["c": 1]), .moved(2))
        for i in 0..<10 {
            each(Compare3.spec, i) { n in
                let P = Compare3.Parts(n)
                if i < 3 { XCTAssertEqual(P.kind, 0) }
                if P.kind == 2 { XCTAssertEqual(P.s, 0) } else { XCTAssertNotEqual(P.s, 0) }
                XCTAssertTrue(P.a < P.b && P.c < P.d)
            }
        }
    }
}
