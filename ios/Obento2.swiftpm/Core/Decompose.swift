import Foundation

/// What 4th grade's Fractions chapter shares (design/grade4.md chapter 4, the preview design/prototype/grade4-ch4.html):
/// a whole bar's length and the pieces' names.
public enum Fractions4 {
    /// A whole bar's length in squares for pieces of 1/n: 48 when n divides it (halves to twelfths, 16ths, 24ths), else
    /// 40 (fifths, tenths, 20ths), 45 (ninths, 15ths), 36 (18ths), 50 (25ths) or 60 (30ths), so each piece is a whole
    /// number of squares.
    public static func whole(_ n: Int) -> Int { [48, 40, 45, 36, 50, 60].first { $0 % max(1, n) == 0 } ?? 2 * max(1, n) }
    /// "eighths", "eighth", "halves", "twenty-fourths".
    public static func piece(_ d: Int, _ plural: Bool = true) -> String { UnlikeFractions.pieceName(d, plural) }
    /// "5 eighths", "1 eighth".
    public static func pieces(_ n: Int, _ d: Int) -> String { "\(n) \(piece(d, n != 1))" }
    /// "a third", "an eighth".
    public static func aPiece(_ d: Int) -> String { let w = piece(d, false); return (w.first.map { "aeiou".contains($0) } == true ? "an " : "a ") + w }
    static func cap(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }
    static func pick<T>(_ a: [T], _ rng: inout SeededRandom) -> T { a[Int.random(in: 0..<a.count, using: &rng)] }
}

/// Breaking fractions apart (g4-decompose, 4.NF.3a, 4.NF.3b, 4.NF.4a; new, design/grade4.md chapter 4; the preview
/// design/prototype/grade4-ch4.html). Three kinds: unit pieces (5/8 is five pieces of 1/8), two ways (5/8 = 2/8 + 3/8 =
/// 1/8 + 4/8), and wholes and a part (2 1/8 = 8/8 + 8/8 + 1/8).
///
/// On the paper: the bar is one whole. Unit pieces: tap each line between the shaded pieces; they part a square, each
/// named 1/d; then write how many pieces of 1/d. Two ways: tap one line between the shaded pieces; a copy of the bar
/// draws under it; split it another way. Wholes and a part: tap each whole bar; its pieces count and its name turns from
/// 1 into d/d.
///
/// Every step's picture has "at": 0 the question, 1 the hands' move, 2 the copy (two ways) or write (unit pieces), 3 done
/// (wholes: 2 done). The splits are kept on the run ("s<j>": joint j split on the bar, "c<j>" on the copy; "w<j>": whole
/// j tapped).
public enum Decompose {
    /// kind 0 unit pieces, 1 two ways, 2 wholes and a part.
    public static func unit(a: Int, d: Int) -> Numbers { ["kind": 0, "a": Double(a), "d": Double(d)] }
    public static func twoWays(a: Int, d: Int) -> Numbers { ["kind": 1, "a": Double(a), "d": Double(d)] }
    public static func wholes(w: Int, n: Int, d: Int) -> Numbers { ["kind": 2, "w": Double(w), "n": Double(n), "d": Double(d)] }

    public struct Parts: Sendable {
        public let kind: Int, a: Int, d: Int, w: Int, n: Int
        public init(_ x: Numbers) {
            func i(_ k: String, _ v: Int) -> Int { Int((x[k] ?? Double(v)).rounded()) }
            kind = i("kind", 0); a = i("a", 2); d = max(2, i("d", 4)); w = i("w", 1); n = i("n", 1)
        }
        public var W: Int { Fractions4.whole(d) }
        public var pw: Int { W / d }
        /// The shaded parts, left to right, for splits at these joints (joint j is between piece j and j + 1).
        public func parts(_ splits: Set<Int>) -> [Int] {
            var out: [Int] = [], last = 0
            for j in splits.sorted() { out.append(j - last); last = j }
            out.append(a - last)
            return out
        }
        /// "2/8 + 3/8".
        public func sum(_ splits: Set<Int>) -> String { parts(splits).map { "\($0)/\(d)" }.joined(separator: " + ") }
        /// The same parts in any order: the same way.
        public func same(_ s: Set<Int>, _ t: Set<Int>) -> Bool { parts(s).sorted() == parts(t).sorted() }
    }

