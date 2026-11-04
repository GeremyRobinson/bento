import XCTest
@testable import ObentoCore

/// 6th grade, chapter 7: Area and volume (design/grade6.md, the preview design/prototype/grade6-ch7.html).
final class AreaG6Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func type(_ l: inout LessonRun, _ v: [(String, String)]) -> LessonRun.Outcome {
        l.reset()
        for (b, x) in v { l.active = b; for ch in x { l.type(String(ch)) } }
        return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(91 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 17)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(6)[6]
        XCTAssertEqual(ch.title, "Area and volume")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
        XCTAssertEqual(Curriculum.grade(of: "g6-fracvol"), 6)
    }

    // MARK: Area of a parallelogram

    func testParaSteps() {
        var l = LessonRun(Para6.spec, numbers: Para6.numbers(b: 12, h: 5, s: 3))
        XCTAssertEqual(l.words.say, "Cut straight down.")
        _ = l.go()
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(l.words.say, "Cut straight down. Drag down a grid line.")
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("Cut from the top side to the bottom side."))
        XCTAssertEqual(move(&l, ["c": 13]), .notYet("Cut from the top side to the bottom side."))
        XCTAssertEqual(move(&l, ["c": 3]), .moved(2))
        XCTAssertEqual(move(&l, ["d": 0]), .notYet("Slide it to the other end."))
        XCTAssertEqual(move(&l, ["d": 1]), .moved(3))
        XCTAssertEqual(type(&l, [("x", "30")]), .notYet("That’s a triangle’s area. A parallelogram is the whole rectangle."))
        XCTAssertEqual(type(&l, [("x", "17")]), .notYet("Multiply: 5 rows of 12."))
        XCTAssertEqual(type(&l, [("x", "61")]), .notYet("Count the squares: 5 rows of 12."))
        XCTAssertEqual(type(&l, [("x", "60")]), .moved(4))
        XCTAssertEqual(l.words.say, "Cut and slide: the same squares make a 12 by 5 rectangle.")
    }
    func testParaGenerator() {
        for i in 0..<3 { each(Para6.spec, i) { n in let p = Para6.Parts(n); XCTAssert((4...10).contains(p.b) && (2...6).contains(p.h) && (1...3).contains(p.s) && p.s < p.b && p.lean == 1 && p.story == 0) } }
        for i in 3..<10 { each(Para6.spec, i) { n in let p = Para6.Parts(n); XCTAssert((4...16).contains(p.b) && (2...12).contains(p.h) && p.s >= 1 && p.s < p.b) } }
        let story = Para6.Parts(Para6.numbers(b: 8, h: 3, s: 2, story: 1))
        XCTAssertEqual(story.cutSay, "It’s a garden bed, measured in feet. Cut straight down a grid line.")
        XCTAssertEqual(story.unit, "square feet")
        let c = checks(Para6.spec).map(Para6.Parts.init)
        XCTAssertEqual(c[0].lean, -1); XCTAssertEqual(c[1].h % 2, 1); XCTAssertGreaterThanOrEqual(c[2].b, 12); XCTAssertGreaterThan(c[3].story, 0)
    }

    // MARK: Area of a triangle

    func testTriSteps() {
        var l = LessonRun(Tri6.spec, numbers: Tri6.numbers(b: 6, h: 4, p: 2))
        _ = l.go()
        XCTAssertEqual(l.words.say, "Fit the copy against it. Drag the copy.")
        XCTAssertEqual(move(&l, ["f": 0]), .notYet("Put it against the slanted side."))
        XCTAssertEqual(move(&l, ["f": 1]), .moved(2))
        XCTAssertEqual(type(&l, [("x", "10")]), .notYet("Multiply base × height."))
        XCTAssertEqual(type(&l, [("x", "25")]), .notYet("The rectangle is 4 rows of 6."))
        XCTAssertEqual(type(&l, [("x", "24")]), .moved(3))
        XCTAssertEqual(type(&l, [("x", "24")]), .notYet("A triangle is half of a rectangle: divide by 2."))
        XCTAssertEqual(type(&l, [("x", "11")]), .notYet("Two triangles make 24: take half."))
        XCTAssertEqual(type(&l, [("x", "12")]), .moved(4))
        XCTAssertEqual(l.words.say, "Two copies make a 6 by 4 rectangle, so one is half.")
    }
    func testTriGenerator() {
        for i in 0..<8 {
            each(Tri6.spec, i) { n in
                let p = Tri6.Parts(n)
                XCTAssert((2...20).contains(p.b) && (2...20).contains(p.h) && (p.b * p.h) % 2 == 0)
                XCTAssert(p.p >= 0 && p.p <= p.b + 4)
                if i == 0 { XCTAssert(p.p > 0 && p.p < p.b) }
                if i == 1 { XCTAssert(p.p == 0 || p.p == p.b) }
                if i == 2 { XCTAssert(p.p > p.b) }
            }
        }
        let c = checks(Tri6.spec).map(Tri6.Parts.init)
        XCTAssert(c[0].b % 2 == 1 || c[0].h % 2 == 1); XCTAssert(c[1].b >= 10 && c[1].h >= 10)
    }

    // MARK: Area of a trapezoid

    func testTrapSteps() {
        var l = LessonRun(Trap6.spec, numbers: Trap6.numbers(a: 4, b: 8, h: 5))
        _ = l.go()
        XCTAssertEqual(move(&l, ["f": 0]), .notYet("Put it against the slanted side."))
        XCTAssertEqual(move(&l, ["f": 1]), .moved(2))
        XCTAssertEqual(type(&l, [("x", "32")]), .notYet("Put the bases end to end: add them."))
        XCTAssertEqual(type(&l, [("x", "13")]), .notYet("The bottom is 4 and 8 end to end."))
        XCTAssertEqual(type(&l, [("x", "12")]), .moved(3))
        XCTAssertEqual(type(&l, [("x", "17")]), .notYet("Area is length times height."))
        XCTAssertEqual(type(&l, [("x", "60")]), .moved(4))
        XCTAssertEqual(type(&l, [("x", "60")]), .notYet("Divide by 2 at the end."))
        XCTAssertEqual(type(&l, [("x", "29")]), .notYet("That area holds two trapezoids. Take half."))
        XCTAssertEqual(type(&l, [("x", "30")]), .moved(5))
        XCTAssertEqual(l.words.say, "Two trapezoids make a 12 by 5 rectangle, so one is half.")
    }
    func testTrapGenerator() {
        each(Trap6.spec, 0, 500) { n in
            let p = Trap6.Parts(n)
            XCTAssert((2...15).contains(p.a) && (2...15).contains(p.b) && (2...12).contains(p.h) && p.a != p.b && p.P % 2 == 0)
        }
        let c = checks(Trap6.spec).map(Trap6.Parts.init)
        XCTAssertEqual((c[0].a + c[0].b) % 2, 1); XCTAssertEqual(c[1].h % 2, 1)
    }

    // MARK: Area of a polygon

    func testPolyShapes() {
        let L = Poly6.Shape(Poly6.numbers(kind: .L, W: 10, H: 8, a: 4, b: 3))
        XCTAssertEqual(L.area, 10 * 8 - 4 * 3)
        XCTAssertEqual(L.pieces, [Poly6.Piece(tri: false, w: 6, h: 8), Poly6.Piece(tri: false, w: 4, h: 5)])
        let take = Poly6.Shape(Poly6.numbers(kind: .take, W: 10, H: 8, a: 4, b: 3))
        XCTAssertEqual(take.area, 80 - 6)
        XCTAssertEqual(take.slots, 3)
        let turned = Poly6.Shape(Poly6.numbers(kind: .rt, W: 6, H: 4, a: 2, tr: 1, fx: 1))
        XCTAssertEqual(turned.width, 4); XCTAssertEqual(turned.height, 8)
        for i in 0..<12 {
            each(Poly6.spec, i, 200) { n in
                let S = Poly6.Shape(n)
                XCTAssert(S.pieces.allSatisfy { !$0.tri || ($0.w * $0.h) % 2 == 0 }, "\(n)")
                XCTAssert(S.width <= 14 && S.height <= 14, "\(n)")
                XCTAssert(S.corners.allSatisfy { $0.0 >= 0 && $0.0 <= S.width && $0.1 >= 0 && $0.1 <= S.height })
                if i < 3 { XCTAssertEqual(S.kind, .L) } else if i < 6 { XCTAssertEqual(S.kind, .rt) }
            }
        }
    }
    func testPolyStepsFromTheCut() {
        var l = LessonRun(Poly6.spec, numbers: Poly6.numbers(kind: .L, W: 10, H: 8, a: 4, b: 3))
        _ = l.go()
        XCTAssertEqual(move(&l, ["k": 0]), .notYet("That piece isn’t a rectangle or a triangle."))
        // the child cut across instead: a 10 by 3... no, the top 6 by 3 and the bottom 10 by 5
        l.keep("n", nil)
        for (k, v) in Poly6.keep([Poly6.Piece(tri: false, w: 6, h: 3), Poly6.Piece(tri: false, w: 10, h: 5)]) { l.keep(k, v) }
        XCTAssertEqual(move(&l, ["k": 1]), .moved(2))
        XCTAssertEqual(l.wanted(l.step.answer!), ["x": 18])
        XCTAssertEqual(type(&l, [("x", "9")]), .notYet("Multiply the two sides."))
        XCTAssertEqual(type(&l, [("x", "18")]), .moved(3))
        XCTAssertEqual(type(&l, [("x", "50")]), .moved(4))
        XCTAssertEqual(type(&l, [("x", "118")]), .notYet("That counts a piece twice."))
        XCTAssertEqual(type(&l, [("x", "60")]), .notYet("Add the pieces’ areas."))
        XCTAssertEqual(type(&l, [("x", "68")]), .moved(5))
    }
    func testPolyTakeAway() {
        var l = LessonRun(Poly6.spec, numbers: Poly6.numbers(kind: .take, W: 10, H: 8, a: 4, b: 3))
        _ = l.go()
        for (k, v) in Poly6.keep([Poly6.Piece(tri: false, w: 10, h: 8), Poly6.Piece(tri: true, w: 4, h: 3, sign: -1)]) { l.keep(k, v) }
        XCTAssertEqual(move(&l, ["k": 1]), .moved(2))
        XCTAssertEqual(type(&l, [("x", "80")]), .moved(3))
        XCTAssertEqual(type(&l, [("x", "12")]), .notYet("A triangle is half its rectangle: divide by 2."))
        XCTAssertEqual(type(&l, [("x", "6")]), .moved(4))
        // no third piece: the slot is passed with nothing in it
        XCTAssertEqual(l.wanted(l.step.answer!), ["x": 0])
        XCTAssertEqual(type(&l, [("x", "0")]), .moved(5))
        XCTAssertEqual(type(&l, [("x", "86")]), .notYet("The corner is taken away: subtract it."))
        XCTAssertEqual(type(&l, [("x", "74")]), .moved(6))
        XCTAssertEqual(Poly6.done(Poly6.Shape(Poly6.numbers(kind: .take, W: 10, H: 8, a: 4, b: 3)).pieces), "Take the corner away: the rectangle less the triangle.")
        XCTAssertEqual(Poly6.done(Poly6.Shape(Poly6.numbers(kind: .house, W: 8, H: 4, a: 2)).pieces), "Cut into a rectangle and two triangles, the areas add.")
    }

    // MARK: Nets and surface area

    func testNets() {
        let box = Nets6.net(Nets6.box(a: 5, b: 3, c: 4))
        XCTAssertEqual(box.SA, 2 * (20 + 15 + 12))
        XCTAssertEqual(box.V, 60)
        XCTAssertEqual(box.groups.map(\.n), [2, 2, 2])
        XCTAssertEqual(Nets6.net(Nets6.cube(4)).SA, 96)
        XCTAssertEqual(Nets6.net(Nets6.cube(4)).terms, [.num(6), .op("×"), .text("4²")])
        XCTAssertEqual(Nets6.net(Nets6.prism(right: true, L: 3)).SA, 12 + 9 + 15 + 12)
        XCTAssertEqual(Nets6.net(Nets6.prism(right: false, L: 2)).SA, 12 + 10 + 10 + 24)
        let pyr = Nets6.net(Nets6.pyramid(s: 4, l: 5))
        XCTAssertEqual(pyr.SA, 16 + 4 * 10); XCTAssertNil(pyr.V)
        XCTAssertGreaterThan(pyr.faces[1].turn, 90)
        var l = LessonRun(Nets6.spec, numbers: Nets6.box(a: 5, b: 3, c: 4))
        _ = l.go()
        XCTAssertEqual(l.words.say, "Fold it into a box. Drag each face toward the middle.")
        XCTAssertEqual(move(&l, ["f": -1]), .notYet("Fold it all the way up."))
        XCTAssertFalse(l.missed)
        XCTAssertEqual(move(&l, ["f": -2]), .notYet("Fold the sides up first."))
        XCTAssertEqual(move(&l, ["f": 5]), .moved(2))
        XCTAssertEqual(move(&l, ["t": -1]), .notYet("Tap a face of the net."))
        XCTAssertEqual(move(&l, ["t": 6]), .moved(3))
        XCTAssertEqual(type(&l, [("x", "60")]), .notYet("That’s the cubes inside. The surface is the faces."))
        XCTAssertEqual(type(&l, [("x", "47")]), .notYet("That’s 3 faces. A box has 6."))
        XCTAssertEqual(type(&l, [("x", "93")]), .notYet("Add the faces’ areas: every face counts."))
        XCTAssertEqual(type(&l, [("x", "94")]), .moved(4))
        XCTAssertEqual(l.words.say, "The net is the box’s outside laid flat: 94 squares cover it.")
    }
    func testNetsGenerator() {
        for i in 0..<12 {
            each(Nets6.spec, i, 200) { n in
                let N = Nets6.net(n)
                XCTAssert(N.width <= 22 && N.height <= 14, "\(n)")
                XCTAssert(N.faces.allSatisfy { !$0.tri || ($0.w * $0.h) % 2 == 0 })
                if i < 6 { XCTAssert(N.kind == .cube || N.kind == .box) }
            }
        }
        let c = checks(Nets6.spec).map(Nets6.net)
        XCTAssertEqual(c.map(\.kind), [.cube, .box, .pyramid, .prism])
    }

    // MARK: Volume with fraction edges

    func testFracVol() {
        let p = FracVol6.Parts(FracVol6.numbers(x: 3, y: 4, z: 3))
        XCTAssertEqual(p.N, 36); XCTAssertEqual(p.Vs, "4 1/2"); XCTAssertEqual(p.edge(3), "1½"); XCTAssertEqual(p.edge(4), "2")
        var l = LessonRun(FracVol6.spec, numbers: FracVol6.numbers(x: 3, y: 4, z: 3))
        _ = l.go()
        XCTAssertEqual(move(&l, ["c": 7]), .notYet("Cover every square: 7 of 12 so far."))
        XCTAssertFalse(l.missed)
        XCTAssertEqual(move(&l, ["c": 12]), .moved(2))
        XCTAssertEqual(l.words.say, "Build it up to 1½. Drag up, a layer at a time.")
        XCTAssertEqual(move(&l, ["l": 2]), .notYet("That’s 1 high. Build it to 1½."))
        XCTAssertEqual(move(&l, ["l": 3]), .moved(3))
        XCTAssertEqual(type(&l, [("w", "36"), ("n", "0"), ("d", "1")]), .notYet("8 small cubes make one whole."))
        XCTAssertEqual(type(&l, [("w", "2"), ("n", "0"), ("d", "1")]), .notYet("The halves count too: share all 36 small cubes into wholes of 8."))
        XCTAssertEqual(type(&l, [("w", "3"), ("n", "0"), ("d", "1")]), .notYet("Share the 36 small cubes into wholes of 8."))
        XCTAssertEqual(type(&l, [("w", "4")]), .notYet("Write the whole number and the fraction."))
        XCTAssertEqual(type(&l, [("w", "4"), ("n", "2"), ("d", "4")]), .moved(4))
        XCTAssertEqual(l.words.say, "8 small cubes make one whole cube, so 36 of them make 4 1/2.")
        let whole = LessonRun(FracVol6.spec, numbers: FracVol6.numbers(x: 4, y: 4, z: 3))
        XCTAssertEqual(whole.steps[3].answer?.boxes, ["w"])
        let wholes = FracVol6.Parts(FracVol6.numbers(x: 5, y: 4, z: 2))
        XCTAssertEqual(wholes.written(4), "The halves count too: share all 40 small cubes into wholes of 8.")
    }
    func testFracVolGenerator() {
        for i in 0..<12 {
            each(FracVol6.spec, i, 200) { n in
                let p = FracVol6.Parts(n), odd = [p.x, p.y, p.z].filter { $0 % p.d != 0 }.count
                XCTAssert(p.N <= 72 && [p.x, p.y, p.z].allSatisfy { $0 >= p.d && $0 <= 6 }, "\(n)")
                if i < 3 { XCTAssertEqual(odd, 1) } else if i < 6 { XCTAssertEqual(odd, 2) } else { XCTAssertGreaterThan(odd, 0) }
                if i >= 6 && i % 3 == 2 { XCTAssertEqual(p.d, 3) }
            }
        }
        let c = checks(FracVol6.spec).map(FracVol6.Parts.init)
        XCTAssertEqual(c[3].mode, 1)
    }
}
