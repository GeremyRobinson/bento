import SwiftUI

/// Area of a polygon on the paper, as in the preview (design/prototype/grade6-ch7.html, dPoly): a shape of rectangles and
/// right triangles from the picture's top (an L, a rectangle and a triangle, two triangles, a house, a rectangle with a
/// corner off), every corner on a grid point, its straight sides named outside it, its heights dashed. Cut along grid
/// lines (each cut runs edge to edge, from side to side or to another cut; a tap takes a cut back), or, with a corner
/// off, along the slanted side to take the corner away; Cut names each piece in it ("6 × 4", "6 × 3 ÷ 2"), or reds the
/// one that's neither. The record beside: each piece's area, then the total (added, or the corner taken away).
///
/// The cuts are hand state ("n", and each cut's "v", "k", "lo", "hi" in units; "take" for the slanted cut; "bad" the
/// piece that's neither). Cut keeps the pieces (Poly6.keep, and each one's corners) for the record and its checks.
@MainActor
struct PolyLesson: PaperLesson {
    static let X0 = 2.0
    var liveKeys: Set<String> { ["grab", "x1", "y1"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { 0 }

    struct Shape {
        let S: Poly6.Shape
        init(_ n: Numbers) { S = Poly6.Shape(n) }
        var U: Double { max(S.width, S.height) <= 14 ? 2 : 1 }
        var pts: [CGPoint] { S.corners.map { CGPoint(x: Double($0.0), y: Double($0.1)) } }
        func X(_ x: Double) -> Double { PolyLesson.X0 + x * U }
        func Y(_ y: Double) -> Double { y * U }
        func sq(_ p: [CGPoint]) -> [CGPoint] { p.map { CGPoint(x: X($0.x), y: Y($0.y)) } }
        func units(_ q: CGPoint) -> CGPoint { CGPoint(x: (q.x - PolyLesson.X0) / U, y: q.y / U) }
        var rx: Double { ((X(Double(S.width)) + 4) / 5).rounded(.up) * 5 }
        func row(_ j: Int) -> Double { 1 + 3 * Double(j) }
        /// The slanted side of a rectangle with a corner off.
        var slant: (CGPoint, CGPoint) {
            for i in pts.indices { let a = pts[i], b = pts[(i + 1) % pts.count]; if a.x != b.x && a.y != b.y { return (a, b) } }
            return (pts[0], pts[1])
        }
    }
    struct Cut: Equatable { var v: Bool, k: Double, lo: Double, hi: Double }

    static func cuts(_ h: Numbers) -> [Cut] {
        (0..<Int(h["n"] ?? 0)).map { i in Cut(v: (h["v\(i)"] ?? 0) != 0, k: h["k\(i)"] ?? 0, lo: h["lo\(i)"] ?? 0, hi: h["hi\(i)"] ?? 0) }
    }
    static func store(_ cs: [Cut], take: Bool, into h: inout Numbers) {
        h = h.filter { !["n", "take", "bad"].contains($0.key) && !$0.key.hasPrefix("v") && !$0.key.hasPrefix("k") && !$0.key.hasPrefix("lo") && !$0.key.hasPrefix("hi") }
        h["n"] = Double(cs.count); if take { h["take"] = 1 }
        for (i, c) in cs.enumerated() { h["v\(i)"] = c.v ? 1 : 0; h["k\(i)"] = c.k; h["lo\(i)"] = c.lo; h["hi\(i)"] = c.hi }
    }
    /// The shape cut along each cut in turn (in units); the cuts that cut something.
    static func pieces(_ pts: [CGPoint], _ cs: [Cut]) -> (pieces: [[CGPoint]], kept: [Cut]) {
        var pcs = [pts], kept: [Cut] = []
        for c in cs {
            var done = false
            pcs = pcs.flatMap { pc -> [[CGPoint]] in
                guard !done, A7.chords(pc, vertical: c.v, at: c.k).contains(where: { abs($0.0 - c.lo) < 1e-3 && abs($0.1 - c.hi) < 1e-3 }) else { return [pc] }
                done = true
                return A7.split(pc, c.v ? CGPoint(x: c.k, y: c.lo) : CGPoint(x: c.lo, y: c.k), c.v ? CGPoint(x: c.k, y: c.hi) : CGPoint(x: c.hi, y: c.k))
            }
            if done { kept.append(c) }
        }
        return (pcs, kept)
    }
    /// What Cut makes of the hand's cuts: the pieces, in order (top first, then left), each as a Poly6 piece; or the
    /// indexes of the ones that are neither.
    static func parts(_ S: Shape, _ h: Numbers) -> (pieces: [(pts: [CGPoint], p: Poly6.Piece)], bad: [Int]) {
        if (h["take"] ?? 0) != 0, let r = S.S.takeRect, let t = S.S.takeCorner {
            let rp = r.map { CGPoint(x: Double($0.0), y: Double($0.1)) }, tp = t.map { CGPoint(x: Double($0.0), y: Double($0.1)) }
            var tri = A7.kind(tp) ?? Poly6.Piece(tri: true, w: 1, h: 1); tri.sign = -1
            return ([(rp, A7.kind(rp) ?? Poly6.Piece(tri: false, w: 1, h: 1)), (tp, tri)], [])
        }
        let pcs = pieces(S.pts, cuts(h)).pieces
        let ks = pcs.map(A7.kind)
        let bad = ks.indices.filter { ks[$0] == nil }
        guard bad.isEmpty else { return ([], bad) }
        let out = zip(pcs, ks).map { ($0, $1!) }.sorted { a, b in
            let p = A7.centroid(A7.simplify(a.0)), q = A7.centroid(A7.simplify(b.0))
            return abs(p.y - q.y) > 0.01 ? p.y < q.y : p.x < q.x
        }
        return (out.map { (pts: $0.0, p: $0.1) }, [])
    }
    /// The pieces Cut kept (with their corners).
    static func keptPieces(_ k: Numbers) -> [(pts: [CGPoint], p: Poly6.Piece)] {
        guard let ps = Poly6.pieces(k) else { return [] }
        return ps.enumerated().map { i, p in
            let n = Int(k["c\(i)n"] ?? 0)
            return ((0..<n).map { j in CGPoint(x: k["c\(i)x\(j)"] ?? 0, y: k["c\(i)y\(j)"] ?? 0) }, p)
        }
    }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let S = Shape(s.numbers), at = stage(s)
        switch at {
        case 1: return CGPoint(x: S.rx, y: 1)
        case 2, 3:
            let n = Self.keptPieces(s.run.kept).count, k = at == 3 ? n : min(Int(s.picture["k"] ?? 0), n)
            return CGPoint(x: S.rx, y: S.row(k) + 2)
        case 4: return CGPoint(x: S.rx, y: S.row(Self.keptPieces(s.run.kept).count) + 2)
        default: return nil
        }
    }
    func autoAnswer(_ s: PaperState) -> [String: Double]? {
        // a slot with no piece in it (a corner taken off is two pieces, where three have room): passed with nothing
        guard stage(s) == 2, Int(s.picture["k"] ?? 0) >= Self.keptPieces(s.run.kept).count else { return nil }
        return ["x": 0]
    }
    func keysFocus(_ s: PaperState) -> CGRect? { let S = Shape(s.numbers); return CGRect(x: S.X(0), y: 0, width: Double(S.S.width) * S.U, height: Double(S.S.height) * S.U) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let S = Shape(s.numbers), at = stage(s), U = S.U, pts = S.pts
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        var actions: [String] = []
        let kept = Self.keptPieces(s.run.kept)
        if at <= 1 {
            let cs = Self.cuts(s.hand), take = (s.h("take") ?? 0) != 0
            let res = take ? (pieces: [pts], kept: []) : Self.pieces(pts, cs)
            let bad = Set((0..<Int(s.h("nbad") ?? 0)).map { Int(s.h("bad\($0)") ?? -1) })
            for (j, pc) in res.pieces.enumerated() {
                let id = "pc\(pc.map { "\($0.x),\($0.y)" }.joined(separator: ";"))\(bad.contains(j))"
                A7.shape(&pic, id, S.sq(pc), line: bad.contains(j) ? A7.red : .chapter)
                A7.faint(&pic, id + "f", S.sq(pc), U: U, org: CGPoint(x: Self.X0, y: 0))
            }
            for c in res.kept {
                pic.line("cut\(c.v)\(c.k)_\(c.lo)", c.v ? [(S.X(c.k), S.Y(c.lo)), (S.X(c.k), S.Y(c.hi))] : [(S.X(c.lo), S.Y(c.k)), (S.X(c.hi), S.Y(c.k))], .chapter)
            }
            if let r = S.S.takeRect, let t = S.S.takeCorner {
                let tp = S.sq(t.map { CGPoint(x: Double($0.0), y: Double($0.1)) })
                A7.shape(&pic, "tk\(take)", tp, fill: take ? .tint(0.12) : nil, dashed: true)
                if take { pic.sketch.segments("tks", stripes(tp, &pic), .tint(0.6), width: Sketch.stroke) }
                _ = r
                for (k, g) in S.S.takeLegs.enumerated() { leg(&pic, "tl\(k)", g, S) }
            }
            for (k, g) in S.S.heights.enumerated() {
                let x = S.X(Double(g.0.0)), y0 = S.Y(Double(min(g.0.1, g.1.1))), y1 = S.Y(Double(max(g.0.1, g.1.1)))
                if g.0.0 == g.1.0 {
                    A7.height(&pic, "ht\(k)", x: x, from: g.0.1 < g.1.1 ? y0 : y1, to: g.0.1 < g.1.1 ? y1 : y0, toward: 1)
                    pic.label("htl\(k)", "\(abs(g.1.1 - g.0.1))", A7.words, .right, edge: x + 0.2, along: (y0 + y1) / 2)
                } else {
                    let y = S.Y(Double(g.0.1)), xa = S.X(Double(min(g.0.0, g.1.0))), xb = S.X(Double(max(g.0.0, g.1.0)))
                    pic.line("ht\(k)l", [(xa, y), (xb, y)], .ink2, dashed: true)
                    pic.label("htl\(k)", "\(abs(g.1.0 - g.0.0))", A7.words, .above, edge: y - 0.2, along: (xa + xb) / 2)
                }
            }
            // the cut being drawn, snapped to its grid line
            if s.grabbed, let x0 = s.h("x0"), let y0 = s.h("y0"), let x1 = s.h("x1"), let y1 = s.h("y1") {
                let vert = abs(y1 - y0) > abs(x1 - x0)
                if vert { let x = ((x0 + x1) / 2 - Self.X0) / U; let c = Self.X0 + x.rounded() * U; live.line("drag", [(c, y0), (c, y1)], .chapter, dashed: true) }
                else { let y = ((y0 + y1) / 2) / U; let c = y.rounded() * U; live.line("drag", [(x0, c), (x1, c)], .chapter, dashed: true) }
            }
            if at == 1 {
                actions = ["Cut"]
                if s.on("ring") { A7.ring(&pic, "ring", x: S.X(0), y: 0, w: Double(S.S.width) * U, h: Double(S.S.height) * U) }
                if s.on("spot") {
                    // one cut that works (the usual way's first)
                    if S.S.kind == .take { A7.shape(&pic, "spot", S.sq((S.S.takeCorner ?? []).map { CGPoint(x: Double($0.0), y: Double($0.1)) }), fill: nil, dashed: true) }
                    else if let c = Self.firstCut(S) { pic.line("spot", c.v ? [(S.X(c.k), S.Y(c.lo) - 1), (S.X(c.k), S.Y(c.hi) + 1)] : [(S.X(c.lo) - 1, S.Y(c.k)), (S.X(c.hi) + 1, S.Y(c.k))], .chapter, dashed: true) }
                }
            }
        } else {
            for (j, pc) in kept.enumerated() {
                let neg = pc.p.sign < 0, q = S.sq(pc.pts)
                A7.shape(&pic, "pt\(j)", q, fill: neg ? .tint(0.12) : A7.fill, dashed: neg)
                if neg { pic.sketch.segments("pts\(j)", stripes(q, &pic), .tint(0.6), width: Sketch.stroke) } else { A7.faint(&pic, "ptf\(j)", q, U: U, org: CGPoint(x: Self.X0, y: 0)) }
                name(&pic, "nm\(j)", pc.p, at: A7.centroid(A7.simplify(q)), room: Double(pc.p.w) * U)
                let lit = (at == 2 && Int(s.picture["k"] ?? 0) == j) || at == 3
                if lit && s.on("ring") { let xs = q.map(\.x), ys = q.map(\.y); A7.ring(&pic, "ring\(j)", x: xs.min()!, y: ys.min()!, w: xs.max()! - xs.min()!, h: ys.max()! - ys.min()!) }
            }
        }
        // the shape's straight sides named outside it
        for (j, e) in edgeLabels(pts).enumerated() {
            if e.h { pic.label("el\(j)_\(e.s)", "\(e.s)", A7.words, e.side, edge: S.Y(e.at), along: S.X(e.m)) }
            else { pic.label("el\(j)_\(e.s)", "\(e.s)", A7.words, e.side, edge: S.X(e.at), along: S.Y(e.m)) }
        }
        // the record beside: each piece, then the total
        if at >= 2 {
            let n = kept.count, k = at == 2 ? Int(s.picture["k"] ?? 0) : n
            for (j, pc) in kept.enumerated() where j <= k {
                let toks: [M7.Tok] = [.n(pc.p.w), .op("×"), .n(pc.p.h)] + (pc.p.tri ? [.op("÷"), .n(2)] : []) + [.op("=")]
                M7.row(&rec, "rp\(j)", toks + [j < k || at > 3 ? .n(pc.p.A, .chapter) : j == k && at == 2 ? .box("x", cells: max(2, "\(pc.p.A)".count)) : .n(pc.p.A, .chapter)], x: S.rx, line: S.row(j))
            }
            if at >= 3 {
                var toks: [M7.Tok] = []
                for (j, pc) in kept.enumerated() { if j > 0 { toks.append(.op(pc.p.sign < 0 ? "−" : "+")) }; toks.append(.n(pc.p.A)) }
                let total = kept.reduce(0) { $0 + $1.p.sign * $1.p.A }
                M7.row(&rec, "rs", toks + [.op("="), at == 3 ? .box("x", cells: max(2, "\(total)".count)) : .n(total, .chapter), .w("square units")], x: S.rx, line: S.row(n))
            }
        }
        let room = pic.R(-1, -2.5, max(S.rx + 30, S.X(Double(S.S.width)) + 3) + 1, Double(S.S.height) * U + 5)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, actions: actions, extent: room)
    }

