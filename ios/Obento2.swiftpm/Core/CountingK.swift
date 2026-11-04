import Foundation

/// What Kindergarten's Count to 10 chapter shares (design/gradeK.md, the preview design/prototype/gradeK-ch1.html): one
/// block is one thing (a dot 3 squares across in the middle of its block, a cube filling it), the ten track is K's
/// number line (ten outlined blocks), and every number the child writes is tapped on the number row drawn under the
/// record (0–10), never typed. Most kindergartners can't read yet, so every line here is also spoken (App's Voice).
public enum CountK {
    static func int(_ v: [String: Double], _ k: String, _ d: Int = 0) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    static func pick<T>(_ a: [T], _ rng: inout SeededRandom) -> T { a[Int.random(in: 0..<a.count, using: &rng)] }
    /// The number row's keys.
    public static let row = 0...10
    /// "1 cube", "2 cubes".
    public static func plural(_ n: Int, _ one: String, _ many: String) -> String { "\(n) \(n == 1 ? one : many)" }
    /// A step answered by a tap on the number row: its box, what it should hold, the known slips and what else to say.
    static func write(_ box: String, _ want: Int, known: [(Int, String)], other: @escaping @Sendable (Int) -> String, hint: String, explain: String) -> AnswerTask {
        AnswerTask(prompt: [.box(box)], expected: [box: Double(want)],
                   known: known.map { ([box: Double($0.0)], $0.1) }, hint: hint, explain: explain,
                   check: { v in
                       let x = Int((v[box] ?? -1).rounded())
                       return x == want ? .right : .wrong(other(x))
                   }, incomplete: "Tap a number.", byHand: true)
    }
}

// MARK: - Count to 10

/// Count to 10 (gk-count10, new; K.CC.B.4a, 4b, 5). Two kinds of problem, by turns after the first three.
///
/// How many? Up to 10 dots on a field of 10 × 4 blocks: in a line, an array (rows of equal length touching), round a ring
/// (the blocks round the edge of a 4 × 3 rectangle) or scattered (no two in blocks that share a side); an empty ten track
/// a block under them. Tap each dot: it gets the next number; the last is ringed. Then the dots go onto the track in the
/// order they were counted (the same count, however they sat), and the count is written with the number row.
///
/// Make 7: only the ten track. Drag along it: cubes fill from the start line, each numbered.
///
/// "at": 0 count, 1 write, 2 done; the make kind: 3 make, 4 done.
public enum CountToTen {
    public enum Kind: Int, Sendable { case count, make }
    public enum Lay: Int, Sendable { case line, array, ring, scattered }
    /// The arrays: rows × columns.
    public static let arrays: [Int: (Int, Int)] = [4: (2, 2), 6: (2, 3), 8: (2, 4), 9: (3, 3), 10: (2, 5)]
    /// The ring's places, round a rectangle 4 blocks across and 3 down, from its top-left corner clockwise.
    static let ring: [(Int, Int)] = [(0, 0), (1, 0), (2, 0), (3, 0), (3, 1), (3, 2), (2, 2), (1, 2), (0, 2), (0, 1)]
    /// Fewer than 10 spread evenly round it: the corners first, then the sides' middles, so it always reads as a ring.
    static let ringSets: [Int: [Int]] = [4: [0, 3, 5, 8], 5: [0, 2, 4, 6, 8], 6: [0, 3, 4, 5, 8, 9], 7: [0, 1, 3, 4, 5, 8, 9],
                                         8: [0, 1, 3, 4, 5, 6, 8, 9], 9: [0, 1, 2, 3, 4, 5, 6, 8, 9], 10: Array(0..<10)]

    /// `places`: each dot's block (column 0–9, row 0–3) in the field.
    public static func numbers(kind: Kind = .count, n: Int, lay: Lay = .line, places: [(Int, Int)] = []) -> Numbers {
        var x: Numbers = ["kind": Double(kind.rawValue), "n": Double(n), "lay": Double(lay.rawValue)]
        let rows = places.map(\.1).max().map { $0 + 1 } ?? 0
        x["rows"] = Double(rows)
        for (j, p) in places.enumerated() { x["p\(j)"] = Double(p.0 + 10 * p.1) }
        return x
    }
    /// A line of n dots from column c0.
    public static func line(_ n: Int, from c0: Int = 0) -> Numbers { numbers(n: n, lay: .line, places: (0..<n).map { (c0 + $0, 0) }) }