    /// The preview's generator: unit pieces for index < 3 (d up to 6), two ways for 3 and 4 (4 with d of 8 or more),
    /// wholes and a part for 5; then unit, two ways, wholes in turn. Unit: a 2 to d − 1; two ways: a 3 to d − 1; wholes and
    /// a part: w 1–3, n 1 to d − 1 in lowest terms, d up to 8.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let kind = i < 3 ? 0 : i < 5 ? 1 : i == 5 ? 2 : (i - 6) % 3
        switch kind {
        case 2:
            let d = Fractions4.pick([3, 4, 5, 6, 8], &rng)
            var n: Int; repeat { n = Int.random(in: 1...(d - 1), using: &rng) } while gcd(n, d) != 1
            return wholes(w: Int.random(in: 1...3, using: &rng), n: n, d: d)
        case 0:
            let d = Fractions4.pick(i < 3 ? [3, 4, 5, 6] : [3, 4, 5, 6, 8, 10, 12], &rng)
            return unit(a: Int.random(in: 2...(d - 1), using: &rng), d: d)
        default:
            let d = Fractions4.pick(i == 4 || i % 2 == 1 ? [8, 10, 12] : [4, 5, 6, 8, 10, 12], &rng)
            return twoWays(a: Int.random(in: 3...(d - 1), using: &rng), d: d)
        }
    }

    public static let spec = LessonSpec(id: "g4-decompose", title: "Breaking fractions apart", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in
            let s = Parts(x)
            return s.kind == 2 ? [.num(Double(s.w)), .frac(.num(Double(s.n)), .num(Double(s.d)))] : [.frac(.num(Double(s.a)), .num(Double(s.d)))]
        },
        idea: { x in
            let s = Parts(x)
            return s.kind == 2 ? "Each whole is \(s.d) \(Fractions4.piece(s.d))." : "A fraction is pieces of one size, and they can be grouped any way."
        },
        depends: ["g3-unitfrac"],
        check: [CheckItem(0), CheckItem(3), CheckItem(4), CheckItem(5)]) { x in steps(x) }

    static func steps(_ x: Numbers) -> [LessonStep] {
        let s = Parts(x), d = s.d, a = s.a, name = Fractions4.piece(d)
        switch s.kind {
        case 0:
            // tap each line between the shaded pieces: the box is how many lines are split once they all are
            let say = "Break it into pieces of 1/\(d). Tap each line between the shaded pieces."
            let split = LessonStep(StepWords(say: say, hint: "Each shaded piece is 1/\(d).", action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(a - 1)], hint: "Each shaded piece is 1/\(d).",
                                   explain: "\(a) pieces, each 1/\(d).",
                                   check: { v in
                                       guard let j = v["x"] else { return .soft("Tap each line between the shaded pieces.") }
                                       return j < 0 ? .wrong("Split between the shaded pieces.") : Int(j.rounded()) == a - 1 ? .right : .soft("Tap each line between the shaded pieces.")
                                   }, byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
            // how many pieces of 1/d, typed
            let known: [(values: [String: Double], message: String)] = [
                (["x": Double(d)], "\(d) is the bottom: it says how big the pieces are. Count the pieces."),
                (["x": Double(a - 1)], "That counts the gaps. Count the pieces."),
            ].filter { $0.values["x"] != Double(a) }
            let write = LessonStep(StepWords(say: "How many pieces of 1/\(d)?", hint: "Count the pieces of 1/\(d).", action: "Check"),
                answer: AnswerTask(prompt: [.frac(.num(Double(a)), .num(Double(d))), .op("="), .box("x"), .op("×"), .frac(.num(1), .num(Double(d)))],
                                   expected: ["x": Double(a)], known: known, hint: "Count the pieces of 1/\(d).",
                                   explain: "\(a) pieces of 1/\(d): \(a)/\(d) = \(a) × 1/\(d).",
                                   check: { v in Int((v["x"] ?? -1).rounded()) == a ? .right : .wrong("Count the pieces of 1/\(d).") },
                                   incomplete: "Type the number in the box."),
                picture: ["at": 2])
            return [LessonStep(StepWords(say: say, hint: "Each shaded piece is 1/\(d).", action: "Let’s find out"), picture: ["at": 0]),
                    split, write,
                    LessonStep(StepWords(say: "\(Fractions4.pieces(a, d)) are \(a) pieces of 1/\(d).", hint: "A fraction is pieces of one size.",
                                         action: "Next problem"), picture: ["at": 3])]
        case 1:
            // one line split (the box is the joint, 1 to a − 1; past the shaded pieces it's a miss)
            let say1 = "Break it into two parts. Tap a line between the shaded pieces."
            let split = LessonStep(StepWords(say: say1, hint: "Tap a line inside the shaded part.", action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": 1], hint: "Tap a line inside the shaded part.",
                                   explain: "Any line between the shaded pieces breaks it into two parts.",
                                   check: { v in
                                       guard let j = v["x"] else { return .soft("Tap a line between the shaded pieces.") }
                                       return j >= 1 && j < Double(a) ? .right : .wrong("Split between the shaded pieces.")
                                   }, byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
            // the copy split another way: the box is 1 when its parts differ from the first's, 100 + the first split's
            // line when they're the same (what a miss says is that split's own sum), −1 off the shaded pieces
            let say2 = "Now break the copy another way. Tap lines between its shaded pieces."
            let again: [(values: [String: Double], message: String)] = (1..<max(2, a)).map { j in
                (["x": Double(100 + j)], "That’s \(j)/\(d) + \(a - j)/\(d) again. Split it somewhere else.")
            }
            let copy = LessonStep(StepWords(say: say2, hint: "Split it at a different line.", action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": 1], known: again, hint: "Split it at a different line.",
                                   explain: "The same \(a) pieces, grouped another way.",
                                   check: { v in
                                       guard let r = v["x"] else { return .soft("Tap lines between its shaded pieces.") }
                                       if r < 0 { return .wrong("Split between the shaded pieces.") }
                                       return r == 1 ? .right : .wrong("That’s the same again. Split it somewhere else.")
                                   }, byHand: true),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [LessonStep(StepWords(say: say1, hint: "Tap a line inside the shaded part.", action: "Let’s find out"), picture: ["at": 0]),
                    split, copy,
                    LessonStep(StepWords(say: "The same \(a) pieces, grouped another way.", hint: "A fraction’s pieces can be grouped any way.",
                                         action: "Next problem"), picture: ["at": 3])]
        default:
            let say = "How many \(name) make each whole? Tap each whole bar."
            let tap = LessonStep(StepWords(say: say, hint: "A whole bar is all \(d) of its \(name).", action: "Check"),
                answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(s.w)], hint: "A whole bar is all \(d) of its \(name).",
                                   explain: "Each whole is \(d) \(name): \(d)/\(d).",
                                   check: { v in
                                       guard let t = v["x"] else { return .soft("Tap each whole bar.") }
                                       return t < 0 ? .wrong("That one isn’t a whole. Tap the bars named 1.") : Int(t.rounded()) == s.w ? .right : .soft("Tap each whole bar.")
                                   }, byHand: true),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [LessonStep(StepWords(say: say, hint: "A whole bar is all \(d) of its \(name).", action: "Let’s find out"), picture: ["at": 0]),
                    tap,
                    LessonStep(StepWords(say: "Each whole is \(d) \(name).", hint: "Each whole is \(d) \(name).", action: "Next problem"), picture: ["at": 2])]
        }
    }
}
