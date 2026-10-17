import Foundation

/// Add with different bottoms: p/a + q/b, where b is a multiple of a. The picture is the problem: a row of a-ths
/// over a row of b-ths, both one whole long. The child shades b-ths until they cover p/a, then adds q more, and reads the total.
/// Numbers: a, p, b, q. Cells are the b-ths of the bottom row, left to right.
public enum AddFractions {
    public struct Problem: Equatable, Sendable {
        public let a: Int, p: Int, b: Int, q: Int
        public init(a: Int, p: Int, b: Int, q: Int) { self.a = a; self.p = p; self.b = b; self.q = q }
        public init(_ n: Numbers) { self.init(a: Int(n["a"] ?? 1), p: Int(n["p"] ?? 0), b: Int(n["b"] ?? 1), q: Int(n["q"] ?? 0)) }
        public var numbers: Numbers { ["a": Double(a), "p": Double(p), "b": Double(b), "q": Double(q)] }
        /// How many b-ths one a-th is.
        public var k: Int { b / a }
        /// How many b-ths cover p/a.
        public var covered: Int { p * k }
        public var total: Int { covered + q }
        /// The whole's length in grid cells, so every piece sits on the grid.
        public var wholeCells: Int { b == 6 ? 18 : b == 10 ? 20 : 16 }
        public var sum: String { "\(p)/\(a) + \(q)/\(b)" }
    }

    /// Every problem that keeps the picture on the grid and every fraction, the answer too, in lowest terms.
    public static let problems: [Problem] = {
        var out: [Problem] = []
        for b in [4, 6, 8, 10] { for a in 2..<b where b % a == 0 {
            for p in 1..<a where gcd(p, a) == 1 { for q in 1..<b where gcd(q, b) == 1 {
                let s = Problem(a: a, p: p, b: b, q: q)
                if s.total < b, gcd(s.total, b) == 1 { out.append(s) }
            } }
        } }
        return out
    }()

    public static let spec = LessonSpec(id: "ad", title: "Add with different bottoms", master: "bars",
                                        generate: { rng, _ in problems.randomElement(using: &rng)!.numbers }) { n in
        let s = Problem(n), A = amount(s.p, s.a), B = amount(s.q, s.b), names = plural(s.b)
        // "the fourth", "the 3 fourths": the part of the top row the child covers
        let the = s.p == 1 ? "the \(name(s.a))" : "the \(s.p) \(plural(s.a))"
        let shaded: @Sendable (Int) -> String = { "\($0) of \(s.b) shaded" }
        let ask = LessonStep(StepWords(say: "\(capital(A)) and \(B).", hint: "How much is that together? Look at the picture.", action: "Let’s find out"))
        let cover = LessonStep(StepWords(say: "\(s.p)/\(s.a) is how many \(names)?", hint: "Tap the \(names) until they cover \(the).", action: "Check"),
            task: MarkTask(cells: Set(0..<s.b), want: s.covered, showMe: Array(0..<s.covered), snap: Array(0..<s.covered),
                           mistakes: [Mistake(.tooFew) { _, _ in "Not yet. Some of \(the) is still uncovered." },
                                      Mistake(.tooMany) { _, _ in "Too many. Some \(names) go past \(the)." }],
                           count: shaded),
            // hint 1: the child's count drawn beside where the fraction really ends; hint 2: the right pieces outlined
            onMiss: ["guide": 1, "yours": 1], look: s.p == 1 ? "The \(name(s.a)) ends here" : "The \(s.p) \(plural(s.a)) end here",
            hint2: ["outline": 1])
        let add = LessonStep(StepWords(say: "Now add \(s.q)/\(s.b). How many \(names)?",
                                       hint: s.q == 1 ? "Tap one more \(name(s.b)) to add it on." : "Tap \(number(s.q)) more \(names) to add them on.", action: "Check"),
            task: MarkTask(cells: Set(0..<s.b), want: s.q, showMe: Array(s.covered..<s.total),
                           mistakes: [Mistake(.noneMarked) { _, _ in s.q == 1 ? "Add the extra \(name(s.b)) first." : "Add the \(number(s.q)) extra \(names) first." },
                                      Mistake(.tooFew) { m, w in "Not yet. Add \(number(w - m)) more." },
                                      Mistake(.tooMany) { _, _ in s.q == 1 ? "Only one \(name(s.b)) is being added." : "Only \(number(s.q)) \(names) are being added." }],
                           style: 2, count: shaded),
            picture: ["match": 1, "waiting": 1], onMiss: ["yours": 1, "totalGuide": 1], hint2: ["outline": 1])
        let verb = s.p == 1 ? "covers" : "cover"
        let done = LessonStep(StepWords(say: "\(capital(amount(s.total, s.b, words: true))).",
                                        hint: "\(capital(A)) \(verb) \(number(s.covered)) \(names). Add \(number(s.q)) more and you have \(number(s.total)).",
                                        action: "Next problem"),
                              picture: ["match": 1, "total": 1])
        return [ask, cover, add, done]
    }

    // MARK: words

    static func name(_ d: Int) -> String {
        [2: "half", 3: "third", 4: "fourth", 5: "fifth", 6: "sixth", 8: "eighth", 9: "ninth", 10: "tenth", 12: "twelfth"][d] ?? "\(d)th"
    }
    public static func plural(_ d: Int) -> String { d == 2 ? "halves" : name(d) + "s" }
    static func number(_ n: Int) -> String {
        ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"][safe: n] ?? "\(n)"
    }
    /// "a fourth", "an eighth", "3 fourths" (or "three eighths" in words).
    static func amount(_ n: Int, _ d: Int, words: Bool = false) -> String {
        if n == 1 { return (name(d).first == "e" ? "an " : "a ") + name(d) }
        return "\(words ? number(n) : String(n)) \(plural(d))"
    }
    static func capital(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }
}

func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
