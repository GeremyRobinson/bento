import Foundation

// 3rd grade's chapter 2, Times-table tricks (design/grade3.md chapter 2, the preview design/prototype/grade3-ch2.html):
// a thing is a dot in a cell (chapter 1's G3), the ruler cuts an array in two, a tap picks the pair to do first, and a ten
// is a ten-frame. Every number the child writes is typed with the iPad's keys and Check, as the preview types.

// MARK: - Multiply by breaking apart

/// Multiply by breaking apart (the web's g3-split; 3.OA.B.5, 3.MD.C.7c). a rows of b dots. The ruler's handle stands on a
/// stem over the top edge; dragged along it snaps between things and a dashed cut runs down ("5 | 3"). Let go after 5: the
/// cut turns solid and the b − 5 part glides a square away. Write `7 × 5 = [35]`, then `7 × 3 = [21]`; the parts glide
/// back and `35 + 21 = [56]`. The record: `7 × 8 = 7 × 5 + 7 × 3 = 35 + 21 = 56`.
///
/// "a", "b". "at": 0 cut, 1 five, 2 rest, 3 sum, 4 done. Boxes: "k" the cut let go at, "f", "r", "s" the typed answers.
public enum Split3 {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }
    public struct Parts: Sendable {
        public let a: Int, b: Int
        public init(_ x: Numbers) { a = max(2, min(9, G3.int(x, "a", 7))); b = max(6, min(9, G3.int(x, "b", 8))) }
        public var r: Int { b - 5 }
        public var P: Int { a * b }
        public var f5: Int { a * 5 }
        public var fr: Int { a * r }
        /// A thing's cell: the biggest of 5, 4, 3 squares that keeps the array 27 squares tall and 30 wide (so it shows at
        /// 75% with its record beside it).
        public var c: Int { G3.cell(b, a, wide: 30, tall: 27) }
        public func rowsOf(_ n: Int) -> String { "\(G3.count(a, "row")) of \(n)" }
        public func cut(_ k: Int) -> String { "\(k) | \(b - k). Cut after 5: 5s are easy." }
        public var fiveSlips: [(Int, String)] { [(a + 5, "× means \(G3.count(a, "group")) of 5, not \(a) + 5.")] }
        public var restSlips: [(Int, String)] { [(a + r, "× means \(G3.count(a, "group")) of \(r).")] }
        public var sumSlips: [(Int, String)] {
            [(f5, "That's only the first part. Add the \(rowsOf(r)) too."),
             (fr, "That's only the second part. Add the \(rowsOf(5)) too."),
             (P + a, "Check each part again: \(rowsOf(r)) is \(fr).")]
        }
        public var why: String { "\(rowsOf(5)) and \(rowsOf(r)) make \(rowsOf(b))." }
    }

    /// The web's: problems 0–2 a 2–5, b 6 or 7; then a 3–9, b 6–9.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        i < 3 ? numbers(a: Int.random(in: 2...5, using: &rng), b: Int.random(in: 6...7, using: &rng))
              : numbers(a: Int.random(in: 3...9, using: &rng), b: Int.random(in: 6...9, using: &rng))
    }

    public static let spec = LessonSpec(id: "g3-split", title: "Multiply by breaking apart", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op("×"), .num(Double(P.b))] },
        idea: { _ in "A big array is two smaller ones side by side, so two easy facts make the hard one." },
        depends: ["g3-facts"],
        check: [CheckItem(3, when: { Parts($0).b >= 8 }), CheckItem(3, when: { Parts($0).a >= 6 }), CheckItem(3), CheckItem(3)]) { x in
        let P = Parts(x)
        let cutHint = "Drag the handle until 5 are on the left."
        let cut = LessonStep(StepWords(say: "Cut after 5.", hint: cutHint, action: "Check"),
            answer: G2.hand("k", 5, hint: cutHint, explain: "\(P.b) = 5 + \(P.r).", said: { k in P.cut(k) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let fiveHint = "Count by 5s, \(P.a) times."
        let five = LessonStep(StepWords(say: "Write \(P.a) × 5.", hint: fiveHint, action: "Check"),
            answer: G3.typed("f", P.f5, P.fiveSlips, hint: fiveHint, explain: "\(P.rowsOf(5)) is \(P.a) × 5 = \(P.f5)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let restHint = "\(G3.count(P.a, "group")) of \(P.r)."
        let rest = LessonStep(StepWords(say: "Write \(P.a) × \(P.r).", hint: restHint, action: "Check"),
            answer: G3.typed("r", P.fr, P.restSlips, hint: restHint, explain: "\(P.rowsOf(P.r)) is \(P.a) × \(P.r) = \(P.fr)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let sumHint = "\(P.b) is 5 + \(P.r), so add the two answers."
        let sum = LessonStep(StepWords(say: "Put them back together: write \(P.f5) + \(P.fr).", hint: sumHint, action: "Check"),
            answer: G3.typed("s", P.P, P.sumSlips, hint: sumHint, explain: "\(P.f5) + \(P.fr) = \(P.P)."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 4])
        return [cut, five, rest, sum, done]
    }
}

// MARK: - Multiply three numbers

/// Multiply three numbers (g3-three, new; 3.OA.B.5 grouping). `3 × 5 × 2` written over the picture (the record's first
/// line); under it a rows of b groups of c dots, each group outlined. Tap the two to do first (either pair is right): b × c
/// joins each row's groups into one; a × b numbers the groups 1 to a × b. Write the pair, then the rest; the other way is
/// then written under the first line.
///
/// "a", "b", "c". "at": 0 tap, 1 pair, 2 total, 3 done. Boxes: "w" the pair tapped (1 b × c, 2 a × b; kept as "pick"),
/// "p" the pair's product, "t" the total.
public enum Three3 {
    public static func numbers(a: Int, b: Int, c: Int) -> Numbers { ["a": Double(a), "b": Double(b), "c": Double(c)] }
    public struct Parts: Sendable {
        public let a: Int, b: Int, c: Int
        public init(_ x: Numbers) { a = max(2, min(5, G3.int(x, "a", 3))); b = max(2, min(5, G3.int(x, "b", 5))); c = max(2, min(5, G3.int(x, "c", 2))) }
        public var ab: Int { a * b }
        public var bc: Int { b * c }
        public var T: Int { a * b * c }
        /// A thing's cell: a block when a row holds 10 or fewer, else 4 squares.
        public var cell: Int { bc <= 10 ? 5 : 4 }
        /// Which pair was tapped (from what the tap kept): true for b × c.
        public static func right(_ pick: Double?) -> Bool { (pick ?? 1) != 2 }
        public func pair(_ R: Bool) -> Int { R ? bc : ab }
        public func say(_ at: Int, _ R: Bool) -> String {
            switch at {
            case 0: return "Tap the two to do first."
            case 1: return R ? "Write \(b) × \(c)." : "Write \(a) × \(b)."
            case 2: return R ? "Write \(a) × \(bc)." : "Write \(ab) × \(c)."
            default: return why
            }
        }
        public func pairSlips(_ R: Bool) -> [(Int, String)] {
            R ? [(b + c, "\(b) + \(c) adds them. \(G3.count(b, "group")) of \(c) is \(b) × \(c).")]
              : [(a + b, "\(a) + \(b) adds them. \(G3.count(a, "row")) of \(b) groups is \(a) × \(b).")]
        }
        public func pairHint(_ R: Bool) -> String { R ? "Count the dots in one row." : "Count the groups." }
        public func totalSlips(_ R: Bool) -> [(Int, String)] {
            [(a + b + c, "\(a) + \(b) + \(c) adds them. Multiply all three."),
             (pair(R), R ? "\(bc) is one row. There are \(G3.count(a, "row")) of \(bc)." : "\(ab) is how many groups. Each group has \(c)."),
             (a * c, R ? "That's \(a) × \(c). Each row has \(bc), not \(c)." : "That's \(a) × \(c). There are \(ab) groups, not \(a).")]
        }
        public func totalHint(_ R: Bool) -> String { R ? "Count by \(bc)s, \(a) times." : "Count by \(c)s, \(ab) times." }
        public var why: String { "Either two first: \(T) both ways." }
    }

    /// A typed number whose answer and slips follow the pair tapped ("kept.pick").
    static func typed(_ box: String, _ P: Parts, want: @escaping @Sendable (Bool) -> Int, slips: @escaping @Sendable (Bool) -> [(Int, String)],
                      hint: @escaping @Sendable (Bool) -> String, plain: String) -> AnswerTask {
        AnswerTask(prompt: [.box(box)], expected: [box: Double(want(true))], hint: plain, explain: plain,
                   check: { v in
                       guard let x = v[box] else { return .soft("Write the number.") }
                       let R = Parts.right(v["kept.pick"]), k = Int(x.rounded()), w = want(R)
                       if k == w { return .right }
                       return .wrong(slips(R).first { $0.0 == k && $0.0 != w }?.1 ?? "Not quite. \(hint(R))")
                   }, incomplete: "Write the number.",
                   expectKept: { kept in [box: Double(want(Parts.right(kept["pick"])))] })
    }

    /// The design's: problems 0–2 b and c are 5 and 2 (either way round), a 2–4; then any three of 2–5 with a product of
    /// 60 or less and b × c at most 15.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 3 {
            let five = Bool.random(using: &rng)
            return numbers(a: Int.random(in: 2...4, using: &rng), b: five ? 5 : 2, c: five ? 2 : 5)
        }
        var a = 0, b = 0, c = 0
        repeat { a = Int.random(in: 2...5, using: &rng); b = Int.random(in: 2...5, using: &rng); c = Int.random(in: 2...5, using: &rng) } while a * b * c > 60 || b * c > 15
        return numbers(a: a, b: b, c: c)
    }

    public static let spec = LessonSpec(id: "g3-three", title: "Multiply three numbers", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op("×"), .num(Double(P.b)), .op("×"), .num(Double(P.c))] },
        idea: { _ in "Multiply any two first: the total is the same." },
        depends: ["g3-facts"],
        check: [CheckItem(3, when: { Parts($0).bc == 10 }), CheckItem(3, when: { Parts($0).ab == 10 }),
                CheckItem(3, when: { Parts($0).T >= 40 }), CheckItem(3)]) { x in
        let P = Parts(x)
        let tapHint = "Tap the first two or the last two."
        let tap = LessonStep(StepWords(say: P.say(0, true), hint: tapHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("w")], expected: ["w": 1], hint: tapHint, explain: "\(P.b) × \(P.c) first.",
                               check: { v in let w = Int((v["w"] ?? 0).rounded()); return w == 1 || w == 2 ? .right : .soft(tapHint) }, byHand: true),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let pair = LessonStep(StepWords(say: P.say(1, true), hint: "Multiply the two you tapped.", action: "Check"),
            answer: typed("p", P, want: { P.pair($0) }, slips: { P.pairSlips($0) }, hint: { P.pairHint($0) }, plain: "Multiply the two you tapped."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let total = LessonStep(StepWords(say: P.say(2, true), hint: "Multiply by the number that's left.", action: "Check"),
            answer: typed("t", P, want: { _ in P.T }, slips: { P.totalSlips($0) }, hint: { P.totalHint($0) }, plain: "Multiply by the number that's left."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [tap, pair, total, done]
    }
}

// MARK: - Double a fact

/// Double a fact (g3-double, new; 3.OA.D.9, 3.OA.B.5, 3.OA.C.7). 2h rows of n dots, `4` down the left and `7` over the top.
/// The ruler's handle sticks out of the right edge; dragged down it snaps between rows ("14 | 14"). Let go at the middle:
/// the halves part a square, each named `2 × 7`. Write one half, `2 × 7 = [14]`, then the double, `14 + 14 = [28]`. Tap Even
/// or Odd; then the fact's row of the times table writes itself under the record, every one even.
///
/// "h" rows in a half, "n". "at": 0 cut, 1 half, 2 double, 3 even, 4 done. Boxes: "k" the cut let go at (rows above it),
/// "h" one half, "d" the double, "c" the pick (0 even, 1 odd).
public enum Double3 {
    public static func numbers(h: Int, n: Int) -> Numbers { ["h": Double(h), "n": Double(n)] }
    public struct Parts: Sendable {
        public let h: Int, n: Int
        public init(_ x: Numbers) { h = max(2, min(4, G3.int(x, "h", 2))); n = max(2, min(9, G3.int(x, "n", 7))) }
        public var rows: Int { 2 * h }
        public var half: Int { h * n }
        public var P: Int { 2 * half }
        /// A thing's cell: the biggest of 5, 4, 3 squares that keeps the array 28 squares a side (so it shows at 75%
        /// with its record beside it; the design's 4 made 8 × 9 32 squares tall).
        public var c: Int { G3.cell(n, rows, wide: 28, tall: 28) }
        /// The fact's row of the times table: 4, 8, 12 … 40.
        public var table: [Int] { (1...10).map { $0 * rows } }
        public func cut(_ k: Int) -> String { "\(k * n) and \((rows - k) * n) aren't equal. Find the middle." }
        public var halfSlips: [(Int, String)] {
            [(h + n, "\(h) + \(n) adds them. \(G3.count(h, "row")) of \(n) is \(h) × \(n)."),
             (P, "That's all \(rows) rows. Write one half: \(G3.count(h, "row")) of \(n).")]
        }
        public var doubleSlips: [(Int, String)] {
            var s: [(Int, String)] = [(half, "\(half) is one half. Add the other half too.")]
            if half >= 10 { for w in [P - 10, P + 10] { s.append((w, "\(half) + \(half): add the tens, then the ones.")) } }
            return s
        }
        public static let odd = "Two equal halves and no dot left over: even."
        public var why: String { "Two equal halves: every \(rows)s fact is even." }
    }

    /// The design's: problems 0–2 h = 2 (4s from 2s), n 2–5; then h 2–4, n 3–9.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        i < 3 ? numbers(h: 2, n: Int.random(in: 2...5, using: &rng)) : numbers(h: Int.random(in: 2...4, using: &rng), n: Int.random(in: 3...9, using: &rng))
    }

    public static let spec = LessonSpec(id: "g3-double", title: "Double a fact", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.rows)), .op("×"), .num(Double(P.n))] },
        idea: { _ in "Two equal halves: a 4s, 6s or 8s fact is a double, so it's even." },
        depends: ["g3-facts"],
        check: [CheckItem(3, when: { Parts($0).h == 2 }), CheckItem(3, when: { Parts($0).h == 3 }),
                CheckItem(3, when: { Parts($0).h == 4 }), CheckItem(3, when: { Parts($0).n % 2 == 1 })]) { x in
        let P = Parts(x)
        let cutHint = "Cut where the rows above and below are the same."
        let cut = LessonStep(StepWords(say: "Cut it into two equal halves.", hint: cutHint, action: "Check"),
            answer: G2.hand("k", P.h, hint: cutHint, explain: "\(P.half) and \(P.half).", said: { k in P.cut(k) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let halfHint = "Count by \(P.n)s, \(P.h) times."
        let half = LessonStep(StepWords(say: "Write \(P.h) × \(P.n).", hint: halfHint, action: "Check"),
            answer: G3.typed("h", P.half, P.halfSlips, hint: halfHint, explain: "\(P.h) × \(P.n) = \(P.half)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let dHint = "Count on \(P.half) from \(P.half)."
        let double = LessonStep(StepWords(say: "Write \(P.half) + \(P.half).", hint: dHint, action: "Check"),
            answer: G3.typed("d", P.P, P.doubleSlips, hint: dHint, explain: "\(P.half) + \(P.half) = \(P.P)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let evenHint = "Is there a dot left over?"
        let even = LessonStep(StepWords(say: "Tap Even or Odd.", hint: evenHint, action: "Check"),
            answer: G2.hand("c", 0, hint: evenHint, explain: Parts.odd, said: { _ in Parts.odd }),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 4])
        return [cut, half, double, even, done]
    }
}

// MARK: - Multiply by multiples of 10

/// Multiply by multiples of 10 (the web's g3-mult10; 3.NBT.A.3). A square is one; a ten is a ten-frame, 2 rows of 5
/// squares, a block wide. `4 × 30` is rows of 3 tens, a square between rows, `3 tens` over the first and `4` down the left.
/// Drag down to make the rows ("4 rows · 12 tens"), write `4 × 3 = [12]`; with ten tens or more, ten of them glide into a
/// hundred (the tens left over beside them: "1 hundred and 2 tens"); write `4 × 30 = 12 tens = [120]`.
///
/// "a", "t". "at": 0 rows, 1 fact, 2 tens, 3 done. Boxes: "r" the rows let go at, "f" the fact, "x" the product.
public enum Tens3 {
    public static func numbers(a: Int, t: Int) -> Numbers { ["a": Double(a), "t": Double(t)] }
    public struct Parts: Sendable {
        public let a: Int, m: Int
        public init(_ x: Numbers) { a = max(2, min(9, G3.int(x, "a", 4))); m = max(2, min(9, G3.int(x, "t", 30) / 10)) }
        public var t: Int { 10 * m }
        public var f: Int { a * m }
        public var P: Int { a * t }
        public var hundreds: Int { f / 10 }
        public var left: Int { f % 10 }
        /// How far the rows may be dragged: at least one more, never more than 36 squares (3 a row).
        public var cap: Int { G3.cap(a, 3) }
        public func rows(_ n: Int) -> String { "That's \(n) rows. \(a) × \(t) is \(a) rows of \(m) tens." }
        public var factSlips: [(Int, String)] { [(a + m, "× means groups: \(G3.count(a, "group")) of \(m), not \(a) + \(m).")] }
        public var tensSlips: [(Int, String)] {
            [(f, "\(f) is how many tens. Each ten is 10, so \(f) tens is \(f * 10)."),
             (f * 100, "\(f) tens is \(f) × 10, which is \(f * 10). You wrote \(G3.count(f, "hundred"))."),
             (a + t, "\(G3.count(a, "group")) of \(t) is much more than \(a) + \(t).")]
        }
        /// What the fold leaves: "1 hundred and 2 tens".
        public var folded: String { G3.count(hundreds, "hundred") + (left > 0 ? " and \(G3.count(left, "ten"))" : "") }
        public var why: String { "\(f) tens is \(P): tens count like ones." }
    }

    /// The web's: a and t ÷ 10 are 2–5 for problems 0–2, then 2–9.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let hi = i < 3 ? 5 : 9
        return numbers(a: Int.random(in: 2...hi, using: &rng), t: Int.random(in: 2...hi, using: &rng) * 10)
    }

    public static let spec = LessonSpec(id: "g3-mult10", title: "Multiply by multiples of 10", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op("×"), .num(Double(P.t))] },
        idea: { _ in "Tens count the same way ones do, so a fact you know gives the answer in tens." },
        depends: ["g3-facts", "g2-hundreds"],
        check: [CheckItem(3, when: { Parts($0).f < 10 }), CheckItem(3, when: { Parts($0).f >= 10 }),
                CheckItem(3, when: { Parts($0).f % 10 == 0 }), CheckItem(3)]) { x in
        let P = Parts(x)
        let rowsHint = "Stop when there are \(P.a) rows."
        let rows = LessonStep(StepWords(say: "Drag down to make \(P.a) rows of \(P.m) tens.", hint: rowsHint, action: "Check"),
            answer: G2.hand("r", P.a, hint: rowsHint, explain: "\(P.a) rows of \(P.m) tens.", said: { n in P.rows(n) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let factHint = "Count by \(P.m)s, \(P.a) times."
        let fact = LessonStep(StepWords(say: "Write \(P.a) × \(P.m): how many tens?", hint: factHint, action: "Check"),
            answer: G3.typed("f", P.f, P.factSlips, hint: factHint, explain: "\(P.a) × \(P.m) = \(P.f), so \(P.a) × \(P.m) tens is \(P.f) tens."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let tensHint = "Each ten is 10 ones. How much are \(P.f) tens? Count by 10s, or think of \(P.f) in the tens place."
        // the fold's line goes first in the instruction ("Ten tens make a hundred.")
        // (the fact kept on one line when the words wrap: no break inside 4 × 30)
        let fact2 = P.f >= 10 ? "\(P.a)\u{00A0}×\u{00A0}\(P.t)" : "\(P.a) × \(P.t)"
        let tens = LessonStep(StepWords(say: (P.f >= 10 ? "Ten tens make a hundred. " : "") + "Write \(fact2).", hint: tensHint, action: "Check"),
            answer: G3.typed("x", P.P, P.tensSlips, hint: tensHint, explain: "\(P.f) tens = \(P.P): write \(P.f), then a 0 for the ones."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [rows, fact, tens, done]
    }
}
