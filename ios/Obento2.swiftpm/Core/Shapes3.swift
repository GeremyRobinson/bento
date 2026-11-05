import Foundation

// 3rd grade's chapter 4, Shapes and area (design/grade3.md chapter 4, the preview design/prototype/grade3-ch4.html): a
// quadrilateral's sides, corners, lengths and parallel sides found by tapping, then its most special name; area as tiles
// laid in a row and the row dragged down; an L cut into two rectangles; the edge traced round a shape a cm at a time; and
// a fence and a garden dragged into shape. Where a lesson measures area, one square of the grid is one square unit (the
// call of 4 Nov), so the tiles are the paper's own squares. Every number the child writes is typed with the iPad's keys
// and Check; the preview's grey lines (a story, what a square stands for) are folded into the instruction.

/// What the chapter shares.
public enum S3 {
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { Int((v[k] ?? Double(d)).rounded()) }
    static func r(_ a: Int, _ b: Int, _ rng: inout SeededRandom) -> Int { a >= b ? a : Int.random(in: a...b, using: &rng) }
    static func pick<T>(_ a: [T], _ rng: inout SeededRandom) -> T { a[Int.random(in: 0..<a.count, using: &rng)] }
    /// "1 row", "3 rows".
    public static func count(_ n: Int, _ one: String, _ many: String) -> String { "\(n) \(n == 1 ? one : many)" }
    /// A step answered by a code its hand move puts in the box: right when it's `want`, else what `said` says (a real miss,
    /// or a notice that isn't one).
    static func hand(_ box: String, _ want: Int, hint: String, explain: String, said: @escaping @Sendable (Int) -> Verdict) -> AnswerTask {
        AnswerTask(prompt: [.box(box)], expected: [box: Double(want)], hint: hint, explain: explain,
                   check: { v in let x = Int((v[box] ?? -99).rounded()); return x == want ? .right : said(x) }, byHand: true)
    }
    /// A typed number whose answer and slips follow what an earlier move kept (`kept` read from "kept.<name>").
    static func typedKept(_ box: String, want: @escaping @Sendable (Numbers) -> Int, slips: @escaping @Sendable (Numbers) -> [(Int, String)],
                          hint: @escaping @Sendable (Numbers) -> String, plain: String) -> AnswerTask {
        AnswerTask(prompt: [.box(box)], expected: [box: Double(want([:]))], hint: plain, explain: plain,
                   check: { v in
                       guard let x = v[box] else { return .soft("Write the number.") }
                       var kept: Numbers = [:]
                       for (k, y) in v where k.hasPrefix("kept.") { kept[String(k.dropFirst(5))] = y }
                       let w = want(kept), n = Int(x.rounded())
                       if n == w { return .right }
                       return .wrong(slips(kept).first { $0.0 == n && $0.0 != w }?.1 ?? "Not quite. \(hint(kept))")
                   }, incomplete: "Write the number.",
                   expectKept: { kept in [box: Double(want(kept))] })
    }
}

// MARK: - Quadrilaterals

/// Quadrilaterals (the web's g3-quads; 3.G.A.1). One square is a unit of length. The shape is big, its corners on grid
/// crossings, every side a whole number of squares; a turned shape runs along 3-4-5 steps. Tap each side (problems 1–3),
/// tap the square corners (a page corner lays itself in each; Done), tap each side to measure it (a strip of squares lays
/// along it, matching sides get the same ticks), Yes or No: all 4 sides the same?, tap two sides that never meet (they
/// run on, dashed; parallel ones get matching arrowheads, others are measured closing in; No more), tap its most special
/// name, and (every 4th) is this square also a rectangle? Make one (problems 7, 15, …): drag a corner of a square until it
/// isn't a square, rectangle or rhombus; Done; then its name. The record beside it gets one short line a step.
///
/// Numbers: "shape" 0–5 (`names`), "x0" "y0" … "x3" "y3" its corners in squares, "turn", "warm", "also", "make".
/// "at": 0 sides, 1 corners, 2 measure, 3 equal, 4 parallel, 5 name, 6 also, 7 done, 8 make. Boxes: "s" sides lit (4), −1 a
/// tap inside, −2 a side again; "c" the corners found when Done (or 4), 100 + i a corner that isn't square; "l" sides
/// measured (4), −2 again; "e" 1 Yes, 0 No; "p" pairs found (No more, or 2), 50 two sides that meet, 100 + k a pair that
/// closes in; "n" the name tapped; "a" 1 Yes, 0 No; "m" the made shape's name when Done, −1 a side too short, −2 sides
/// crossed, −3 a corner pointing in. Kept on make: "made" its name, "mR" its square corners, "mE" 1 all sides equal, "mP"
/// its parallel pairs, "v0x" … its corners.
public enum Quads3 {
    public static let names = ["square", "rectangle", "rhombus", "parallelogram", "trapezoid", "quadrilateral"]
    public static let named = [
        "Every corner fits a page corner, and all 4 sides are equal.",
        "4 square corners, but the sides aren't all equal.",
        "4 equal sides, but no square corners.",
        "2 pairs of parallel sides, but no square corners and not all sides equal.",
        "Only 1 pair of parallel sides: its most special name is trapezoid.",
        "No special name fits: it's just a 4-sided shape.",
    ]