    /// A piece's name in it: on one row, or two, or three when even "2 × 12" is wider than the piece.
    private func name(_ pen: inout GridPen, _ id: String, _ p: Poly6.Piece, at c: CGPoint, room: Double) {
        let one = "\(p.w) × \(p.h)\(p.tri ? " ÷ 2" : "")"
        let fits = { (t: String) in R6.width(t, A7.small.colour(.ink)) <= room * (p.tri ? 0.6 : 0.9) - 0.4 }
        let rows = fits(one) ? [one] : fits("\(p.w) × \(p.h)") ? ["\(p.w) × \(p.h)", "÷ 2"] : ["\(p.w)", "× \(p.h)"] + (p.tri ? ["÷ 2"] : [])
        for (k, r) in rows.enumerated() { pen.word("\(id)r\(k)", r, at: c.x, c.y + (Double(k) - Double(rows.count - 1) / 2) * 1.2, A7.small.colour(.ink)) }
    }
    /// Stripes across a shape a square apart (a corner taken away).
    private func stripes(_ q: [CGPoint], _ pen: inout GridPen) -> [(CGPoint, CGPoint)] {
        let xs = q.map(\.x), ys = q.map(\.y)
        guard let x0 = xs.min(), let x1 = xs.max(), let y0 = ys.min(), let y1 = ys.max() else { return [] }
        var out: [(CGPoint, CGPoint)] = []
        var t = x0 - (y1 - y0)
        while t < x1 {
            // the line x - y = t - y0 … clipped by sampling along it
            var inside: [CGPoint] = []
            for i in 0...40 {
                let u = Double(i) / 40, p = CGPoint(x: t + u * (y1 - y0), y: y1 - u * (y1 - y0))
                if A7.inside(q, p) { inside.append(p) }
            }
            if let a = inside.first, let b = inside.last, inside.count > 1 { out.append((pen.P(a.x, a.y), pen.P(b.x, b.y))) }
            t += 1
        }
        return out
    }
    private func leg(_ pen: inout GridPen, _ id: String, _ g: ((Int, Int), (Int, Int), Int), _ S: Shape) {
        let r = (S.S.takeRect ?? []).map { CGPoint(x: Double($0.0), y: Double($0.1)) }
        if g.0.1 == g.1.1 {
            let m = Double(g.0.0 + g.1.0) / 2
            pen.label(id, "\(g.2)", A7.words, A7.inside(r, CGPoint(x: m, y: Double(g.0.1) - 0.05)) ? .below : .above, edge: S.Y(Double(g.0.1)), along: S.X(m))
        } else {
            let m = Double(g.0.1 + g.1.1) / 2
            pen.label(id, "\(g.2)", A7.words, A7.inside(r, CGPoint(x: Double(g.0.0) - 0.05, y: m)) ? .right : .left, edge: S.X(Double(g.0.0)), along: S.Y(m))
        }
    }
    /// A straight side's length and where its label goes (outside the shape).
    private func edgeLabels(_ pts: [CGPoint]) -> [(s: Int, side: GridPen.Side, at: Double, m: Double, h: Bool)] {
        var out: [(s: Int, side: GridPen.Side, at: Double, m: Double, h: Bool)] = []
        for i in pts.indices {
            let a = pts[i], b = pts[(i + 1) % pts.count]
            if a.y == b.y && a.x != b.x { let m = (a.x + b.x) / 2; out.append((Int(abs(b.x - a.x)), A7.inside(pts, CGPoint(x: m, y: a.y - 0.05)) ? .below : .above, a.y, m, true)) }
            else if a.x == b.x && a.y != b.y { let m = (a.y + b.y) / 2; out.append((Int(abs(b.y - a.y)), A7.inside(pts, CGPoint(x: a.x - 0.05, y: m)) ? .right : .left, a.x, m, false)) }
        }
        return out
    }
    /// A cut that works: the usual way's first (for the hint and the ghost).
    static func firstCut(_ S: Shape) -> Cut? {
        for k in 1..<max(2, max(S.S.width, S.S.height)) {
            for v in [true, false] {
                for c in A7.chords(S.pts, vertical: v, at: Double(k)) {
                    let parts = A7.split(S.pts, v ? CGPoint(x: Double(k), y: c.0) : CGPoint(x: c.0, y: Double(k)), v ? CGPoint(x: Double(k), y: c.1) : CGPoint(x: c.1, y: Double(k)))
                    if parts.allSatisfy({ A7.kind($0) != nil }) { return Cut(v: v, k: Double(k), lo: c.0, hi: c.1) }
                }
            }
        }
        return nil
    }

