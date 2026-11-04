import XCTest
@testable import ObentoCore

/// 1st grade, chapter 6: Shapes and equal parts (design/grade1.md, the preview design/prototype/grade1-ch6.html).
final class Shapes1Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(71 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(1)[5]
        XCTAssertEqual(ch.title, "Shapes and equal parts")
        XCTAssertEqual(ch.colour, "geometry")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertTrue(Curriculum.voiced(l.id)) }
        // every 1st grade chapter is built: the grade's test is on the map
        XCTAssertTrue(Curriculum.chapters(1).allSatisfy(Curriculum.built))
        XCTAssertEqual(Curriculum.grade(of: Curriculum.gradeTest(1)), 1)
    }

    // MARK: What makes a triangle

    func testTriangle() {
        let x = WhatShape1.numbers(kind: 0, pts: [(0, 16), (20, 16), (8, 0)])
        var l = LessonRun(WhatShape1.spec, numbers: x)
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Is it a triangle? Trace its sides.")
        XCTAssertEqual(move(&l, ["t": -1]), .notYet("Drag along a side."))
        XCTAssertEqual(move(&l, ["t": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "Is it a triangle?")
        XCTAssertEqual(move(&l, ["c": 0]), .notYet("Big or small, it's still a triangle: 3 straight sides, closed."))
        XCTAssertEqual(move(&l, ["c": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Draw a different triangle. Tap the corners. Tap the first one again to close it.")
        let P = WhatShape1.Parts(x)
        XCTAssertEqual(WhatShape1.drawn(P, [(0, 16), (20, 16), (8, 0)]), -5)
        XCTAssertEqual(WhatShape1.drawn(P, [(5, 5), (15, 5), (15, 15), (5, 15)]), -104)
        XCTAssertEqual(P.drawMiss(-104), "That has 4 sides. A triangle has 3.")
        XCTAssertEqual(WhatShape1.drawn(P, [(0, 0), (5, 5), (10, 10)]), -1)
        XCTAssertEqual(WhatShape1.drawn(P, [(0, 0), (10, 0), (0, 10), (10, 10)]), -2)
        XCTAssertEqual(WhatShape1.drawn(P, [(2, 20), (22, 20), (4, 3)]), 1)
        // a corner in the middle of a side doesn't make a side
        XCTAssertEqual(WhatShape1.drawn(P, [(2, 20), (12, 20), (22, 20), (4, 3)]), 1)
        XCTAssertEqual(move(&l, ["d": -5]), .notYet("That's the same one. Make it bigger, smaller or turned."))
        XCTAssertEqual(move(&l, ["d": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "Big, small or turned, 3 straight sides closed make a triangle.")
        XCTAssertEqual(P.record.n, 3)
        XCTAssertEqual(P.record.words, "straight sides, closed: a triangle")
    }

    func testNearMisses() {
        let pts = [(0, 16), (20, 16), (8, 0)]
        let gap = WhatShape1.Parts(WhatShape1.numbers(kind: 0, miss: 1, side: 0, pts: pts))
        XCTAssertFalse(gap.yes)
        XCTAssertEqual(gap.pickSay, "There's a gap. Is it a triangle?")
        XCTAssertEqual(gap.wrongYes, "It has a gap, so it isn't closed.")
        XCTAssertEqual(gap.record.words, "a gap: not a triangle")
        XCTAssertEqual(LessonRun(WhatShape1.spec, numbers: WhatShape1.numbers(kind: 0, miss: 1, pts: pts)).steps.count, 3)
        let bent = WhatShape1.Parts(WhatShape1.numbers(kind: 0, miss: 3, side: 1, pts: pts))
        XCTAssertEqual(bent.pts.count, 4)
        XCTAssertEqual(bent.nSides, 4)
        XCTAssertEqual(bent.wrongYes, "It has 4 sides.")
        XCTAssertEqual(bent.record.n, 4)
        let curve = WhatShape1.Parts(WhatShape1.numbers(kind: 0, miss: 2, side: 2, pts: pts))
        XCTAssertEqual(curve.nSides, 2)
        XCTAssertEqual(curve.pickSay, "That side is curved. Is it a triangle?")
        XCTAssertGreaterThanOrEqual(curve.lines.flatMap(\.path).map(\.0).min() ?? -1, -0.001)
        var l = LessonRun(WhatShape1.spec, numbers: WhatShape1.numbers(kind: 0, miss: 2, side: 2, pts: pts))
        _ = move(&l, ["t": 1])
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("One side is curved."))
        XCTAssertEqual(move(&l, ["c": 0]), .moved(2))
        let sq = WhatShape1.Parts(WhatShape1.numbers(kind: 2, variant: 1, pts: [(0, 0), (8, 4), (4, 12), (-4, 8)]))
        XCTAssertEqual(sq.wrongNo, "Turned, it's still a square: 4 same sides, square corners.")
        XCTAssertEqual(WhatShape1.drawn(sq, [(0, 0), (10, 0), (10, 10), (0, 10)]), 1)
        XCTAssertEqual(WhatShape1.drawn(sq, [(0, 0), (12, 0), (12, 10), (0, 10)]), -4)
        XCTAssertEqual(WhatShape1.drawn(sq, [(0, 0), (12, 0), (14, 10), (0, 10)]), -3)
    }

    func testShapesGenerator() {
        for i in [0, 2] { each(WhatShape1.spec, i, 100) { x in let P = WhatShape1.Parts(x); XCTAssertEqual(P.kind, "triangle"); XCTAssertTrue(P.yes); XCTAssertEqual(P.variant, 0) } }
        each(WhatShape1.spec, 4) { x in let P = WhatShape1.Parts(x); XCTAssertTrue(P.yes); XCTAssertNotEqual(P.variant, 0) }
        var misses = 0
        each(WhatShape1.spec, 8) { x in
            let P = WhatShape1.Parts(x)
            if !P.yes { misses += 1 }
            // corners on crossings, 10–28 squares across, fits beside the patch
            XCTAssertLessThanOrEqual(P.w, 32); XCTAssertLessThanOrEqual(P.h, 30)
            XCTAssertGreaterThanOrEqual(P.given.count, P.need)
            if P.yes { XCTAssertEqual(WhatShape1.drawn(P, P.given), -5) }
        }
        XCTAssertGreaterThan(misses, 100); XCTAssertLessThan(misses, 200)
        let c = checks(WhatShape1.spec)
        XCTAssertEqual(WhatShape1.Parts(c[0]).kind, "square")
        XCTAssertEqual(WhatShape1.Parts(c[2]).miss, 1)
        XCTAssertEqual(WhatShape1.Parts(c[3]).miss, 2)
    }

    // MARK: Put shapes together

    func testCompose() {
        var l = LessonRun(Compose1.spec, numbers: Compose1.numbers(set: 2))
        XCTAssertEqual(l.steps.count, 2)
        XCTAssertEqual(l.words.say, "Slide the pieces in to make a hexagon.")
        XCTAssertEqual(move(&l, ["f": -12]), .notYet("That sticks out 2 squares."))
        XCTAssertEqual(move(&l, ["f": -11]), .notYet("That sticks out 1 square."))
        XCTAssertEqual(move(&l, ["f": -1]), .notYet("Pieces can't stack."))
        XCTAssertEqual(move(&l, ["f": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "Shapes put together make a new shape, and it can build more.")
        let turned = Compose1.Parts(Compose1.numbers(set: 0, turns: [0, 1]))
        XCTAssertTrue(turned.needsTurn(0))
        XCTAssertEqual(turned.fillSay(0), "Slide the pieces in to make a trapezoid. Tap a piece to turn it.")
        // two stages: the square made is the first piece of the trapezoid
        let x = Compose1.numbers(set: 6)
        var t = LessonRun(Compose1.spec, numbers: x)
        XCTAssertEqual(t.steps.count, 3)
        XCTAssertEqual(move(&t, ["f": 1]), .moved(1))
        XCTAssertEqual(t.words.say, "Now use it to make a trapezoid.")
        let P = Compose1.Parts(x)
        XCTAssertEqual(Compose1.key(P.start(1)[0]), Compose1.key(P.outline(0)))
        XCTAssertEqual(P.stages[1].words, "A square and 2 triangles make a trapezoid.")
    }

    func testComposePlaces() {
        // every piece fits its place exactly, and the places fill the outline without overlapping
        for set in 0..<8 {
            let P = Compose1.Parts(Compose1.numbers(set: set))
            for i in P.stages.indices {
                let out = P.outline(i), sl = P.slots(i), st = P.start(i)
                var placed: [[Compose1.Pt]] = []
                for (j, s) in sl.enumerated() {
                    XCTAssertEqual(Compose1.key(st[j]), s.key, "set \(set) stage \(i) piece \(j)")
                    let at = Shapes1.shift(st[j], s.x, s.y)
                    XCTAssertTrue(Shapes1.samples(at).allSatisfy { Shapes1.inside($0, out) || Shapes1.polyDist($0, out) < 0.05 }, "set \(set) piece \(j) inside")
                    for o in placed { XCTAssertFalse(Shapes1.samples(at).contains { Shapes1.inside($0, o) && Shapes1.polyDist($0, o) > 0.05 }) }
                    placed.append(at)
                }
            }
        }
        each(Compose1.spec, 1) { x in XCTAssertFalse(Compose1.Parts(x).needsTurn(0)); XCTAssertFalse(Compose1.Parts(x).two) }
        each(Compose1.spec, 4) { x in XCTAssertTrue(Compose1.Parts(x).needsTurn(0)) }
        each(Compose1.spec, 6) { x in XCTAssertTrue(Compose1.Parts(x).two) }
    }

    // MARK: Build with solids

    func testBuild() {
        var l = LessonRun(Build1.spec, numbers: Build1.numbers(set: 3))
        XCTAssertEqual(l.steps.count, 2)
        XCTAssertEqual(l.words.say, "Build a tower. Drag each piece on.")
        XCTAssertEqual(move(&l, ["p": -2]), .notYet("Nothing stands on a point."))
        XCTAssertEqual(move(&l, ["p": -13]), .notYet("The cylinder goes at the bottom."))
        XCTAssertEqual(move(&l, ["p": -14]), .notYet("The cone goes on the cylinder."))
        XCTAssertEqual(move(&l, ["p": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "Solids put together make a new solid, and it can build more.")
        let rocket = Build1.Parts(Build1.numbers(set: 4, poses: [0, 1, 0]))
        XCTAssertEqual(rocket.buildSay(0), "Build a rocket. Drag each piece on. Tap a piece to turn it.")
        XCTAssertFalse(rocket.fitsAsIs(0, rocket.stages[0].pieces[0], pose: 0))
        XCTAssertTrue(rocket.fitsAsIs(0, rocket.stages[0].pieces[0], pose: 2))
        XCTAssertEqual(rocket.goes(0, "box"), "The box goes at the bottom.")
        XCTAssertEqual(rocket.said(0)(-3), "It rolls off. Put a flat face down.")
        XCTAssertEqual(rocket.said(0)(-1), "That sticks out past the shape.")
        XCTAssertEqual(rocket.ghost(0).count, 4)
        XCTAssertEqual(rocket.size(0), [1, 1, 4])
        var t = LessonRun(Build1.spec, numbers: Build1.numbers(set: 6))
        XCTAssertEqual(t.steps.count, 3)
        XCTAssertEqual(move(&t, ["p": 1]), .moved(1))
        XCTAssertEqual(t.words.say, "Now use it to build a bigger box.")
        let big = Build1.Parts(Build1.numbers(set: 5))
        XCTAssertEqual(big.ghost(0).count, 8)
        each(Build1.spec, 0) { x in XCTAssertEqual(Build1.Parts(x).stages[0].pieces.count, 2) }
        each(Build1.spec, 4) { x in let P = Build1.Parts(x); XCTAssertEqual(P.which, 4); XCTAssertTrue(P.needsTurn(0)) }
        each(Build1.spec, 6) { x in XCTAssertTrue(Build1.Parts(x).twoStage) }
    }

    // MARK: Halves and fourths

    func testHalves() {
        let x = Halves1.numbers(shape: 0, parts: 4, cut: 0, shaded: 3)
        var l = LessonRun(Halves1.spec, numbers: x)
        let P = Halves1.Parts(x)
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Cut it into 4 equal parts, down and across.")
        XCTAssertEqual(Halves1.cut(P, [], Halves1.down(20))?.done, false)
        XCTAssertNil(Halves1.cut(P, [], Halves1.down(15)))
        XCTAssertEqual(Halves1.missCode(P, [], Halves1.down(15)), -(1000 + 1500 + 25))
        XCTAssertEqual(move(&l, ["k": -(1000 + 1500 + 25)]), .notYet("Not equal: 15 squares and 25 squares."))
        XCTAssertEqual(Halves1.cut(P, [Halves1.down(20)], Halves1.across(12))?.done, true)
        XCTAssertEqual(Halves1.cut(P, [Halves1.down(10), Halves1.down(20)], Halves1.down(30))?.done, true)
        XCTAssertEqual(Halves1.parts(P.g, [Halves1.down(20), Halves1.across(12)]).count, 4)
        XCTAssertEqual(move(&l, ["k": -2]), .notYet("Cut from edge to edge."))
        XCTAssertEqual(move(&l, ["k": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "4 equal parts. What are they called?")
        XCTAssertEqual(move(&l, ["n": 1]), .notYet("Halves means 2 equal parts. Here there are 4."))
        XCTAssertEqual(move(&l, ["n": 0]), .notYet("The whole is the full rectangle. Each part is a smaller piece of it."))
        XCTAssertEqual(move(&l, ["n": 2]), .moved(2))
        XCTAssertEqual(l.words.say, "Fourths are also called quarters. Shade 3 fourths.")
        XCTAssertEqual(move(&l, ["s": 3]), .moved(3))
        XCTAssertEqual(l.words.say, "4 equal parts are fourths, also called quarters.")
        XCTAssertEqual(P.record.map(\.1), ["fourths shaded", "fourths make the whole"])
        // a square cut corner to corner; a circle through the middle
        let sq = Halves1.Parts(Halves1.numbers(shape: 1, parts: 2, cut: 2))
        XCTAssertEqual(Halves1.cut(sq, [], Halves1.d0)?.done, true)
        XCTAssertEqual(sq.cutSay, "Cut it into 2 equal parts, corner to corner.")
        let c = Halves1.Parts(Halves1.numbers(shape: 2, parts: 2))
        XCTAssertNil(Halves1.cut(c, [], Halves1.down(10)))
        XCTAssertEqual(c.cutMiss(Halves1.missCode(c, [], Halves1.down(10))), "Not equal. Cut through the middle.")
        let r2 = Halves1.Parts(Halves1.numbers(shape: 0, parts: 2))
        XCTAssertEqual(r2.cutMiss(Halves1.missCode(r2, [Halves1.down(20)], Halves1.across(12))), "That makes 4 parts. Make 2.")
        XCTAssertEqual(r2.shadeSay, "Shade 1 half.")
    }

    func testCompareParts() {
        var l = LessonRun(Halves1.spec, numbers: Halves1.compare(shape: 0))
        XCTAssertEqual(l.steps.count, 2)
        XCTAssertEqual(l.words.say, "Tap a bigger piece.")
        XCTAssertEqual(move(&l, ["b": -1]), .notYet("A fourth is half of a half. More parts are smaller."))
        XCTAssertEqual(move(&l, ["b": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "The more equal parts, the smaller each part.")
        each(Halves1.spec, 1, 100) { x in let P = Halves1.Parts(x); XCTAssertFalse(P.compare); XCTAssertEqual(P.parts, 2) }
        each(Halves1.spec, 6, 50) { x in XCTAssertTrue(Halves1.Parts(x).compare) }
        each(Halves1.spec, 9, 50) { x in XCTAssertTrue(Halves1.Parts(x).compare) }
        each(Halves1.spec, 7) { x in
            let P = Halves1.Parts(x)
            XCTAssertFalse(P.compare)
            // the cut asked is one of the equal patterns, every part a whole number of squares
            if P.shape == 1 && P.parts == 4 { XCTAssertNotEqual(P.cut, 1) }
            XCTAssertFalse(Halves1.patterns(P.g, P.parts).isEmpty)
        }
    }
}