    public struct Parts: Sendable {
        public let kind: Kind, n: Int, lay: Lay, rows: Int
        public let places: [(col: Int, row: Int)]
        public init(_ x: Numbers) {
            kind = Kind(rawValue: CountK.int(x, "kind")) ?? .count
            n = max(1, min(10, CountK.int(x, "n", 1)))
            lay = Lay(rawValue: CountK.int(x, "lay")) ?? .line
            rows = CountK.int(x, "rows", 1)
            places = kind == .make ? [] : (0..<n).map { j in let p = CountK.int(x, "p\(j)"); return (p % 10, p / 10) }
        }
        public var say: String { kind == .make ? "Make \(n)." : "Tap each dot." }
        public static let why = "The last number you say is how many."
        /// A drag along the track let go on `m` cubes: nil when it's right.
        public func made(_ m: Int) -> String? { m == n ? nil : "That’s \(m). Make \(n)." }
        /// A number tapped on the row: what to say.
        public func wrote(_ v: Int) -> String {
            v == n - 1 ? "One short. The last number was \(n)." : v == n + 1 ? "One too many. The last number was \(n)." : "The last number was \(n)."
        }
    }

    /// Easy first: index 0–2 count, n 1–5, a line; 3–5 n 1–10, count and make by turns, a line, an array or scattered;
    /// 6+ any kind and lay, n 4–10 (rings only from here).
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        var kind = Kind.count, n: Int, lay = Lay.line
        if index < 3 { n = Int.random(in: 1...5, using: &rng) }
        else {
            kind = index < 6 ? (index % 2 == 1 ? .count : .make) : (Bool.random(using: &rng) ? .count : .make)
            n = index < 6 ? Int.random(in: 1...10, using: &rng) : Int.random(in: 4...10, using: &rng)
            let lays: [Lay] = (index < 6 ? [.line, .array, .scattered] : [.line, .array, .ring, .scattered]).filter { $0 != .array || arrays[n] != nil }
            lay = CountK.pick(lays, &rng)
        }
        if kind == .make { return numbers(kind: .make, n: n, lay: .line) }
        return numbers(kind: .count, n: n, lay: lay, places: places(lay, n, &rng))
    }

    /// Where the dots sit for a lay.
    static func places(_ lay: Lay, _ n: Int, _ rng: inout SeededRandom) -> [(Int, Int)] {
        switch lay {
        case .line:
            let c0 = Int.random(in: 0...(10 - n), using: &rng)
            return (0..<n).map { (c0 + $0, 0) }
        case .array:
            let (r, c) = arrays[n] ?? (1, n), c0 = Int.random(in: 0...(10 - c), using: &rng)
            return (0..<r).flatMap { a in (0..<c).map { b in (c0 + b, a) } }
        case .ring:
            let c0 = Int.random(in: 0...6, using: &rng)
            return (ringSets[n] ?? Array(0..<n)).map { (c0 + ring[$0].0, ring[$0].1) }
        case .scattered:
            var out: [(Int, Int)] = [], tries = 0
            while out.count < n {
                tries += 1
                if tries > 400 { out = []; tries = 0 }
                let c = Int.random(in: 0...9, using: &rng), r = Int.random(in: 0...3, using: &rng)
                if out.contains(where: { abs($0.0 - c) + abs($0.1 - r) <= 1 }) { continue }
                out.append((c, r))
            }
            return out
        }
    }

    public static let spec = LessonSpec(id: "gk-count10", title: "Count to 10", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { n in [.num(Double(Parts(n).n))] },
        idea: { _ in Parts.why },
        depends: [],
        check: [CheckItem(3, when: { Parts($0).lay == .scattered && Parts($0).n >= 7 && Parts($0).kind == .count }),
                CheckItem(6, when: { Parts($0).lay == .ring && Parts($0).kind == .count }),
                CheckItem(4, when: { Parts($0).kind == .make }), CheckItem(3)]) { x in
        let P = Parts(x), n = P.n
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": P.kind == .make ? 4 : 2])
        if P.kind == .make {
            let make = LessonStep(StepWords(say: P.say, hint: "Fill a cube for each number, 1 to \(n).", action: "Check"),
                answer: AnswerTask(prompt: [.box("m")], expected: ["m": Double(n)], hint: "Fill a cube for each number, 1 to \(n).", explain: "\(n) cubes.",
                                   check: { v in P.made(Int((v["m"] ?? 0).rounded())).map { .wrong($0) } ?? .right }, byHand: true),
                picture: ["at": 3], onMiss: ["over": 1], hint2: ["spot": 1])
            return [make, done]
        }
        let count = LessonStep(StepWords(say: P.say, hint: "Tap each dot once.", action: "Check"),
            answer: AnswerTask(prompt: [.box("c")], expected: ["c": Double(n)], hint: "Tap each dot once.", explain: "Each dot gets one number.",
                               check: { v in Int((v["c"] ?? -1).rounded()) == n ? .right : .wrong("You counted that one.") }, byHand: true),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: "Write how many.", hint: "The last number was \(n).", action: "Check"),
            answer: CountK.write("n", n, known: [(n - 1, P.wrote(n - 1)), (n + 1, P.wrote(n + 1))], other: { P.wrote($0) },
                                 hint: "The last number was \(n).", explain: "The last number was \(n), so there are \(n)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [count, write, done]
    }
}

