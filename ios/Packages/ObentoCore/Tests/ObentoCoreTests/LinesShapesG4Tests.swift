import XCTest
@testable import ObentoCore

/// 4th grade, chapter 8: Lines and shapes (design/grade4.md, the preview design/prototype/grade4-ch8.html).
final class LinesShapesG4Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(81 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 11)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(4)[7]
        XCTAssertEqual(ch.title, "Lines and shapes")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
        XCTAssertEqual(Geo4.stepsWords(3, -1), "3 across and 1 up")
        XCTAssertEqual(Geo4.stepsWords(-6, 2), "3 across and 1 up")
        XCTAssertEqual(Geo4.stepsWords(0, 4), "straight up")
        XCTAssertEqual(Geo4.stepsWords(5, 0), "straight across")
        XCTAssertEqual(Geo4.kind(45), 0); XCTAssertEqual(Geo4.kind(90), 1); XCTAssertEqual(Geo4.kind(135), 2); XCTAssertEqual(Geo4.kind(180), 3)
    }

    /// Call of 3 Nov: a first miss only rings the general area; the exact spot waits for a second miss.
    func testHintsWait() {
        for spec in [LinesRays.spec, Turns4.spec, Protractor4.spec, AnglesAdd.spec, Classify4.spec, Symmetry4.spec] {
            for i in 0..<9 {
                var rng = SeededRandom(seed: UInt64(i))
                for st in spec.steps(spec.generate(&rng, i)) where !st.onMiss.isEmpty {
                    XCTAssertNil(st.onMiss["spot"], spec.id); XCTAssertEqual(st.hint2["spot"], 1, spec.id)
                }
            }
        }
    }

    // MARK: Points, lines, rays and angles

    func testRay() {
        var l = LessonRun(LinesRays.spec, numbers: LinesRays.numbers(kind: 0, item: 1))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Tap each end. A dot or an arrowhead?")
        _ = l.go()
        XCTAssertEqual(move(&l, ["e": -1]), .notYet("That’s point A, not an end. Tap where it stops or goes on."))
        XCTAssertEqual(move(&l, ["e": -3]), .notYet("Tap the ends: where it stops or goes on."))
        XCTAssertFalse(l.missed)
        XCTAssertEqual(move(&l, ["e": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "What is it called? Tap its name.")
        XCTAssertEqual(move(&l, ["c": 2]), .notYet("A segment has two endpoints and stops at both."))
        XCTAssertEqual(move(&l, ["c": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "No endpoints is a line, 1 is a ray, 2 is a segment.")
        XCTAssertEqual(LinesRays.Parts(l.numbers).named, "ray AB")
    }

    func testAngle() {
        var l = LessonRun(LinesRays.spec, numbers: LinesRays.numbers(kind: 1, item: 0, deg: 40))
        _ = l.go()
        XCTAssertEqual(l.words.say, "How wide does it open? Drag the page corner onto its corner.")
        XCTAssertEqual(move(&l, ["k": 0]), .notYet("Put the page corner’s point on the angle’s corner."))
        XCTAssertEqual(move(&l, ["k": 1]), .moved(2))
        XCTAssertEqual(LinesRays.Parts(l.numbers).finding, "It fits inside the page corner.")
        XCTAssertEqual(move(&l, ["c": 2]), .notYet("Long arms don’t make a bigger angle. Look at how wide it opens."))
        XCTAssertEqual(move(&l, ["c": 0]), .moved(3))
        let s = LinesRays.Parts(LinesRays.numbers(kind: 1, item: 3, deg: 180))
        XCTAssertEqual(s.names, ["Acute", "Right", "Obtuse", "Straight"])
        XCTAssertEqual(s.why, "Opened all the way into a straight line, it’s a straight angle.")
        XCTAssertEqual(LinesRays.Parts(LinesRays.numbers(kind: 1, item: 2, deg: 130)).choose(0), .wrong("Acute is smaller than a square corner."))
    }

    func testTwoLines() {
        var l = LessonRun(LinesRays.spec, numbers: LinesRays.numbers(kind: 2, item: 1, turn: 1))
        XCTAssertEqual(l.steps.count, 5)
        _ = l.go()
        XCTAssertEqual(l.words.say, "Run each line on. Drag an arrowhead away from the line.")
        XCTAssertEqual(move(&l, ["r": 0]), .notYet("Drag the arrowhead away from the line, so it goes on."))
        XCTAssertEqual(move(&l, ["r": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Are the corners square? Drag the page corner to where they cross.")
        XCTAssertEqual(move(&l, ["k": 1]), .moved(3))
        XCTAssertEqual(move(&l, ["c": 0]), .notYet("Keep them going: they get closer and cross. Parallel lines stay the same distance apart."))
        XCTAssertEqual(move(&l, ["c": 2]), .notYet("They meet at square corners, so they’re perpendicular."))
        XCTAssertEqual(move(&l, ["c": 1]), .moved(4))
        let p = LinesRays.Parts(l.numbers)
        XCTAssertTrue(Geo4.perp(p.d1, p.d2))
        // parallel lines have no page corner step
        XCTAssertEqual(LinesRays.Parts(LinesRays.numbers(kind: 2, item: 0)).stages, [.ask, .run, .name, .done])
        // crossing lines' second line is on grid steps near the angle
        for t in 0..<6 {
            let q = LinesRays.Parts(LinesRays.numbers(kind: 2, item: 2, deg: 45, turn: t))
            XCTAssertFalse(Geo4.same(q.d1, q.d2)); XCTAssertFalse(Geo4.perp(q.d1, q.d2))
        }
    }

    func testMakeIt() {
        let ray = LinesRays.Parts(LinesRays.numbers(kind: 0, item: 1, make: true))
        XCTAssertEqual(ray.say(.make), "Make a ray from A through B. Tap each end for a dot or an arrowhead. Then Check.")
        XCTAssertEqual(ray.ends(10), .soft("Tap both ends: a dot or an arrowhead."))
        XCTAssertEqual(ray.ends(12), .right)
        XCTAssertEqual(ray.ends(21), .wrong("That ray starts at the other end. Ray AB starts at A and goes on through B."))
        XCTAssertEqual(ray.ends(22), .wrong("That’s a line: it goes on both ways. A ray stops at A."))
        let ang = LinesRays.Parts(LinesRays.numbers(kind: 1, item: 2, make: true))
        XCTAssertEqual(ang.say(.turn), "Make an obtuse angle. Turn the free arm.")
        XCTAssertEqual(ang.turned(120), .right)
        XCTAssertEqual(ang.turned(60), .wrong("That’s an acute angle: it fits inside the page corner. An obtuse angle opens past it."))
        XCTAssertEqual(ang.turned(180), .wrong("That’s a straight angle: a straight line. An obtuse angle opens past the page corner, but not all the way."))
        let par = LinesRays.Parts(LinesRays.numbers(kind: 2, item: 0, turn: 1, make: true))
        XCTAssertEqual(par.relation((4, -2)), 0); XCTAssertEqual(par.relation((1, 2)), 1); XCTAssertEqual(par.relation((1, 0)), 2)
        XCTAssertEqual(par.drawn(2), .wrong("Run them on: they’d cross. Go the same steps as this one: 2 across and 1 up."))
        XCTAssertEqual(par.drawn(0), .right)
    }

    func testLinesGenerator() {
        for i in 0..<12 {
            each(LinesRays.spec, i, 100) { x in
                let p = LinesRays.Parts(x)
                if i < 3 { XCTAssertEqual(p.kind, i == 1 ? 1 : 0) } else { XCTAssertEqual(p.kind, i % 3) }
                XCTAssertEqual(p.make, i >= 6 && i % 2 == 0)
                if p.kind == 1 && !p.make { XCTAssertTrue(p.deg == 30 || p.deg == 90 || p.deg == 150 || p.deg == 180 || (15...80).contains(p.deg) || (100...165).contains(p.deg)) }
                if p.kind == 2 && p.item == 2 { XCTAssertTrue((30...70).contains(p.deg)) }
            }
        }
        let c = checks(LinesRays.spec).map(LinesRays.Parts.init)
        XCTAssertEqual(c.count, 5)
        XCTAssertEqual(c[0].kind, 0); XCTAssertTrue(c[1].deg < 90); XCTAssertTrue(c[2].deg > 90 && c[2].deg < 180)
        XCTAssertEqual(c[3].item, 1); XCTAssertEqual(c[4].item, 2)
    }

    // MARK: Angles and degrees

    func testTurns() {
        var l = LessonRun(Turns4.spec, numbers: Turns4.numbers(n: 1, d: 4))
        XCTAssertEqual(l.words.say, "Turn it 1/4 of the way round. Drag the arm round.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["t": 120]), .notYet("That’s 1/3 of a turn: 120°. A quarter is 90°."))
        XCTAssertEqual(move(&l, ["t": 95]), .notYet("That’s 95°. A quarter is 90°."))
        XCTAssertEqual(move(&l, ["t": 90]), .moved(2))
        XCTAssertEqual(move(&l, ["R": 25]), .notYet("A whole turn is 360°."))
        XCTAssertEqual(move(&l, ["R": 270]), .notYet("That’s the rest of the turn. Read the part you turned."))
        XCTAssertEqual(move(&l, ["R": 45]), .notYet("That’s a part of half a turn."))
        XCTAssertEqual(move(&l, ["R": 80]), .notYet("Split 360° into 4 equal parts."))
        XCTAssertEqual(move(&l, ["R": 90]), .moved(3))
        XCTAssertEqual(l.words.say, "A whole turn is 360 one-degree steps.")
        let c = Turns4.Parts(Turns4.clock(4))
        XCTAssertEqual(c.question, "The minute hand turns from 12 to 4.")
        XCTAssertEqual(c.turned(90), .wrong("That’s from 12 to 3. Stop at 4."))
        XCTAssertEqual(c.written(20), .wrong("That’s minutes. Each number is 30° of the turn."))
        XCTAssertEqual(c.written(240), .wrong("That’s the rest of the way round."))
        XCTAssertEqual(c.written(120), .right)
        XCTAssertTrue(Turns4.part(120)! == (1, 3)); XCTAssertNil(Turns4.part(95))
    }

    func testTurnsGenerator() {
        for i in 0..<9 {
            each(Turns4.spec, i, 100) { x in
                let p = Turns4.Parts(x)
                XCTAssertTrue((1...359).contains(p.ans))
                if i == 0 { XCTAssertEqual(p.ans, 90) }
                if i >= 3 && i % 3 == 1 { XCTAssertTrue(p.clock) }
                if !p.clock { XCTAssertEqual(Geo4.g(p.n, p.d), 1); XCTAssertEqual(360 * p.n % p.d, 0) }
            }
        }
        let c = checks(Turns4.spec).map(Turns4.Parts.init)
        XCTAssertTrue([3, 6].contains(c[1].d)); XCTAssertTrue(c[2].clock); XCTAssertTrue([8, 12].contains(c[3].d))
    }

    // MARK: Measuring angles

    func testMeasure() {
        var l = LessonRun(Protractor4.spec, numbers: Protractor4.numbers(deg: 130))
        XCTAssertEqual(l.words.say, "How big is this angle? Lay the protractor on it.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["p": 0]), .notYet("Put its centre on the corner."))
        XCTAssertEqual(move(&l, ["p": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Read where the other arm crosses. Type it.")
        XCTAssertEqual(move(&l, ["R": 50]), .notYet("That’s the other scale. Count from the 0 on the bottom arm: this angle is bigger than a square corner."))
        XCTAssertEqual(move(&l, ["R": 120]), .notYet("That’s one long mark off. Find the long mark just before the arm, then count on: each small mark is 1°."))
        XCTAssertEqual(move(&l, ["R": 133]), .notYet("Read the scale that starts at 0 on the first arm."))
        XCTAssertEqual(move(&l, ["R": 130]), .moved(3))
        XCTAssertEqual(l.words.say, "Count from the 0 on the first arm.")
    }

    func testDrawAngle() {
        var l = LessonRun(Protractor4.spec, numbers: Protractor4.numbers(deg: 65, draw: true))
        XCTAssertEqual(l.steps.count, 3)
        _ = l.go()
        XCTAssertEqual(l.words.say, "Make an angle of 65°. Turn the free arm.")
        XCTAssertEqual(move(&l, ["a": 115]), .notYet("That’s 115°. 65° is smaller than a square corner."))
        XCTAssertEqual(move(&l, ["a": 70]), .notYet("That’s 70°. Count from the 0 on the first arm."))
        XCTAssertEqual(move(&l, ["a": 65]), .moved(2))
        for i in 0..<9 {
            each(Protractor4.spec, i, 60) { x in
                let p = Protractor4.Parts(x)
                XCTAssertTrue((10...170).contains(p.deg)); XCTAssertEqual(p.draw, i % 2 == 1); XCTAssertEqual(p.left, (i / 2) % 2 == 1)
                if i < 3 { XCTAssertEqual(p.deg % 10, 0) } else if i < 6 { XCTAssertEqual(p.deg % 5, 0) }
            }
        }
        let c = checks(Protractor4.spec).map(Protractor4.Parts.init)
        XCTAssertTrue(!c[0].draw && c[0].deg > 90); XCTAssertTrue(!c[1].draw && c[1].left && c[1].deg < 90)
        XCTAssertTrue(c[2].draw && c[2].deg < 90); XCTAssertTrue(c[3].draw && c[3].deg > 90)
    }

    // MARK: Angles add up

    func testRightAngle() {
        var l = LessonRun(AnglesAdd.spec, numbers: AnglesAdd.numbers(a: 35))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "How big is the whole corner? Drag the page corner onto it.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["k": 0]), .notYet("Put the page corner’s point on the angle’s corner."))
        XCTAssertEqual(move(&l, ["k": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "How big is the other part? Type it.")
        XCTAssertEqual(move(&l, ["R": 145]), .notYet("These two make a right angle, 90°."))
        XCTAssertEqual(move(&l, ["R": 125]), .notYet("The missing part is smaller than the whole."))
        XCTAssertEqual(move(&l, ["R": 50]), .notYet("What goes with 35° to make 90°?"))
        XCTAssertEqual(move(&l, ["R": 55]), .moved(3))
        XCTAssertEqual(l.words.say, "The two parts fill the square corner.")
    }

    func testStraightAndFolds() {
        var l = LessonRun(AnglesAdd.spec, numbers: AnglesAdd.numbers(st: true, a: 70))
        XCTAssertEqual(l.steps.count, 5)
        _ = l.go(); _ = move(&l, ["k": 1])
        XCTAssertEqual(l.words.say, "How big is the whole corner? Another one fits beside it.")
        _ = move(&l, ["k": 1])
        XCTAssertEqual(move(&l, ["R": 20]), .notYet("These two make a straight line, 180°."))
        XCTAssertEqual(move(&l, ["R": 110]), .moved(4))
        var m = LessonRun(AnglesAdd.spec, numbers: AnglesAdd.numbers(a: 40, fold: 1, W: 125))
        XCTAssertEqual(m.steps.count, 5)
        _ = m.go(); _ = move(&m, ["p": 1])
        XCTAssertEqual(move(&m, ["W": 55]), .notYet("That’s the other scale. Count from the 0 on the bottom arm: this angle is bigger than a square corner."))
        XCTAssertEqual(move(&m, ["W": 125]), .moved(3))
        XCTAssertEqual(move(&m, ["R": 85]), .moved(4))
        XCTAssertEqual(m.words.say, "The two parts fill the whole angle.")
        let w = AnglesAdd.Parts(AnglesAdd.numbers(a: 40, fold: 2, b: 75))
        XCTAssertEqual(w.ans, 115)
        XCTAssertEqual(w.written(35), .wrong("Both parts fill the whole angle: add them."))
        XCTAssertEqual(w.written(100), .wrong("Add the two parts: 40° and 75°."))
        for i in 0..<9 {
            each(AnglesAdd.spec, i, 100) { x in
                let p = AnglesAdd.Parts(x)
                XCTAssertGreaterThan(p.ans, 0); XCTAssertLessThan(p.T, 180 + 1)
                if i < 3 { XCTAssertEqual(p.T, 90); XCTAssertEqual(p.a % 10, 0) }
                if p.fold == 1 { XCTAssertGreaterThan(p.miss!, 10) }
            }
        }
        let c = checks(AnglesAdd.spec).map(AnglesAdd.Parts.init)
        XCTAssertTrue(c[2].st); XCTAssertTrue(c[3].st && c[3].a % 10 != 0); XCTAssertNotEqual(c[4].fold, 0)
    }

    // MARK: Sorting by sides and angles

    func testSortRectangle() {
        var l = LessonRun(Classify4.spec, numbers: Classify4.numbers(shape: 0))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Which corners are square? Tap each square corner. Then No more.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("There’s another square corner."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(2))
        XCTAssertEqual(move(&l, ["y": 100 + 1]), .notYet("Not parallel: one goes straight across, the other straight up."))
        XCTAssertEqual(move(&l, ["y": 1]), .notYet("There’s another parallel pair."))
        XCTAssertEqual(move(&l, ["y": 0]), .notYet("Look again: two of its sides go the same steps."))
        XCTAssertEqual(move(&l, ["y": 2]), .moved(3))
        XCTAssertEqual(move(&l, ["z": 2]), .notYet("It has a square corner, so it goes in that loop too."))
        XCTAssertEqual(move(&l, ["z": 3]), .moved(4))
        XCTAssertEqual(Classify4.Parts(l.numbers).record, "2 pairs of parallel sides, 4 square corners: both loops.")
    }

    func testSortShapes() {
        let tri = Classify4.Parts(Classify4.numbers(shape: 1))
        XCTAssertTrue(tri.tri); XCTAssertEqual(tri.marks.count, 1); XCTAssertEqual(tri.want, [true, false])
        XCTAssertEqual(tri.record, "1 square corner: the square corner loop.")
        XCTAssertEqual(tri.sortVerdict(3), .wrong("It has no obtuse angle: keep it out of that loop."))
        XCTAssertEqual(tri.cornersVerdict(102), .wrong("That corner isn’t square: the page corner doesn’t fit it."))
        let par = Classify4.Parts(Classify4.numbers(shape: 2))
        XCTAssertEqual(par.pairs.count, 2); XCTAssertEqual(par.want, [true, false])
        XCTAssertEqual(par.sidesVerdict(100 + 10 * 0 + 1), .wrong("Not parallel: one goes straight across, the other 1 across and 2 up."))
        let rt = Classify4.Parts(Classify4.numbers(shape: 6, rot: 1, flip: true))
        XCTAssertEqual(rt.want, [true, true]); XCTAssertEqual(rt.nS, 2)
        let kite = Classify4.Parts(Classify4.numbers(shape: 7, rot: 3))
        XCTAssertEqual(kite.want, [false, false]); XCTAssertEqual(kite.record, "No parallel sides, no square corners: neither loop.")
        let ob = Classify4.Parts(Classify4.numbers(shape: 10))
        XCTAssertEqual(ob.want, [false, true]); XCTAssertEqual(ob.marks.count, 1)
        // turned or mirrored, a shape keeps its corners and pairs
        for s in 0..<Classify4.shapes.count {
            let a = Classify4.Parts(Classify4.numbers(shape: s))
            for r in 0..<4 { for f in [false, true] {
                let b = Classify4.Parts(Classify4.numbers(shape: s, rot: r, flip: f))
                XCTAssertEqual(a.want, b.want); XCTAssertEqual(a.pairs.count, b.pairs.count)
                XCTAssertEqual(b.pts.map(\.0).min(), 0); XCTAssertEqual(b.pts.map(\.1).min(), 0)
            } }
        }
        let c = checks(Classify4.spec).map(Classify4.Parts.init)
        XCTAssertTrue([1, 9].contains(c[0].shape)); XCTAssertEqual(c[1].shape, 2); XCTAssertEqual(c[2].shape, 6); XCTAssertEqual(c[3].shape, 7)
    }

    // MARK: Lines of symmetry

    func testSymmetryFold() {
        var l = LessonRun(Symmetry4.spec, numbers: Symmetry4.numbers(kind: 0, shape: 1, line: 2))
        let p = Symmetry4.Parts(l.numbers)
        XCTAssertFalse(p.ok)
        XCTAssertEqual(p.landed(1), "1 corner sticks out.")
        XCTAssertEqual(l.words.say, "Is the dashed line a line of symmetry? Fold on it: drag one half over the line.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["f": 0]), .notYet("Drag the half all the way over the line."))
        XCTAssertEqual(move(&l, ["f": 1]), .moved(2))
        XCTAssertEqual(move(&l, ["c": 0]), .notYet("Folded on a diagonal, the corners stick out."))
        XCTAssertEqual(move(&l, ["c": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "A line of symmetry lands every corner on a corner.")
        let sq = Symmetry4.Parts(Symmetry4.numbers(kind: 0, shape: 0, line: 2))
        XCTAssertTrue(sq.ok); XCTAssertEqual(sq.landed(1), "Every corner lands on a corner.")
        XCTAssertEqual(Symmetry4.Parts(Symmetry4.numbers(kind: 0, shape: 6, line: 0)).yesNo(0), .wrong("A parallelogram’s halves match if you turn one, not if you fold it."))
        // every shape's lines fold it onto itself, its tempting lines don't, turned or not
        for (k, s) in Symmetry4.shapes.enumerated() {
            for t in 0..<4 {
                let q = Symmetry4.Parts(Symmetry4.numbers(kind: 1, shape: k, turn: t))
                for a in q.trueLines { XCTAssertTrue(Symmetry4.isSym(q.local, a), "\(s.name) \(a)") }
                for a in s.traps { XCTAssertFalse(Symmetry4.isSym(q.local, (a + 90 * Double(t)).truncatingRemainder(dividingBy: 180)), "\(s.name) trap \(a)") }
            }
        }
    }

    func testSymmetryCount() {
        var l = LessonRun(Symmetry4.spec, numbers: Symmetry4.numbers(kind: 1, shape: 0))
        _ = l.go()
        XCTAssertEqual(l.words.say, "How many lines of symmetry? Draw a fold line across it. Then No more.")
        XCTAssertEqual(move(&l, ["n": -1]), .notYet("Parts stick out: that’s not a line of symmetry."))
        XCTAssertEqual(move(&l, ["n": 2]), .moved(2))
        XCTAssertEqual(move(&l, ["R": 2]), .notYet("A square folds on its diagonals too: 4 in all."))
        XCTAssertEqual(move(&l, ["R": 4]), .moved(3))
        XCTAssertEqual(l.words.say, "A square folds 4 ways.")
        XCTAssertEqual(Symmetry4.Parts(Symmetry4.numbers(kind: 1, shape: 1)).count(4), .wrong("The diagonals don’t work for a rectangle. Only the two through the middles of the sides: 2."))
        XCTAssertEqual(Symmetry4.Parts(Symmetry4.numbers(kind: 1, shape: 5)).count(5), .wrong("A regular shape with 6 sides has 6 lines of symmetry."))
        XCTAssertEqual(Symmetry4.Parts(Symmetry4.numbers(kind: 1, shape: 6)).why, "No fold makes the two halves match.")
        for i in 0..<9 {
            each(Symmetry4.spec, i, 60) { x in
                let p = Symmetry4.Parts(x)
                XCTAssertEqual(p.kind, i < 3 ? 0 : i % 2)
                if i < 3 { XCTAssertEqual(p.shape, [1, 0, 7][i]) }
                if i <= 5 { XCTAssertEqual(p.turn, 0) }
            }
        }
        let c = checks(Symmetry4.spec).map(Symmetry4.Parts.init)
        XCTAssertTrue(c[0].ok); XCTAssertFalse(c[1].ok); XCTAssertEqual(c[2].kind, 1); XCTAssertTrue([1, 6].contains(c[3].shape))
    }
}
