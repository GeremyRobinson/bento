import XCTest
@testable import ObentoCore

/// 4th grade, chapter 3: Factors and patterns (design/grade4.md, the preview design/prototype/grade4-ch3.html).
final class FactorsPatternsTests: XCTestCase {
    private func move(_ l: inout LessonRun, _ set: [String: Double]) -> LessonRun.Outcome {
        l.reset(); for (k, v) in set { l.set(k, v) }; return l.go()
    }
    private func type(_ l: inout LessonRun, _ x: Int) -> LessonRun.Outcome {
        l.reset(); for ch in String(x) { l.type(String(ch)) }; return l.go()
    }
    private func each(_ spec: LessonSpec, _ index: Int, _ count: Int = 300, _ body: (Numbers) -> Void) {
        var rng = SeededRandom(seed: UInt64(77 + index))
        for _ in 0..<count { body(spec.generate(&rng, index)) }
    }
    private func checks(_ spec: LessonSpec) -> [Numbers] {
        var rng = SeededRandom(seed: 9)
        return spec.check.map { $0.draw(spec, using: &rng) }
    }

    func testOnTheMap() {
        let ch = Curriculum.chapters(4)[2]
        XCTAssertEqual(ch.title, "Factors and patterns")
        XCTAssertTrue(Curriculum.built(ch))
        for l in ch.lessons { XCTAssertEqual(Lessons.spec(l.id)?.title, l.name) }
    }

    // MARK: Factors and multiples

    func testFactorMaths() {
        XCTAssertEqual(Factors.small(20), [1, 2, 4])
        XCTAssertEqual(Factors.all(20), [1, 2, 4, 5, 10, 20])
        XCTAssertEqual(Factors.all(16), [1, 2, 4, 8, 16])
        XCTAssertEqual(Factors.choices.prefix(5), [12, 16, 18, 20, 28])
        XCTAssertEqual(Factors.rows(20, 3), "3 rows of 6, 2 over")
        XCTAssertEqual(Factors.rows(20, 1), "1 row of 20")
        XCTAssertEqual(Factors.rows(20, 4), "4 rows of 5")
    }

