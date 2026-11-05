import XCTest
@testable import ObentoCore

/// 2nd grade, chapter 7: Shapes (design/grade2.md, the preview design/prototype/grade2-ch7.html).
final class Shapes2Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func ok(_ l: inout LessonRun, _ set: [String: Double]) -> Bool { if case .moved = move(&l, set) { return true }; return false }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 200, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(77 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    // MARK: Sides and corners

    func testSidesName() {
        let pts: [(Int, Int)] = [(12, 0), (25, 9), (20, 22), (4, 22), (0, 9)]
        var l = LessonRun(Sides2.spec, numbers: Sides2.numbers(name: pts, variant: 0))
        XCTAssertEqual(l.steps.count, 3)
        XCTAssertEqual(l.words.say, "Count its corners.")
        XCTAssertEqual(move(&l, ["c": 0]), .notYet("Tap each corner."))
        XCTAssertEqual(move(&l, ["c": 4]), .notYet("One corner isn't counted yet."))
        XCTAssertEqual(move(&l, ["c": 2]), .notYet("3 corners aren't counted yet."))
        XCTAssertEqual(move(&l, ["c": -1]), .notYet("That corner is counted already."))
        XCTAssertTrue(ok(&l, ["c": 5]))
        XCTAssertEqual(l.words.say, "Tap its name.")
        XCTAssertEqual(move(&l, ["m": 3]), .notYet("A hexagon has 6 sides."))
        XCTAssertTrue(ok(&l, ["m": 2]))
        XCTAssertEqual(l.words.say, "5 sides and 5 corners make a pentagon, however it's turned.")
        XCTAssertEqual(Sides2.Parts(l.numbers).record, "5 sides, 5 corners: pentagon")
        XCTAssertEqual(Sides2.Parts(Sides2.numbers(draw: 6)).why, "6 sides and 6 corners make a hexagon, however it's turned.")
    }

    func testSquareIsAQuadrilateral() {
        let sq: [(Double, Double)] = [(0, 0), (20, 0), (20, 20), (0, 20)], rect: [(Double, Double)] = [(0, 0), (24, 0), (24, 12), (0, 12)]
        XCTAssertEqual(Sides2.pickCode(Sides2.facts(sq), 1), 1)
        XCTAssertEqual(Sides2.Parts.nameMiss(Sides2.pickCode(Sides2.facts(sq), 0)), "A square has 4 sides, so it's a quadrilateral too.")
        XCTAssertEqual(Sides2.Parts.nameMiss(Sides2.pickCode(Sides2.facts(rect), 2)), "A rectangle has 4 sides, so it's a quadrilateral too.")
        XCTAssertEqual(Sides2.Parts.nameMiss(Sides2.pickCode(Sides2.facts([(0, 0), (20, 0), (10, 15)]), 1)), "A quadrilateral has 4 sides.")
    }

    func testSidesDraw() {
        var l = LessonRun(Sides2.spec, numbers: Sides2.numbers(draw: 5))
        XCTAssertEqual(l.words.say, "Draw a shape with 5 corners.")
        let four: [(Double, Double)] = [(0, 0), (10, 0), (10, 10), (0, 10)]
        let line: [(Double, Double)] = [(0, 0), (5, 0), (10, 0)]
        let bow: [(Double, Double)] = [(0, 0), (10, 10), (10, 0), (0, 10)]
        let five: [(Double, Double)] = [(5, 0), (10, 4), (8, 10), (2, 10), (0, 4)]
        XCTAssertEqual(move(&l, ["d": Double(Sides2.drawn(5, four))]), .notYet("That has 4 sides. Draw 5."))
        XCTAssertEqual(move(&l, ["d": Double(Sides2.drawn(5, line))]), .notYet("Those corners are in a line."))
        XCTAssertEqual(move(&l, ["d": Double(Sides2.drawn(5, bow))]), .notYet("Two sides cross. Move a corner."))
        // a corner in the middle of a side isn't a corner
        let fourPlus: [(Double, Double)] = [(0, 0), (5, 0), (10, 0), (10, 10), (0, 10)]
        XCTAssertEqual(Sides2.drawn(5, fourPlus), -104)
        XCTAssertTrue(ok(&l, ["d": Double(Sides2.drawn(5, five))]))
    }

    func testSidesGenerator() {
        var rng = SeededRandom(seed: 3)
        for i in 0..<40 {
            let x = Sides2.spec.generate(&rng, i), P = Sides2.Parts(x)
            XCTAssertEqual(P.draw, i == 2 || (i > 2 && i % 2 == 0), "\(i)")
            if i == 0 { XCTAssertEqual(P.n, 3) }
            if i == 1 { XCTAssertEqual(P.n, 4); let f = Sides2.facts(P.pts); XCTAssertFalse(f.right && f.same) }
            if P.draw { continue }
            XCTAssertEqual(P.pts.count, P.n)
            XCTAssertLessThanOrEqual(P.w, 30); XCTAssertLessThanOrEqual(P.h, 24); XCTAssertGreaterThanOrEqual(max(P.w, P.h), 18)
            let f = Sides2.facts(P.pts)
            XCTAssertEqual(f.n, P.n); XCTAssertFalse(f.cross)
            for p in P.pts { XCTAssertEqual(p.0, p.0.rounded()); XCTAssertEqual(p.1, p.1.rounded()) }
        }
        for (i, x) in checks(Sides2.spec).enumerated() {
            let P = Sides2.Parts(x)
            if i == 0 { XCTAssertEqual(P.n, 5); XCTAssertFalse(P.draw) }
            if i == 1 { XCTAssertEqual(P.n, 6) }
            if i == 2 { XCTAssertEqual(P.n, 4); XCTAssertEqual(P.variant, 1) }
        }
    }

    // MARK: Faces, edges and corners

    func testSolidCounts() {
        let want: [(Int, Int, Int)] = [(6, 12, 8), (6, 12, 8), (5, 8, 5), (5, 9, 6)]
        for s in 0..<4 {
            let P = Solids2.Parts(Solids2.numbers(solid: s))
            XCTAssertEqual(P.faces, want[s].0); XCTAssertEqual(P.edges, want[s].1); XCTAssertEqual(P.corners, want[s].2)
            // every edge joins two faces; each corner is on 3 faces or more
            for e in P.geo.E { XCTAssertEqual(e.f.count, 2) }
            for vf in P.geo.VF { XCTAssertGreaterThanOrEqual(vf.count, 3) }
            // the base faces down
            XCTAssertTrue(P.geo.N.contains { $0.z < -0.9 })
        }
    }

    func testSolids() {
        var l = LessonRun(Solids2.spec, numbers: Solids2.numbers(solid: 1, turn: 0))
        XCTAssertEqual(l.steps.count, 6)
        XCTAssertEqual(l.words.say, "Tilt the paper.")
        XCTAssertEqual(move(&l, ["t": 0]), .notYet("Drag the paper up."))
        XCTAssertTrue(ok(&l, ["t": 1]))
        XCTAssertEqual(l.words.say, "Tap every face. Turn it to see more.")
        XCTAssertEqual(move(&l, ["f": -203]), .notYet("You can see 3. 3 more are hidden at the back and bottom."))
        XCTAssertEqual(move(&l, ["f": -101]), .notYet("A face you can see isn't counted yet."))
        XCTAssertEqual(move(&l, ["f": -102]), .notYet("2 faces you can see aren't counted yet."))
        XCTAssertEqual(move(&l, ["f": -301]), .notYet("1 more is hidden. Turn it."))
        XCTAssertEqual(move(&l, ["f": -6]), .notYet("That face is counted already."))
        XCTAssertTrue(ok(&l, ["f": 6]))
        XCTAssertEqual(move(&l, ["e": -4]), .notYet("Some edges are hidden too. Turn it."))
        XCTAssertEqual(move(&l, ["e": -101]), .notYet("An edge you can see isn't counted yet."))
        XCTAssertTrue(ok(&l, ["e": 12]))
        XCTAssertEqual(move(&l, ["v": -5]), .notYet("One corner is around the back. Look where the dashed edges meet."))
        XCTAssertEqual(move(&l, ["v": -4]), .notYet("Some corners are hidden too. Turn it."))
        XCTAssertTrue(ok(&l, ["v": 8]))
        XCTAssertEqual(l.words.say, "Tap its name.")
        XCTAssertEqual(move(&l, ["n": 0]), .notYet("A cube's faces are all squares. These faces are rectangles: a rectangular prism."))
        XCTAssertEqual(move(&l, ["n": 2]), .notYet("Count again: 6 faces, 12 edges, 8 corners. That's a rectangular prism."))
        XCTAssertTrue(ok(&l, ["n": 1]))
        XCTAssertEqual(l.words.say, "Its faces are rectangles, not all squares.")
        let P = Solids2.Parts(l.numbers)
        XCTAssertEqual(P.record(3, named: true), "6 faces · 12 edges · 8 corners: rectangular prism")
        XCTAssertEqual(P.record(1, named: false), "6 faces")
        XCTAssertEqual(Solids2.Parts(Solids2.numbers(solid: 2)).nameMiss(3), "A triangular prism has a triangle at each end. This one's faces all meet at one point at the top: a pyramid.")
    }

    func testSolidsOrder() {
        var rng = SeededRandom(seed: 5)
        for i in 0..<12 { XCTAssertEqual(Solids2.Parts(Solids2.spec.generate(&rng, i)).solid, [1, 3, 0, 2][i % 4]) }
        XCTAssertEqual(checks(Solids2.spec).map { Solids2.Parts($0).solid }, [1, 3, 0, 2])
    }

    // MARK: Halves, thirds and fourths

    func testCuts() {
        let g = Shares2.geom(0)
        XCTAssertEqual(Shares2.snap(g, (16.2, 0.5), (16, 23.5)), [Shares2.down(16)])
        XCTAssertEqual(Shares2.snap(g, (16, 2), (16, 9)), [-2])
        XCTAssertEqual(Shares2.snap(g, (0, 0), (40, 20)), [-1])
        var r = Shares2.cutting(g, 3, [], [Shares2.down(16)])
        XCTAssertEqual(r.code, 0)
        r = Shares2.cutting(g, 3, r.cuts, [Shares2.down(32)])
        XCTAssertEqual(r.code, 1)
        XCTAssertEqual(Shares2.readout(g, Shares2.judge(g, r.cuts)), "16 | 16 | 16")
        let bad = Shares2.cutting(g, 3, [Shares2.down(16)], [Shares2.down(36)])
        let P = Shares2.Parts(Shares2.numbers(shape: 0, parts: 3, cut: 0, shaded: 2))
        XCTAssertEqual(P.cutMiss(bad.code), "Not equal: 16, 20 and 12 squares wide.")
        let tall = Shares2.cutting(g, 2, [], [Shares2.across(10)])
        XCTAssertEqual(P.cutMiss(tall.code), "Not equal: 10 and 14 squares tall.")
        XCTAssertEqual(P.cutMiss(Shares2.cutting(g, 2, [Shares2.down(24)], [Shares2.across(12)]).code), "That makes 4 parts. Cut it into 3.")
        // the circle: from the middle out, or across through it, to 30°
        let c = Shares2.geom(2)
        XCTAssertEqual(Shares2.snap(c, (15, 15), (15, 1)), [Shares2.radius(270)])
        XCTAssertEqual(Shares2.snap(c, (1, 15), (29, 15)), [Shares2.radius(0), Shares2.radius(180)])
        XCTAssertEqual(Shares2.snap(c, (2, 2), (10, 3)), [-3])
        var cc = Shares2.cutting(c, 3, [], [Shares2.radius(270)])
        cc = Shares2.cutting(c, 3, cc.cuts, [Shares2.radius(30)])
        XCTAssertEqual(cc.code, 0)
        XCTAssertEqual(Shares2.cutting(c, 3, cc.cuts, [Shares2.radius(150)]).code, 1)
        XCTAssertEqual(Shares2.cutting(c, 3, cc.cuts, [Shares2.radius(120)]).code, -4)
        // the square, corner to corner; not on a rectangle
        let sq = Shares2.geom(1)
        XCTAssertEqual(Shares2.snap(sq, (1, 1), (23, 23)), [Shares2.d0])
        XCTAssertEqual(Shares2.cutting(sq, 2, [], [Shares2.d0]).code, 1)
        XCTAssertEqual(Shares2.cutting(g, 2, [], [Shares2.d0]).code, -1)
        // every web cut makes equal parts
        for shape in 0..<3 { for parts in 2...4 { for cut in Shares2.cuts(shape, parts) {
            let G = Shares2.geom(shape), j = Shares2.judge(G, Shares2.cutSet(G, parts, cut))
            XCTAssertEqual(j.n, parts); XCTAssertTrue(j.equal, "\(shape) \(parts) \(cut)")
        } } }
    }

    func testShares() {
        var l = LessonRun(Shares2.spec, numbers: Shares2.numbers(shape: 0, parts: 3, cut: 0, shaded: 2))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Cut it into 3 equal parts.")
        XCTAssertEqual(move(&l, ["k": -2]), .notYet("Cut from edge to edge."))
        XCTAssertTrue(ok(&l, ["k": 1]))
        XCTAssertEqual(l.words.say, "Name the parts.")
        XCTAssertEqual(move(&l, ["n": 0]), .notYet("Halves means 2 equal parts. Here there are 3."))
        XCTAssertEqual(move(&l, ["n": 2]), .notYet("3 equal parts are thirds."))
        XCTAssertTrue(ok(&l, ["n": 1]))
        XCTAssertEqual(l.words.say, "Shade 2 thirds.")
        XCTAssertEqual(move(&l, ["s": 1]), .notYet("That's 1 third. Shade 2."))
        XCTAssertTrue(ok(&l, ["s": 2]))
        XCTAssertEqual(l.words.say, "How many make the whole? Write it.")
        XCTAssertEqual(move(&l, ["w": 2]), .notYet("That's only the shaded ones. Count every part."))
        XCTAssertEqual(move(&l, ["w": 1]), .notYet("The whole is made of all the parts. How many thirds fit in it?"))
        XCTAssertEqual(move(&l, ["w": 5]), .notYet("Count every part, shaded or not."))
        XCTAssertTrue(ok(&l, ["w": 3]))
        XCTAssertEqual(l.words.say, "3 equal parts, so each one is a third.")
        var s = LessonRun(Shares2.spec, numbers: Shares2.numbers(shape: 0, parts: 4, cut: 0, shaded: 1, other: 1))
        XCTAssertEqual(s.words.say, "Same size? Tap yes or no.")
        XCTAssertEqual(move(&s, ["y": 0]), .notYet("They look different, but each is 1 of 4 equal parts of the same rectangle."))
        XCTAssertTrue(ok(&s, ["y": 1]))
        XCTAssertEqual(Shares2.Parts(s.numbers).why, "Same whole, same number of parts: the same size.")
    }

    func testSharesGenerator() {
        var rng = SeededRandom(seed: 4)
        for i in 0..<60 {
            let P = Shares2.Parts(Shares2.spec.generate(&rng, i))
            XCTAssertEqual(P.same, i % 4 == 3, "\(i)")
            if i < 3 { XCTAssertTrue(P.parts == 2 || P.parts == 4); XCTAssertEqual(P.shaded, 1) }
            if P.same { XCTAssertNotEqual(P.shape, 2); XCTAssertNotEqual(P.other, P.cut) }
            XCTAssertTrue(Shares2.cuts(P.shape, P.parts).contains(P.cut))
        }
        let c = checks(Shares2.spec).map(Shares2.Parts.init)
        XCTAssertTrue(c[0].same); XCTAssertEqual(c[1].parts, 3); XCTAssertGreaterThanOrEqual(c[2].shaded, 2); XCTAssertEqual(c[3].shape, 2)
    }
}
