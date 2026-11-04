import Foundation

/// Factors and multiples (the web app's g4-factors, 4.OA.4; design/grade4.md chapter 3, the preview
/// design/prototype/grade4-ch3.html). The web's maths: n from 12 to 60 with exactly three factor pairs (up to 32 for the
/// first three), t 3–9 not the small half of a pair and at most n ÷ 2, a factor about half the time; its slips.
///
/// On the paper: one square is one. n squares in one long row (1 × n), and under it the same squares to arrange: drag
/// the bottom edge down and they flow into that many rows; let go on a rectangle and it stays, named (the fewest rows
/// first, then the next). Then hop by t along the long row and tap Yes or No: is n a multiple of t? Then write how many
/// factors.
///
/// Every step's picture has "at": 0 the question, 1 the first pair, 2 the second, 3 hop, 4 Yes or No, 5 write, 6 done.
public enum Factors {
    public static func numbers(n: Int, t: Int) -> Numbers { ["n": Double(n), "t": Double(t)] }

    /// The small half of each factor pair, smallest first (1 always): 20 → 1, 2, 4.
    public static func small(_ n: Int) -> [Int] { (1...max(1, Int(Double(n).squareRoot()))).filter { n % $0 == 0 && $0 * $0 <= n } }
    /// Every factor, smallest first: 20 → 1, 2, 4, 5, 10, 20.
    public static func all(_ n: Int) -> [Int] {
        let s = small(n)
        var out = s
        for a in s.reversed() where a * a != n { out.append(n / a) }
        return out
    }
    /// Numbers from 12 to 60 with exactly three factor pairs: 1 × n and two more.
    public static let choices: [Int] = (12...60).filter { small($0).count == 3 }

    /// n squares in R rows: as many in each row as fit (q), and what's left over (L).
    public static func arrange(_ n: Int, _ R: Int) -> (q: Int, L: Int) { (n / max(1, R), n - max(1, R) * (n / max(1, R))) }
    /// "1 row of 20", "3 rows of 6, 2 over" (the live readout).
    public static func rows(_ n: Int, _ R: Int) -> String {
        let g = arrange(n, R)
        return R == 1 ? "1 row of \(n)" : "\(R) rows of \(g.q)" + (g.L > 0 ? ", \(g.L) over" : "")
    }

    public struct Parts: Sendable {
        public let n: Int, t: Int
        public init(_ x: Numbers) { n = Int((x["n"] ?? 20).rounded()); t = Int((x["t"] ?? 3).rounded()) }
        /// The two pairs after 1 × n: a1 × b1 (fewer rows first), a2 × b2.
        public var a1: Int { small(n).dropFirst().first ?? 1 }
        public var a2: Int { small(n).dropFirst(2).first ?? a1 }
        public var b1: Int { n / a1 }
        public var b2: Int { n / a2 }
        public var factors: [Int] { all(n) }
        public var q: Int { n / t }
        public var r: Int { n % t }
        public var isMultiple: Bool { r == 0 }
        /// Hops along the long row to reach (or pass) its end.
        public var hopsTo: Int { (n + t - 1) / t }
        /// The most rows the bottom edge goes down to: two past the second pair, 8 at most, n ÷ 2 at most.
        public var maxR: Int { min(8, n / 2, a2 + 2) }

        /// What letting go at R rows says when looking for pair `k` (0 the first, 1 the second): nil when it's that pair.
        public func tried(_ R: Int, pair k: Int) -> String? {
            let want = k == 0 ? a1 : a2, L = arrange(n, R).L
            if R == want { return nil }
            if L > 0 { return "\(R) rows leave \(L) over: not a rectangle." }
            if k == 1 && R == a1 { return "\(R) rows: you found that one. Try more rows." }
            return "\(R) rows make one too, but there’s one with fewer rows."
        }
        /// What letting go after `h` hops says (nil: the row's end is reached or passed).
        public func hopped(_ h: Int) -> String? { h >= hopsTo ? nil : "\(n - h * t) left on the row: hop on to its end." }
        /// What a wrong Yes or No says (the web's).
        public var notQuite: String {
            isMultiple ? "Count by \(t)s: you land right on \(n)." : "Count by \(t)s: \(t * q), then \(t * (q + 1)). You skip over \(n), with \(r) left."
        }
    }

