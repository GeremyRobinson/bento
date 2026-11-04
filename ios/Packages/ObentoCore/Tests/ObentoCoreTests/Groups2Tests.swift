import XCTest
@testable import ObentoCore

/// 2nd grade, chapter 3: Equal groups (design/grade2.md, the preview design/prototype/grade2-ch3.html).
final class Groups2Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(55 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(2)[2]
        XCTAssertEqual(ch.title, "Equal groups"); XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name); XCTAssertTrue(Curriculum.voiced(l.id)) }
    }

    func testEvenOdd() {
        var l = LessonRun(EvenOdd2.spec, numbers: EvenOdd2.numbers(n: 13, mix: 4))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Tap each dot.")
        XCTAssertEqual(move(&l, ["k": 13]), .moved(1))
        XCTAssertEqual(l.words.say, "Tap even or odd.")
        XCTAssertEqual(move(&l, ["c": 0]), .notYet("One dot is left over without a partner, so 13 is odd."))
        XCTAssertEqual(move(&l, ["c": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Write how many are in each row.")
        XCTAssertEqual(move(&l, ["a": 7, "b": 7]), .notYet("That's 14. Each row has 6, and 1 is left."))
        XCTAssertEqual(move(&l, ["a": 13, "b": 6]), .notYet("That's all 13 dots. Write how many are in one row."))
        XCTAssertEqual(move(&l, ["a": 6, "b": 5]), .notYet("Both rows have the same number of dots."))
        XCTAssertEqual(move(&l, ["a": 5, "b": 5]), .notYet("That's 11. Count the dots in one row."))
        XCTAssertEqual(move(&l, ["a": 6, "b": 6]), .moved(3))
        XCTAssertEqual(l.words.say, "One dot has no partner, so 13 is odd.")

        var e = LessonRun(EvenOdd2.spec, numbers: EvenOdd2.numbers(n: 14))
        _ = move(&e, ["k": 14])
        XCTAssertEqual(move(&e, ["c": 1]), .notYet("Every dot has a partner and none are left over, so 14 is even."))
        XCTAssertEqual(move(&e, ["c": 0]), .moved(2))
        XCTAssertEqual(move(&e, ["a": 7, "b": 7]), .moved(3))
        XCTAssertEqual(e.words.say, "Every dot has a partner, so 14 is even.")

        let P = EvenOdd2.Parts(EvenOdd2.numbers(n: 17, mix: 12))
        XCTAssertEqual(Set(P.places).count, 17); XCTAssertTrue(P.places.allSatisfy { (0..<30).contains($0) })
        for i in 0..<8 {
            each(EvenOdd2.spec, i) { x in
                let n = EvenOdd2.Parts(x).n
                XCTAssertTrue(i < 3 ? (4...12).contains(n) : (7...20).contains(n))
            }
        }
        let c = checks(EvenOdd2.spec).map(EvenOdd2.Parts.init)
        XCTAssertFalse(c[0].odd); XCTAssertTrue(c[1].odd)
        XCTAssertTrue(!c[2].odd && c[2].n >= 15); XCTAssertTrue(c[3].odd && c[3].n >= 15)
    }

    func testArrays() {
        var l = LessonRun(Arrays2.spec, numbers: Arrays2.numbers(rows: 3, cols: 4))
        XCTAssertEqual(l.steps.count, 4)
        XCTAssertEqual(l.words.say, "Tap each row.")
        XCTAssertEqual(move(&l, ["r": -1]), .notYet("That goes down. Rows go across."))
        XCTAssertEqual(move(&l, ["r": 3]), .moved(1))
        XCTAssertEqual(l.words.say, "Count one row.")
        XCTAssertEqual(move(&l, ["c": -1]), .notYet("That's down. Count across."))
        XCTAssertEqual(move(&l, ["c": 4]), .moved(2))
        XCTAssertEqual(l.words.say, "Add 4 once for each row.")
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("Add 4 once for every row: that's 3 times."))
        XCTAssertEqual(move(&l, ["x": 8]), .notYet("There are 3 rows, so add 4 3 times."))
        XCTAssertEqual(move(&l, ["x": 16]), .notYet("There are only 3 rows. Add 4 3 times."))
        XCTAssertEqual(move(&l, ["x": 11]), .notYet("Skip count by 4s, once for each row."))
        XCTAssertEqual(move(&l, ["x": 12]), .moved(3))
        XCTAssertEqual(l.words.say, "Every row has 4, so add 4 for each row.")
        XCTAssertEqual(Arrays2.Parts(Arrays2.numbers(rows: 2, cols: 5, story: true)).lines,
                       ["A box of muffins has 2 rows with 5 muffins in each row.", "How many muffins are in the box?"])
        for i in 0..<8 {
            each(Arrays2.spec, i) { x in
                let P = Arrays2.Parts(x), hi = i < 3 ? 4 : 5
                XCTAssertTrue((2...hi).contains(P.R) && (2...hi).contains(P.C)); XCTAssertEqual(P.story, i % 4 == 3)
            }
        }
        let c = checks(Arrays2.spec).map(Arrays2.Parts.init)
        XCTAssertNotEqual(c[1].R, c[1].C); XCTAssertTrue(c[2].R == 5 || c[2].C == 5); XCTAssertTrue(c[3].story)
    }

    func testSquares() {
        var l = LessonRun(Squares2.spec, numbers: Squares2.numbers(rows: 3, cols: 4))
        XCTAssertEqual(l.steps.count, 5)
        XCTAssertEqual(l.words.say, "Cut it into 3 rows.")
        XCTAssertEqual(move(&l, ["k1": 5]), .notYet("That's 5 rows. Cut 3."))
        XCTAssertEqual(move(&l, ["k1": 3]), .moved(1))
        XCTAssertEqual(l.words.say, "Now cut the rows into squares.")
        XCTAssertEqual(move(&l, ["k2": 2]), .notYet("Those are 2 squares wide and 5 tall."))
        XCTAssertEqual(move(&l, ["k2": 5]), .moved(2))
        XCTAssertEqual(l.words.say, "Tap each row.")
        XCTAssertEqual(move(&l, ["r": 3]), .moved(3))
        XCTAssertEqual(l.words.say, "Write how many squares.")
        XCTAssertEqual(move(&l, ["x": 300]), .notYet("That counts the paper's small squares. Count the ones you cut."))
        XCTAssertEqual(move(&l, ["x": 7]), .notYet("That's 3 + 4. Add 4 for each row."))
        XCTAssertEqual(move(&l, ["x": 16]), .notYet("There are only 3 rows. Add 4 3 times."))
        XCTAssertEqual(move(&l, ["x": 12]), .moved(4))
        XCTAssertEqual(l.words.say, "Same-size squares, so every row has the same number.")

        var c = LessonRun(Squares2.spec, numbers: Squares2.numbers(rows: 4, cols: 2, rowsFirst: false))
        XCTAssertEqual(c.words.say, "Cut it into 2 columns.")
        XCTAssertEqual(move(&c, ["k1": 2]), .moved(1))
        XCTAssertEqual(c.words.say, "Now cut the columns into squares.")
        XCTAssertEqual(move(&c, ["k2": 10]), .notYet("Those are 5 squares wide and 10 tall."))
        let P = Squares2.Parts(Squares2.numbers(rows: 4, cols: 6))
        XCTAssertEqual(P.sizes(true), [2, 4, 5, 10]); XCTAssertEqual(P.sizes(false), [2, 3, 5, 6, 10, 15])
        for i in 0..<8 {
            each(Squares2.spec, i) { x in
                let P = Squares2.Parts(x)
                if i < 3 { XCTAssertTrue((2...3).contains(P.R) && (2...4).contains(P.C) && P.rowsFirst) }
                else { XCTAssertTrue((2...5).contains(P.R) && (2...6).contains(P.C)) }
                // the cut that's wanted is always one the handle can make
                XCTAssertTrue(P.sizes(P.rowsCut(0)).contains(5)); XCTAssertTrue(P.sizes(P.rowsCut(1)).contains(5))
            }
        }
        let k = checks(Squares2.spec).map(Squares2.Parts.init)
        XCTAssertGreaterThanOrEqual(k[1].R, 4); XCTAssertGreaterThanOrEqual(k[2].C, 5)
    }
}
