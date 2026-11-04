import XCTest
@testable import ObentoCore

/// 4th grade, chapter 1: Big numbers (design/grade4.md, the preview design/prototype/grade4-ch1.html).
final class BigNumbersTests: XCTestCase {
    /// A hand move: its boxes set (as the move does), checked.
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func type(_ l: inout LessonRun, _ x: Int) -> LessonRun.Outcome {
        l.reset(); for ch in String(x) { l.type(String(ch)) }; return l.go()
    }
    /// Many problems from each place in a run.
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(17 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }

    // MARK: the chapter's words

    func testNamesAndCommas() {
        XCTAssertEqual(BigNumbers.commas(47382), "47,382")
        XCTAssertEqual(BigNumbers.commas(305280), "305,280")
        XCTAssertEqual(BigNumbers.commas(999), "999")
        XCTAssertEqual(BigNumbers.commas(1000), "1,000")
        XCTAssertEqual(BigNumbers.name(40605), "forty thousand, six hundred five")
        XCTAssertEqual(BigNumbers.name(305280), "three hundred five thousand, two hundred eighty")
        XCTAssertEqual(BigNumbers.name(921012), "nine hundred twenty-one thousand, twelve")
        XCTAssertEqual(BigNumbers.name(7000), "seven thousand")
        XCTAssertEqual(BigNumbers.name(15), "fifteen")
        XCTAssertEqual(BigNumbers.place(2, 1), "hundred"); XCTAssertEqual(BigNumbers.place(4, 3), "ten thousands")
        XCTAssertEqual(BigNumbers.digit(47382, 3), 7)
    }

    // MARK: grades on the map

