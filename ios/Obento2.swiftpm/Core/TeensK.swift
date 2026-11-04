import Foundation

/// What Kindergarten's Teens and tens chapter shares (design/gradeK.md chapter 5, the preview
/// design/prototype/gradeK-ch5.html): one block is one thing (a dot, a cell of a ten frame, a number on the hundred chart),
/// a full row of ten is the ten, and every number the child writes is tapped: on the number row (0–10, or grown to 20 with
/// 11–20 on a second row), or, past 20, on the digit pad (0–9, a rub-out and Check). Every line here is also spoken.
public enum TeensK {
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    /// The first wrong-answer line that fits (the web's slips, in order: never the answer, 0 to `hi` only), else `other`.
    static func slip(_ v: Int, _ ans: Int, _ list: [(Int, String)], _ other: String, hi: Int = 20) -> String {
        list.first { $0.0 == v && $0.0 != ans && (0...hi).contains($0.0) }?.1 ?? other
    }
    /// The slips a step names (what the engine checks first): the ones that can be written.
    static func known(_ ans: Int, _ list: [(Int, String)], hi: Int = 20) -> [(Int, String)] {
        var seen: Set<Int> = []
        return list.filter { $0.0 != ans && (0...hi).contains($0.0) && seen.insert($0.0).inserted }
    }
    /// A step answered by a code its hand move puts in the box: right when it's `want`, else what `said` says.
    static func hand(_ box: String, _ want: Int, hint: String, explain: String, said: @escaping @Sendable (Int) -> String) -> AnswerTask {
        AnswerTask(prompt: [.box(box)], expected: [box: Double(want)], hint: hint, explain: explain,
                   check: { v in let x = Int((v[box] ?? -99).rounded()); return x == want ? .right : .wrong(said(x)) }, byHand: true)
    }
    /// "1 dot", "7 dots".
    public static func dots(_ n: Int) -> String { n == 1 ? "1 dot" : "\(n) dots" }
}

// MARK: - The numerals' strokes

/// How each numeral is written (the web's stroke shapes, `DIGITS` in numerals.ts): one or two strokes a digit, each from
/// its start, in a 60 × 100 box that is 6 × 10 squares. Tracing follows these points.
public enum Numerals {
    static let paths: [Character: String] = [
        "0": "M30 6 C 12 6, 5 28, 5 50 C 5 72, 12 94, 30 94 C 48 94, 55 72, 55 50 C 55 28, 48 6, 30 6",
        "1": "M18 20 L32 6 L32 94",
        "2": "M8 26 C 10 12, 20 6, 30 6 C 44 6, 53 15, 53 28 C 53 46, 30 64, 7 94 L 55 94",
        "3": "M9 16 C 14 9, 22 6, 30 6 C 43 6, 51 14, 51 26 C 51 39, 42 48, 28 48 C 44 48, 55 58, 55 71 C 55 85, 44 94, 30 94 C 20 94, 11 90, 6 82",
        "4": "M38 6 L6 64 L56 64 | M42 36 L42 94",
        "5": "M12 6 L9 45 C 16 40, 23 38, 30 38 C 46 38, 55 50, 55 66 C 55 83, 44 94, 28 94 C 18 94, 10 90, 6 84 | M20 6 L52 6",
        "6": "M48 10 C 43 7, 37 6, 31 6 C 14 6, 5 28, 5 58 C 5 81, 15 94, 30 94 C 46 94, 55 82, 55 68 C 55 53, 45 44, 31 44 C 19 44, 9 52, 6 62",
        "7": "M6 6 L55 6 L22 94",
        "8": "M50 20 C 47 11, 40 6, 30 6 C 17 6, 9 15, 9 27 C 9 40, 19 45, 30 50 C 43 56, 54 63, 54 76 C 54 88, 44 94, 30 94 C 16 94, 6 88, 6 76 C 6 63, 17 56, 30 50 C 41 45, 51 39, 51 28 C 51 25, 51 22, 50 20",
        "9": "M54 30 C 53 15, 44 6, 30 6 C 16 6, 6 15, 6 28 C 6 42, 16 51, 30 51 C 42 51, 51 45, 54 32 L54 94",
    ]
    public typealias Pt = (x: Double, y: Double)

