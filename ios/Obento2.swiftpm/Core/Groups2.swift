import Foundation

/// What 2nd grade's chapter 3, Equal groups, shares (design/grade2.md chapter 3, the preview design/prototype/grade2-ch3.html):
/// the record of rows added (`4 + 4 + 4 = [ ]`) and the lines the arrays and the squares both say, word for word. Every
/// number the child writes is typed with the iPad's keys and Check, as the preview types; the hands do the rest.
public enum Groups2 {
    /// c + c + c, once for each row.
    public static func repeated(_ rows: Int, _ cols: Int) -> [Int] { Array(repeating: cols, count: rows) }
    public static func slips(_ R: Int, _ C: Int) -> [(Int, String)] {
        [(R * C - C, "There are \(R) rows, so add \(C) \(R) times."), (R * C + C, "There are only \(R) rows. Add \(C) \(R) times.")]
    }
    public static func plain(_ C: Int) -> String { "Skip count by \(C)s, once for each row." }
    /// A sweep down a column on "Tap each row."
    public static let down = "That goes down. Rows go across."
    public static let rowHint = "Tap each row from top to bottom."
}

// MARK: - Even and odd

/// Even and odd (the web's g2-evenodd; 2.OA.C.3, fold: an even number as two equal addends). A dot is a 3 × 3 counter; the
/// dots lie loose on a field of three rows of ten places, the number at its right end, Facts to 20's pair frame (two rows
/// of ten) under it. Tap each dot (or drag across them): it takes the next number and hops into the frame, top then bottom,
/// column by column; each full column rings as a pair, the readout counts by 2s. Then even or odd, then the two rows
/// written, `13 = [6] + [6] + 1`.
///
/// "n", "mix" (where the dots lie). "at": 0 count, 1 pick, 2 write, 3 done. Boxes: "k" the dots counted (n), "c" the pick
/// (0 even, 1 odd), "a" "b" the rows.
public enum EvenOdd2 {
    public static func numbers(n: Int, mix: Int = 0) -> Numbers { ["n": Double(n), "mix": Double(mix)] }
    public struct Parts: Sendable {
        public let n: Int, mix: Int
        public init(_ x: Numbers) { n = max(2, min(20, G2.int(x, "n", 13))); mix = G2.int(x, "mix") }
        public var pairs: Int { n / 2 }
        public var odd: Bool { n % 2 == 1 }
        public var word: String { odd ? "odd" : "even" }
        /// The places (0–29: row × 10 + column) the dots lie on, in the field's three rows of ten.
        public var places: [Int] {
            var rng = SeededRandom(seed: UInt64(max(0, mix)) &* 7 &+ 3)
            return (0..<30).map { ($0, Int.random(in: 0...99999, using: &rng)) }.sorted { $0.1 < $1.1 }.prefix(n).map(\.0)
        }
        public var pickMiss: String {
            odd ? "One dot is left over without a partner, so \(n) is odd." : "Every dot has a partner and none are left over, so \(n) is even."
        }
        public var why: String { odd ? "One dot has no partner, so \(n) is odd." : "Every dot has a partner, so \(n) is even." }
        /// The rows written: right, or what the preview says.
        public func rows(_ a: Int, _ b: Int) -> String? {
            if a == pairs && b == pairs { return nil }
            if odd && a == pairs + 1 && b == pairs + 1 { return "That's \(2 * pairs + 2). Each row has \(pairs), and 1 is left." }
            if a == n || b == n { return "That's all \(n) dots. Write how many are in one row." }
            if a != b { return "Both rows have the same number of dots." }
            return "That's \(a + b + (odd ? 1 : 0)). Count the dots in one row."
        }
    }