    func testGrades() {
        XCTAssertEqual(Grades.all.filter(Grades.isLive), [4, 5, 6])
        // 5th grade exactly as it was: the same chapters, lessons, ids and tests
        let g5 = Curriculum.chapters(5)
        XCTAssertEqual(g5.map(\.key), ["whole", "decimals", "fractions", "measurement", "geometry"])
        XCTAssertEqual(g5.map(\.test), ["test-whole", "test-decimals", "test-fractions", "test-measurement", "test-geometry"])
        XCTAssertEqual(g5.flatMap(\.lessons).count, 21)
        XCTAssertEqual(g5[0].lessons.map(\.id), ["g5-mult2", "g5-divide", "g5-order"])
        XCTAssertTrue(g5.allSatisfy(Curriculum.built))
        XCTAssertEqual(Curriculum.gradeTest(5), "test-grade")
        // 4th grade: 8 chapters, 35 lessons, every one built
        let g4 = Curriculum.chapters(4)
        XCTAssertEqual(g4.count, 8)
        XCTAssertEqual(g4.flatMap(\.lessons).count, 35)
        XCTAssertEqual(g4[0].title, "Big numbers")
        XCTAssertEqual(g4[0].lessons.map(\.id), ["g4-tentimes", "g4-readwrite", "g4-compare", "g4-placevalue", "g4-addsub"])
        XCTAssertTrue(Curriculum.built(g4[0]))
        XCTAssertTrue(Curriculum.built(g4[1]))
        XCTAssertTrue(Curriculum.built(g4[2]))
        XCTAssertTrue(Curriculum.built(g4[3]))
        XCTAssertTrue(Curriculum.built(g4[4]))
        XCTAssertTrue(Curriculum.built(g4[5]))
        XCTAssertTrue(Curriculum.built(g4[6]))
        XCTAssertTrue(g4.allSatisfy(Curriculum.built))
        XCTAssertEqual(Curriculum.gradeTest(4), "test-grade-4")
        XCTAssertTrue(Curriculum.isGradeTest("test-grade") && Curriculum.isGradeTest("test-grade-4"))
        // no id is on two grades: each grade's progress is its own
        let ids4 = Set(g4.flatMap { $0.lessons.map(\.id) + [$0.test] } + [Curriculum.gradeTest(4)])
        let ids5 = Set(g5.flatMap { $0.lessons.map(\.id) + [$0.test] } + [Curriculum.gradeTest(5)])
        XCTAssertTrue(ids4.isDisjoint(with: ids5))
        XCTAssertEqual(Curriculum.grade(of: "g4-compare"), 4); XCTAssertEqual(Curriculum.grade(of: "add"), 5)
        XCTAssertEqual(Curriculum.grade(of: "test-g4-big"), 4); XCTAssertEqual(Curriculum.grade(of: "test-whole"), 5)
        XCTAssertNil(Curriculum.grade(of: "nope"))
        // every built lesson's spec is the app's
        for c in g4 + g5 { for l in c.lessons where Curriculum.built(l.id) { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name, l.id) } }
        XCTAssertTrue(Curriculum.chapters(3).isEmpty && !Grades.isLive(3))
    }

    // MARK: Tens, hundreds, thousands

    func testTensHundredsA() {
        // 340: how many tens? 3 hundreds open into 30 tens, and 4 more
        var l = LessonRun(TensHundreds.spec, numbers: TensHundreds.numbers(kind: 0, p: 10, c: 34))
        XCTAssertEqual(l.display, [.text("340"), .op("="), .text("?"), .text("tens")])
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "How many tens make 340?")
        _ = l.go()
        XCTAssertEqual(l.words.say, "How many tens make 340? Tap each hundred.")
        XCTAssertEqual(l.words.hint, "Each hundred opens into ten tens.")
        XCTAssertTrue(l.handAnswered)
        // a ten tapped instead
        XCTAssertEqual(move(&l, ["x": -1]), .notYet("Count tens: open the hundreds."))
        XCTAssertEqual(l.misses, 1)
        XCTAssertEqual(move(&l, ["x": 3]), .moved(2))
        // write it, with the web's slips
        XCTAssertEqual(l.words.say, "Write how many tens.")
        XCTAssertEqual(l.step.answer?.prompt, [.text("340"), .op("="), .box("x"), .text("tens")])
        XCTAssertEqual(type(&l, 4), .notYet("The 3 hundreds are 30 tens more."))
        XCTAssertEqual(type(&l, 3), .notYet("That’s the hundreds."))
        XCTAssertEqual(type(&l, 340), .notYet("That’s ones."))
        XCTAssertEqual(type(&l, 33), .notYet("Count the tens: each full frame is ten."))
        XCTAssertEqual(type(&l, 34), .moved(3))
        XCTAssertEqual(l.words.say, "A hundred is ten tens.")
        XCTAssertEqual(l.words.action, "Next problem")
    }

    func testTensHundredsB() {
        // 52 hundreds: 5 full tens close into 5 thousands; 5,200
        var l = LessonRun(TensHundreds.spec, numbers: TensHundreds.numbers(kind: 1, p: 100, c: 52))
        XCTAssertEqual(l.words.say, "What number is 52 hundreds?")
        _ = l.go()
        XCTAssertEqual(l.words.say, "What number is 52 hundreds? Tap each full ten.")
        XCTAssertEqual(move(&l, ["x": -2]), .notYet("That frame has 2. Only a full ten closes."))
        XCTAssertEqual(move(&l, ["x": 5]), .moved(2))
        XCTAssertEqual(l.words.say, "Write the number.")
        XCTAssertEqual(type(&l, 52), .notYet("That’s how many hundreds. Write the number."))
        XCTAssertEqual(type(&l, 520), .notYet("That’s 52 tens."))
        XCTAssertEqual(type(&l, 52000), .notYet("That’s 52 thousands."))
        XCTAssertEqual(type(&l, 5020), .notYet("Read the chart: a digit for every place, a 0 where it’s empty."))
        XCTAssertEqual(type(&l, 5200), .moved(3))
        XCTAssertEqual(l.words.say, "Ten hundreds make a thousand.")
        // thousands say 10, not "ten thousands"
        let t = TensHundreds.Parts(TensHundreds.numbers(kind: 1, p: 1000, c: 30))
        XCTAssertEqual(t.why, "10 thousands make a ten thousand.")
        XCTAssertEqual(t.N, 30000); XCTAssertEqual(t.columns, 5)
    }

    func testTensHundredsGenerator() {
        for i in 0..<8 {
            each(TensHundreds.spec, i) { n in
                let s = TensHundreds.Parts(n)
                XCTAssertEqual(s.kind, i % 2)
                if i < 3 { XCTAssertEqual(s.p, 10); XCTAssertTrue((11...39).contains(s.c), "\(s.c)") }
                else { XCTAssertTrue([100, 1000].contains(s.p)); XCTAssertTrue((11...99).contains(s.c)) }
            }
        }
        var rng = SeededRandom(seed: 3)
        for item in TensHundreds.spec.check { _ = item.draw(TensHundreds.spec, using: &rng) }
        XCTAssertEqual(TensHundreds.Parts(TensHundreds.spec.check[2].draw(TensHundreds.spec, using: &rng)).p, 100)
        XCTAssertEqual(TensHundreds.Parts(TensHundreds.spec.check[3].draw(TensHundreds.spec, using: &rng)).p, 1000)
    }

    // MARK: Reading and writing big numbers

    func testReadWriteA() {
        var l = LessonRun(ReadWriteBig.spec, numbers: ReadWriteBig.numbers(kind: 0, N: 40605))
        XCTAssertEqual(l.display, [.text("Build the number")])
        _ = l.go()
        XCTAssertEqual(l.words.say, "Build the number. Tap a column to put a disk in.")
        XCTAssertEqual(l.go(), .notYet("Tap a column to put a disk in."))
        XCTAssertEqual(l.misses, 0)
        // the traps: 4,605 and 400,605
        XCTAssertEqual(move(&l, ["x": 4605]), .notYet("That reads four thousand, six hundred five. Forty thousand is 4 ten thousands."))
        XCTAssertEqual(move(&l, ["x": 400605]), .notYet("That reads four hundred thousand, six hundred five. Forty thousand is 4 ten thousands."))
        // a place the number hasn't, filled: what it has no
        XCTAssertEqual(ReadWriteBig.Parts(l.numbers).built(140605), "That reads one hundred forty thousand, six hundred five. Forty thousand, six hundred five has no hundred thousands.")
        XCTAssertEqual(move(&l, ["x": 40600]), .notYet("That reads forty thousand, six hundred. Five is 5 ones."))
        XCTAssertEqual(l.misses, 3)
        XCTAssertEqual(move(&l, ["x": 40605]), .moved(2))
        XCTAssertEqual(l.words.say, "An empty place still needs its 0.")
    }

    func testReadWriteB() {
        var l = LessonRun(ReadWriteBig.spec, numbers: ReadWriteBig.numbers(kind: 1, N: 305280))
        let s = ReadWriteBig.Parts(l.numbers)
        XCTAssertEqual(s.parts, [5, 3, 2, 1])
        XCTAssertEqual(s.expanded, "300,000 + 5,000 + 200 + 80")
        XCTAssertEqual(l.display, [.text("305,280"), .op("="), .text("?")])
        _ = l.go()
        XCTAssertEqual(l.words.say, "Pull each digit down, out of the chart.")
        // a 0 won't come; let go too soon goes back: notices, not misses
        XCTAssertEqual(move(&l, ["x": -5]), .notYet("0 ten thousands is nothing. Leave it."))
        XCTAssertEqual(move(&l, ["x": -100]), .notYet("Drag it down, below the chart."))
        XCTAssertEqual(l.misses, 0)
        XCTAssertEqual(move(&l, ["x": 4]), .moved(2))
        XCTAssertEqual(l.words.say, "Each digit is worth its place.")
    }

    func testReadWriteGenerator() {
        for i in 0..<8 {
            each(ReadWriteBig.spec, i) { n in
                let s = ReadWriteBig.Parts(n)
                XCTAssertEqual(s.kind, i % 2)
                XCTAssertTrue((1000...999_999).contains(s.N))
                if i < 3 { XCTAssertEqual(s.length, 4); XCTAssertFalse(String(s.N).contains("0")) }
                else { XCTAssertTrue([5, 6].contains(s.length)) }
            }
        }
        // half the later ones have a 0 inside
        var zeros = 0
        each(ReadWriteBig.spec, 4, 400) { if ReadWriteBig.zeroInside(ReadWriteBig.Parts($0).N) { zeros += 1 } }
        XCTAssertTrue((140...260).contains(zeros), "\(zeros)")
        var rng = SeededRandom(seed: 5)
        let c = ReadWriteBig.spec.check.map { ReadWriteBig.Parts($0.draw(ReadWriteBig.spec, using: &rng)) }
        XCTAssertTrue(c[0].a && ReadWriteBig.zeroInside(c[0].N))
        XCTAssertTrue(!c[1].a && c[1].length == 6)
        XCTAssertTrue(c[2].a && c[2].length == 6)
        XCTAssertTrue(!c[3].a && ReadWriteBig.zeroInside(c[3].N))
    }

    // MARK: Comparing big numbers

    func testCompareDifferentLengths() {
        // 12,345 or 9,876: the second starts under the first's first digit; slide it right one column
        var l = LessonRun(CompareBig.spec, numbers: CompareBig.numbers(A: 12345, B: 9876, kind: 2))
        let s = CompareBig.Parts(l.numbers)
        XCTAssertEqual(s.n, 5); XCTAssertEqual(s.start, 0); XCTAssertEqual(s.aligned, 1); XCTAssertEqual(s.first, 4)
        XCTAssertEqual(l.steps.count, 5, "ask, slide, the place, the sign, done")
        XCTAssertEqual(l.words.say, "Which is bigger, 12,345 or 9,876?")
        _ = l.go()
        XCTAssertEqual(l.words.say, "Line them up. Slide the second number until ones are under ones.")
        XCTAssertEqual(move(&l, ["x": 0]), .notYet("The 6 is under the tens. Ones go under ones."))
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("The 6 is past the ones. Ones go under ones."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Tap the first place that differs.")
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("The ten thousands differ first: 1 and 0."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(3))
        XCTAssertEqual(l.words.hint, "1 ten thousand and 0 ten thousands.")
        XCTAssertEqual(move(&l, ["s": 0]), .notYet("12,345 has a ten thousand. 9,876 has none."))
        XCTAssertEqual(move(&l, ["s": 1]), .notYet("The ten thousands differ: 1 and 0."))
        XCTAssertEqual(move(&l, ["s": 2]), .moved(4))
        XCTAssertEqual(l.words.say, "The first place that differs decides.")
    }

    func testCompareMiddlePlaceAndEqual() {
        var l = LessonRun(CompareBig.spec, numbers: CompareBig.numbers(A: 52318, B: 52418, kind: 1))
        XCTAssertEqual(l.steps.count, 4, "same length: no slide")
        _ = l.go()
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("Both have 2 thousands. Look further right."))
        XCTAssertEqual(move(&l, ["x": 0]), .notYet("The hundreds differ first: 3 and 4."))
        XCTAssertEqual(move(&l, ["x": 2]), .moved(2))
        XCTAssertEqual(move(&l, ["s": 2]), .notYet("52,418 is bigger: 52,318 < 52,418."))
        XCTAssertEqual(move(&l, ["s": 0]), .moved(3))
        // equal: only the sign
        var e = LessonRun(CompareBig.spec, numbers: CompareBig.numbers(A: 70412, B: 70412, kind: 3))
        XCTAssertEqual(e.steps.count, 3)
        _ = e.go()
        XCTAssertEqual(move(&e, ["s": 2]), .notYet("Every place has the same digit."))
        XCTAssertEqual(move(&e, ["s": 1]), .moved(2))
        XCTAssertEqual(e.words.say, "Every place matches, so they’re equal.")
    }

    func testCompareGenerator() {
        for i in 0..<8 {
            each(CompareBig.spec, i) { n in
                let s = CompareBig.Parts(n)
                XCTAssertTrue((1000...999_999).contains(s.A) && (1000...999_999).contains(s.B))
                switch s.kind {
                case 0: XCTAssertEqual(s.lA, s.lB); XCTAssertEqual(s.first, s.n - 1)
                case 1: XCTAssertEqual(s.lA, s.lB); XCTAssertNotNil(s.first); XCTAssertLessThan(s.first!, s.n - 1)
                case 2: XCTAssertEqual(abs(s.lA - s.lB), 1)
                    // the shorter has the bigger first digit (the trap)
                    let (lng, sht) = s.lA > s.lB ? (s.A, s.B) : (s.B, s.A)
                    XCTAssertGreaterThan(BigNumbers.digit(sht, BigNumbers.length(sht) - 1), BigNumbers.digit(lng, BigNumbers.length(lng) - 1))
                default: XCTAssertEqual(s.A, s.B)
                }
                if i < 3 { XCTAssertEqual(s.kind, 0); XCTAssertEqual(s.n, 4) }
            }
        }
    }

    // MARK: Place value and rounding

    func testPlaceValue() {
        // 47,382 to the nearest thousand: line 1 40,000 to 50,000; block 7; 382 to 47,000, 618 to 48,000
        var l = LessonRun(PlaceValueRound.spec, numbers: PlaceValueRound.numbers(n: 47382, r: 1000))
        let s = PlaceValueRound.Parts(l.numbers)
        XCTAssertEqual(s.lo1, 40000); XCTAssertEqual(s.block, 7); XCTAssertEqual(s.T, 47000); XCTAssertEqual(s.R, 47000); XCTAssertFalse(s.up)
        XCTAssertEqual(l.display, [.text("47,382"), .op("≈"), .text("?"), .text("(nearest thousand)")])
        _ = l.go()
        XCTAssertEqual(l.words.say, "Round to the nearest thousand. Tap the thousand the point is in.")
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("47,382 is between 47,000 and 48,000."))
        XCTAssertEqual(move(&l, ["x": 7]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 10]), .notYet("That end is 618 away. The other end is 382."))
        XCTAssertEqual(move(&l, ["x": 0]), .moved(3))
        XCTAssertEqual(l.step.answer?.prompt, [.text("47,382"), .op("≈"), .box("x")])
        XCTAssertEqual(type(&l, 48000), .notYet("The next digit is 3. Less than 5 rounds down, to 47,000."))
        XCTAssertEqual(type(&l, 47382), .notYet("A rounded number ends in zeros. Every digit after the thousands place becomes 0."))
        XCTAssertEqual(type(&l, 47400), .notYet("That’s 47,382 to the nearest hundred. Round to the nearest thousand instead."))
        XCTAssertEqual(type(&l, 47), .notYet("Keep the zeros: 47 thousands is written 47,000."))
        XCTAssertEqual(type(&l, 46000), .notYet("Write the end you dragged to."))
        XCTAssertEqual(type(&l, 47000), .moved(4))
        XCTAssertEqual(l.words.say, "382 to 47,000, 618 to 48,000. 47,000 is closer.")
        XCTAssertEqual(s.rule, "3 is less than 5: round down")
        // exactly halfway rounds up
        var h = LessonRun(PlaceValueRound.spec, numbers: PlaceValueRound.numbers(n: 2350, r: 100))
        _ = h.go(); _ = move(&h, ["x": 3])
        XCTAssertEqual(move(&h, ["x": 0]), .notYet("Exactly halfway rounds up."))
        XCTAssertEqual(move(&h, ["x": 10]), .moved(3))
        XCTAssertEqual(PlaceValueRound.Parts(h.numbers).why, "50 to 2,300, 50 to 2,400. Exactly halfway rounds up.")
    }

    func testPlaceValueGenerator() {
        for i in 0..<8 {
            each(PlaceValueRound.spec, i) { n in
                let s = PlaceValueRound.Parts(n)
                let (d, places) = i < 3 ? (4, [10, 100]) : i < 6 ? (5, [100, 1000, 10000]) : (6, [1000, 10000, 100000])
                XCTAssertEqual(BigNumbers.length(s.n), d); XCTAssertTrue(places.contains(s.r)); XCTAssertNotEqual(s.n % s.r, 0)
                XCTAssertTrue((0...9).contains(s.block)); XCTAssertEqual(s.lo1 + s.block * s.r, s.T)
            }
        }
        var rng = SeededRandom(seed: 9)
        let c = PlaceValueRound.spec.check.map { PlaceValueRound.Parts($0.draw(PlaceValueRound.spec, using: &rng)) }
        XCTAssertFalse(c[0].up); XCTAssertTrue(c[1].up); XCTAssertEqual(c[2].next, 5)
    }

    // MARK: Add and subtract big numbers

    func testAddWithCarry() {
        // 46,372 + 21,519: the ones carry, nothing else does
        var l = LessonRun(AddSubBig.spec, numbers: AddSubBig.numbers(a: 46372, b: 21519, sub: false))
        let s = AddSubBig.Parts(l.numbers)
        XCTAssertEqual(s.R, 67891); XCTAssertEqual(s.at, 0)
        XCTAssertEqual(s.phases, [.slide([0]), .close(0), .slide([1]), .slide([2]), .slide([3, 4])])
        XCTAssertEqual(s.written(after: 0), [:])
        XCTAssertEqual(s.written(after: 1), [:], "the ones wait for their ten to close")
        XCTAssertEqual(s.written(after: 2), [0: 1])
        XCTAssertEqual(s.written(after: 4), [0: 1, 1: 9, 2: 8])
        XCTAssertEqual(l.steps.count, 8, "ask, five moves, write, done")
        _ = l.go()
        XCTAssertEqual(l.words.say, "Slide the striped ones up.")
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("Start with the ones."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Tap the full ten.")
        XCTAssertEqual(l.words.hint, "10 ones make 1 ten.")
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("11 ones: tap the full ten first."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(3))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(4))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(5))
        XCTAssertEqual(l.words.say, "Slide the rest up together.")
        XCTAssertEqual(move(&l, ["x": 1]), .moved(6))
        XCTAssertEqual(l.words.say, "Write the rest of the answer.")
        XCTAssertEqual(type(&l, 66), .notYet("Read each column’s disks, from the left."))
        XCTAssertEqual(type(&l, 67), .moved(7))
        XCTAssertEqual(l.words.say, "Ten in one place make 1 in the next.")
        XCTAssertEqual(l.misses, 0)
    }

    func testAddCarryIntoThousands() {
        // the hundreds carry: forgetting the carried 1 is a slip the box can show
        let l = LessonRun(AddSubBig.spec, numbers: AddSubBig.numbers(a: 4521, b: 2632, sub: false))
        let s = AddSubBig.Parts(l.numbers)
        XCTAssertEqual(s.at, 2); XCTAssertEqual(s.R, 7153)
        XCTAssertEqual(s.typed(6), "You carried 1 from the hundreds. Add it to the thousands too.")
        XCTAssertEqual(l.steps.last(where: { $0.answer?.byHand == false })?.answer?.known.first?.values, ["x": 6])
    }

    func testSubtractWithTrade() {
        // 6,742 − 1,517: the ones trade a ten
        var l = LessonRun(AddSubBig.spec, numbers: AddSubBig.numbers(a: 6742, b: 1517, sub: true))
        let s = AddSubBig.Parts(l.numbers)
        XCTAssertEqual(s.R, 5225); XCTAssertEqual(s.at, 0)
        XCTAssertEqual(s.phases, [.slide([0]), .slide([1]), .slide([2]), .slide([3])])
        XCTAssertEqual(s.written(after: 1), [0: 5])
        _ = l.go()
        XCTAssertEqual(l.words.hint, "Too few on top? Open a ten first.")
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("2 ones can’t take away 7. Open a ten."))
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("Open a ten."))
        XCTAssertEqual(l.misses, 1)
        XCTAssertEqual(move(&l, ["x": 1]), .moved(2))
        // the tens have enough
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("There are enough tens. Take away first."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(3))
        _ = move(&l, ["x": 1]); _ = move(&l, ["x": 1])
        XCTAssertEqual(type(&l, 4), .notYet("Read each column’s disks, from the left."))
        XCTAssertEqual(type(&l, 5), .moved(6))
        // the slips the box can show: a trade in the thousands (52,742 − 18,521 = 34,221) taken the smaller from the bigger
        // (46,221), or not crossed out (44,221)
        let t = AddSubBig.Parts(AddSubBig.numbers(a: 52742, b: 18521, sub: true))
        XCTAssertEqual(t.at, 3); XCTAssertEqual(t.R, 34221)
        XCTAssertEqual(t.typed(46), "In each column take the bottom digit from the top one. When the top is smaller, trade a ten first.")
        XCTAssertEqual(t.typed(44), "When a place trades a ten away, it has 1 less. Cross it out and write the new digit.")
        XCTAssertEqual(t.phases, [.slide([0]), .slide([1]), .slide([2]), .slide([3, 4])])
        XCTAssertEqual(LessonRun(AddSubBig.spec, numbers: AddSubBig.numbers(a: 52742, b: 18521, sub: true)).steps[5].answer?.known.map { $0.values["x"] ?? 0 }, [46, 44])
    }

    func testAddSubGenerator() {
        for i in 0..<8 {
            each(AddSubBig.spec, i, 200) { n in
                let s = AddSubBig.Parts(n), d = i < 4 ? 4 : 5
                XCTAssertEqual(BigNumbers.length(s.a), d); XCTAssertEqual(BigNumbers.length(s.b), d)
                XCTAssertEqual(s.columns.filter(\.regroup).count, 1)
                if s.sub {
                    XCTAssertGreaterThanOrEqual(s.a - s.b, 1000)
                    XCTAssertNotEqual(BigNumbers.digit(s.a, s.at + 1), 0, "never a trade across a 0")
                }
                // the hands write the ones, tens and hundreds of the answer
                XCTAssertEqual(s.written(after: s.phases.count), [0: BigNumbers.digit(s.R, 0), 1: BigNumbers.digit(s.R, 1), 2: BigNumbers.digit(s.R, 2)])
                let l = LessonRun(AddSubBig.spec, numbers: n)
                XCTAssertEqual(l.steps.count, s.phases.count + 3)
            }
        }
        var rng = SeededRandom(seed: 2)
        let spec = AddSubBig.spec
        XCTAssertTrue(AddSubBig.Parts(spec.check[0].draw(spec, using: &rng)).sub)
        XCTAssertFalse(AddSubBig.Parts(spec.check[1].draw(spec, using: &rng)).sub)
        XCTAssertTrue(spec.check[3].story)
        // the story picks the operation first (the web's)
        let story = LessonRun(spec, numbers: AddSubBig.numbers(a: 46372, b: 21519, sub: false), story: true)
        XCTAssertEqual(story.words.say, "A library has 46,372 books. It gets 21,519 more. How many books does it have now?")
    }
}
