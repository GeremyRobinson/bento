import XCTest
@testable import ObentoCore

final class SortingShapesTests: XCTestCase {
    private typealias Box = SortingShapes.Box
    private func run(_ kind: Int, _ v: Int, mirrored: Bool = false) -> LessonRun {
        var l = LessonRun(SortingShapes.spec, numbers: SortingShapes.numbers(kind: kind, v: v, mirrored: mirrored)); l.skipAsk(); return l
    }
    private func move(_ l: inout LessonRun, _ v: Double) -> LessonRun.Outcome { l.set("x", v); return l.go() }
    private func parts(_ kind: Int, _ v: Int, mirrored: Bool = false) -> SortingShapes.Parts {
        SortingShapes.Parts(SortingShapes.numbers(kind: kind, v: v, mirrored: mirrored))
    }

    /// Every shape of the catalogue, sorted by its corners: the family it's in, its pairs and its square corners.
    func testCatalogueSortsByItsCorners() {
        let want: [[Box]] = [[.squares, .squares, .squares], [.rectangles, .rectangles, .rectangles], [.rhombuses, .rhombuses],
                             // the third "parallelogram" has four sides of 15 squares: a rhombus
                             [.parallelograms, .parallelograms, .rhombuses],
                             [.trapezoids, .trapezoids, .trapezoids], [.quadrilaterals, .quadrilaterals]]
        for (k, list) in SortingShapes.catalogue.enumerated() {
            XCTAssertEqual(list.count, want[k].count)
            for v in list.indices {
                for m in [false, true] {
                    let s = parts(k, v, mirrored: m)
                    XCTAssertEqual(s.smallest, want[k][v], "kind \(k) shape \(v) mirrored \(m)")
                    XCTAssertLessThanOrEqual(s.width, SortingShapes.widest, "never into the family picture")
                    XCTAssertLessThanOrEqual(s.height, 21)
                    XCTAssertEqual(s.corners.count, 4)
                }
            }
        }
        // trapezoids with and without square corners
        XCTAssertEqual(parts(4, 1).rights.count, 2)
        XCTAssertEqual(parts(4, 0).rights.count, 0)
        // the tilted square: every side 15 squares (9 across, 12 up), every corner square
        let tilted = parts(0, 1)
        XCTAssertEqual((0..<4).map { tilted.wholeLength($0) }, [15, 15, 15, 15])
        XCTAssertEqual(tilted.rights, [0, 1, 2, 3])
        XCTAssertEqual(tilted.pairs, [[0, 2], [1, 3]])
        // an other quadrilateral: no parallel sides, no square corners
        XCTAssertEqual(parts(5, 0).pairs, [])
        XCTAssertEqual(parts(5, 0).rights, [])
    }

    /// Mirrored: the same family, the corners still in order round it, left to right flipped.
    func testMirrored() {
        let a = parts(4, 1), b = parts(4, 1, mirrored: true)
        XCTAssertEqual(a.width, b.width)
        XCTAssertEqual(b.corners.map(\.x), a.corners.reversed().map { a.width - $0.x })
        XCTAssertEqual(b.rights.count, a.rights.count)
        XCTAssertEqual(b.pairs.count, 1)
    }

    /// A square, as in the preview's Say: every box around it named.
    func testSquareWalkThrough() {
        var l = run(0, 0)
        let s = SortingShapes.Parts(l.numbers)
        XCTAssertEqual(SortingShapes.spec.master, "shapes")
        XCTAssertEqual(l.display, [.text("Sort the shape.")])
        XCTAssertEqual(l.words.say, "Tap two sides that are parallel. Parallel sides go the same way. When there are no more, tap No more.")
        XCTAssertEqual(l.words.action, "No more")
        // sides 0 and 1 aren't parallel: measured on the grid
        XCTAssertEqual(move(&l, 101), .notYet("Not parallel: one goes straight across, the other straight up."))
        XCTAssertEqual(l.misses, 1)
        XCTAssertEqual(l.picture["ring"], 1)
        XCTAssertEqual(move(&l, 0), .notYet("Look again: two sides go the same way."))
        XCTAssertEqual(move(&l, 1), .notYet("There’s another parallel pair."))
        XCTAssertEqual(move(&l, 2), .moved(2))

        XCTAssertEqual(l.words.say, "Tap every square corner. When there are no more, tap No more.")
        XCTAssertEqual(move(&l, 3), .notYet("There’s another square corner."))
        XCTAssertEqual(move(&l, 4), .moved(3))

        XCTAssertEqual(l.words.say, "Tap the smallest box it fits in. Its sides are counted in squares.")
        XCTAssertEqual(move(&l, Double(Box.rectangles.rawValue)), .notYet("It fits there. Is there a smaller box inside that it fits in too?"))
        XCTAssertEqual(move(&l, Double(Box.quadrilaterals.rawValue)), .notYet("It fits there. Is there a smaller box inside that it fits in too?"))
        XCTAssertEqual(move(&l, Double(Box.squares.rawValue)), .moved(4))
        XCTAssertEqual(l.words.say, "It’s a square. So it’s also a rectangle, a rhombus, a parallelogram, a trapezoid and a quadrilateral.")
        XCTAssertEqual(s.why, l.words.say)
        XCTAssertEqual(l.go(), .newProblem)
    }

