import Foundation

/// What 3rd grade's chapter 1, Multiply and divide, shares (design/grade3.md chapter 1, the preview
/// design/prototype/grade3-ch1.html): a thing is a dot in a cell of 5, 4 or 3 squares (the biggest that keeps the array
/// within 32 squares a side), how far an edge may be dragged, and the typed steps' slips. Every number the child writes is
/// typed with the iPad's keys and Check, as the preview types; the hands make the arrays, the shares and the slides.
public enum G3 {
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    /// "1 row", "4 rows".
    public static func count(_ n: Int, _ one: String, _ many: String? = nil) -> String { "\(n) \(n == 1 ? one : many ?? one + "s")" }
    /// The cell a thing sits in, in squares: 5 up to 5 a side, 4 up to 7, then 3 (the preview's 5 up to 6 and 4 up to 8
    /// made arrays 32 squares tall; at most 30 shows every problem at 75%).
    public static func cell(_ m: Int) -> Int { m <= 5 ? 5 : m <= 7 ? 4 : 3 }
    /// How far a drag may go past the answer n with cells of c: at least one more, never more than 36 squares or 10.
    public static func cap(_ n: Int, _ c: Int) -> Int { max(n + 1 <= 10 ? n + 1 : 10, min(10, n + 2, 36 / c)) }
    /// A typed number: right, a known slip (the preview's words), or "Not quite." and the hint.
    static func typed(_ box: String, _ want: Int, _ slips: [(Int, String)], hint: String, explain: String) -> AnswerTask {
        G2.typed(box, want, slips, plain: "Not quite. \(hint)", hint: hint, explain: explain)
    }
}

// MARK: - Multiplication facts

/// Multiplication facts (the web's g3-facts; 3.OA.A.1, 3.OA.B.5, 3.OA.C.7). a rows of b dots. Drag the bottom edge down to
/// make the rows (it snaps a row at a time, "3 rows of 6"); the rows count by b, the last count typed (`6, 12, 18, [24]`,
/// a long list keeps its first two and last two); turn it a quarter by its corner (b rows of a, the same dots), and write
/// `6 × 4 = [24]`. A square has no turn.
///
/// "a", "b". "at": 0 rows, 1 count, 2 turn, 3 write the turn, 4 done. Boxes: "r" the rows let go at, "n" the count, "q" the
/// turn (1 a quarter), "t" the turned fact.
public enum Facts3 {
    public static func numbers(a: Int, b: Int) -> Numbers { ["a": Double(a), "b": Double(b)] }
    public struct Parts: Sendable {
        public let a: Int, b: Int
        public init(_ x: Numbers) { a = max(2, min(10, G3.int(x, "a", 4))); b = max(2, min(10, G3.int(x, "b", 6))) }
        public var P: Int { a * b }
        public var square: Bool { a == b }
        public var c: Int { G3.cell(max(a, b)) }
        public var cap: Int { G3.cap(a, c) }
        /// The counts written before the box: every row's but the last; a long list its first two, "…", its last two.
        public var shown: [Int?] {
            let counts = (1..<a).map { $0 * b }
            return counts.count > 4 ? [counts[0], counts[1], nil, counts[a - 3], counts[a - 2]] : counts
        }
        public func rows(_ n: Int) -> String { "That's \(n) rows. \(a) × \(b) is \(a) rows of \(b)." }
        public var countSlips: [(Int, String)] {
            [((a - 1) * b + 1, "Each jump is \(b), not 1. \((a - 1) * b) + \(b) = \(P)."),
             ((a - 1) * b, "That's only \(G3.count(a - 1, "jump")) of \(b). Make \(G3.count(a, "jump"))."),
             ((a + 1) * b, "That's \(G3.count(a + 1, "jump")) of \(b). Stop after \(G3.count(a, "jump"))."),
             (a + b, "\(a) + \(b) puts them together once. You need \(G3.count(a, "group")) of \(b).")]
        }
        public var turnSlips: [(Int, String)] {
            [(a + b, "× means groups. \(G3.count(b, "group")) of \(a) is \(P), not \(a + b)."),
             (b * b, "That's \(b) × \(b). Here it is \(G3.count(b, "group")) of \(a).")]
        }
        public var why: String { square ? "\(a) rows of \(b) make \(P)." : "Same dots, turned: \(a) × \(b) = \(b) × \(a)." }
    }

