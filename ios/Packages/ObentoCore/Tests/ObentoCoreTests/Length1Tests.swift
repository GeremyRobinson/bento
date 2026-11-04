import XCTest
@testable import ObentoCore

/// 1st grade, chapter 5: Length, time and graphs (design/grade1.md, the preview design/prototype/grade1-ch5.html).
final class Length1Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(53 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(1)[4]
        XCTAssertEqual(ch.title, "Length, time and graphs")
        XCTAssertEqual(ch.colour, "measurement")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertTrue(Curriculum.voiced(l.id)) }
        XCTAssertEqual(Spoken.text("8:30 is half past 8."), "half past 8 is half past 8.")
        XCTAssertEqual(Spoken.text("Write 3:00."), "Write 3 o'clock.")
    }

    func testOrder() {
        // pencil 7, crayon 4, ribbon 9
        var l = LessonRun(Order1.spec, numbers: Order1.numbers([0, 1, 2], [7, 4, 9]))
        XCTAssertEqual(l.steps.count, 3)
        XCTAssertEqual(l.words.say, "Slide each one's end to the dashed line.")
        XCTAssertEqual(move(&l, ["l": -1]), .notYet("Put its end on the line."))
        XCTAssertEqual(move(&l, ["l": 3]), .moved(1))
        XCTAssertEqual(l.words.say, "Now the far ends tell. Drag them into order, longest on top.")
        XCTAssertEqual(move(&l, ["o": 21]), .notYet("The ribbon goes past the crayon's end, so it's longer."))
        XCTAssertEqual(move(&l, ["o": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Line up the ends; the one that goes farthest is longest.")
        XCTAssertEqual(Order1.Parts(Order1.numbers([0, 1, 2], [7, 4, 9])).record, "ribbon, pencil, crayon")

        var b = LessonRun(Order1.spec, numbers: Order1.between([8, 9], [5, 3]))
        XCTAssertEqual(b.steps.count, 4)
        XCTAssertEqual(b.words.say, "These two are stuck. Lay the string along the rug.")
        XCTAssertEqual(move(&b, ["a": -1]), .notYet("Put the string's end at the rug's end."))
        XCTAssertEqual(move(&b, ["a": 1]), .moved(1))
        XCTAssertEqual(b.words.say, "Now lay it along the desk.")
        XCTAssertEqual(move(&b, ["b": 1]), .moved(2))
        XCTAssertEqual(move(&b, ["c": 1]), .notYet("The desk stops before the mark, so the rug is longer."))
        XCTAssertEqual(move(&b, ["c": 0]), .moved(3))
        XCTAssertEqual(b.words.say, "The string was as long as the rug, and the desk is shorter.")
        XCTAssertEqual(Order1.Parts(Order1.between([8, 9], [3, 5])).tapMiss, "The desk goes past the mark, so it's longer.")

        for i in 0..<12 {
            each(Order1.spec, i) { x in
                let P = Order1.Parts(x)
                XCTAssertEqual(P.between, i >= 6 && (i - 6) % 3 == 0)
                if P.between { XCTAssertNotEqual(P.a, P.b); XCTAssertTrue((3...6).contains(P.a)); XCTAssertNotEqual(P.names[0], P.names[1]); return }
                XCTAssertEqual(Set(P.lens).count, 3); XCTAssertEqual(Set(P.names).count, 3)
                XCTAssertFalse(P.lens[0] > P.lens[1] && P.lens[1] > P.lens[2])
                for k in 0..<3 { XCTAssertLessThanOrEqual(P.lens[k] + P.shifts[k], 13) }
                if i < 3 { for p in [(0, 1), (0, 2), (1, 2)] { XCTAssertGreaterThanOrEqual(abs(P.lens[p.0] - P.lens[p.1]), 2) } }
            }
        }
        let c = checks(Order1.spec).map(Order1.Parts.init)
        XCTAssertTrue(c[2].between); XCTAssertFalse(c[3].between)
    }

    func testMeasure() {
        var l = LessonRun(Cubes1.spec, numbers: Cubes1.numbers(0, 3, a: 7, b: 4))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Lay cubes under the pencil.")
        XCTAssertEqual(move(&l, ["f": -1]), .notYet("Start at the dashed line."))
        XCTAssertEqual(move(&l, ["f": -2]), .notYet("That's past the end of the pencil."))
        XCTAssertEqual(move(&l, ["f": 7]), .moved(1))
        XCTAssertEqual(l.words.say, "Now lay cubes under the straw.")
        XCTAssertEqual(move(&l, ["g": 4]), .moved(2))
        XCTAssertEqual(l.words.say, "Tap the cubes that stick out past the straw.")
        XCTAssertEqual(move(&l, ["m": -1]), .notYet("Tap the cubes past the straw's end."))
        XCTAssertEqual(move(&l, ["m": 3]), .moved(3))
        XCTAssertEqual(move(&l, ["x": 11]), .notYet("That's both together. Find the extra cubes the pencil has."))
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("That's how long the pencil is. How many cubes more than the straw?"))
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("Count the cubes past the straw's end."))
        XCTAssertEqual(move(&l, ["x": 3]), .moved(4))
        XCTAssertEqual(l.words.say, "Cubes end to end, no gaps: the count is the length.")
        for i in 0..<12 {
            each(Cubes1.spec, i) { x in
                let P = Cubes1.Parts(x)
                XCTAssertNotEqual(P.a, P.b); XCTAssertNotEqual(P.names[0], P.names[1])
                XCTAssertLessThanOrEqual(P.mx, i < 3 ? 8 : 12)
            }
        }
        XCTAssertEqual(Cubes1.Parts(checks(Cubes1.spec)[2]).diff, 1)
    }

    func testTime() {
        var l = LessonRun(Time1.spec, numbers: Time1.numbers(hour: 8, minute: 30))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Tap the number the short hand just passed.")
        XCTAssertEqual(move(&l, ["h": 9]), .notYet("The short hand hasn't reached 9 yet. It's still 8."))
        XCTAssertEqual(move(&l, ["h": 6]), .notYet("That's the long hand. The short hand tells the hour."))
        XCTAssertEqual(move(&l, ["h": 2]), .notYet("Find the short hand. Which number did it just pass?"))
        XCTAssertEqual(move(&l, ["h": 8]), .moved(1))
        XCTAssertEqual(l.words.say, "Trace from 12 round to the long hand.")
        XCTAssertEqual(move(&l, ["m": -1]), .notYet("Start at 12."))
        XCTAssertEqual(move(&l, ["m": -2]), .notYet("Clocks go this way."))
        XCTAssertEqual(move(&l, ["m": -3]), .notYet("That's past the long hand."))
        XCTAssertEqual(move(&l, ["m": -4]), .notYet("Keep going to the long hand."))
        XCTAssertEqual(move(&l, ["m": 30]), .moved(2))
        XCTAssertEqual(l.words.say, "Write the time.")
        XCTAssertEqual(move(&l, ["x": 6]), .notYet("The short hand tells the hour. The long hand tells the minutes."))
        XCTAssertEqual(move(&l, ["x": 9]), .notYet("The short hand hasn't reached 9 yet. It's still 8."))
        XCTAssertEqual(move(&l, ["x": 8]), .moved(3))
        XCTAssertEqual(move(&l, ["y": 6]), .notYet("The long hand points at 6, but that means 30 minutes."))
        XCTAssertEqual(move(&l, ["y": 60]), .notYet("A whole hour is 60 minutes, but the long hand has only gone halfway around: 30 minutes."))
        XCTAssertEqual(move(&l, ["y": 8]), .notYet("That's the short hand. The long hand tells the minutes."))
        XCTAssertEqual(move(&l, ["y": 30]), .moved(4))
        XCTAssertEqual(l.words.say, "Half way round is half the hour: 30 minutes.")
        var o = LessonRun(Time1.spec, numbers: Time1.numbers(hour: 3, minute: 0))
        XCTAssertEqual(o.words.say, "Tap the number the short hand points at.")
        XCTAssertEqual(move(&o, ["h": 12]), .notYet("That's the long hand. The short hand tells the hour."))
        XCTAssertEqual(move(&o, ["h": 3]), .moved(1))
        XCTAssertEqual(o.words.say, "Tap where the long hand points.")
        XCTAssertEqual(move(&o, ["m": 0]), .moved(2))
        XCTAssertEqual(move(&o, ["x": 3]), .moved(3))
        XCTAssertEqual(move(&o, ["y": 12]), .notYet("The long hand points at 12, but that means 0 minutes."))
        XCTAssertEqual(move(&o, ["y": 0]), .moved(4))
        XCTAssertEqual(o.words.say, "Long hand on 12: a new hour starts.")
        XCTAssertEqual(Time1.Parts(Time1.numbers(hour: 3, minute: 0)).said, "3 o'clock")
        for i in 0..<12 { each(Time1.spec, i) { x in let P = Time1.Parts(x); if i == 1 { XCTAssertFalse(P.half) }; XCTAssertTrue((1...12).contains(P.hour)) } }
    }

    func testPicGraph() {
        // fruit: apples 8, bananas 3, grapes 5; read apples, against bananas
        var l = LessonRun(PicGraph1.spec, numbers: PicGraph1.numbers(theme: 0, counts: [8, 3, 5], ask: 0, x: 0, y: 1, sort: true))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Tap each picture to put it in its row.")
        XCTAssertEqual(move(&l, ["p": 16]), .moved(1))
        XCTAssertEqual(l.words.say, "How many apples? Tap each picture to count it.")
        XCTAssertEqual(move(&l, ["k": 12]), .notYet("That's the Grapes row. Find the Apples row."))
        XCTAssertEqual(move(&l, ["k": 8]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("That's the Bananas row. Find the Apples row."))
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("Touch each picture once and say its number. Each picture is one apple."))
        XCTAssertEqual(move(&l, ["x": 8]), .moved(3))
        XCTAssertEqual(l.words.say, "Longer or shorter than the Bananas row?")
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("The pictures line up. Look where each row ends: the Apples row goes past the end of the Bananas row."))
        XCTAssertEqual(move(&l, ["c": 0]), .moved(4))
        XCTAssertEqual(l.words.say, "One picture for each, so the longest row has the most.")

        var m = LessonRun(PicGraph1.spec, numbers: PicGraph1.numbers(theme: 1, counts: [2, 7, 4], ask: 1, x: 0, y: 1, few: true))
        XCTAssertEqual(m.words.say, "Which row has the fewest?")
        XCTAssertEqual(move(&m, ["c": 1]), .notYet("That row is the longest. The fewest is the shortest row."))
        XCTAssertEqual(move(&m, ["c": 2]), .notYet("Look at where each row ends. The fewest is the shortest row."))
        XCTAssertEqual(move(&m, ["c": 0]), .moved(1))
        XCTAssertEqual(PicGraph1.Parts(m.numbers).rec2, "Dogs has the fewest.")

        var d = LessonRun(PicGraph1.spec, numbers: PicGraph1.numbers(theme: 0, counts: [8, 3, 5], ask: 2, x: 0, y: 1))
        XCTAssertEqual(d.words.say, "How many more apples than bananas? Tap the Apples pictures past the Bananas row's end.")
        XCTAssertEqual(move(&d, ["m": -1]), .notYet("The Bananas row has that one too. Tap past its end."))
        XCTAssertEqual(move(&d, ["m": 5]), .moved(1))
        XCTAssertEqual(move(&d, ["x": 11]), .notYet("How many more means the difference. Take away."))
        XCTAssertEqual(move(&d, ["x": 5]), .moved(2))

        var t = LessonRun(PicGraph1.spec, numbers: PicGraph1.numbers(theme: 2, counts: [6, 3, 5], ask: 3, x: 0, y: 1))
        XCTAssertEqual(t.words.say, "How many sunny days and rainy days together? Slide one row onto the end of the other.")
        XCTAssertEqual(move(&t, ["j": -1]), .notYet("Use the Sunny and Rainy rows."))
        XCTAssertEqual(move(&t, ["j": -2]), .notYet("Slide it to the end of the other row."))
        XCTAssertEqual(move(&t, ["j": 1]), .moved(1))
        XCTAssertEqual(move(&t, ["x": 3]), .notYet("Together means add."))
        XCTAssertEqual(move(&t, ["x": 9]), .moved(2))

        for i in 0..<12 {
            each(PicGraph1.spec, i) { x in
                let P = PicGraph1.Parts(x)
                XCTAssertEqual(Set(P.c).count, 3); XCTAssertNotEqual(P.x, P.y)
                XCTAssertEqual(P.sort, i < 3); XCTAssertEqual(P.ask, i < 3 ? i % 2 : i % 4)
                if P.ask == 2 { XCTAssertGreaterThan(P.c[P.x], P.c[P.y]) }
            }
        }
        XCTAssertEqual(Set(Len1.pile(20, seed: 5)), Set(0..<20))
    }

    func testTally() {
        // apples 12, bananas 4, grapes 9
        var l = LessonRun(Tally1.spec, numbers: Tally1.numbers(theme: 0, counts: [12, 4, 9], ask: 0, x: 0, y: 1, make: true))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Tap each one to make its mark.")
        XCTAssertEqual(move(&l, ["mk": 25]), .moved(1))
        XCTAssertEqual(l.words.say, "How many apples? Tap each bundle, then each mark.")
        XCTAssertEqual(move(&l, ["k": -1]), .notYet("Count the bundles first, by 5s."))
        XCTAssertEqual(move(&l, ["k": 11]), .notYet("That's the Bananas row. Find the Apples row."))
        XCTAssertEqual(move(&l, ["k": 12]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("That's the Bananas row. Find the Apples row."))
        XCTAssertEqual(move(&l, ["x": 4 + 0]), .notYet("That's the Bananas row. Find the Apples row."))
        XCTAssertEqual(move(&l, ["x": 14]), .notYet("The line across is the 5th mark of its bundle, not an extra one."))
        XCTAssertEqual(move(&l, ["x": 11]), .notYet("Count the bundles by 5s first: 5, 10. Then count on the single marks."))
        XCTAssertEqual(move(&l, ["x": 12]), .moved(3))
        XCTAssertEqual(l.words.say, "Every fifth mark goes across, so count by 5s.")
        XCTAssertEqual(Tally1.Parts(Tally1.numbers(theme: 0, counts: [7, 4, 9], ask: 0, x: 0, y: 1)).slips.first { $0.0 == 4 }?.1, "That's the Bananas row. Find the Apples row.")

        var a = LessonRun(Tally1.spec, numbers: Tally1.numbers(theme: 1, counts: [7, 4, 9], ask: 2, x: 0, y: 1))
        XCTAssertEqual(a.words.say, "How many in all? Tap each row, top to bottom.")
        XCTAssertEqual(move(&a, ["t": -1]), .notYet("Tap the rows in turn, top to bottom."))
        XCTAssertEqual(move(&a, ["t": 3]), .moved(1))
        XCTAssertEqual(move(&a, ["x": 11]), .notYet("You left out the Fish row. Add all three."))
        XCTAssertEqual(move(&a, ["x": 20]), .moved(2))

        for i in 0..<12 {
            each(Tally1.spec, i) { x in
                let P = Tally1.Parts(x)
                XCTAssertEqual(Set(P.c).count, 3); XCTAssertEqual(P.make, i < 3)
                if i < 3 { XCTAssertEqual(P.ask, 0); XCTAssertGreaterThanOrEqual(P.n, 5); XCTAssertLessThanOrEqual(P.c.max()!, 9) }
                if P.ask == 1 { XCTAssertGreaterThan(P.c[P.x], P.c[P.y]) }
                if P.ask == 2 { XCTAssertLessThanOrEqual(P.sum, 20) }
            }
        }
    }
}