    func testFactorsNotAMultiple() {
        var l = LessonRun(Factors.spec, numbers: Factors.numbers(n: 20, t: 3))
        XCTAssertEqual(l.words.say, "Find the factor pairs of 20.")
        _ = l.go()
        XCTAssertEqual(l.words.say, "Make a rectangle with the squares. Drag the bottom edge down.")
        XCTAssertTrue(l.handAnswered)
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("3 rows leave 2 over: not a rectangle."))
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("4 rows make one too, but there’s one with fewer rows."))
        XCTAssertEqual(move(&l, ["x": 2]), .moved(2))
        XCTAssertEqual(l.words.say, "Make another rectangle. Drag the bottom edge down.")
        XCTAssertEqual(move(&l, ["x": 2]), .notYet("2 rows: you found that one. Try more rows."))
        XCTAssertEqual(move(&l, ["x": 5]), .notYet("5 rows make one too, but there’s one with fewer rows."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(3))
        XCTAssertEqual(l.words.say, "Is 20 a multiple of 3? Hop by 3s along the row.")
        XCTAssertEqual(move(&l, ["x": 6]), .notYet("2 left on the row: hop on to its end."))
        XCTAssertEqual(move(&l, ["x": 7]), .moved(4))
        XCTAssertEqual(l.words.say, "Is 20 a multiple of 3? Tap Yes or No.")
        XCTAssertEqual(move(&l, ["c": 0]), .notYet("Count by 3s: 18, then 21. You skip over 20, with 2 left."))
        XCTAssertEqual(move(&l, ["c": 1]), .moved(5))
        XCTAssertEqual(l.words.say, "How many factors are there? Count both numbers of every pair.")
        XCTAssertEqual(type(&l, 3), .notYet("There are 3 pairs, but each pair has two factors."))
        XCTAssertEqual(type(&l, 4), .notYet("1 and 20 are factors too: 1 × 20 = 20."))
        XCTAssertEqual(type(&l, 5), .notYet("Count the numbers in the list."))
        XCTAssertEqual(type(&l, 6), .moved(6))
        XCTAssertEqual(l.words.say, "Each rectangle is a factor pair.")
    }

    func testFactorsSquareAndMultiple() {
        var l = LessonRun(Factors.spec, numbers: Factors.numbers(n: 16, t: 8))
        _ = l.go()
        XCTAssertEqual(move(&l, ["x": 2]), .moved(2))
        XCTAssertEqual(move(&l, ["x": 3]), .notYet("3 rows leave 1 over: not a rectangle."))
        XCTAssertEqual(move(&l, ["x": 4]), .moved(3))
        XCTAssertEqual(move(&l, ["x": 2]), .moved(4))
        XCTAssertEqual(move(&l, ["c": 1]), .notYet("Count by 8s: you land right on 16."))
        XCTAssertEqual(move(&l, ["c": 0]), .moved(5))
        XCTAssertEqual(type(&l, 3), .notYet("There are 3 pairs, but each pair has two factors, except 4 × 4, which uses 4 once."))
        XCTAssertEqual(type(&l, 6), .notYet("4 × 4 uses the same factor twice. Count 4 only once."))
        XCTAssertEqual(type(&l, 5), .moved(6))
    }

    func testFactorsGenerator() {
        for i in 0..<9 {
            each(Factors.spec, i) { x in
                let s = Factors.Parts(x)
                XCTAssertEqual(Factors.small(s.n).count, 3)
                XCTAssertTrue((12...(i < 3 ? 32 : 60)).contains(s.n))
                XCTAssertTrue((3...9).contains(s.t))
                XCTAssertFalse(Factors.small(s.n).contains(s.t))
                XCTAssertLessThanOrEqual(2 * s.t, s.n)
                XCTAssertGreaterThan(s.maxR, s.a2)
            }
        }
        var yes = 0
        each(Factors.spec, 4, 400) { if Factors.Parts($0).isMultiple { yes += 1 } }
        XCTAssertTrue((100...300).contains(yes), "\(yes)")
        let c = checks(Factors.spec).map(Factors.Parts.init)
        XCTAssertTrue(c[0].isMultiple); XCTAssertFalse(c[1].isMultiple); XCTAssertEqual(c[2].n, 16); XCTAssertGreaterThan(c[3].n, 32)
    }

    // MARK: Prime or composite

    func testPrimeComposite() {
        var l = LessonRun(PrimeComposite.spec, numbers: PrimeComposite.numbers(n: 51))
        XCTAssertEqual(l.words.say, "Is 51 prime or composite?")
        _ = l.go()
        XCTAssertEqual(l.words.say, "Can 51 squares make a rectangle? Drag the bottom edge down: 2 rows, 3 rows, …")
        let P = PrimeComposite.Parts(l.numbers)
        XCTAssertEqual(P.stop, 8); XCTAssertEqual(P.rects, [3])
        XCTAssertEqual(move(&l, ["x": 2, "f": 0]), .notYet("2 rows leave 1 over: not a rectangle."))
        XCTAssertEqual(move(&l, ["x": 3, "f": 8]), .notYet("Keep trying more rows."))
        XCTAssertEqual(l.misses, 0)
        XCTAssertEqual(move(&l, ["x": 8, "f": 0]), .notYet("You passed one: 3 rows make a rectangle. Let go on it."))
        XCTAssertEqual(l.misses, 1)
        XCTAssertEqual(move(&l, ["x": 8, "f": 8]), .moved(2))
        XCTAssertEqual(l.words.say, "Is 51 prime or composite? From here, any rectangle is one you’ve found, turned round.")
        XCTAssertEqual(move(&l, ["c": 0]), .notYet("51 makes 3 rows of 17. More than one rectangle: composite."))
        XCTAssertEqual(move(&l, ["c": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "More than one rectangle: composite.")

        var p = LessonRun(PrimeComposite.spec, numbers: PrimeComposite.numbers(n: 29))
        _ = p.go()
        XCTAssertEqual(move(&p, ["x": 6, "f": 0]), .moved(2))
        XCTAssertEqual(move(&p, ["c": 1]), .notYet("Only 1 row made a rectangle. Prime."))
        XCTAssertEqual(move(&p, ["c": 0]), .moved(3))
        XCTAssertEqual(p.words.say, "Only one rectangle: prime.")

        var two = LessonRun(PrimeComposite.spec, numbers: PrimeComposite.numbers(n: 2))
        _ = two.go()
        XCTAssertEqual(move(&two, ["x": 2, "f": 0]), .moved(2))
        XCTAssertEqual(move(&two, ["c": 1]), .notYet("2 makes only one rectangle, 1 × 2. Prime."))
        XCTAssertEqual(PrimeComposite.Parts(PrimeComposite.numbers(n: 96)).rects, [2, 3, 4, 6, 8])
    }

    func testPrimeGenerator() {
        for i in 0..<12 {
            each(PrimeComposite.spec, i) { x in
                let n = PrimeComposite.Parts(x).n
                XCTAssertTrue((2...100).contains(n))
                switch i {
                case 0: XCTAssertTrue(PrimeComposite.isPrime(n) && n >= 5 && n <= 30)
                case 1: XCTAssertTrue(!PrimeComposite.isPrime(n) && n >= 5 && n <= 30)
                case 2: XCTAssertTrue(n >= 5 && n <= 30)
                case 3: XCTAssertTrue(!PrimeComposite.isPrime(n) && n % 2 != 0 && n % 5 != 0)
                case 4: XCTAssertTrue(PrimeComposite.isPrime(n) && n > 50)
                case 5: XCTAssertGreaterThanOrEqual(Factors.small(n).count, 4)
                default: break
                }
            }
        }
        XCTAssertTrue(PrimeComposite.looks.contains(91))
        XCTAssertFalse(PrimeComposite.looks.contains(1))
    }

    // MARK: Number and shape patterns

    func testNumberRule() {
        var l = LessonRun(Patterns.spec, numbers: Patterns.number(s: 1, d: 3, k: 20))
        XCTAssertEqual(l.words.say, "Start at 1. Add 3.")
        _ = l.go()
        XCTAssertEqual(l.words.say, "Start at 1. Add 3. Drag each hop out from the last number.")
        let P = Patterns.Parts(l.numbers)
        XCTAssertEqual(P.vals, [1, 4, 7, 10, 13, 16]); XCTAssertEqual(P.want, [1, 7, 13])
        XCTAssertEqual(move(&l, ["x": 4]), .notYet("That hop is 4. The rule adds 3."))
        XCTAssertEqual(move(&l, ["x": 3]), .moved(2))
        XCTAssertEqual(l.words.say, "Tap the odd numbers.")
        XCTAssertEqual(move(&l, ["x": 1010]), .notYet("10 is even: it’s 5 twos."))
        XCTAssertEqual(move(&l, ["x": 1004]), .notYet("4 is even: it’s 2 twos."))
        XCTAssertEqual(move(&l, ["x": 1]), .moved(3))
        XCTAssertEqual(l.words.say, "Will the 20th number be odd or even? Tap one.")
        XCTAssertEqual(move(&l, ["c": 0]), .notYet("Odd, even, odd, even: it repeats every 2, so the 20th is like the 2nd."))
        XCTAssertEqual(move(&l, ["c": 1]), .moved(4))
        XCTAssertEqual(l.words.say, "Adding 3 turns odd into even and back.")

        var e = LessonRun(Patterns.spec, numbers: Patterns.number(s: 3, d: 4, k: 11))
        _ = e.go(); _ = move(&e, ["x": 4]); _ = move(&e, ["x": 1])
        XCTAssertEqual(move(&e, ["c": 1]), .notYet("Odd, odd, odd: adding 4 keeps odd numbers odd."))
        XCTAssertEqual(move(&e, ["c": 0]), .moved(4))
        XCTAssertEqual(e.words.say, "Adding 4 keeps odd numbers odd.")
        XCTAssertEqual(Patterns.ord(22), "22nd"); XCTAssertEqual(Patterns.ord(13), "13th"); XCTAssertEqual(Patterns.ord(21), "21st")
    }

    func testShapeRule() {
        var l = LessonRun(Patterns.spec, numbers: Patterns.shape(sk: 2, f: 3, d: 2, q: 10))
        XCTAssertEqual(l.words.say, "Build shape 4.")
        _ = l.go()
        XCTAssertEqual(l.words.say, "Build shape 4. Tap squares to add them. Each shape has 2 more than the last.")
        let P = Patterns.Parts(l.numbers)
        XCTAssertEqual((1...4).map { P.cells($0).count }, [3, 5, 7, 9])
        XCTAssertEqual(move(&l, ["x": 8]), .notYet("Shape 4 has 2 more than shape 3: 9."))
        XCTAssertEqual(move(&l, ["x": 9]), .moved(2))
        XCTAssertEqual(l.words.say, "How many squares will shape 10 have? Drag out copies of the new squares.")
        XCTAssertEqual(move(&l, ["x": 9]), .notYet("That’s shape 9. One more copy."))
        XCTAssertEqual(move(&l, ["x": 12]), .notYet("That’s shape 12. 2 copies too many."))
        XCTAssertEqual(move(&l, ["x": 10]), .moved(3))
        XCTAssertEqual(type(&l, 20), .notYet("10 × 2 forgets that shape 1 starts with 3."))
        XCTAssertEqual(type(&l, 19), .notYet("19 is shape 9. Shape 10 has one more copy."))
        XCTAssertEqual(type(&l, 23), .notYet("23 is shape 11. Shape 10 has one copy fewer."))
        XCTAssertEqual(type(&l, 22), .notYet("Count the row: 3, and 9 copies of 2."))
        XCTAssertEqual(type(&l, 21), .moved(4))
        XCTAssertEqual(l.words.say, "9 more shapes add 9 × 2 to the first one.")
    }

    func testShapesAreTheirCounts() {
        for sk in 0...2 {
            for f in 1...5 {
                for d in 1...4 {
                    if sk == 1 && (f % 2 == 0 || d % 2 == 1) { continue }
                    let P = Patterns.Parts(Patterns.shape(sk: sk, f: f, d: d, q: 8))
                    for j in 1...4 {
                        let c = P.cells(j)
                        XCTAssertEqual(c.count, P.count(j), "sk \(sk) f \(f) d \(d) shape \(j)")
                        XCTAssertEqual(Set(c.map { "\($0.x),\($0.y)" }).count, c.count)
                        // each shape is the last one and its new squares
                        if j > 1 { XCTAssertEqual(c.filter { $0.g == j - 1 }.count, d) }
                        if j > 1 { XCTAssertTrue(Set(P.cells(j - 1).map { "\($0.x),\($0.y)" }).isSubset(of: Set(c.map { "\($0.x),\($0.y)" }))) }
                    }
                }
            }
        }
    }

    func testPatternsGenerator() {
        for i in 0..<10 {
            let kind = i < 3 ? [0, 1, 2][i] : [1, 0, 1, 2][(i - 3) % 4]
            each(Patterns.spec, i) { x in
                let P = Patterns.Parts(x)
                XCTAssertEqual(P.kind, kind)
                if P.isShape {
                    XCTAssertTrue((6...12).contains(P.q)); XCTAssertTrue((1...4).contains(P.d))
                    if P.sk == 0 { XCTAssertLessThanOrEqual(P.n4, 11) }
                    if P.sk == 1 { XCTAssertEqual(P.f % 2, 1); XCTAssertEqual(P.d % 2, 0) }
                } else {
                    XCTAssertEqual(P.d % 2, kind == 0 ? 1 : 0)
                    XCTAssertLessThanOrEqual(P.vals.last!, 60)
                    XCTAssertTrue((10...30).contains(P.k))
                }
            }
        }
        XCTAssertEqual(checks(Patterns.spec).map { Patterns.Parts($0).kind }, [0, 2, 1, 1])
    }
}