    /// A stroke's path as drawn: its points, finely, in the box's units (0–60 across, 0–100 down).
    static func outline(_ d: String) -> [Pt] {
        let spaced = d.map { $0.isLetter ? " \($0) " : $0 == "," ? " " : String($0) }.joined()
        let toks = spaced.split(separator: " ").map(String.init)
        var out: [Pt] = [], i = 0, cmd = "M"
        func num() -> Double { defer { i += 1 }; return i < toks.count ? Double(toks[i]) ?? 0 : 0 }
        while i < toks.count {
            if let c = toks[i].first, c.isLetter { cmd = toks[i]; i += 1; continue }
            switch cmd {
            case "M", "L": out.append((num(), num()))
            case "C":
                let p0 = out.last ?? (0, 0), a = (num(), num()), b = (num(), num()), e = (num(), num())
                for k in 1...24 {
                    let u = Double(k) / 24, v = 1 - u
                    out.append((v * v * v * p0.x + 3 * v * v * u * a.0 + 3 * v * u * u * b.0 + u * u * u * e.0,
                                v * v * v * p0.y + 3 * v * v * u * a.1 + 3 * v * u * u * b.1 + u * u * u * e.1))
                }
            default: i += 1
            }
        }
        return out
    }

    /// Points spread evenly along a line, every `step` units (at least 40 a stroke), from its start to its end.
    static func even(_ pts: [Pt]) -> [Pt] {
        var cum: [Double] = [0]
        for k in 1..<pts.count { cum.append(cum[k - 1] + hypot(pts[k].x - pts[k - 1].x, pts[k].y - pts[k - 1].y)) }
        let len = cum.last ?? 0, n = max(40, Int((len / 2).rounded()))
        var out: [Pt] = [], j = 1
        for i in 0...n {
            let at = len * Double(i) / Double(n)
            while j < pts.count - 1 && cum[j] < at { j += 1 }
            let a = pts[j - 1], b = pts[j], span = cum[j] - cum[j - 1], u = span > 0 ? (at - cum[j - 1]) / span : 0
            out.append((a.x + (b.x - a.x) * min(1, max(0, u)), a.y + (b.y - a.y) * min(1, max(0, u))))
        }
        return out
    }

    /// The strokes of a whole number written from (x, y), 6 × 10 squares a digit: each stroke's points in squares, in the
    /// order they're written (the first digit's strokes first).
    public static func strokes(_ n: Int, x: Double = 0, y: Double = 0) -> [[Pt]] {
        // written out step by step: GitHub's older compiler times out on the chained form
        var out: [[Pt]] = []
        for (di, ch) in String(n).enumerated() {
            let left: Double = x + 6 * Double(di)
            for part in (paths[ch] ?? "").split(separator: "|") {
                let line: [Pt] = even(outline(String(part).trimmingCharacters(in: .whitespaces)))
                var stroke: [Pt] = []
                for q in line { stroke.append((left + q.x / 10, y + q.y / 10)) }
                out.append(stroke)
            }
        }
        return out
    }
}

// MARK: - Count to 20

