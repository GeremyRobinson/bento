import Foundation

/// Prime or composite (g4-prime, 4.OA.4; new; design/grade4.md chapter 3, the preview design/prototype/grade4-ch3.html).
/// n from 2 to 100 (never 1, which is neither), a prime about half the time; now and then a composite with no factor 2
/// or 5 (51, 57, 91: they look prime), and some with many pairs (60, 72, 96, every pair found).
///
/// On the paper: one square is one. n squares in rows of ten, named n. Drag the bottom edge down to try 2 rows, 3 rows,
/// …: they flow into that many rows, leftovers dashed; let go on a rectangle and it turns green and its pair is written.
/// Only the try is drawn. Once the rows would outnumber a row's squares the tries stop: any rectangle from there is one
/// found already, turned round. Then tap Prime or Composite.
///
/// Every step's picture has "at": 0 the question, 1 the tries, 2 Prime or Composite, 3 done.
public enum PrimeComposite {
    public static func numbers(n: Int) -> Numbers { ["n": Double(n)] }
    public static func isPrime(_ n: Int) -> Bool { n >= 2 && Factors.small(n).count == 1 }
    static func composite(_ n: Int) -> Bool { n > 3 && !isPrime(n) }
    static func upto(_ lo: Int, _ hi: Int, _ f: @escaping (Int) -> Bool) -> [Int] { (lo...hi).filter(f) }
    /// Composites with no factor 2 or 5: they look prime.
    public static let looks = upto(4, 100) { composite($0) && $0 % 2 != 0 && $0 % 5 != 0 }
    /// Four or more factor pairs.
    public static let many = upto(4, 100) { Factors.small($0).count >= 4 }

    public struct Parts: Sendable {
        public let n: Int
        public init(_ x: Numbers) { n = max(2, Int((x["n"] ?? 51).rounded())) }
        public var prime: Bool { isPrime(n) }
        /// Every pair, the small one first: 1 × n, then the rectangles.
        public var pairs: [(Int, Int)] { Factors.small(n).map { ($0, n / $0) } }
        /// The rows that make a rectangle (2 or more).
        public var rects: [Int] { Array(Factors.small(n).dropFirst()) }
        /// The tries stop here: past the square root, the rows outnumber a row's squares.
        public var stop: Int { Int(Double(n).squareRoot()) + 1 }
        /// The rows found, as one number (bit R for R rows).
        public static func mask(_ rows: [Int]) -> Int { rows.reduce(0) { $0 | (1 << $1) } }
        public var all: Int { Self.mask(rects) }

        /// What letting go at R rows says, with `found` (a mask) the rectangles let go on so far.
        public func tried(_ R: Int, found: Int) -> Verdict {
            if R >= stop {
                if let miss = rects.first(where: { found & (1 << $0) == 0 }) { return .wrong("You passed one: \(miss) rows make a rectangle. Let go on it.") }
                return .right
            }
            let g = Factors.arrange(n, R)
            return g.L > 0 ? .soft("\(R) rows leave \(g.L) over: not a rectangle.") : .soft("Keep trying more rows.")
        }
        /// What a wrong pick says.
        public var notQuite: String {
            if !prime { return "\(n) makes \(rects[0]) rows of \(n / rects[0]). More than one rectangle: composite." }
            return n == 2 ? "2 makes only one rectangle, 1 × 2. Prime." : "Only 1 row made a rectangle. Prime."
        }
    }

    /// The preview's generator. Index < 3: 5–30, a prime, a composite, either. Then a composite with no factor 2 or 5, a
    /// prime over 50, one with four or more pairs; after that a prime half the time, else a look-prime, a many-pairs or
    /// any composite.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        func pick(_ a: [Int]) -> Int { a[Int.random(in: 0..<a.count, using: &rng)] }
        if index < 3 {
            let pool = (5...30).filter { index == 0 ? isPrime($0) : index == 1 ? composite($0) : true }
            return numbers(n: pick(pool))
        }
        if index < 6 { return numbers(n: pick([looks, upto(51, 100, isPrime), many][index - 3])) }
        if Bool.random(using: &rng) { return numbers(n: pick(upto(2, 100, isPrime))) }
        return numbers(n: pick([looks, many, upto(4, 100, composite)][Int.random(in: 0...2, using: &rng)]))
    }

    public static let spec = LessonSpec(id: "g4-prime", title: "Prime or composite", master: "squares",
        generate: { rng, index in make(&rng, index) },
        display: { x in [.num(Double(Parts(x).n))] },
        idea: { _ in "A prime makes only one rectangle; a composite makes more." },
        depends: ["g4-factors"],
        check: [CheckItem(0), CheckItem(3), CheckItem(4), CheckItem(5)]) { x in
        let s = Parts(x), n = s.n
        var steps = [LessonStep(StepWords(say: "Is \(n) prime or composite?", hint: "Find every rectangle \(n) squares make.", action: "Let’s find out"),
                                picture: ["at": 0])]
        // the tries: the box is the rows let go at, and "f" the rectangles found so far
        let hint = s.rects.isEmpty ? "Try every number of rows up to \(s.stop)." : "Let go on \(s.rects.map(String.init).joined(separator: ", ")) rows."
        steps.append(LessonStep(StepWords(say: "Can \(n) squares make a rectangle? Drag the bottom edge down: 2 rows, 3 rows, …", hint: hint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x"), .box("f")], expected: ["x": Double(s.stop), "f": Double(s.all)], hint: hint,
                               explain: s.prime ? "Only 1 row of \(n)." : s.pairs.map { "\($0.0) × \($0.1)" }.joined(separator: ", ") + ".",
                               check: { v in
                                   guard let r = v["x"] else { return .soft("Drag the bottom edge down.") }
                                   return s.tried(Int(r.rounded()), found: Int((v["f"] ?? 0).rounded()))
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        // Prime or Composite, tapped: the box is the choice (0 Prime, 1 Composite)
        let want = s.prime ? 0.0 : 1
        steps.append(LessonStep(StepWords(say: "Is \(n) prime or composite? From here, any rectangle is one you’ve found, turned round.",
                                          hint: s.prime ? "Only one rectangle." : "More than one rectangle.", action: "Check"),
            answer: AnswerTask(prompt: [.box("c")], expected: ["c": want], hint: s.prime ? "Only one rectangle." : "More than one rectangle.",
                               explain: s.prime ? "\(n) is prime." : "\(n) is composite.",
                               check: { v in
                                   guard let c = v["c"] else { return .soft("Tap Prime or Composite.") }
                                   return c == want ? .right : .wrong(s.notQuite)
                               }, byHand: true),
            picture: ["at": 2]))
        steps.append(LessonStep(StepWords(say: s.prime ? "Only one rectangle: prime." : "More than one rectangle: composite.",
                                          hint: "A prime makes only one rectangle; a composite makes more.", action: "Next problem"), picture: ["at": 3]))
        return steps
    }
}