    func hands(_ s: PaperState) -> Hands? {
        let S = Shape(s.numbers), U = S.U, pts = S.pts
        guard stage(s) == 1 else { return nil }
        let base = s.hand.filter { !["grab", "x0", "y0", "x1", "y1"].contains($0.key) }
        return Hands(grab: { q in
            let u = S.units(q)
            guard u.x > -1.3, u.x < Double(S.S.width) + 1.3, u.y > -1.3, u.y < Double(S.S.height) + 1.3 else { return nil }
            return base.merging(["grab": 1, "x0": q.x, "y0": q.y, "x1": q.x, "y1": q.y]) { $1 }
        }, drag: { q, hd in
            var hd = hd; hd["x1"] = q.x; hd["y1"] = q.y; return hd
        }, release: { hd in
            var out = hd.filter { !["grab", "x0", "y0", "x1", "y1", "nbad"].contains($0.key) && !$0.key.hasPrefix("bad") }
            let a = S.units(CGPoint(x: hd["x0"] ?? 0, y: hd["y0"] ?? 0)), z = S.units(CGPoint(x: hd["x1"] ?? 0, y: hd["y1"] ?? 0))
            let dx = z.x - a.x, dy = z.y - a.y, tol = 0.7 / U
            var cs = Self.cuts(hd), take = (hd["take"] ?? 0) != 0
            if hypot(dx, dy) * U < 0.8 {
                // a tap on a cut takes it back
                cs.removeAll { c in let ac = c.v ? z.x : z.y, al = c.v ? z.y : z.x; return abs(ac - c.k) < tol && al > c.lo - tol && al < c.hi + tol }
                if take, Self.dist(z, S.slant) < tol { take = false }
                Self.store(cs, take: take, into: &out); return HandMove(hand: out)
            }
            if S.S.kind == .take {
                let (p1, p2) = S.slant, len = hypot(p2.x - p1.x, p2.y - p1.y)
                if Self.dist(a, S.slant) < 1.2 / U + 0.3, Self.dist(z, S.slant) < 1.2 / U + 0.3, hypot(dx, dy) > 0.6 * len {
                    Self.store([], take: true, into: &out); return HandMove(hand: out)
                }
            }
            let vert = abs(dy) > abs(dx), k = (vert ? (a.x + z.x) / 2 : (a.y + z.y) / 2).rounded()
            let mid = vert ? (a.y + z.y) / 2 : (a.x + z.x) / 2, span = abs(vert ? dy : dx)
            var found: Cut?
            for pc in Self.pieces(pts, cs).pieces { for c in A7.chords(pc, vertical: vert, at: k) where mid > c.0 - 0.01 && mid < c.1 + 0.01 { found = Cut(v: vert, k: k, lo: c.0, hi: c.1) } }
            guard let f = found, span >= 0.6 * (f.hi - f.lo) else {
                Self.store(cs, take: take, into: &out)
                return HandMove(hand: out, missHand: out, set: [("k", -2)], check: true)
            }
            if !cs.contains(f) { cs.append(f) }
            Self.store(Self.pieces(pts, cs).kept, take: false, into: &out)
            return HandMove(hand: out)
        }, actions: ["Cut": {
            var out = base
            let r = Self.parts(S, base)
            if !r.bad.isEmpty {
                out["nbad"] = Double(r.bad.count); for (i, b) in r.bad.enumerated() { out["bad\(i)"] = Double(b) }
                return HandMove(hand: out, missHand: out, set: [("k", 0)], check: true)
            }
            var keep = Poly6.keep(r.pieces.map(\.p))
            for (i, pc) in r.pieces.enumerated() {
                keep["c\(i)n"] = Double(pc.pts.count)
                for (j, q) in pc.pts.enumerated() { keep["c\(i)x\(j)"] = q.x; keep["c\(i)y\(j)"] = q.y }
            }
            return HandMove(hand: out, missHand: out, set: [("k", 1)], keep: keep, check: true)
        }])
    }
    static func dist(_ q: CGPoint, _ s: (CGPoint, CGPoint)) -> Double {
        let (a, b) = s, dx = b.x - a.x, dy = b.y - a.y
        let u = max(0, min(1, ((q.x - a.x) * dx + (q.y - a.y) * dy) / (dx * dx + dy * dy)))
        return hypot(q.x - a.x - u * dx, q.y - a.y - u * dy)
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let S = Shape(s.numbers)
        guard stage(s) == 1 else { return [] }
        if S.S.kind == .take {
            let (a, b) = S.slant
            return [.drag(from: CGPoint(x: S.X(a.x), y: S.Y(a.y)), to: CGPoint(x: S.X(b.x), y: S.Y(b.y))), .tap(.action("Cut"))]
        }
        var moves: [GhostMove] = [], cs: [Cut] = []
        // cut until every piece is a rectangle or a triangle (a house takes two)
        for _ in 0..<3 {
            let pcs = Self.pieces(S.pts, cs).pieces
            guard let bad = pcs.first(where: { A7.kind($0) == nil }) else { break }
            guard let c = Self.firstCut(Shape(s.numbers), within: bad) else { break }
            cs.append(c)
            moves.append(c.v ? .drag(from: CGPoint(x: S.X(c.k), y: S.Y(c.lo)), to: CGPoint(x: S.X(c.k), y: S.Y(c.hi)))
                             : .drag(from: CGPoint(x: S.X(c.lo), y: S.Y(c.k)), to: CGPoint(x: S.X(c.hi), y: S.Y(c.k))))
        }
        return moves + [.tap(.action("Cut"))]
    }
    static func firstCut(_ S: Shape, within pc: [CGPoint]) -> Cut? {
        for k in 1..<max(2, max(S.S.width, S.S.height)) {
            for v in [true, false] {
                for c in A7.chords(pc, vertical: v, at: Double(k)) {
                    let parts = A7.split(pc, v ? CGPoint(x: Double(k), y: c.0) : CGPoint(x: c.0, y: Double(k)), v ? CGPoint(x: Double(k), y: c.1) : CGPoint(x: c.1, y: Double(k)))
                    if parts.allSatisfy({ A7.kind($0) != nil }) { return Cut(v: v, k: Double(k), lo: c.0, hi: c.1) }
                }
            }
        }
        // no single cut finishes it: one that leaves a rectangle or a triangle on one side
        for k in 1..<max(2, max(S.S.width, S.S.height)) {
            for v in [false, true] {
                for c in A7.chords(pc, vertical: v, at: Double(k)) {
                    let parts = A7.split(pc, v ? CGPoint(x: Double(k), y: c.0) : CGPoint(x: c.0, y: Double(k)), v ? CGPoint(x: Double(k), y: c.1) : CGPoint(x: c.1, y: Double(k)))
                    if parts.contains(where: { A7.kind($0) != nil }) { return Cut(v: v, k: Double(k), lo: c.0, hi: c.1) }
                }
            }
        }
        return nil
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        // Cut with nothing cut: the shape itself is neither (an L, a house, a rectangle with a corner off)
        guard stage(s) == 1 else { return nil }
        let S = Shape(s.numbers)
        if A7.kind(S.pts) == nil { return HandMove(hand: ["nbad": 1, "bad0": 0], missHand: ["nbad": 1, "bad0": 0], set: [("k", 0)], check: true) }
        return HandMove(hand: [:], set: [("k", -2)], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let kept = Self.keptPieces(s.run.kept)
        switch stage(s) {
        case 2:
            let k = Int(s.picture["k"] ?? 0)
            guard k < kept.count else { return nil }
            let p = kept[k].p
            return ["x": Double(p.tri ? p.w * p.h : p.w + p.h)]
        case 3:
            let S = kept.reduce(0) { $0 + $1.p.sign * $1.p.A }
            return ["x": Double(kept.contains { $0.p.sign < 0 } ? kept.reduce(0) { $0 + $1.p.A } : S + (kept.first?.p.A ?? 0))]
        default: return nil
        }
    }
}
