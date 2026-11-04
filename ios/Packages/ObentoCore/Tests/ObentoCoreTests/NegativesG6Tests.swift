import XCTest
@testable import ObentoCore

/// 6th grade, chapter 4: Negative numbers (design/grade6.md, the preview design/prototype/grade6-ch4.html).
final class NegativesG6Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func typeAll(_ l: inout LessonRun, _ v: [(String, String)]) -> LessonRun.Outcome {
        l.reset()
        for (b, x) in v { l.active = b; for ch in x { l.type(String(ch)) } }
        return l.go()
    }
    private func choose(_ l: inout LessonRun, _ i: Int) -> LessonRun.Outcome { l.choose(i); return l.go() }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(41 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(6)[3]
        XCTAssertEqual(ch.title, "Negative numbers")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
        XCTAssertEqual(Curriculum.grade(of: "g6-planeshapes"), 6)
    }

    func testMinusTyped() {
        var l = LessonRun(Quadrants6.spec, numbers: Quadrants6.numbers(x: -3, y: 5, kind: 1))
        _ = l.go(); _ = move(&l, ["x": -3, "y": 5]); _ = move(&l, ["f": 1])
        XCTAssertEqual(l.words.say, "Write where it printed.")
        l.active = "x"; l.type("−"); l.type("3")
        XCTAssertEqual(l.typed["x"], "-3")
        l.type("−"); XCTAssertEqual(l.typed["x"], "3")
        l.type("-"); XCTAssertEqual(l.typed["x"], "-3")
        // a minus alone isn't a number yet
        l.active = "y"; l.type("−")
        XCTAssertEqual(l.go(), .notYet("Fill in every box."))
    }

    // MARK: Negative numbers

    func testNegatives() {
        var l = LessonRun(Negatives6.spec, numbers: Negatives6.numbers(kind: 0, n: 7))
        XCTAssertEqual(l.words.say, "It’s 7 below zero. Drag the point to it.")
        _ = l.go()
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("That’s 7 above 0."))
        XCTAssertEqual(move(&l, ["x": -8]), .notYet("Count from 0, not from the end of the line."))
        XCTAssertEqual(move(&l, ["x": -6]), .notYet("That’s −6."))
        XCTAssertEqual(move(&l, ["x": -7]), .moved(2))
        XCTAssertEqual(l.words.say, "Fold the paper at 0. Drag the half with the point over the 0 line.")
        XCTAssertEqual(move(&l, ["f": 0]), .notYet("Fold the half with the point."))
        XCTAssertEqual(move(&l, ["f": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "Write the opposite.")
        XCTAssertEqual(l.step.answer?.prompt.first, .text("−(−7)"))
        XCTAssertEqual(typeAll(&l, [("x", "-7")]), .notYet("That’s where it started. The fold lands on the other side of 0."))
        XCTAssertEqual(typeAll(&l, [("x", "6")]), .notYet("Read the number where the fold printed it."))
        XCTAssertEqual(typeAll(&l, [("x", "7")]), .moved(4))
        XCTAssertEqual(l.words.say, "−7 and 7 are the same distance from 0, on opposite sides.")
    }

    func testOppositesAndTwice() {
        let have = Negatives6.Parts(Negatives6.numbers(kind: 3, n: 5))
        XCTAssertEqual(have.t, 5); XCTAssertEqual(have.ans, -5); XCTAssertEqual(have.placed(-5), "That’s 5 left of 0.")
        XCTAssertFalse(have.up); XCTAssertEqual(have.U, 2)
        var l = LessonRun(Negatives6.spec, numbers: Negatives6.numbers(kind: 4, n: 6))
        XCTAssertEqual(l.words.say, "Find −(−6). Put 6 on the line.")
        _ = l.go(); _ = move(&l, ["x": 6]); _ = move(&l, ["f": 1])
        XCTAssertEqual(l.words.say, "Now fold that half back over 0.")
        XCTAssertEqual(move(&l, ["f": 1]), .moved(4))
        XCTAssertEqual(l.step.answer?.prompt.first, .text("−(−6)"))
        XCTAssertEqual(typeAll(&l, [("x", "-6")]), .notYet("That’s one fold. The second lands where it started."))
        XCTAssertEqual(typeAll(&l, [("x", "6")]), .moved(5))
        XCTAssertEqual(l.words.say, "Two folds land where it started: −(−6) = 6.")
        let half = Negatives6.Parts(Negatives6.numbers(kind: 5, n: 3.5))
        XCTAssertEqual(half.placeSay, "It’s −3.5 °C. Put −3.5 on the line.")
        XCTAssertEqual(half.lo, -8); XCTAssertEqual(half.step, 0.5)
        let loss = Negatives6.Parts(Negatives6.numbers(kind: 6, n: 4))
        XCTAssertEqual(loss.why, "A loss of 4 and a gain of 4 are the same distance from 0, on opposite sides.")
    }

    func testNegativesGenerator() {
        for i in 0..<12 {
            each(Negatives6.spec, i, 120) { n in
                let s = Negatives6.Parts(n)
                XCTAssertLessThanOrEqual(abs(s.t), s.hi)
                if i < 3 { XCTAssertTrue(s.up); XCTAssertLessThan(s.t, 0); XCTAssertLessThanOrEqual(abs(s.t), i == 0 ? 6 : 10) }
                else if i < 6 { XCTAssertFalse(s.up); XCTAssertEqual(s.t > 0, i == 4) }
                if s.half { XCTAssertEqual(s.t.truncatingRemainder(dividingBy: 1), -0.5) }
            }
        }
        let c = checks(Negatives6.spec).map(Negatives6.Parts.init)
        XCTAssertTrue(c[0].up); XCTAssertFalse(c[1].up); XCTAssertTrue(c[2].twice); XCTAssertTrue(c[3].half)
    }

    // MARK: Compare and order

    func testCompare() {
        var l = LessonRun(Compare6.spec, numbers: Compare6.numbers(kind: 1, [-7, -3]))
        XCTAssertEqual(l.words.say, "Put −7 and −3 on the line: drag each point to its number.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["x": Neg6.wrong(0, 7)]), .notYet("That’s 7. −7 is left of 0."))
        XCTAssertEqual(move(&l, ["x": Neg6.wrong(1, -4)]), .notYet("That’s −4."))
        XCTAssertEqual(move(&l, ["x": 2]), .moved(2))
        XCTAssertEqual(l.words.say, "Pick < or > between them.")
        XCTAssertEqual(choose(&l, 1), .notYet("−7 is left of −3, so it’s less."))
        XCTAssertEqual(choose(&l, 0), .moved(3))
        XCTAssertEqual(l.words.say, "Left is less. −7 is less than −3.")
        let d = Neg6.dropped(Neg6.wrong(2, -2.5))
        XCTAssertEqual(d.j, 2); XCTAssertEqual(d.v, -2.5)
    }

    func testCompareThreeAndAbs() {
        var l = LessonRun(Compare6.spec, numbers: Compare6.numbers(kind: 4, [-2, 5, -6]))
        _ = l.go(); _ = move(&l, ["x": 3])
        XCTAssertEqual(l.words.say, "Write them in order, least first.")
        XCTAssertEqual(typeAll(&l, [("o0", "-2"), ("o1", "5"), ("o2", "-6")]), .notYet("Left is less: read them off the line from the left."))
        XCTAssertEqual(typeAll(&l, [("o0", "-6"), ("o1", "5"), ("o2", "-2")]), .notYet("Write each number from the line, least first."))
        XCTAssertEqual(typeAll(&l, [("o0", "-6"), ("o1", "-2"), ("o2", "5")]), .moved(3))
        XCTAssertEqual(l.words.say, "Left is less. −6 < −2 < 5 reads left to right.")

        var a = LessonRun(Compare6.spec, numbers: Compare6.numbers(kind: 5, [-8, -5]))
        XCTAssertEqual(a.words.say, "One friend owes $8, another owes $5. A debt is below 0: drag each point to its number.")
        _ = a.go(); _ = move(&a, ["x": 2]); _ = choose(&a, 0)
        XCTAssertEqual(a.words.say, "Measure each one from 0: drag from 0 to each point.")
        XCTAssertEqual(move(&a, ["x": -1]), .notYet("Stop at a point."))
        XCTAssertEqual(move(&a, ["x": 2]), .moved(4))
        XCTAssertEqual(a.step.answer?.choices, ["$8 debt", "$5 debt"])
        XCTAssertEqual(choose(&a, 1), .notYet("Look at the brackets: the longer one is the bigger debt."))
        XCTAssertEqual(choose(&a, 0), .moved(5))
        XCTAssertEqual(a.words.say, "Left is less. −8 is less than −5, but a $8 debt is the bigger debt.")
        XCTAssertEqual(Compare6.Parts(Compare6.numbers(kind: 6, [-7, -3])).tempWords, "−7 °C is colder than −3 °C.")
    }

    func testCompareGenerator() {
        for i in 0..<14 {
            each(Compare6.spec, i, 120) { n in
                let s = Compare6.Parts(n)
                XCTAssertEqual(Set(s.vs).count, s.vs.count)
                for v in s.vs { XCTAssertLessThanOrEqual(abs(v), 12); XCTAssertNotEqual(v, 0) }
                if i < 3 { XCTAssertTrue(s.vs.contains { $0 < 0 } && s.vs.contains { $0 > 0 }) }
                else if i < 6 { XCTAssertTrue(s.vs.allSatisfy { $0 < 0 }) }
            }
        }
        let c = checks(Compare6.spec).map(Compare6.Parts.init)
        XCTAssertEqual(c.map(\.kind), [1, 0, 3, 2])
    }

    // MARK: Distance on a number line

    func testDistance() {
        var l = LessonRun(Distance6.spec, numbers: Distance6.numbers(a: -3, b: 5))
        XCTAssertEqual(l.words.say, "How far apart are −3 and 5? Drag from −3 to 0.")
        _ = l.go()
        XCTAssertEqual(Distance6.Parts(l.numbers).U, 4)
        XCTAssertEqual(move(&l, ["x": -1]), .notYet("Stop at 0."))
        XCTAssertEqual(move(&l, ["x": 0]), .moved(2))
        XCTAssertEqual(l.words.say, "Now from 0 to 5.")
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("Stop at 5."))
        XCTAssertEqual(move(&l, ["x": 5]), .moved(3))
        XCTAssertEqual(typeAll(&l, [("x", "2")]), .notYet("Going from a negative to a positive crosses 0, so add."))
        XCTAssertEqual(typeAll(&l, [("x", "9")]), .notYet("Count the jumps between marks, starting after 0."))
        XCTAssertEqual(typeAll(&l, [("x", "-8")]), .notYet("Distance counts steps, so it’s always positive."))
        XCTAssertEqual(typeAll(&l, [("x", "8")]), .moved(4))
        XCTAssertEqual(l.words.say, "You cross 0, so the two distances add.")
        XCTAssertEqual(Distance6.Parts(Distance6.numbers(a: -9, b: 4)).U, 2)
        for i in [0, 3] {
            each(Distance6.spec, i) { n in
                let s = Distance6.Parts(n)
                XCTAssertTrue(-12 <= s.a && s.a <= -1 && 1 <= s.b && s.b <= 12)
                if i == 0 { XCTAssertTrue(s.a >= -5 && s.b <= 5) }
                XCTAssertLessThanOrEqual((s.sum + 2) * s.U, 56)
            }
        }
        let c = checks(Distance6.spec).map(Distance6.Parts.init)
        XCTAssertTrue(-c[2].a >= 7 && c[2].b >= 7); XCTAssertGreaterThan(-c[3].a, c[3].b)
    }

    // MARK: Points in four quadrants

    func testQuadrants() {
        var l = LessonRun(Quadrants6.spec, numbers: Quadrants6.numbers(x: -3, y: 5, kind: 1))
        XCTAssertEqual(l.words.say, "Put (−3, 5) on the paper: drag the point.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["x": 5, "y": -3]), .notYet("That’s (5, −3). x comes first."))
        XCTAssertEqual(move(&l, ["x": 3, "y": 5]), .notYet("That’s (3, 5). x is −3, left of 0."))
        XCTAssertEqual(move(&l, ["x": -3, "y": -5]), .notYet("That’s (−3, −5). y is 5, above 0."))
        XCTAssertEqual(move(&l, ["x": -3, "y": 5]), .moved(2))
        XCTAssertEqual(l.words.say, "Fold over the x-axis. Drag the half with the point over it.")
        XCTAssertEqual(move(&l, ["f": 2]), .notYet("That flips x. Over the x-axis, y flips."))
        XCTAssertEqual(move(&l, ["f": 0]), .notYet("Fold the half with the point."))
        XCTAssertEqual(move(&l, ["f": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "Write where it printed.")
        XCTAssertEqual(typeAll(&l, [("x", "3"), ("y", "-5")]), .notYet("Over the x-axis, x stays."))
        XCTAssertEqual(typeAll(&l, [("x", "-3"), ("y", "5")]), .notYet("y flips: 5 becomes −5."))
        XCTAssertEqual(typeAll(&l, [("x", "-3"), ("y", "-5")]), .moved(4))
        XCTAssertEqual(l.words.say, "A fold over the x-axis keeps x and flips the sign of y.")
    }

    func testQuadrantsBothAndPick() {
        var l = LessonRun(Quadrants6.spec, numbers: Quadrants6.numbers(x: 4, y: -2, kind: 3))
        _ = l.go(); _ = move(&l, ["x": 4, "y": -2])
        XCTAssertEqual(move(&l, ["f": 2]), .moved(3))
        XCTAssertEqual(l.words.say, "Now fold over the other axis.")
        XCTAssertEqual(move(&l, ["f": 4]), .notYet("That’s the y-axis again. Now fold over the x-axis."))
        XCTAssertEqual(move(&l, ["f": 1]), .moved(4))
        XCTAssertEqual(typeAll(&l, [("x", "4"), ("y", "2")]), .notYet("Both flip."))
        XCTAssertEqual(typeAll(&l, [("x", "-4"), ("y", "2")]), .moved(5))
        var q = LessonRun(Quadrants6.spec, numbers: Quadrants6.numbers(x: -4, y: -2, kind: 5))
        _ = q.go(); _ = move(&q, ["x": -4, "y": -2])
        XCTAssertEqual(q.step.answer?.choices, ["I", "II", "III", "IV"])
        XCTAssertEqual(choose(&q, 1), .notYet("Left of the y-axis and below the x-axis: find that corner."))
        XCTAssertEqual(choose(&q, 2), .moved(3))
        XCTAssertEqual(q.words.say, "x is negative and y is negative: quadrant III.")
    }

    func testQuadrantsGenerator() {
        for i in 0..<12 {
            each(Quadrants6.spec, i, 120) { n in
                let s = Quadrants6.Parts(n)
                XCTAssertLessThanOrEqual(abs(s.x), Double(Neg6.X)); XCTAssertLessThanOrEqual(abs(s.y), Double(Neg6.Y))
                XCTAssertNotEqual(s.x, 0); XCTAssertNotEqual(s.y, 0)
                if i < 3 { XCTAssertTrue((s.x < 0) != (s.y < 0)); XCTAssertLessThanOrEqual(max(abs(s.x), abs(s.y)), 6) }
            }
        }
        let c = checks(Quadrants6.spec).map(Quadrants6.Parts.init)
        XCTAssertEqual(c.prefix(3).map { Quadrants6.quadrant($0.x, $0.y) }, [1, 2, 3])
        XCTAssertEqual(c[3].kind, 1)
    }

    // MARK: Shapes on the plane

    func testShapes() {
        var l = LessonRun(Shapes6.spec, numbers: Shapes6.numbers(x1: -4, x2: 5, y1: -2, y2: 3, out: 0, thing: 0))
        XCTAssertEqual(l.words.say, "The park is a rectangle. Put its other two corners: both have y = −2.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["x": Neg6.corner(5, 1)]), .notYet("That’s (5, 1). Its y is −2."))
        XCTAssertEqual(move(&l, ["x": Neg6.corner(2, -2)]), .notYet("A corner shares x with one corner and y with the other."))
        XCTAssertEqual(Neg6.cornerAt(Neg6.corner(-11, 7)).u, -11); XCTAssertEqual(Neg6.cornerAt(Neg6.corner(-11, -7)).v, -7)
        XCTAssertEqual(move(&l, ["x": 2]), .moved(2))
        XCTAssertEqual(l.words.say, "Measure the top: drag along it from corner to corner.")
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("Stop at the corner."))
        XCTAssertEqual(move(&l, ["x": 9]), .moved(3))
        XCTAssertEqual(Shapes6.Parts(l.numbers).topCount, "4 + 5 = 9")
        XCTAssertEqual(typeAll(&l, [("h", "1")]), .notYet("The side crosses 0: 3 and 2 add."))
        XCTAssertEqual(typeAll(&l, [("h", "6")]), .notYet("Count the units between the corners, not the points."))
        XCTAssertEqual(typeAll(&l, [("h", "5")]), .moved(4))
        XCTAssertEqual(l.words.say, "Now the area.")
        XCTAssertEqual(typeAll(&l, [("A", "28")]), .notYet("That’s all the way round. Area: multiply the sides."))
        XCTAssertEqual(typeAll(&l, [("A", "45")]), .moved(5))
        XCTAssertEqual(l.words.say, "The side crosses the axis, so the two distances to it add.")
        let take = Shapes6.Parts(Shapes6.numbers(x1: 3, x2: 10, y1: -7, y2: -2, out: 1))
        XCTAssertEqual(take.topCount, "10 − 3 = 7"); XCTAssertEqual(take.sideTerms.0, -7)
        XCTAssertEqual(take.side(9), "Both ends are on one side of 0: take away.")
        XCTAssertEqual(take.totalled(35), "That’s the area. Add all four sides.")
        XCTAssertEqual(take.total, 24)
    }

    func testShapesGenerator() {
        for i in 0..<12 {
            each(Shapes6.spec, i, 120) { n in
                let s = Shapes6.Parts(n)
                for c in s.corners {
                    XCTAssertLessThanOrEqual(abs(c.u), Neg6.X - 1); XCTAssertLessThanOrEqual(abs(c.v), Neg6.Y)
                    XCTAssertGreaterThanOrEqual(abs(c.u), 2); XCTAssertGreaterThanOrEqual(abs(c.v), 2)
                }
                XCTAssertNotEqual(s.w * s.h, 2 * (s.w + s.h))
                if i < 3 { XCTAssertTrue(s.crossX) }
                if (3..<6).contains(i) { XCTAssertTrue(s.crossX && s.crossY) }
            }
        }
        let c = checks(Shapes6.spec).map(Shapes6.Parts.init)
        XCTAssertTrue(c[0].crossX); XCTAssertFalse(c[1].crossX); XCTAssertFalse(c[2].perim); XCTAssertTrue(c[3].perim)
    }
}