    /// What a shape's corners make it: its sides (across, down), their lengths squared, which corners are square (corner i
    /// between side i − 1 and side i), which opposite pairs are parallel (0: sides 0 and 2, 1: sides 1 and 3), its name.
    public struct Cls: Sendable {
        public let sides: [(Int, Int)], l2: [Int], right: [Bool], par: [Bool], allEqual: Bool, name: Int, convex: Bool
        public var nRight: Int { right.filter { $0 }.count }
        public var nPar: Int { par.filter { $0 }.count }
        public var lens: [Double] { l2.map { Double($0).squareRoot() } }
        public var len: [Int] { lens.map { Int($0.rounded()) } }
        /// Corner i is narrower than a square corner.
        public func narrow(_ i: Int) -> Bool {
            let u = sides[i], w = (-sides[(i + 3) % 4].0, -sides[(i + 3) % 4].1)
            return u.0 * w.0 + u.1 * w.1 > 0
        }
    }
    public static func classify(_ v: [(Int, Int)]) -> Cls {
        let s = (0..<4).map { (v[($0 + 1) % 4].0 - v[$0].0, v[($0 + 1) % 4].1 - v[$0].1) }
        let l2 = s.map { $0.0 * $0.0 + $0.1 * $0.1 }
        let right = (0..<4).map { i in s[i].0 * s[(i + 3) % 4].0 + s[i].1 * s[(i + 3) % 4].1 == 0 }
        let par = [0, 1].map { i in s[i].0 * s[i + 2].1 - s[i].1 * s[i + 2].0 == 0 }
        let eq = l2.allSatisfy { $0 == l2[0] }
        let nR = right.filter { $0 }.count, nP = par.filter { $0 }.count
        let name = nR == 4 && eq ? 0 : nR == 4 ? 1 : eq ? 2 : nP == 2 ? 3 : nP == 1 ? 4 : 5
        let cr = (0..<4).map { i in s[i].0 * s[(i + 1) % 4].1 - s[i].1 * s[(i + 1) % 4].0 }
        return Cls(sides: s, l2: l2, right: right, par: par, allEqual: eq, name: name, convex: cr.allSatisfy { $0 > 0 } || cr.allSatisfy { $0 < 0 })
    }
    /// A shape a corner was dragged into: its name, or why it can't stay (−1 a side under 3, −2 sides cross, −3 a corner in).
    public static func madeCode(_ v: [(Int, Int)]) -> Int {
        let c = classify(v)
        if (c.l2.min() ?? 0) < 9 { return -1 }
        if cross(v[0], v[1], v[2], v[3]) || cross(v[1], v[2], v[3], v[0]) { return -2 }
        if !c.convex { return -3 }
        return c.name
    }
    static func cross(_ a: (Int, Int), _ b: (Int, Int), _ c: (Int, Int), _ d: (Int, Int)) -> Bool {
        func o(_ p: (Int, Int), _ q: (Int, Int), _ r: (Int, Int)) -> Int { ((q.0 - p.0) * (r.1 - p.1) - (q.1 - p.1) * (r.0 - p.0)).signum() }
        return o(a, b, c) * o(a, b, d) < 0 && o(c, d, a) * o(c, d, b) < 0
    }

    /// How far apart two opposite sides (side i and side i + 2) are at each end of one of them, in whole squares, measured
    /// square on to whichever side the other's ends drop onto inside it: the ends, where they drop, how far.
    public struct Close: Sendable { public let from: [(Double, Double)], feet: [(Double, Double)], d: [Int] }
    public static func closeIn(_ v: [(Int, Int)], _ i: Int) -> Close {
        func opt(_ s: Int, _ t: Int) -> (Close, Double) {
            let p = v[t % 4], q = v[(t + 1) % 4], px = Double(p.0), py = Double(p.1)
            let ex = Double(q.0 - p.0), ey = Double(q.1 - p.1), L = (ex * ex + ey * ey).squareRoot(), ux = ex / L, uy = ey / L
            let from = [v[s % 4], v[(s + 1) % 4]].map { (Double($0.0), Double($0.1)) }
            let ts = from.map { (($0.0 - px) * ux + ($0.1 - py) * uy) / L }
            let feet = ts.map { (px + ex * $0, py + ey * $0) }
            let d = from.map { Int(abs(ux * ($0.1 - py) - uy * ($0.0 - px)).rounded()) }
            return (Close(from: from, feet: feet, d: d), ts.reduce(0.0) { $0 + max(0, -$1, $1 - 1) })
        }
        let a = opt(i + 2, i), b = opt(i, i + 2)
        return a.1 <= b.1 ? a.0 : b.0
    }

    /// The preview's words for a wrong name: `shape` the right one, `i` the one tapped.
    public static func nameSlip(_ c: (nRight: Int, allEqual: Bool, nPar: Int), shape: Int, _ i: Int) -> String {
        if shape == 0 && i == 1 { return "It is a rectangle, but all 4 sides are equal too. Its most special name is square." }
        if shape == 0 && i == 2 { return "It has 4 square corners too: it's a square." }
        if shape == 3 && i == 1 { return "A rectangle needs 4 square corners. This one leans." }
        if i == 5 { return "It is a quadrilateral, but it has a more special name. Look at its sides and corners." }
        if (i == 0 || i == 1) && c.nRight < 4 { return "A \(names[i]) needs 4 square corners. This has \(c.nRight)." }
        if (i == 0 || i == 2) && !c.allEqual { return "A \(names[i]) has 4 equal sides. These aren't all equal." }
        if i == 3 && c.nPar < 2 { return "A parallelogram has 2 pairs of parallel sides." }
        if i == 4 && c.nPar != 1 { return "A trapezoid has exactly 1 pair of parallel sides." }
        return "It fits a more special name: \(names[shape])."
    }

    public static func numbers(shape: Int, v: [(Int, Int)], turn: Int = 0, warm: Bool = false, also: Bool = false, make: Bool = false) -> Numbers {
        var n: Numbers = ["shape": Double(shape), "turn": Double(turn), "warm": warm ? 1 : 0, "also": also ? 1 : 0, "make": make ? 1 : 0]
        for (i, p) in v.prefix(4).enumerated() { n["x\(i)"] = Double(p.0); n["y\(i)"] = Double(p.1) }
        return n
    }
    public struct Parts: Sendable {
        public let shape: Int, v: [(Int, Int)], warm: Bool, also: Bool, make: Bool
        public init(_ x: Numbers) {
            shape = max(0, min(5, S3.int(x, "shape")))
            let sq = [(0, 0), (20, 0), (20, 20), (0, 20)]
            v = (0..<4).map { i in x["x\(i)"] == nil ? sq[i] : (S3.int(x, "x\(i)"), S3.int(x, "y\(i)")) }
            warm = S3.int(x, "warm") != 0; also = S3.int(x, "also") != 0; make = S3.int(x, "make") != 0
        }
        public var cls: Cls { Quads3.classify(v) }
        public var w: Int { v.map(\.0).max() ?? 0 }
        public var h: Int { v.map(\.1).max() ?? 0 }
        /// The steps' "at" codes, in order.
        public var stages: [Int] { make ? [8, 5, 7] : (warm ? [0] : []) + [1, 2, 3, 4, 5] + (also ? [6] : []) + [7] }
        public var alsoSay: String { shape == 0 ? "Tap Yes or No: is this square also a rectangle?" : "Tap Yes or No: is this rectangle also a square?" }
        /// The last line: the name's line, or the also question's answer.
        public func doneSay(_ name: Int) -> String { also ? (shape == 0 ? "Every square is a rectangle." : "Its sides aren't all equal.") : Quads3.named[max(0, min(5, name))] }
        public func cornersMiss(_ x: Int) -> Verdict {
            if x >= 100 { return .wrong(cls.narrow(x - 100) ? "That corner is narrower than a square corner." : "That corner is wider than a square corner.") }
            let left = cls.nRight - x
            return .wrong(left == 1 ? "One more corner fits a paper corner." : "\(left) more corners fit a paper corner.")
        }
        public func pairsMiss(_ x: Int) -> Verdict {
            if x == 50 { return .wrong("Those two meet at a corner.") }
            if x >= 100 { let d = Quads3.closeIn(v, x - 100).d; return .wrong("They close in: \(d[0]) squares apart here, \(d[1]) there.") }
            return .wrong("There's another pair that never meets.")
        }
    }