    /// The preview's: problems 0–2 4–12, then 7–20.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        numbers(n: i < 3 ? Int.random(in: 4...12, using: &rng) : Int.random(in: 7...20, using: &rng), mix: Int.random(in: 0...9999, using: &rng))
    }

    public static let spec = LessonSpec(id: "g2-evenodd", title: "Even and odd", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.num(Double(Parts(x).n))] },
        idea: { _ in "A dot with no partner makes it odd." },
        depends: ["k-count20"],
        check: [CheckItem(0, when: { !Parts($0).odd }), CheckItem(0, when: { Parts($0).odd }),
                CheckItem(3, when: { !Parts($0).odd && Parts($0).n >= 15 }), CheckItem(3, when: { Parts($0).odd && Parts($0).n >= 15 })]) { x in
        let P = Parts(x)
        let countHint = "Tap the dots that are left."
        let count = LessonStep(StepWords(say: "Tap each dot.", hint: countHint, action: "Check"),
            answer: G2.hand("k", P.n, hint: countHint, explain: "\(G2.count(P.pairs, "pair"))\(P.odd ? " and 1" : "").", said: { _ in countHint }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let pickHint = P.odd ? "Look for a dot with no partner." : "Look for a dot with no partner. Is there one?"
        let pick = LessonStep(StepWords(say: "Tap even or odd.", hint: pickHint, action: "Check"),
            answer: G2.hand("c", P.odd ? 1 : 0, hint: pickHint, explain: P.why, said: { _ in P.pickMiss }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let rowHint = "Count the dots in the top row."
        var prompt: [Math] = [.num(Double(P.n)), .op("="), .box("a"), .op("+"), .box("b")]
        if P.odd { prompt += [.op("+"), .num(1)] }
        let write = LessonStep(StepWords(say: "Write how many are in each row.", hint: rowHint, action: "Check"),
            answer: AnswerTask(prompt: prompt, expected: ["a": Double(P.pairs), "b": Double(P.pairs)], hint: rowHint,
                               explain: "\(P.n) = \(P.pairs) + \(P.pairs)\(P.odd ? " + 1" : "").",
                               check: { v in
                                   guard let a = v["a"], let b = v["b"] else { return .soft("Write how many are in each row.") }
                                   return P.rows(Int(a.rounded()), Int(b.rounded())).map { .wrong($0) } ?? .right
                               }, incomplete: "Write how many are in each row."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [count, pick, write, done]
    }
}

// MARK: - Arrays

/// Arrays (the web's g2-arrays; 2.OA.C.4). A dot sits in the middle of its own block (Kindergarten's dot), so the strong
/// lines run between the rows and the columns; the story kind (every fourth) draws the muffin box round it. Tap each row
/// (it lights and takes its number at the left), count one row (its dots number), then write `4 + 4 + 4 = [12]`; once it's
/// right the running totals write in at the rows' right ends.
///
/// "rows", "cols", "story". "at": 0 rows, 1 one row, 2 write, 3 done. Boxes: "r" the rows lit (R; −1 a sweep down a
/// column), "c" the dots counted in one row (C; −1 a dot in another row), "x" the sum.
public enum Arrays2 {
    public static func numbers(rows: Int, cols: Int, story: Bool = false) -> Numbers { ["rows": Double(rows), "cols": Double(cols), "story": story ? 1 : 0] }
    public struct Parts: Sendable {
        public let R: Int, C: Int, story: Bool
        public init(_ x: Numbers) { R = max(2, min(5, G2.int(x, "rows", 3))); C = max(2, min(5, G2.int(x, "cols", 4))); story = G2.int(x, "story") != 0 }
        public var T: Int { R * C }
        public var lines: [String] { ["A box of muffins has \(R) rows with \(C) muffins in each row.", "How many muffins are in the box?"] }
        public var why: String { "Every row has \(C), so add \(C) for each row." }
        public var add: String { "Add \(C) once for each row." }
        public var slips: [(Int, String)] { [(R + C, "Add \(C) once for every row: that's \(R) times.")] + Groups2.slips(R, C) }
    }

    /// The preview's: 2–5 rows of 2–5 (problems 0–2 up to 4 by 4); every fourth the muffin story.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let hi = i < 3 ? 4 : 5
        return numbers(rows: Int.random(in: 2...hi, using: &rng), cols: Int.random(in: 2...hi, using: &rng), story: i % 4 == 3)
    }

    public static let spec = LessonSpec(id: "g2-arrays", title: "Arrays", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.R)), .text("rows of"), .num(Double(P.C))] },
        idea: { _ in "Every row has the same number, so add it once for each row." },
        depends: ["g2-skip"],
        check: [CheckItem(0), CheckItem(4, when: { Parts($0).R != Parts($0).C }), CheckItem(5, when: { Parts($0).R == 5 || Parts($0).C == 5 }), CheckItem(3)]) { x in
        let P = Parts(x)
        let rows = LessonStep(StepWords(say: "Tap each row.", hint: Groups2.rowHint, action: "Check"),
            answer: G2.hand("r", P.R, hint: Groups2.rowHint, explain: G2.count(P.R, "row") + ".", said: { _ in Groups2.down }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let oneHint = "Count across one row. Every row is the same."
        let one = LessonStep(StepWords(say: "Count one row.", hint: oneHint, action: "Check"),
            answer: G2.hand("c", P.C, hint: oneHint, explain: "\(P.C) in a row.", said: { _ in "That's down. Count across." }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let sum = Groups2.repeated(P.R, P.C).map(String.init).joined(separator: " + ")
        let addHint = "Add \(P.C) for every row: " + (1...P.R).map { "\($0 * P.C)" }.joined(separator: ", ") + "."
        let write = LessonStep(StepWords(say: P.add, hint: Groups2.plain(P.C), action: "Check"),
            answer: G2.typed("x", P.T, P.slips, plain: Groups2.plain(P.C), hint: addHint, explain: "\(sum) = \(P.T)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [rows, one, write, done]
    }
}

// MARK: - Rows and columns of squares

/// Rows and columns of squares (g2-squares, new; 2.G.A.2). A square tile is a block, so every cut falls on a strong line:
/// a rectangle 2–5 blocks tall and 2–6 across, plain inside. Cut it into rows (drag down its left side: the cuts snap to
/// equal rows that fit, dashed, Cut), then the rows into squares (along the top), tap each row, then write
/// `4 + 4 + 4 = [12] squares`; once it's right the running totals write in. From problem 3 the columns come first in half.
///
/// "rows", "cols", "first" (1 rows first, 0 columns). "at": 0 the first cut, 1 the second, 2 tap each row, 3 write, 4 done.
/// Boxes: "k1" the pieces the first cut makes (0: no cut dragged), "k2" the second cut's piece in squares (5 a square; 0
/// none), "r" the rows lit, "x" the squares.
public enum Squares2 {
    public static func numbers(rows: Int, cols: Int, rowsFirst: Bool = true) -> Numbers { ["rows": Double(rows), "cols": Double(cols), "first": rowsFirst ? 1 : 0] }
    public struct Parts: Sendable {
        public let R: Int, C: Int, rowsFirst: Bool
        public init(_ x: Numbers) { R = max(2, min(5, G2.int(x, "rows", 3))); C = max(2, min(6, G2.int(x, "cols", 4))); rowsFirst = G2.int(x, "first", 1) != 0 }
        public var T: Int { R * C }
        /// The axis each cut runs along: true, the rows (down the left side).
        public func rowsCut(_ cut: Int) -> Bool { cut == 0 ? rowsFirst : !rowsFirst }
        public func len(_ rows: Bool) -> Int { rows ? 5 * R : 5 * C }
        public static func name(_ rows: Bool) -> String { rows ? "rows" : "columns" }
        /// The piece sizes a cut can snap to: whole squares that share the side out evenly (2 or more, not the whole side).
        public func sizes(_ rows: Bool) -> [Int] { let l = len(rows); return (2..<l).filter { l % $0 == 0 } }
        public var firstSay: String { rowsFirst ? "Cut it into \(G2.count(R, "row"))." : "Cut it into \(G2.count(C, "column"))." }
        public var secondSay: String { rowsFirst ? "Now cut the rows into squares." : "Now cut the columns into squares." }
        public static func drag(_ rows: Bool) -> String { rows ? "Drag down its left side to cut it." : "Drag along its top to cut it." }
        /// The first cut made into k pieces.
        public func first(_ k: Int) -> String {
            let rows = rowsCut(0)
            return k <= 0 ? Self.drag(rows) : "That's \(k) \(Self.name(rows)). Cut \(rows ? R : C)."
        }
        /// The second cut's pieces s squares long (along its axis).
        public func second(_ s: Int) -> String {
            let rows = rowsCut(1)
            if s <= 0 { return Self.drag(rows) }
            return "Those are \(rows ? 5 : s) squares wide and \(rows ? s : 5) tall."
        }
        public var slips: [(Int, String)] {
            [(25 * T, "That counts the paper's small squares. Count the ones you cut."), (R + C, "That's \(R) + \(C). Add \(C) for each row.")] + Groups2.slips(R, C)
        }
        public static let why = "Same-size squares, so every row has the same number."
    }

    /// The design's: problems 0–2 2–3 rows and 2–4 columns, rows cut first; from 3 rows 2–5, columns 2–6, the columns
    /// first in half.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        func r(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b, using: &rng) }
        if i < 3 { return numbers(rows: r(2, 3), cols: r(2, 4)) }
        return numbers(rows: r(2, 5), cols: r(2, 6), rowsFirst: r(0, 1) == 1)
    }

    public static let spec = LessonSpec(id: "g2-squares", title: "Rows and columns of squares", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.R)), .text("rows of"), .num(Double(P.C))] },
        idea: { _ in Parts.why },
        depends: ["g2-arrays"],
        check: [CheckItem(0), CheckItem(3, when: { Parts($0).R >= 4 }), CheckItem(4, when: { Parts($0).C >= 5 }), CheckItem(5)]) { x in
        let P = Parts(x)
        let r0 = P.rowsCut(0)
        let firstHint = r0 ? "Make \(G2.count(P.R, "row")) the same size." : "Make \(G2.count(P.C, "column")) the same size."
        let cut1 = LessonStep(StepWords(say: P.firstSay, hint: firstHint, action: "Cut"),
            answer: AnswerTask(prompt: [.box("k1")], expected: ["k1": Double(r0 ? P.R : P.C)], hint: firstHint, explain: P.firstSay,
                               check: { v in
                                   let k = Int((v["k1"] ?? 0).rounded())
                                   return k == (r0 ? P.R : P.C) ? .right : k <= 0 ? .soft(P.first(0)) : .wrong(P.first(k))
                               }, byHand: true),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let secondHint = "A square is as wide as it's tall."
        let cut2 = LessonStep(StepWords(say: P.secondSay, hint: secondHint, action: "Cut"),
            answer: AnswerTask(prompt: [.box("k2")], expected: ["k2": 5], hint: secondHint, explain: "\(P.T) squares.",
                               check: { v in
                                   let s = Int((v["k2"] ?? 0).rounded())
                                   return s == 5 ? .right : s <= 0 ? .soft(P.second(0)) : .wrong(P.second(s))
                               }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let rows = LessonStep(StepWords(say: "Tap each row.", hint: Groups2.rowHint, action: "Check"),
            answer: G2.hand("r", P.R, hint: Groups2.rowHint, explain: G2.count(P.R, "row") + ".", said: { _ in Groups2.down }),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let sum = Groups2.repeated(P.R, P.C).map(String.init).joined(separator: " + ")
        let addHint = "Add \(P.C) for every row: " + (1...P.R).map { "\($0 * P.C)" }.joined(separator: ", ") + "."
        let write = LessonStep(StepWords(say: "Write how many squares.", hint: Groups2.plain(P.C), action: "Check"),
            answer: G2.typed("x", P.T, P.slips, plain: Groups2.plain(P.C), hint: addHint, explain: "\(sum) = \(P.T) squares."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 4])
        return [cut1, cut2, rows, write, done]
    }
}
