import Foundation

/// 1st grade's chapter 6, Shapes and equal parts (design/grade1.md chapter 6, the preview design/prototype/grade1-ch6.html):
/// one square is one step of a side. Flat shapes have their corners on the paper's crossings; Put shapes together's pieces are
/// whole blocks; Build with solids is Unit cubes (one cube is one block); every half and fourth is a whole number of squares.
/// Every line is spoken (App's Voice); the preview's grey second line is folded into the instruction; no keyboard.
public enum Shapes1 {
    public typealias Pt = (Double, Double)
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { G1.int(v, k, d) }
    static func rnd(_ a: Int, _ b: Int, _ rng: inout SeededRandom) -> Int { Int.random(in: a...b, using: &rng) }
    static func pick<T>(_ a: [T], _ rng: inout SeededRandom) -> T { a[Int.random(in: 0..<a.count, using: &rng)] }
    public static func an(_ s: String) -> String { ShapesK.an(s) }
    public static func cap(_ s: String) -> String { ShapesK.cap(s) }
    public static func pl(_ n: Int, _ one: String, _ many: String) -> String { "\(n) \(n == 1 ? one : many)" }

    // MARK: polygons (the preview's helpers)

    public static func bbox(_ p: [Pt]) -> (x0: Double, y0: Double, x1: Double, y1: Double) {
        (p.map(\.0).min() ?? 0, p.map(\.1).min() ?? 0, p.map(\.0).max() ?? 0, p.map(\.1).max() ?? 0)
    }
    public static func norm(_ p: [Pt]) -> [Pt] { let b = bbox(p); return p.map { ($0.0 - b.x0, $0.1 - b.y0) } }
    public static func shift(_ p: [Pt], _ x: Double, _ y: Double) -> [Pt] { p.map { ($0.0 + x, $0.1 + y) } }
    public static func scale(_ p: [Pt], _ k: Double) -> [Pt] { p.map { ($0.0 * k, $0.1 * k) } }
    public static func area2(_ p: [Pt]) -> Double { p.indices.reduce(0) { s, i in let a = p[i], b = p[(i + 1) % p.count]; return s + a.0 * b.1 - b.0 * a.1 } }
    public static func inside(_ q: Pt, _ p: [Pt]) -> Bool { PutShapes.inside(q, p) }
    public static func segDist(_ q: Pt, _ a: Pt, _ b: Pt) -> Double {
        let dx = b.0 - a.0, dy = b.1 - a.1, l2 = dx * dx + dy * dy
        let u = l2 > 0 ? max(0, min(1, ((q.0 - a.0) * dx + (q.1 - a.1) * dy) / l2)) : 0
        return hypot(q.0 - a.0 - u * dx, q.1 - a.1 - u * dy)
    }
    public static func polyDist(_ q: Pt, _ p: [Pt]) -> Double { p.indices.map { segDist(q, p[$0], p[($0 + 1) % p.count]) }.min() ?? 0 }
    /// A point on a circle (degrees, y down: 270 is the top), and n + 1 of them from a0 to a1.
    public static func arc(_ cx: Double, _ cy: Double, _ r: Double, _ a0: Double, _ a1: Double, _ n: Int) -> [Pt] {
        (0...n).map { i in let a = (a0 + (a1 - a0) * Double(i) / Double(n)) * .pi / 180; return (cx + r * cos(a), cy + r * sin(a)) }
    }
    static func orient(_ a: Pt, _ b: Pt, _ c: Pt) -> Double { (b.0 - a.0) * (c.1 - a.1) - (b.1 - a.1) * (c.0 - a.0) }
    static func meet(_ a: Pt, _ b: Pt, _ c: Pt, _ d: Pt) -> Bool {
        let o1 = orient(a, b, c), o2 = orient(a, b, d), o3 = orient(c, d, a), o4 = orient(c, d, b)
        if ((o1 > 0 && o2 < 0) || (o1 < 0 && o2 > 0)) && ((o3 > 0 && o4 < 0) || (o3 < 0 && o4 > 0)) { return true }
        func on(_ a: Pt, _ b: Pt, _ p: Pt) -> Bool { min(a.0, b.0) <= p.0 && p.0 <= max(a.0, b.0) && min(a.1, b.1) <= p.1 && p.1 <= max(a.1, b.1) }
        return (o1 == 0 && on(a, b, c)) || (o2 == 0 && on(a, b, d)) || (o3 == 0 && on(c, d, a)) || (o4 == 0 && on(c, d, b))
    }
    /// Points inside a polygon every half square, a little in from its sides.
    public static func samples(_ pts: [Pt]) -> [Pt] {
        let b = bbox(pts)
        var out: [Pt] = [], x = b.x0 + 0.25
        while x < b.x1 { var y = b.y0 + 0.25; while y < b.y1 { let q = (x + 0.013, y + 0.017); if inside(q, pts) && polyDist(q, pts) > 0.12 { out.append(q) }; y += 0.5 }; x += 0.5 }
        return out
    }
}

// MARK: - What makes a triangle

/// What makes a triangle (g1-shapes, new; 1.G.1). One shape, its corners on the paper's crossings (10–28 squares across):
/// upright, turned, thin, or a near miss (a gap, a curved side, a side bent in two; for a square, one with sides not the
/// same). Trace each side (it darkens and counts, its corners get dots); tap Yes or No; after a yes, tap corners in the empty
/// patch beside it to draw a different one (only what makes the shape is checked).
///
/// Numbers: `kind` 0 triangle, 1 rectangle, 2 square, 3 hexagon; `variant` 0 upright, 1 turned, 2 thin; `miss` 0 none, 1 gap,
/// 2 curve, 3 bent, 4 long; `side` the side the miss is on; `n` corners at `x<i>`, `y<i>`. "at": 0 trace, 1 pick, 2 draw (a
/// yes only), 3 done. Boxes: "t" 1 every side traced, −1 a drag along nothing; "c" 1 Yes, 0 No; "d" the drawing (WhatShape1.drawn).
public enum WhatShape1 {
    public static let kinds = ["triangle", "rectangle", "square", "hexagon"]
    public static let sides = [3, 4, 4, 6]
    public static let variants = ["upright", "turned", "thin"]
    public static let misses = ["", "gap", "curve", "bent", "long"]
    public static let say: [String: String] = [
        "triangle": "Big, small or turned, 3 straight sides closed make a triangle.",
        "rectangle": "Big, small or turned, 4 straight sides and square corners make a rectangle.",
        "square": "Big, small or turned, 4 same sides and square corners make a square.",
        "hexagon": "Big, small or turned, 6 straight sides closed make a hexagon.",
    ]
    static let why: [String: String] = ["triangle": "straight sides, closed: a triangle", "rectangle": "straight sides, square corners: a rectangle",
                                        "square": "same sides, square corners: a square", "hexagon": "straight sides, closed: a hexagon"]
    public static func numbers(kind: Int, variant: Int = 0, miss: Int = 0, side: Int = 0, pts: [(Int, Int)]) -> Numbers {
        var x: Numbers = ["kind": Double(kind), "variant": Double(variant), "miss": Double(miss), "side": Double(side), "n": Double(pts.count)]
        for (i, p) in pts.enumerated() { x["x\(i)"] = Double(p.0); x["y\(i)"] = Double(p.1) }
        return x
    }

