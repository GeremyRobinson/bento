import Foundation

/// Comparing fractions (the web app's g4-fraccompare, 4.NF.2; design/grade4.md chapter 4, the preview
/// design/prototype/grade4-ch4.html). The web's maths: a/b ? c/d, renamed over L = lcm(b, d): A/L ? C/L.
///
/// On the paper: two bars of one whole (Fractions4.whole of L), a/b shaded on top and c/d striped under it, named at their
/// right ends with ? between. Cut both with the ruler into pieces of one size (a dot under each old cut, green when a new
/// cut lands on it, red when none does); Cut's box is how many pieces make the whole. The pieces count, a dashed line
/// from each shaded end; then tap <, = or > (the box "c": 0, 1, 2).
///
/// Every step's picture has "at": 0 the question, 1 the cut, 2 the choice, 3 done.
public enum CompareFractions {
    public static func numbers(a: Int, b: Int, c: Int, d: Int) -> Numbers { ["a": Double(a), "b": Double(b), "c": Double(c), "d": Double(d)] }
    public static let signs = ["<", "=", ">"]
    static let signWords = ["less than", "equal to", "greater than"]
    static func cmp(_ x: Int, _ y: Int) -> Int { x < y ? 0 : x == y ? 1 : 2 }

    public struct Parts: Sendable {
        public let a: Int, b: Int, c: Int, d: Int
        public init(_ x: Numbers) {
            func i(_ k: String, _ v: Int) -> Int { Int((x[k] ?? Double(v)).rounded()) }
            a = i("a", 1); b = max(2, i("b", 2)); c = i("c", 1); d = max(2, i("d", 3))
        }
        public var L: Int { b / gcd(b, d) * d }
        public var A: Int { a * (L / b) }
        public var C: Int { c * (L / d) }
        /// 0 <, 1 =, 2 >.
        public var k: Int { cmp(A, C) }
        public var W: Int { Fractions4.whole(L) }
        public var p1: Int { W / b }
        public var p2: Int { W / d }
        public var pL: Int { W / L }
        /// The ruler's sizes: every length that cuts the whole evenly, 1 square up to the bigger old piece.
        public var sizes: [Int] { (1...max(p1, p2)).filter { W % $0 == 0 } }
        /// What Cut at `n` pieces in the whole says: nil when it's L.
        public func cut(_ n: Int) -> String? {
            if n == L { return nil }
            let s = W / max(1, n)
            if p1 % s != 0 || p2 % s != 0 { return "That cut misses \(Fractions4.aPiece(p1 % s != 0 ? b : d))." }
            return "Those fit. Bigger pieces fit too."
        }
        /// What a wrong sign says (the web's slips): tops compared, bigger bottom, called equal, missed equal, turned round.
        public func wrong(_ i: Int) -> String {
            let PL = Fractions4.piece(L)
            if i == 1 { return "They’d be equal only with the same number of \(PL). \(A) and \(C) are not the same." }
            if k == 1 { return "\(a)/\(b) and \(c)/\(d) are both \(A)/\(L): the same amount, cut into different pieces." }
            if cmp(a, c) == i { return "Tops only compare when the pieces are the same size." }
            if cmp(b, d) == i { return "A bigger bottom means smaller pieces. Compare \(A)/\(L) and \(C)/\(L) instead." }
            return "\(A)/\(L) has \(k == 0 ? "fewer" : "more") pieces than \(C)/\(L). So \(a)/\(b) is \(signWords[k]) \(c)/\(d)."
        }
        /// The last words: why.
        public var why: String {
            k == 1 ? "Both are \(Fractions4.pieces(A, L)): the same amount."
                : "\(Fractions4.cap(Fractions4.pieces(A, L))) is \(k == 0 ? "less" : "more") than \(Fractions4.pieces(C, L))."
        }
    }

    static let apart = [(2, 3), (2, 5), (3, 4), (3, 5), (4, 5)]
    /// The web's generator: index < 4 one bottom goes into the other (b 2–6, 2b or 3b up to 12), then half the time 2 and
    /// 3, 2 and 5, 3 and 4, 3 and 5 or 4 and 5; either way round; lowest terms; the same amount now and then.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        var b: Int, d: Int
        if i < 4 || Bool.random(using: &rng) {
            b = Int.random(in: 2...6, using: &rng)
            let ks = [2, 3].filter { b * $0 <= 12 }
            d = b * Fractions4.pick(ks, &rng)
        } else { (b, d) = Fractions4.pick(apart, &rng) }
        if Bool.random(using: &rng) { swap(&b, &d) }
        let L = b / gcd(b, d) * d, same = L == max(b, d) && Double.random(in: 0..<1, using: &rng) < 0.2
        while true {
            let a = Int.random(in: 1...(b - 1), using: &rng)
            let c = same ? (a * d) / b : Int.random(in: 1...(d - 1), using: &rng)
            if same {
                guard (a * d) % b == 0, c >= 1, c < d, gcd(b < d ? a : c, min(b, d)) == 1 else { continue }
            } else {
                guard gcd(a, b) == 1, gcd(c, d) == 1 else { continue }
            }
            return numbers(a: a, b: b, c: c, d: d)
        }
    }

    public static let spec = LessonSpec(id: "g4-fraccompare", title: "Comparing fractions", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let s = Parts(x); return [.frac(.num(Double(s.a)), .num(Double(s.b))), .op("?"), .frac(.num(Double(s.c)), .num(Double(s.d)))] },
        idea: { _ in "Same-size pieces are fair to compare, so more of them means bigger." },
        depends: ["g4-equiv", "g3-fraccompare"],
        check: [CheckItem(0), CheckItem(0, when: { Parts($0).k == 1 }),
                CheckItem(4, when: { let s = Parts($0); return s.L != s.b && s.L != s.d }),
                CheckItem(4, when: { let s = Parts($0); return s.L != s.b && s.L != s.d && cmp(s.a, s.c) != s.k })]) { x in
        let s = Parts(x)
        let say = "Cut both bars into pieces of one size. Drag the ruler, then tap Cut."
        let hint = "Every old cut needs a new cut on it."
        let cut = LessonStep(StepWords(say: say, hint: hint, action: "Cut"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.L)], hint: hint,
                               explain: "Each \(Fractions4.piece(s.b, false)) is \(s.L / s.b) \(Fractions4.piece(s.L, s.L / s.b != 1)); each \(Fractions4.piece(s.d, false)) is \(s.L / s.d).",
                               check: { v in
                                   guard let n = v["x"], n > 0 else { return .soft("Drag the ruler first.") }
                                   return s.cut(Int(n.rounded())).map { .wrong($0) } ?? .right
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["oldCuts": 1])
        let choose = LessonStep(StepWords(say: "Which is more? Tap <, = or >.", hint: "Count the pieces each bar has shaded.", action: "Check"),
            answer: AnswerTask(prompt: [.box("c")], expected: ["c": Double(s.k)], hint: "Count the pieces each bar has shaded.",
                               explain: s.why,
                               check: { v in
                                   guard let c = v["c"] else { return .soft("Tap <, = or >.") }
                                   let i = Int(c.rounded())
                                   return i == s.k ? .right : .wrong(s.wrong(i))
                               }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1])
        return [LessonStep(StepWords(say: say, hint: hint, action: "Let’s find out"), picture: ["at": 0]),
                cut, choose,
                LessonStep(StepWords(say: s.why, hint: "Cut both into pieces of one size, then count the pieces.", action: "Next problem"), picture: ["at": 3])]
    }
}
