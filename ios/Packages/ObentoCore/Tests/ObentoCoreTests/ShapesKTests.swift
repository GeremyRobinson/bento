import XCTest
@testable import ObentoCore

/// Kindergarten, chapter 2: Shapes (design/gradeK.md, the preview design/prototype/gradeK-ch2.html).
final class ShapesKTests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double], keep: Numbers = [:]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in keep { l.keep(k, v) }; for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(41 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(0)[1]
        XCTAssertEqual(ch.title, "Shapes")
        XCTAssertEqual(ch.test, "test-gk-shapes")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertTrue(Curriculum.voiced(l.id)) }
        XCTAssertEqual(Lessons.spec("k-solids")?.depends, ["k-shapes"])
        XCTAssertEqual(Lessons.spec("gk-compose")?.depends, ["gk-draw"])
    }

    // MARK: Flat shapes

    func testFlatTriangle() {
        var l = LessonRun(FlatShapes.spec, numbers: FlatShapes.numbers(shape: 1, w: 9, h: 7, turn: 0))
        let P = FlatShapes.Parts(l.numbers)
        XCTAssertEqual(P.corners.count, 3)
        XCTAssertEqual(l.words.say, "Tap each side.")
        XCTAssertEqual(move(&l, ["s": -1]), .notYet("You counted that side."))
        XCTAssertEqual(move(&l, ["s": 3]), .moved(1))
        XCTAssertEqual(l.words.say, "Tap each corner.")
        XCTAssertEqual(move(&l, ["c": -1]), .notYet("You counted that corner."))
        XCTAssertEqual(move(&l, ["c": 3]), .moved(2))
        XCTAssertEqual(l.words.say, "Tap its name.")
        let hex = P.choices.firstIndex(of: "hexagon")!
        XCTAssertEqual(move(&l, ["p": Double(hex)]), .notYet("A hexagon has 6 sides. This shape has 3 sides."))
        let circle = P.choices.firstIndex(of: "circle")!
        XCTAssertEqual(move(&l, ["p": Double(circle)]), .notYet("A circle is round, with no corners. This shape has 3 sides."))
        XCTAssertEqual(move(&l, ["p": Double(P.right)]), .moved(3))
        XCTAssertEqual(l.words.say, "3 straight sides and 3 corners make a triangle, turned or not.")
        XCTAssertEqual(P.record, ["3 sides · 3 corners", "It’s a triangle."])
    }

    func testFlatCircleAndSquare() {
        var l = LessonRun(FlatShapes.spec, numbers: FlatShapes.numbers(shape: 0, w: 8, h: 7, turn: 0))
        let P = FlatShapes.Parts(l.numbers)
        XCTAssertEqual(P.r, 12)
        XCTAssertEqual(FlatShapes.Parts(FlatShapes.numbers(shape: 0, w: 10, h: 7, turn: 0)).r, 13)
        XCTAssertEqual(move(&l, ["s": 0]), .moved(1))
        XCTAssertEqual(l.words.say, "It’s round. No straight sides. Tap each corner.")
        XCTAssertEqual(move(&l, ["c": 0]), .moved(2))
        XCTAssertEqual(l.words.say, "No corners. It’s round all the way. Tap its name.")
        XCTAssertEqual(move(&l, ["p": Double(P.choices.firstIndex(of: "triangle")!)]), .notYet("A triangle has straight sides and corners. This shape is round, with none."))
        let S = FlatShapes.Parts(FlatShapes.numbers(shape: 2, w: 8, h: 7, turn: 30))
        XCTAssertEqual(S.record, ["4 sides · 4 corners", "4 sides the same", "It’s a square."])
        XCTAssertTrue(S.choices.contains("square")); XCTAssertFalse(S.choices.contains("rectangle"))
    }

    func testFlatShapesOnTheGrid() {
        // every corner on a crossing; a square's sides the same and its corners square; a rectangle half again as wide
        for i in [0, 3, 6] {
            each(FlatShapes.spec, i) { x in
                let P = FlatShapes.Parts(x), c = P.corners
                if i < 3 { XCTAssertTrue([0, 1, 2].contains(P.shape)); XCTAssertEqual(P.turn, 0) }
                XCTAssertEqual(c.count, P.n)
                XCTAssertLessThanOrEqual(P.width, 36); XCTAssertLessThanOrEqual(P.height, 27)
                XCTAssertEqual(c.map(\.0).min() ?? 0, 0); XCTAssertEqual(c.map(\.1).min() ?? 0, 0)
                if P.kind == "square" || P.kind == "rectangle" {
                    let e = (0..<4).map { (c[($0 + 1) % 4].0 - c[$0].0, c[($0 + 1) % 4].1 - c[$0].1) }
                    for k in 0..<4 { XCTAssertEqual(e[k].0 * e[(k + 1) % 4].0 + e[k].1 * e[(k + 1) % 4].1, 0) }
                    let l = e.map { $0.0 * $0.0 + $0.1 * $0.1 }
                    if P.kind == "square" { XCTAssertEqual(Set(l).count, 1) } else { XCTAssertGreaterThanOrEqual(Double(l[0]), 2.25 * Double(l[1]) - 1e-9) }
                }
                XCTAssertEqual(P.choices.count, 4)
                XCTAssertTrue(P.choices.contains(P.kind))
            }
        }
        // turned shapes take the grid's turns
        let t = FlatShapes.Parts(FlatShapes.numbers(shape: 2, w: 9, h: 7, turn: 45))
        XCTAssertEqual(t.corners.count, 4); XCTAssertEqual(t.angle, .pi / 4, accuracy: 1e-9)
        let h = FlatShapes.Parts(FlatShapes.numbers(shape: 4, w: 9, h: 7, turn: 15))
        XCTAssertEqual(h.width, 20); XCTAssertEqual(h.height, 24)
    }

    func testFlatChecks() {
        var rng = SeededRandom(seed: 3)
        let spec = FlatShapes.spec
        let items = spec.check.map { $0.draw(spec, using: &rng) }.map(FlatShapes.Parts.init)
        XCTAssertEqual(items[0].kind, "triangle"); XCTAssertTrue(items[0].turned)
        XCTAssertEqual(items[1].kind, "square"); XCTAssertTrue(items[1].turned)
        XCTAssertEqual(items[2].kind, "rectangle"); XCTAssertEqual(items[3].kind, "hexagon")
    }

    // MARK: Draw shapes

    func testDrawChecks() {
        XCTAssertNil(DrawShape.check("triangle", [(0, 0), (4, 0), (2, 3)]))
        XCTAssertEqual(DrawShape.check("triangle", [(0, 0), (4, 0), (4, 3), (0, 3)])?.msg, "That has 4 sides. A triangle has 3.")
        XCTAssertNil(DrawShape.check("square", [(1, 1), (4, 1), (4, 4), (1, 4)]))
        // a tilted square counts
        XCTAssertNil(DrawShape.check("square", [(2, 0), (4, 1), (3, 3), (1, 2)]))
        let m = DrawShape.check("square", [(0, 0), (3, 0), (3, 2), (0, 2)])
        XCTAssertEqual(m?.msg, "Sides 3, 2, 3, 2. Make them all the same."); XCTAssertEqual(m?.blocks, true)
        XCTAssertEqual(DrawShape.check("square", [(0, 0), (3, 0), (4, 2), (1, 2)])?.msg, "Make square corners, like the grid’s.")
        XCTAssertEqual(DrawShape.check("rectangle", [(0, 0), (2, 0), (2, 2), (0, 2)])?.msg, "That’s a square. Make 2 sides longer.")
        XCTAssertNil(DrawShape.check("rectangle", [(0, 0), (5, 0), (5, 2), (0, 2)]))
        let tilt = DrawShape.check("square", [(2, 0), (6, 2), (5, 4), (1, 2)])
        XCTAssertEqual(tilt?.msg, "These 2 are longer."); XCTAssertEqual(tilt?.longer, [true, false, true, false])
        XCTAssertNil(DrawShape.check("hexagon", [(2, 0), (5, 0), (7, 2), (5, 4), (2, 4), (0, 2)]))
        // refused, with the paper's reason
        XCTAssertEqual(DrawShape.refuse([(0, 0), (2, 0), (4, 0)], closed: false), "Those are in a line.")
        XCTAssertEqual(DrawShape.refuse([(0, 0), (4, 4), (4, 0), (0, 4)], closed: true), "Sides can’t cross.")
        XCTAssertNil(DrawShape.refuse([(0, 0), (4, 0), (4, 4), (0, 4)], closed: true))
        XCTAssertNil(DrawShape.refuse([(0, 0), (4, 0)], closed: false))
    }

    func testDrawRun() {
        var l = LessonRun(DrawShape.spec, numbers: DrawShape.numbers(kind: "square"))
        XCTAssertEqual(l.words.say, "Draw a square.")
        XCTAssertEqual(move(&l, ["d": 1], keep: DrawShape.keep([(0, 0), (3, 0), (3, 2), (0, 2)], closed: true)), .notYet("Sides 3, 2, 3, 2. Make them all the same."))
        XCTAssertEqual(move(&l, ["d": 1], keep: DrawShape.keep([(0, 0), (3, 0), (3, 3), (0, 3)], closed: true)), .moved(1))
        XCTAssertEqual(l.words.say, "4 sides the same joined at 4 square corners make a square.")
        var c = LessonRun(DrawShape.spec, numbers: DrawShape.numbers(kind: "circle"))
        XCTAssertEqual(move(&c, ["d": 2]), .moved(1))
        XCTAssertEqual(c.words.say, "A circle is round all the way: no sides, no corners.")
        each(DrawShape.spec, 0) { XCTAssertTrue(["triangle", "rectangle"].contains(DrawShape.Parts($0).kind)) }
        each(DrawShape.spec, 4) { XCTAssertTrue(["triangle", "rectangle", "square"].contains(DrawShape.Parts($0).kind)) }
        var seen = Set<String>(); each(DrawShape.spec, 7) { seen.insert(DrawShape.Parts($0).kind) }
        XCTAssertEqual(seen, Set(DrawShape.kinds))
    }

    // MARK: Solid shapes

    func testSolidsRun() {
        var l = LessonRun(Solids3K.spec, numbers: Solids3K.numbers(shape: 2))
        XCTAssertEqual(l.words.say, "Tilt the paper.")
        // a short drag is only a notice
        XCTAssertEqual(move(&l, ["t": 0]), .notYet("Drag it further up."))
        XCTAssertEqual(l.misses, 0)
        XCTAssertEqual(move(&l, ["t": 1]), .moved(1))
        XCTAssertEqual(move(&l, ["w": 0]), .notYet("That one is flat. It lies on the paper."))
        XCTAssertEqual(move(&l, ["w": 1]), .moved(2))
        XCTAssertEqual(move(&l, ["f": -1]), .notYet("That’s round. Find a flat part."))
        XCTAssertEqual(move(&l, ["f": 0]), .notYet("This part is flat."))
        XCTAssertEqual(move(&l, ["f": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "One circle at each end. Tap rolls or slides.")
        XCTAssertEqual(move(&l, ["r": 1]), .notYet("A cylinder has a round side. Lay it down and it rolls."))
        XCTAssertEqual(move(&l, ["r": 0]), .moved(4))
        let P = Solids3K.Parts(l.numbers)
        XCTAssertEqual(P.names.count, 4)
        XCTAssertEqual(move(&l, ["n": Double(P.names.firstIndex(of: "Rectangle")!)]), .notYet("A rectangle is flat, like a drawing. This shape is solid: a cylinder."))
        if let cone = P.names.firstIndex(of: "Cone") { XCTAssertEqual(move(&l, ["n": Double(cone)]), .notYet("A cone comes to a point. A cylinder has two flat ends.")) }
        XCTAssertEqual(move(&l, ["n": Double(P.rightName)]), .moved(5))
        XCTAssertEqual(l.words.say, "It has two flat circle ends: a cylinder.")
        XCTAssertEqual(P.record, ["It has a flat face.", "It rolls.", "It’s a cylinder."])
    }

    func testSphereAndCube() {
        var s = LessonRun(Solids3K.spec, numbers: Solids3K.numbers(shape: 1))
        _ = move(&s, ["t": 1]); _ = move(&s, ["w": 1])
        XCTAssertEqual(move(&s, ["f": -1]), .notYet("That’s round. It’s round all over."))
        XCTAssertEqual(move(&s, ["f": 0]), .moved(3))
        XCTAssertEqual(s.words.say, "It is round all over, so no part of it is flat. Tap rolls or slides.")
        var c = LessonRun(Solids3K.spec, numbers: Solids3K.numbers(shape: 0))
        _ = move(&c, ["t": 1]); _ = move(&c, ["w": 1]); _ = move(&c, ["f": 1])
        XCTAssertEqual(move(&c, ["r": 0]), .notYet("A cube has flat faces and corners. It slides, but it can’t roll."))
        XCTAssertEqual(move(&c, ["r": 1]), .moved(4))
        XCTAssertEqual(Solids3K.Parts(Solids3K.numbers(shape: 0)).record, ["It has a flat face.", "It slides.", "It’s a cube."])
    }

    func testSolidsGenerator() {
        each(Solids3K.spec, 0) { x in let P = Solids3K.Parts(x); XCTAssertEqual(P.thing, -1); XCTAssertEqual(P.turn, 0) }
        each(Solids3K.spec, 5) { x in let P = Solids3K.Parts(x); XCTAssertGreaterThanOrEqual(P.thing, 0); XCTAssertEqual(P.turn, 0) }
        each(Solids3K.spec, 4) { x in
            let P = Solids3K.Parts(x)
            XCTAssertEqual(P.thing, -1)
            if P.turn == 2 { XCTAssertTrue(["cylinder", "cone"].contains(P.kind)) }
            XCTAssertEqual(Set(P.names).count, 4); XCTAssertTrue(P.names.contains(ShapesK.cap(P.kind))); XCTAssertTrue(P.names.contains(ShapesK.cap(P.s.flat)))
        }
    }

    // MARK: Where is it?

    func testWhereRelations() {
        let cube = WhereIsIt.Thing(kind: 0, bx: 4, by: 2)
        XCTAssertEqual(WhereIsIt.relation(.init(kind: 2, bx: 4, by: 0), to: 0, cube), "behind")
        XCTAssertEqual(WhereIsIt.relation(.init(kind: 2, bx: 4, by: 4), to: 0, cube), "in front of")
        XCTAssertEqual(WhereIsIt.relation(.init(kind: 2, bx: 2, by: 2), to: 0, cube), "beside")
        XCTAssertEqual(WhereIsIt.relation(.init(kind: 2, bx: 4, by: 2, on: 0), to: 0, cube), "above")
        XCTAssertNil(WhereIsIt.relation(.init(kind: 2, bx: 7, by: 2), to: 0, cube))
        let table = WhereIsIt.Thing(kind: WhereIsIt.table, bx: 3, by: 1)
        XCTAssertEqual(WhereIsIt.relation(.init(kind: 1, bx: 5, by: 1), to: 9, table), "below")
        XCTAssertEqual(WhereIsIt.relation(.init(kind: 1, bx: 3, by: 1, on: 9), to: 9, table), "above")
        XCTAssertTrue(WhereIsIt.same("beside", "next to"))
    }

    func testWherePut() {
        let x: Numbers = ["kind": 0, "word": 4, "n": 2, "k0": 0, "x0": 4, "y0": 2, "on0": -1, "k1": 2, "x1": 0, "y1": 0, "on1": -1, "tx": -1, "ty": -1,
                          "ref": 0, "who": 1, "gx": 4, "gy": 0, "gon": -1]
        var l = LessonRun(WhereIsIt.spec, numbers: x)
        XCTAssertEqual(l.words.say, "Put the cone behind the cube.")
        XCTAssertEqual(move(&l, ["p": 1]), .notYet("That’s beside the cube. Behind is the far side."))
        XCTAssertEqual(move(&l, ["p": 0]), .notYet("Behind is the far side."))
        XCTAssertEqual(move(&l, ["p": 8]), .notYet("That top is round. It slides off."))
        XCTAssertEqual(move(&l, ["p": 4]), .moved(1))
        XCTAssertEqual(l.words.say, "Behind is the far side: the cube is between you and the cone.")
        XCTAssertEqual(WhereIsIt.Parts(x).record, "The cone is behind the cube.")
        // next to: beside is the same place, said in the words asked
        var y = x; y["word"] = 1
        var n = LessonRun(WhereIsIt.spec, numbers: y)
        XCTAssertEqual(move(&n, ["p": 4]), .notYet("That’s behind the cube. Next to is just left or right of it."))
        XCTAssertEqual(move(&n, ["p": 1]), .moved(1))
    }

    func testWhereGenerator() {
        for i in [0, 4, 7] {
            each(WhereIsIt.spec, i, 200) { x in
                let P = WhereIsIt.Parts(x)
                if i < 3 { XCTAssertTrue(P.put); XCTAssertTrue(["beside", "next to", "above"].contains(P.word)); XCTAssertNil(P.table) }
                else if i < 6 { XCTAssertTrue(P.put); XCTAssertTrue(["in front of", "behind"].contains(P.word)) }
                else { XCTAssertNotNil(P.table); if P.put { XCTAssertEqual(P.word, "below") } else { XCTAssertNotEqual(P.word, "next to") } }
                // on the floor, nothing over anything else (a put's things never touch; a find's stand by the one they go by)
                let floor = P.things.filter { $0.on < 0 }, feet = floor.map(\.foot)
                func over(_ a: (x: Int, y: Int, w: Int, h: Int), _ b: (x: Int, y: Int, w: Int, h: Int)) -> Bool { a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h }
                for f in feet + (P.table.map { [$0.foot] } ?? []) { XCTAssertTrue(f.x >= 0 && f.y >= 0 && f.x + f.w <= 10 && f.y + f.h <= 6) }
                for a in feet.indices { for b in feet.indices where b > a {
                    XCTAssertFalse(P.put ? WhereIsIt.touch(feet[a], feet[b]) : over(feet[a], feet[b]), "\(x)")
                } }
                if let t = P.table { for th in floor where P.relation(of: th) != "below" || P.ref != WhereIsIt.table { if !(P.ref == WhereIsIt.table && WhereIsIt.relation(th, to: 9, t) == "below") { XCTAssertFalse(over(th.foot, t.foot), "\(x)") } } }
                XCTAssertNotEqual(P.who, P.ref)
                if P.put {
                    // the place the words name is free, and it's where the words say
                    let g = P.target!
                    XCTAssertTrue(WhereIsIt.same(P.relation(of: g), P.word))
                    XCTAssertNil(P.letGo(WhereIsIt.code(P.word == "next to" ? "beside" : P.word)))
                } else {
                    let hits = P.things.indices.filter { $0 != P.ref && WhereIsIt.same(P.relation(of: P.things[$0]), P.word) }
                    XCTAssertEqual(hits, [P.who])
                }
            }
        }
    }

    // MARK: Put shapes together

    func testComposePieces() {
        for set in 0..<7 {
            let P = PutShapes.Parts(PutShapes.numbers(set: set))
            // the pieces as the set lays them fill the outline, none over another
            let at = PutShapes.places
            let placed = (0..<P.n).map { j -> [(Double, Double)] in
                let s = set == 4 || set == 5 ? PutShapes.turned(P.S.pieces[0], j * 2) : P.S.pieces[j]
                let b = PutShapes.norm(s)
                return b.map { ($0.0 + at[set][j].0, $0.1 + at[set][j].1) }
            }
            for p in placed { XCTAssertTrue(P.fit(p).all, "set \(set)") }
            for a in placed.indices { for b in placed.indices where b > a { XCTAssertFalse(P.overlap(placed[a], placed[b]), "set \(set)") } }
            // waiting in the tray, past the outline, none over another, nothing past 14 blocks across
            let tray = P.tray.enumerated().map { j, t in P.start(j).map { ($0.0 + t.0, $0.1 + t.1) } }
            for p in tray { XCTAssertFalse(P.fit(p).some); XCTAssertLessThanOrEqual(p.map(\.0).max() ?? 0, 13) }
            for a in tray.indices { for b in tray.indices where b > a { XCTAssertFalse(P.overlap(tray[a], tray[b])) } }
        }
        let P = PutShapes.Parts(PutShapes.numbers(set: 4))
        XCTAssertTrue(P.fit([(0, 0), (2, 0), (2, 2), (0, 2)]).all)
        let out = P.fit([(2, 0), (4, 0), (4, 2), (2, 2)])
        XCTAssertTrue(out.some); XCTAssertFalse(out.all)
        XCTAssertEqual(PutShapes.turned([(0, 0), (4, 0), (4, 2), (0, 2)], 1).map { "\($0.0),\($0.1)" }, ["2.0,0.0", "2.0,4.0", "0.0,4.0", "0.0,0.0"])
    }

    func testComposeRun() {
        var l = LessonRun(PutShapes.spec, numbers: PutShapes.numbers(set: 4))
        XCTAssertEqual(l.words.say, "Fill the shape.")
        XCTAssertEqual(move(&l, ["f": -1]), .notYet("That one sticks out."))
        XCTAssertEqual(move(&l, ["f": -2]), .notYet("Pieces can’t stack."))
        XCTAssertEqual(move(&l, ["f": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "One shape. Tap its name.")
        let P = PutShapes.Parts(l.numbers)
        XCTAssertEqual(move(&l, ["n": Double(P.choices.firstIndex(of: "triangle")!)]), .notYet("A triangle has 3 sides. This shape has 4 sides."))
        XCTAssertEqual(move(&l, ["n": Double(P.right)]), .moved(2))
        XCTAssertEqual(P.record, "2 triangles make a square.")
        XCTAssertEqual(l.words.say, "Full sides touching, no gaps: they make one bigger shape.")
        each(PutShapes.spec, 0) { XCTAssertTrue((0...3).contains(PutShapes.Parts($0).which)); XCTAssertEqual(PutShapes.Parts($0).turns, [0, 0, 0, 0]) }
        each(PutShapes.spec, 4) { x in
            let P = PutShapes.Parts(x)
            XCTAssertTrue((4...6).contains(P.which))
            // one piece must turn: the same half twice, or the big triangle's half turned
            XCTAssertTrue(P.halves || P.turns.prefix(2).contains { $0 != 0 })
        }
    }
}
