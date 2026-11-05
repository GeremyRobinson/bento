import XCTest
@testable import ObentoCore

/// 3rd grade, chapter 4: Shapes and area (design/grade3.md, the preview design/prototype/grade3-ch4.html).
final class Shapes3Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 200, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(71 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(3)[3]
        XCTAssertEqual(ch.title, "Shapes and area")
        for l in ch.lessons where Curriculum.built(l.id) { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertFalse(Curriculum.voiced(l.id)) }
    }

    func testClassify() {
        XCTAssertEqual(Quads3.classify([(0, 0), (20, 0), (20, 20), (0, 20)]).name, 0)
        XCTAssertEqual(Quads3.classify([(0, 0), (30, 0), (30, 14), (0, 14)]).name, 1)
        XCTAssertEqual(Quads3.classify([(5, 0), (18, 0), (13, 12), (0, 12)]).name, 2)
        XCTAssertEqual(Quads3.classify([(5, 0), (30, 0), (25, 12), (0, 12)]).name, 3)
        XCTAssertEqual(Quads3.classify([(5, 0), (25, 0), (30, 12), (0, 12)]).name, 4)
        XCTAssertEqual(Quads3.madeCode([(0, 0), (20, 0), (20, 20), (0, 20)]), 0)
        XCTAssertEqual(Quads3.madeCode([(0, 0), (20, 0), (25, 20), (0, 20)]), 4)
        XCTAssertEqual(Quads3.madeCode([(0, 0), (20, 0), (0, 20), (20, 20)]), -2)
        XCTAssertEqual(Quads3.madeCode([(0, 0), (20, 0), (10, 5), (0, 20)]), -3)
        XCTAssertEqual(Quads3.madeCode([(0, 0), (20, 0), (21, 1), (0, 20)]), -1)
        // a trapezoid's legs close in: 12 squares apart at one end of the top... measured square on
        let d = Quads3.closeIn([(5, 0), (25, 0), (30, 12), (0, 12)], 1).d
        XCTAssertEqual(d.count, 2)
        XCTAssertNotEqual(d[0], d[1])
    }

    func testQuadsRectangle() {
        var l = LessonRun(Quads3.spec, numbers: Quads3.numbers(shape: 1, v: [(0, 0), (30, 0), (30, 14), (0, 14)], warm: true))
        XCTAssertEqual(l.steps.count, 7)
        XCTAssertEqual(l.words.say, "Tap each side.")
        XCTAssertEqual(move(&l, ["s": -1]), .notYet("Tap a side: one of the lines around the edge."))
        XCTAssertEqual(l.misses, 0)
        XCTAssertEqual(move(&l, ["s": 4]), .moved(1))
        XCTAssertEqual(l.words.say, "Tap the square corners.")
        XCTAssertEqual(move(&l, ["c": 3]), .notYet("One more corner fits a paper corner."))
        XCTAssertEqual(move(&l, ["c": 4]), .moved(2))
        XCTAssertEqual(move(&l, ["l": -2]), .notYet("That side is measured. Tap the others."))
        XCTAssertEqual(move(&l, ["l": 4]), .moved(3))
        XCTAssertEqual(move(&l, ["e": 1]), .notYet("Compare them: some sides are longer than others."))
        XCTAssertEqual(move(&l, ["e": 0]), .moved(4))
        XCTAssertEqual(move(&l, ["p": 50]), .notYet("Those two meet at a corner."))
        XCTAssertEqual(move(&l, ["p": 1]), .notYet("There's another pair that never meets."))
        XCTAssertEqual(move(&l, ["p": 2]), .moved(5))
        XCTAssertEqual(move(&l, ["n": 0]), .notYet("A square has 4 equal sides. These aren't all equal."))
        XCTAssertEqual(move(&l, ["n": 5]), .notYet("It is a quadrilateral, but it has a more special name. Look at its sides and corners."))
        XCTAssertEqual(move(&l, ["n": 1]), .moved(6))
        XCTAssertEqual(l.words.say, "4 square corners, but the sides aren't all equal.")
    }

    func testQuadsTrapezoidAndAlso() {
        var t = LessonRun(Quads3.spec, numbers: Quads3.numbers(shape: 4, v: [(5, 0), (25, 0), (30, 12), (0, 12)]))
        XCTAssertEqual(move(&t, ["c": 100]), .notYet("That corner is wider than a square corner."))
        XCTAssertEqual(move(&t, ["c": 101]), .notYet("That corner is wider than a square corner."))
        XCTAssertEqual(move(&t, ["c": 102]), .notYet("That corner is narrower than a square corner."))
        XCTAssertEqual(move(&t, ["c": 0]), .moved(1))
        XCTAssertEqual(move(&t, ["l": 4]), .moved(2))
        XCTAssertEqual(move(&t, ["e": 0]), .moved(3))
        if case .notYet(let s) = move(&t, ["p": 101]) { XCTAssertTrue(s.hasPrefix("They close in: ")) } else { XCTFail() }
        XCTAssertEqual(move(&t, ["p": 1]), .moved(4))
        XCTAssertEqual(move(&t, ["n": 3]), .notYet("A parallelogram has 2 pairs of parallel sides."))
        XCTAssertEqual(move(&t, ["n": 4]), .moved(5))
        XCTAssertEqual(t.words.say, "Only 1 pair of parallel sides: its most special name is trapezoid.")
        var a = LessonRun(Quads3.spec, numbers: Quads3.numbers(shape: 0, v: [(0, 0), (20, 0), (20, 20), (0, 20)], also: true))
        XCTAssertEqual(a.steps.count, 7)
        for b in [["c": 4.0], ["l": 4], ["e": 1], ["p": 2]] { _ = move(&a, b) }
        XCTAssertEqual(move(&a, ["n": 1]), .notYet("It is a rectangle, but all 4 sides are equal too. Its most special name is square."))
        XCTAssertEqual(move(&a, ["n": 0]), .moved(5))
        XCTAssertEqual(a.words.say, "Tap Yes or No: is this square also a rectangle?")
        XCTAssertEqual(move(&a, ["a": 0]), .notYet("A rectangle needs 4 square corners. A square has them, so every square is a rectangle."))
        XCTAssertEqual(move(&a, ["a": 1]), .moved(6))
        XCTAssertEqual(a.words.say, "Every square is a rectangle.")
    }

    func testQuadsMake() {
        var l = LessonRun(Quads3.spec, numbers: Quads3.numbers(shape: 0, v: [(0, 0), (20, 0), (20, 20), (0, 20)], make: true))
        XCTAssertEqual(l.steps.count, 3)
        XCTAssertEqual(move(&l, ["m": 1]), .notYet("It's still a rectangle: 4 square corners."))
        XCTAssertEqual(move(&l, ["m": -2]), .notYet("The sides cross. Keep 4 sides."))
        for (k, v) in ["made": 4.0, "mR": 2, "mE": 0, "mP": 1] { l.keep(k, v) }
        XCTAssertEqual(move(&l, ["m": 4]), .moved(1))
        XCTAssertEqual(move(&l, ["n": 3]), .notYet("A parallelogram has 2 pairs of parallel sides."))
        XCTAssertEqual(move(&l, ["n": 4]), .moved(2))
    }

    func testQuadsGenerator() {
        for i in 0..<12 {
            each(Quads3.spec, i, 40) { n in
                let P = Quads3.Parts(n), c = P.cls
                XCTAssertEqual(c.name, P.shape)
                XCTAssertTrue(c.convex)
                XCTAssertLessThanOrEqual(P.w, 42); XCTAssertLessThanOrEqual(P.h, 26)
                XCTAssertTrue(c.lens.allSatisfy { $0 >= 8 && $0 == $0.rounded() })
                if i < 3 { XCTAssertEqual(P.shape, [0, 1, 4][i]); XCTAssertTrue(P.warm) }
                if i % 4 == 3 { XCTAssertTrue(P.also); XCTAssertLessThanOrEqual(P.shape, 1) }
                if i == 6 { XCTAssertTrue(P.make) }
            }
        }
    }

    func testArea() {
        var l = LessonRun(Area3.spec, numbers: Area3.numbers(l: 7, w: 4, unit: 1))
        XCTAssertEqual(l.words.say, "A rug is 7 ft by 4 ft. Drag across the top row to tile it. 1 tile is 4 × 4 squares here.")
        XCTAssertEqual(move(&l, ["n": 5]), .notYet("The row has 7. Keep going."))
        XCTAssertEqual(l.misses, 0)
        XCTAssertEqual(move(&l, ["n": 7]), .moved(1))
        XCTAssertEqual(move(&l, ["r": 3]), .notYet("That's 3 rows. The rectangle has 4."))
        XCTAssertEqual(move(&l, ["r": 4]), .moved(2))
        XCTAssertEqual(l.words.say, "Write 4 × 7.")
        XCTAssertEqual(move(&l, ["A": 22]), .notYet("22 is the distance around. Area counts the tiles inside."))
        XCTAssertEqual(move(&l, ["A": 11]), .notYet("7 + 4 counts one row and one column. Every row has 7 tiles, so multiply."))
        XCTAssertEqual(move(&l, ["A": 21]), .notYet("That's 3 rows. Count all 4 rows of 7."))
        XCTAssertEqual(move(&l, ["A": 28]), .moved(3))
        XCTAssertEqual(l.words.say, "4 rows of 7 tiles: 28 square feet.")
        each(Area3.spec, 0) { n in let P = Area3.Parts(n); XCTAssertTrue((3...5).contains(P.l) && (2...4).contains(P.w) && P.unit == 0) }
        each(Area3.spec, 3) { n in let P = Area3.Parts(n); XCTAssertTrue((3...10).contains(P.l) && (2...8).contains(P.w) && P.unit == 1) }
        each(Area3.spec, 7) { n in XCTAssertEqual(Area3.Parts(n).unit, 0) }
    }

    /// Tiles and centimetres are the biggest of 5, 4, 3 squares that keep the problem at 75% (not one square a unit).
    func testSizes() {
        XCTAssertEqual(Area3.Parts(Area3.numbers(l: 5, w: 4)).c, 5)
        XCTAssertNil(Area3.Parts(Area3.numbers(l: 5, w: 4)).note)
        XCTAssertEqual(Area3.Parts(Area3.numbers(l: 9, w: 6, unit: 3)).c, 3)
        XCTAssertEqual(Area3.Parts(Area3.numbers(l: 10, w: 8)).c, 3)
        XCTAssertEqual(Area3.Parts(Area3.numbers(l: 9, w: 6, unit: 3)).note, "1 tile is 3 × 3 squares here.")
        XCTAssertEqual(LShape3.Parts(LShape3.numbers(W: 6, H: 5, w: 3, h: 3)).c, 5)
        XCTAssertEqual(LShape3.Parts(LShape3.numbers(W: 8, H: 6, w: 3, h: 2)).c, 4)
        XCTAssertEqual(LShape3.Parts(LShape3.numbers(W: 10, H: 8, w: 4, h: 3)).c, 3)
        XCTAssertEqual(Perim3.Parts(Perim3.numbers(kind: 0, a: 5, b: 3)).cell, 5)
        XCTAssertEqual(Perim3.Parts(Perim3.numbers(kind: 0, a: 15, b: 7)).cell, 2)
        XCTAssertEqual(Perim3.Parts(Perim3.numbers(kind: 1, a: 9)).cell, 2)
        XCTAssertEqual(Perim3.Parts(Perim3.numbers(kind: 2, a: 5, b: 10, c: 11)).tall, 10)
        XCTAssertEqual(PerimArea3.Parts(PerimArea3.fence(P: 16, q: 3, start: (7, 1))).c, 5)
        XCTAssertEqual(PerimArea3.Parts(PerimArea3.tiles(A: 24, p: 6, q: 4, start: (12, 2))).c, 3)
        XCTAssertEqual(G3.cell(9, 6, within: [(30, 27), (62, 12)]), 3)
        XCTAssertEqual(G3.cell(8, 6, wide: 28, tall: 28), 3)
    }

    func testLShape() {
        // a 7 × 5 with a 2 × 2 corner off the top right: down at 5 or across at 2
        let P = LShape3.Parts(LShape3.numbers(W: 7, H: 5, w: 2, h: 2))
        XCTAssertEqual(P.tot, 31)
        XCTAssertEqual(P.parts(down: true), [LShape3.Part(x0: 0, x1: 5, y0: 0, y1: 5), LShape3.Part(x0: 5, x1: 7, y0: 2, y1: 5)])
        XCTAssertEqual(P.parts(down: false), [LShape3.Part(x0: 0, x1: 5, y0: 0, y1: 2), LShape3.Part(x0: 0, x1: 7, y0: 2, y1: 5)])
        var l = LessonRun(LShape3.spec, numbers: LShape3.numbers(W: 7, H: 5, w: 2, h: 2))
        XCTAssertEqual(move(&l, ["k": 103]), .notYet("That leaves an L. Cut from the inside corner."))
        XCTAssertEqual(move(&l, ["k": 202]), .moved(1))
        l.keep("ax", 2)
        XCTAssertEqual(P.say(1, down: false), "Write 2 × 5.")
        XCTAssertEqual(move(&l, ["a": 7]), .notYet("5 + 2 counts one row and one column. Every row has 5 tiles, so multiply."))
        XCTAssertEqual(move(&l, ["a": 10]), .moved(2))
        XCTAssertEqual(move(&l, ["b": 20]), .notYet("Not quite. Count by 7s, once for each of the 3 rows."))
        XCTAssertEqual(move(&l, ["b": 21]), .moved(3))
        XCTAssertEqual(move(&l, ["s": 35]), .notYet("That counts the missing corner too."))
        XCTAssertEqual(move(&l, ["s": 21]), .notYet("That's one part. Add the other part too."))
        XCTAssertEqual(move(&l, ["s": 31]), .moved(4))
        XCTAssertEqual(l.words.say, "Two rectangles: add their areas.")
        // flipped to the bottom left: the inside corner moves with it
        let F = LShape3.Parts(LShape3.numbers(W: 8, H: 6, w: 3, h: 2, K: 3))
        XCTAssertEqual(F.X, 3); XCTAssertEqual(F.Y, 4)
        XCTAssertEqual(F.parts(down: true).map(\.area).reduce(0, +), F.tot)
        XCTAssertEqual(F.parts(down: false).map(\.area).reduce(0, +), F.tot)
        for i in [0, 3, 7] {
            each(LShape3.spec, i) { n in
                let Q = LShape3.Parts(n)
                XCTAssertLessThanOrEqual(Q.tot, 80)
                XCTAssertEqual(Q.parts(down: true).map(\.area).reduce(0, +), Q.tot)
                XCTAssertEqual(Q.parts(down: false).map(\.area).reduce(0, +), Q.tot)
                XCTAssertEqual(Q.hide != 0, i >= 6)
                if i < 3 { XCTAssertEqual(Q.K, 0) }
            }
        }
    }

    func testPerimeter() {
        var l = LessonRun(Perim3.spec, numbers: Perim3.numbers(kind: 0, a: 7, b: 4))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Trace around the edge. 1 cm is 4 squares.")
        XCTAssertEqual(move(&l, ["t": 11]), .moved(1))
        XCTAssertEqual(l.words.say, "Write 7 + 4.")
        XCTAssertEqual(move(&l, ["two": 28]), .notYet("Perimeter adds up lengths. 7 × 4 would be the squares inside."))
        XCTAssertEqual(move(&l, ["two": 11]), .moved(2))
        XCTAssertEqual(l.words.say, "Trace the other two sides.")
        XCTAssertEqual(move(&l, ["t": 22]), .moved(3))
        XCTAssertEqual(move(&l, ["P": 11]), .notYet("A rectangle has 4 sides. The two sides without labels are 7 cm and 4 cm too."))
        XCTAssertEqual(move(&l, ["P": 18]), .notYet("That's only 3 sides. Add the last 4 cm side too."))
        XCTAssertEqual(move(&l, ["P": 22]), .moved(4))
        XCTAssertEqual(l.words.say, "All the way around: every side counts once.")
        let R = Perim3.Parts(Perim3.numbers(kind: 0, a: 7, b: 4))
        XCTAssertEqual(R.label(2), "7 cm, like the top"); XCTAssertEqual(R.label(3), "4 cm, like the right")
        var s = LessonRun(Perim3.spec, numbers: Perim3.numbers(kind: 1, a: 5))
        XCTAssertEqual(s.steps.count, 3)
        XCTAssertEqual(move(&s, ["t": 20]), .moved(1))
        XCTAssertEqual(move(&s, ["P": 10]), .notYet("That's two sides. A square has 4 sides of 5 cm."))
        XCTAssertEqual(move(&s, ["P": 20]), .moved(2))
        var t = LessonRun(Perim3.spec, numbers: Perim3.numbers(kind: 2, a: 9, b: 7, c: 6))
        XCTAssertEqual(move(&t, ["t": 16]), .moved(1))
        XCTAssertEqual(move(&t, ["two": 16]), .moved(2))
        XCTAssertEqual(t.words.say, "Trace the last side.")
        XCTAssertEqual(move(&t, ["t": 22]), .moved(3))
        XCTAssertEqual(move(&t, ["P": 16]), .notYet("A triangle has 3 sides. Add the 6 cm side too."))
        XCTAssertEqual(move(&t, ["P": 22]), .moved(4))
        each(Perim3.spec, 1) { n in let P = Perim3.Parts(n); XCTAssertEqual(P.kind, 0); XCTAssertTrue(P.a > P.b && P.a <= 9 && P.b <= 6) }
        each(Perim3.spec, 5) { n in
            let P = Perim3.Parts(n)
            if P.kind == 2 { XCTAssertTrue(P.b + P.c - P.a >= 3 && P.a + P.c - P.b >= 3 && P.a + P.b - P.c >= 3) }
        }
    }

    func testSamePerimeter() {
        var m = LessonRun(PerimArea3.spec, numbers: PerimArea3.missing(P: 24, l: 8))
        XCTAssertEqual(m.words.say, "The fence is 24 m. One side is 8 m. Drag the other side. 1 square m is 4 × 4 squares here.")
        XCTAssertEqual(move(&m, ["d": 3]), .notYet("That fence is 22. It needs 24."))
        XCTAssertEqual(move(&m, ["d": 4]), .moved(1))
        XCTAssertEqual(move(&m, ["w": 16]), .notYet("24 − 8 is the other three sides."))
        XCTAssertEqual(move(&m, ["w": 8]), .notYet("8 is both short sides. Each one is 4."))
        XCTAssertEqual(move(&m, ["w": 12]), .notYet("12 is one long and one short side."))
        XCTAssertEqual(move(&m, ["w": 4]), .moved(2))
        var f = LessonRun(PerimArea3.spec, numbers: PerimArea3.fence(P: 16, q: 3, start: (7, 1)))
        let F = PerimArea3.Parts(PerimArea3.fence(P: 16, q: 3, start: (7, 1)))
        XCTAssertEqual(F.spots.map { [$0.0, $0.1] }, [[7, 1], [6, 2], [5, 3], [4, 4]])
        XCTAssertEqual(f.words.say, "Make a garden of 15 square m with a 16 m fence. Drag the corner.")
        XCTAssertEqual(move(&f, ["d": 602]), .notYet("That garden is 12 square m. It needs 15."))
        XCTAssertEqual(move(&f, ["d": 503]), .moved(1))
        XCTAssertEqual(move(&f, ["w": 16]), .notYet("16 is the fence. The area counts the tiles inside."))
        XCTAssertEqual(move(&f, ["w": 15]), .moved(2))
        var t = LessonRun(PerimArea3.spec, numbers: PerimArea3.tiles(A: 12, p: 4, q: 3, start: (6, 2)))
        XCTAssertEqual(t.words.say, "Make 12 tiles into a rectangle with a fence of 14. Drag the corner.")
        XCTAssertEqual(move(&t, ["d": 602]), .notYet("That fence is 16. It needs 14."))
        XCTAssertEqual(move(&t, ["d": 403]), .moved(1))
        XCTAssertEqual(move(&t, ["w": 7]), .notYet("That's two sides. Add all 4."))
        XCTAssertEqual(move(&t, ["w": 14]), .moved(2))
        for i in 0..<9 {
            each(PerimArea3.spec, i, 100) { n in
                let P = PerimArea3.Parts(n)
                XCTAssertEqual(P.kind, i < 3 ? 0 : (i - 3) % 3)
                XCTAssertTrue(P.P % 2 == 0 && P.P >= 12 && P.P <= 24)
                if P.kind > 0 { XCTAssertTrue(P.spots.contains { $0 == (P.p, P.q) }); XCTAssertTrue(P.spots.contains { $0 == P.start }) }
                if P.kind == 2 { XCTAssertFalse(P.start == (P.p, P.q)) }
            }
        }
    }
}
