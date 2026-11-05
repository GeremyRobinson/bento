import Foundation

// 3rd grade's chapter 5, Fractions (design/grade3.md chapter 5, the preview design/prototype/grade3-ch5.html): a shape cut
// into equal parts with the ruler (or parts that look different, counted and judged), a bar's parts counted and one slid
// out and hopped along the shading, hops along a number line to name a point, a point dragged under another on a second
// line (or hops to a whole number), and two bars compared by their pieces. The fractions family's whole is 48 squares, so
// a half to an eighth is 24, 16, 12, 8 or 6 squares; a square unit of a shape is a tile of 5 squares (4 when 5 won't
// show at 75%). Every fraction the child writes is typed with the iPad's keys, top and bottom, and Check; misses and
// slips are the preview's words.

/// What the chapter shares.
public enum Fr3 {
    /// The whole bar or line: 48 squares.
    public static let whole = 48
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    static func r(_ a: Int, _ b: Int, _ rng: inout SeededRandom) -> Int { a >= b ? a : Int.random(in: a...b, using: &rng) }
    static func pick<T>(_ a: [T], _ rng: inout SeededRandom) -> T { a[Int.random(in: 0..<a.count, using: &rng)] }
    static func chance(_ p: Double, _ rng: inout SeededRandom) -> Bool { Double.random(in: 0..<1, using: &rng) < p }
    static let names: [Int: (String, String)] = [1: ("whole", "wholes"), 2: ("half", "halves"), 3: ("third", "thirds"),
                                                 4: ("fourth", "fourths"), 6: ("sixth", "sixths"), 8: ("eighth", "eighths")]
    /// "fourth" (n = 1), "fourths".
    public static func pname(_ n: Int, _ d: Int) -> String {
        guard let p = names[d] else { return "\(d)ths" }
        return n == 1 ? p.0 : p.1
    }
    public static func plural(_ n: Int, _ one: String, _ many: String) -> String { "\(n) \(n == 1 ? one : many)" }
    static func isAre(_ n: Int) -> String { n == 1 ? "is" : "are" }
    /// "6, 6, 5 and 7".
    public static func andList(_ l: [Int]) -> String {
        guard l.count > 1 else { return l.first.map { "\($0)" } ?? "" }
        var head: [String] = []
        for v in l.dropLast() { head.append("\(v)") }
        return head.joined(separator: ", ") + " and \(l[l.count - 1])"
    }

    /// A step answered by a code its hand move puts in the box: right when it's `want`, else what `said` says.
    static func hand(_ box: String, _ want: Int, hint: String, explain: String, said: @escaping @Sendable (Int) -> String) -> AnswerTask {
        AnswerTask(prompt: [.box(box)], expected: [box: Double(want)], hint: hint, explain: explain,
                   check: { v in let x = Int((v[box] ?? -99).rounded()); return x == want ? .right : .wrong(said(x)) }, byHand: true)
    }

    /// A fraction typed top ("t…") and bottom ("b…"): right; a known slip (the preview's words); the same amount written
    /// another way, nudged ("That's the same amount. Write it as 1 part of 4."); or "Not quite." and the hint.
    static func typed(_ top: String, _ bottom: String, _ N: Int, _ D: Int, _ slips: [(Int, Int, String)], hint: String, nudge: String?, explain: String) -> AnswerTask {
        var list: [(Int, Int, String)] = []
        for s in slips where !(s.0 == N && s.1 == D) && !list.contains(where: { $0.0 == s.0 && $0.1 == s.1 }) { list.append(s) }
        let found = list
        var known: [(values: [String: Double], message: String)] = []
        for s in list { known.append(([top: Double(s.0), bottom: Double(s.1)], s.2)) }
        return AnswerTask(prompt: [.frac(.box(top), .box(bottom))], expected: [top: Double(N), bottom: Double(D)], known: known,
                          hint: hint, explain: explain,
                          check: { v in
                              guard let t = v[top], let b = v[bottom] else { return .soft("Write the top and the bottom.") }
                              let n = Int(t.rounded()), d = Int(b.rounded())
                              if n == N && d == D { return .right }
                              if let s = found.first(where: { $0.0 == n && $0.1 == d }) { return .wrong(s.2) }
                              if let nudge, d > 0, n * D == d * N { return .wrong("That's the same amount. Write it as \(nudge).") }
                              return .wrong("Not quite. \(hint)")
                          }, incomplete: "Write the top and the bottom.")
    }
}

// MARK: - Equal parts of a shape

