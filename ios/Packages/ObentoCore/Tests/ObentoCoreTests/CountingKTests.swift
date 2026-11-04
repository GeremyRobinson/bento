import XCTest
@testable import ObentoCore

/// Kindergarten, chapter 1: Count to 10 (design/gradeK.md, the preview design/prototype/gradeK-ch1.html).
final class CountingKTests: XCTestCase {
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
        XCTAssertTrue(Grades.isLive(0))
        let chapters = Curriculum.chapters(0)
        XCTAssertEqual(chapters.count, 5)
        XCTAssertEqual(chapters.flatMap(\.lessons).count, 23)
        let ch = chapters[0]
        XCTAssertEqual(ch.title, "Count to 10")
        XCTAssertEqual(ch.test, "test-gk-count")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
        // the first two chapters are built: the rest wait off the map
        XCTAssertTrue(Curriculum.built(chapters[1]))
        XCTAssertFalse(chapters.dropFirst(2).contains(where: Curriculum.built))
        XCTAssertEqual(Curriculum.grade(of: "gk-onemore"), 0)
        XCTAssertEqual(Curriculum.grade(of: "k-compare"), 0)
        XCTAssertEqual(Curriculum.gradeTest(0), "test-grade-0")
        // spoken in K (and 1st grade), not in 4th
        XCTAssertTrue(Curriculum.voiced("gk-count10"))
        XCTAssertFalse(Curriculum.voiced("g4-compare"))
        let ids = chapters.flatMap(\.lessons).map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        for g in [4, 5, 6] { XCTAssertTrue(Set(Curriculum.chapters(g).flatMap(\.lessons).map(\.id)).isDisjoint(with: ids)) }
        XCTAssertEqual(Grades.short(0), "K")
        XCTAssertEqual(Grades.onMe(0), "Kindergarten")
    }

    // MARK: Count to 10

    func testCountHowMany() {
        let x = CountToTen.numbers(n: 7, lay: .scattered, places: [(0, 0), (2, 0), (4, 1), (6, 0), (8, 3), (1, 2), (3, 3)])
        var l = LessonRun(CountToTen.spec, numbers: x)
        XCTAssertEqual(l.words.say, "Tap each dot.")
        XCTAssertTrue(l.handAnswered)
        // a dot tapped twice: a miss, said on the paper
        XCTAssertEqual(move(&l, ["c": -1]), .notYet("You counted that one."))
        XCTAssertEqual(move(&l, ["c": 7]), .moved(1))
        XCTAssertEqual(l.words.say, "Write how many.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["n": 6]), .notYet("One short. The last number was 7."))
        XCTAssertEqual(move(&l, ["n": 8]), .notYet("One too many. The last number was 7."))
        XCTAssertEqual(move(&l, ["n": 3]), .notYet("The last number was 7."))
        XCTAssertEqual(move(&l, ["n": 7]), .moved(2))
        XCTAssertEqual(l.words.say, "The last number you say is how many.")
        XCTAssertTrue(l.isLast)
    }

    func testCountMake() {
        var l = LessonRun(CountToTen.spec, numbers: CountToTen.numbers(kind: .make, n: 7))
        XCTAssertEqual(l.words.say, "Make 7.")
        XCTAssertEqual(move(&l, ["m": 8]), .notYet("That’s 8. Make 7."))
        XCTAssertEqual(move(&l, ["m": 5]), .notYet("That’s 5. Make 7."))
        XCTAssertEqual(move(&l, ["m": 7]), .moved(1))
        XCTAssertEqual(l.words.say, "The last number you say is how many.")
        XCTAssertEqual(l.steps.count, 2)
    }

    func testCountGenerator() {
        // the first three: count, 1–5, a line
        each(CountToTen.spec, 0) { x in
            let P = CountToTen.Parts(x)
            XCTAssertEqual(P.kind, .count); XCTAssertEqual(P.lay, .line); XCTAssertTrue((1...5).contains(P.n))
            XCTAssertEqual(P.places.count, P.n)
        }
        // 3–5 by turns: 3 and 5 count, 4 make
        each(CountToTen.spec, 3) { XCTAssertEqual(CountToTen.Parts($0).kind, .count) }
        each(CountToTen.spec, 4) { XCTAssertEqual(CountToTen.Parts($0).kind, .make) }
        var kinds = Set<Int>(), lays = Set<Int>()
        for i in 3..<12 {
            each(CountToTen.spec, i) { x in
                let P = CountToTen.Parts(x)
                kinds.insert(P.kind.rawValue)
                XCTAssertTrue((1...10).contains(P.n))
                if i >= 6 { XCTAssertGreaterThanOrEqual(P.n, 4) }
                guard P.kind == .count else { return }
                lays.insert(P.lay.rawValue)
                if i < 6 { XCTAssertNotEqual(P.lay, .ring) }
                if P.lay == .array { XCTAssertNotNil(CountToTen.arrays[P.n]) }
                // every dot in its own block of the 10 × 4 field
                XCTAssertEqual(Set(P.places.map { "\($0.col),\($0.row)" }).count, P.n)
                for p in P.places { XCTAssertTrue((0...9).contains(p.col) && (0...3).contains(p.row)) }
                // scattered: no two in blocks that share a side
                if P.lay == .scattered {
                    for a in P.places { for b in P.places where a.col != b.col || a.row != b.row { XCTAssertGreaterThan(abs(a.col - b.col) + abs(a.row - b.row), 1) } }
                }
                XCTAssertEqual(P.rows, (P.places.map(\.row).max() ?? 0) + 1)
            }
        }
        XCTAssertEqual(kinds, [0, 1])
        XCTAssertEqual(lays, [0, 1, 2, 3])
    }

    func testCountCheck() {
        let c = checks(CountToTen.spec).map(CountToTen.Parts.init)
        XCTAssertEqual(c[0].lay, .scattered); XCTAssertGreaterThanOrEqual(c[0].n, 7)
        XCTAssertEqual(c[1].lay, .ring)
        XCTAssertEqual(c[2].kind, .make)
    }

    // MARK: One more

    func testOneMore() {
        var l = LessonRun(OneMore.spec, numbers: OneMore.numbers(n: 6))
        XCTAssertEqual(l.words.say, "Make one more.")
        XCTAssertEqual(move(&l, ["m": 6]), .notYet("That’s 6 again. One more."))
        XCTAssertEqual(move(&l, ["m": 8]), .notYet("That’s 8: 2 more."))
        XCTAssertEqual(move(&l, ["m": 4]), .notYet("That’s less than 6."))
        XCTAssertEqual(move(&l, ["m": 7]), .moved(1))
        XCTAssertEqual(l.words.say, "Write 1 more than 6.")
        XCTAssertEqual(move(&l, ["x": 6]), .notYet("That’s 6 again. One more."))
        XCTAssertEqual(move(&l, ["x": 8]), .notYet("That’s 8: 2 more."))
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("That’s less than 6."))
        XCTAssertEqual(move(&l, ["x": 7]), .moved(2))
        XCTAssertEqual(l.words.say, "Each next number is one more cube.")
        each(OneMore.spec, 0) { XCTAssertTrue((1...4).contains(OneMore.Parts($0).n)) }
        var seen = Set<Int>()
        each(OneMore.spec, 5) { seen.insert(OneMore.Parts($0).n) }
        XCTAssertEqual(seen, Set(1...9))
        let c = checks(OneMore.spec).map { OneMore.Parts($0).n }
        XCTAssertLessThanOrEqual(c[0], 4); XCTAssertGreaterThanOrEqual(c[1], 7); XCTAssertEqual(c[2], 9)
    }

    // MARK: More, less or the same

    func testCompare() {
        var l = LessonRun(CompareGroups.spec, numbers: CompareGroups.numbers(top: 6, bottom: 4, spread: true, shift: 0))
        XCTAssertEqual(l.words.say, "Count each row.")
        XCTAssertEqual(move(&l, ["top": -1, "bottom": -1]), .notYet("You counted that one."))
        XCTAssertEqual(move(&l, ["top": 6, "bottom": 4]), .moved(1))
        XCTAssertEqual(l.words.say, "Line them up.")
        XCTAssertEqual(move(&l, ["l": 0]), .notYet("Start it under the top row."))
        XCTAssertEqual(move(&l, ["l": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "Tap the row with more.")
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("Every bottom dot has a partner. 2 top dots don’t."))
        XCTAssertEqual(move(&l, ["c": 2]), .notYet("2 dots have no partner."))
        XCTAssertEqual(move(&l, ["c": 0]), .moved(3))
        XCTAssertEqual(l.words.say, "The row with dots left over has more.")
        XCTAssertEqual(CompareGroups.Parts(l.numbers).sentence, "6 is more than 4")
        let same = CompareGroups.Parts(CompareGroups.numbers(top: 5, bottom: 5))
        XCTAssertEqual(same.picked(0), "Look again: every dot has a partner.")
        XCTAssertNil(same.picked(2))
        XCTAssertEqual(same.sentence, "5 is the same as 5")
        let one = CompareGroups.Parts(CompareGroups.numbers(top: 3, bottom: 4))
        XCTAssertEqual(one.picked(0), "Every top dot has a partner. 1 bottom dot doesn’t.")
        XCTAssertEqual(one.picked(2), "1 dot has no partner.")
        XCTAssertEqual(one.sentence, "3 is less than 4")
    }

    func testCompareGenerator() {
        each(CompareGroups.spec, 0) { x in
            let P = CompareGroups.Parts(x)
            XCTAssertTrue(P.top <= 5 && P.bottom <= 5); XCTAssertGreaterThanOrEqual(P.extra, 2)
        }
        var same = 0
        each(CompareGroups.spec, 4, 500) { x in
            let P = CompareGroups.Parts(x)
            if P.extra == 0 { same += 1 }
            // the bottom row looks longer only when it's the smaller row of 5 or fewer; it never ends past 12 blocks
            XCTAssertEqual(P.spread, P.bottom < P.top && P.bottom <= 5 && P.bottom > 1)
            XCTAssertLessThanOrEqual((P.slots.last ?? 0) + P.shift + 1, 12)
            if !P.spread { XCTAssertTrue((1...3).contains(P.shift)) }
        }
        XCTAssertTrue((50...150).contains(same))
        let c = checks(CompareGroups.spec).map(CompareGroups.Parts.init)
        XCTAssertEqual(c.map(\.right), [0, 1, 2, c[3].right]); XCTAssertEqual(c[3].extra, 1)
    }

    // MARK: Which number is more?

    func testNumCompare() {
        var l = LessonRun(CompareNumbers.spec, numbers: CompareNumbers.numbers(a: 6, b: 8))
        XCTAssertEqual(l.words.say, "Make each number.")
        XCTAssertEqual(move(&l, ["w": CompareNumbers.Parts.code(row: 0, m: 7)]), .notYet("That’s 7. Make 6."))
        XCTAssertEqual(move(&l, ["w": CompareNumbers.Parts.code(row: 1, m: 5)]), .notYet("That’s 5. Make 8."))
        XCTAssertEqual(move(&l, ["w": 0]), .moved(1))
        XCTAssertEqual(l.words.say, "Tap the one that’s more.")
        XCTAssertEqual(move(&l, ["p": 0]), .notYet("6 stops 2 cubes before 8."))
        XCTAssertEqual(move(&l, ["p": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "8 comes after 6 when you count, so 8 is more.")
        let less = CompareNumbers.Parts(CompareNumbers.numbers(a: 4, b: 3, less: true))
        XCTAssertEqual(less.want, 1)
        XCTAssertEqual(less.missed, "3 stops 1 cube before 4.")
        XCTAssertEqual(less.why, "3 comes before 4 when you count, so 3 is less.")
        XCTAssertEqual(less.sentence, "3 is less than 4")
        each(CompareNumbers.spec, 1) { x in
            let P = CompareNumbers.Parts(x)
            XCTAssertTrue(P.a <= 5 && P.b <= 5 && P.extra >= 2 && !P.less)
        }
        var asks = 0
        each(CompareNumbers.spec, 5, 600) { x in let P = CompareNumbers.Parts(x); XCTAssertNotEqual(P.a, P.b); if P.less { asks += 1 } }
        XCTAssertTrue((150...250).contains(asks))
        let c = checks(CompareNumbers.spec).map(CompareNumbers.Parts.init)
        XCTAssertEqual(c[0].extra, 1); XCTAssertTrue(c[1].less); XCTAssertEqual(c[2].big, 10)
    }

    // MARK: The voice

    func testSpoken() {
        XCTAssertEqual(Spoken.text("3 + 4 = 7"), "3 plus 4 equals 7")
        XCTAssertEqual(Spoken.text("9 − 5 = 4"), "9 minus 5 equals 4")
        XCTAssertEqual(Spoken.text("45¢"), "45 cents")
        XCTAssertEqual(Spoken.text("That’s 8. Make 7."), "That's 8. Make 7.")
        XCTAssertEqual(Spoken.text("Shade 3/4."), "Shade 3 fourths.")
        XCTAssertEqual(Spoken.text("1/2 of 6"), "1 half of 6")
        XCTAssertEqual(Spoken.text("7 > 5"), "7 is greater than 5")
    }

    func testEveryProblemPlays() {
        // every problem from easy to hard can be played to its last step with the expected answers
        for spec in [CountToTen.spec, OneMore.spec, CompareGroups.spec, CompareNumbers.spec] {
            for i in 0..<10 {
                each(spec, i, 40) { x in
                    var l = LessonRun(spec, numbers: x)
                    for _ in 0..<8 where !l.isLast { if let a = l.step.answer { for (b, v) in a.expected { l.set(b, v) } }; _ = l.go() }
                    XCTAssertTrue(l.isLast, "\(spec.id) \(x)")
                    XCTAssertFalse(l.missedAny)
                }
            }
        }
    }
}
