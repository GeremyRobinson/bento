import Foundation

/// 2nd grade's chapter 7, Shapes (design/grade2.md chapter 7, the preview design/prototype/grade2-ch7.html): one square is one
/// step of a side, every corner on a grid crossing; a solid is Unit cubes' (a block is a cube's side); every half, third and
/// fourth of a whole is a whole number of squares (a rectangle 48 × 24, a square 24 × 24, a circle 30 across). Every line is
/// spoken (App's Voice); the preview's grey second line is folded into the instruction; the one number written (how many parts
/// make the whole) is typed with the iPad's keys and Check, as the preview types. Its words, slips and generators word for word.
public enum Shapes2 {
    public typealias Pt = Shapes1.Pt
    static func int(_ v: Numbers, _ k: String, _ d: Int = 0) -> Int { G2.int(v, k, d) }
    static func rnd(_ a: Int, _ b: Int, _ rng: inout SeededRandom) -> Int { Int.random(in: a...b, using: &rng) }
    static func pick<T>(_ a: [T], _ rng: inout SeededRandom) -> T { a[Int.random(in: 0..<a.count, using: &rng)] }
    public static func an(_ s: String) -> String { ShapesK.an(s) }
    public static func count(_ n: Int, _ one: String) -> String { G2.count(n, one) }
    /// "16 and 20", "16, 20 and 12".
    public static func listAnd(_ a: [Int]) -> String {
        guard let last = a.last else { return "" }
        if a.count == 1 { return "\(last)" }
        return a.dropLast().map(String.init).joined(separator: ", ") + " and \(last)"
    }
    static func orient(_ a: Pt, _ b: Pt, _ c: Pt) -> Double { Shapes1.orient(a, b, c) }
    /// The convex hull of points (corners in a line dropped).
    public static func hull(_ pts: [Pt]) -> [Pt] {
        let P = pts.sorted { $0.0 < $1.0 || ($0.0 == $1.0 && $0.1 < $1.1) }
        guard P.count >= 3 else { return P }
        var lo: [Pt] = [], hi: [Pt] = []
        for p in P { while lo.count >= 2 && orient(lo[lo.count - 2], lo[lo.count - 1], p) <= 0 { lo.removeLast() }; lo.append(p) }
        for p in P.reversed() { while hi.count >= 2 && orient(hi[hi.count - 2], hi[hi.count - 1], p) <= 0 { hi.removeLast() }; hi.append(p) }
        return Array(lo.dropLast()) + Array(hi.dropLast())
    }
    public static func centroid(_ pts: [Pt]) -> Pt {
        var a = 0.0, cx = 0.0, cy = 0.0
        for i in pts.indices {
            let p = pts[i], q = pts[(i + 1) % pts.count]
            let c: Double = p.0 * q.1 - q.0 * p.1
            a += c; cx += (p.0 + q.0) * c; cy += (p.1 + q.1) * c
        }
        return abs(a) < 1e-9 ? pts[0] : (cx / (3 * a), cy / (3 * a))
    }
    public static func rot(_ p: Pt, _ o: Pt, _ deg: Double) -> Pt {
        let a = deg * .pi / 180, c = cos(a), s = sin(a), dx = p.0 - o.0, dy = p.1 - o.1
        return (o.0 + c * dx - s * dy, o.1 + s * dx + c * dy)
    }
}

// MARK: - Sides and corners

/// Sides and corners (g2-shapes, new; 2.G.A.1). Name it: a shape 18–30 squares across, its corners on the paper's crossings (wide
/// or thin, turned, some with a dent); tap each corner or trace each side (each lights and counts, `5 corners · 5 sides`), Check,
/// then tap its name. Draw it: an empty patch of paper 30 × 22; tap crossings to place corners (each draws the side from the last),
/// tap the first to close; a corner can be dragged. Then its name. The record: `5 sides, 5 corners: pentagon`.
///
/// Numbers: `kind` 0 name, 1 draw; `n` sides; a name's `variant` (Sides2.variants) and corners `x<i>`, `y<i>`. "at": 0 count (or
/// draw), 1 name, 2 done. Boxes: "c" the corners counted (−1 one tapped twice); "d" 1 drawn right, −1 in a line, −2 sides cross,
/// −(100 + n) n sides; "m" the name tapped (0 triangle … 3 hexagon), + 10 when the shape has square corners (a rectangle), + 20
/// a square.
public enum Sides2 {
    public static let names = ["triangle", "quadrilateral", "pentagon", "hexagon"]
    public static func name(_ n: Int) -> String { names[max(0, min(3, n - 3))] }
    public static let variants = ["plain", "turned", "thin", "dent", "square", "rect"]
    public static let PW = 30.0, PH = 22.0
    public static func numbers(draw n: Int) -> Numbers { ["kind": 1, "n": Double(n)] }
    public static func numbers(name pts: [(Int, Int)], variant: Int) -> Numbers {
        var x: Numbers = ["kind": 0, "n": Double(pts.count), "variant": Double(variant)]
        for (i, p) in pts.enumerated() { x["x\(i)"] = Double(p.0); x["y\(i)"] = Double(p.1) }
        return x
    }

