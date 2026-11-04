import XCTest
@testable import ObentoCore

/// 6th grade, chapter 5: Expressions (design/grade6.md, the preview design/prototype/grade6-ch5.html).
final class ExpressionsG6Tests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func typeAll(_ l: inout LessonRun, _ v: [(String, String)]) -> LessonRun.Outcome {
        l.reset()
        for (b, x) in v { l.active = b; for ch in x { l.type(String(ch)) } }
        return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(53 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 11)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(6)[4]
        XCTAssertEqual(ch.title, "Expressions")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
        XCTAssertEqual(Curriculum.grade(of: "g6-equiv"), 6)
    }

    // MARK: Exponents and order

    func testExpoSquare() {
        var l = LessonRun(Expo6.spec, numbers: Expo6.numbers(a: 4, n: 2, b: 5, c: 3))
        XCTAssertEqual(l.words.say, "Tap what goes first.")
        _ = l.go()
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["p": 2]), .notYet("The exponent goes before × and +."))
        XCTAssertEqual(move(&l, ["p": 0]), .moved(2))
        XCTAssertEqual(l.words.say, "Build 4². Drag the corner out a block at a time.")
        XCTAssertEqual(move(&l, ["x": 42]), .notYet("That’s 4 × 2. 4² is 4 by 4."))
        XCTAssertEqual(move(&l, ["x": 44]), .moved(3))
        XCTAssertEqual(l.words.say, "Write what 4² makes. Count the squares.")
        XCTAssertEqual(typeAll(&l, [("x", "8")]), .notYet("4² means 4 × 4, not 4 × 2."))
        XCTAssertEqual(typeAll(&l, [("x", "15")]), .notYet("Count the squares: 4 rows of 4."))
        XCTAssertEqual(typeAll(&l, [("x", "16")]), .moved(4))
        XCTAssertEqual(l.words.say, "Tap what’s next.")
        XCTAssertEqual(move(&l, ["p": 1]), .notYet("× goes before +."))
        XCTAssertEqual(move(&l, ["p": 0]), .notYet("Tap what’s next."))
        XCTAssertEqual(move(&l, ["p": 2]), .moved(5))
        XCTAssertEqual(typeAll(&l, [("x", "8")]), .notYet("The sign is ×: 5 groups of 3."))
        XCTAssertEqual(typeAll(&l, [("x", "15")]), .moved(6))
        XCTAssertEqual(l.words.say, "Add last.")
        XCTAssertEqual(typeAll(&l, [("x", "63")]), .notYet("5 × 3 comes first. Add 15, not 5."))
        XCTAssertEqual(typeAll(&l, [("x", "23")]), .notYet("4² means 4 × 4, not 4 × 2."))
        XCTAssertEqual(typeAll(&l, [("x", "240")]), .notYet("The sign is +, so add."))
        XCTAssertEqual(typeAll(&l, [("x", "31")]), .moved(7))
        XCTAssertEqual(l.words.say, "4² is 4 × 4, and it goes before × and +.")
        XCTAssertTrue(l.isLast)
    }

    func testExpoCube() {
        var l = LessonRun(Expo6.spec, numbers: Expo6.numbers(a: 3, n: 3, b: 2, c: 7))
        _ = l.go(); _ = move(&l, ["p": 0])
        XCTAssertEqual(l.words.say, "Build 3³. Start with its floor: drag the corner out a block at a time.")
        XCTAssertEqual(move(&l, ["x": 33]), .moved(3))
        XCTAssertEqual(l.words.say, "Build it up. Drag up to stack the layers.")
        XCTAssertEqual(move(&l, ["l": 2]), .notYet("That’s 3 × 3 × 2. 3³ is 3 by 3 by 3."))
        XCTAssertEqual(move(&l, ["l": 3]), .moved(4))
        XCTAssertEqual(l.words.say, "Write what 3³ makes. Count the cubes.")
        XCTAssertEqual(typeAll(&l, [("x", "26")]), .notYet("Count the cubes: 3 layers of 9."))
        XCTAssertEqual(typeAll(&l, [("x", "27")]), .moved(5))
        XCTAssertEqual(l.steps.count, 9)
    }

    func testExpoGenerator() {
        for i in [0, 1, 2] { each(Expo6.spec, i) { x in let s = Expo6.Parts(x); XCTAssertTrue((3...4).contains(s.a)); XCTAssertEqual(s.n, 2); XCTAssertTrue(s.b <= 5 && s.c <= 5) } }
        each(Expo6.spec, 5) { x in
            let s = Expo6.Parts(x)
            XCTAssertFalse(s.a == 2 && s.n == 2)
            XCTAssertTrue((2...5).contains(s.a) && (2...9).contains(s.b) && (2...9).contains(s.c))
            XCTAssertEqual(s.S, s.E + s.b * s.c)
        }
        let c = checks(Expo6.spec).map(Expo6.Parts.init)
        XCTAssertEqual(c[0].n, 3); XCTAssertTrue(c[1].n == 2 && c[1].a >= 3)
    }

    // MARK: Write expressions

    func testWriteTimesPlus() {
        var l = LessonRun(Write6.spec, numbers: Write6.numbers(kind: 2, p: 5, k: 3))
        XCTAssertEqual(l.words.say, "3 times n, plus 5. Slide pieces onto the line, then Check.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["k": 0, "c": 0, "h": 1]), .notYet("Slide pieces onto the line."))
        XCTAssertEqual(l.misses, 0)
        XCTAssertEqual(move(&l, ["k": 1, "c": 5, "h": 1]), .notYet("That’s n + 5. The words say 3 times n."))
        XCTAssertEqual(move(&l, ["k": 3, "c": 4, "h": 1]), .notYet("That’s 3n + 4. The words say 3 times n, plus 5."))
        XCTAssertEqual(move(&l, ["k": 3, "c": 5, "h": 1]), .moved(2))
        XCTAssertEqual(l.words.say, "3 times n, plus 5. Write it the short way.")
        XCTAssertEqual(l.step.answer?.boxes, ["a", "b"])
        XCTAssertEqual(typeAll(&l, [("a", "3"), ("b", "4")]), .notYet("Count the squares."))
        XCTAssertEqual(typeAll(&l, [("a", "3"), ("b", "5")]), .moved(3))
        XCTAssertEqual(l.words.say, "Tap the coefficient.")
        let spans = Write6.Parts(l.numbers).spans
        XCTAssertEqual(move(&l, ["p": Double(spans.firstIndex { $0.id == "p" }!)]), .notYet("5 is a term on its own. The coefficient multiplies n."))
        XCTAssertEqual(move(&l, ["p": Double(spans.firstIndex { $0.id == "k" }!)]), .moved(4))
        XCTAssertEqual(l.words.say, "3n means 3 n’s, so 3 is the coefficient.")
    }

    func testWriteLessHalfTwice() {
        var less = Write6.Parts(Write6.numbers(kind: 3, q: 12))
        XCTAssertEqual(less.sentence, "n less than 12.")
        XCTAssertEqual(less.built(k: 1, c: -12, cut: 1), .wrong("12 − n: start with 12 and take n away."))
        XCTAssertEqual(less.built(k: -1, c: 12, cut: 1), .right)
        XCTAssertEqual(Write6.Parts.compact(k: -1, c: 12, cut: 1), "12 − n")
        less = Write6.Parts(Write6.numbers(kind: 3, story: true, q: 15))
        XCTAssertEqual(less.built(k: 1, c: 15, cut: 1), .wrong("That’s n + 15. Read the story again."))
        let half = Write6.Parts(Write6.numbers(kind: 4))
        XCTAssertEqual(half.built(k: 1, c: 0, cut: 1), .wrong("That’s n. The words say half of n."))
        XCTAssertEqual(half.built(k: 1, c: 0, cut: 2), .right)
        XCTAssertEqual(half.sentence, "Half of n.")
        let twice = Write6.Parts(Write6.numbers(kind: 5, m: 4, ask: 0))
        XCTAssertEqual(twice.built(k: 2, c: 4, cut: 1), .wrong("That’s 2n + 4. Twice the sum is two of n + 4."))
        XCTAssertEqual(twice.built(k: 2, c: 8, cut: 1), .right)
        XCTAssertEqual(twice.boxMiss("b", 8), "Inside the brackets is one n + 4.")
        XCTAssertEqual(twice.right, ["sum"])
        XCTAssertEqual(twice.wrongTap("two"), "2 is a factor. The sum is n + 4.")
    }

    func testWriteGenerator() {
        each(Write6.spec, 0) { XCTAssertEqual(Write6.Parts($0).kind, 0) }
        each(Write6.spec, 1) { let s = Write6.Parts($0); XCTAssertEqual(s.kind, 1); XCTAssertTrue((2...5).contains(s.k)) }
        each(Write6.spec, 4) { XCTAssertEqual(Write6.Parts($0).kind, 4) }
        each(Write6.spec, 8) { x in
            let s = Write6.Parts(x)
            // every build fits the 40-square line: an n strip is 8 squares
            let len = 8 * abs(s.wantK) + (s.kind == 3 ? s.q + 8 : s.wantC)
            XCTAssertLessThanOrEqual(len, 40)
            if s.story { XCTAssertTrue([0, 1, 3].contains(s.kind)) }
        }
        XCTAssertEqual(Write6.Parts(checks(Write6.spec)[2]).kind, 5)
    }

    // MARK: Evaluate expressions

    func testEval() {
        var l = LessonRun(Eval6.spec, numbers: Eval6.numbers(a: 3, b: 2, x: 4, y: 5))
        XCTAssertEqual(l.words.say, "Make x 4. Drag the end of an x strip.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("That’s 5. x is 4."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(2))
        XCTAssertEqual(l.words.say, "Write what 3x is. Count the cells.")
        XCTAssertEqual(typeAll(&l, [("x", "34")]), .notYet("3x means 3 × 4."))
        XCTAssertEqual(typeAll(&l, [("x", "7")]), .notYet("3x means 3 × 4."))
        XCTAssertEqual(typeAll(&l, [("x", "11")]), .notYet("Count the cells: 3 rows of 4."))
        XCTAssertEqual(typeAll(&l, [("x", "12")]), .moved(3))
        XCTAssertEqual(l.words.say, "Make y 5. Drag the end of a y strip.")
        XCTAssertEqual(move(&l, ["x": 5]), .moved(4))
        XCTAssertEqual(typeAll(&l, [("x", "10")]), .moved(5))
        XCTAssertEqual(typeAll(&l, [("x", "120")]), .notYet("The sign between 12 and 10 is +, so add."))
        XCTAssertEqual(typeAll(&l, [("x", "22")]), .moved(6))
        XCTAssertEqual(l.words.say, "Every x is 4, so 3x is 3 rows of 4.")
    }

    func testEvalGenerator() {
        each(Eval6.spec, 0) { x in let s = Eval6.Parts(x); XCTAssertTrue([s.a, s.b, s.x, s.y].allSatisfy { $0 <= 5 }); XCTAssertEqual(s.cap, 6) }
        each(Eval6.spec, 4) { x in let s = Eval6.Parts(x); XCTAssertTrue((2...9).contains(s.a) && (1...9).contains(s.x)); XCTAssertLessThanOrEqual(s.x, s.cap) }
        let c = checks(Eval6.spec).map(Eval6.Parts.init)
        XCTAssertTrue(c[2].x == 1 || c[2].y == 1)
    }

    // MARK: Equivalent expressions

    func testEquivCombine() {
        var l = LessonRun(Equiv6.spec, numbers: Equiv6.numbers(kind: 0, k: 3))
        XCTAssertEqual(l.words.say, "Slide them together. Drag the bottom strip up.")
        _ = l.go()
        XCTAssertEqual(move(&l, ["x": 0]), .notYet("Slide them all together."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(2))
        XCTAssertEqual(l.step.answer?.prompt.first, .text("x + x + x"))
        XCTAssertEqual(typeAll(&l, [("c", "2")]), .notYet("Count the rows: each row is one x."))
        XCTAssertEqual(typeAll(&l, [("c", "3")]), .moved(3))
        XCTAssertEqual(move(&l, ["t": 1]), .notYet("Drag x. Try two lengths: see both sides each time."))
        XCTAssertEqual(l.misses, 0)
        XCTAssertEqual(move(&l, ["t": 2]), .moved(4))
        XCTAssertEqual(l.words.say, "3 rows of x are 3x, whatever x is.")
    }

    func testEquivDistributeAndFactor() {
        var l = LessonRun(Equiv6.spec, numbers: Equiv6.numbers(kind: 1, a: 3, b: 4))
        _ = l.go()
        XCTAssertEqual(move(&l, ["x": -1]), .notYet("Cut all the way down."))
        XCTAssertEqual(move(&l, ["x": 0]), .notYet("Cut where x ends."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(2))
        XCTAssertEqual(typeAll(&l, [("c", "3"), ("d", "4")]), .notYet("Every row has 4 too: 3 rows of 4."))
        XCTAssertEqual(typeAll(&l, [("c", "1"), ("d", "12")]), .notYet("3 rows of x make 3x."))
        XCTAssertEqual(typeAll(&l, [("c", "3"), ("d", "12")]), .moved(3))
        XCTAssertEqual(Equiv6.Parts(l.numbers).sides(7).0, 33)
        XCTAssertEqual(Equiv6.Parts(l.numbers).sides(7).1, 33)

        var f = LessonRun(Equiv6.spec, numbers: Equiv6.numbers(kind: 2, g: 4, m: 1, n: 3))
        let s = Equiv6.Parts(f.numbers)
        XCTAssertEqual(s.shown, "4x + 12")
        _ = f.go()
        XCTAssertEqual(move(&f, ["x": 1]), .notYet("Drag the bottom edge down to make rows."))
        XCTAssertEqual(move(&f, ["x": 2]), .notYet("That fits, but more rows fit too."))
        XCTAssertEqual(move(&f, ["x": 3]), .notYet("Not every row gets the same."))
        XCTAssertEqual(move(&f, ["x": 4]), .moved(2))
        XCTAssertEqual(f.step.answer?.boxes, ["g", "n"])
        XCTAssertEqual(typeAll(&f, [("g", "2"), ("n", "6")]), .notYet("That’s a common factor, but not the greatest."))
        XCTAssertEqual(typeAll(&f, [("g", "4"), ("n", "2")]), .notYet("Write what one row holds."))
        XCTAssertEqual(typeAll(&f, [("g", "4"), ("n", "3")]), .moved(3))
        XCTAssertEqual(Equiv6.Parts(Equiv6.numbers(kind: 2, g: 3, m: 2, n: 1)).why, "3 rows of 2x + 1 are 6x + 3, whatever x is.")
    }

    func testEquivPair() {
        var l = LessonRun(Equiv6.spec, numbers: Equiv6.numbers(kind: 3, a: 2, b: 3, same: false))
        XCTAssertEqual(Equiv6.Parts(l.numbers).shown, "2(x + 3) and 2x + 3")
        _ = l.go()
        XCTAssertEqual(move(&l, ["t": 1]), .moved(2))
        XCTAssertEqual(l.step.answer?.choices ?? [], ["Same", "Not the same"])
        l.choose(0)
        XCTAssertEqual(l.go(), .notYet("Look at the two numbers: they’re different, so not the same."))
        l.choose(1)
        XCTAssertEqual(l.go(), .moved(3))
        XCTAssertEqual(l.words.say, "2(x + 3) is 2x + 6, not 2x + 3.")
    }

    func testEquivGenerator() {
        each(Equiv6.spec, 0) { XCTAssertEqual(Equiv6.Parts($0).k, 3) }
        each(Equiv6.spec, 4) { x in let s = Equiv6.Parts(x); XCTAssertEqual(s.kind, 1); XCTAssertLessThanOrEqual(2 * (s.xCap + s.b), 42) }
        each(Equiv6.spec, 6) { x in
            let s = Equiv6.Parts(x)
            XCTAssertEqual(s.kind, 2)
            XCTAssertEqual(Expr6.gcd(s.m, s.n), 1)
            XCTAssertLessThanOrEqual(s.g * (2 * s.m + s.n), 21)
            let (p, q) = s.sides(5); XCTAssertEqual(p, q)
        }
        each(Equiv6.spec, 7) { XCTAssertEqual(Equiv6.Parts($0).kind, 3) }
    }
}