/// Count to 20 (the web's k-count20, K.CC.A.2, K.CC.B.5). One block is one dot. The twenty track (two ten tracks
/// touching, 50 × 10 squares); n dots, the top row full. Count the top row (10 at its right end); keep counting the bottom
/// row (the top row's numbers go, all but the 10); write n on the number row grown to 20. The ring (folded in, from index
/// 6, every third problem): n dots spread evenly round a 6 × 6 square of blocks, counted all the way round.
///
/// "at": 0 top, 1 rest, 2 write, 3 done; the ring: 4 count, 2 write, 3 done. The counting steps' boxes: how many once
/// every dot is counted, or −1 a dot counted already, −2 a bottom one before the top row is done, −3 a top one after it.
public enum Count20K {
    /// The ring's 20 places, clockwise from the top left corner (block columns and rows).
    public static let ring: [(Int, Int)] = [(0, 0), (1, 0), (2, 0), (3, 0), (4, 0), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5), (4, 5),
                                            (3, 5), (2, 5), (1, 5), (0, 5), (0, 4), (0, 3), (0, 2), (0, 1)]
    public static func numbers(n: Int, ring: Bool = false, off: Int = 0) -> Numbers { ["n": Double(n), "ring": ring ? 1 : 0, "off": Double(off)] }
    public struct Parts: Sendable {
        public let n: Int, ring: Bool, off: Int
        public init(_ x: Numbers) {
            n = max(11, min(20, TeensK.int(x, "n", 14))); ring = TeensK.int(x, "ring") == 1; off = max(0, min(19, TeensK.int(x, "off")))
        }
        public var rest: Int { n - 10 }
        /// Dot j's block (column, row): along the two rows, or its place round the ring.
        public func place(_ j: Int) -> (col: Int, row: Int) {
            if ring { let p = Count20K.ring[(j * 20 / n + off) % 20]; return (p.0, p.1) }
            return (j % 10, j / 10)
        }
        public func counted(_ code: Int) -> String {
            switch code {
            case -2: "Count the top row first."
            case -3: "That row is counted. Keep going on the bottom row."
            default: "You counted that one."
            }
        }
        public var slips: [(Int, String)] {
            ring ? [(n - 1, "One short. Count every dot once, all the way round."), (n + 1, "One too many. Stop at the dot you began with.")]
                : [(rest, "That’s only the bottom row. Don’t start again at 1. Say 10, then keep going: 11, 12..."),
                   (n - 1, "One short. Make sure you count every dot in the bottom row."),
                   (n + 1, "One too many. The first dot in the bottom row is 11."),
                   (10, "10 is the top row. Keep counting the bottom row.")]
        }
        public func wrote(_ v: Int) -> String {
            TeensK.slip(v, n, slips, ring ? "The last number was \(n)." : "That’s \(v). Say 10, then count on the bottom row.")
        }
        public var why: String { ring ? "Each dot gets one number, so the last number says how many." : "A full row is 10, so keep counting on from 10." }
    }
    /// The web's generator as it is (n 11–20; the first three 11–15); the ring every third problem from index 6, spread
    /// evenly from a random place.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let ring = i >= 6 && i % 3 == 0
        let n = Int.random(in: 11...(i < 3 ? 15 : 20), using: &rng)
        return numbers(n: n, ring: ring, off: ring ? Int.random(in: 0...19, using: &rng) : 0)
    }

    public static let spec = LessonSpec(id: "k-count20", title: "Count to 20", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.num(Double(Parts(x).n))] },
        idea: { _ in "A full row is 10, so keep counting on from 10." },
        depends: [],
        check: [CheckItem(3, when: { Parts($0).n <= 14 }), CheckItem(3, when: { Parts($0).n >= 17 }), CheckItem(3, when: { Parts($0).n == 20 }),
                CheckItem(6, when: { Parts($0).ring })]) { x in
        let P = Parts(x), n = P.n
        let writeHint = P.ring ? "The last number was \(n)." : "Say 10, then count on the bottom row."
        let write = LessonStep(StepWords(say: "Write how many.", hint: writeHint, action: "Check"),
            answer: CountK.write("x", n, known: TeensK.known(n, P.slips), other: { P.wrote($0) }, hint: writeHint, explain: "\(n) dots."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        if P.ring {
            let hint = "Tap each dot once, all the way round."
            let count = LessonStep(StepWords(say: "Count them all.", hint: hint, action: "Check"),
                answer: TeensK.hand("c", n, hint: hint, explain: "\(n) dots.", said: P.counted), picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [count, write, done]
        }
        let topHint = "Tap each dot in the top row."
        let top = LessonStep(StepWords(say: "Count the top row.", hint: topHint, action: "Check"),
            answer: TeensK.hand("c", 10, hint: topHint, explain: "A full row is 10.", said: P.counted), picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let restHint = "Count on along the bottom row: 11, 12, 13..."
        let rest = LessonStep(StepWords(say: "Keep counting.", hint: restHint, action: "Check"),
            answer: TeensK.hand("d", n, hint: restHint, explain: "\(n) dots.", said: P.counted), picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [top, rest, write, done]
    }
}

// MARK: - Write numbers 0 to 20

/// Write numbers 0 to 20 (the web's k-write, K.CC.A.3). One block is one cell of a ten frame (11–20: two frames, one under
/// the other, a block between). Count the dots (0: none, a tap on the frame); tap the numeral from three (the web's
/// look-alikes, in its order); trace it, a stroke at a time from its start dot.
///
/// "at": 0 count, 1 pick, 2 trace, 3 done. The count step's box: n once every dot is counted (0: the frame tapped), or −1
/// a dot counted already. The trace step's: 1 once every stroke is traced, −1 a stroke touched away from its start dot,
/// −2 away from where it stopped.
public enum WriteK {
    static let looks: [Int: Int] = [6: 9, 9: 6, 2: 5, 5: 2, 3: 8, 8: 3, 1: 7, 7: 1, 4: 9]
    static let shape: [Int: String] = [
        0: "0 is one closed ring", 1: "1 is one straight line down", 2: "2 curves on top and sits on a flat line",
        3: "3 has two bumps and is open on the left", 4: "4 has a corner and a line straight down", 5: "5 has a flat hat on top and a round belly",
        6: "6 has its loop at the bottom", 7: "7 has a flat line on top, then slants down", 8: "8 has two closed loops, one on top of the other",
        9: "9 has its loop at the top",
    ]
    public static func numbers(n: Int) -> Numbers { ["n": Double(n)] }
    static func swapped(_ n: Int) -> Int { Int(String(String(n).reversed())) ?? n }
    public struct Parts: Sendable {
        public let n: Int
        public init(_ x: Numbers) { n = max(0, min(20, TeensK.int(x, "n", 7))) }
        public var two: Bool { n > 10 }
        /// The web's choices: the right numeral and two look-alikes, in an order fixed by the number.
        public var choices: [Int] {
            let near = n == 0 ? 1 : n == 20 ? 19 : n % 2 == 1 ? n + 1 : n - 1
            let others: [Int]
            if n == 0 { others = [1, 8] }
            else if n == 10 || n == 20 { others = [near, n == 10 ? 20 : 10] }
            else if n > 10 { others = n == 11 ? [10, 12] : [WriteK.swapped(n), near] }
            else { let l = WriteK.looks[n] ?? near; others = [l, near == l ? (n > 1 ? n - 1 : n + 1) : near] }
            let all = [n] + others, k = n % 3
            return Array(all[k...] + all[..<k])
        }
        public func picked(_ v: Int) -> String {
            if n > 10 && v == WriteK.swapped(n) && v != n { return "That’s \(v). \(n) starts with 1: 1 ten and \(n - 10 == 1 ? "1 one" : "\(n - 10) ones")." }
            if n <= 9 && v <= 9, let a = WriteK.shape[v], let b = WriteK.shape[n] { return "That’s \(v), not \(n). \(a). \(b)." }
            if abs(v - n) == 1 { return "That’s \(v), one \(v > n ? "more" : "less") than \(n). You counted \(TeensK.dots(n))." }
            if v % 10 == 0 && n % 10 == 0 { return "That’s \(v): \(v / 10 == 1 ? "1 ten" : "\(v / 10) tens"). \(n) is \(n / 10 == 1 ? "1 ten" : "\(n / 10) tens")." }
            return "That’s \(v). You counted \(TeensK.dots(n)), and \(n) is written \(n)."
        }
        public func traced(_ code: Int) -> String { code == -2 ? "Go on from where you stopped." : "Start at the dot." }
        public var strokes: Int { Numerals.strokes(n).count }
        public static let why = "The number says how many dots."
    }
    /// The web's generator as it is (1–5, then 1–10, 0 now and then at index 6, then teens, or 1–10 and 20).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 3 { return numbers(n: Int.random(in: 1...5, using: &rng)) }
        if i < 6 { return numbers(n: Int.random(in: 1...10, using: &rng)) }
        if i == 6 && Int.random(in: 0...2, using: &rng) == 0 { return numbers(n: 0) }
        return numbers(n: Bool.random(using: &rng) ? Int.random(in: 11...19, using: &rng) : [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20][Int.random(in: 0...10, using: &rng)])
    }

    public static let spec = LessonSpec(id: "k-write", title: "Write numbers 0 to 20", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.num(Double(Parts(x).n))] },
        idea: { _ in Parts.why },
        depends: ["k-count20"],
        check: [CheckItem(4, when: { [2, 5, 6, 9].contains(Parts($0).n) }), CheckItem(7, when: { (12...19).contains(Parts($0).n) }),
                CheckItem(7, when: { (12...19).contains(Parts($0).n) }), CheckItem(8, when: { [10, 20].contains(Parts($0).n) })]) { x in
        let P = Parts(x), n = P.n
        let countHint = n == 0 ? "Tap the frame." : "Tap each dot once."
        let count = LessonStep(StepWords(say: "Count the dots.", hint: countHint, action: "Check"),
            answer: TeensK.hand("c", n, hint: countHint, explain: TeensK.dots(n) + ".", said: { _ in "You counted that one." }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let pickHint = n > 10 ? "\(n) starts with 1: 1 ten and \(n - 10) more." : "Look at its shape."
        let pick = LessonStep(StepWords(say: n == 0 ? "None. None is 0. Tap the 0." : "Tap the \(n).", hint: pickHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("p")], expected: ["p": Double(n)], known: P.choices.filter { $0 != n }.map { (["p": Double($0)], P.picked($0)) },
                               hint: pickHint, explain: "\(n) is written \(n).",
                               check: { v in let k = Int((v["p"] ?? -1).rounded()); return k == n ? .right : .wrong(P.picked(k)) }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let traceHint = "Start at the dot and follow the line."
        let trace = LessonStep(StepWords(say: "Trace it.", hint: traceHint, action: "Check"),
            answer: TeensK.hand("t", 1, hint: traceHint, explain: "\(n) is written \(n).", said: P.traced),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [count, pick, trace, done]
    }
}

// MARK: - Teen numbers

/// Teen numbers (the web's k-teens, K.NBT.A.1, K.CC.B.5). One block is one cell. Two ten frames side by side, a block
/// apart: the first full, named 10 under it; the second holding the ones. Count the second frame (its count goes under
/// it); its count slides onto the 0 of 10 and covers it; write 10 + 6 = [16]. Make a teen (folded in, from index 3, every
/// other problem): drag across two empty frames (the first fills first), let go on the teen, write 16 = 10 + [6].
///
/// "at": 0 count, 1 write, 2 done; the make kind: 3 make, 4 write, 2 done. The count step's box: ones once each is
/// counted, or −1 a dot of the full frame, −2 one counted already. The make step's: the dots made.
public enum TeenNumbersK {
    public static func numbers(ones: Int, make: Bool = false) -> Numbers { ["ones": Double(ones), "make": make ? 1 : 0] }
    public struct Parts: Sendable {
        public let ones: Int, make: Bool
        public init(_ x: Numbers) {
            make = TeensK.int(x, "make") == 1
            ones = max(1, min(make ? 10 : 9, TeensK.int(x, "ones", 6)))
        }
        public var n: Int { 10 + ones }
        public func counted(_ code: Int) -> String { code == -1 ? "That’s the full frame. Count the dots in the second frame." : "You counted that one." }
        public func made(_ m: Int) -> String? { m == n ? nil : "That’s \(m). Make \(n)." }
        public var slips: [(Int, String)] {
            make ? [(10, "10 is the full frame. Count the dots in the second frame."), (ones - 1, "One short. Count every dot in the second frame."),
                    (ones + 1, "One too many. Count each dot in the second frame once.")]
                : [(10 * ones + 1, "You have the right digits, but the 1 for the ten comes first: \(n)."),
                   (ones, "Don’t forget the full frame. Start at 10 and count on \(ones)."),
                   (n - 1, "Start at 10, then say 11 for the first extra dot."),
                   (n + 1, "One too many. Start at 10 and count on only \(ones).")]
        }
        public var answer: Int { make ? ones : n }
        public func wrote(_ v: Int) -> String {
            make ? TeensK.slip(v, ones, slips, "That’s \(v). Count the dots in the second frame.", hi: 10)
                : TeensK.slip(v, n, slips, "That’s \(v). Start at 10 and count on \(ones).")
        }
        public static let why = "A teen number is a ten and some ones."
    }
    /// The web's generator as it is (ones 1–9; the first three 1–5); the make kind every other problem from index 3, its
    /// ones 1–10.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let mk = i >= 3 && i % 2 == 1
        return numbers(ones: Int.random(in: 1...(mk ? 10 : i < 3 ? 5 : 9), using: &rng), make: mk)
    }

    public static let spec = LessonSpec(id: "k-teens", title: "Teen numbers", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return P.make ? [.text("Make"), .num(Double(P.n))] : [.num(10), .op("+"), .num(Double(P.ones))] },
        idea: { _ in Parts.why },
        depends: ["k-count20", "k-write"],
        check: [CheckItem(3, when: { Parts($0).ones <= 3 }), CheckItem(4, when: { Parts($0).ones >= 6 }), CheckItem(3, when: { Parts($0).ones >= 6 }),
                CheckItem(3)]) { x in
        let P = Parts(x), n = P.n
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 2])
        if P.make {
            let makeHint = "Fill the first frame, then \(P.ones) more."
            let mk = LessonStep(StepWords(say: "Make \(n).", hint: makeHint, action: "Check"),
                answer: AnswerTask(prompt: [.box("m")], expected: ["m": Double(n)], hint: makeHint, explain: "10 and \(P.ones) more.",
                                   check: { v in P.made(Int((v["m"] ?? 0).rounded())).map { .wrong($0) } ?? .right }, byHand: true),
                picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
            let writeHint = "Count the dots in the second frame."
            let write = LessonStep(StepWords(say: "Write the ones.", hint: writeHint, action: "Check"),
                answer: CountK.write("x", P.ones, known: TeensK.known(P.ones, P.slips, hi: 10), other: { P.wrote($0) }, hint: writeHint,
                                     explain: "\(n) = 10 + \(P.ones)."),
                picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [mk, write, done]
        }
        let countHint = "Tap each dot in the second frame."
        let count = LessonStep(StepWords(say: "Count these.", hint: countHint, action: "Check"),
            answer: TeensK.hand("c", P.ones, hint: countHint, explain: "\(P.ones) more.", said: P.counted),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = "Start at 10 and count on \(P.ones)."
        let write = LessonStep(StepWords(say: "Watch the 0. Write the number.", hint: writeHint, action: "Check"),
            answer: CountK.write("x", n, known: TeensK.known(n, P.slips), other: { P.wrote($0) }, hint: writeHint, explain: "10 + \(P.ones) = \(n)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [count, write, done]
    }
}

// MARK: - Count by tens to 100

/// Count by tens to 100 (the web's k-tens, K.CC.A.1). One ten is a ten frame tile, 2 × 1 blocks, in rows of five. Tap
/// each tile: it gets its running total over it, by tens. Write 10, 20, 30, [40] with the digit pad (K's one written
/// number past 20).
///
/// "at": 0 count, 1 write, 2 done. The count step's box: rows once every tile is counted, or −1 one counted already.
public enum TensK {
    public static func numbers(rows: Int) -> Numbers { ["rows": Double(rows)] }
    public struct Parts: Sendable {
        public let rows: Int
        public init(_ x: Numbers) { rows = max(2, min(10, TeensK.int(x, "rows", 4))) }
        public var total: Int { 10 * rows }
        public var slips: [(Int, String)] {
            [(rows, "That’s the number of frames. Each frame is 10, so count 10, 20, 30..."), (total - 10, "One ten short. Say one ten for every frame."),
             (total + 10, "One ten too many. There are only \(rows) frames."), (total - 9, "Count by tens all the way. After \(total - 10) comes \(total).")]
        }
        public func wrote(_ v: Int) -> String { TeensK.slip(v, total, slips, "That’s \(v). Say one ten for each frame: 10, 20, 30...", hi: 999) }
        public static let why = "Each frame is 10, so count by tens."
    }
    /// The web's generator as it is (2–10 tens; the first three 2–5).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers { numbers(rows: Int.random(in: 2...(i < 3 ? 5 : 10), using: &rng)) }

    public static let spec = LessonSpec(id: "k-tens", title: "Count by tens to 100", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.num(Double(Parts(x).rows)), .text("tens")] },
        idea: { _ in Parts.why },
        depends: ["k-count20"],
        check: [CheckItem(3, when: { Parts($0).rows <= 5 }), CheckItem(3, when: { (6...9).contains(Parts($0).rows) }),
                CheckItem(3, when: { (6...9).contains(Parts($0).rows) }), CheckItem(3, when: { Parts($0).rows == 10 })]) { x in
        let P = Parts(x), t = P.total
        let countHint = "Tap each frame once: 10, 20, 30..."
        let count = LessonStep(StepWords(say: "Count by tens.", hint: countHint, action: "Check"),
            answer: TeensK.hand("c", P.rows, hint: countHint, explain: "\(P.rows) tens.", said: { _ in "You counted that ten." }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let writeHint = "Say one ten for each frame."
        let write = LessonStep(StepWords(say: "Write how many.", hint: writeHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(t)], known: TeensK.known(t, P.slips, hi: 999).map { (["x": Double($0.0)], $0.1) },
                               hint: writeHint, explain: "\(P.rows) tens is \(t).",
                               check: { v in let k = Int((v["x"] ?? -1).rounded()); return k == t ? .right : .wrong(P.wrote(k)) },
                               incomplete: "Tap a number.", byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": 2])
        return [count, write, done]
    }
}

// MARK: - Count to 100

/// Count to 100 (gk-count100, new; K.CC.A.1 by ones, K.CC.A.2). One block is one number: the hundred chart, 10 × 10 blocks.
/// Count on: the chart written up to the start (ringed); tap the next empty block, then the next, each writing its
/// number. Which goes here?: the chart written but one dashed block; tap its number from three under the chart (it, and
/// the numbers above and below it). Then the camera steps back to the whole chart and the last column lights, 10 … 100.
///
/// "at": 0 count on, 1 which, 2 done. The count step's box: m once every number is written, or −next, the number that
/// comes next, for a tap on any other block.
public enum CountTo100 {
    public static func numbers(on s: Int, more m: Int) -> Numbers { ["kind": 0, "s": Double(s), "m": Double(m)] }
    public static func numbers(which n: Int, choices: [Int]) -> Numbers {
        var x: Numbers = ["kind": 1, "n": Double(n)]
        for (i, c) in choices.enumerated() { x["c\(i)"] = Double(c) }
        return x
    }
    public static func row(_ v: Int) -> Int { (v - 1) / 10 }
    public struct Parts: Sendable {
        public let on: Bool, s: Int, m: Int, n: Int, choices: [Int]
        public init(_ x: Numbers) {
            on = TeensK.int(x, "kind") == 0
            m = max(1, min(7, TeensK.int(x, "m", 5)))
            s = max(1, min(100 - m, TeensK.int(x, "s", 37)))
            n = max(2, min(99, TeensK.int(x, "n", 40)))
            let c = (0..<3).compactMap { x["c\($0)"].map { Int($0.rounded()) } }
            choices = c.count == 3 ? c : CountTo100.choices(n)
        }
        public var e: Int { s + m }
        /// The rows in play (3, from this one): the start's row (or the gap's) and its neighbours, kept on the chart.
        public var top: Int { max(0, min(7, CountTo100.row(on ? s : n) - 1)) }
        /// Where a row ends and the next starts, for the last line.
        public var turn: Int {
            if on { return CountTo100.row(e) > CountTo100.row(s) ? 10 * CountTo100.row(e) : min(90, 10 * (CountTo100.row(e) + 1)) }
            return n % 10 == 0 ? min(n, 90) : n % 10 == 1 ? n - 1 : max(10, 10 * (n / 10))
        }
        public func tapped(_ code: Int) -> String {
            let next = -code
            return next % 10 == 1 ? "\(next) comes next. It starts the next row." : "\(next) comes next. It goes right after \(next - 1)."
        }
        public func picked(_ v: Int) -> String { "\(v) is \(v < n ? "up" : "down") here. After \(n - 1) comes \(n)." }
        public var why: String { "Each row is ten numbers: \(turn) ends one row and \(turn + 1) starts the next." }
    }
    /// Its choices: the numbers 10 above and below it, or the next two in its column at the chart's top and bottom.
    static func choices(_ n: Int) -> [Int] { let r = row(n); return r == 0 ? [n, n + 10, n + 20] : r == 9 ? [n, n - 10, n - 20] : [n - 10, n, n + 10] }
    /// Easy first: index 0–2 count on within one row, 30 at most; 3–5 across a row's end; 6+ both kinds by turns (count on
    /// at the odd ones), up to 100, and 1 count on in 4 ends at 100.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i >= 6 && i % 2 == 0 {
            let n = Int.random(in: 2...99, using: &rng)
            var c = choices(n)
            c.shuffle(using: &rng)
            return numbers(which: n, choices: c)
        }
        var m = Int.random(in: 3...7, using: &rng), s: Int
        if i < 3 { let r = Int.random(in: 0...2, using: &rng); s = Int.random(in: (10 * r + 1)...(10 * r + 10 - m), using: &rng) }
        else if i < 6 { let r = Int.random(in: 0...8, using: &rng); s = Int.random(in: (10 * r + 11 - m)...(10 * r + 10), using: &rng) }
        else if Int.random(in: 1...4, using: &rng) == 1 { m = Int.random(in: 6...7, using: &rng); s = 100 - m }
        else { s = Int.random(in: 1...min(94, 100 - m), using: &rng) }
        return numbers(on: s, more: m)
    }

    public static let spec = LessonSpec(id: "gk-count100", title: "Count to 100", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return P.on ? [.text("Count to"), .num(Double(P.e))] : [.text("Which goes here?")] },
        idea: { _ in "Each row is ten numbers: one row ends with a ten and the next starts after it." },
        depends: ["k-tens"],
        check: [CheckItem(3, when: { let P = Parts($0); return P.on && CountTo100.row(P.e) > CountTo100.row(P.s) }),
                CheckItem(6, when: { let P = Parts($0); return !P.on && P.n % 10 == 0 }),
                CheckItem(7, when: { let P = Parts($0); return P.on && P.e == 100 }),
                CheckItem(6, when: { let P = Parts($0); return !P.on && P.n >= 50 })]) { x in
        let P = Parts(x)
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 2])
        if P.on {
            let hint = "Tap the empty block right after \(P.s)."
            let count = LessonStep(StepWords(say: "Count to \(P.e).", hint: hint, action: "Check"),
                answer: TeensK.hand("k", P.m, hint: hint, explain: "\(P.s + 1) to \(P.e).", said: P.tapped),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [count, done]
        }
        let hint = "Look at the numbers before it and after it."
        let which = LessonStep(StepWords(say: "Tap the missing number.", hint: hint, action: "Check"),
            answer: AnswerTask(prompt: [.box("x")], expected: ["x": Double(P.n)], known: P.choices.filter { $0 != P.n }.map { (["x": Double($0)], P.picked($0)) },
                               hint: hint, explain: "After \(P.n - 1) comes \(P.n).",
                               check: { v in let k = Int((v["x"] ?? -1).rounded()); return k == P.n ? .right : .wrong(P.picked(k)) }, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [which, done]
    }
}
