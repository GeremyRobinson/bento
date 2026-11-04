import XCTest
@testable import ObentoCore

/// Kindergarten, chapter 3: Measure and sort (design/gradeK.md, the preview design/prototype/gradeK-ch3.html).
final class MeasureKTests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(29 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(0)[2]
        XCTAssertEqual(ch.title, "Measure and sort")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertTrue(Curriculum.voiced(l.id)) }
        XCTAssertEqual(Lessons.spec("gk-heavier")?.depends, ["k-length"])
    }

    // MARK: Longer and shorter

    func testLengthLonger() {
        // the preview's How to: pencil 7, ribbon 4
        var l = LessonRun(LengthK.spec, numbers: LengthK.numbers(top: 0, bottom: 2, a: 7, b: 4, shift: 2))
        XCTAssertEqual(l.words.say, "Line them up.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["l": 1]), .notYet("Its end goes on the line."))
        XCTAssertEqual(move(&l, ["l": -2]), .notYet("Its end goes on the line."))
        XCTAssertEqual(move(&l, ["l": 0]), .moved(1))
        XCTAssertEqual(l.words.say, "Tap the longer one.")
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("The ribbon is only 4 cubes. The pencil is 7."))
        XCTAssertEqual(move(&l, ["c": 2]), .notYet("They are not the same."))
        XCTAssertEqual(move(&l, ["c": 0]), .moved(2))
        XCTAssertEqual(l.words.say, "Count what sticks out. Write how many stick out.")
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("7 is the whole pencil. Count only the cubes past the dashed line."))
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("4 is the whole ribbon. Count only the cubes past the dashed line."))
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("One short. Count every cube past the dashed line."))
        XCTAssertEqual(move(&l, ["x": 9]), .notYet("That’s 9. Count only the cubes past the dashed line."))
        XCTAssertEqual(move(&l, ["x": 3]), .moved(3))
        XCTAssertEqual(l.words.say, "Same start, so the one that sticks out is longer.")
        XCTAssertTrue(l.isLast)
        let P = LengthK.Parts(l.numbers)
        XCTAssertEqual(P.recordWords, "The pencil is longer by")
        XCTAssertEqual(P.unit, "cubes.")
    }

    func testLengthSameAndOneOff() {
        var l = LessonRun(LengthK.spec, numbers: LengthK.numbers(top: 1, bottom: 4, a: 5, b: 5, shift: -1))
        XCTAssertEqual(l.steps.count, 3)
        XCTAssertEqual(move(&l, ["l": 0]), .moved(1))
        XCTAssertEqual(move(&l, ["c": 0]), .notYet("Look again: they end at the same place."))
        XCTAssertEqual(move(&l, ["c": 2]), .moved(2))
        XCTAssertEqual(l.words.say, "They end at the same place. Same start and same end: the same length.")
        XCTAssertEqual(LengthK.Parts(l.numbers).recordWords, "The crayon and the snake are the same length.")
        // one too many, a cube that sticks out alone
        let P = LengthK.Parts(LengthK.numbers(top: 0, bottom: 1, a: 3, b: 4))
        XCTAssertEqual(P.wrote(2), "One too many. Count each cube past the line once.")
        XCTAssertEqual(P.unit, "cube.")
    }

    func testLengthTaller() {
        var l = LessonRun(LengthK.spec, numbers: LengthK.numbers(top: 0, bottom: 3, a: 6, b: 4, tall: true, mover: 1, shift: 2))
        XCTAssertEqual(l.words.say, "Stand them on the floor.")
        XCTAssertEqual(move(&l, ["l": 1]), .notYet("Its foot goes on the floor."))
        XCTAssertEqual(move(&l, ["l": 0]), .moved(1))
        XCTAssertEqual(l.words.say, "Tap the taller one.")
        XCTAssertEqual(move(&l, ["c": 0]), .moved(2))
        XCTAssertEqual(l.words.say, "Count what sticks up. Write how many stick up.")
        XCTAssertEqual(move(&l, ["x": 6]), .notYet("6 is the whole tower. Count only the cubes above the dashed line."))
        XCTAssertEqual(move(&l, ["x": 2]), .moved(3))
        XCTAssertEqual(l.words.say, "Same floor, so the one that sticks up is taller.")
        XCTAssertEqual(LengthK.Parts(l.numbers).recordWords, "The tower is taller by")
        XCTAssertEqual(LengthK.Parts(l.numbers).height, 6)
    }

    func testLengthGenerator() {
        each(LengthK.spec, 0) { x in
            let P = LengthK.Parts(x)
            XCTAssertFalse(P.tall); XCTAssertTrue(P.a <= 8 && P.b <= 8 && P.a >= 2 && P.b >= 2); XCTAssertGreaterThanOrEqual(P.extra, 3)
            XCTAssertNotEqual(P.top, P.bottom); XCTAssertEqual(P.mover, 1)
            XCTAssertTrue((-2...3).contains(P.shift) && P.shift != 0); XCTAssertLessThanOrEqual(P.b + max(0, P.shift), 11)
        }
        var same = 0, tall = 0
        for i in 3..<12 { each(LengthK.spec, i, 200) { x in
            let P = LengthK.Parts(x)
            if P.same { same += 1 }
            XCTAssertEqual(P.tall, i >= 6 && i % 3 == 0)
            if P.tall {
                tall += 1
                XCTAssertTrue(P.a <= 6 && P.b <= 6); XCTAssertGreaterThan(P.shift, 0); XCTAssertLessThanOrEqual(P.height, 6)
            } else { XCTAssertLessThanOrEqual(P.b + max(0, P.shift), 11); XCTAssertGreaterThanOrEqual(P.shift, -2) }
        } }
        XCTAssertGreaterThan(same, 150); XCTAssertGreaterThan(tall, 300)
        let c = checks(LengthK.spec).map(LengthK.Parts.init)
        XCTAssertGreaterThan(c[0].a, c[0].b); XCTAssertLessThan(c[1].a, c[1].b); XCTAssertTrue(c[2].same)
        XCTAssertTrue(c[3].tall); XCTAssertEqual(c[3].extra, 1)
    }

    // MARK: Heavier and lighter

    func testHeavier() {
        // a rock (8) on the left, a pillow (3)
        var l = LessonRun(Heavier.spec, numbers: Heavier.numbers(x: 0, y: 3))
        XCTAssertEqual(l.words.say, "Put them on.")
        XCTAssertEqual(move(&l, ["p": -1]), .notYet("Put it on a pan."))
        XCTAssertEqual(move(&l, ["p": -2]), .notYet("One thing on each pan."))
        XCTAssertEqual(move(&l, ["p": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "Watch the balance. Tap the heavier one.")
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("That side went up. It’s lighter."))
        XCTAssertEqual(move(&l, ["c": 2]), .notYet("One side went down."))
        XCTAssertEqual(move(&l, ["c": 0]), .moved(2))
        XCTAssertEqual(l.words.say, "The heavier side goes down.")
        XCTAssertEqual(Heavier.Parts(l.numbers).heavyLine, "The rock is heavier.")
        XCTAssertTrue(l.isLast)
    }

    func testLighterBothWaysAndLevel() {
        // the pillow (4 long, 3) and the rock (1 long, 8), both ways, asked lighter
        var l = LessonRun(Heavier.spec, numbers: Heavier.numbers(x: 3, y: 0, lighter: true, both: true))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(move(&l, ["p": 1]), .moved(1))
        XCTAssertEqual(l.words.say, "Watch the balance. Tap the lighter one.")
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("That side went down. It’s heavier."))
        XCTAssertEqual(move(&l, ["c": 0]), .moved(2))
        XCTAssertEqual(l.words.say, "Tap the longer one.")
        XCTAssertEqual(move(&l, ["g": 1]), .notYet("The rock is only 1 cube. The pillow is 4."))
        XCTAssertEqual(move(&l, ["g": 0]), .moved(3))
        XCTAssertEqual(l.words.say, "Longer isn’t always heavier.")
        let P = Heavier.Parts(l.numbers)
        XCTAssertEqual(P.heavyLine, "The pillow is lighter.")
        XCTAssertEqual(P.longLine, "The pillow is longer.")
        // two of the same: level
        var s = LessonRun(Heavier.spec, numbers: Heavier.numbers(x: 5, y: 5))
        XCTAssertEqual(move(&s, ["p": 1]), .moved(1))
        XCTAssertEqual(move(&s, ["c": 0]), .notYet("Look again: it stayed level."))
        XCTAssertEqual(move(&s, ["c": 2]), .moved(2))
        XCTAssertEqual(s.words.say, "The same weight: the balance stays level.")
        XCTAssertEqual(Heavier.Parts(s.numbers).heavyLine, "The books weigh the same.")
    }

    func testHeavierGenerator() {
        each(Heavier.spec, 0) { x in
            let P = Heavier.Parts(x)
            XCTAssertFalse(P.level); XCTAssertFalse(P.lighter); XCTAssertFalse(P.both)
            XCTAssertGreaterThanOrEqual(abs(P.T[0].weight - P.T[1].weight), 5)
        }
        each(Heavier.spec, 3) { x in let P = Heavier.Parts(x); XCTAssertTrue(P.both); XCTAssertNotEqual(P.T[0].len, P.T[1].len) }
        each(Heavier.spec, 4) { x in let P = Heavier.Parts(x); XCTAssertFalse(P.both); XCTAssertFalse(P.level) }
        var level = 0, lighter = 0
        each(Heavier.spec, 6, 600) { x in let P = Heavier.Parts(x); if P.level { level += 1 }; if P.lighter { lighter += 1 } }
        XCTAssertGreaterThan(level, 40); XCTAssertGreaterThan(lighter, 120)
        // every thing lies flat in a pan (4 blocks at most)
        XCTAssertTrue(Heavier.things.allSatisfy { (1...4).contains($0.len) })
        let c = checks(Heavier.spec).map(Heavier.Parts.init)
        XCTAssertTrue(c[0].lighter)
        XCTAssertLessThan(c[1].T[c[1].longer].weight, c[1].T[1 - c[1].longer].weight)
        XCTAssertTrue(c[2].both)
    }

    // MARK: Sort and count

    func testSort() {
        // the How to: 5 buttons and 3 leaves
        var l = LessonRun(SortK.spec, numbers: SortK.numbers(by: 0, counts: [5, 3]))
        let P = SortK.Parts(l.numbers)
        XCTAssertEqual(P.kinds.map(\.one), ["button", "leaf"])
        // the circled one's kind first: (theme + 5) % 2 = 1, the leaves
        XCTAssertEqual(P.order, [1, 0])
        XCTAssertEqual(l.words.say, "Tap each leaf.")
        XCTAssertEqual(move(&l, ["s0": -1]), .notYet("That’s a button. It is round with 4 little holes."))
        XCTAssertEqual(move(&l, ["s0": 3]), .moved(1))
        XCTAssertEqual(l.words.say, "Tap each button.")
        XCTAssertEqual(move(&l, ["s1": -2]), .notYet("That’s a leaf. It has a pointed tip and a line down the middle."))
        XCTAssertEqual(move(&l, ["s1": 5]), .moved(2))
        XCTAssertEqual(l.words.say, "Tap the row with the most.")
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("That group has the fewest. Which group has the most?"))
        XCTAssertEqual(move(&l, ["c": 0]), .moved(3))
        XCTAssertEqual(l.words.say, "In order: most at the top. Rows from one line: the longest row has the most.")
        XCTAssertEqual(P.record, "The buttons have the most.")
    }

    func testSortFewestAndMiddle() {
        var l = LessonRun(SortK.spec, numbers: SortK.numbers(by: 1, counts: [2, 7, 4], theme: 1, ask: 1))
        let P = SortK.Parts(l.numbers)
        XCTAssertEqual(P.kinds.map(\.many), ["squares", "triangles", "circles"])
        XCTAssertEqual(P.order, [0, 1, 2])
        XCTAssertEqual(P.rank, [1, 2, 0])
        for j in 0..<3 { XCTAssertEqual(move(&l, ["s\(j)": Double(P.counts[P.order[j]])]), .moved(j + 1)) }
        XCTAssertEqual(l.words.say, "Tap the row with the fewest.")
        XCTAssertEqual(move(&l, ["c": 2]), .notYet("That group is in the middle. The fewest is the shortest row."))
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("That group has the most. Which group has the fewest?"))
        XCTAssertEqual(move(&l, ["c": 0]), .moved(4))
        XCTAssertEqual(P.record, "The squares have the fewest.")
        XCTAssertEqual(l.words.say, "In order: most at the top. Rows from one line: the shortest row has the fewest.")
    }

    func testSortGenerator() {
        each(SortK.spec, 0) { x in
            let P = SortK.Parts(x)
            XCTAssertEqual(P.K, 2); XCTAssertLessThanOrEqual(P.total, 8); XCTAssertTrue(P.counts.allSatisfy { (1...6).contains($0) })
            XCTAssertEqual(Set(P.counts).count, 2); XCTAssertEqual(P.ask, 0)
            XCTAssertEqual(Set(P.cells).count, P.total); XCTAssertTrue(P.cells.allSatisfy { (0..<18).contains($0) })
        }
        each(SortK.spec, 7) { x in
            let P = SortK.Parts(x)
            XCTAssertEqual(P.K, 3); XCTAssertLessThanOrEqual(P.total, 15); XCTAssertEqual(Set(P.counts).count, 3); XCTAssertEqual(P.ask, 1)
            XCTAssertEqual(P.kindOf[P.circled], P.first)
        }
        let c = checks(SortK.spec).map(SortK.Parts.init)
        XCTAssertEqual(c.map(\.ask), [1, 0, 0, 1]); XCTAssertEqual(c[2].by, 1)
    }
}