    /// The web's: problems 0–2 b is 2, 5 or 10 and a 3–6 (3, 4 or 6 when b is 5); then a 2–10, b 3–9, a square redrawn 6
    /// times in 10.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 3 {
            let b = [2, 5, 10].randomElement(using: &rng)!
            return numbers(a: b == 5 ? [3, 4, 6].randomElement(using: &rng)! : Int.random(in: 3...6, using: &rng), b: b)
        }
        var a = 0, b = 0
        repeat { a = Int.random(in: 2...10, using: &rng); b = Int.random(in: 3...9, using: &rng) } while a == b && Double.random(in: 0..<1, using: &rng) < 0.6
        return numbers(a: a, b: b)
    }

    public static let spec = LessonSpec(id: "g3-facts", title: "Multiplication facts", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op("×"), .num(Double(P.b))] },
        idea: { _ in "Same dots, turned: the total stays the same." },
        depends: ["g2-arrays", "g2-skip"],
        check: [CheckItem(3, when: { !Parts($0).square }), CheckItem(3, when: { let P = Parts($0); return P.a >= 6 && P.b >= 6 && !P.square }),
                CheckItem(3, when: { !Parts($0).square }), CheckItem(3, when: { !Parts($0).square })]) { x in
        let P = Parts(x)
        let rowsHint = "Stop when there are \(P.a) rows."
        let rows = LessonStep(StepWords(say: "Drag down to make \(P.a) rows of \(P.b).", hint: rowsHint, action: "Check"),
            answer: G2.hand("r", P.a, hint: rowsHint, explain: "\(P.a) rows of \(P.b).", said: { n in P.rows(n) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let countHint = "Add \(P.b) to the last number you see."
        let count = LessonStep(StepWords(say: "Count by \(P.b)s.", hint: countHint, action: "Check"),
            answer: G3.typed("n", P.P, P.countSlips, hint: countHint, explain: "\(G3.count(P.a, "jump")) of \(P.b) land on \(P.P)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 4])
        if P.square { return [rows, count, done] }
        let turnHint = "Grab the corner and swing it a quarter turn."
        let turn = LessonStep(StepWords(say: "Turn it.", hint: turnHint, action: "Check"),
            answer: G2.hand("q", 1, hint: turnHint, explain: "\(P.b) rows of \(P.a).",
                           said: { n in n == 2 ? "That's a half turn: still \(P.a) rows of \(P.b). Stop at a quarter turn." : turnHint }),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let wHint = "Turn the array on its side. No dots are added or taken away. So the total is the same as the \(P.a) × \(P.b) you counted."
        let write = LessonStep(StepWords(say: "Now write \(P.b) × \(P.a).", hint: wHint, action: "Check"),
            answer: G3.typed("t", P.P, P.turnSlips, hint: wHint, explain: "\(P.b) × \(P.a) = \(P.P), the same as \(P.a) × \(P.b)."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [rows, count, turn, write, done]
    }
}

// MARK: - Division facts

/// Division facts (the web's g3-divfacts; 3.OA.A.2, 3.OA.B.6, 3.OA.C.7). The pile of a in rows of 10 on the left (a dot in
/// a 3-square cell), b empty rows on the right. Drag their right edge across: each column takes one dot for every row from
/// the end of the pile, sliding across ("3 in each · 12 left"). Let go short: keep going; past: more than a. Then
/// `4 × 6 = 24` is written, and `24 ÷ 4 = [6]` typed.
///
/// "b", "q" (a = b × q). "at": 0 share, 1 write, 2 done. Boxes: "k" the columns let go at, "d" the quotient.
public enum DivFacts3 {
    public static func numbers(b: Int, q: Int) -> Numbers { ["b": Double(b), "q": Double(q)] }
    public struct Parts: Sendable {
        public let b: Int, q: Int
        public init(_ x: Numbers) { b = max(2, min(10, G3.int(x, "b", 4))); q = max(2, min(10, G3.int(x, "q", 6))) }
        public var a: Int { b * q }
        public var say: String { "Drag across to share \(a) into \(b) rows." }
        /// Let go with k in each row: nil when it's right.
        public func shared(_ k: Int) -> Verdict {
            if k == q { return .right }
            if k > q { return .wrong("\(b) × \(k) = \(b * k). That's more than \(a).") }
            if k > 0 { return .soft("\(b) × \(k) = \(b * k). \(a - b * k) are left. Keep going.") }
            return .soft(say)
        }
        public var slips: [(Int, String)] {
            [(b, "\(b) is how many groups there are. How many are in each group?"), (a * b, "Dividing shares \(a) out, so the answer is smaller than \(a).")]
        }
        public var why: String { "\(b) rows of \(q) make \(a), so \(a) ÷ \(b) = \(q)." }
    }

    /// The web's: problems 0–2 ÷ 2, 5 or 10 with the answer 2–6; then ÷ 3–9 with the answer 2–10.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let b = i < 3 ? [2, 5, 10].randomElement(using: &rng)! : Int.random(in: 3...9, using: &rng)
        return numbers(b: b, q: i < 3 ? Int.random(in: 2...6, using: &rng) : Int.random(in: 2...10, using: &rng))
    }

    public static let spec = LessonSpec(id: "g3-divfacts", title: "Division facts", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op("÷"), .num(Double(P.b))] },
        idea: { x in let P = Parts(x); return "\(P.b) rows of \(P.q) make \(P.a)." },
        depends: ["g3-facts"],
        check: [CheckItem(3, when: { Parts($0).b >= 6 }), CheckItem(3, when: { Parts($0).q >= 6 }), CheckItem(3), CheckItem(3)]) { x in
        let P = Parts(x)
        let shareHint = "Each row takes one more with every column."
        let share = LessonStep(StepWords(say: P.say, hint: shareHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("k")], expected: ["k": Double(P.q)], hint: shareHint, explain: "\(P.b) × \(P.q) = \(P.a).",
                               check: { v in P.shared(Int((v["k"] ?? 0).rounded())) }, byHand: true),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let wHint = "It's the missing number from \(P.b) × ? = \(P.a)."
        let write = LessonStep(StepWords(say: "Now write \(P.a) ÷ \(P.b).", hint: wHint, action: "Check"),
            answer: G3.typed("d", P.q, P.slips, hint: wHint, explain: "\(P.a) ÷ \(P.b) = \(P.q)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 2])
        return [share, write, done]
    }
}

// MARK: - Find the missing number

/// Find the missing number (g3-unknown, new; 3.OA.A.4, 3.OA.B.6). The array's own names are the equation: rows down the
/// left, how many in each over the top, the total in a bracket on the right; the missing one an empty box where its name
/// goes. Forms: 0 `a × ? = c`, 1 `? × b = c`, 2 `c ÷ ? = b`, 3 `? ÷ a = b`; flipped, the total comes first (`48 = 8 × ?`).
/// Drag the open side until it holds the total (form 3: make the rows; they count by b), then write the box.
///
/// "a" rows, "b" in each, "form", "flip". "at": 0 drag, 1 write, 2 done. Boxes: "e" the edge let go at (columns in form 0,
/// rows otherwise), "u" the missing number.
public enum Unknown3 {
    public static func numbers(a: Int, b: Int, form: Int, flip: Bool = false) -> Numbers {
        ["a": Double(a), "b": Double(b), "form": Double(form), "flip": flip ? 1 : 0]
    }
    public struct Parts: Sendable {
        public let a: Int, b: Int, form: Int, flip: Bool
        public init(_ x: Numbers) {
            a = max(2, min(10, G3.int(x, "a", 8))); b = max(2, min(10, G3.int(x, "b", 6)))
            form = max(0, min(3, G3.int(x, "form"))); flip = G3.int(x, "flip") != 0
        }
        public var T: Int { a * b }
        public var c: Int { G3.cell(max(a, b)) }
        /// The edge dragged: columns (form 0) or rows.
        public var cols: Bool { form == 0 }
        public var want: Int { cols ? b : a }
        public var ans: Int { form == 0 ? b : form == 3 ? T : a }
        public var cap: Int { form == 3 ? G3.cap(a, c) : min(10, 36 / c) }
        public var say: String { form == 3 ? "Drag down to make \(a) rows of \(b)." : "Drag the side until it holds \(T)." }
        /// Rows × in each when the edge is at n.
        public func rc(_ n: Int) -> (Int, Int) { cols ? (a, n) : (n, b) }
        public func dragged(_ n: Int) -> String {
            let (r, k) = rc(n)
            return form == 3 ? "That's \(n) rows. Make \(a) rows of \(b)." : "\(r) rows of \(k) is \(r * k). That's \(r * k > T ? "more" : "less") than \(T)."
        }
        public var slips: [(Int, String)] {
            switch form {
            case 0, 1:
                let known = form == 0 ? a : b, what = form == 0 ? "in each row" : "rows", rowsWord = form == 0 ? "\(a) rows" : "rows of \(b)"
                return [(T - known, "Taking \(known) away once leaves \(T - known). You want \(rowsWord) that make \(T)."),
                        (T, "\(T) is all the dots together. How many \(what)?"),
                        (ans + 1, form == 0 ? "\(a) rows of \(b + 1) is \(a * (b + 1)). That's more than \(T)." : "\(a + 1) rows of \(b) is \((a + 1) * b). That's more than \(T)."),
                        (ans - 1, form == 0 ? "\(a) rows of \(b - 1) is \(a * (b - 1)). That's less than \(T)." : "\(a - 1) rows of \(b) is \((a - 1) * b). That's less than \(T).")]
            case 2:
                return [(T - b, "Taking \(b) away once leaves \(T - b). How many rows of \(b) make \(T)?"),
                        (T * b, "Dividing makes \(T) smaller. How many rows of \(b) make \(T)?"),
                        (b, "\(b) is how many in each row. How many rows?")]
            default:
                return [(a + b, "\(a) + \(b) puts them together once. \(a) rows of \(b) is \(a) × \(b)."),
                        (abs(a - b), "The total is all the dots: \(a) rows of \(b)."),
                        ((a - 1) * b, "That's \(a - 1) rows of \(b). There are \(a) rows."),
                        ((a + 1) * b, "That's \(a + 1) rows of \(b). There are only \(a) rows.")]
            }
        }
        public var hint: String { form == 0 ? "Count the dots in one row." : form == 3 ? "Count by \(b)s, one row at a time." : "Count the rows." }
        public var why: String { form < 2 ? "\(a) rows of \(b) make \(T)." : "÷ is a times fact backwards." }
    }

    /// The design's: problems 0–2 forms 0 and 3 only, with one number 2, 5 or 10; then any form, a and b 2–10, the total
    /// written first half the time.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 3 {
            let form = Bool.random(using: &rng) ? 0 : 3, easy = [2, 5, 10].randomElement(using: &rng)!, other = Int.random(in: 2...10, using: &rng)
            return form == 0 ? numbers(a: easy, b: other, form: 0) : numbers(a: other, b: easy, form: 3)
        }
        let form = Int.random(in: 0...3, using: &rng), a = Int.random(in: 2...10, using: &rng), b = Int.random(in: 2...10, using: &rng)
        return numbers(a: a, b: b, form: form, flip: Double.random(in: 0..<1, using: &rng) < 0.5)
    }

    public static let spec = LessonSpec(id: "g3-unknown", title: "Find the missing number", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .op("×"), .num(Double(P.b)), .op("="), .num(Double(P.T))] },
        idea: { _ in "÷ is a times fact backwards." },
        depends: ["g3-divfacts"],
        check: [CheckItem(3, when: { Parts($0).form == 0 }), CheckItem(3, when: { Parts($0).form == 2 }),
                CheckItem(3, when: { Parts($0).form == 3 }), CheckItem(3, when: { Parts($0).flip })]) { x in
        let P = Parts(x)
        let dragHint = P.form == 3 ? "Stop when there are \(P.a) rows." : "Stop when the dots make \(P.T)."
        let drag = LessonStep(StepWords(say: P.say, hint: dragHint, action: "Check"),
            answer: G2.hand("e", P.want, hint: dragHint, explain: "\(P.a) rows of \(P.b) is \(P.T).", said: { n in P.dragged(n) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: "Write the missing number.", hint: P.hint, action: "Check"),
            answer: G3.typed("u", P.ans, P.slips, hint: P.hint, explain: "\(P.a) × \(P.b) = \(P.T)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 2])
        return [drag, write, done]
    }
}

// MARK: - Two-step word problems

/// Two-step word problems (the web's g3-twostep; 3.OA.D.8). The story on the picture's top rows; a thing is a dot in a cell.
/// Then fewer / then more: drag down to make the packs (each row outlined as one), write how many; slide the block of c over
/// the last ones (they're crossed out) or in after the last one; write how many now. Then share: the pile of a in rows of
/// 10; slide c away, write how many are left; drag across to share them into b (as Division facts), write how many in each.
///
/// "kind" 0 then fewer, 1 then more, 2 then share; "a", "b", "c", "who" (and "q" when sharing: a = b × q + c). "at": 0, 1,
/// 2, 3 the steps in order, 4 done. Boxes: "p" the packs let go at, "s" the slide (0 landed; else how many it covered),
/// "k" the share's columns, "g" and "h" the two typed answers.
public enum TwoStep3 {
    public static func numbers(kind: Int, a: Int, b: Int, c: Int, who: Int = 0) -> Numbers {
        ["kind": Double(kind), "a": Double(a), "b": Double(b), "c": Double(c), "who": Double(who)]
    }
    public static func share(b: Int, q: Int, c: Int, who: Int = 0) -> Numbers {
        ["kind": 2, "a": Double(b * q + c), "b": Double(b), "c": Double(c), "q": Double(q), "who": Double(who)]
    }
    public struct Who: Sendable { public let name, they, things, thing, groups, group, lose: String }
    public static let cast = [
        Who(name: "Mia", they: "She", things: "stickers", thing: "sticker", groups: "packs", group: "pack", lose: "gives away"),
        Who(name: "Leo", they: "He", things: "crayons", thing: "crayon", groups: "boxes", group: "box", lose: "loses"),
        Who(name: "Ava", they: "She", things: "marbles", thing: "marble", groups: "bags", group: "bag", lose: "loses"),
        Who(name: "Sam", they: "He", things: "cookies", thing: "cookie", groups: "trays", group: "tray", lose: "eats"),
    ]
    public struct Parts: Sendable {
        public let kind: Int, a: Int, b: Int, cc: Int, q: Int, w: Who
        public init(_ x: Numbers) {
            kind = max(0, min(2, G3.int(x, "kind")))
            w = TwoStep3.cast[max(0, min(3, G3.int(x, "who")))]
            if kind < 2 {
                a = max(2, min(9, G3.int(x, "a", 4))); b = max(2, min(10, G3.int(x, "b", 6))); q = 0
                cc = max(2, min(kind == 0 ? max(2, a * b - 1) : 20, G3.int(x, "c", 5)))
            } else {
                b = max(2, min(8, G3.int(x, "b", 3))); q = max(2, min(9, G3.int(x, "q", 9))); cc = max(2, min(15, G3.int(x, "c", 5))); a = b * q + cc
            }
        }
        /// The packs' total (then fewer, then more), or what's left to share.
        public var P: Int { kind < 2 ? a * b : a - cc }
        /// The second answer.
        public var ans2: Int { kind == 0 ? P - cc : kind == 1 ? P + cc : q }
        public var story: String {
            switch kind {
            case 0: return "\(w.name) has \(a) \(w.groups) of \(b) \(w.things). \(w.they) gives \(cc) \(w.things) away. How many \(w.things) does \(w.name) have left?"
            case 1: return "\(w.name) has \(a) \(w.groups) of \(b) \(w.things) and \(cc) more \(w.things). How many \(w.things) does \(w.name) have in all?"
            default: return "\(w.name) has \(a) \(w.things). \(w.they) \(w.lose) \(cc). \(w.they) shares the rest equally into \(b) \(w.groups). How many \(w.things) go in each \(w.group)?"
            }
        }
        /// The story's sentences (each a row if it fits).
        public var lines: [String] {
            var out: [String] = [], cur = ""
            for ch in story { cur.append(ch); if ch == "." || ch == "?" { out.append(cur.trimmingCharacters(in: .whitespaces)); cur = "" } }
            return out
        }
        public func packs(_ n: Int) -> String { "That's \(n) \(w.groups). \(w.name) has \(a) \(w.groups) of \(b)." }
        public func slid(_ cov: Int) -> String {
            kind == 1 ? "That's \(cov) in. Slide all \(cc) in after the last one." : "That covers \(cov). Slide all \(cc) over the last ones."
        }
        public func shared(_ k: Int) -> Verdict {
            if k == q { return .right }
            if k > q { return .wrong("\(b) × \(k) = \(b * k). That's more than \(P).") }
            if k > 0 { return .soft("\(b) × \(k) = \(b * k). \(P - b * k) are left. Keep going.") }
            return .soft("Drag across to share them into \(b) \(w.groups).")
        }
        public var firstSlips: [(Int, String)] {
            if kind == 2 { return [(a + cc, "\(cc) \(w.things) are gone, so there are fewer. Subtract.")] }
            return [(a + b, "\(a) \(w.groups) of \(b) is \(a) equal groups. Multiply: \(a) × \(b)."),
                    ((a - 1) * b, "That's \(a - 1) × \(b). There are \(a) \(w.groups): count \(b) more."),
                    ((a + 1) * b, "That's \(a + 1) × \(b). There are only \(a) \(w.groups).")]
        }
        public var firstHint: String { kind == 2 ? "Count back \(cc) from \(a)." : "Count by \(b)s, once for each of the \(a) \(w.groups)." }
        public var secondSlips: [(Int, String)] {
            switch kind {
            case 0: return [(P + cc, "Giving \(w.things) away leaves fewer. Subtract \(cc).")] + (b > cc ? [(a * (b - cc), "\(w.they) gave away \(cc) in all, not \(cc) from each \(w.group).")] : [])
            case 1: return [(P - cc, "\(cc) more means the total gets bigger. Add \(cc)."), (a * (b + cc), "The \(cc) extra \(w.things) are added once, not to each \(w.group).")]
            default:
                return [(P - b, "Sharing into \(b) equal \(w.groups) means dividing: \(b) × ? = \(P)."), (b, "\(b) is how many \(w.groups). How many go in each one?"),
                        (q + 1, "\(b) × \(q + 1) = \(b * (q + 1)), more than \(P). Each one gets fewer."),
                        (q - 1, "\(b) × \(q - 1) = \(b * (q - 1)), so \(P - b * (q - 1)) would be left over. Each one gets more.")]
            }
        }
        public var secondHint: String { kind == 0 ? "Count back \(cc) from \(P)." : kind == 1 ? "Count on \(cc) from \(P)." : "\(b) × ? = \(P)." }
        public static let why = "The first answer starts the second step."
    }

    /// The web's: the kind at random; problems 0–2 2–5 groups of 2, 5 or 10, c up to 9 (sharing into 2 or 5, each 2–5, c
    /// 2–9); then 2–9 groups of 3–9, c up to 20 and less than the total (sharing into 3–8, each 2–9, c 2–15).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ x: Int, _ y: Int) -> Int { Int.random(in: x...y, using: &rng) }
        let kind = r(0, 2), who = r(0, 3), early = i < 3
        if kind < 2 {
            let a = r(2, early ? 5 : 9), b = early ? [2, 5, 10].randomElement(using: &rng)! : r(3, 9)
            let c = kind == 0 ? r(2, min(a * b - 1, early ? 9 : 20)) : r(2, early ? 9 : 20)
            return numbers(kind: kind, a: a, b: b, c: c, who: who)
        }
        let b = early ? [2, 5].randomElement(using: &rng)! : r(3, 8), q = r(2, early ? 5 : 9), c = r(2, early ? 9 : 15)
        return share(b: b, q: q, c: c, who: who)
    }

    public static let spec = LessonSpec(id: "g3-twostep", title: "Two-step word problems", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.text(Parts(x).story)] },
        idea: { _ in Parts.why },
        depends: ["g3-facts", "g3-divfacts"],
        check: [CheckItem(3, when: { Parts($0).kind == 0 }), CheckItem(3, when: { Parts($0).kind == 1 }),
                CheckItem(3, when: { Parts($0).kind == 2 }), CheckItem(3, when: { Parts($0).kind == 2 })]) { x in
        let P = Parts(x), w = P.w
        let slideSay = P.kind == 1 ? "Slide \(P.cc) in." : "Slide \(P.cc) away."
        let slideHint = P.kind == 1 ? "Let go just after the last one." : "Let go right over the last ones."
        let slide = LessonStep(StepWords(say: slideSay, hint: slideHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("s")], expected: ["s": 0], hint: slideHint, explain: P.kind == 1 ? "\(P.cc) more." : "\(P.cc) gone.",
                               check: { v in
                                   guard let s = v["s"] else { return .soft(slideSay) }
                                   let k = Int(s.rounded())
                                   return k == 0 ? .right : k > 0 ? .wrong(P.slid(k)) : .soft(slideSay)
                               }, byHand: true),
            picture: ["at": P.kind == 2 ? 0 : 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let first = LessonStep(StepWords(say: P.kind == 2 ? "Write how many are left." : "Write how many \(w.things).", hint: P.firstHint, action: "Check"),
            answer: G3.typed("g", P.P, P.firstSlips, hint: P.firstHint, explain: P.kind == 2 ? "\(P.a) − \(P.cc) = \(P.P)." : "\(P.a) × \(P.b) = \(P.P)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let secondSay = P.kind == 0 ? "Write how many are left." : P.kind == 1 ? "Write how many in all." : "Write how many go in each \(w.group)."
        let second = LessonStep(StepWords(say: secondSay, hint: P.secondHint, action: "Check"),
            answer: G3.typed("h", P.ans2, P.secondSlips, hint: P.secondHint,
                             explain: P.kind == 2 ? "\(P.P) ÷ \(P.b) = \(P.q)." : "\(P.P) \(P.kind == 0 ? "−" : "+") \(P.cc) = \(P.ans2)."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 4])
        if P.kind == 2 {
            let shareHint = "Each \(w.group) takes one more with every column."
            let share = LessonStep(StepWords(say: "Drag across to share them into \(P.b) \(w.groups).", hint: shareHint, action: "Check"),
                answer: AnswerTask(prompt: [.box("k")], expected: ["k": Double(P.q)], hint: shareHint, explain: "\(P.b) × \(P.q) = \(P.P).",
                                   check: { v in P.shared(Int((v["k"] ?? 0).rounded())) }, byHand: true),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [slide, first, share, second, done]
        }
        let packsHint = "Stop when there are \(P.a) \(w.groups)."
        let packs = LessonStep(StepWords(say: "Drag down to make \(P.a) \(w.groups) of \(P.b).", hint: packsHint, action: "Check"),
            answer: G2.hand("p", P.a, hint: packsHint, explain: "\(P.a) \(w.groups) of \(P.b).", said: { n in P.packs(n) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [packs, first, slide, second, done]
    }
}