    /// A drawn (or given) shape's facts: corners in a line merged, sides crossing, square corners, same sides.
    public struct Facts: Sendable { public let c: [Shapes2.Pt]; public let n: Int; public let cross: Bool; public let right: Bool; public let same: Bool }
    public static func facts(_ pts: [Shapes2.Pt]) -> Facts {
        var c = pts
        var changed = true
        while changed && c.count > 2 {
            changed = false
            for i in c.indices {
                let a = c[(i + c.count - 1) % c.count], b = c[(i + 1) % c.count]
                if Shapes2.orient(a, c[i], b) == 0 { c.remove(at: i); changed = true; break }
            }
        }
        let n = c.count
        var cross = false
        if n >= 4 {
            for i in 0..<n { for j in (i + 2)..<max(i + 2, n) where !(i == 0 && j == n - 1) { if Shapes1.meet(c[i], c[(i + 1) % n], c[j], c[(j + 1) % n]) { cross = true } } }
        }
        func l2(_ i: Int) -> Double { let a = c[i], b = c[(i + 1) % n]; let dx: Double = b.0 - a.0, dy: Double = b.1 - a.1; return dx * dx + dy * dy }
        func square(_ i: Int) -> Bool {
            let a = c[(i + n - 1) % n], b = c[(i + 1) % n], p = c[i]
            let dx: Double = (a.0 - p.0) * (b.0 - p.0), dy: Double = (a.1 - p.1) * (b.1 - p.1)
            return dx + dy == 0
        }
        let right = n == 4 && c.indices.allSatisfy(square)
        let same = n >= 3 && c.indices.allSatisfy { l2($0) == l2(0) }
        return Facts(c: c, n: n, cross: cross, right: right, same: same)
    }
    /// What a finished drawing says: 1 right, or the miss code.
    public static func drawn(_ want: Int, _ pts: [Shapes2.Pt]) -> Int {
        let f = facts(pts)
        if f.n < 3 { return -1 }
        if f.cross { return -2 }
        if f.n != want { return -(100 + f.n) }
        return 1
    }
    /// The name box's value for a pick: the name's index, plus 10 for a rectangle or 20 for a square when it's wrong.
    public static func pickCode(_ f: Facts, _ j: Int) -> Int {
        guard j != f.n - 3 else { return j }
        return j + (f.n == 4 && f.right ? (f.same ? 20 : 10) : 0)
    }

