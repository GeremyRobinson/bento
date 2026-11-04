import XCTest
@testable import ObentoCore

/// 4th grade, chapter 4: Fractions (design/grade4.md, the preview design/prototype/grade4-ch4.html).
final class FractionsG4Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func type(_ l: inout LessonRun, _ x: Int, box: String = "x") -> LessonRun.Outcome {
        l.reset(); l.active = box; for ch in String(x) { l.type(String(ch)) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(91 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(4)[3]
        XCTAssertEqual(ch.title, "Fractions")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
    }

    func testWholes() {
        XCTAssertEqual(Fractions4.whole(8), 48)
        XCTAssertEqual(Fractions4.whole(10), 40)
        XCTAssertEqual(Fractions4.whole(15), 45)
        XCTAssertEqual(Fractions4.whole(18), 36)
        XCTAssertEqual(Fractions4.whole(25), 50)
        XCTAssertEqual(Fractions4.whole(30), 60)
        XCTAssertEqual(Fractions4.piece(2), "halves")
        XCTAssertEqual(Fractions4.aPiece(8), "an eighth")
        XCTAssertEqual(Fractions4.aPiece(3), "a third")
        // every bottom any of these lessons makes cuts its whole into whole squares
        for n in [2, 3, 4, 5, 6, 8, 9, 10, 12, 15, 18, 20, 24, 25, 30] { XCTAssertEqual(Fractions4.whole(n) % n, 0, "\(n)") }
    }

    // MARK: Breaking fractions apart

    func testUnitPieces() {
        var l = LessonRun(Decompose.spec, numbers: Decompose.unit(a: 5, d: 8))
        XCTAssertEqual(l.words.say, "Break it into pieces of 1/8. Tap each line between the shaded pieces.")
        _ = l.go()
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["x": -1]), .notYet("Split between the shaded pieces."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(2))
        XCTAssertEqual(l.words.say, "How many pieces of 1/8?")
        XCTAssertEqual(type(&l, 8), .notYet("8 is the bottom: it says how big the pieces are. Count the pieces."))
        XCTAssertEqual(type(&l, 4), .notYet("That counts the gaps. Count the pieces."))
        XCTAssertEqual(type(&l, 3), .notYet("Count the pieces of 1/8."))
        XCTAssertEqual(type(&l, 5), .moved(3))
        XCTAssertEqual(l.words.say, "5 eighths are 5 pieces of 1/8.")
    }