    /// Measured misses: a tilted side and a slanting side; a corner wider or narrower than square; a box it doesn't fit.
    func testMisses() {
        // the rhombus (0,9) (12,0) (24,9) (12,18): side 0 goes 4 across, 3 up; side 1 goes 4 across, 3 down
        var r = run(2, 0)
        XCTAssertEqual(move(&r, 101), .notYet("Not parallel: one goes 4 across, 3 up, the other 4 across, 3 down."))
        XCTAssertEqual(move(&r, 2), .moved(2))
        // no square corners: No more at once is right; the corner at (0, 9) is narrower, at (12, 0) wider
        let s = SortingShapes.Parts(r.numbers)
        XCTAssertEqual(s.rights, [])
        XCTAssertEqual(move(&r, 100), .notYet("That corner isn’t square. It’s narrower than a grid square’s corner."))
        XCTAssertEqual(move(&r, 101), .notYet("That corner isn’t square. It’s wider than a grid square’s corner."))
        XCTAssertEqual(move(&r, 0), .moved(3))
        XCTAssertEqual(move(&r, Double(Box.rectangles.rawValue)), .notYet("Rectangles need 4 square corners."))
        XCTAssertEqual(move(&r, Double(Box.squares.rawValue)), .notYet("Squares need 4 square corners and 4 equal sides."))
        XCTAssertEqual(move(&r, Double(Box.rhombuses.rawValue)), .moved(4))
        XCTAssertEqual(r.words.say, "It’s a rhombus. So it’s also a parallelogram, a trapezoid and a quadrilateral.")

        // a trapezoid: one pair; parallelograms need two
        var t = run(4, 1)
        XCTAssertEqual(SortingShapes.Parts(t.numbers).pairs, [[0, 2]])
        XCTAssertEqual(move(&t, 1), .moved(2))
        XCTAssertEqual(move(&t, 2), .moved(3))
        XCTAssertEqual(move(&t, Double(Box.parallelograms.rawValue)), .notYet("Parallelograms need 2 pairs of parallel sides."))
        XCTAssertEqual(move(&t, Double(Box.trapezoids.rawValue)), .moved(4))
        XCTAssertEqual(t.words.say, "It’s a trapezoid. So it’s also a quadrilateral.")

        // a quadrilateral: no pairs, so No more at once is right; only its own box
        var q = run(5, 1)
        XCTAssertEqual(move(&q, 0), .moved(2))
        XCTAssertEqual(move(&q, 0), .moved(3))
        XCTAssertEqual(move(&q, Double(Box.trapezoids.rawValue)), .notYet("Trapezoids need at least one pair of parallel sides."))
        XCTAssertEqual(move(&q, Double(Box.quadrilaterals.rawValue)), .moved(4))
        XCTAssertEqual(q.words.say, "It’s a quadrilateral. It has 4 sides, but no parallel sides.")
    }

    func testHowASideGoes() {
        let p = parts(3, 0) // (6,0) (24,0) (18,8) (0,8)
        XCTAssertEqual(p.how(0), "straight across")
        XCTAssertEqual(p.how(1), "3 across, 4 up")
        XCTAssertEqual(p.how(3), "3 across, 4 up")
        XCTAssertEqual(parts(1, 0).how(1), "straight up")
    }

    func testGeneratorAndCheck() {
        var rng = SeededRandom(seed: 4)
        var families: Set<Int> = [], mirrored = 0
        for i in 0..<2000 {
            let n = SortingShapes.spec.generate(&rng, i % 10), s = SortingShapes.Parts(n)
            families.insert(s.smallest.rawValue)
            if n["m"] == 1 { mirrored += 1 }
            XCTAssertLessThanOrEqual(s.width, SortingShapes.widest)
            XCTAssertEqual(LessonRun(SortingShapes.spec, numbers: n).steps.count, 5)
        }
        XCTAssertEqual(families.count, 6, "every family comes up")
        XCTAssertTrue((800...1200).contains(mirrored), "mirrored at random")
        for item in SortingShapes.spec.check {
            for _ in 0..<100 { XCTAssertTrue(item.when?(item.draw(SortingShapes.spec, using: &rng)) ?? true) }
        }
        XCTAssertEqual(SortingShapes.spec.requiredKeys, ["kind", "v", "m"])
    }
}