    /// One side of the shape on the paper: from corner a to b, straight, curved (through `ctrl`), or stopping short (at `end`);
    /// `path` 25 points along it.
    public struct Side: Sendable {
        public let a: Int, b: Int, kind: String
        public var ctrl: Shapes1.Pt? = nil, end: Shapes1.Pt? = nil
        public var path: [Shapes1.Pt] = []
    }
    public struct Parts: Sendable {
        public let k: Int, variant: Int, miss: Int, side: Int
        public let given: [Shapes1.Pt]
        /// The shape as drawn: its corners (a bent side's middle one too) and sides, shifted to start at 0, 0.
        public let pts: [Shapes1.Pt]
        public let lines: [Side]
        public let w: Double, h: Double
        public init(_ x: Numbers) {
            k = max(0, min(3, Shapes1.int(x, "kind"))); variant = max(0, min(2, Shapes1.int(x, "variant")))
            miss = max(0, min(4, Shapes1.int(x, "miss"))); side = Shapes1.int(x, "side")
            let n = max(3, Shapes1.int(x, "n", 3))
            given = (0..<n).map { (Double(Shapes1.int(x, "x\($0)")), Double(Shapes1.int(x, "y\($0)"))) }
            var p = given
            let s = Shapes1.area2(p) > 0 ? 1.0 : -1, i = ((side % n) + n) % n
            func out(_ a: Shapes1.Pt, _ b: Shapes1.Pt) -> Shapes1.Pt { let dx = b.0 - a.0, dy = b.1 - a.1, l = max(1e-9, hypot(dx, dy)); return (s * dy / l, -s * dx / l) }
            if miss == 3 {
                let a = p[i], b = p[(i + 1) % n], o = out(a, b)
                p.insert((((a.0 + b.0) / 2 + o.0 * 3.5).rounded(), ((a.1 + b.1) / 2 + o.1 * 3.5).rounded()), at: i + 1)
            }
            let N = p.count
            var L: [Side] = []
            for j in 0..<N {
                let a = p[j], b = p[(j + 1) % N], len = hypot(b.0 - a.0, b.1 - a.1)
                var sd = Side(a: j, b: (j + 1) % N, kind: "line")
                if miss == 2 && j == i { let o = out(a, b); sd = Side(a: j, b: (j + 1) % N, kind: "curve", ctrl: ((a.0 + b.0) / 2 + o.0 * len * 0.55, (a.1 + b.1) / 2 + o.1 * len * 0.55)) }
                if miss == 1 && j == i { let u = (len - 3) / len; sd = Side(a: j, b: (j + 1) % N, kind: "short", end: (a.0 + (b.0 - a.0) * u, a.1 + (b.1 - a.1) * u)) }
                let e = sd.end ?? b
                sd.path = (0...24).map { t in
                    let u = Double(t) / 24
                    if let c = sd.ctrl { return ((1 - u) * (1 - u) * a.0 + 2 * u * (1 - u) * c.0 + u * u * e.0, (1 - u) * (1 - u) * a.1 + 2 * u * (1 - u) * c.1 + u * u * e.1) }
                    return (a.0 + (e.0 - a.0) * u, a.1 + (e.1 - a.1) * u)
                }
                L.append(sd)
            }
            // shifted so everything (a curve's bulge too) starts at 0, 0
            let b = Shapes1.bbox(L.flatMap(\.path))
            func mv(_ q: Shapes1.Pt) -> Shapes1.Pt { (q.0 - b.x0, q.1 - b.y0) }
            pts = p.map(mv)
            lines = L.map { var sd = $0; sd.path = sd.path.map(mv); sd.ctrl = sd.ctrl.map(mv); sd.end = sd.end.map(mv); return sd }
            w = b.x1 - b.x0; h = b.y1 - b.y0
        }
        public var kind: String { WhatShape1.kinds[k] }
        public var need: Int { WhatShape1.sides[k] }
        public var yes: Bool { miss == 0 }
        /// The straight sides it has (a curved one doesn't count).
        public var nSides: Int { lines.filter { $0.kind != "curve" }.count }
        public var traceSay: String { "Is it \(Shapes1.an(kind))? Trace its sides." }
        /// The finding a traced side showed is said with the question (the preview's grey line under it).
        public var pickSay: String { (miss == 2 ? "That side is curved. " : miss == 1 ? "There's a gap. " : "") + "Is it \(Shapes1.an(kind))?" }
        public var drawSay: String { "Draw a different \(kind). Tap the corners. Tap the first one again to close it." }
        public var wrongNo: String {
            switch kind {
            case "triangle": return variant == 2 ? "Long and thin, it still has 3 straight sides." : variant == 1 ? "Turned, it's still a triangle: 3 straight sides, closed." : "Big or small, it's still a triangle: 3 straight sides, closed."
            case "square": return variant == 1 ? "Turned, it's still a square: 4 same sides, square corners." : "It has 4 same sides and square corners."
            case "rectangle": return variant == 1 ? "Turned, it's still a rectangle: 4 sides, square corners." : variant == 2 ? "Long and thin, it still has 4 sides and square corners." : "It has 4 straight sides and square corners."
            default: return variant == 1 ? "Turned, it's still a hexagon: 6 straight sides, closed." : "It has 6 straight sides, closed."
            }
        }
        public var wrongYes: String { [1: "It has a gap, so it isn't closed.", 2: "One side is curved.", 3: "It has \(nSides) sides.", 4: "Its sides aren't all the same."][miss] ?? "" }
        public func picked(_ c: Int) -> String { c == 1 ? wrongYes : wrongNo }
        /// The record: a number, then words.
        public var record: (n: Int?, words: String) {
            if yes { return (need, WhatShape1.why[kind] ?? "") }
            if miss == 3 { return (nSides, "sides: not \(Shapes1.an(kind))") }
            return (nil, ([1: "a gap", 2: "a curved side", 4: "sides not the same"][miss] ?? "") + ": not \(Shapes1.an(kind))")
        }
        public var why: String { WhatShape1.say[kind] ?? "" }
        public func drawMiss(_ code: Int) -> String {
            switch code {
            case -1: return "Those corners are in a line."
            case -2: return "Its sides cross. Try again."
            case -3: return "Its corners aren't square."
            case -4: return "Its sides aren't all the same."
            case -5: return "That's the same one. Make it bigger, smaller or turned."
            default: return code <= -100 ? "That has \(-code - 100) sides. \(Shapes1.cap(Shapes1.an(kind))) has \(need)." : "Tap the first corner again to close it."
            }
        }
    }