    func testTwoWays() {
        let P = Decompose.Parts(Decompose.twoWays(a: 5, d: 8))
        XCTAssertEqual(P.parts([2]), [2, 3])
        XCTAssertEqual(P.sum([2]), "2/8 + 3/8")
        XCTAssertTrue(P.same([2], [3]))
        XCTAssertFalse(P.same([2], [1]))
        XCTAssertEqual(P.parts([1, 3]), [1, 2, 2])
        var l = LessonRun(Decompose.spec, numbers: Decompose.twoWays(a: 5, d: 8))
        XCTAssertEqual(l.words.say, "Break it into two parts. Tap a line between the shaded pieces.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["x": 6]), .notYet("Split between the shaded pieces."))
        XCTAssertEqual(move(&l, ["x": 2]), .moved(2))
        XCTAssertEqual(l.words.say, "Now break the copy another way. Tap lines between its shaded pieces.")
        XCTAssertEqual(move(&l, ["x": 102]), .notYet("That’s 2/8 + 3/8 again. Split it somewhere else."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "The same 5 pieces, grouped another way.")
    }

    func testWholesAndAPart() {
        var l = LessonRun(Decompose.spec, numbers: Decompose.wholes(w: 2, n: 1, d: 8))
        XCTAssertEqual(l.words.say, "How many eighths make each whole? Tap each whole bar.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["x": -1]), .notYet("That one isn’t a whole. Tap the bars named 1."))
        XCTAssertEqual(move(&l, ["x": 2]), .moved(2))
        XCTAssertEqual(l.words.say, "Each whole is 8 eighths.")
    }

    func testDecomposeGenerator() {
        for i in 0..<12 {
            each(Decompose.spec, i, 150) { x in
                let s = Decompose.Parts(x), kind = i < 3 ? 0 : i < 5 ? 1 : i == 5 ? 2 : (i - 6) % 3
                XCTAssertEqual(s.kind, kind)
                XCTAssertEqual(s.W % s.d, 0)
                switch s.kind {
                case 0: XCTAssertTrue((2..<s.d).contains(s.a)); if i < 3 { XCTAssertLessThanOrEqual(s.d, 6) }
                case 1: XCTAssertTrue((3..<s.d).contains(s.a)); if i == 4 { XCTAssertGreaterThanOrEqual(s.d, 8) }
                default:
                    XCTAssertTrue((1...3).contains(s.w)); XCTAssertTrue((1..<s.d).contains(s.n)); XCTAssertEqual(gcd(s.n, s.d), 1)
                    XCTAssertLessThanOrEqual(s.d, 8)
                }
            }
        }
        let c = checks(Decompose.spec).map(Decompose.Parts.init)
        XCTAssertEqual(c.map(\.kind), [0, 1, 1, 2])
        XCTAssertGreaterThanOrEqual(c[2].d, 8)
    }

    // MARK: Equivalent fractions

    func testEquivalent() {
        let P = EquivFractions.Parts(EquivFractions.numbers(a: 1, b: 2, k: 4))
        XCTAssertEqual(P.W, 48); XCTAssertEqual(P.pb, 24); XCTAssertEqual(P.pN, 6)
        XCTAssertEqual(P.sizes, [1, 2, 3, 4, 6, 8, 12, 24])
        XCTAssertEqual(P.reads(6), "Eighths: each half into 4")
        XCTAssertEqual(P.reads(24), "Halves")
        var l = LessonRun(EquivFractions.spec, numbers: EquivFractions.numbers(a: 1, b: 2, k: 4))
        XCTAssertEqual(l.words.say, "Cut the lower bar into eighths. Drag the ruler, then tap Cut.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("Drag the ruler to make the pieces smaller."))
        XCTAssertEqual(move(&l, ["x": 6]), .notYet("Those are sixths. Cut into eighths."))
        XCTAssertEqual(move(&l, ["x": 8]), .moved(2))
        XCTAssertEqual(l.words.say, "How many eighths are shaded? The shaded part hasn’t moved.")
        XCTAssertEqual(type(&l, 1), .notYet("Whatever you multiply the bottom by, multiply the top by too."))
        XCTAssertEqual(type(&l, 7), .notYet("Multiply the top by 4."))
        XCTAssertEqual(type(&l, 8), .notYet("8 is all the pieces. Count the shaded ones."))
        XCTAssertEqual(type(&l, 5), .notYet("Cutting is times, not plus. Multiply the top by 4."))
        XCTAssertEqual(type(&l, 3), .notYet("Count the shaded eighths."))
        XCTAssertEqual(type(&l, 4), .moved(3))
        XCTAssertEqual(l.words.say, "Every piece cut into 4: 4 times the pieces, the same amount.")
    }

    func testEquivalentGenerator() {
        each(EquivFractions.spec, 0) { x in
            let s = EquivFractions.Parts(x)
            XCTAssertTrue((2...6).contains(s.b)); XCTAssertTrue((2...5).contains(s.k)); XCTAssertEqual(gcd(s.a, s.b), 1)
            XCTAssertEqual(s.W % s.N, 0)
            XCTAssertTrue(s.sizes.contains(s.pN))
        }
        let c = checks(EquivFractions.spec).map(EquivFractions.Parts.init)
        XCTAssertEqual(c[0].a, 1); XCTAssertGreaterThan(c[1].a, 1); XCTAssertGreaterThanOrEqual(c[2].k, 4)
        XCTAssertTrue(c[3].a > 1 && c[3].b >= 5)
    }

    // MARK: Comparing fractions

    func testCompare() {
        let P = CompareFractions.Parts(CompareFractions.numbers(a: 2, b: 3, c: 3, d: 4))
        XCTAssertEqual(P.L, 12); XCTAssertEqual(P.A, 8); XCTAssertEqual(P.C, 9); XCTAssertEqual(P.k, 0)
        XCTAssertEqual(P.W, 48); XCTAssertEqual(P.p1, 16); XCTAssertEqual(P.p2, 12); XCTAssertEqual(P.pL, 4)
        XCTAssertNil(P.cut(12))
        var l = LessonRun(CompareFractions.spec, numbers: CompareFractions.numbers(a: 2, b: 3, c: 3, d: 4))
        XCTAssertEqual(l.words.say, "Cut both bars into pieces of one size. Drag the ruler, then tap Cut.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["x": 6]), .notYet("That cut misses a fourth."))
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("That cut misses a third."))
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("That cut misses a fourth."))
        XCTAssertEqual(move(&l, ["x": 24]), .notYet("Those fit. Bigger pieces fit too."))
        XCTAssertEqual(move(&l, ["x": 12]), .moved(2))
        XCTAssertEqual(l.words.say, "Which is more? Tap <, = or >.")
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("They’d be equal only with the same number of twelfths. 8 and 9 are not the same."))
        XCTAssertEqual(move(&l, ["c": 2]), .notYet("8/12 has fewer pieces than 9/12. So 2/3 is less than 3/4."))
        XCTAssertEqual(move(&l, ["c": 0]), .moved(3))
        XCTAssertEqual(l.words.say, "8 twelfths is less than 9 twelfths.")
        // tops alone point the wrong way
        let Q = CompareFractions.Parts(CompareFractions.numbers(a: 2, b: 3, c: 3, d: 5))
        XCTAssertEqual(Q.k, 2)
        XCTAssertEqual(Q.wrong(0), "Tops only compare when the pieces are the same size.")
        let B = CompareFractions.Parts(CompareFractions.numbers(a: 3, b: 4, c: 1, d: 6))
        XCTAssertEqual(B.wrong(0), "A bigger bottom means smaller pieces. Compare 9/12 and 2/12 instead.")
        // the same amount
        let E = CompareFractions.Parts(CompareFractions.numbers(a: 1, b: 2, c: 3, d: 6))
        XCTAssertEqual(E.k, 1)
        XCTAssertEqual(E.wrong(0), "1/2 and 3/6 are both 3/6: the same amount, cut into different pieces.")
        XCTAssertEqual(E.why, "Both are 3 sixths: the same amount.")
    }

    func testCompareGenerator() {
        for i in [0, 3, 4, 8] {
            each(CompareFractions.spec, i) { x in
                let s = CompareFractions.Parts(x)
                XCTAssertNotEqual(s.b, s.d)
                XCTAssertTrue((1..<s.b).contains(s.a)); XCTAssertTrue((1..<s.d).contains(s.c))
                XCTAssertLessThanOrEqual(s.L, 20)
                XCTAssertEqual(s.W % s.L, 0)
                XCTAssertTrue(s.sizes.contains(s.pL))
                if i < 4 { XCTAssertEqual(s.L, max(s.b, s.d)) }
            }
        }
        let c = checks(CompareFractions.spec).map(CompareFractions.Parts.init)
        XCTAssertEqual(c[1].k, 1)
        XCTAssertTrue(c[2].L != c[2].b && c[2].L != c[2].d)
        XCTAssertTrue(c[3].L != c[3].b && c[3].L != c[3].d && CompareFractions.cmp(c[3].a, c[3].c) != c[3].k)
    }

    // MARK: Adding and subtracting like fractions

    func testAddLike() {
        var l = LessonRun(LikeFractions.add, numbers: LikeFractions.numbers(a: 2, c: 3, d: 8, sub: false))
        XCTAssertEqual(l.words.say, "Put the pieces together. Slide the striped pieces into the top bar.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["s": 0]), .notYet("Put them in the top bar."))
        XCTAssertEqual(move(&l, ["s": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Write how much in all.")
        XCTAssertEqual(move(&l, ["T": 6, "B": 8]), .notYet("Putting the pieces together is adding: count them all."))
        XCTAssertEqual(move(&l, ["T": 5, "B": 16]), .notYet("Eighths and eighths are still eighths."))
        XCTAssertEqual(move(&l, ["T": 5, "B": 5]), .notYet("The pieces are still eighths, so the bottom stays 8."))
        XCTAssertEqual(move(&l, ["T": 4, "B": 8]), .notYet("Count the shaded eighths."))
        XCTAssertEqual(move(&l, ["T": 5, "B": 8]), .moved(3))
        XCTAssertEqual(l.words.say, "Same-size pieces, so the tops add.")
        // past a whole
        var m = LessonRun(LikeFractions.add, numbers: LikeFractions.numbers(a: 5, c: 4, d: 6, sub: false))
        _ = m.go(); _ = move(&m, ["s": 1])
        XCTAssertEqual(m.words.say, "Write how much in all. More than 1 is fine here.")
        XCTAssertEqual(move(&m, ["T": 8, "B": 6]), .notYet("Count the shaded sixths in both bars."))
    }

    func testTakeLike() {
        var l = LessonRun(LikeFractions.take, numbers: LikeFractions.numbers(a: 7, c: 2, d: 8, sub: true))
        XCTAssertEqual(l.words.say, "Take the striped pieces away. Slide them onto the shaded ones.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["s": 0]), .notYet("Slide them onto the shaded pieces."))
        XCTAssertEqual(move(&l, ["s": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Write what’s left.")
        XCTAssertEqual(move(&l, ["T": 9, "B": 8]), .notYet("2/8 is taken away, so there’s less."))
        XCTAssertEqual(move(&l, ["T": 5, "B": 0]), .notYet("The pieces are still eighths."))
        XCTAssertEqual(move(&l, ["T": 4, "B": 8]), .notYet("Count the eighths that aren’t crossed out."))
        XCTAssertEqual(move(&l, ["T": 5, "B": 8]), .moved(3))
        XCTAssertEqual(l.words.say, "Same-size pieces, so the tops are taken away.")
        let s = LikeFractions.Parts(LikeFractions.numbers(a: 5, c: 2, d: 5, sub: true, story: 1))
        XCTAssertEqual(s.text, "A ribbon is 1 m long. Mia cuts off 2/5 m. How much ribbon is left?")
    }

    func testLikeGenerators() {
        for i in 0..<8 {
            each(LikeFractions.add, i) { x in
                let s = LikeFractions.Parts(x)
                XCTAssertEqual(gcd(s.R, s.d), 1); XCTAssertNotEqual(s.R, s.d)
                if i < 3 { XCTAssertLessThan(s.R, s.d); XCTAssertLessThanOrEqual(s.d, 6) }
            }
            each(LikeFractions.take, i) { x in
                let s = LikeFractions.Parts(x)
                XCTAssertTrue(s.sub); XCTAssertGreaterThan(s.R, 0); XCTAssertEqual(gcd(s.R, s.d), 1)
                XCTAssertTrue((2...s.d).contains(s.a)); XCTAssertTrue((1..<s.a).contains(s.c))
                if i < 3 { XCTAssertLessThan(s.a, s.d) }
            }
        }
        let a = checks(LikeFractions.add).map(LikeFractions.Parts.init)
        XCTAssertGreaterThan(a[1].a + a[1].c, a[1].d); XCTAssertLessThan(a[2].a + a[2].c, a[2].d)
        XCTAssertTrue(LikeFractions.add.check[3].story)
        let t = checks(LikeFractions.take).map(LikeFractions.Parts.init)
        XCTAssertEqual(t[1].a, t[1].d)
    }

    func testStoryAsksTheSign() {
        let l = LessonRun(LikeFractions.take, numbers: LikeFractions.numbers(a: 3, c: 1, d: 4, sub: true, story: 2), story: true)
        XCTAssertEqual(l.words.say, "A jug holds 3/4 L of juice. Leo drinks 1/4 L. How much juice is left?")
    }
}