/// Equal parts of a shape (g3-shapeparts, new; 3.G.A.2, 3.NF.A.1). A rectangle W × H tiles (a tile c squares a side).
/// Strips: the ruler over the top snaps at every tile line, its cuts repeat across, each part counts its squares ("2 parts
/// of 12"); let go on b equal parts and they turn solid ("fourths: 6 squares each"); tap one part, it lifts; write
/// `1 part = [1]/[4]`. Other shapes: the rectangle comes cut into parts that look different (a snake of tiles, cut in
/// turn); tap each part (its squares count); Yes or No: are the parts equal?; equal: write `each part = [1]/[4]`.
///
/// "kind" 0 strips, 1 shapes; "W", "H", "b"; shapes: "cols" 1 the snake runs down the columns, "fx", "fy" flipped, "bad"
/// the part one square short (−1: none). "at": strips 0 cut, 1 tap, 2 write, 3 done; shapes 0 count, 1 judge, 2 write (equal
/// only), then done. Boxes: "k" the ruler's columns a part; "p" the part tapped; "n" parts counted; "c" 0 Yes, 1 No; "t" "b".
public enum ShapeParts3 {
    public static func strips(W: Int, H: Int, b: Int) -> Numbers { ["kind": 0, "W": Double(W), "H": Double(H), "b": Double(b)] }
    public static func shapes(W: Int, H: Int, b: Int, cols: Bool, fx: Bool = false, fy: Bool = false, bad: Int = -1) -> Numbers {
        ["kind": 1, "W": Double(W), "H": Double(H), "b": Double(b), "cols": cols ? 1 : 0, "fx": fx ? 1 : 0, "fy": fy ? 1 : 0, "bad": Double(bad)]
    }
    /// The rectangle's room in squares with its record and readout beside it (so the problem shows at 75%).
    static let room = [(40, 25)]

    /// The parts of a W × H rectangle cut into b along a snake of tiles (rows, or columns), in turn; `bad` one square short
    /// and the next one long. regions[row][col] is the part a tile is in.
    public static func snake(W: Int, H: Int, b: Int, byCols: Bool, fx: Bool, fy: Bool, bad: Int?) -> [[Int]] {
        var order: [(Int, Int)] = []
        if !byCols {
            for r in 0..<H { for j in 0..<W { order.append((r, r % 2 == 1 ? W - 1 - j : j)) } }
        } else {
            for j in 0..<W { for r in 0..<H { order.append((j % 2 == 1 ? H - 1 - r : r, j)) } }
        }
        var sz = Array(repeating: W * H / max(1, b), count: b)
        if let bad, bad >= 0, bad + 1 < b { sz[bad] -= 1; sz[bad + 1] += 1 }
        var rg = Array(repeating: Array(repeating: 0, count: W), count: H)
        var t = 0
        for (i, z) in sz.enumerated() {
            for _ in 0..<z where t < order.count {
                let (r, j) = order[t]; t += 1
                rg[fy ? H - 1 - r : r][fx ? W - 1 - j : j] = i
            }
        }
        return rg
    }

    public struct Parts: Sendable {
        public let kind: Int, W: Int, H: Int, b: Int, cols: Bool, fx: Bool, fy: Bool, bad: Int
        public init(_ x: Numbers) {
            kind = Fr3.int(x, "kind") == 1 ? 1 : 0
            W = max(2, min(8, Fr3.int(x, "W", 4))); H = max(2, min(6, Fr3.int(x, "H", 3))); b = max(2, min(8, Fr3.int(x, "b", 4)))
            cols = Fr3.int(x, "cols") == 1; fx = Fr3.int(x, "fx") == 1; fy = Fr3.int(x, "fy") == 1; bad = Fr3.int(x, "bad", -1)
        }
        public var strips: Bool { kind == 0 }
        public var T: Int { W * H }
        /// One part's squares.
        public var s: Int { T / b }
        /// A strip's columns.
        public var k0: Int { W / b }
        /// A tile's side in squares.
        public var c: Int { G3.cell(W, H, within: ShapeParts3.room, sizes: [5, 4]) }
        public var note: String? { c < 5 ? "1 square unit is \(c) × \(c) squares here." : nil }
        /// Each tile's part.
        public var regions: [[Int]] {
            if strips {
                var rg: [[Int]] = []
                for _ in 0..<H { var row: [Int] = []; for j in 0..<W { row.append(j / max(1, k0)) }; rg.append(row) }
                return rg
            }
            return ShapeParts3.snake(W: W, H: H, b: b, byCols: cols, fx: fx, fy: fy, bad: bad >= 0 ? bad : nil)
        }
        public var sizes: [Int] {
            let rg = regions
            var out = Array(repeating: 0, count: b)
            for row in rg { for v in row where v < b { out[v] += 1 } }
            return out
        }
        public var equal: Bool { sizes.allSatisfy { $0 == s } }
        /// The ruler at k columns a part: "2 parts of 12", "1 part of 12, 1 of 6" (nothing at the far end).
        public func cutText(_ k: Int) -> String {
            guard k > 0, k < W else { return "" }
            let full = W / k, r = W % k
            return r != 0 ? "\(Fr3.plural(full, "part", "parts")) of \(k * H), 1 of \(r * H)" : "\(full) parts of \(k * H)"
        }
        /// Let go at k columns a part: what it says when it isn't b equal parts.
        public func cutMiss(_ k: Int) -> String {
            let full = W / max(1, k), r = W % max(1, k)
            if r != 0 { return "The last part is \(r * H) squares. The \(full == 1 ? "other is" : "others are") \(k * H)." }
            return "That's \(full) equal parts. Cut \(b)."
        }
        public var cutDone: String { "\(Fr3.pname(2, b)): \(s) squares each" }
        public var slips: [(Int, Int, String)] {
            var out: [(Int, Int, String)] = [(b, 1, "The bottom says how many equal parts make the whole: \(b). The top says how many you take: 1.")]
            if b > 2 { out.append((1, b - 1, "There are \(b - 1) cuts, but \(b) parts. Count the parts.")) }
            return out
        }
        public var judged: String { equal ? "Each part is \(s) squares: they're equal." : "Not all the same: \(Fr3.andList(sizes)) squares." }
        public var why: String {
            if strips { return "\(b) equal parts: each is 1/\(b) of it." }
            return equal ? "Different shapes, same area: each is 1/\(b)." : "\(Fr3.andList(sizes)) squares: not \(Fr3.pname(2, b))."
        }
    }

