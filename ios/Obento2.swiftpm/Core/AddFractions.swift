import Foundation

/// Add with different bottoms: p/a + q/b, where b is a multiple of a. The picture is the problem: a row of a-ths
/// over a row of b-ths, both one whole long. The child shades b-ths until they cover p/a, then adds q more, and reads the total.
public struct AddFractions: Sendable {
    public struct Problem: Equatable, Sendable {
        public let a: Int, p: Int, b: Int, q: Int
        public init(a: Int, p: Int, b: Int, q: Int) { self.a = a; self.p = p; self.b = b; self.q = q }
        /// How many b-ths one a-th is.
        public var k: Int { b / a }
        /// How many b-ths cover p/a.
        public var covered: Int { p * k }
        public var total: Int { covered + q }
        /// The whole's length in grid cells, so every piece sits on the grid.
        public var wholeCells: Int { b == 6 ? 18 : b == 10 ? 20 : 16 }
        public var sum: String { "\(p)/\(a) + \(q)/\(b)" }
    }

    public enum Step: Equatable, Sendable {
        case ask
        /// Shade b-ths until they cover p/a.
        case cover
        /// Add q more b-ths.
        case add
        case done
    }

    public enum Outcome: Equatable, Sendable {
        case moved(Step)
        /// Check pressed with the wrong count; the line to show.
        case notYet(String)
        case newProblem
    }

    public let problem: Problem
    public private(set) var step: Step = .ask
    /// The b-ths shaded to cover p/a, by position in the row.
    public private(set) var shaded: Set<Int> = []
    /// The b-ths added on.
    public private(set) var added: Set<Int> = []

    public init(problem: Problem) { self.problem = problem }

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

    public static func generate<R: RandomNumberGenerator>(using rng: inout R) -> AddFractions {
        AddFractions(problem: problems.randomElement(using: &rng)!)
    }

    public var words: StepWords {
        let s = problem, A = Self.amount(s.p, s.a), B = Self.amount(s.q, s.b), the = target
        switch step {
        case .ask:
            return StepWords(say: "\(Self.capital(A)) and \(B).", hint: "How much is that together? Look at the picture.", action: "Let’s find out")
        case .cover:
            return StepWords(say: "\(s.p)/\(s.a) is how many \(Self.plural(s.b))?", hint: "Tap the \(Self.plural(s.b)) until they cover \(the).", action: "Check")
        case .add:
            return StepWords(say: "Now add \(s.q)/\(s.b). How many \(Self.plural(s.b))?",
                             hint: s.q == 1 ? "Tap one more \(Self.name(s.b)) to add it on." : "Tap \(Self.number(s.q)) more \(Self.plural(s.b)) to add them on.", action: "Check")
        case .done:
            let verb = s.p == 1 ? "covers" : "cover"
            return StepWords(say: "\(Self.capital(Self.amount(s.total, s.b, words: true))).",
                             hint: "\(Self.capital(A)) \(verb) \(Self.number(s.covered)) \(Self.plural(s.b)). Add \(Self.number(s.q)) more and you have \(Self.number(s.total)).",
                             action: "Next problem")
        }
    }

    /// The count under the picture while the child works.
    public var countLine: String { "\(shaded.count + added.count) of \(problem.b) shaded" }

    /// "the fourth", "the 3 fourths": the part of the top row the child covers.
    var target: String { problem.p == 1 ? "the \(Self.name(problem.a))" : "the \(problem.p) \(Self.plural(problem.a))" }

    /// What p/a covers in the bottom row, for the guide line after a wrong count.
    public var guideLine: String { problem.p == 1 ? "The \(Self.name(problem.a)) ends here" : "The \(problem.p) \(Self.plural(problem.a)) end here" }

    /// Tapping a b-th shades it, tapping again clears it. While adding, the shaded ones stay put.
    @discardableResult
    public mutating func tap(_ i: Int) -> Bool {
        guard (0..<problem.b).contains(i) else { return false }
        switch step {
        case .cover: if shaded.contains(i) { shaded.remove(i) } else { shaded.insert(i) }
        case .add:
            guard !shaded.contains(i) else { return false }
            if added.contains(i) { added.remove(i) } else { added.insert(i) }
        default: return false
        }
        return true
    }

    /// The pieces "Show me" fills, one by one.
    public mutating func showMe() -> [Int] {
        switch step {
        case .cover: shaded = []; let e = Array(0..<problem.covered); shaded = Set(e); return e
        case .add: added = []; let e = Array(problem.covered..<problem.total); added = Set(e); return e
        default: return []
        }
    }

    public mutating func reset() {
        if step == .cover { shaded = [] }
        if step == .add { added = [] }
    }

    public mutating func go() -> Outcome {
        let s = problem, n = Self.plural(s.b), A = target
        switch step {
        case .ask: step = .cover
        case .cover:
            if shaded.count < s.covered { return .notYet("Not yet. Some of \(A) is still uncovered.") }
            if shaded.count > s.covered { return .notYet("Too many. Some \(n) go past \(A).") }
            // the shaded pieces line up under the fraction they cover
            shaded = Set(0..<s.covered); step = .add
        case .add:
            if added.isEmpty { return .notYet(s.q == 1 ? "Add the extra \(Self.name(s.b)) first." : "Add the \(Self.number(s.q)) extra \(n) first.") }
            if added.count < s.q { return .notYet("Not yet. Add \(Self.number(s.q - added.count)) more.") }
            if added.count > s.q { return .notYet(s.q == 1 ? "Only one \(Self.name(s.b)) is being added." : "Only \(Self.number(s.q)) \(n) are being added.") }
            step = .done
        case .done: return .newProblem
        }
        return .moved(step)
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