    /// The web's generator: index < 3 n up to 32; t 3–9, not the small half of a pair and at most n ÷ 2, a factor about
    /// half the time (when there is one).
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let pool = choices.filter { index < 3 ? $0 <= 32 : true }
        let n = pool[Int.random(in: 0..<pool.count, using: &rng)], s = small(n)
        let tries = (3...9).filter { !s.contains($0) && $0 * 2 <= n }
        let yes = tries.filter { n % $0 == 0 }, no = tries.filter { n % $0 != 0 }
        let pickYes = !yes.isEmpty && (Bool.random(using: &rng) || no.isEmpty)
        let from = pickYes ? yes : no
        return numbers(n: n, t: from[Int.random(in: 0..<from.count, using: &rng)])
    }

    public static let spec = LessonSpec(id: "g4-factors", title: "Factors and multiples", master: "squares",
        generate: { rng, index in make(&rng, index) },
        display: { x in [.text("factors of \(Parts(x).n)")] },
        idea: { _ in "Factors multiply to make a number, and each rectangle shows one pair." },
        depends: ["g3-facts", "g3-divfacts"],
        check: [CheckItem(0, when: { Parts($0).isMultiple }), CheckItem(3, when: { !Parts($0).isMultiple }),
                CheckItem(0, when: { Parts($0).n == 16 }), CheckItem(3, when: { Parts($0).n > 32 })]) { x in
        let s = Parts(x), n = s.n, t = s.t
        var steps = [LessonStep(StepWords(say: "Find the factor pairs of \(n).", hint: "Every number makes one long row, so 1 and \(n) are factors.",
                                          action: "Let’s find out"), picture: ["at": 0])]
        // the two pairs: the box is how many rows the bottom edge was let go at
        for (k, a) in [s.a1, s.a2].enumerated() {
            let say = (k == 0 ? "Make a rectangle with the squares." : "Make another rectangle.") + " Drag the bottom edge down."
            let hint = "Try \(a) rows."
            steps.append(LessonStep(StepWords(say: say, hint: hint, action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(a)], hint: hint, explain: "\(a) rows of \(n / a): \(a) × \(n / a) = \(n).",
                                   check: { v in
                                       guard let r = v["x"] else { return .soft("Drag the bottom edge down.") }
                                       return s.tried(Int(r.rounded()), pair: k).map { .wrong($0) } ?? .right
                                   }, byHand: true),
                picture: ["at": Double(1 + k)], onMiss: ["ring": 1]))
        }
        // hop by t along the long row: the box is how many hops
        steps.append(LessonStep(StepWords(say: "Is \(n) a multiple of \(t)? Hop by \(t)s along the row.", hint: "Each hop is \(t) squares.", action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.hopsTo)], hint: "Each hop is \(t) squares.",
                               explain: s.isMultiple ? "\(s.q) hops land on \(n)." : "\(s.q) hops reach \(t * s.q); one more passes \(n).",
                               check: { v in
                                   guard let h = v["x"] else { return .soft("Hop by \(t)s along the row.") }
                                   return s.hopped(Int(h.rounded())).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 3], onMiss: ["ring": 1]))
        // Yes or No, tapped: the box is the choice (0 Yes, 1 No)
        let yn = s.isMultiple ? 0.0 : 1
        steps.append(LessonStep(StepWords(say: "Is \(n) a multiple of \(t)? Tap Yes or No.", hint: "Count by \(t)s. Do you land exactly on \(n)?", action: "Check"),
            answer: AnswerTask(prompt: [.box("c")], expected: ["c": yn], hint: "Count by \(t)s. Do you land exactly on \(n)?",
                               explain: s.isMultiple ? "\(t) × \(s.q) = \(n), so yes." : "\(t) × \(s.q) = \(t * s.q) and \(s.r) left over, so no.",
                               check: { v in
                                   guard let c = v["c"] else { return .soft("Tap Yes or No.") }
                                   return c == yn ? .right : .wrong(s.notQuite)
                               }, byHand: true),
            picture: ["at": 4]))
        // how many factors, typed, with the web's slips
        let np = 3, want = s.factors.count, square = s.a2 == s.b2
        var slips: [(Double, String)] = [(Double(np), "There are \(np) pairs, but each pair has two factors\(square ? ", except \(s.a2) × \(s.a2), which uses \(s.a2) once" : "").")]
        if square { slips.append((Double(2 * np), "\(s.a2) × \(s.a2) uses the same factor twice. Count \(s.a2) only once.")) }
        slips.append((Double(want - 2), "1 and \(n) are factors too: 1 × \(n) = \(n)."))
        let whint = "Write each pair: 1 and \(n), \(s.a1) and \(s.b1), \(s.a2) and \(s.b2). Count them all."
        steps.append(LessonStep(StepWords(say: "How many factors are there? Count both numbers of every pair.", hint: whint, action: "Check"),
            answer: AnswerTask(prompt: [.text("factors of"), .num(Double(n)), .op("="), .box("x")], expected: ["x": Double(want)],
                               known: BigNumbers.slips(Double(want), slips), hint: whint,
                               explain: "The factors of \(n) are \(s.factors.map(String.init).joined(separator: ", ")). That’s \(want).",
                               check: { v in Int((v["x"] ?? -1).rounded()) == want ? .right : .wrong("Count the numbers in the list.") },
                               incomplete: "Type the number in the box."),
            picture: ["at": 5]))
        steps.append(LessonStep(StepWords(say: "Each rectangle is a factor pair.", hint: "Factors multiply to make a number, and each rectangle shows one pair.",
                                          action: "Next problem"), picture: ["at": 6]))
        return steps
    }
}