    /// The preview's: problems 0–2 and every even one strips (b 2–4 early, then 2, 3, 4, 6 or 8; W a multiple of b up to 8,
    /// H 2–6, 12 to 48 tiles); the odd ones from 3 other shapes (a snake whose parts aren't all rectangles), one in four
    /// not equal.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 3 || i % 2 == 0 {
            let b = i < 3 ? Fr3.pick([2, 3, 4], &rng) : Fr3.pick([2, 3, 4, 6, 8], &rng)
            while true {
                let W = b * Fr3.r(1, 8 / b, &rng), H = Fr3.r(2, 6, &rng)
                if W >= 2 && W * H >= 12 && W * H <= 48 { return strips(W: W, H: H, b: b) }
            }
        }
        while true {
            let W = Fr3.r(3, 8, &rng), H = Fr3.r(2, 6, &rng), T = W * H, b = Fr3.pick([2, 3, 4, 6, 8], &rng)
            if T < 12 || T > 48 || T % b != 0 { continue }
            let s = T / b, byCols = Fr3.chance(0.5, &rng), run = byCols ? H : W
            if s < 3 || s % run == 0 || run % s == 0 { continue }
            let bad = Fr3.chance(0.25, &rng) ? Fr3.r(0, b - 2, &rng) : -1
            let fx = Fr3.chance(0.5, &rng), fy = Fr3.chance(0.5, &rng)
            let rg = snake(W: W, H: H, b: b, byCols: byCols, fx: fx, fy: fy, bad: bad >= 0 ? bad : nil)
            // (parts that look different: at least one isn't a plain rectangle)
            var anyOdd = false
            for p in 0..<b {
                var ys: [Int] = [], xs: [Int] = []
                for (y, row) in rg.enumerated() { for (x, v) in row.enumerated() where v == p { ys.append(y); xs.append(x) } }
                let box = ((ys.max() ?? 0) - (ys.min() ?? 0) + 1) * ((xs.max() ?? 0) - (xs.min() ?? 0) + 1)
                if box != ys.count { anyOdd = true }
            }
            if !anyOdd { continue }
            return shapes(W: W, H: H, b: b, cols: byCols, fx: fx, fy: fy, bad: bad)
        }
    }

    public static let spec = LessonSpec(id: "g3-shapeparts", title: "Equal parts of a shape", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.text("\(P.b) equal parts")] },
        idea: { _ in "Equal parts have the same area: each is one of them, 1 over how many." },
        depends: ["g2-shares", "g3-area"],
        check: [CheckItem(3, when: { let P = Parts($0); return P.strips && P.b >= 6 }), CheckItem(3, when: { let P = Parts($0); return !P.strips && P.equal }),
                CheckItem(3, when: { let P = Parts($0); return !P.strips && !P.equal }), CheckItem(3)]) { x in
        let P = Parts(x), b = P.b, note = P.note.map { " " + $0 } ?? ""
        let fracHint = "The whole is cut into \(b) equal parts and you take 1. That's 1 on top, \(b) on the bottom."
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 9])
        if P.strips {
            let cutHint = "Drag the ruler until it makes \(b) parts the same size."
            let cut = LessonStep(StepWords(say: "Cut it into \(b) equal parts." + note, hint: cutHint, action: "Check"),
                answer: Fr3.hand("k", P.k0, hint: cutHint, explain: "\(b) equal parts of \(P.s) squares.", said: { k in P.cutMiss(k) }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
            let tap = LessonStep(StepWords(say: "Tap one part.", hint: "Any part will do.", action: "Check"),
                answer: AnswerTask(prompt: [.box("p")], expected: ["p": 1], hint: "Any part will do.", explain: "One part of \(b).",
                                   check: { v in (v["p"] ?? 0) >= 1 ? .right : .soft("Tap one part.") }, byHand: true),
                picture: ["at": 1])
            let write = LessonStep(StepWords(say: "Write 1 part as a fraction.", hint: fracHint, action: "Check"),
                answer: Fr3.typed("t", "b", 1, b, P.slips, hint: fracHint, nudge: "1 part of \(b)", explain: "1 part of \(b): 1/\(b)."),
                picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [cut, tap, write, done]
        }
        let countHint = "Tap every part, once each."
        let count = LessonStep(StepWords(say: "Tap each part." + note, hint: countHint, action: "Check"),
            answer: Fr3.hand("n", b, hint: countHint, explain: "\(b) parts: \(Fr3.andList(P.sizes)) squares.", said: { _ in "Tap each part." }),
            picture: ["at": 0])
        let judgeHint = "Are all the counts the same?"
        let judge = LessonStep(StepWords(say: "Tap Yes or No: are the parts equal?", hint: judgeHint, action: "Check"),
            answer: Fr3.hand("c", P.equal ? 0 : 1, hint: judgeHint, explain: P.judged, said: { _ in P.judged }),
            picture: ["at": 1], onMiss: ["ring": 1])
        guard P.equal else { return [count, judge, done] }
        let write = LessonStep(StepWords(say: "Write each part as a fraction.", hint: fracHint, action: "Check"),
            answer: Fr3.typed("t", "b", 1, b, P.slips, hint: fracHint, nudge: "1 part of \(b)", explain: "Each part is 1 of \(b): 1/\(b)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [count, judge, write, done]
    }
}

// MARK: - Unit fractions

/// Unit fractions (the web's g3-unitfrac; 3.NF.A.1). The bar is a whole of 48 squares, 8 tall, cut into b parts with k
/// shaded. Tap each part to count it (Check: "4 parts"); slide one part up (the bar steps down two blocks to make room);
/// write `1 part = [1]/[4]`; with 2 or more shaded, hop it along the shaded parts (1, 2, 3) and write
/// `shaded = [3]/[4]`; the shaded parts are named 1/4, 2/4, 3/4.
///
/// "b", "k". "at": 0 count, 1 slide, 2 one, 3 hop, 4 shaded, 9 done. Boxes: "n" parts counted (Check), "u" the part slid
/// up (its index + 1), "t1" "b1", "h" the hops let go at, "t2" "b2".
public enum UnitFrac3 {
    public static func numbers(b: Int, k: Int) -> Numbers { ["b": Double(b), "k": Double(k)] }
    public struct Parts: Sendable {
        public let b: Int, k: Int
        public init(_ x: Numbers) { b = max(2, min(8, Fr3.int(x, "b", 4))); k = max(1, min(b - 1, Fr3.int(x, "k", 1))) }
        public var pw: Int { Fr3.whole / b }
        public var oneSlips: [(Int, Int, String)] {
            [(b, 1, "The bottom number says how many equal parts make the whole: \(b). The top says how many you take: 1."),
             (1, b - 1, "The bottom counts all \(b) parts of the whole, not only the other \(b - 1).")]
        }
        public var shadedSlips: [(Int, Int, String)] {
            let u = b - k
            return [(k, u, "The bottom counts all \(b) parts of the whole, not only the \(u) that \(Fr3.isAre(u)) not shaded."),
                    (u, b, "\(Fr3.plural(u, "part", "parts")) \(Fr3.isAre(u)) not shaded. Count the shaded parts for the top."),
                    (b, k, "The bottom says how many parts make the whole: \(b). The top counts the shaded parts: \(k)."),
                    (1, b, "That's one part. \(Fr3.plural(k, "part", "parts")) \(Fr3.isAre(k)) shaded, so count \(Fr3.plural(k, "piece", "pieces")) of 1/\(b).")]
        }
        public var why: String { k > 1 ? "\(k) pieces of 1/\(b) make \(k)/\(b)." : "The whole has \(b) equal parts, and 1 is shaded." }
    }

    /// The web's: problems 0–2 one part of 2, 3 or 4 shaded; then 3, 4, 6 or 8 parts, one shaded 35% of the time, else 2
    /// to b − 1.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 3 { return numbers(b: Fr3.pick([2, 3, 4], &rng), k: 1) }
        let b = Fr3.pick([3, 4, 6, 8], &rng)
        return numbers(b: b, k: Fr3.chance(0.35, &rng) ? 1 : Fr3.r(2, b - 1, &rng))
    }

    public static let spec = LessonSpec(id: "g3-unitfrac", title: "Unit fractions", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("shaded"), .op("="), .text("?")] },
        idea: { _ in "The bottom counts the equal parts of the whole; the top counts the parts you take." },
        depends: ["g2-shares"],
        check: [CheckItem(3, when: { Parts($0).k == 1 }), CheckItem(3, when: { Parts($0).k >= 2 }),
                CheckItem(3, when: { let P = Parts($0); return P.k >= 2 && P.b >= 6 }), CheckItem(3)]) { x in
        let P = Parts(x), b = P.b, k = P.k
        let countHint = "Tap every part, shaded or not."
        let count = LessonStep(StepWords(say: "Tap each part to count it.", hint: countHint, action: "Check"),
            answer: Fr3.hand("n", b, hint: countHint, explain: "\(b) parts.", said: { _ in "Count every part, shaded or not." }),
            picture: ["at": 0], onMiss: ["ring": 1])
        let slide = LessonStep(StepWords(say: "Slide one part up.", hint: "Drag any part up out of the bar.", action: "Check"),
            answer: AnswerTask(prompt: [.box("u")], expected: ["u": 1], hint: "Drag any part up out of the bar.", explain: "One part of \(b).",
                               check: { v in (v["u"] ?? 0) >= 1 ? .right : .soft("Slide one part up.") }, byHand: true),
            picture: ["at": 1])
        let oneHint = "The whole is cut into \(b) parts and you take 1. That's 1 on top, \(b) on the bottom."
        let one = LessonStep(StepWords(say: "Write 1 part as a fraction.", hint: oneHint, action: "Check"),
            answer: Fr3.typed("t1", "b1", 1, b, P.oneSlips, hint: oneHint, nudge: "1 part of \(b)", explain: "1 part of \(b): 1/\(b)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 9])
        guard k > 1 else { return [count, slide, one, done] }
        let hopHint = "Lay it on each shaded part in turn."
        let hop = LessonStep(StepWords(say: "Hop it along the shaded parts.", hint: hopHint, action: "Check"),
            answer: Fr3.hand("h", k, hint: hopHint, explain: "\(Fr3.plural(k, "piece", "pieces")) of 1/\(b).", said: { _ in "That's past the shading." }),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let shHint = "Count the shaded parts for the top. The whole still has \(b) parts."
        let shaded = LessonStep(StepWords(say: "Write the shaded parts as a fraction.", hint: shHint, action: "Check"),
            answer: Fr3.typed("t2", "b2", k, b, P.shadedSlips, hint: shHint, nudge: "\(k) parts of \(b)", explain: "\(k) parts of \(b): \(k)/\(b)."),
            picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [count, slide, one, hop, shaded, done]
    }
}

// MARK: - Fractions on a number line

/// Fractions on a number line (the web's g3-fracline; 3.NF.A.2a, b). The line is 48 squares: 0 to 1 a whole of 48, or 0
/// to 2 with a whole of 24, a tick every whole / b. Hop from 0 to 1 (the spaces: "4 hops"), hop from 0 to the point (the
/// jumps), write `point = [3]/[4]`; then every tick is named.
///
/// "a", "b", "w" (wholes). "at": 0 spaces, 1 jumps, 2 name, 9 done. Boxes: "s" hops let go at, "j" the same, "t" "b".
public enum FracLine3 {
    public static func numbers(a: Int, b: Int, w: Int = 1) -> Numbers { ["a": Double(a), "b": Double(b), "w": Double(w)] }
    public struct Parts: Sendable {
        public let a: Int, b: Int, w: Int
        public init(_ x: Numbers) {
            b = max(2, min(8, Fr3.int(x, "b", 4))); w = Fr3.int(x, "w", 1) == 2 ? 2 : 1; a = max(1, min(w * b - 1, Fr3.int(x, "a", 3)))
        }
        /// A whole's squares, and a tick's.
        public var per: Int { Fr3.whole / w }
        public var ts: Int { per / b }
        public var N: Int { w * b }
        public var slips: [(Int, Int, String)] {
            var out: [(Int, Int, String)] = [(b, a, "The bottom is the number of spaces in one whole: \(b). The top is the number of hops: \(a)."),
                                             (a, b + 1, "The bottom counts spaces, not tick marks. One whole has \(b) spaces.")]
            if w == 2 { out.append((a, w * b, "The bottom counts the spaces in one whole, 0 to 1. That's \(b).")) }
            return out
        }
        public var why: String {
            a > b ? "\(a) hops of 1/\(b): past 1, because \(a) is more than \(b)." : "\(Fr3.plural(a, "hop", "hops")) of 1/\(b) \(a == 1 ? "lands" : "land") on \(a)/\(b)."
        }
    }

    /// The web's: problems 0–2 halves, thirds or fourths, 0 to 1; then thirds to eighths, a line to 2 three times in ten
    /// when b is 6 or less (the point past 1). Never on a whole.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let b = i < 3 ? Fr3.pick([2, 3, 4], &rng) : Fr3.pick([3, 4, 6, 8], &rng)
        let w = i >= 3 && b <= 6 && Fr3.chance(0.3, &rng) ? 2 : 1
        var a: Int
        repeat { a = Fr3.r(1, w * b - 1, &rng) } while a % b == 0 || (w == 2 && a < b)
        return numbers(a: a, b: b, w: w)
    }

    public static let spec = LessonSpec(id: "g3-fracline", title: "Fractions on a number line", master: "number-line",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("point"), .op("="), .text("?")] },
        idea: { _ in "Cut 0 to 1 into equal spaces: each hop is one of them, and the hops name the point." },
        depends: ["g3-unitfrac"],
        check: [CheckItem(3, when: { Parts($0).w == 1 }), CheckItem(3, when: { Parts($0).w == 2 }),
                CheckItem(3, when: { Parts($0).b >= 6 }), CheckItem(3)]) { x in
        let P = Parts(x), a = P.a, b = P.b
        let sHint = "Hop a space at a time until you land on 1."
        let spaces = LessonStep(StepWords(say: "Hop from 0 to 1.", hint: sHint, action: "Check"),
            answer: Fr3.hand("s", b, hint: sHint, explain: "\(b) hops from 0 to 1.", said: { n in n > b ? "That's past 1." : "Hop all the way to 1." }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let jHint = "Hop a space at a time until you land on the point."
        let jumps = LessonStep(StepWords(say: "Hop from 0 to the point.", hint: jHint, action: "Check"),
            answer: Fr3.hand("j", a, hint: jHint, explain: "\(a) hops to the point.", said: { n in n > a ? "That's past the point." : "Hop all the way to the point." }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let nHint = "Top: the hops, \(a). Bottom: the spaces in one whole, \(b)."
        let name = LessonStep(StepWords(say: "Write the point as a fraction.", hint: nHint, action: "Check"),
            answer: Fr3.typed("t", "b", a, b, P.slips, hint: nHint, nudge: nil, explain: "\(a) hops of 1/\(b): \(a)/\(b)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [spaces, jumps, name, LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 9])]
    }
}

// MARK: - Equal fractions

/// Equal fractions (g3-equiv, new; 3.NF.A.3a, b, c). Same point: two lines 0 to 1, 48 squares, six rows apart; the top cut
/// in b with its point at a/b, named; the bottom cut in d with a point at 0. Drag the point under a/b (a dashed line drops
/// from the top point as it nears; "5 eighths"), write `3/4 = [6]/[8]`; both points ring and each coarser piece shows how
/// many finer ones it holds. Wholes: one line 0 to 2 (a whole of 24, cut in b) or 0 to 4 in wholes (12 each); hop to the
/// point, write `2 = [8]/[4]`.
///
/// "kind" 0 same point ("a", "b", "d"), 1 wholes ("n", "b"). "at": 0 drag / hop, 1 write, 9 done. Boxes: "m" the point let
/// go at (ticks), "h" hops, "t" "b".
public enum Equiv3 {
    public static func same(a: Int, b: Int, d: Int) -> Numbers { ["kind": 0, "a": Double(a), "b": Double(b), "d": Double(d)] }
    public static func wholes(n: Int, b: Int) -> Numbers { ["kind": 1, "n": Double(n), "b": Double(b)] }
    public struct Parts: Sendable {
        public let kind: Int, a: Int, b: Int, d: Int, n: Int
        public init(_ x: Numbers) {
            kind = Fr3.int(x, "kind") == 1 ? 1 : 0
            b = max(kind == 1 ? 1 : 2, min(8, Fr3.int(x, "b", 4))); d = max(2, min(8, Fr3.int(x, "d", 8)))
            a = max(1, Fr3.int(x, "a", 3)); n = max(1, min(4, Fr3.int(x, "n", 1)))
        }
        /// Same point: the bottom's ticks to the point.
        public var c: Int { a * d / max(1, b) }
        public var t1: Int { Fr3.whole / max(1, b) }
        public var t2: Int { Fr3.whole / d }
        /// Wholes: the line's wholes (4 in wholes, else 2), a whole's squares, a tick's, the hops to the point.
        public var Lw: Int { b == 1 ? 4 : 2 }
        public var per: Int { Fr3.whole / Lw }
        public var ts: Int { per / b }
        public var A: Int { n * b }
        public func dragSaid(_ m: Int) -> String { m < c ? "That's \(m) \(Fr3.pname(m, d)). \(c - m) more." : "That's past it." }
        public var sameSlips: [(Int, Int, String)] {
            [(a, d, "That's \(a) \(Fr3.pname(a, d)). Count the \(Fr3.pname(2, d)) to the point."),
             (d, c, "The bottom says how many pieces make the whole: \(d). The top counts them to the point: \(c)."),
             (c, d + 1, "The bottom counts spaces, not tick marks. One whole has \(d) spaces.")]
        }
        public var wholeSlips: [(Int, Int, String)] {
            [(b, A, "The bottom says how many pieces make one whole: \(b). The top counts the hops: \(A)."),
             (A, b + 1, "The bottom counts spaces, not tick marks. One whole has \(Fr3.plural(b, "space", "spaces"))."),
             (A, Lw * b, "The bottom counts the spaces in one whole, 0 to 1. That's \(b)."),
             (n, b, "That's \(n) \(Fr3.pname(n, b)). Count the hops to the point.")]
        }
        public var why: String {
            if kind == 0 { return "Same point, so they're the same amount." }
            if b == 1 { return n == 1 ? "1 piece makes a whole." : "1 piece makes a whole, so \(n) pieces make \(n)." }
            return n == 1 ? "\(b) \(Fr3.pname(b, b)) make a whole." : "\(b) \(Fr3.pname(b, b)) make a whole, so \(A) \(Fr3.pname(A, b)) make \(n)."
        }
    }

    /// The design's: same point with b and d from the pairs 2–4, 2–6, 2–8, 3–6, 4–8 (either on top; problems 0–2 halves and
    /// fourths, problem 0 halves on top), a/b on a tick of d; then wholes one problem in four (problems 6, 10, …): 0 to 2
    /// cut in halves to sixths (the point on 1 or 2), or 0 to 4 in wholes.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i >= 3 && (i - 3) % 4 == 3 {
            let b = Fr3.pick([1, 2, 3, 4, 6], &rng)
            return wholes(n: b == 1 ? Fr3.r(1, 4, &rng) : Fr3.r(1, 2, &rng), b: b)
        }
        let pairs = [(2, 4), (2, 6), (2, 8), (3, 6), (4, 8)]
        let pr = i < 3 ? (2, 4) : Fr3.pick(pairs, &rng)
        let (b, d) = i == 0 || Fr3.chance(0.5, &rng) ? pr : (pr.1, pr.0)
        let a = b < d ? Fr3.r(1, b - 1, &rng) : (b / d) * Fr3.r(1, d - 1, &rng)
        return same(a: a, b: b, d: d)
    }

    public static let spec = LessonSpec(id: "g3-equiv", title: "Equal fractions", master: "number-line",
        generate: { rng, i in make(&rng, i) },
        display: { x in
            let P = Parts(x)
            return P.kind == 0 ? [.frac(.num(Double(P.a)), .num(Double(P.b))), .op("="), .frac(.text("?"), .num(Double(P.d)))]
                               : [.num(Double(P.n)), .op("="), .frac(.text("?"), .num(Double(P.b)))]
        },
        idea: { _ in "Two fractions at the same point on the line are the same amount." },
        depends: ["g3-fracline"],
        check: [CheckItem(3, when: { let P = Parts($0); return P.kind == 0 && P.d > P.b }), CheckItem(3, when: { let P = Parts($0); return P.kind == 0 && P.d < P.b }),
                CheckItem(6, when: { Parts($0).kind == 1 }), CheckItem(3, when: { let P = Parts($0); return P.kind == 0 && P.b * P.d == 18 })]) { x in
        let P = Parts(x)
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 9])
        if P.kind == 1 {
            let hHint = "Hop a space at a time until you land on the point."
            let hop = LessonStep(StepWords(say: "Hop from 0 to the point.", hint: hHint, action: "Check"),
                answer: Fr3.hand("h", P.A, hint: hHint, explain: "\(P.A) hops to the point.", said: { m in m > P.A ? "That's past the point." : "Hop all the way to the point." }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
            let wHint = "Top: the hops, \(P.A). Bottom: the spaces in one whole, \(P.b)."
            let write = LessonStep(StepWords(say: "Write \(P.n) in \(Fr3.pname(2, P.b)).", hint: wHint, action: "Check"),
                answer: Fr3.typed("t", "b", P.A, P.b, P.wholeSlips, hint: wHint, nudge: nil, explain: "\(P.n) = \(P.A)/\(P.b)."),
                picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [hop, write, done]
        }
        let dHint = "Drag it along until it's right under \(P.a)/\(P.b)."
        let drag = LessonStep(StepWords(say: "Drag the point under \(P.a)/\(P.b).", hint: dHint, action: "Check"),
            answer: Fr3.hand("m", P.c, hint: dHint, explain: "\(P.c) \(Fr3.pname(P.c, P.d)).", said: { m in P.dragSaid(m) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let wHint = "Top: the \(Fr3.pname(2, P.d)) to the point, \(P.c). Bottom: the \(Fr3.pname(2, P.d)) in one whole, \(P.d)."
        let write = LessonStep(StepWords(say: "Write \(P.a)/\(P.b) in \(Fr3.pname(2, P.d)).", hint: wHint, action: "Check"),
            answer: Fr3.typed("t", "b", P.c, P.d, P.sameSlips, hint: wHint, nudge: nil, explain: "\(P.a)/\(P.b) = \(P.c)/\(P.d)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [drag, write, done]
    }
}

// MARK: - Comparing fractions

/// Comparing fractions (the web's g3-fraccompare; 3.NF.A.3d). Two bars of one whole (48 squares, 8 tall, 2 apart), each
/// named at its right end, the sign's place between the names. Same bottom: tap the one with more pieces (its shaded pieces
/// number). Same top: the two first pieces lift out over the bars, their real sizes; tap the bigger. The same amount: drag
/// the ruler under them to cut both into the smaller pieces. Then tap the sign (< = >): the names come together into
/// `3/8 < 5/8`, the shading's ends drop dashed lines across the other bar and the extra is outlined.
///
/// "a", "b", "c", "d" (a/b on top). "at": 0 first, 1 sign, 9 done. Boxes: "t" the bar or piece tapped (0 top, 1 bottom),
/// "r" the ruler's pieces in a whole, "c" 0 <, 1 =, 2 >.
public enum Compare3 {
    public static func numbers(a: Int, b: Int, c: Int, d: Int) -> Numbers { ["a": Double(a), "b": Double(b), "c": Double(c), "d": Double(d)] }
    public static let signs = ["<", "=", ">"]
    public static let sizes = [1, 2, 3, 4, 6, 8]
    public struct Parts: Sendable {
        public let a: Int, b: Int, c: Int, d: Int
        public init(_ x: Numbers) {
            b = max(2, min(8, Fr3.int(x, "b", 8))); d = max(2, min(8, Fr3.int(x, "d", 8)))
            a = max(1, min(b, Fr3.int(x, "a", 3))); c = max(1, min(d, Fr3.int(x, "c", 5)))
        }
        /// 0 same bottom, 1 same top, 2 the same amount.
        public var kind: Int { b == d ? 0 : a == c ? 1 : 2 }
        /// −1, 0 or 1: a/b against c/d.
        public var s: Int { let v = a * d - c * b; return v > 0 ? 1 : v < 0 ? -1 : 0 }
        public var right: Int { s + 1 }
        public var B: Int { min(b, d) }
        public var D: Int { max(b, d) }
        public var big: String { s > 0 ? "\(a)/\(b)" : "\(c)/\(d)" }
        /// The bar (or piece) to tap first.
        public var first: Int { kind == 0 ? (a > c ? 0 : 1) : (b < d ? 0 : 1) }
        public var firstMiss: String {
            if kind == 0 {
                let more = max(a, c), fewer = min(a, c)
                return "\(fewer)/\(b) is only \(Fr3.plural(fewer, "piece", "pieces")). \(more)/\(b) is \(more) of the same size."
            }
            return "\(max(b, d)) is bigger than \(min(b, d)), but \(max(b, d)) pieces in a whole are smaller pieces."
        }
        public func rulerText(_ n: Int) -> String {
            n == 1 ? "" : n > B && n % B == 0 ? "\(Fr3.pname(2, n)): \(n / B) in each \(Fr3.pname(1, B))" : Fr3.pname(2, n)
        }
        public func rulerMiss(_ n: Int) -> String { "That's \(Fr3.pname(2, n)). Cut both into \(Fr3.pname(2, D))." }
        public func signMiss(_ i: Int) -> String {
            if kind == 2 {
                return i == 0 ? "The shading lines up exactly. \(a)/\(b) and \(c)/\(d) are the same amount, cut differently."
                              : "More pieces does not mean more. The shading lines up exactly, so they are equal."
            }
            if i == 1 { return kind == 0 ? "Same size pieces, but \(big) has more of them." : "Same number of pieces, but the pieces of \(big) are bigger." }
            return kind == 1 ? "More pieces means smaller pieces. \(big) is bigger, so the sign opens toward \(big)."
                             : "\(big) is the bigger amount. The open side of the sign faces the bigger fraction."
        }
        public var say: String {
            kind == 0 ? "Tap the one with more pieces." : kind == 1 ? "Tap the bigger piece." : "Drag the ruler to cut both into \(Fr3.pname(2, D))."
        }
        public var why: String {
            kind == 0 ? "\(big) reaches further, so it's bigger." : kind == 1 ? "Fewer pieces in a whole, bigger pieces." : "The shading ends in the same place."
        }
    }

    /// The web's: problems 0–2 the same bottom; then the same bottom 40%, the same top 42%, the same amount 18%.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let r = i < 3 ? 0 : Double.random(in: 0..<1, using: &rng)
        if r < 0.4 {
            let b = Fr3.pick([3, 4, 6, 8], &rng), a = Fr3.r(1, b - 1, &rng)
            var c: Int
            repeat { c = Fr3.r(1, b - 1, &rng) } while c == a
            return numbers(a: a, b: b, c: c, d: b)
        }
        if r < 0.82 {
            var a: Int, b: Int, d: Int
            repeat { a = Fr3.r(1, 3, &rng); b = Fr3.pick([2, 3, 4, 6, 8], &rng); d = Fr3.pick([2, 3, 4, 6, 8], &rng) } while b == d || a >= min(b, d)
            return numbers(a: a, b: b, c: a, d: d)
        }
        let (b, k) = Fr3.pick([(2, 2), (2, 4), (3, 2), (4, 2)], &rng), a = Fr3.r(1, b - 1, &rng)
        return Fr3.chance(0.5, &rng) ? numbers(a: a, b: b, c: a * k, d: b * k) : numbers(a: a * k, b: b * k, c: a, d: b)
    }

    public static let spec = LessonSpec(id: "g3-fraccompare", title: "Comparing fractions", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.frac(.num(Double(P.a)), .num(Double(P.b))), .text("?"), .frac(.num(Double(P.c)), .num(Double(P.d)))] },
        idea: { _ in "Compare how far the shading reaches: same-size pieces, more is bigger; fewer pieces in a whole, bigger pieces." },
        depends: ["g3-unitfrac"],
        check: [CheckItem(3, when: { Parts($0).kind == 0 }), CheckItem(3, when: { Parts($0).kind == 1 }),
                CheckItem(3, when: { let P = Parts($0); return P.kind == 1 && P.a >= 2 }), CheckItem(3, when: { Parts($0).kind == 2 })]) { x in
        let P = Parts(x)
        let first: LessonStep
        if P.kind == 2 {
            let h = "Cut both bars into the smaller pieces: \(Fr3.pname(2, P.D))."
            first = LessonStep(StepWords(say: P.say, hint: h, action: "Check"),
                answer: Fr3.hand("r", P.D, hint: h, explain: "Both in \(Fr3.pname(2, P.D)).", said: { n in P.rulerMiss(n) }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        } else {
            let h = P.kind == 0 ? "The pieces are the same size. Which has more?" : "Fewer pieces in a whole are bigger pieces."
            first = LessonStep(StepWords(say: P.say, hint: h, action: "Check"),
                answer: Fr3.hand("t", P.first, hint: h, explain: P.why, said: { _ in P.firstMiss }),
                picture: ["at": 0], onMiss: ["ring": 1])
        }
        let sh = "The open side of the sign faces the bigger amount."
        let sign = LessonStep(StepWords(say: "Tap the sign.", hint: sh, action: "Check"),
            answer: Fr3.hand("c", P.right, hint: sh, explain: "\(P.a)/\(P.b) \(Compare3.signs[P.right]) \(P.c)/\(P.d)", said: { i in P.signMiss(i) }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        return [first, sign, LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 9])]
    }
}
