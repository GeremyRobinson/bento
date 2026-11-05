import SwiftUI

/// Perimeter on the paper, as in the preview (design/prototype/grade3-ch4.html, dPerim): a centimetre is 3 squares (2 for a
/// big shape, said in the first line), the shape drawn true size with the web's labels and a faint tick inside every side
/// at each cm. Trace the edge: the point walks round from the first corner (a rectangle's top left, a triangle's bottom
/// left), snapping to each cm tick and turning the corners; the walk so far is drawn in the chapter colour and the readout
/// sums each side walked ("7 + 4"); a side without a label gets one once it's walked ("7 cm, like the top"). Letting go
/// short keeps the walk; it goes on from there. A rectangle or triangle writes `7 + 4 = [11]` after two sides, then walks
/// the rest; then `7 + 4 + 7 + 4 = [22] cm`.
///
/// Hand: "grab", "t" the cm walked.
@MainActor
struct Perim3Lesson: PaperLesson {
    typealias Pt = Geo4.Pt
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let Y0 = 2.0
    /// Beside the shape while shape and labels are 48 squares wide or less; a wider one keeps its record under it.
    func recordBeside(_ n: Numbers) -> Double? {
        let P = Perim3.Parts(n), r = (Self.corners(P).map(\.x).max() ?? 0) + Double(P.label(1).split(separator: ",").map(\.count).max() ?? 4) * 0.52
        return r <= 48 ? Self.Y0 : nil
    }
    func messageRows(_ n: Numbers) -> Int { 2 }