    // the shapes' sizes in squares (the web's pixel sizes, a fifth): slanted sides along whole-number triangles
    static let legs = [(5, 12), (9, 12), (8, 15), (12, 16), (16, 12), (15, 20)]
    static let off: [Int: [Int]] = [12: [0, 5, 9, 16], 15: [0, 8, 20], 16: [0, 12], 20: [0, 15, 21]]
    static let pyv: [(Int, Int)] = {
        var o: [(Int, Int)] = []
        for x in -30...30 {
            for y in -30...30 {
                let l2 = x * x + y * y, l = Int(Double(l2).squareRoot().rounded())
                if l * l == l2 && l >= 8 && l <= 28 { o.append((x, y)) }
            }
        }
        return o
    }()
    static let rots = [(4, 3), (3, 4), (4, -3), (3, -4)]
    static func root(_ n: Int) -> Int? { let r = Int(Double(n).squareRoot().rounded()); return r * r == n ? r : nil }

    static func base(_ shape: Int, _ turned: Bool, _ rng: inout SeededRandom) -> [(Int, Int)]? {
        switch shape {
        case 0:
            let s = turned ? S3.pick([15, 20], &rng) : S3.r(16, 24, &rng)
            return [(0, 0), (s, 0), (s, s), (0, s)]
        case 1:
            let w = turned ? 5 * S3.r(4, 7, &rng) : S3.r(26, 40, &rng), h = turned ? 5 * S3.r(2, 3, &rng) : S3.r(12, 22, &rng)
            return w - h < 6 ? nil : [(0, 0), (w, 0), (w, h), (0, h)]
        case 2:
            let (a, b) = S3.pick(legs, &rng), s = root(a * a + b * b) ?? 13
            return [(a, 0), (a + s, 0), (s, b), (0, b)]
        case 3:
            let (a, b) = S3.pick(legs, &rng), w = turned ? 5 * S3.r(3, 5, &rng) : S3.r(22, 34, &rng)
            return [(a, 0), (a + w, 0), (w, b), (0, b)]
        case 4:
            let h = S3.pick([12, 15, 16, 20], &rng), o1 = S3.pick(off[h]!, &rng), o2 = S3.pick(off[h]!, &rng), w = S3.r(26, 40, &rng), top = w - o1 - o2
            return top < 10 || (o1 == 0 && o2 == 0) ? nil : [(o1, 0), (o1 + top, 0), (w, h), (0, h)]
        default:
            var vs = [S3.pick(pyv, &rng), S3.pick(pyv, &rng), S3.pick(pyv, &rng)]
            let sx = vs.reduce(0) { $0 + $1.0 }, sy = vs.reduce(0) { $0 + $1.1 }
            guard let l4 = root(sx * sx + sy * sy), l4 >= 8 else { return nil }
            vs.append((-sx, -sy))
            vs.sort { atan2(Double($0.1), Double($0.0)) < atan2(Double($1.1), Double($1.0)) }
            var out = [(0, 0)]
            for k in 0..<3 { out.append((out[k].0 + vs[k].0, out[k].1 + vs[k].1)) }
            return out
        }
    }