// MARK: - One more

/// One more (gk-onemore, new; K.CC.B.4c, K.CC.A.2). One block is one cube. The number stairs: trains of 1, 2, … n cubes,
/// one under the other, left ends on one start line, each train's number at its right end; under the last an empty row
/// of 10 dashed blocks. Drag the new train out a cube at a time: one past the train above. Write 1 more than n on the
/// number row. Then the stair is seen: the last cube of each train lights in turn.
///
/// "at": 0 make, 1 write, 2 done.
public enum OneMore {
    public static func numbers(n: Int) -> Numbers { ["n": Double(n)] }
    public struct Parts: Sendable {
        public let n: Int
        public init(_ x: Numbers) { n = max(1, min(9, CountK.int(x, "n", 1))) }
        public var answer: Int { n + 1 }
        /// The new train let go on `m` cubes (or `m` tapped on the row): what to say, nil when it's right.
        public func said(_ m: Int) -> String? {
            if m == n + 1 { return nil }
            if m == n { return "That’s \(n) again. One more." }
            if m > n { return "That’s \(m): \(m - n) more." }
            return "That’s less than \(n)."
        }
        public static let why = "Each next number is one more cube."
    }
    /// Easy first: index 0–2 n 1–4; then 1–9.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers { numbers(n: Int.random(in: 1...(index < 3 ? 4 : 9), using: &rng)) }