    // the preview's generator
    static func angleOk(_ p: [Shapes2.Pt], _ min: Double) -> Bool { WhatShape1.angleOk(p, min) }
    static func reflex(_ pts: [Shapes2.Pt]) -> [Bool] {
        let n = pts.count, s = Shapes1.area2(pts) > 0 ? 1.0 : -1.0
        return pts.indices.map { j in
            let o = Shapes2.orient(pts[(j + n - 1) % n], pts[j], pts[(j + 1) % n])
            return (o > 0 ? 1.0 : o < 0 ? -1.0 : 0) != s
        }
    }
    static func ok(_ pts: [Shapes2.Pt], _ n: Int, _ variant: String) -> Bool {
        let b = Shapes1.bbox(pts), w = b.x1, h = b.y1
        if pts.count != n || max(w, h) < 18 || w > 30 || h > 24 || min(w, h) < (variant == "thin" ? 5 : 10) { return false }
        for j in 0..<n {
            let a = pts[j], c = pts[(j + 1) % n]
            if hypot(c.0 - a.0, c.1 - a.1) < 5 || Shapes2.orient(pts[(j + n - 1) % n], a, c) == 0 { return false }
        }
        for i in 0..<n { for j in (i + 2)..<max(i + 2, n) where !(i == 0 && j == n - 1) { if Shapes1.meet(pts[i], pts[(i + 1) % n], pts[j], pts[(j + 1) % n]) { return false } } }
        if !angleOk(pts, 28) { return false }
        let rf = reflex(pts), dents = rf.filter { $0 }.count
        if dents != (variant == "dent" ? 1 : 0) { return false }
        if variant == "dent", let k = rf.firstIndex(of: true), Shapes1.polyDist(pts[k], Shapes2.hull(pts)) < 2.5 { return false }
        for j in 0..<n { for i in 0..<n where i != j && (i + 1) % n != j { if Shapes1.segDist(pts[j], pts[i], pts[(i + 1) % n]) < 3 { return false } } }
        return true
    }
    static func make(_ n: Int, _ variant: String, notSquare: Bool, _ rng: inout SeededRandom) -> [(Int, Int)] {
        for _ in 0..<20000 {
            var pts: [Shapes2.Pt]
            if variant == "square" || variant == "rect" {
                if Shapes2.rnd(0, 1, &rng) == 1 {
                    let w = variant == "square" ? Shapes2.rnd(18, 24, &rng) : Shapes2.rnd(22, 30, &rng)
                    let h = variant == "square" ? w : Shapes2.rnd(12, 20, &rng)
                    if variant == "rect" && w - h < 5 { continue }
                    pts = [(0, 0), (Double(w), 0), (Double(w), Double(h)), (0, Double(h))]
                } else {
                    let ab = Shapes2.pick([(2, 1), (1, 2), (3, 1), (1, 3), (3, 2), (2, 3), (4, 3), (3, 4)], &rng), k = Shapes2.rnd(2, 8, &rng)
                    let m = variant == "square" ? k : Shapes2.rnd(2, 8, &rng)
                    if variant == "rect" && abs(k - m) < 2 { continue }
                    let u = (Double(ab.0 * k), Double(ab.1 * k)), v = (Double(-ab.1 * m), Double(ab.0 * m))
                    pts = [(0, 0), u, (u.0 + v.0, u.1 + v.1), v]
                    let xs = pts.map(\.0)
                    if (xs.max() ?? 0) - (xs.min() ?? 0) < 18 { continue }
                }
            } else {
                let thin = variant == "thin"
                let W = Double(thin ? Shapes2.rnd(26, 32, &rng) : Shapes2.rnd(24, 32, &rng)), H = Double(thin ? Shapes2.rnd(7, 10, &rng) : Shapes2.rnd(18, 26, &rng))
                let a0 = Double.random(in: 0..<1, using: &rng) * 2 * .pi, step = 2 * .pi / Double(n)
                let dent = variant == "dent" ? Shapes2.rnd(0, n - 1, &rng) : -1
                var rotA = 0.0
                if variant == "turned" || (thin && Shapes2.rnd(0, 1, &rng) == 1) {
                    let sign: Double = Shapes2.rnd(0, 1, &rng) == 1 ? 1 : -1
                    rotA = sign * (.pi / 9 + Double.random(in: 0..<1, using: &rng) * .pi / 4)
                }
                pts = []
                for j in 0..<n {
                    let a = a0 + Double(j) * step + (Double.random(in: 0..<1, using: &rng) - 0.5) * 0.5 * step
                    let r: Double
                    if j == dent { r = n == 4 ? -(0.12 + Double.random(in: 0..<1, using: &rng) * 0.25) : 0.25 + Double.random(in: 0..<1, using: &rng) * 0.25 }
                    else { r = 0.82 + Double.random(in: 0..<1, using: &rng) * 0.18 }
                    let x = W / 2 * r * cos(a), y = H / 2 * r * sin(a)
                    let px: Double = x * cos(rotA) - y * sin(rotA), py: Double = x * sin(rotA) + y * cos(rotA)
                    pts.append((px.rounded(), py.rounded()))
                }
            }
            pts = Shapes1.norm(pts)
            if !ok(pts, n, variant) { continue }
            let f = facts(pts)
            if notSquare && f.right && f.same { continue }
            return pts.map { (Int($0.0), Int($0.1)) }
        }
        return n == 3 ? [(0, 20), (24, 20), (9, 0)] : n == 4 ? [(0, 0), (24, 0), (24, 14), (0, 14)] : n == 5 ? [(12, 0), (25, 9), (20, 22), (4, 22), (0, 9)] : [(0, 11), (7, 0), (21, 0), (28, 11), (21, 22), (7, 22)]
    }
    /// The preview's: problems 0–2 name a triangle, name a quadrilateral that isn't a square, draw a triangle; from 3 odd
    /// problems name and even ones draw, pentagons and hexagons more often.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let draw = i == 2 || (i > 2 && i % 2 == 0)
        let n = i == 0 ? 3 : i == 1 ? 4 : i == 2 ? 3 : Shapes2.pick([3, 4, 5, 5, 6, 6], &rng)
        if draw { return numbers(draw: n) }
        let vs: [String]
        if i < 2 { vs = ["plain", "turned"] }
        else if n == 3 { vs = ["plain", "turned", "thin"] }
        else if n == 4 { vs = ["plain", "turned", "thin", "dent", "square", "rect"] }
        else { vs = ["plain", "turned", "thin", "dent"] }
        let v = Shapes2.pick(vs, &rng)
        return numbers(name: make(n, v, notSquare: i == 1, &rng), variant: variants.firstIndex(of: v) ?? 0)
    }

    public struct Parts: Sendable {
        public let draw: Bool, n: Int, variant: Int
        /// A name's shape, from 0, 0.
        public let pts: [Shapes2.Pt]
        public init(_ x: Numbers) {
            draw = Shapes2.int(x, "kind") == 1
            variant = max(0, min(5, Shapes2.int(x, "variant")))
            let k = max(3, min(6, Shapes2.int(x, "n", 3)))
            if draw { pts = []; n = k }
            else {
                let m = max(3, Shapes2.int(x, "n", 3))
                pts = Shapes1.norm((0..<m).map { (Double(Shapes2.int(x, "x\($0)")), Double(Shapes2.int(x, "y\($0)"))) })
                n = m
            }
        }
        public var w: Double { draw ? Sides2.PW : Shapes1.bbox(pts).x1 }
        public var h: Double { draw ? Sides2.PH : Shapes1.bbox(pts).y1 }
        public var shapeName: String { Sides2.name(n) }
        public var countSay: String { "Count its corners." }
        public var drawSay: String { "Draw a shape with \(n) corners." }
        public static let nameSay = "Tap its name."
        public var why: String { "\(n) sides and \(n) corners make \(Shapes2.an(shapeName)), however it's turned." }
        public var record: String { "\(n) sides, \(n) corners: \(shapeName)" }
        /// What a Check (or a corner tapped twice) says.
        public func countMiss(_ c: Int) -> String {
            if c < 0 { return "That corner is counted already." }
            if c == 0 { return "Tap each corner." }
            let k = n - c
            return k == 1 ? "One corner isn't counted yet." : "\(k) corners aren't counted yet."
        }
        public func drawMiss(_ code: Int) -> String {
            switch code {
            case -1: return "Those corners are in a line."
            case -2: return "Two sides cross. Move a corner."
            case ...(-100): return "That has \(-code - 100) sides. Draw \(n)."
            default: return "Tap the first corner again to close it."
            }
        }
        public static func nameMiss(_ code: Int) -> String {
            let sq = code / 10, j = max(0, min(3, code % 10))
            if sq == 2 { return "A square has 4 sides, so it's a quadrilateral too." }
            if sq == 1 { return "A rectangle has 4 sides, so it's a quadrilateral too." }
            return "A \(Sides2.names[j]) has \(j + 3) sides."
        }
    }

    public static let spec = LessonSpec(id: "g2-shapes", title: "Sides and corners", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.text(P.draw ? P.drawSay : P.countSay)] },
        idea: { x in Parts(x).why },
        depends: ["g1-shapes"],
        check: [CheckItem(3, when: { let P = Parts($0); return !P.draw && P.n == 5 }), CheckItem(4, when: { Parts($0).n == 6 }),
                CheckItem(5, when: { let P = Parts($0); return !P.draw && P.n == 4 && P.variant == 1 }), CheckItem(6)]) { x in
        let P = Parts(x)
        var steps: [LessonStep] = []
        if P.draw {
            let hint = "Tap a crossing for each corner. Tap the first one again to close it."
            steps.append(LessonStep(StepWords(say: P.drawSay, hint: hint, action: "Check"),
                answer: G2.hand("d", 1, hint: hint, explain: "\(P.n) corners, \(P.n) sides.", said: { P.drawMiss($0) }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1]))
        } else {
            let hint = "Tap each corner once, or trace each side."
            steps.append(LessonStep(StepWords(say: P.countSay, hint: hint, action: "Check"),
                answer: G2.hand("c", P.n, hint: hint, explain: "\(P.n) corners · \(P.n) sides.", said: { P.countMiss($0) }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        let nameHint = "Count its sides."
        steps.append(LessonStep(StepWords(say: Parts.nameSay, hint: nameHint, action: "Check"),
            answer: G2.hand("m", P.n - 3, hint: nameHint, explain: "\(P.n) sides: \(Shapes2.an(P.shapeName)).", said: { Parts.nameMiss($0) }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        steps.append(LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 2]))
        return steps
    }
}

// MARK: - Faces, edges and corners

/// Faces, edges and corners (g2-solids, the web's; 2.G.A.1; 3D on the shared PaperStand). Unit cubes' scale: a block (5 squares)
/// is a cube's side. Flat first: the solid's base on the paper (a box 3 × 2 blocks, a cube 2 × 2, a square pyramid 2 × 2, a
/// triangular prism 3 × 2), its name hidden. Tilt the paper (drag it up): the solid rises from its base, 2 blocks tall. Turn it
/// with one finger (across: round; up and down: over), snapping every 15°; tap every face (it tints and takes its number), Check;
/// the same for the edges (each drawn in ink) and the corners (a dot). Hidden edges are dashed. Then its name.
///
/// Numbers: `solid` 0 cube, 1 box, 2 pyramid, 3 triangular prism; `turn` 0–2 (0°, 90°, 45°). "at": 0 tilt, 1 faces, 2 edges,
/// 3 corners, 4 name, 5 done. Boxes: "t" 1 tilted (0 not far enough); "f", "e", "v" the count (Check), or a miss code
/// (Solids2.Parts.countMiss); "n" the name tapped.
public enum Solids2 {
    public struct Solid: Sendable { public let kind: String, name: String, say: String }
    public static let solids = [
        Solid(kind: "cube", name: "cube", say: "Every face is a square."),
        Solid(kind: "box", name: "rectangular prism", say: "Its faces are rectangles, not all squares."),
        Solid(kind: "pyramid", name: "pyramid", say: "Its side faces meet at one point at the top."),
        Solid(kind: "triPrism", name: "triangular prism", say: "It has a triangle at each end."),
    ]
    public static let names = solids.map(\.name)
    static let why: [String: [String: String]] = [
        "cube": ["rectangular prism": "Every face is a square, so it's a cube."],
        "rectangular prism": ["cube": "A cube's faces are all squares. These faces are rectangles: a rectangular prism."],
        "pyramid": ["triangular prism": "A triangular prism has a triangle at each end. This one's faces all meet at one point at the top: a pyramid."],
        "triangular prism": ["pyramid": "A pyramid's faces meet at one point. This has a triangle at each end: a triangular prism."],
    ]
    public static let turns = [0.0, 90.0, 45.0]
    public static func numbers(solid: Int, turn: Int = 0) -> Numbers { ["solid": Double(solid), "turn": Double(turn)] }

    /// A solid in squares about the middle of its base (x along, y across, z up): corners, faces (with their outward way),
    /// edges with the faces they join, the faces at each corner.
    public struct Geo: Sendable {
        public let V: [Vec3]
        public let F: [[Int]]
        public let N: [Vec3]
        public let E: [(a: Int, b: Int, f: [Int])]
        public let VF: [[Int]]
    }
    static let geos = solids.map { geo($0.kind) }
    public static func geo(_ kind: String) -> Geo {
        var V: [Vec3], F: [[Int]]
        switch kind {
        case "cube", "box":
            let X = kind == "cube" ? 5.0 : 7.5
            V = [Vec3(-X, -5, 0), Vec3(X, -5, 0), Vec3(X, 5, 0), Vec3(-X, 5, 0), Vec3(-X, -5, 10), Vec3(X, -5, 10), Vec3(X, 5, 10), Vec3(-X, 5, 10)]
            F = [[0, 1, 2, 3], [4, 5, 6, 7], [0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]]
        case "pyramid":
            V = [Vec3(-5, -5, 0), Vec3(5, -5, 0), Vec3(5, 5, 0), Vec3(-5, 5, 0), Vec3(0, 0, 10)]
            F = [[0, 1, 2, 3], [0, 1, 4], [1, 2, 4], [2, 3, 4], [3, 0, 4]]
        default:
            V = [Vec3(-7.5, -5, 0), Vec3(7.5, -5, 0), Vec3(7.5, 5, 0), Vec3(-7.5, 5, 0), Vec3(-7.5, 0, 10), Vec3(7.5, 0, 10)]
            F = [[0, 1, 2, 3], [0, 1, 5, 4], [3, 2, 5, 4], [0, 3, 4], [1, 2, 5]]
        }
        var cen = Vec3(0, 0, 0)
        for v in V { cen = cen + v * (1 / Double(V.count)) }
        var N: [Vec3] = []
        for f in F {
            var n = (V[f[1]] - V[f[0]]).cross(V[f[2]] - V[f[0]])
            var m = Vec3(0, 0, 0)
            for i in f { m = m + V[i] * (1 / Double(f.count)) }
            if n.dot(m - cen) < 0 { n = n * -1 }
            N.append(n.normalized)
        }
        var E: [(a: Int, b: Int, f: [Int])] = []
        for (fi, f) in F.enumerated() {
            for (i, a) in f.enumerated() {
                let b = f[(i + 1) % f.count], lo = min(a, b), hi = max(a, b)
                if let k = E.firstIndex(where: { $0.a == lo && $0.b == hi }) { E[k].f.append(fi) } else { E.append((lo, hi, [fi])) }
            }
        }
        let VF = V.indices.map { i in F.indices.filter { F[$0].contains(i) } }
        return Geo(V: V, F: F, N: N, E: E, VF: VF)
    }

    public struct Parts: Sendable {
        public let solid: Int, turn: Int
        public let geo: Geo
        public init(_ x: Numbers) {
            solid = max(0, min(3, Shapes2.int(x, "solid"))); turn = max(0, min(2, Shapes2.int(x, "turn")))
            geo = Solids2.geos[solid]
        }
        public var S: Solid { Solids2.solids[solid] }
        public var faces: Int { geo.F.count }
        public var edges: Int { geo.E.count }
        public var corners: Int { geo.V.count }
        public var yaw0: Double { Solids2.turns[turn] }
        public static let tiltSay = "Tilt the paper."
        public static func say(_ what: String) -> String { "Tap every \(what). Turn it to see more." }
        public static let nameSay = "Tap its name."
        public var why: String { S.say }
        /// The record so far: `6 faces · 12 edges · 8 corners`, then its name.
        public func record(_ found: Int, named: Bool) -> String {
            let parts = [Shapes2.count(faces, "face"), Shapes2.count(edges, "edge"), Shapes2.count(corners, "corner")]
            let s = parts.prefix(found).joined(separator: " · ")
            return named ? "\(s): \(S.name)" : s
        }
        /// A Check's miss, by code: −(100 + m) m you can see aren't counted; −(200 + seen) every face you can see counted, flat
        /// (the rest are at the back and bottom); −(300 + k) k more hidden; −4 more hidden (edges or corners); −5 one corner
        /// round the back; −6 one tapped twice.
        public func countMiss(_ what: String, _ code: Int) -> String {
            let one = String(what.dropLast())
            switch code {
            case -6: return "That \(one) is counted already."
            case -5: return "One corner is around the back. Look where the dashed edges meet."
            case -4: return what == "edges" ? "Some edges are hidden too. Turn it." : "Some corners are hidden too. Turn it."
            case -299 ... -200: let seen = -code - 200; return "You can see \(seen). \(faces - seen) more are hidden at the back and bottom."
            case -399 ... -300: let k = -code - 300; return "\(k) more \(k == 1 ? "is" : "are") hidden. Turn it."
            case -199 ... -100:
                let m = -code - 100
                return m == 1 ? "\(ShapesK.cap(Shapes2.an(one))) you can see isn't counted yet." : "\(m) \(what) you can see aren't counted yet."
            default: return "Tap every \(one)."
            }
        }
        public func nameMiss(_ j: Int) -> String {
            let w = Solids2.names[max(0, min(3, j))]
            return Solids2.why[S.name]?[w] ?? "Count again: \(faces) faces, \(edges) edges, \(corners) corners. That's \(Shapes2.an(S.name))."
        }
    }

    /// The web's: box, triangular prism, cube, pyramid in turn, each turned one of three ways.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers { numbers(solid: [1, 3, 0, 2][i % 4], turn: Shapes2.rnd(0, 2, &rng)) }

    public static let spec = LessonSpec(id: "g2-solids", title: "Faces, edges and corners", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { _ in [.text("Count its faces, edges and corners.")] },
        idea: { x in Parts(x).why },
        depends: ["g2-shapes", "g1-build"],
        check: [CheckItem(0), CheckItem(1), CheckItem(2), CheckItem(3)]) { x in
        let P = Parts(x)
        let tiltHint = "Put your finger on the paper and drag it up."
        var steps = [LessonStep(StepWords(say: Parts.tiltSay, hint: tiltHint, action: "Check"),
            answer: G2.hand("t", 1, hint: tiltHint, explain: "It stands up.", said: { _ in "Drag the paper up." }),
            picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1])]
        let counts = [("faces", "f", P.faces), ("edges", "e", P.edges), ("corners", "v", P.corners)]
        for (k, c) in counts.enumerated() {
            let one = String(c.0.dropLast())
            let hint = "Tap each \(one) once. Drag across it to turn it."
            steps.append(LessonStep(StepWords(say: Parts.say(one), hint: hint, action: "Check"),
                answer: G2.hand(c.1, c.2, hint: hint, explain: Shapes2.count(c.2, one), said: { P.countMiss(c.0, $0) }),
                picture: ["at": Double(k + 1)], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        let nameHint = "Look at its faces: squares, rectangles or triangles?"
        steps.append(LessonStep(StepWords(say: Parts.nameSay, hint: nameHint, action: "Check"),
            answer: G2.hand("n", P.solid, hint: nameHint, explain: "\(Shapes2.an(P.S.name)).", said: { P.nameMiss($0) }),
            picture: ["at": 4], onMiss: ["ring": 1], hint2: ["spot": 1]))
        steps.append(LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 5]))
        return steps
    }
}

// MARK: - Halves, thirds and fourths

/// Halves, thirds and fourths (g2-shares, the web's; 2.G.A.3). The whole big, a size every cut lands on whole squares: a
/// rectangle 48 × 24 (halves 24, thirds 16, fourths 12 wide, or a cross of 24 × 12), a square 24 × 24 (12, 8, 6), a circle 30
/// across. Cut with the ruler, edge to edge (straight down or across, snapped to a square; the square corner to corner; the
/// circle from the middle out, or across through it, to equal turns); the readout gives each part's width (`16 | 16 | 16`;
/// a circle's or a corner-to-corner's `the same`). Right: the parts number and land on the first. Then the name, shade, and
/// `[3] thirds make 1 whole`. Same size? (problems 3, 7, 11 …): two copies at half size cut two ways; tap yes or no, then a part
/// of one lifts, cuts into pieces and slides onto a part of the other, covering it exactly; then the name, shade and write.
///
/// Numbers: `shape` 0 rectangle, 1 square, 2 circle; `parts` 2–4; `cut` the way it's cut (the web's cutsFor); `shaded`; `other`
/// the Same size? copy's cut (−1: not that kind). "at": 0 cut (or same), 1 name, 2 shade, 3 write, 4 done. Boxes: "k" 1 cut, else
/// a miss code (Shares2.cutMiss); "y" 1 yes, 0 no; "n" the name (0 halves, 1 thirds, 2 fourths); "s" the parts shaded (Check);
/// "w" how many make the whole (typed).
public enum Shares2 {
    public static let shapes = ["rectangle", "square", "circle"]
    public static let plural = [2: "halves", 3: "thirds", 4: "fourths"], single = [2: "half", 3: "third", 4: "fourth"]
    public static let nameList = ["halves", "thirds", "fourths"]
    public static func pw(_ n: Int, _ parts: Int) -> String { (n == 1 ? single[parts] : plural[parts]) ?? "" }
    /// The web's cuts (diagrams/early-g1/parts.ts cutsFor).
    public static func cuts(_ shape: Int, _ parts: Int) -> [Int] {
        if shape == 2 { return [0] }
        if parts == 3 { return [0, 1] }
        if parts == 2 { return shape == 1 ? [0, 1, 2] : [0, 1] }
        return shape == 1 ? [0, 1, 2, 3] : [0, 1, 3]
    }
    /// Same size? pairs: a square's corner-to-corner fourths are only paired with its cross.
    static func pairOk(_ shape: Int, _ parts: Int, _ a: Int, _ b: Int) -> Bool { a != b && !(shape == 1 && parts == 4 && (a == 2 || b == 2) && a + b != 2) }
    public static func numbers(shape: Int, parts: Int, cut: Int = 0, shaded: Int = 1, other: Int = -1) -> Numbers {
        ["shape": Double(shape), "parts": Double(parts), "cut": Double(cut), "shaded": Double(shaded), "other": Double(other)]
    }
    /// The web's: problems 0–2 halves or fourths with one shaded; the same-size kind on index % 4 = 3.
    static func make(_ rng: inout SeededRandom, _ i: Int) -> Numbers {
        let early = i < 3, same = i % 4 == 3
        let parts = early ? Shapes2.pick([2, 4], &rng) : Shapes2.rnd(2, 4, &rng)
        let shape = same ? Shapes2.rnd(0, 1, &rng) : Shapes2.rnd(0, 2, &rng), cs = cuts(shape, parts), cut = Shapes2.pick(cs, &rng)
        let shaded = early ? 1 : Shapes2.rnd(1, parts, &rng)
        var other = -1
        if same { other = Shapes2.pick(cs.filter { pairOk(shape, parts, cut, $0) }, &rng) }
        return numbers(shape: shape, parts: parts, cut: cut, shaded: shaded, other: other)
    }

    // MARK: cuts, as numbers: 100 + n straight down n squares from the left edge, 200 + n across n from the top, 300 corner to
    // corner from the top left, 301 from the top right, 400 + a degrees a circle's radius (y down: 270 is up)
    public static func down(_ n: Int) -> Int { 100 + n }
    public static func across(_ n: Int) -> Int { 200 + n }
    public static let d0 = 300, d1 = 301
    public static func radius(_ a: Int) -> Int { 400 + ((a % 360) + 360) % 360 }

    public struct Geom: Sendable {
        public let kind: Int, x0: Double, y0: Double, W: Double, H: Double
        public var cx: Double { x0 + W / 2 }
        public var cy: Double { y0 + H / 2 }
        public var r: Double { W / 2 }
    }
    public static func geom(_ shape: Int, x0: Double = 0, y0: Double = 0, half: Bool = false) -> Geom {
        // the square 24 a side and the circle 30 across (centred on a block corner): at the design's 36 they showed at 65–71%
        if shape == 2 { return Geom(kind: 2, x0: x0, y0: y0, W: 30, H: 30) }
        if shape == 1 { return Geom(kind: 1, x0: x0, y0: y0, W: 24, H: 24) }
        return half ? Geom(kind: 0, x0: x0, y0: y0, W: 24, H: 12) : Geom(kind: 0, x0: x0, y0: y0, W: 48, H: 24)
    }
    /// The web's cut as lines (the preview's cutSet).
    public static func cutSet(_ g: Geom, _ parts: Int, _ cut: Int) -> [Int] {
        let W = Int(g.W), H = Int(g.H)
        func strips(_ t: (Int) -> Int, _ F: Int, _ n: Int) -> [Int] { (1..<n).map { t(F * $0 / n) } }
        if g.kind == 2 { return parts == 2 ? [radius(90), radius(270)] : parts == 3 ? [radius(270), radius(30), radius(150)] : [radius(0), radius(90), radius(180), radius(270)] }
        if parts == 2 { return cut == 0 ? [down(W / 2)] : cut == 1 ? [across(H / 2)] : [d1] }
        if parts == 3 { return cut == 0 ? strips(down, W, 3) : strips(across, H, 3) }
        return cut == 0 ? [down(W / 2), across(H / 2)] : cut == 1 ? strips(down, W, 4) : cut == 3 ? strips(across, H, 4) : [d0, d1]
    }
    static func at(_ cuts: [Int], _ kind: Int) -> [Int] { cuts.filter { $0 / 100 == kind }.map { $0 % 100 }.sorted() }
    static func gaps(_ xs: [Int], _ full: Int) -> [Int] { let a = [0] + xs + [full]; return (1..<a.count).map { a[$0] - a[$0 - 1] } }

    /// The parts a set of cuts makes, and whether they're equal (rectangles: same widths and heights; wedges: same turns).
    public struct Judge: Sendable {
        public var n: Int, equal: Bool, mixed = false, tri = false
        public var parts: [[Shapes2.Pt]] = []
        public var ws: [Int] = [], hs: [Int] = []
    }
    public static func outline(_ g: Geom) -> [Shapes2.Pt] {
        g.kind == 2 ? Array(Shapes1.arc(g.cx, g.cy, g.r, 0, 360, 72).prefix(72)) : [(g.x0, g.y0), (g.x0 + g.W, g.y0), (g.x0 + g.W, g.y0 + g.H), (g.x0, g.y0 + g.H)]
    }
    public static func judge(_ g: Geom, _ cuts: [Int]) -> Judge {
        if g.kind == 2 {
            let as_ = Array(Set(cuts.filter { $0 >= 400 }.map { $0 - 400 })).sorted()
            if as_.count < 2 { return Judge(n: 1, equal: true, parts: [outline(g)]) }
            var parts: [[Shapes2.Pt]] = [], turns: [Int] = []
            for (j, a0) in as_.enumerated() {
                let a1 = j + 1 < as_.count ? as_[j + 1] : as_[0] + 360
                turns.append(a1 - a0)
                parts.append([(g.cx, g.cy)] + Shapes1.arc(g.cx, g.cy, g.r, Double(a0), Double(a1), max(2, (a1 - a0) / 5)))
            }
            return Judge(n: as_.count, equal: turns.allSatisfy { $0 == turns[0] }, parts: parts)
        }
        let x0 = g.x0, y0 = g.y0, W = g.W, H = g.H
        let TL = (x0, y0), TR = (x0 + W, y0), BR = (x0 + W, y0 + H), BL = (x0, y0 + H), O = (x0 + W / 2, y0 + H / 2)
        let D0 = cuts.contains(d0), D1 = cuts.contains(d1), xs = at(cuts, 1), ys = at(cuts, 2)
        if (D0 || D1) && (!xs.isEmpty || !ys.isEmpty) { return Judge(n: 2 + xs.count + ys.count, equal: false, mixed: true) }
        if D0 && D1 { return Judge(n: 4, equal: true, tri: true, parts: [[TL, TR, O], [TR, BR, O], [BR, BL, O], [BL, TL, O]]) }
        if D0 { return Judge(n: 2, equal: true, tri: true, parts: [[TL, TR, BR], [TL, BR, BL]]) }
        if D1 { return Judge(n: 2, equal: true, tri: true, parts: [[TL, TR, BL], [TR, BR, BL]]) }
        let ws = gaps(xs, Int(W)), hs = gaps(ys, Int(H)), X = [0] + xs + [Int(W)], Y = [0] + ys + [Int(H)]
        var parts: [[Shapes2.Pt]] = []
        for b in 0..<(Y.count - 1) {
            for a in 0..<(X.count - 1) {
                let l = x0 + Double(X[a]), r = x0 + Double(X[a + 1]), t = y0 + Double(Y[b]), d = y0 + Double(Y[b + 1])
                parts.append([(l, t), (r, t), (r, d), (l, d)])
            }
        }
        let eq = ws.allSatisfy { $0 == ws[0] } && hs.allSatisfy { $0 == hs[0] }
        return Judge(n: ws.count * hs.count, equal: eq, parts: parts, ws: ws, hs: hs)
    }
    /// The live readout of a set of cuts: each part's width (`16 | 16 | 16`), heights, both (`12 | 12 · 12 | 12`), or `the same`.
    public static func readout(_ g: Geom, _ j: Judge) -> String? {
        guard j.n >= 2, !j.mixed else { return nil }
        if g.kind == 2 || j.tri { return j.equal ? "the same" : "not the same" }
        let w = j.ws.map(String.init).joined(separator: " | "), h = j.hs.map(String.init).joined(separator: " | ")
        return j.hs.count == 1 ? w : j.ws.count == 1 ? h : "\(w) · \(h)"
    }
    /// A cut's line, its ends on the outline.
    public static func line(_ g: Geom, _ c: Int) -> (Shapes2.Pt, Shapes2.Pt) {
        if c == d0 { return ((g.x0, g.y0), (g.x0 + g.W, g.y0 + g.H)) }
        if c == d1 { return ((g.x0 + g.W, g.y0), (g.x0, g.y0 + g.H)) }
        if c >= 400 { let a = Double(c - 400) * .pi / 180; return ((g.cx, g.cy), (g.cx + g.r * cos(a), g.cy + g.r * sin(a))) }
        let v = Double(c % 100)
        return c / 100 == 1 ? ((g.x0 + v, g.y0), (g.x0 + v, g.y0 + g.H)) : ((g.x0, g.y0 + v), (g.x0 + g.W, g.y0 + v))
    }
    /// A finger's drag as cuts: down or across (snapped to a square), the square's corner to corner, or a circle's radius or
    /// diameter (snapped to 30°). nil: too short; a negative code: what's wrong (cutMiss).
    public static func snap(_ g: Geom, _ a: Shapes2.Pt, _ b: Shapes2.Pt) -> [Int]? {
        let dx = b.0 - a.0, dy = b.1 - a.1, ax = abs(dx), ay = abs(dy)
        if hypot(dx, dy) < 3 { return nil }
        func d(_ p: Shapes2.Pt, _ q: Shapes2.Pt) -> Double { hypot(p.0 - q.0, p.1 - q.1) }
        if g.kind == 2 {
            let C = (g.cx, g.cy)
            func s30(_ v: Double) -> Int { ((Int((v / 30).rounded()) * 30) % 360 + 360) % 360 }
            func ang(_ p: Shapes2.Pt, _ q: Shapes2.Pt) -> Double { atan2(q.1 - p.1, q.0 - p.0) * 180 / .pi }
            if d(a, C) < 5 && d(b, C) > 6 { return [radius(s30(ang(C, b)))] }
            if d(a, C) > 8 && d(b, C) > 8 && Shapes1.segDist(C, a, b) < 4 { let r = s30(ang(a, b)); return [radius(r), radius(r + 180)] }
            return [-3]
        }
        if g.kind == 1 {
            let TL = (g.x0, g.y0), TR = (g.x0 + g.W, g.y0), BR = (g.x0 + g.W, g.y0 + g.H), BL = (g.x0, g.y0 + g.H)
            func near(_ p: Shapes2.Pt, _ c: Shapes2.Pt) -> Bool { d(p, c) < 4 }
            if (near(a, TL) && near(b, BR)) || (near(a, BR) && near(b, TL)) { return [d0] }
            if (near(a, TR) && near(b, BL)) || (near(a, BL) && near(b, TR)) { return [d1] }
        }
        if ax < 0.35 * ay {
            if ay < 0.5 * g.H { return [-2] }
            return [down(Int(max(1, min(g.W - 1, ((a.0 + b.0) / 2 - g.x0).rounded()))))]
        }
        if ay < 0.35 * ax {
            if ax < 0.5 * g.W { return [-2] }
            return [across(Int(max(1, min(g.H - 1, ((a.1 + b.1) / 2 - g.y0).rounded()))))]
        }
        return [-1]
    }
    /// What new cuts do to the cuts made so far: the cuts now and whether they're done (code 1), still part way (0), or the miss
    /// code (the cuts go).
    public static func cutting(_ g: Geom, _ parts: Int, _ made: [Int], _ new: [Int]) -> (cuts: [Int], code: Int) {
        if let c = new.first, c < 0 { return (made, c) }
        let add = new.filter { !made.contains($0) }
        if add.isEmpty { return (made, 0) }
        if g.kind != 1 && add.contains(where: { $0 == d0 || $0 == d1 }) { return (made, -1) }
        let all = made + add, j = judge(g, all)
        if j.mixed { return (all, -4) }
        if j.n < parts { return (all, 0) }
        if j.n > parts { return (all, -(50 + j.n)) }
        if !j.equal {
            if g.kind == 2 || j.tri { return (all, -4) }
            let wide = j.ws.contains { $0 != j.ws[0] }, list = wide ? j.ws : j.hs
            var packed = 0, k = 1
            for w in list { packed += w * k; k *= 50 }
            return (all, -(100_000_000 + (wide ? 0 : 50_000_000) + list.count * 10_000_000 + packed))
        }
        return (all, 1)
    }
    public struct Parts: Sendable {
        public let shape: Int, parts: Int, cut: Int, shaded: Int, other: Int
        public init(_ x: Numbers) {
            shape = max(0, min(2, Shapes2.int(x, "shape"))); parts = max(2, min(4, Shapes2.int(x, "parts", 2)))
            let cs = Shares2.cuts(shape, parts), c = Shapes2.int(x, "cut")
            cut = cs.contains(c) ? c : cs[0]
            shaded = max(1, min(parts, Shapes2.int(x, "shaded", 1)))
            let o = Shapes2.int(x, "other", -1)
            other = o >= 0 && shape != 2 && cs.contains(o) && o != cut ? o : -1
        }
        public var same: Bool { other >= 0 }
        public var name: String { Shares2.plural[parts] ?? "" }
        public var one: String { Shares2.single[parts] ?? "" }
        public var shapeName: String { Shares2.shapes[shape] }
        public var nameIndex: Int { parts - 2 }
        public var cutSay: String { "Cut it into \(parts) equal parts." }
        public static let sameSay = "Same size? Tap yes or no.", nameSay = "Name the parts.", writeSay = "How many make the whole? Write it."
        public var shadeSay: String { "Shade \(shaded) \(Shares2.pw(shaded, parts))." }
        public var why: String { same ? "Same whole, same number of parts: the same size." : "\(parts) equal parts, so each one is \(Shapes2.an(one))." }
        public var recordWords: String { "\(name) make 1 whole" }
        public var sameMiss: String { "They look different, but each is 1 of \(parts) equal parts of the same \(shapeName)." }
        public func nameMiss(_ j: Int) -> String {
            let w = Shares2.nameList[max(0, min(2, j))]
            return w == "halves" ? "Halves means 2 equal parts. Here there are \(parts)." : w == "thirds" ? "There are \(parts) parts: \(name)." : "\(parts) equal parts are \(name)."
        }
        public func shadeMiss(_ k: Int) -> String { "That's \(k) \(Shares2.pw(k, parts)). Shade \(shaded)." }
        public func cutMiss(_ code: Int) -> String {
            switch code {
            case -1: return shape == 1 ? "Cut straight down, across, or corner to corner." : "Cut straight down or across."
            case -2: return "Cut from edge to edge."
            case -3: return "Cut from the middle out to the edge."
            case -4: return "Not equal: some parts are bigger."
            case -99 ... -50: return "That makes \(-code - 50) parts. Cut it into \(parts)."
            case ...(-100_000_000):
                var c = -code - 100_000_000
                let tall = c >= 50_000_000
                if tall { c -= 50_000_000 }
                let n = c / 10_000_000
                var packed = c % 10_000_000, list: [Int] = []
                for _ in 0..<n { list.append(packed % 50); packed /= 50 }
                return "Not equal: \(Shapes2.listAnd(list)) squares \(tall ? "tall" : "wide")."
            default: return "Cut from edge to edge."
            }
        }
        public var slips: [(Int, String)] {
            var out: [(Int, String)] = []
            if shaded < parts { out.append((shaded, "That's only the shaded ones. Count every part.")) }
            out.append((1, "The whole is made of all the parts. How many \(name) fit in it?"))
            return out
        }
        public static let plain = "Count every part, shaded or not."
    }

    public static let spec = LessonSpec(id: "g2-shares", title: "Halves, thirds and fourths", master: "bars",
        generate: { rng, i in make(&rng, i) },
        display: { x in let P = Parts(x); return [.text(P.same ? Parts.sameSay : P.cutSay)] },
        idea: { x in Parts(x).why },
        depends: ["g1-halves"],
        check: [CheckItem(3, when: { Parts($0).same }), CheckItem(4, when: { let P = Parts($0); return P.parts == 3 && !P.same }),
                CheckItem(5, when: { let P = Parts($0); return P.shaded >= 2 && !P.same }), CheckItem(6, when: { Parts($0).shape == 2 })]) { x in
        let P = Parts(x)
        var steps: [LessonStep] = []
        if P.same {
            let hint = "Each is 1 of \(P.parts) equal parts of the same \(P.shapeName)."
            steps.append(LessonStep(StepWords(say: Parts.sameSay, hint: hint, action: "Check"),
                answer: G2.hand("y", 1, hint: hint, explain: "The same size.", said: { _ in P.sameMiss }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1]))
        } else {
            let hint = "Drag from one edge to the other."
            steps.append(LessonStep(StepWords(say: P.cutSay, hint: hint, action: "Check"),
                answer: G2.hand("k", 1, hint: hint, explain: "\(P.parts) equal parts.", said: { P.cutMiss($0) }),
                picture: ["at": 0], onMiss: ["ring": 1], hint2: ["spot": 1]))
        }
        let nameHint = "Count the equal parts."
        steps.append(LessonStep(StepWords(say: Parts.nameSay, hint: nameHint, action: "Check"),
            answer: G2.hand("n", P.nameIndex, hint: nameHint, explain: "\(P.parts) equal parts are \(P.name).", said: { P.nameMiss($0) }),
            picture: ["at": 1], onMiss: ["ring": 1], hint2: ["spot": 1]))
        let shadeHint = "Tap a part to shade it."
        steps.append(LessonStep(StepWords(say: P.shadeSay, hint: shadeHint, action: "Check"),
            answer: G2.hand("s", P.shaded, hint: shadeHint, explain: "\(P.shaded) \(Shares2.pw(P.shaded, P.parts)).", said: { P.shadeMiss($0) }),
            picture: ["at": 2], onMiss: ["ring": 1], hint2: ["spot": 1]))
        steps.append(LessonStep(StepWords(say: Parts.writeSay, hint: Parts.plain, action: "Check"),
            answer: G2.typed("w", P.parts, P.slips, plain: Parts.plain, hint: Parts.plain, explain: "\(P.parts) \(P.recordWords)."),
            picture: ["at": 3], onMiss: ["ring": 1], hint2: ["spot": 1]))
        steps.append(LessonStep(StepWords(say: P.why, hint: "", action: "Next problem"), picture: ["at": 4]))
        return steps
    }
}