    /// The web's order: problems 0–2 a square, a rectangle and a trapezoid with the sides warm-up; every index % 4 = 3 a
    /// square or rectangle with the also question; the rest (index × 5 + 0 or 1) % 6, turned along 3-4-5 steps from problem
    /// 4; make one (a square to change) at index % 8 = 6. Every side 8 squares or more, the shape 42 × 26 at most.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let early = i < 3, also = i % 4 == 3, mk = !early && i % 8 == 6
        let shape = mk ? 0 : early ? [0, 1, 4][i] : also ? S3.r(0, 1, &rng) : (i * 5 + S3.r(0, 1, &rng)) % 6
        var turn = early || mk ? 0 : S3.r(0, 4, &rng)
        var tries = 0
        while true {
            tries += 1
            if tries >= 400 { turn = 0 }
            guard var v = mk ? [(0, 0), (20, 0), (20, 20), (0, 20)] : base(shape, turn > 0, &rng) else { continue }
            if turn > 0 {
                let (cs, sn) = rots[turn - 1]
                let t = v.map { (cs * $0.0 - sn * $0.1, sn * $0.0 + cs * $0.1) }
                guard t.allSatisfy({ $0.0 % 5 == 0 && $0.1 % 5 == 0 }) else { continue }
                v = t.map { ($0.0 / 5, $0.1 / 5) }
            }
            let mx = v.map(\.0).min() ?? 0, my = v.map(\.1).min() ?? 0
            v = v.map { ($0.0 - mx, $0.1 - my) }
            guard (v.map(\.0).max() ?? 0) <= 42, (v.map(\.1).max() ?? 0) <= 26 else { continue }
            let c = classify(v)
            guard c.convex, c.name == shape, (c.l2.min() ?? 0) >= 64, c.l2.allSatisfy({ root($0) != nil }) else { continue }
            if [0, 1].contains(where: { k in let d = closeIn(v, k).d; return !c.par[k] && abs(d[0] - d[1]) < 2 }) { continue }
            return numbers(shape: shape, v: v, turn: turn, warm: early, also: also, make: mk)
        }
    }

    public static let spec = LessonSpec(id: "g3-quads", title: "Quadrilaterals", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("Name the shape.")] },
        idea: { _ in "Sides and corners give a shape its most special name." },
        depends: ["k-shapes"],
        check: [CheckItem(3, when: { Parts($0).also }), CheckItem(4, when: { Parts($0).shape == 2 }),
                CheckItem(8, when: { Parts($0).shape == 4 }), CheckItem(9, when: { Parts($0).shape == 3 })]) { x in
        let P = Parts(x), c = P.cls
        var out: [LessonStep] = []
        for st in P.stages {
            switch st {
            case 0:
                let hint = "Tap each line around the edge once."
                out.append(LessonStep(StepWords(say: "Tap each side.", hint: hint, action: "Check"),
                    answer: S3.hand("s", 4, hint: hint, explain: "4 sides.", said: { n in
                        .soft(n == -2 ? "That side is counted. Tap the others." : "Tap a side: one of the lines around the edge.") }),
                    picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1]))
            case 1:
                let hint = "A square corner fits a page corner."
                out.append(LessonStep(StepWords(say: "Tap the square corners.", hint: hint, action: "Done"),
                    answer: S3.hand("c", c.nRight, hint: hint, explain: S3.count(c.nRight, "square corner", "square corners") + ".", said: { P.cornersMiss($0) }),
                    picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
            case 2:
                let hint = "Tap each side once."
                out.append(LessonStep(StepWords(say: "Tap each side to measure it.", hint: hint, action: "Check"),
                    answer: S3.hand("l", 4, hint: hint, explain: "Each side measured.", said: { _ in .soft("That side is measured. Tap the others.") }),
                    picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
            case 3:
                let hint = "Look at the 4 lengths."
                out.append(LessonStep(StepWords(say: "Tap Yes or No: all 4 sides the same?", hint: hint, action: "Check"),
                    answer: S3.hand("e", c.allEqual ? 1 : 0, hint: hint, explain: c.allEqual ? "All 4 sides are the same." : "Not all the same.", said: { _ in
                        .wrong(c.allEqual ? "Measure them: all 4 sides are the same length." : "Compare them: some sides are longer than others.") }),
                    picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
            case 4:
                let hint = "Opposite sides that stay the same distance apart never meet."
                out.append(LessonStep(StepWords(say: "Tap two sides that never meet.", hint: hint, action: "No more"),
                    answer: S3.hand("p", c.nPar, hint: hint, explain: S3.count(c.nPar, "pair", "pairs") + " of parallel sides.", said: { P.pairsMiss($0) }),
                    picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1]))
            case 5:
                let hint = "Look at its sides and corners."
                if P.make {
                    let a = AnswerTask(prompt: [.box("n")], expected: ["n": 3], hint: hint, explain: "Its most special name.",
                        check: { v in
                            let made = S3.int(v, "kept.made", 3), n = S3.int(v, "n", -1)
                            if n == made { return .right }
                            let k = (nRight: S3.int(v, "kept.mR"), allEqual: S3.int(v, "kept.mE") != 0, nPar: S3.int(v, "kept.mP"))
                            return .wrong(Quads3.nameSlip(k, shape: made, n))
                        }, byHand: true, expectKept: { kept in ["n": kept["made"] ?? 3] })
                    out.append(LessonStep(StepWords(say: "Tap its most special name.", hint: hint, action: "Check"), answer: a,
                        picture: ["at": 5], onMiss: ["ring": 1], hint2: ["spot": 1]))
                } else {
                    let k = (nRight: c.nRight, allEqual: c.allEqual, nPar: c.nPar)
                    out.append(LessonStep(StepWords(say: "Tap its most special name.", hint: hint, action: "Check"),
                        answer: S3.hand("n", P.shape, hint: hint, explain: "It's a \(names[P.shape]).", said: { .wrong(Quads3.nameSlip(k, shape: P.shape, $0)) }),
                        picture: ["at": 5], onMiss: ["ring": 1], hint2: ["spot": 1]))
                }
            case 6:
                let sq = P.shape == 0, hint = sq ? "A rectangle needs 4 square corners." : "A square needs 4 equal sides."
                out.append(LessonStep(StepWords(say: P.alsoSay, hint: hint, action: "Check"),
                    answer: S3.hand("a", sq ? 1 : 0, hint: hint, explain: sq ? "Yes." : "No.", said: { _ in
                        .wrong(sq ? "A rectangle needs 4 square corners. A square has them, so every square is a rectangle." : "A square needs 4 equal sides. These aren't all equal.") }),
                    picture: ["at": 6], onMiss: ["ring": 1], hint2: ["spot": 1]))
            case 8:
                let hint = "Drag one corner so a corner isn't square any more."
                out.append(LessonStep(StepWords(say: "Drag a corner. Make a 4-sided shape that isn't a square, rectangle or rhombus.", hint: hint, action: "Done"),
                    answer: AnswerTask(prompt: [.box("m")], expected: ["m": 3], hint: hint, explain: "Not a square, rectangle or rhombus.",
                        check: { v in
                            let m = S3.int(v, "m", 0)
                            switch m {
                            case 3...5: return .right
                            case -1: return .wrong("Keep 4 sides.")
                            case -2: return .wrong("The sides cross. Keep 4 sides.")
                            case -3: return .wrong("That corner points in. Keep every corner pointing out.")
                            default:
                                let k = max(0, min(2, m))
                                return .wrong("It's still a \(names[k]): \(["4 square corners and 4 equal sides", "4 square corners", "4 equal sides"][k]).")
                            }
                        }, byHand: true),
                    picture: ["at": 8], onMiss: ["ring": 1], hint2: ["spot": 1]))
            default:
                out.append(LessonStep(StepWords(say: P.doneSay(P.shape), hint: "", action: "Next problem"), picture: ["at": 7]))
            }
        }
        return out
    }
}

// MARK: - Area by counting squares

/// Area by counting squares (the web's g3-area; 3.MD.C.5, 3.MD.C.6, 3.MD.C.7a, b). One square of the grid is one square
/// unit, a tile. The rectangle's outline, `l` across and `w` down, its sides named. Drag across the top row to tile it
/// ("5 tiles"); drag the row down (rows of l fill down and count by l at the right end, "3 rows of 7"); write
/// `4 × 7 = [28] square units`. From problem 4 a problem names a unit in turn (a rug "7 ft by 4 ft": square feet).
///
/// "l", "w", "unit" (0 square units, 1 ft, 2 cm, 3 m, 4 in). "at": 0 row, 1 rows, 2 write, 3 done. Boxes: "n" the tiles laid
/// in the top row, "r" the rows let go at, "A".
public enum Area3 {
    public static let units: [(u: String, sq: String, thing: String)] = [("", "square units", ""), ("ft", "square feet", "A rug"),
        ("cm", "square centimeters", "A sticker"), ("m", "square meters", "A garden"), ("in", "square inches", "A photo")]
    public static func numbers(l: Int, w: Int, unit: Int = 0) -> Numbers { ["l": Double(l), "w": Double(w), "unit": Double(unit)] }
    public struct Parts: Sendable {
        public let l: Int, w: Int, unit: Int
        public init(_ x: Numbers) { l = max(2, min(10, S3.int(x, "l", 7))); w = max(1, min(8, S3.int(x, "w", 4))); unit = max(0, min(4, S3.int(x, "unit"))) }
        public var A: Int { l * w }
        public var uw: String { Area3.units[unit].sq }
        /// A side's name: "7 ft", or "7".
        public func nm(_ n: Int) -> String { unit == 0 ? "\(n)" : "\(n) \(Area3.units[unit].u)" }
        public var story: String? { unit == 0 ? nil : "\(Area3.units[unit].thing) is \(l) \(Area3.units[unit].u) by \(w) \(Area3.units[unit].u)." }
        public var slips: [(Int, String)] {
            [(2 * (l + w), "\(2 * (l + w)) is the distance around. Area counts the tiles inside."),
             (l + w, "\(l) + \(w) counts one row and one column. Every row has \(l) tiles, so multiply."),
             (A - l, "That's \(S3.count(w - 1, "row", "rows")). Count all \(w) rows of \(l).")]
        }
        public var why: String { "\(w) rows of \(l) tiles: \(A) \(uw)." }
    }

    /// The web's: problems 0–2 l 3–5 by w 2–4; then l 3–10 by w 2–8; from problem 4 a unit in turn (feet, centimeters,
    /// meters, inches, then square units).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let e = i < 3
        return numbers(l: e ? S3.r(3, 5, &rng) : S3.r(3, 10, &rng), w: e ? S3.r(2, 4, &rng) : S3.r(2, 8, &rng), unit: e ? 0 : [1, 2, 3, 4, 0][(i - 3) % 5])
    }

    public static let spec = LessonSpec(id: "g3-area", title: "Area by counting squares", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.num(Double(P.l)), .op("×"), .num(Double(P.w))] },
        idea: { _ in "Area counts the square tiles inside: rows of tiles, so multiply." },
        depends: ["g2-arrays", "g3-facts"],
        check: [CheckItem(3), CheckItem(3, when: { Parts($0).l >= 7 }), CheckItem(3, when: { Parts($0).w >= 6 }), CheckItem(3)]) { x in
        let P = Parts(x)
        let rowHint = "Drag from the left end all the way to the right end."
        let row = LessonStep(StepWords(say: (P.story.map { $0 + " " } ?? "") + "Drag across the top row to tile it.", hint: rowHint, action: "Check"),
            answer: S3.hand("n", P.l, hint: rowHint, explain: "\(P.l) tiles in a row.", said: { _ in .soft("The row has \(P.l). Keep going.") }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let rowsHint = "Stop when there are \(P.w) rows."
        let rows = LessonStep(StepWords(say: "Drag the row down.", hint: rowsHint, action: "Check"),
            answer: S3.hand("r", P.w, hint: rowsHint, explain: "\(P.w) rows of \(P.l).", said: { r in .wrong("That's \(S3.count(r, "row", "rows")). The rectangle has \(P.w).") }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let hint = "Count by \(P.l)s, once for each of the \(P.w) rows."
        let write = LessonStep(StepWords(say: "Write \(P.w) × \(P.l).", hint: hint, action: "Check"),
            answer: G3.typed("A", P.A, P.slips, hint: hint, explain: "\(P.w) × \(P.l) = \(P.A)."),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [row, rows, write, done]
    }
}

// MARK: - Area of L-shapes

/// Area of L-shapes (g3-lshape, new; 3.MD.C.7d). One square is one square unit, as Area. A W × H rectangle with a w × h
/// corner missing (K: 0 top right, 1 top left, 2 bottom right, 3 bottom left), every side named. Cut it into two rectangles
/// with the ruler, from the inside corner, down or across (readout "4 × 3 | 5 × 6", or "a rectangle | an L"); the parts
/// glide a square apart; write each part's area, `4 × 3 = [12]` (it tiles itself), then they glide back: `12 + 30 = [42]`.
/// The record reads `4 × 3 + 5 × 6`, `= 12 + 30 = 42`. From problem 7 one outside side has no name, and the cut finds it.
///
/// "W", "H", "w", "h", "K", "hide" (0, 1 the top side, 2 the side down from it). "at": 0 cut, 1 a, 2 b, 3 sum, 4 done. Boxes:
/// "k" the cut, 100 + column (down) or 200 + row (across); kept "ax" (1 down, 2 across); "a", "b", "s".
public enum LShape3 {
    public static func numbers(W: Int, H: Int, w: Int, h: Int, K: Int = 0, hide: Int = 0) -> Numbers {
        ["W": Double(W), "H": Double(H), "w": Double(w), "h": Double(h), "K": Double(K), "hide": Double(hide)]
    }
    /// A part of the L: its columns and rows, in squares of the W × H rectangle.
    public struct Part: Sendable, Equatable {
        public let x0: Int, x1: Int, y0: Int, y1: Int
        public var rows: Int { y1 - y0 }
        public var cols: Int { x1 - x0 }
        public var area: Int { rows * cols }
    }
    public struct Parts: Sendable {
        public let W: Int, H: Int, w: Int, h: Int, K: Int, hide: Int
        public init(_ x: Numbers) {
            W = max(4, min(10, S3.int(x, "W", 7))); H = max(4, min(8, S3.int(x, "H", 5)))
            w = max(1, min(W - 1, S3.int(x, "w", 2))); h = max(1, min(H - 1, S3.int(x, "h", 2)))
            K = max(0, min(3, S3.int(x, "K"))); hide = max(0, min(2, S3.int(x, "hide")))
        }
        public var fx: Bool { K == 1 || K == 3 }
        public var fy: Bool { K >= 2 }
        public var tot: Int { W * H - w * h }
        /// The inside corner's column and row: where a cut down or across starts.
        public var X: Int { fx ? w : W - w }
        public var Y: Int { fy ? H - h : h }
        /// The missing corner's columns and rows.
        public var nx: (Int, Int) { fx ? (0, w) : (W - w, W) }
        public var ny: (Int, Int) { fy ? (H - h, H) : (0, h) }
        /// The outline from the top-left of the unflipped L, flipped to K: (0,0) (W−w,0) (W−w,h) (W,h) (W,H) (0,H).
        public var outline: [(Int, Int)] {
            [(0, 0), (W - w, 0), (W - w, h), (W, h), (W, H), (0, H)].map { (fx ? W - $0.0 : $0.0, fy ? H - $0.1 : $0.1) }
        }
        /// The outline's sides' lengths, in order.
        public var lens: [Int] { [W - w, h, w, H - h, W, H] }
        /// The two parts a cut down (`down`) or across makes.
        public func parts(down: Bool) -> [Part] {
            if down {
                return [(0, X), (X, W)].map { a, b in
                    let notch = a >= nx.0 && b <= nx.1
                    return Part(x0: a, x1: b, y0: notch ? (fy ? 0 : h) : 0, y1: notch ? (fy ? H - h : H) : H)
                }
            }
            return [(0, Y), (Y, H)].map { a, b in
                let notch = a >= ny.0 && b <= ny.1
                return Part(x0: notch ? (fx ? w : 0) : 0, x1: notch ? (fx ? W : W - w) : W, y0: a, y1: b)
            }
        }
        /// The ruler's rest (no cut): a corner the L has, away from the missing corner.
        public var restDown: Int { !fx && !fy ? 0 : W }
        public var restAcross: Int { fy && !fx ? 0 : H }
        /// What the side with no name is found to be: "8 − 3 = 5".
        public var found: String? { hide == 1 ? "\(W) − \(w) = \(W - w)" : hide == 2 ? "\(H) − \(h) = \(H - h)" : nil }
        static func down(_ kept: Numbers) -> Bool { (kept["ax"] ?? 1) != 2 }
        public func say(_ at: Int, down: Bool) -> String {
            let p = parts(down: down)
            switch at {
            case 0: return "Cut it into two rectangles."
            case 1: return "Write \(p[0].rows) × \(p[0].cols)."
            case 2: return "Write \(p[1].rows) × \(p[1].cols)."
            case 3: return "Write \(p[0].area) + \(p[1].area)."
            default: return "Two rectangles: add their areas."
            }
        }
        public func partSlips(_ p: Part) -> [(Int, String)] {
            p.rows + p.cols != p.area ? [(p.rows + p.cols, "\(p.cols) + \(p.rows) counts one row and one column. Every row has \(p.cols) tiles, so multiply.")] : []
        }
        public func sumSlips(down: Bool) -> [(Int, String)] {
            let p = parts(down: down)
            return [(W * H, "That counts the missing corner too."), (p[0].area, "That's one part. Add the other part too."),
                    (p[1].area, "That's one part. Add the other part too."), (2 * (W + H), "That's the distance around. Area counts the tiles inside.")]
        }
        public func cut(_ code: Int) -> Verdict {
            code == 100 + X || code == 200 + Y ? .right : .wrong("That leaves an L. Cut from the inside corner.")
        }
    }

    /// The design's: problems 0–2 W 5–7, H 4–5, a 2 × 2, 2 × 3 or 3 × 2 corner off the top right; then W 5–10, H 4–8, w 2 to
    /// W − 2, h 2 to H − 2, any corner, area 80 or less; from problem 7 one outside side has no name.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        while true {
            var W: Int, H: Int, w: Int, h: Int, K = 0
            if i < 3 {
                W = S3.r(5, 7, &rng); H = S3.r(4, 5, &rng)
                (w, h) = S3.pick([(2, 2), (2, 3), (3, 2)], &rng)
            } else {
                W = S3.r(5, 10, &rng); H = S3.r(4, 8, &rng); w = S3.r(2, W - 2, &rng); h = S3.r(2, H - 2, &rng); K = S3.r(0, 3, &rng)
            }
            if W * H - w * h <= 80 { return numbers(W: W, H: H, w: w, h: h, K: K, hide: i >= 6 ? S3.r(1, 2, &rng) : 0) }
        }
    }

    public static let spec = LessonSpec(id: "g3-lshape", title: "Area of L-shapes", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("Find the area.")] },
        idea: { _ in "Cut an L into two rectangles and add their areas." },
        depends: ["g3-area"],
        check: [CheckItem(3), CheckItem(3, when: { Parts($0).K != 0 }), CheckItem(3, when: { Parts($0).W >= 8 }), CheckItem(6, when: { Parts($0).hide != 0 })]) { x in
        let P = Parts(x)
        let cutHint = "Start the cut at the inside corner."
        let cut = LessonStep(StepWords(say: P.say(0, down: true), hint: cutHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("k")], expected: ["k": Double(100 + P.X)], hint: cutHint, explain: "Two rectangles.",
                               check: { v in P.cut(S3.int(v, "k")) }, byHand: true),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        func part(_ n: Int, _ box: String) -> LessonStep {
            let plain = "Count the tiles in a row, then multiply by the rows."
            return LessonStep(StepWords(say: P.say(n + 1, down: true), hint: plain, action: "Check"),
                answer: S3.typedKept(box, want: { k in P.parts(down: Parts.down(k))[n].area },
                                     slips: { k in P.partSlips(P.parts(down: Parts.down(k))[n]) },
                                     hint: { k in let p = P.parts(down: Parts.down(k))[n]; return "Count by \(p.cols)s, once for each of the \(p.rows) rows." }, plain: plain),
                picture: ["at": Double(n + 1)], onMiss: ["ring": 1], hint2: ["spot": 1])
        }
        let sumPlain = "Add the two parts."
        let sum = LessonStep(StepWords(say: P.say(3, down: true), hint: sumPlain, action: "Check"),
            answer: S3.typedKept("s", want: { _ in P.tot }, slips: { k in P.sumSlips(down: Parts.down(k)) },
                                 hint: { k in let p = P.parts(down: Parts.down(k)); return "Add the two parts: \(p[0].area) + \(p[1].area)." }, plain: sumPlain),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.say(4, down: true), hint: "", action: "Next problem"), picture: ["at": 4])
        return [cut, part(0, "a"), part(1, "b"), sum, done]
    }
}