    public static let spec = LessonSpec(id: "gk-onemore", title: "One more", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in [.text("1 more than"), .num(Double(Parts(x).n))] },
        idea: { _ in Parts.why },
        depends: ["gk-count10"],
        check: [CheckItem(3, when: { Parts($0).n <= 4 }), CheckItem(3, when: { Parts($0).n >= 7 }), CheckItem(3, when: { Parts($0).n == 9 }), CheckItem(3)]) { x in
        let P = Parts(x), n = P.n
        let hint = "One more cube than the train above."
        let make = LessonStep(StepWords(say: "Make one more.", hint: hint, action: "Check"),
            answer: AnswerTask(prompt: [.box("m")], expected: ["m": Double(n + 1)], hint: hint, explain: "\(n) and 1 more is \(n + 1).",
                               check: { v in P.said(Int((v["m"] ?? 0).rounded())).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: "Write 1 more than \(n).", hint: "Count the new train's cubes.", action: "Check"),
            answer: CountK.write("x", n + 1, known: [(n, P.said(n)!), (n + 2, P.said(n + 2)!), (n - 1, P.said(n - 1) ?? "")].filter { $0.0 >= 0 },
                                 other: { P.said($0) ?? "" }, hint: "Count the new train's cubes.", explain: "1 more than \(n) is \(n + 1)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 2])
        return [make, write, done]
    }
}

// MARK: - More, less or the same

/// More, less or the same (the web app's k-compare, K.CC.C.6). One block is one dot. Two ten tracks a block apart; the
/// top row sits on its track from the start line, the bottom row starts out of line: spread out (a block between dots)
/// when it's the smaller row and has 5 or fewer, so it looks longer than it is; otherwise shifted 1–3 blocks right,
/// never ending past 12 blocks. Count each row (the web's two count boxes set from the taps), slide the bottom row under
/// the top one's start (partner lines draw, the dots with no partner are ringed), then tap the row with more or "same".
///
/// "at": 0 count, 1 line up, 2 pick, 3 done.
public enum CompareGroups {
    public static let choices = ["more than", "less than", "the same as"]
    public static func numbers(top: Int, bottom: Int, spread: Bool = false, shift: Int = 1) -> Numbers {
        ["top": Double(top), "bottom": Double(bottom), "spread": spread ? 1 : 0, "shift": Double(shift)]
    }
    public struct Parts: Sendable {
        public let top: Int, bottom: Int, spread: Bool, shift: Int
        public init(_ x: Numbers) {
            top = max(1, min(10, CountK.int(x, "top", 1))); bottom = max(1, min(10, CountK.int(x, "bottom", 1)))
            spread = CountK.int(x, "spread") == 1; shift = CountK.int(x, "shift")
        }
        /// 0 the top row has more, 1 the bottom row has more (the top is less), 2 the same.
        public var right: Int { top > bottom ? 0 : top < bottom ? 1 : 2 }
        public var extra: Int { abs(top - bottom) }
        /// Where the bottom row's dots start, in blocks, before it's lined up.
        public var slots: [Int] { (0..<bottom).map { spread ? 2 * $0 : $0 } }
        /// The row (or "same") tapped: what to say, nil when it's right. `c`: 0 top, 1 bottom, 2 same.
        public func picked(_ c: Int) -> String? {
            if c == right { return nil }
            if c == 2 { return extra == 1 ? "1 dot has no partner." : "\(extra) dots have no partner." }
            if right == 2 { return "Look again: every dot has a partner." }
            let more = right == 0 ? "top" : "bottom", less = right == 0 ? "bottom" : "top"
            return "Every \(less) dot has a partner. \(extra) \(more) \(extra == 1 ? "dot doesn’t" : "dots don’t")."
        }
        /// "6 is more than 4".
        public var sentence: String { "\(top) is \(CompareGroups.choices[right]) \(bottom)" }
        public static let why = "The row with dots left over has more."
    }

    /// The web's generator as it is: top and bottom 1–10 (the first three 5 at most and 2 apart; after that 1 in 5 the
    /// same). New here: where the bottom row starts (it never changes the answer).
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        let hi = index < 3 ? 5 : 10, top = Int.random(in: 1...hi, using: &rng)
        var bottom = top
        if !(index >= 3 && Int.random(in: 0...4, using: &rng) == 0) {
            let gap = index < 3 ? 2 : 1
            bottom = CountK.pick((1...hi).filter { abs($0 - top) >= gap }, &rng)
        }
        let spread = bottom < top && bottom <= 5 && bottom > 1
        let shift = spread ? 0 : Int.random(in: 1...min(3, 12 - bottom), using: &rng)
        return numbers(top: top, bottom: bottom, spread: spread, shift: shift)
    }

    public static let spec = LessonSpec(id: "k-compare", title: "More, less or the same", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in let P = Parts(x); return [.num(Double(P.top)), .text("and"), .num(Double(P.bottom))] },
        idea: { _ in "When you match the dots in pairs, the row with dots left over has more." },
        depends: ["gk-count10"],
        check: [CheckItem(3, when: { Parts($0).top > Parts($0).bottom }), CheckItem(3, when: { Parts($0).top < Parts($0).bottom }),
                CheckItem(3, when: { Parts($0).top == Parts($0).bottom }), CheckItem(3, when: { Parts($0).extra == 1 })]) { x in
        let P = Parts(x)
        let count = LessonStep(StepWords(say: "Count each row.", hint: "Tap each dot once.", action: "Check"),
            answer: AnswerTask(prompt: [.box("top"), .box("bottom")], expected: ["top": Double(P.top), "bottom": Double(P.bottom)],
                               hint: "Tap each dot once.", explain: "The top row has \(P.top). The bottom row has \(P.bottom).",
                               check: { v in Int((v["top"] ?? -1).rounded()) == P.top && Int((v["bottom"] ?? -1).rounded()) == P.bottom ? .right : .wrong("You counted that one.") },
                               byHand: true),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let line = LessonStep(StepWords(say: "Line them up.", hint: "Start it under the top row.", action: "Check"),
            answer: AnswerTask(prompt: [.box("l")], expected: ["l": 1], hint: "Start it under the top row.", explain: "One dot under each dot.",
                               check: { v in v["l"] == 1 ? .right : .wrong("Start it under the top row.") }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let pick = LessonStep(StepWords(say: "Tap the row with more.", hint: "Which row has dots left over?", action: "Check"),
            answer: AnswerTask(prompt: [.box("c")], expected: ["c": Double(P.right)], hint: "Which row has dots left over?", explain: Parts.why,
                               check: { v in P.picked(Int((v["c"] ?? -1).rounded())).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [count, line, pick, done]
    }
}

// MARK: - Which number is more?

/// Which number is more? (gk-numcompare, new; K.CC.C.7). One block is one cube. Two numerals at the start of two empty
/// ten tracks (they're what to build). Make each number (drag out a train), see where the shorter one stops and the
/// longer one's extra cubes ("2 more"), then tap the number that's more (or less). The record is written by the tap.
///
/// "at": 0 make, 1 pick, 2 done.
public enum CompareNumbers {
    public static func numbers(a: Int, b: Int, less: Bool = false) -> Numbers { ["a": Double(a), "b": Double(b), "ask": less ? 1 : 0] }
    public struct Parts: Sendable {
        public let a: Int, b: Int, less: Bool
        public init(_ x: Numbers) { a = max(1, min(10, CountK.int(x, "a", 1))); b = max(1, min(10, CountK.int(x, "b", 2))); less = CountK.int(x, "ask") == 1 }
        public var big: Int { max(a, b) }
        public var small: Int { min(a, b) }
        public var extra: Int { big - small }
        /// The row to tap: 0 (a's) or 1 (b's).
        public var want: Int { less ? (a < b ? 0 : 1) : (a > b ? 0 : 1) }
        public var value: [Int] { [a, b] }
        public var say: String { less ? "Tap the one that’s less." : "Tap the one that’s more." }
        public var why: String { less ? "\(small) comes before \(big) when you count, so \(small) is less." : "\(big) comes after \(small) when you count, so \(big) is more." }
        public var missed: String { "\(small) stops \(CountK.plural(extra, "cube", "cubes")) before \(big)." }
        /// "8 is more than 6" (or "6 is less than 8").
        public var sentence: String { less ? "\(small) is less than \(big)" : "\(big) is more than \(small)" }
        /// What the make step's box holds: 0 both made, else 100 × the row + the cubes it was let go on.
        public static func code(row: Int, m: Int) -> Double { Double(100 * row + m) }
        public func made(_ code: Int) -> String? {
            guard code != 0 else { return nil }
            let r = code / 100, m = code % 100
            return "That’s \(m). Make \(value[min(1, max(0, r))])."
        }
    }
    /// a, b 1–10, never the same. Easy first: index 0–2 both 5 at most, 2 or more apart, ask more; then 1–10, 1 or more
    /// apart, ask less 1 in 3.
    static func make(_ rng: inout SeededRandom, _ index: Int) -> Numbers {
        var a = 1, b = 1
        if index < 3 {
            repeat { a = Int.random(in: 1...5, using: &rng); b = Int.random(in: 1...5, using: &rng) } while abs(a - b) < 2
            return numbers(a: a, b: b)
        }
        repeat { a = Int.random(in: 1...10, using: &rng); b = Int.random(in: 1...10, using: &rng) } while a == b
        return numbers(a: a, b: b, less: Int.random(in: 0...2, using: &rng) == 0)
    }

    public static let spec = LessonSpec(id: "gk-numcompare", title: "Which number is more?", master: "bars",
        generate: { rng, index in make(&rng, index) },
        display: { x in let P = Parts(x); return [.num(Double(P.a)), .text("and"), .num(Double(P.b))] },
        idea: { _ in "The number that comes after when you count is more." },
        depends: ["k-compare", "gk-onemore"],
        check: [CheckItem(3, when: { Parts($0).extra == 1 }), CheckItem(3, when: { Parts($0).less }),
                CheckItem(3, when: { Parts($0).a == 10 || Parts($0).b == 10 }), CheckItem(3)]) { x in
        let P = Parts(x)
        let make = LessonStep(StepWords(say: "Make each number.", hint: "A cube for each number, 1 to \(P.a), then 1 to \(P.b).", action: "Check"),
            answer: AnswerTask(prompt: [.box("w")], expected: ["w": 0], hint: "A cube for each number.", explain: "\(P.a) cubes and \(P.b) cubes.",
                               check: { v in P.made(Int((v["w"] ?? -1).rounded())).map { .wrong($0) } ?? .right }, byHand: true),
            picture: ["at": 0], onMiss: ["over": 1], hint2: ["spot": 1])
        let pick = LessonStep(StepWords(say: P.say, hint: "Look at the cubes past the dashed line.", action: "Check"),
            answer: AnswerTask(prompt: [.box("p")], expected: ["p": Double(P.want)], hint: "Look at the cubes past the dashed line.", explain: P.why,
                               check: { v in Int((v["p"] ?? -1).rounded()) == P.want ? .right : .wrong(P.missed) }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 2])
        return [make, pick, done]
    }
}
