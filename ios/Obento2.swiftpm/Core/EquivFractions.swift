import Foundation

/// Equivalent fractions (the web app's g4-equiv, 4.NF.1; design/grade4.md chapter 4, the preview
/// design/prototype/grade4-ch4.html). The web's maths: a/b with b 2–6 and a in lowest terms, every piece cut into k (2–5):
/// a/b = (a × k)/(b × k). LESSONS.md's 4th grade example: the pieces cut again, in place.
///
/// On the paper: two bars of one whole (Fractions4.whole of b × k), a/b on top, the same bar under it named ?/N. Drag the
/// ruler under them: it snaps only to sizes that cut every piece evenly, the new cuts dashed across the lower bar; Cut (its
/// box is how many pieces make the whole). The cuts turn solid, the shaded part hasn't moved, its pieces count; then write
/// the top.
///
/// Every step's picture has "at": 0 the question, 1 the cut, 2 write, 3 done.
public enum EquivFractions {
    public static func numbers(a: Int, b: Int, k: Int) -> Numbers { ["a": Double(a), "b": Double(b), "k": Double(k)] }

    public struct Parts: Sendable {
        public let a: Int, b: Int, k: Int
        public init(_ x: Numbers) { a = Int((x["a"] ?? 1).rounded()); b = max(2, Int((x["b"] ?? 2).rounded())); k = max(2, Int((x["k"] ?? 2).rounded())) }
        public var N: Int { b * k }
        public var A: Int { a * k }
        public var W: Int { Fractions4.whole(N) }
        /// One old piece's length, and one new piece's.
        public var pb: Int { W / b }
        public var pN: Int { W / N }
        /// The ruler's sizes: every length that cuts an old piece evenly, 1 square to a whole old piece.
        public var sizes: [Int] { (1...pb).filter { pb % $0 == 0 } }
        /// The ruler's readout for a piece `s` squares long: "Eighths: each half into 4" ("Halves" uncut).
        public func reads(_ s: Int) -> String {
            let m = pb / max(1, s)
            return m == 1 ? Fractions4.cap(Fractions4.piece(b)) : "\(Fractions4.cap(Fractions4.piece(b * m))): each \(Fractions4.piece(b, false)) into \(m)"
        }
    }

    /// The web's generator: b 2–6, a in lowest terms, k 2–5 (the index doesn't change it).
    static func make(_ rng: inout SeededRandom) -> Numbers {
        let b = Int.random(in: 2...6, using: &rng)
        var a: Int; repeat { a = Int.random(in: 1...(b - 1), using: &rng) } while gcd(a, b) != 1
        return numbers(a: a, b: b, k: Int.random(in: 2...5, using: &rng))
    }

    public static let spec = LessonSpec(id: "g4-equiv", title: "Equivalent fractions", master: "bars",
        generate: { rng, _ in make(&rng) },
        display: { x in let s = Parts(x); return [.frac(.num(Double(s.a)), .num(Double(s.b))), .op("="), .frac(.text("?"), .num(Double(s.N)))] },
        // the spec's new idea line (specs/k12/grade4.md §3)
        idea: { _ in "Cut each piece into equal smaller pieces: more pieces, same amount." },
        depends: ["g3-fraccompare", "g3-facts"],
        check: [CheckItem(0, when: { Parts($0).a == 1 }), CheckItem(0, when: { Parts($0).a > 1 }), CheckItem(0, when: { Parts($0).k >= 4 }),
                CheckItem(0, when: { Parts($0).a > 1 && Parts($0).b >= 5 })]) { x in
        let s = Parts(x), N = s.N, name = Fractions4.piece(N), k = s.k
        let say = "Cut the lower bar into \(name). Drag the ruler, then tap Cut."
        // the cut: its box is how many pieces of the ruler's length make a whole
        let cut = LessonStep(StepWords(say: say, hint: "Cut every \(Fractions4.piece(s.b, false)) into \(k).", action: "Cut"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(N)], hint: "Cut every \(Fractions4.piece(s.b, false)) into \(k).",
                               explain: "Every piece cut into \(k), so there are \(k) times as many.",
                               check: { v in
                                   guard let n = v["x"], n > 0 else { return .soft("Drag the ruler first.") }
                                   let m = Int(n.rounded())
                                   if m == N { return .right }
                                   if m == s.b { return .soft("Drag the ruler to make the pieces smaller.") }
                                   return .wrong("Those are \(Fractions4.piece(m)). Cut into \(name).")
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1])
        // the top, typed, with the web's slips
        var known: [(values: [String: Double], message: String)] = []
        for (v, m) in [(s.a, "Whatever you multiply the bottom by, multiply the top by too."), (s.a + N - s.b, "Multiply the top by \(k)."),
                       (N, "\(N) is all the pieces. Count the shaded ones."), (s.a + k, "Cutting is times, not plus. Multiply the top by \(k).")]
            where v != s.A && !known.contains(where: { $0.values["x"] == Double(v) }) { known.append((["x": Double(v)], m)) }
        let write = LessonStep(StepWords(say: "How many \(name) are shaded? The shaded part hasn’t moved.", hint: "Count the shaded \(name).", action: "Check"),
            answer: AnswerTask(prompt: [.frac(.num(Double(s.a)), .num(Double(s.b))), .op("="), .frac(.box("x"), .num(Double(N)))],
                               expected: ["x": Double(s.A)], known: known, hint: "Count the shaded \(name).",
                               explain: "Do the same to the top. The shaded part has not changed: \(s.a) × \(k) = \(s.A).",
                               check: { v in Int((v["x"] ?? -1).rounded()) == s.A ? .right : .wrong("Count the shaded \(name).") },
                               incomplete: "Type the number in the box."),
            picture: ["at": 2], onMiss: ["ring": 1])
        return [LessonStep(StepWords(say: say, hint: "Cut every \(Fractions4.piece(s.b, false)) into \(k).", action: "Let’s find out"), picture: ["at": 0]),
                cut, write,
                LessonStep(StepWords(say: "Every piece cut into \(k): \(k) times the pieces, the same amount.",
                                     hint: "Every piece is cut into \(k), so there are \(k) times as many.", action: "Next problem"), picture: ["at": 3])]
    }
}