// MARK: - Perimeter

/// Perimeter (the web's g3-perim; 3.MD.D.8). A centimetre is 3 squares (2 for a big shape), the shape drawn true size with
/// the web's labels: two sides of a rectangle, one side of a square, all three of a triangle. Trace around the edge: from the
/// top left corner the point snaps to each cm tick and turns the corners; each side lights as it's walked and joins the
/// readout's sum ("7 + 4"), and a side without a label gets one ("7 cm, like the top"). A rectangle or triangle writes
/// `7 + 4 = [11]` after two sides, then walks the rest; then `7 + 4 + 7 + 4 = [22] cm`.
///
/// "kind" 0 rectangle, 1 square, 2 triangle; "a", "b", "c". "at": 0 walk two sides, 1 write them, 2 walk the rest, 3 write
/// all, 4 done. Boxes: "t" the cm walked when let go at the step's end; "two", "P".
public enum Perim3 {
    public static func numbers(kind: Int, a: Int, b: Int = 0, c: Int = 0) -> Numbers { ["kind": Double(kind), "a": Double(a), "b": Double(b), "c": Double(c)] }
    public struct Parts: Sendable {
        public let kind: Int, a: Int, b: Int, c: Int
        public init(_ x: Numbers) {
            kind = max(0, min(2, S3.int(x, "kind"))); a = max(2, min(15, S3.int(x, "a", 7)))
            b = kind == 1 ? a : max(2, min(12, S3.int(x, "b", 4))); c = kind == 2 ? max(2, min(12, S3.int(x, "c", 5))) : 0
        }
        /// Its sides, from the top (a triangle: its bottom, then up the right).
        public var S: [Int] { kind == 2 ? [a, b, c] : [a, b, a, b] }
        public var P: Int { S.reduce(0, +) }
        /// The cm walked once each side is done.
        public var cum: [Int] { var o = [0]; for s in S { o.append(o[o.count - 1] + s) }; return o }
        public var given: [Bool] { kind == 0 ? [true, true, false, false] : kind == 1 ? [true, false, false, false] : [true, true, true] }
        public func label(_ k: Int) -> String { given[k] ? "\(S[k]) cm" : "\(S[k]) cm, like the \(kind == 0 ? ["top", "right"][max(0, k - 2)] : "top")" }
        /// Squares to a centimetre: 3, or 2 for a big shape.
        public var cell: Int {
            if kind == 2 { return a <= 8 && max(b, c) <= 7 ? 3 : 2 }
            return a <= 8 && b <= 6 ? 3 : 2
        }
        /// The steps' "at" codes.
        public var stages: [Int] { kind == 1 ? [2, 3, 4] : [0, 1, 2, 3, 4] }
        public var note: String { "1 cm is \(cell) squares\(cell < 3 ? " here" : "")." }
        public func say(_ at: Int) -> String {
            switch at {
            case 0: return "Trace around the edge."
            case 1: return "Write \(a) + \(b)."
            case 2: return kind == 1 ? "Trace around the edge." : kind == 0 ? "Trace the other two sides." : "Trace the last side."
            case 3: return "Write the distance all the way around."
            default: return "All the way around: every side counts once."
            }
        }
        public var twoSlips: [(Int, String)] {
            [(a * b, kind == 0 ? "Perimeter adds up lengths. \(a) × \(b) would be the squares inside." : "Perimeter adds up the lengths of the sides.")]
        }
        public var twoHint: String { kind == 0 ? "Add the long side and the short side." : "Start with the bottom and the right side." }
        public var slips: [(Int, String)] {
            switch kind {
            case 0: return [(a + b, "A rectangle has 4 sides. The two sides without labels are \(a) cm and \(b) cm too."),
                            (a * b, "\(a * b) counts squares inside. Perimeter walks around the edge: add all 4 sides."),
                            (2 * a + b, "That's only 3 sides. Add the last \(b) cm side too."), (a + 2 * b, "That's only 3 sides. Add the last \(a) cm side too.")]
            case 1: return [(a, "That's one side. Walk all the way around: 4 sides of \(a) cm."), (2 * a, "That's two sides. A square has 4 sides of \(a) cm."),
                            (a * a, "\(a) × \(a) counts squares inside. Perimeter adds all 4 sides.")]
            default: return [(a + b, "A triangle has 3 sides. Add the \(c) cm side too.")]
            }
        }
        public var hint: String {
            kind == 0 ? "Two sides make \(a + b). The other two sides are the same, so add \(a + b) again." : kind == 1 ? "Count by \(a)s, once for each side." : "Add the third side, \(c) cm."
        }
    }