    /// A drawn shape checked (corners in squares, closed): 1 right, or the code of what's wrong (Parts.drawMiss).
    public static func drawn(_ P: Parts, _ cs: [Shapes1.Pt]) -> Int {
        var c = cs
        var changed = true
        while changed && c.count > 2 {
            changed = false
            for i in c.indices { let a = c[(i + c.count - 1) % c.count], b = c[(i + 1) % c.count]; if Shapes1.orient(a, c[i], b) == 0 { c.remove(at: i); changed = true; break } }
        }
        let n = c.count
        if n < 3 { return -1 }
        for i in 0..<n { for j in (i + 2)..<max(i + 2, n) where !(i == 0 && j == n - 1) { if Shapes1.meet(c[i], c[(i + 1) % n], c[j], c[(j + 1) % n]) { return -2 } } }
        if n != P.need { return -(100 + n) }
        let right = c.indices.allSatisfy { i in let a = c[(i + n - 1) % n], b = c[(i + 1) % n], p = c[i]; return (a.0 - p.0) * (b.0 - p.0) + (a.1 - p.1) * (b.1 - p.1) == 0 }
        func l2(_ i: Int) -> Double { let a = c[i], b = c[(i + 1) % n]; return (b.0 - a.0) * (b.0 - a.0) + (b.1 - a.1) * (b.1 - a.1) }
        if (P.kind == "square" || P.kind == "rectangle") && !right { return -3 }
        if P.kind == "square" && !c.indices.allSatisfy({ l2($0) == l2(0) }) { return -4 }
        func key(_ p: [Shapes1.Pt]) -> String { Shapes1.norm(p).map { "\(Int($0.0)),\(Int($0.1))" }.sorted().joined(separator: ";") }
        if key(c) == key(P.given) { return -5 }
        return 1
    }