    /// The shape's corners in the picture's squares, and the column its left labels need.
    static func corners(_ P: Perim3.Parts) -> [Pt] {
        let cl = Double(P.cell)
        var pts: [Pt]
        if P.kind < 2 {
            pts = [Pt(0, 0), Pt(Double(P.a) * cl, 0), Pt(Double(P.a) * cl, Double(P.b) * cl), Pt(0, Double(P.b) * cl)]
        } else {
            let a = Double(P.a), b = Double(P.b), c = Double(P.c), px = (a * a + c * c - b * b) / (2 * a)
            let hh = ((c * c - px * px).squareRoot() * cl).rounded()
            pts = [Pt(0, hh), Pt(a * cl, hh), Pt((px * cl).rounded(), 0)]
        }
        let last = P.label(P.S.count - 1), mx = pts.map(\.x).min() ?? 0
        let lw = Double(P.kind == 2 ? last.count : last.split(separator: ",").map(\.count).max() ?? 4) * 0.52 + 1.5
        let ox = ((lw - mx) / 5).rounded(.up) * 5
        return pts.map { Pt($0.x + ox, $0.y + Y0) }
    }
    static func point(_ pts: [Pt], _ P: Perim3.Parts, _ t: Int) -> Pt {
        let cum = P.cum, n = pts.count
        var k = 0
        while k < n - 1 && cum[k + 1] <= t { k += 1 }
        let u = min(1, Double(t - cum[k]) / Double(P.S[k])), a = pts[k], b = pts[(k + 1) % n]
        return Pt(a.x + (b.x - a.x) * u, a.y + (b.y - a.y) * u)
    }
    /// Where the walk starts and must reach on this step.
    static func span(_ P: Perim3.Parts, _ st: Int) -> (Int, Int) {
        let two = P.S[0] + P.S[1]
        switch st { case 0: return (0, two); case 1: return (two, two); case 2: return (P.kind == 1 ? 0 : two, P.P); default: return (P.P, P.P) }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Perim3.Parts(s.numbers), st = at(s), pts = Self.corners(P), n = pts.count, cum = P.cum
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let ring = s.on("ring") || s.on("spot"), spot = s.on("spot"), ch = Sketch.Colour.chapter
        let ctr = Pt(pts.map(\.x).reduce(0, +) / Double(n), pts.map(\.y).reduce(0, +) / Double(n))
        let (t0, end) = Self.span(P, st), walking = st == 0 || st == 2, t = walking ? Int((s.h("t") ?? Double(t0)).rounded()) : end
        G8.path(&pic, "shape", pts, .ink, closed: true)
        for k in 0..<n {
            let a = pts[k], b = pts[(k + 1) % n], dx = b.x - a.x, dy = b.y - a.y, L = (dx * dx + dy * dy).squareRoot()
            var nx = dy / L, ny = -dx / L
            if nx * ((a.x + b.x) / 2 - ctr.x) + ny * ((a.y + b.y) / 2 - ctr.y) < 0 { nx = -nx; ny = -ny }
            // a cm tick on every side, inside it
            var segs: [(CGPoint, CGPoint)] = []
            for j in 1..<P.S[k] {
                let u = Double(j) / Double(P.S[k]), mx = a.x + dx * u, my = a.y + dy * u
                segs.append((pic.P(mx, my), pic.P(mx - nx * 0.6, my - ny * 0.6)))
            }
            if !segs.isEmpty { pic.sketch.segments("tk\(k)", segs, .ink3, width: 1) }
            // its label outside it: the given ones from the start, the others once they're walked
            guard P.given[k] || t >= cum[k + 1] else { continue }
            let text = P.label(k), words = P.given[k] ? S3P.small : S3P.lit
            // beside an upright side, "7 cm, like the top" goes on two rows, so the shape keeps its width
            let rows = abs(nx) > 0.9 && text.contains(", like") ? [String(text.split(separator: ",")[0]) + ",", String(text.split(separator: ",")[1].dropFirst())] : [text]
            let w = rows.map { PaperText.width($0, PaperText.font(words.size, words.weight)) / Paper.cell }.max() ?? 1
            let off = 0.5 + abs(nx) * w / 2 + abs(ny) * 0.4
            for (j, r) in rows.enumerated() {
                let dy = rows.count == 1 ? 0 : (Double(j) - 0.5) * 1.1
                pic.word("lb\(k).\(j)", r, at: (a.x + b.x) / 2 + nx * off, (a.y + b.y) / 2 + ny * off + dy, words)
            }
        }
        // the walk so far, in colour, and the point
        var path: [Pt] = [pts[0]]
        for k in 1..<n where cum[k] <= t { path.append(pts[k]) }
        let q = Self.point(pts, P, t)
        path.append(q)
        if t > 0 { if walking { G8.path(&live, "walk", path, ch) } else { G8.path(&pic, "walk", path, ch) } }
        if walking {
            live.dot("pt", at: q.x, q.y, radius: s.grabbed ? 0.7 : 0.55)
            if s.grabbed {
                let parts = P.S.indices.map { max(0, min(P.S[$0], t - cum[$0])) }.filter { $0 > 0 }
                live.reads(parts.isEmpty ? "0" : parts.map(String.init).joined(separator: " + "))
            }
            if ring { pic.circle("hr", at: q.x, q.y, radius: 1.5, .chapter, dashed: true) }
            if spot { let e = Self.point(pts, P, end); pic.circle("sp", at: e.x, e.y, radius: 1.5, .chapter, dashed: true) }
        } else if st == 1 || st == 3 {
            let xs = pts.map(\.x), ys = pts.map(\.y)
            if ring { KK.hintBox(&pic, "hw", x: xs.min()!, y: ys.min()!, w: xs.max()! - xs.min()!, h: ys.max()! - ys.min()!) }
            if spot { S3P.count(&pic, "sp", "\(st == 1 ? P.a + P.b : P.P)", x: ctr.x - 1, y: ctr.y) }
        }

        // the record
        var line = 1.0
        if P.kind != 1 && st >= 1 {
            M7.row(&rec, "r0", [.n(P.a), .op("+"), .n(P.b), .op("="), M3.box("two", P.a + P.b, cells: 2, right: st >= 2)], x: 0, line: line)
            line += 3
        }
        if st >= 3 {
            var toks: [M7.Tok] = []
            if P.kind == 2 { toks = [.n(P.a + P.b), .op("+"), .n(P.c)] }
            else { for (k, v) in P.S.enumerated() { if k > 0 { toks.append(.op("+")) }; toks.append(.n(v)) } }
            toks += [.op("="), M3.box("P", P.P, cells: 2, right: st == 4), .w("cm")]
            M7.row(&rec, "r1", toks, x: 0, line: line)
        }
        let xs = pts.map(\.x), ys = pts.map(\.y)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes,
                            extent: pic.R(0, 0, xs.max()! + 1, ys.max()! + 2))
    }

    func hands(_ s: PaperState) -> Hands? {
        let st = at(s)
        guard st == 0 || st == 2 else { return nil }
        let P = Perim3.Parts(s.numbers), pts = Self.corners(P), n = pts.count, cum = P.cum, (t0, end) = Self.span(P, st)
        let t = Int((s.h("t") ?? Double(t0)).rounded())
        return Hands(
            grab: { c in let q = Self.point(pts, P, t); return hypot(c.x - q.x, c.y - q.y) <= 2.5 ? ["grab": 1, "t": Double(t)] : nil },
            drag: { c, h in
                // along this side and round the next corner, to the tick nearest the finger
                let now = Int((h["t"] ?? Double(t)).rounded())
                var k = 0
                while k < n - 1 && cum[k + 1] <= now { k += 1 }
                let hi = min(end, cum[min(n, k + 2)])
                var best = now, bd = Double.infinity
                if now <= hi {
                    for u in now...hi { let q = Self.point(pts, P, u), d = hypot(c.x - q.x, c.y - q.y); if d < bd { bd = d; best = u } }
                }
                return ["grab": 1, "t": Double(best)]
            },
            release: { h in
                let u = Int((h["t"] ?? 0).rounded())
                guard u >= end else { return HandMove(hand: ["t": Double(u)]) }
                return HandMove(hand: ["t": Double(u)], missHand: ["t": Double(u)], set: [("t", Double(u))], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let st = at(s)
        guard st == 0 || st == 2 else { return [] }
        let P = Perim3.Parts(s.numbers), pts = Self.corners(P), (t0, end) = Self.span(P, st)
        let t = Int((s.h("t") ?? Double(t0)).rounded())
        guard t < end else { return [] }
        return [.path((t...end).map { let q = Self.point(pts, P, $0); return CGPoint(x: q.x, y: q.y) })]
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Perim3.Parts(s.numbers)
        switch at(s) {
        case 1: return ["two": Double(P.a * P.b)]
        case 3: return ["P": Double(P.kind == 1 ? 2 * P.a : P.a + P.b)]
        default: return nil
        }
    }
}
