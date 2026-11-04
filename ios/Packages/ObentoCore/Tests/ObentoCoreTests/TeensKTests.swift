import XCTest
@testable import ObentoCore

/// Kindergarten, chapter 5: Teens and tens (design/gradeK.md, the preview design/prototype/gradeK-ch5.html).
final class TeensKTests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(17 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(0)[4]
        XCTAssertEqual(ch.title, "Teens and tens")
        XCTAssertEqual(ch.colour, "decimals")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
        XCTAssertTrue(Curriculum.voiced("gk-count100"))
    }

    func testNumerals() {
        // one stroke a digit, two for 4 and 5; the teen's strokes the 1's first, the next digit 6 squares on
        XCTAssertEqual(Numerals.strokes(7).count, 1)
        XCTAssertEqual(Numerals.strokes(4).count, 2)
        XCTAssertEqual(Numerals.strokes(15).count, 3)
        let one = Numerals.strokes(1)[0]
        XCTAssertEqual(one.first!.x, 1.8, accuracy: 0.01); XCTAssertEqual(one.first!.y, 2.0, accuracy: 0.01)
        XCTAssertEqual(one.last!.x, 3.2, accuracy: 0.01); XCTAssertEqual(one.last!.y, 9.4, accuracy: 0.01)
        XCTAssertGreaterThanOrEqual(one.count, 41)
        let six = Numerals.strokes(16, x: 35, y: 5)[1]
        XCTAssertEqual(six.first!.x, 35 + 6 + 4.8, accuracy: 0.01)
        // evenly spread: no gap longer than a square
        for d in 0...9 { for s in Numerals.strokes(d) { for k in 1..<s.count { XCTAssertLessThan(hypot(s[k].x - s[k - 1].x, s[k].y - s[k - 1].y), 0.6) } } }
        // 0 closes on itself
        let z = Numerals.strokes(0)[0]
        XCTAssertEqual(z.first!.x, z.last!.x, accuracy: 0.01); XCTAssertEqual(z.first!.y, z.last!.y, accuracy: 0.01)
    }

    // MARK: Count to 20

    func testCount20Rows() {
        var l = LessonRun(Count20K.spec, numbers: Count20K.numbers(n: 14))
        XCTAssertEqual(l.words.say, "Count the top row.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["c": -2]), .notYet("Count the top row first."))
        XCTAssertEqual(move(&l, ["c": -1]), .notYet("You counted that one."))
        XCTAssertEqual(move(&l, ["c": 10]), .moved(1))
        XCTAssertEqual(l.words.say, "Keep counting.")
        XCTAssertEqual(move(&l, ["d": -3]), .notYet("That row is counted. Keep going on the bottom row."))
        XCTAssertEqual(move(&l, ["d": 14]), .moved(2))
        XCTAssertEqual(l.words.say, "Write how many.")
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("That’s only the bottom row. Don’t start again at 1. Say 10, then keep going: 11, 12..."))
        XCTAssertEqual(move(&l, ["x": 13]), .notYet("One short. Make sure you count every dot in the bottom row."))
        XCTAssertEqual(move(&l, ["x": 15]), .notYet("One too many. The first dot in the bottom row is 11."))
        XCTAssertEqual(move(&l, ["x": 10]), .notYet("10 is the top row. Keep counting the bottom row."))
        XCTAssertEqual(move(&l, ["x": 18]), .notYet("That’s 18. Say 10, then count on the bottom row."))
        XCTAssertEqual(move(&l, ["x": 14]), .moved(3))
        XCTAssertEqual(l.words.say, "A full row is 10, so keep counting on from 10.")
    }

    func testCount20Ring() {
        var l = LessonRun(Count20K.spec, numbers: Count20K.numbers(n: 17, ring: true, off: 5))
        XCTAssertEqual(l.words.say, "Count them all.")
        let P = Count20K.Parts(l.numbers)
        // spread round the ring, no two in one place
        XCTAssertEqual(Set((0..<17).map { "\(P.place($0))" }).count, 17)
        XCTAssertEqual(move(&l, ["c": 17]), .moved(1))
        XCTAssertEqual(move(&l, ["x": 16]), .notYet("One short. Count every dot once, all the way round."))
        XCTAssertEqual(move(&l, ["x": 18]), .notYet("One too many. Stop at the dot you began with."))
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("The last number was 17."))
        XCTAssertEqual(move(&l, ["x": 17]), .moved(2))
        XCTAssertEqual(l.words.say, "Each dot gets one number, so the last number says how many.")
    }

    func testCount20Generator() {
        each(Count20K.spec, 0) { x in let P = Count20K.Parts(x); XCTAssertTrue((11...15).contains(P.n)); XCTAssertFalse(P.ring) }
        each(Count20K.spec, 4) { x in XCTAssertTrue((11...20).contains(Count20K.Parts(x).n)); XCTAssertFalse(Count20K.Parts(x).ring) }
        each(Count20K.spec, 9) { x in XCTAssertTrue(Count20K.Parts(x).ring) }
        let c = checks(Count20K.spec).map(Count20K.Parts.init)
        XCTAssertLessThanOrEqual(c[0].n, 14); XCTAssertGreaterThanOrEqual(c[1].n, 17); XCTAssertEqual(c[2].n, 20); XCTAssertTrue(c[3].ring)
    }

    // MARK: Write numbers

    func testWrite() {
        var l = LessonRun(WriteK.spec, numbers: WriteK.numbers(n: 6))
        XCTAssertEqual(l.words.say, "Count the dots.")
        XCTAssertEqual(move(&l, ["c": -1]), .notYet("You counted that one."))
        XCTAssertEqual(move(&l, ["c": 6]), .moved(1))
        XCTAssertEqual(l.words.say, "Tap the 6.")
        XCTAssertEqual(WriteK.Parts(l.numbers).choices, [6, 9, 5])
        XCTAssertEqual(move(&l, ["p": 9]), .notYet("That’s 9, not 6. 9 has its loop at the top. 6 has its loop at the bottom."))
        XCTAssertEqual(move(&l, ["p": 5]), .notYet("That’s 5, not 6. 5 has a flat hat on top and a round belly. 6 has its loop at the bottom."))
        XCTAssertEqual(move(&l, ["p": 6]), .moved(2))
        XCTAssertEqual(l.words.say, "Trace it.")
        XCTAssertEqual(move(&l, ["t": -1]), .notYet("Start at the dot."))
        XCTAssertEqual(move(&l, ["t": -2]), .notYet("Go on from where you stopped."))
        XCTAssertEqual(move(&l, ["t": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "The number says how many dots.")
    }

    func testWriteTeensAndZero() {
        let P = WriteK.Parts(WriteK.numbers(n: 16))
        XCTAssertTrue(P.choices.contains(61) && P.choices.contains(15) && P.choices.contains(16))
        XCTAssertEqual(P.picked(61), "That’s 61. 16 starts with 1: 1 ten and 6 ones.")
        XCTAssertEqual(P.picked(15), "That’s 15, one less than 16. You counted 16 dots.")
        XCTAssertEqual(WriteK.Parts(WriteK.numbers(n: 20)).picked(10), "That’s 10: 1 ten. 20 is 2 tens.")
        XCTAssertEqual(P.strokes, 2)
        var l = LessonRun(WriteK.spec, numbers: WriteK.numbers(n: 0))
        XCTAssertEqual(move(&l, ["c": 0]), .moved(1))
        XCTAssertEqual(l.words.say, "None. None is 0. Tap the 0.")
        XCTAssertEqual(WriteK.Parts(l.numbers).choices, [0, 1, 8])
    }

    func testWriteGenerator() {
        each(WriteK.spec, 1) { x in XCTAssertTrue((1...5).contains(WriteK.Parts(x).n)) }
        each(WriteK.spec, 4) { x in XCTAssertTrue((1...10).contains(WriteK.Parts(x).n)) }
        var zero = false
        each(WriteK.spec, 6) { x in if WriteK.Parts(x).n == 0 { zero = true } }
        XCTAssertTrue(zero)
        each(WriteK.spec, 9) { x in let n = WriteK.Parts(x).n; XCTAssertTrue((1...20).contains(n)); XCTAssertEqual(Set(WriteK.Parts(x).choices).count, 3) }
        let c = checks(WriteK.spec).map(WriteK.Parts.init)
        XCTAssertTrue([2, 5, 6, 9].contains(c[0].n)); XCTAssertTrue((12...19).contains(c[1].n)); XCTAssertTrue([10, 20].contains(c[3].n))
    }

    // MARK: Teen numbers

    func testTeensCount() {
        var l = LessonRun(TeenNumbersK.spec, numbers: TeenNumbersK.numbers(ones: 6))
        XCTAssertEqual(l.words.say, "Count these.")
        XCTAssertEqual(move(&l, ["c": -1]), .notYet("That’s the full frame. Count the dots in the second frame."))
        XCTAssertEqual(move(&l, ["c": -2]), .notYet("You counted that one."))
        XCTAssertEqual(move(&l, ["c": 6]), .moved(1))
        XCTAssertEqual(l.words.say, "Watch the 0. Write the number.")
        XCTAssertEqual(move(&l, ["x": 6]), .notYet("Don’t forget the full frame. Start at 10 and count on 6."))
        XCTAssertEqual(move(&l, ["x": 15]), .notYet("Start at 10, then say 11 for the first extra dot."))
        XCTAssertEqual(move(&l, ["x": 17]), .notYet("One too many. Start at 10 and count on only 6."))
        XCTAssertEqual(move(&l, ["x": 12]), .notYet("That’s 12. Start at 10 and count on 6."))
        XCTAssertEqual(move(&l, ["x": 16]), .moved(2))
        XCTAssertEqual(l.words.say, "A teen number is a ten and some ones.")
    }

    func testTeensMake() {
        var l = LessonRun(TeenNumbersK.spec, numbers: TeenNumbersK.numbers(ones: 6, make: true))
        XCTAssertEqual(l.words.say, "Make 16.")
        XCTAssertEqual(move(&l, ["m": 17]), .notYet("That’s 17. Make 16."))
        XCTAssertEqual(move(&l, ["m": 16]), .moved(1))
        XCTAssertEqual(l.words.say, "Write the ones.")
        XCTAssertEqual(move(&l, ["x": 10]), .notYet("10 is the full frame. Count the dots in the second frame."))
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("One short. Count every dot in the second frame."))
        XCTAssertEqual(move(&l, ["x": 6]), .moved(2))
        // 20 = 10 + 10
        let P = TeenNumbersK.Parts(TeenNumbersK.numbers(ones: 10, make: true))
        XCTAssertEqual(P.n, 20); XCTAssertEqual(P.answer, 10)
    }

    func testTeensGenerator() {
        each(TeenNumbersK.spec, 1) { x in let P = TeenNumbersK.Parts(x); XCTAssertFalse(P.make); XCTAssertTrue((1...5).contains(P.ones)) }
        each(TeenNumbersK.spec, 4) { x in let P = TeenNumbersK.Parts(x); XCTAssertFalse(P.make); XCTAssertTrue((1...9).contains(P.ones)) }
        var twenty = false
        each(TeenNumbersK.spec, 5) { x in let P = TeenNumbersK.Parts(x); XCTAssertTrue(P.make); if P.ones == 10 { twenty = true } }
        XCTAssertTrue(twenty)
        let c = checks(TeenNumbersK.spec).map(TeenNumbersK.Parts.init)
        XCTAssertLessThanOrEqual(c[0].ones, 3); XCTAssertGreaterThanOrEqual(c[1].ones, 6); XCTAssertFalse(c[1].make)
        XCTAssertGreaterThanOrEqual(c[2].ones, 6); XCTAssertTrue(c[2].make)
    }

    // MARK: Count by tens

    func testTens() {
        var l = LessonRun(TensK.spec, numbers: TensK.numbers(rows: 4))
        XCTAssertEqual(l.words.say, "Count by tens.")
        XCTAssertEqual(move(&l, ["c": -1]), .notYet("You counted that ten."))
        XCTAssertEqual(move(&l, ["c": 4]), .moved(1))
        XCTAssertEqual(l.words.say, "Write how many.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("That’s the number of frames. Each frame is 10, so count 10, 20, 30..."))
        XCTAssertEqual(move(&l, ["x": 30]), .notYet("One ten short. Say one ten for every frame."))
        XCTAssertEqual(move(&l, ["x": 50]), .notYet("One ten too many. There are only 4 frames."))
        XCTAssertEqual(move(&l, ["x": 31]), .notYet("Count by tens all the way. After 30 comes 40."))
        XCTAssertEqual(move(&l, ["x": 400]), .notYet("That’s 400. Say one ten for each frame: 10, 20, 30..."))
        XCTAssertEqual(move(&l, ["x": 40]), .moved(2))
        XCTAssertEqual(l.words.say, "Each frame is 10, so count by tens.")
    }

    func testTensGenerator() {
        each(TensK.spec, 0) { x in XCTAssertTrue((2...5).contains(TensK.Parts(x).rows)) }
        each(TensK.spec, 7) { x in XCTAssertTrue((2...10).contains(TensK.Parts(x).rows)) }
        let c = checks(TensK.spec).map(TensK.Parts.init)
        XCTAssertLessThanOrEqual(c[0].rows, 5); XCTAssertTrue((6...9).contains(c[1].rows)); XCTAssertEqual(c[3].rows, 10)
    }

    // MARK: Count to 100

    func testCountOn() {
        var l = LessonRun(CountTo100.spec, numbers: CountTo100.numbers(on: 37, more: 5))
        XCTAssertEqual(l.words.say, "Count to 42.")
        XCTAssertEqual(move(&l, ["k": -41]), .notYet("41 comes next. It starts the next row."))
        XCTAssertEqual(move(&l, ["k": -38]), .notYet("38 comes next. It goes right after 37."))
        XCTAssertEqual(move(&l, ["k": 5]), .moved(1))
        XCTAssertEqual(l.words.say, "Each row is ten numbers: 40 ends one row and 41 starts the next.")
        XCTAssertEqual(CountTo100.Parts(l.numbers).top, 2)
    }

    func testWhich() {
        var l = LessonRun(CountTo100.spec, numbers: CountTo100.numbers(which: 40, choices: [50, 40, 30]))
        XCTAssertEqual(l.words.say, "Tap the missing number.")
        XCTAssertEqual(move(&l, ["x": 30]), .notYet("30 is up here. After 39 comes 40."))
        XCTAssertEqual(move(&l, ["x": 50]), .notYet("50 is down here. After 39 comes 40."))
        XCTAssertEqual(move(&l, ["x": 40]), .moved(1))
        XCTAssertEqual(l.words.say, "Each row is ten numbers: 40 ends one row and 41 starts the next.")
        XCTAssertEqual(CountTo100.Parts(CountTo100.numbers(which: 5, choices: [5, 15, 25])).top, 0)
        XCTAssertEqual(CountTo100.Parts(CountTo100.numbers(which: 95, choices: [95, 85, 75])).top, 7)
    }

    func testCount100Generator() {
        each(CountTo100.spec, 1) { x in let P = CountTo100.Parts(x); XCTAssertTrue(P.on); XCTAssertEqual(CountTo100.row(P.s + 1), CountTo100.row(P.e)); XCTAssertLessThanOrEqual(P.e, 30) }
        each(CountTo100.spec, 4) { x in let P = CountTo100.Parts(x); XCTAssertTrue(P.on); XCTAssertGreaterThan(CountTo100.row(P.e), CountTo100.row(P.s)) }
        var hundred = false
        each(CountTo100.spec, 7) { x in let P = CountTo100.Parts(x); XCTAssertTrue(P.on); XCTAssertLessThanOrEqual(P.e, 100); XCTAssertTrue((3...7).contains(P.m)); if P.e == 100 { hundred = true } }
        XCTAssertTrue(hundred)
        each(CountTo100.spec, 8) { x in
            let P = CountTo100.Parts(x); XCTAssertFalse(P.on)
            XCTAssertEqual(Set(P.choices), Set(CountTo100.choices(P.n))); XCTAssertTrue(P.choices.allSatisfy { (1...100).contains($0) })
            // the choices sit in the three rows in play
            XCTAssertTrue(P.choices.allSatisfy { (P.top...(P.top + 2)).contains(CountTo100.row($0)) })
        }
        let c = checks(CountTo100.spec).map(CountTo100.Parts.init)
        XCTAssertTrue(c[0].on); XCTAssertFalse(c[1].on); XCTAssertEqual(c[1].n % 10, 0); XCTAssertEqual(c[2].e, 100); XCTAssertGreaterThanOrEqual(c[3].n, 50)
    }
}