    // the preview's generators
    static func angleOk(_ p: [Shapes1.Pt], _ min: Double) -> Bool {
        let n = p.count
        return p.indices.allSatisfy { i in
            let a = p[(i + n - 1) % n], b = p[(i + 1) % n], u = (a.0 - p[i].0, a.1 - p[i].1), v = (b.0 - p[i].0, b.1 - p[i].1)
            let c = (u.0 * v.0 + u.1 * v.1) / (hypot(u.0, u.1) * hypot(v.0, v.1))
            return acos(Swift.max(-1, Swift.min(1, c))) >= min * .pi / 180
        }
    }
    static func ints(_ p: [Shapes1.Pt]) -> [(Int, Int)] { Shapes1.norm(p).map { (Int($0.0.rounded()), Int($0.1.rounded())) } }
    static func tri(_ variant: Int, _ rng: inout SeededRandom) -> [(Int, Int)] {
        for _ in 0..<500 {
            var p: [Shapes1.Pt]
            if variant == 0 {
                let w = Double(Shapes1.rnd(10, 24, &rng)), h = Double(Shapes1.rnd(8, 20, &rng))
                p = [(0, h), (w, h), (Double(Shapes1.rnd(0, Int(w), &rng)), 0)]
                if w > 2.4 * h || h > 2.4 * w || !angleOk(p, 25) { continue }
            } else if variant == 2 {
                let down = Shapes1.rnd(0, 1, &rng), long = Double(Shapes1.rnd(20, down == 1 ? 26 : 28, &rng)), t = Double(Shapes1.rnd(4, 6, &rng)), a = Double(Shapes1.rnd(0, Int(long), &rng))
                p = down == 1 ? [(0, 0), (0, long), (t, a)] : [(0, t), (long, t), (a, 0)]
            } else {
                p = (0..<3).map { _ in (Double(Shapes1.rnd(0, 24, &rng)), Double(Shapes1.rnd(0, 20, &rng))) }
                if (0..<3).contains(where: { i in let a = p[i], b = p[(i + 1) % 3]; return a.0 == b.0 || a.1 == b.1 || hypot(b.0 - a.0, b.1 - a.1) < 10 }) { continue }
                if !angleOk(p, 25) { continue }
            }
            return ints(p)
        }
        return [(0, 16), (20, 16), (8, 0)]
    }
    static func quad(_ kind: String, _ variant: Int, _ rng: inout SeededRandom) -> [(Int, Int)] {
        for _ in 0..<500 {
            var u: Shapes1.Pt, v: Shapes1.Pt
            if variant != 1 {
                var w: Int, h: Int
                if kind == "square" { w = Shapes1.rnd(10, 22, &rng); h = w }
                else if variant == 2 { w = Shapes1.rnd(22, 28, &rng); h = Shapes1.rnd(5, 7, &rng); if Shapes1.rnd(0, 1, &rng) == 1 { swap(&w, &h) } }
                else { w = Shapes1.rnd(12, 26, &rng); h = Shapes1.rnd(8, 20, &rng); if abs(w - h) < 5 { continue } }
                u = (Double(w), 0); v = (0, Double(h))
            } else {
                let ab = Shapes1.pick([(2, 1), (1, 2), (3, 1), (1, 3), (1, 1), (3, 2), (2, 3)], &rng), k = Shapes1.rnd(2, 9, &rng)
                let m = kind == "square" ? k : Shapes1.rnd(2, 9, &rng)
                if kind != "square" && abs(k - m) < 2 { continue }
                u = (Double(ab.0 * k), Double(ab.1 * k)); v = (Double(-ab.1 * m), Double(ab.0 * m))
                if hypot(u.0, u.1) < 8 || hypot(v.0, v.1) < 8 { continue }
            }
            let p = Shapes1.norm([(0, 0), u, (u.0 + v.0, u.1 + v.1), v]), b = Shapes1.bbox(p)
            if b.x1 > 28 || b.y1 > 26 { continue }
            return ints(p)
        }
        return [(0, 0), (16, 0), (16, 12), (0, 12)]
    }
    static func hex(_ variant: Int, _ rng: inout SeededRandom) -> [(Int, Int)] {
        let q = Double(Shapes1.rnd(4, 7, &rng)), r = Double(Shapes1.rnd(8, 12, &rng)), h = variant == 2 ? 2 * Double(Shapes1.rnd(3, 4, &rng)) : 2 * Double(Shapes1.rnd(6, 10, &rng))
        let p: [Shapes1.Pt] = [(0, h / 2), (q, 0), (q + r, 0), (2 * q + r, h / 2), (q + r, h), (q, h)]
        return ints(variant == 1 ? p.map { ($0.1, $0.0) } : p)
    }
    /// The preview's: triangles most; the first three upright triangles (yes), then turned or thin ones (yes); from the 7th
    /// half are near misses (no).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let kind = i < 3 ? 0 : Shapes1.pick([0, 0, 1, 2, 3], &rng)
        var variant: Int, miss = 0
        if i < 3 { variant = 0 }
        else if i < 6 { variant = Shapes1.pick([1, 2], &rng) }
        else { variant = Shapes1.pick([0, 1, 2], &rng); if Shapes1.rnd(0, 1, &rng) == 1 { miss = Shapes1.pick(kind == 2 ? [1, 2, 3, 4] : [1, 2, 3], &rng) } }
        if kind == 2 && variant == 2 { variant = 1 }
        let pts = kind == 0 ? tri(variant, &rng) : kind == 3 ? hex(variant, &rng) : quad(miss == 4 ? "rectangle" : kinds[kind], variant, &rng)
        return numbers(kind: kind, variant: variant, miss: miss, side: Shapes1.rnd(0, pts.count - 1, &rng), pts: pts)
    }

    public static let spec = LessonSpec(id: "g1-shapes", title: "What makes a triangle", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.text("Is it \(Shapes1.an(Parts(x).kind))?")] },
        idea: { x in Parts(x).why },
        depends: ["gk-draw", "k-shapes"],
        check: [CheckItem(3, when: { let P = Parts($0); return P.kind == "square" && P.variant == 1 }), CheckItem(4, when: { let P = Parts($0); return P.kind == "triangle" && P.variant == 2 }),
                CheckItem(7, when: { Parts($0).miss == 1 }), CheckItem(8, when: { Parts($0).miss == 2 })]) { x in
        let P = Parts(x)
        let traceHint = "Put your finger on a side and drag along it."
        let trace = LessonStep(StepWords(say: P.traceSay, hint: traceHint, action: "Check"),
            answer: TeensK.hand("t", 1, hint: traceHint, explain: P.yes ? "\(P.need) straight sides." : "Look at every side.", said: { _ in "Drag along a side." }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let pickHint = "Count its straight sides. Is it closed?"
        let pick = LessonStep(StepWords(say: P.pickSay, hint: pickHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("c")], expected: ["c": P.yes ? 1 : 0], known: [(["c": P.yes ? 0 : 1], P.picked(P.yes ? 0 : 1))], hint: pickHint,
                               explain: P.yes ? P.why : P.wrongYes, byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let drawHint = "Tap a corner, then the next. Tap the first one again to close it."
        let draw = LessonStep(StepWords(say: P.drawSay, hint: drawHint, action: "Check"),
            answer: TeensK.hand("d", 1, hint: drawHint, explain: P.why, said: { P.drawMiss($0) }),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return P.yes ? [trace, pick, draw, done] : [trace, pick, done]
    }
}

// MARK: - Put shapes together

/// Put shapes together (g1-compose, new; 1.G.2). Shapes in blocks (corners on block crossings; circles 4 blocks across).
/// The new shape's outline dashed, its pieces two blocks past it. Slide each in (it moves a square at a time and snaps in
/// when it's within 3 squares of a free place its shape fits); tap one to turn it a quarter turn. Full, the sides that touch
/// fade and the record writes itself. Two-stage problems: the shape just made glides into the tray as a piece for a bigger one.
///
/// Numbers: `set` 0–5 one stage (CSET), 6–7 two stages (CTWO); `t<j>` the first stage's pieces' quarter turns, `u<j>` the
/// second's. "at": 0 fill, 1 fill again (two stages), then done. Boxes "f", "g": 1 full, −1 stacked, −2 turn it, −3 gaps,
/// −(10 + n) sticking out n squares.
public enum Compose1 {
    public typealias Pt = Shapes1.Pt
    public struct Stage: Sendable {
        public let make: String, outline: [Pt]
        /// Each piece's shape (blocks, from 0, 0; nil: the shape just made), its name, and its place in the outline (blocks).
        public let pieces: [[Pt]?], names: [String], slots: [Pt]
        public let words: String
        public var say: String? = nil
    }
    static let sq: [Pt] = [(0, 0), (2, 0), (2, 2), (0, 2)]
    static let rTrap: [Pt] = [(0, 0), (2, 0), (4, 2), (0, 2)], rTri: [Pt] = [(0, 0), (2, 2), (0, 2)]
    static let trapTop: [Pt] = [(0, 2), (1, 0), (3, 0), (4, 2)], trapBot: [Pt] = [(0, 0), (4, 0), (3, 2), (1, 2)]
    static let hexagon: [Pt] = [(0, 2), (1, 0), (3, 0), (4, 2), (3, 4), (1, 4)]
    static let triL: [Pt] = [(0, 2), (1, 0), (1, 2)], triR: [Pt] = [(0, 0), (1, 2), (0, 2)]
    static let sqT1: [Pt] = [(0, 0), (2, 0), (2, 2)], sqT2: [Pt] = [(0, 0), (2, 2), (0, 2)]
    static let qTL = Shapes1.norm([(2, 2)] + Shapes1.arc(2, 2, 2, 180, 270, 12)), qTR = Shapes1.norm([(0, 2)] + Shapes1.arc(0, 2, 2, 270, 360, 12))
    static let hTop = Shapes1.norm(Shapes1.arc(2, 2, 2, 180, 360, 24)), hBot = Shapes1.norm(Shapes1.arc(2, 0, 2, 0, 180, 24))
    static let circle = Array(Shapes1.arc(2, 2, 2, 0, 360, 48).prefix(48))
    static let quarters = (0..<4).map { turned(qTL, $0) }
    public static let sets: [Stage] = [
        Stage(make: "trapezoid", outline: rTrap, pieces: [sq, rTri], names: ["square", "triangle"], slots: [(0, 0), (2, 0)], words: "A square and a triangle make a trapezoid."),
        Stage(make: "trapezoid", outline: trapTop, pieces: [triL, sq, triR], names: ["triangle", "square", "triangle"], slots: [(0, 0), (1, 0), (3, 0)], words: "2 triangles and a square make a trapezoid."),
        Stage(make: "hexagon", outline: hexagon, pieces: [trapTop, trapBot], names: ["trapezoid", "trapezoid"], slots: [(0, 0), (0, 2)], words: "2 trapezoids make a hexagon."),
        Stage(make: "half circle", outline: hTop, pieces: [qTL, qTR], names: ["quarter circle", "quarter circle"], slots: [(0, 0), (2, 0)], words: "2 quarter circles make a half circle."),
        Stage(make: "circle", outline: circle, pieces: [hTop, hBot], names: ["half circle", "half circle"], slots: [(0, 0), (0, 2)], words: "2 half circles make a circle."),
        Stage(make: "circle", outline: circle, pieces: quarters, names: Array(repeating: "quarter circle", count: 4), slots: [(0, 0), (2, 0), (2, 2), (0, 2)], words: "4 quarter circles make a circle."),
    ]
    public static let twos: [[Stage]] = [
        [Stage(make: "square", outline: sq, pieces: [sqT1, sqT2], names: ["triangle", "triangle"], slots: [(0, 0), (0, 0)], words: "2 triangles make a square."),
         Stage(make: "trapezoid", outline: trapTop, pieces: [nil, triL, triR], names: ["square", "triangle", "triangle"], slots: [(1, 0), (0, 0), (3, 0)], words: "A square and 2 triangles make a trapezoid.", say: "Now use it to make a trapezoid.")],
        [sets[1], Stage(make: "hexagon", outline: hexagon, pieces: [nil, trapBot], names: ["trapezoid", "trapezoid"], slots: [(0, 0), (0, 2)], words: "2 trapezoids make a hexagon.", say: "Now use it to make a hexagon.")],
    ]
    /// A quarter turn clockwise, kept from 0, 0.
    public static func turn(_ p: [Pt]) -> [Pt] { let b = Shapes1.bbox(p); return Shapes1.norm(p.map { (b.y1 - $0.1, $0.0) }) }
    public static func turned(_ p: [Pt], _ k: Int) -> [Pt] { var q = Shapes1.norm(p); for _ in 0..<(((k % 4) + 4) % 4) { q = turn(q) }; return q }
    /// A shape's key, whatever order its corners are in.
    public static func key(_ p: [Pt]) -> String { Shapes1.norm(p).map { "\(Int(($0.0 * 100).rounded())),\(Int(($0.1 * 100).rounded()))" }.sorted().joined(separator: ";") }
    public static func numbers(set: Int, turns: [Int] = [], turns2: [Int] = []) -> Numbers {
        var x: Numbers = ["set": Double(set)]
        for j in 0..<4 { x["t\(j)"] = Double(j < turns.count ? turns[j] : 0); x["u\(j)"] = Double(j < turns2.count ? turns2[j] : 0) }
        return x
    }

    public struct Parts: Sendable {
        public let which: Int, turns: [[Int]]
        public init(_ x: Numbers) {
            which = max(0, min(7, Shapes1.int(x, "set")))
            turns = [(0..<4).map { Shapes1.int(x, "t\($0)") }, (0..<4).map { Shapes1.int(x, "u\($0)") }]
        }
        public var stages: [Stage] { which >= 6 ? Compose1.twos[which - 6] : [Compose1.sets[which]] }
        public var two: Bool { which >= 6 }
        /// Stage i's pieces as they start (squares, from 0, 0): turned as the numbers say; the made piece as it was made.
        public func start(_ i: Int) -> [[Pt]] {
            let S = stages[i]
            return S.pieces.enumerated().map { j, p in Shapes1.scale(p.map { Compose1.turned($0, turns[i][j]) } ?? Shapes1.norm(stages[max(0, i - 1)].outline), 5) }
        }
        /// Stage i's outline (squares, from 0, 0) and the places (squares) its pieces go, with each place's shape key.
        public func outline(_ i: Int) -> [Pt] { Shapes1.scale(stages[i].outline, 5) }
        public func slots(_ i: Int) -> [(key: String, x: Double, y: Double)] {
            let S = stages[i]
            return S.pieces.enumerated().map { j, p in (Compose1.key(Shapes1.scale(p ?? stages[max(0, i - 1)].outline, 5)), S.slots[j].0 * 5, S.slots[j].1 * 5) }
        }
        /// A piece turned as it starts needs a turn to fit any place.
        public func needsTurn(_ i: Int) -> Bool {
            let keys = Set(slots(i).map(\.key))
            return start(i).contains { !keys.contains(Compose1.key($0)) }
        }
        public func fillSay(_ i: Int) -> String {
            let S = stages[i]
            return (i > 0 ? S.say ?? "" : "Slide the pieces in to make \(Shapes1.an(S.make)).") + (needsTurn(i) ? " Tap a piece to turn it." : "")
        }
        public static func letGo(_ code: Int) -> String {
            switch code {
            case -1: return "Pieces can't stack."
            case -2: return "Tap it to turn it."
            case -3: return "Slide it so no gaps are left."
            default: let n = max(1, -code - 10); return "That sticks out \(Shapes1.pl(n, "square", "squares"))."
            }
        }
        public static let why = "Shapes put together make a new shape, and it can build more."
    }

    /// The preview's: the first three 2 pieces, nothing to turn; the next three one piece to turn; the 7th two stages; then
    /// 3–4 pieces or two stages, every piece maybe turned.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 6 {
            let set = Shapes1.pick([0, 2, 3, 4], &rng), S = sets[set]
            var turns = [0, 0, 0, 0]
            if i >= 3 {
                let keys = Set(S.pieces.map { key($0!) })
                for j in MeasureK.shuffled(Array(S.pieces.indices), &rng) {
                    let ks = [1, 2, 3].filter { !keys.contains(key(turned(S.pieces[j]!, $0))) }
                    if !ks.isEmpty { turns[j] = Shapes1.pick(ks, &rng); break }
                }
            }
            return numbers(set: set, turns: turns)
        }
        let p = i == 6 ? Shapes1.pick([6, 7], &rng) : Shapes1.pick([1, 5, 6, 7], &rng)
        return numbers(set: p, turns: (0..<4).map { _ in Shapes1.rnd(0, 3, &rng) }, turns2: [0] + (1..<4).map { _ in Shapes1.rnd(0, 3, &rng) })
    }

    public static let spec = LessonSpec(id: "g1-compose", title: "Put shapes together", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.text("Make \(Shapes1.an(Parts(x).stages.last!.make)).")] },
        idea: { _ in Parts.why },
        depends: ["gk-compose", "g1-shapes"],
        check: [CheckItem(0), CheckItem(3), CheckItem(6, when: { Parts($0).two }), CheckItem(8)]) { x in
        let P = Parts(x)
        let hint = "Slide each piece onto its place. Tap a piece to turn it."
        var steps: [LessonStep] = []
        for i in P.stages.indices {
            let box = i == 0 ? "f" : "g"
            steps.append(LessonStep(StepWords(say: P.fillSay(i), hint: hint, action: "Check"),
                answer: TeensK.hand(box, 1, hint: hint, explain: P.stages[i].words, said: Parts.letGo),
                picture: ["at": Double(i)], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        steps.append(LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": Double(P.stages.count)]))
        return steps
    }
}

// MARK: - Build with solids

/// Build with solids (g1-build, new; 1.G.2 solids; 3D). Unit cubes as they are: one cube is one block, every solid is built in
/// blocks (a box 2 × 1 × 1, a cylinder and a cone 1 block across, 1 or 2 tall). It builds a shape, never counts its cubes. Flat
/// first: the new solid's footprint dashed, its pieces beside it, each named; the paper tilts by itself and the new solid stands
/// over its outline as a dashed ghost. Drag each piece onto the outline or onto a piece placed (block by block); tap one to turn
/// it. Full, the new solid's name writes itself. Two stages: the box just made stays as a piece of a bigger box.
///
/// Numbers: `set` 0–5 one stage, 6 two stages; `t<j>` / `u<j>` the pieces' poses (a box 0 along, 1 across, 2 standing; a
/// cylinder 0 standing, 1 lying). "at": 0 build, 1 build again (two stages), then done. Boxes "p", "q": 1 built, −1 sticks
/// out, −2 on a point, −3 rolls off, −(10 + kind) goes elsewhere (Parts.goes).
public enum Build1 {
    public struct Piece: Sendable { public let kind: String; public var h = 1 }
    /// A part of the new solid: what goes there, its back-left-bottom block, its size in blocks.
    public struct Ghost: Sendable { public let kind: String; public let at: [Int]; public let d: [Int] }
    public struct Stage: Sendable {
        public let make: String, pieces: [Piece], ghost: [Ghost], words: String
        public var say: String? = nil
    }
    public static let kinds = ["cube", "box", "made", "cylinder", "cone"]
    public static let sets: [Stage] = [
        Stage(make: "box", pieces: [Piece(kind: "cube"), Piece(kind: "cube")], ghost: [Ghost(kind: "box", at: [0, 0, 0], d: [2, 1, 1])], words: "2 cubes make a box."),
        Stage(make: "bigger box", pieces: [Piece(kind: "box"), Piece(kind: "box")], ghost: [Ghost(kind: "box", at: [0, 0, 0], d: [2, 2, 1])], words: "2 boxes make a bigger box."),
        Stage(make: "big flat box", pieces: Array(repeating: Piece(kind: "cube"), count: 4), ghost: [Ghost(kind: "box", at: [0, 0, 0], d: [2, 2, 1])], words: "4 cubes make a big flat box."),
        Stage(make: "tower", pieces: [Piece(kind: "cylinder", h: 2), Piece(kind: "cone")], ghost: [Ghost(kind: "cylinder", at: [0, 0, 0], d: [1, 1, 2]), Ghost(kind: "cone", at: [0, 0, 2], d: [1, 1, 1])], words: "A cylinder and a cone make a tower."),
        Stage(make: "rocket", pieces: [Piece(kind: "box"), Piece(kind: "cylinder", h: 1), Piece(kind: "cone")],
              ghost: [Ghost(kind: "box", at: [0, 0, 0], d: [1, 1, 2]), Ghost(kind: "cylinder", at: [0, 0, 2], d: [1, 1, 1]), Ghost(kind: "cone", at: [0, 0, 3], d: [1, 1, 1])], words: "A box, a cylinder and a cone make a rocket."),
        Stage(make: "big cube", pieces: Array(repeating: Piece(kind: "cube"), count: 8), ghost: [Ghost(kind: "box", at: [0, 0, 0], d: [2, 2, 2])], words: "8 cubes make a big cube."),
    ]
    public static let two: [Stage] = [sets[0], Stage(make: "bigger box", pieces: [Piece(kind: "made"), Piece(kind: "box")], ghost: [Ghost(kind: "box", at: [0, 0, 0], d: [2, 2, 1])], words: "2 boxes make a bigger box.", say: "Now use it to build a bigger box.")]
    /// What a block of the new solid holds: b a box's, c a cylinder's, n a cone's.
    public static func label(_ kind: String) -> String { kind == "cylinder" ? "c" : kind == "cone" ? "n" : "b" }
    public static func name(_ kind: String) -> String { kind == "made" ? "box" : kind }
    /// A piece's size in blocks at its pose.
    public static func dims(_ p: Piece, pose: Int) -> [Int] {
        switch p.kind {
        case "box", "made": return pose == 1 ? [1, 2, 1] : pose == 2 ? [1, 1, 2] : [2, 1, 1]
        case "cylinder": return pose == 1 ? [p.h, 1, 1] : [1, 1, p.h]
        default: return [1, 1, 1]
        }
    }
    public static func numbers(set: Int, poses: [Int] = [], poses2: [Int] = []) -> Numbers {
        var x: Numbers = ["set": Double(set)]
        for j in 0..<8 { x["t\(j)"] = Double(j < poses.count ? poses[j] : 0) }
        for j in 0..<2 { x["u\(j)"] = Double(j < poses2.count ? poses2[j] : 0) }
        return x
    }
    public struct Vox: Hashable, Sendable { public let i: Int, j: Int, k: Int }

    public struct Parts: Sendable {
        public let which: Int, poses: [[Int]]
        public init(_ x: Numbers) {
            which = max(0, min(6, Shapes1.int(x, "set")))
            poses = [(0..<8).map { Shapes1.int(x, "t\($0)") }, (0..<2).map { Shapes1.int(x, "u\($0)") }]
        }
        public var stages: [Stage] { which == 6 ? Build1.two : [Build1.sets[which]] }
        public var twoStage: Bool { which == 6 }
        /// The new solid's blocks, each with what it holds.
        public func ghost(_ i: Int) -> [Vox: String] {
            var out: [Vox: String] = [:]
            for g in stages[i].ghost { for a in 0..<g.d[0] { for b in 0..<g.d[1] { for c in 0..<g.d[2] { out[Vox(i: g.at[0] + a, j: g.at[1] + b, k: g.at[2] + c)] = Build1.label(g.kind) } } } }
            return out
        }
        public func size(_ i: Int) -> [Int] { let g = ghost(i).keys; return [(g.map(\.i).max() ?? 0) + 1, (g.map(\.j).max() ?? 0) + 1, (g.map(\.k).max() ?? 0) + 1] }
        public func vox(_ p: Piece, pose: Int, at i: Int, _ j: Int, _ k: Int) -> [Vox] {
            let d = Build1.dims(p, pose: pose)
            var out: [Vox] = []
            for a in 0..<d[0] { for b in 0..<d[1] { for c in 0..<d[2] { out.append(Vox(i: i + a, j: j + b, k: k + c)) } } }
            return out
        }
        /// A piece can go in the way it's turned now (a box too long or too tall for every box place can't; a lying cylinder can't).
        public func fitsAsIs(_ i: Int, _ p: Piece, pose: Int) -> Bool {
            if p.kind == "cylinder" { return pose == 0 }
            if p.kind != "box" { return true }
            let d = Build1.dims(p, pose: pose)
            return stages[i].ghost.contains { g in g.kind == "box" && (0..<3).allSatisfy { d[$0] <= g.d[$0] } }
        }
        public func needsTurn(_ i: Int) -> Bool { stages[i].pieces.enumerated().contains { j, p in !fitsAsIs(i, p, pose: poses[i][j]) } }
        public func buildSay(_ i: Int) -> String {
            let S = stages[i]
            return (i > 0 ? S.say ?? "" : "Build \(Shapes1.an(S.make)). Drag each piece on.") + (needsTurn(i) ? " Tap a piece to turn it." : "")
        }
        /// Where a piece of this kind goes, said when it's put where another kind goes: −(10 + its kind).
        public func goes(_ i: Int, _ kind: String) -> String {
            let G = stages[i].ghost
            if let mine = G.first(where: { Build1.label($0.kind) == Build1.label(kind) }), let below = G.first(where: { $0.at[2] + $0.d[2] == mine.at[2] }) {
                return "The \(Build1.name(kind)) goes on the \(Build1.name(below.kind))."
            }
            return "The \(Build1.name(kind)) goes at the bottom."
        }
        public func said(_ i: Int) -> @Sendable (Int) -> String {
            let me = self
            return { code in
                switch code {
                case -2: return "Nothing stands on a point."
                case -3: return "It rolls off. Put a flat face down."
                case ...(-10): return me.goes(i, Build1.kinds[max(0, min(4, -code - 10))])
                default: return "That sticks out past the shape."
                }
            }
        }
        public static let why = "Solids put together make a new solid, and it can build more."
    }

    /// The preview's: the first three 2 pieces; the next three the rocket (one piece to turn); the 7th two stages; then 4
    /// cubes, 8, or two stages.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i < 3 { return numbers(set: Shapes1.pick([0, 1, 3], &rng)) }
        if i < 6 { var t = [0, 0, 0]; let j = Shapes1.rnd(0, 1, &rng); t[j] = j == 0 ? Shapes1.pick([0, 1], &rng) : 1; return numbers(set: 4, poses: t) }
        if i == 6 { return numbers(set: 6, poses2: [0, Shapes1.pick([0, 1], &rng)]) }
        let k = Shapes1.pick([2, 5, 6], &rng)
        return k == 6 ? numbers(set: 6, poses2: [0, Shapes1.pick([0, 1], &rng)]) : numbers(set: k)
    }

    public static let spec = LessonSpec(id: "g1-build", title: "Build with solids", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in [.text("Build \(Shapes1.an(Parts(x).stages.last!.make)).")] },
        idea: { _ in Parts.why },
        depends: ["g1-compose", "k-solids"],
        check: [CheckItem(0), CheckItem(3), CheckItem(6, when: { Parts($0).twoStage }), CheckItem(7)]) { x in
        let P = Parts(x)
        let hint = "Drag a piece onto the dashed shape. Tap a piece to turn it."
        var steps: [LessonStep] = []
        for i in P.stages.indices {
            steps.append(LessonStep(StepWords(say: P.buildSay(i), hint: hint, action: "Check"),
                answer: TeensK.hand(i == 0 ? "p" : "q", 1, hint: hint, explain: P.stages[i].words, said: P.said(i)),
                picture: ["at": Double(i)], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        steps.append(LessonStep(StepWords(say: Parts.why, hint: "", action: "Next problem"), picture: ["at": Double(P.stages.count)]))
        return steps
    }
}

// MARK: - Halves and fourths

/// Halves and fourths (the web's g1-halves; 1.G.3; cutting, "quarters" and "more parts are smaller" folded in). The shape big:
/// a rectangle 40 × 24, a square 30 × 30, or a circle 30 across; every half and fourth is a whole number of squares. Cut with the
/// ruler, edge to edge (straight down or across, corner to corner on the square, through the middle of the circle): the parts'
/// widths read out under them. Not equal: measured, and the cut goes. Then tap the parts' name, then shade. From the 7th problem
/// every third shows the shape twice (30 squares wide), cut in halves and in fourths: tap a bigger piece.
///
/// Numbers: `compare` 0/1; `shape` 0 rectangle, 1 square, 2 circle; `parts` 2 or 4; `cut` the way asked; `shaded`; a compare's
/// `left` (0: the halves on the left), `hcut`, `fcut`. "at": 0 cut, 1 name, 2 shade, 3 done (a compare: 0 pick, 1 done).
/// Boxes: "k" 1 cut, else a miss code (Parts.cutMiss); "n" the name tapped (0 wholes, 1 halves, 2 fourths); "s" the parts
/// shaded; "b" 1 a half tapped, −1 a fourth.
public enum Halves1 {
    public static let shapes = ["rectangle", "square", "circle"]
    public static func cutsAllowed(_ s: Int) -> [Int] { s == 2 ? [0] : s == 1 ? [0, 1, 2] : [0, 1] }
    public static func numbers(shape: Int, parts: Int, cut: Int = 0, shaded: Int = 1) -> Numbers {
        ["shape": Double(shape), "parts": Double(parts), "cut": Double(cut), "shaded": Double(shaded)]
    }
    public static func compare(shape: Int, left: Int = 0, hcut: Int = 0, fcut: Int = 0) -> Numbers {
        ["compare": 1, "shape": Double(shape), "left": Double(left), "hcut": Double(hcut), "fcut": Double(fcut)]
    }
    /// A cut as a number: 100 + n straight down n squares from the left, 200 + n across n squares from the top, 300 corner to
    /// corner from the top left, 301 from the top right.
    public static func down(_ n: Int) -> Int { 100 + n }
    public static func across(_ n: Int) -> Int { 200 + n }
    public static let d0 = 300, d1 = 301

    public struct Geom: Sendable {
        public let kind: Int, x0: Double, W: Double, H: Double
        public var cx: Double { x0 + W / 2 }
        public var cy: Double { H / 2 }
        public var r: Double { W / 2 }
    }
    public static func geom(_ shape: Int, small: Bool = false, x0: Double = 0) -> Geom {
        shape == 2 || shape == 1 ? Geom(kind: shape, x0: x0, W: 30, H: 30) : small ? Geom(kind: 0, x0: x0, W: 30, H: 20) : Geom(kind: 0, x0: x0, W: 40, H: 24)
    }
    /// The cut patterns that make `parts` equal parts.
    public static func patterns(_ g: Geom, _ parts: Int) -> [[Int]] {
        let W = Int(g.W), H = Int(g.H)
        if g.kind == 2 { return parts == 2 ? [[down(15)], [across(15)]] : [[down(15), across(15)]] }
        var L: [[Int]] = []
        if parts == 2 { L += [[down(W / 2)], [across(H / 2)]]; if g.kind == 1 { L += [[d0], [d1]] } }
        else {
            L.append([down(W / 2), across(H / 2)])
            if W % 4 == 0 { L.append([down(W / 4), down(W / 2), down(3 * W / 4)]) }
            if H % 4 == 0 { L.append([across(H / 4), across(H / 2), across(3 * H / 4)]) }
            if g.kind == 1 { L.append([d0, d1]) }
        }
        return L
    }
    /// The parts a set of cuts makes (polygons in squares).
    public static func parts(_ g: Geom, _ cuts: [Int]) -> [[Shapes1.Pt]] {
        let x0 = g.x0, W = g.W, H = g.H
        let TL = (x0, 0.0), TR = (x0 + W, 0.0), BR = (x0 + W, H), BL = (x0, H), O = (x0 + W / 2, H / 2)
        if g.kind == 2 {
            let v = cuts.contains(down(15)), h = cuts.contains(across(15))
            func wedge(_ a0: Double, _ a1: Double) -> [Shapes1.Pt] { [(g.cx, g.cy)] + Shapes1.arc(g.cx, g.cy, g.r, a0, a1, Int(((a1 - a0) / 5).rounded())) }
            if v && h { return [wedge(180, 270), wedge(270, 360), wedge(0, 90), wedge(90, 180)] }
            if v { return [wedge(90, 270), wedge(270, 450)] }
            if h { return [wedge(180, 360), wedge(0, 180)] }
            return [Array(Shapes1.arc(g.cx, g.cy, g.r, 0, 360, 72).prefix(72))]
        }
        if cuts.contains(d0) && cuts.contains(d1) { return [[TL, TR, O], [TR, BR, O], [BR, BL, O], [BL, TL, O]] }
        if cuts.contains(d0) { return [[TL, TR, BR], [TL, BR, BL]] }
        if cuts.contains(d1) { return [[TL, TR, BL], [TR, BR, BL]] }
        let xs = [0.0] + cuts.filter { $0 / 100 == 1 }.map { Double($0 % 100) }.sorted() + [W]
        let ys = [0.0] + cuts.filter { $0 / 100 == 2 }.map { Double($0 % 100) }.sorted() + [H]
        var r: [[Shapes1.Pt]] = []
        for b in 0..<(ys.count - 1) { for a in 0..<(xs.count - 1) { r.append([(x0 + xs[a], ys[b]), (x0 + xs[a + 1], ys[b]), (x0 + xs[a + 1], ys[b + 1]), (x0 + xs[a], ys[b + 1])]) } }
        return r
    }
    /// A cut's line, ends on the outline.
    public static func line(_ g: Geom, _ c: Int) -> (Shapes1.Pt, Shapes1.Pt) {
        let x0 = g.x0, W = g.W, H = g.H
        if c == d0 { return ((x0, 0), (x0 + W, H)) }
        if c == d1 { return ((x0 + W, 0), (x0, H)) }
        let at = Double(c % 100), vertical = c / 100 == 1
        if g.kind == 2 {
            let half = sqrt(max(0, g.r * g.r - (at - 15) * (at - 15)))
            return vertical ? ((x0 + at, g.cy - half), (x0 + at, g.cy + half)) : ((g.cx - half, at), (g.cx + half, at))
        }
        return vertical ? ((x0 + at, 0), (x0 + at, H)) : ((x0, at), (x0 + W, at))
    }
    /// The widths (or heights) the cuts down (across) make.
    public static func sizes(_ cuts: [Int], across: Bool, full: Double) -> [Int] {
        let xs = [0] + cuts.filter { $0 / 100 == (across ? 2 : 1) }.map { $0 % 100 }.sorted() + [Int(full)]
        return (1..<xs.count).map { xs[$0] - xs[$0 - 1] }
    }

    public struct Parts: Sendable {
        public let compare: Bool, shape: Int, parts: Int, cut: Int, shaded: Int, left: Int, hcut: Int, fcut: Int
        public init(_ x: Numbers) {
            compare = Shapes1.int(x, "compare") == 1; shape = max(0, min(2, Shapes1.int(x, "shape")))
            parts = Shapes1.int(x, "parts", 2) == 4 ? 4 : 2; cut = max(0, min(2, Shapes1.int(x, "cut")))
            shaded = max(1, min(parts - 1, Shapes1.int(x, "shaded", 1)))
            left = Shapes1.int(x, "left"); hcut = Shapes1.int(x, "hcut"); fcut = Shapes1.int(x, "fcut")
        }
        public var g: Geom { Halves1.geom(shape) }
        public var name: String { parts == 2 ? "halves" : "fourths" }
        public var one: String { parts == 2 ? "half" : "fourth" }
        public var shapeName: String { Halves1.shapes[shape] }
        public var how: String {
            if shape == 2 { return "through the middle" }
            return parts == 2 ? ["straight down", "straight across", "corner to corner"][cut] : ["down and across", "in strips", "corner to corner"][cut]
        }
        public var cutSay: String { "Cut it into \(parts) equal parts, \(how)." }
        public var nameSay: String { "\(parts) equal parts. What are they called?" }
        /// "Fourths are also called quarters." (the preview's grey line once they're named) is said with the shading.
        public var shadeSay: String { (parts == 4 ? "Fourths are also called quarters. " : "") + "Shade \(shaded) \(shaded == 1 ? one : name)." }
        public static let names = ["Wholes", "Halves", "Fourths"]
        public var right: Int { parts == 2 ? 1 : 2 }
        public func picked(_ j: Int) -> String {
            j == 0 ? "The whole is the full \(shapeName). Each part is a smaller piece of it." : parts == 2 ? "Fourths means 4 equal parts. Here there are 2." : "Halves means 2 equal parts. Here there are 4."
        }
        /// A cut that doesn't make equal parts (or isn't a cut), as its code says.
        public func cutMiss(_ code: Int) -> String {
            switch code {
            case -1: return shape == 1 ? "Cut straight down, across or corner to corner." : "Cut straight down or across."
            case -2: return "Cut from edge to edge."
            case -3: return "Not equal. Cut through the middle."
            case -4: return "Not equal: the parts aren't the same size."
            case ...(-1000): let c = -code - 1000; return "Not equal: \(c / 100) squares and \(c % 100) squares."
            case ...(-50): return "That makes \(-code - 50) parts. Make \(parts)."
            default: return "Cut from edge to edge."
            }
        }
        public var why: String { parts == 4 ? "4 equal parts are fourths, also called quarters." : "2 equal parts are halves, each the same size." }
        public var record: [(Int, String)] { [(shaded, "\(shaded == 1 ? one : name) shaded"), (parts, "\(name) make the whole")] }
        public static let compareWhy = "The more equal parts, the smaller each part."
    }

    /// What a cut does to the cuts made so far: the new cuts (still part way, or done), or the miss code.
    public static func cut(_ P: Parts, _ made: [Int], _ c: Int) -> (cuts: [Int], done: Bool)? {
        let pats = patterns(P.g, P.parts), next = made + [c]
        guard pats.contains(where: { p in next.allSatisfy(p.contains) }) else { return nil }
        return (next, pats.contains { $0.count == next.count && next.allSatisfy($0.contains) })
    }
    public static func missCode(_ P: Parts, _ made: [Int], _ c: Int) -> Int {
        let g = P.g, next = made + [c]
        if g.kind == 2 { return -3 }
        if next.contains(where: { $0 >= 300 }) { return -4 }
        let cw = sizes(next, across: false, full: g.W), rh = sizes(next, across: true, full: g.H)
        func two(_ l: [Int]) -> (Int, Int)? { guard let a = l.first, let b = l.first(where: { $0 != a }) else { return nil }; return (a, b) }
        if let d = two(cw) ?? two(rh) { return -(1000 + 100 * d.0 + d.1) }
        return -(50 + cw.count * rh.count)
    }

    /// The web's: shape 0–2, 2 or 4 parts (halves on the second problem), the cut, 1 to parts − 1 shaded; from the 7th, every third
    /// compares halves and fourths. A square's fourths are never strips (7½ squares each).
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        if i >= 6 && (i - 6) % 3 == 0 {
            let shape = Shapes1.rnd(0, 2, &rng)
            return compare(shape: shape, left: Shapes1.rnd(0, 1, &rng), hcut: Shapes1.pick(cutsAllowed(shape), &rng), fcut: Shapes1.pick(shape == 1 ? [0, 2] : [0], &rng))
        }
        let shape = Shapes1.rnd(0, 2, &rng), parts = i == 1 ? 2 : Shapes1.pick([2, 4], &rng)
        let cuts = shape == 1 && parts == 4 ? [0, 2] : shape == 0 && parts == 4 ? [0, 1] : cutsAllowed(shape)
        return numbers(shape: shape, parts: parts, cut: Shapes1.pick(cuts, &rng), shaded: Shapes1.rnd(1, parts - 1, &rng))
    }

    public static let spec = LessonSpec(id: "g1-halves", title: "Halves and fourths", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.text(P.compare ? "Which piece is bigger?" : "Cut it into \(P.parts) equal parts.")] },
        idea: { _ in "4 equal parts are fourths; 4 fourths make the whole." },
        depends: ["g1-compose"],
        check: [CheckItem(0), CheckItem(1), CheckItem(3, when: { Parts($0).parts == 4 && !Parts($0).compare }), CheckItem(6, when: { Parts($0).compare })]) { x in
        let P = Parts(x)
        if P.compare {
            let hint = "Each fourth is half of a half."
            let pick = LessonStep(StepWords(say: "Tap a bigger piece.", hint: hint, action: "Check"),
                answer: TeensK.hand("b", 1, hint: hint, explain: "A half is bigger than a fourth.", said: { _ in "A fourth is half of a half. More parts are smaller." }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
            return [pick, LessonStep(StepWords(say: Parts.compareWhy, hint: "", action: "Next problem"), picture: ["at": 1])]
        }
        let cutHint = "Drag from one edge to the other, through the middle."
        let cut = LessonStep(StepWords(say: P.cutSay, hint: cutHint, action: "Check"),
            answer: TeensK.hand("k", 1, hint: cutHint, explain: "\(P.parts) equal parts.", said: P.cutMiss),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])
        let nameHint = "Count the equal parts."
        let name = LessonStep(StepWords(say: P.nameSay, hint: nameHint, action: "Check"),
            answer: AnswerTask(prompt: [.box("n")], expected: ["n": Double(P.right)], known: [0, 1, 2].filter { $0 != P.right }.map { (["n": Double($0)], P.picked($0)) },
                               hint: nameHint, explain: "\(P.parts) equal parts are \(P.name).", byHand: true),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1])
        let shadeHint = "Tap a part to shade it."
        let shade = LessonStep(StepWords(say: P.shadeSay, hint: shadeHint, action: "Check"),
            answer: TeensK.hand("s", P.shaded, hint: shadeHint, explain: "\(P.shaded) \(P.shaded == 1 ? P.one : P.name) shaded.", said: { _ in "Shade only \(P.shaded)." }),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1])
        let done = LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 3])
        return [cut, name, shade, done]
    }
}