    /// The web's: problems 0–2 rectangles 3–9 by 2–6; then rectangle, rectangle, square or triangle: rectangles 3–15 by 2–10,
    /// squares 2–12, triangles 5–14 with sides 4–12, not too flat.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let kind = i < 3 ? 0 : S3.pick([0, 0, 1, 2], &rng)
        if kind == 0 {
            var a = 0, b = 0
            repeat { a = S3.r(3, i < 3 ? 9 : 15, &rng); b = S3.r(2, i < 3 ? 6 : 10, &rng) } while a == b
            return numbers(kind: 0, a: max(a, b), b: min(a, b))
        }
        if kind == 1 { return numbers(kind: 1, a: S3.r(2, 12, &rng)) }
        while true {
            let a = S3.r(5, 14, &rng), b = S3.r(4, 12, &rng), c = S3.r(4, 12, &rng)
            if b + c - a >= 3 && a + c - b >= 3 && a + b - c >= 3 && abs(b - c) < a { return numbers(kind: 2, a: a, b: b, c: c) }
        }
    }

    public static let spec = LessonSpec(id: "g3-perim", title: "Perimeter", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("How far around?")] },
        idea: { _ in "All the way around: every side counts once." },
        depends: ["g2-measure", "g2-regroup"],
        check: [CheckItem(3, when: { Parts($0).kind == 0 }), CheckItem(3, when: { Parts($0).kind == 1 }),
                CheckItem(3, when: { Parts($0).kind == 2 }), CheckItem(3, when: { Parts($0).kind == 0 })]) { x in
        let P = Parts(x)
        var out: [LessonStep] = []
        let walkHint = "Drag the point along the edge, round the corners."
        for st in P.stages {
            let say = st == P.stages[0] ? P.say(st) + " " + P.note : P.say(st)
            switch st {
            case 0, 2:
                let end = st == 0 ? P.S[0] + P.S[1] : P.P
                out.append(LessonStep(StepWords(say: say, hint: walkHint, action: "Check"),
                    answer: S3.hand("t", end, hint: walkHint, explain: "\(end) cm walked.", said: { _ in .soft("Keep going round the edge.") }),
                    picture: ["at": Double(st)], onMiss: ["ring": 1], hint2: ["spot": 1]))
            case 1:
                out.append(LessonStep(StepWords(say: say, hint: P.twoHint, action: "Check"),
                    answer: G3.typed("two", P.a + P.b, P.twoSlips, hint: P.twoHint, explain: "\(P.a) + \(P.b) = \(P.a + P.b)."),
                    picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
            case 3:
                out.append(LessonStep(StepWords(say: say, hint: P.hint, action: "Check"),
                    answer: G3.typed("P", P.P, P.slips, hint: P.hint, explain: "\(P.P) cm all the way around."),
                    picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
            default:
                out.append(LessonStep(StepWords(say: say, hint: "", action: "Next problem"), picture: ["at": 4]))
            }
        }
        return out
    }
}

// MARK: - Same perimeter, different area

/// Same perimeter, different area (g3-perimarea, new; 3.MD.D.8). One square is one unit: the fence is counted along the
/// squares' edges (a tick on each line) and the area in tiles; the readout beside it shows both ("fence 16 · area 15").
/// A missing side: "The fence is 24 m. One side is 8 m." Drag the other side; write `8 + [4] + 8 + 4 = 24`. Same fence:
/// drag the corner along the fence's slant (snapping to whole squares); write `5 × 3 = [15]`; every garden this fence
/// makes is listed and the one made ringed. Same tiles: drag the corner (the tiles regroup into rectangles with sides of 2
/// or more); write `3 + 4 + 3 + 4 = [14]`.
///
/// "kind" 0 missing side ("P", "l"), 1 same fence ("P", "p", "q", start "sp" "sq"), 2 same tiles ("A", "p", "q", start).
/// "at": 0 drag, 1 write, 2 done. Boxes: "d" the side let go at (kind 0), or 100 × p + q the corner let go at; "w".
public enum PerimArea3 {
    public static func missing(P: Int, l: Int) -> Numbers { ["kind": 0, "P": Double(P), "l": Double(l)] }
    public static func fence(P: Int, q: Int, start: (Int, Int)) -> Numbers {
        ["kind": 1, "P": Double(P), "p": Double(P / 2 - q), "q": Double(q), "sp": Double(start.0), "sq": Double(start.1)]
    }
    public static func tiles(A: Int, p: Int, q: Int, start: (Int, Int)) -> Numbers {
        ["kind": 2, "A": Double(A), "p": Double(p), "q": Double(q), "sp": Double(start.0), "sq": Double(start.1)]
    }
    public struct Parts: Sendable {
        public let kind: Int, P: Int, p: Int, q: Int, start: (Int, Int)
        public init(_ x: Numbers) {
            kind = max(0, min(2, S3.int(x, "kind")))
            if kind == 0 {
                let P0 = max(8, min(24, S3.int(x, "P", 24) / 2 * 2)), l0 = max(P0 / 4, min(P0 / 2 - 1, S3.int(x, "l", 8)))
                P = P0; p = l0; q = P0 / 2 - l0; start = (l0, 1)
            } else if kind == 1 {
                let P0 = max(8, min(24, S3.int(x, "P", 16) / 2 * 2)), q0 = max(1, min(P0 / 4, S3.int(x, "q", 3)))
                P = P0; p = P0 / 2 - q0; q = q0; start = (S3.int(x, "sp", P0 / 2 - 1), S3.int(x, "sq", 1))
            } else {
                let A0 = S3.int(x, "A", 12), p0 = max(2, S3.int(x, "p", 4)), q0 = max(2, S3.int(x, "q", 3))
                p = p0 * q0 == A0 ? p0 : A0 / 2; q = p0 * q0 == A0 ? q0 : 2; P = 2 * (p + q); start = (S3.int(x, "sp", A0 / 2), S3.int(x, "sq", 2))
            }
        }
        public var s: Int { P / 2 }
        public var A: Int { p * q }
        /// Where the corner may go (columns, rows): on the fence's slant, or where the tiles make a rectangle.
        public var spots: [(Int, Int)] {
            if kind == 1 { return (0..<(s / 2)).map { (s - 1 - $0, $0 + 1) } }
            var out: [(Int, Int)] = []
            var k = 2
            while k * k <= A { if A % k == 0 { out.append((A / k, k)) }; k += 1 }
            return out
        }
        /// The tallest the side may be dragged (kind 0).
        public var maxRows: Int { min(s - 1, q + 2) }
        public var um: String { kind == 2 ? "" : " m" }
        public var story: String {
            kind == 0 ? "The fence is \(P) m. One side is \(p) m." : kind == 1 ? "Make a garden of \(A) square m with a \(P) m fence." : "Make \(A) tiles into a rectangle with a fence of \(P)."
        }
        public func say(_ at: Int) -> String {
            switch at {
            case 0: return story + (kind == 0 ? " Drag the other side." : " Drag the corner.")
            case 1: return kind == 0 ? "Write the other side." : kind == 1 ? "Write \(p) × \(q)." : "Write \(p) + \(q) + \(p) + \(q)."
            default: return kind == 0 ? "Opposite sides match, so half the fence is one long and one short side." : kind == 1 ? "Same fence, different gardens." : "Same tiles, different fences."
            }
        }
        /// Let go at the corner (cols, rows): the miss.
        public func dragMiss(_ cp: Int, _ cq: Int) -> String {
            kind == 1 ? "That garden is \(cp * cq) square m. It needs \(A)." : "That fence is \(2 * (cp + cq)). It needs \(P)."
        }
        public var want: Int { kind == 0 ? q : kind == 1 ? A : P }
        public var slips: [(Int, String)] {
            switch kind {
            case 0: return [(P - p, "\(P) − \(p) is the other three sides."), (P - 2 * p, "\(P - 2 * p) is both short sides. Each one is \(q)."),
                            (P / 2, "\(P / 2) is one long and one short side.")]
            case 1: return [(P, "\(P) is the fence. The area counts the tiles inside."),
                            (p + q, "\(p) + \(q) is one long and one short side. The area counts the tiles inside.")]
            default: return [(A, "\(A) is the tiles inside. The fence goes around the edge."), (p + q, "That's two sides. Add all 4.")]
            }
        }
        public var hint: String {
            kind == 0 ? "\(p) + \(p) is \(2 * p). The two short sides make the other \(P - 2 * p)." : kind == 1 ? "Count by \(p)s, once for each of the \(q) rows." : "Add all 4 sides."
        }
        public var code: Int { kind == 0 ? q : 100 * p + q }
    }

    /// The design's: problems 0–2 missing sides with fences of 20 or less; then missing side, same fence, same tiles in turn.
    /// P even 12–24. Same fence: the square at most one time in four. Same tiles: A 12, 16, 18, 20 or 24, sides 2 or more,
    /// the target's fence 24 or less, starting as a different pair.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let kind = i < 3 ? 0 : (i - 3) % 3
        if kind == 0 {
            let P = 2 * S3.r(6, i < 3 ? 10 : 12, &rng), s = P / 2
            return missing(P: P, l: S3.r(s / 2 + 1, s - 1, &rng))
        }
        if kind == 1 {
            let P = 2 * S3.r(6, 12, &rng), s = P / 2, qMax = s % 2 == 1 ? (s - 1) / 2 : s / 2 - 1
            let q = s % 2 == 0 && Double.random(in: 0..<1, using: &rng) < 0.25 ? s / 2 : S3.r(1, qMax, &rng)
            return fence(P: P, q: q, start: q == 1 ? (s - s / 2, s / 2) : (s - 1, 1))
        }
        let A = S3.pick([12, 16, 18, 20, 24], &rng)
        var pairs: [(Int, Int)] = []
        var q = 2
        while q * q <= A { if A % q == 0 { pairs.append((A / q, q)) }; q += 1 }
        let ok = pairs.filter { 2 * ($0.0 + $0.1) <= 24 }, t = S3.pick(ok, &rng), st = S3.pick(pairs.filter { $0.0 != t.0 }, &rng)
        return tiles(A: A, p: t.0, q: t.1, start: st)
    }

    public static let spec = LessonSpec(id: "g3-perimarea", title: "Same perimeter, different area", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("Fence and garden")] },
        idea: { _ in "The fence goes around the edge; the area counts the tiles inside." },
        depends: ["g3-perim", "g3-area"],
        check: [CheckItem(3), CheckItem(4), CheckItem(5), CheckItem(6)]) { x in
        let P = Parts(x)
        let dragHint = P.kind == 0 ? "Opposite sides match: two long sides and two short sides." : P.kind == 1 ? "Slide the corner along the dashed line." : "Try each rectangle the tiles make."
        let drag = LessonStep(StepWords(say: P.say(0), hint: dragHint, action: "Check"),
            answer: S3.hand("d", P.code, hint: dragHint, explain: "\(P.p) by \(P.q).", said: { c in
                P.kind == 0 ? .wrong(P.dragMiss(P.p, c)) : .wrong(P.dragMiss(c / 100, c % 100)) }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let write = LessonStep(StepWords(say: P.say(1), hint: P.hint, action: "Check"),
            answer: G3.typed("w", P.want, P.slips, hint: P.hint, explain: P.kind == 0 ? "The other side is \(P.q) m." : P.kind == 1 ? "\(P.p) × \(P.q) = \(P.A)." : "The fence is \(P.P)."),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.say(2), hint: "", action: "Next problem"), picture: ["at": 2])
        return [drag, write, done]
    }
}
