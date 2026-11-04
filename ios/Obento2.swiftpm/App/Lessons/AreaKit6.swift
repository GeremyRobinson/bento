import SwiftUI

/// What 6th grade's Area and volume lessons share (design/grade6.md chapter 7, the preview design/prototype/grade6-ch7.html):
/// a shape on the paper, its corners on grid points (filled however it bends, its outline in the chapter's colour), its
/// unit squares faint inside it (cut to its outline, finer than the one line weight), a height drawn dashed with its
/// square corner, and the geometry the hands need (inside or not, a grid line's stretches inside a shape, a shape split
/// along one).
@MainActor
enum A7 {
    static let small = R6.small, lit = R6.lit, maths = R6.maths, words = R6.words
    static let fill = Sketch.Colour.tint(0.22), strong = Sketch.Colour.tint(0.42), red = R6.red

    /// A shape in squares: filled (in triangles, so an L fills as an L), its outline over it, solid or dashed.
    static func shape(_ pen: inout GridPen, _ id: String, _ pts: [CGPoint], fill: Sketch.Colour? = A7.fill, line: Sketch.Colour = .chapter, dashed: Bool = false) {
        if let fill { for (k, t) in triangles(pts).enumerated() { pen.sketch.polygon("\(id)f\(k)", t.map { pen.P($0.x, $0.y) }, fill) } }
        pen.sketch.line(id + "o", (pts + [pts[0]]).map { pen.P($0.x, $0.y) }, line, width: Sketch.stroke, dashed: dashed)
    }
    /// A shape's unit squares, faint: the grid lines `U` squares apart (from `org`) where they run inside it.
    static func faint(_ pen: inout GridPen, _ id: String, _ pts: [CGPoint], U: Double, org: CGPoint = .zero) {
        let xs = pts.map(\.x), ys = pts.map(\.y)
        guard let x0 = xs.min(), let x1 = xs.max(), let y0 = ys.min(), let y1 = ys.max() else { return }
        var segs: [(CGPoint, CGPoint)] = []
        var x = org.x + ((x0 - org.x) / U + 1e-6).rounded(.up) * U
        while x < x1 - 1e-6 { for c in chords(pts, vertical: true, at: x) { segs.append((pen.P(x, c.0), pen.P(x, c.1))) }; x += U }
        var y = org.y + ((y0 - org.y) / U + 1e-6).rounded(.up) * U
        while y < y1 - 1e-6 { for c in chords(pts, vertical: false, at: y) { segs.append((pen.P(c.0, y), pen.P(c.1, y))) }; y += U }
        pen.sketch.segments(id, segs, .tint(0.45), width: 1)
    }
    /// A height: a dashed line from (x, y0) to (x, y1), its square corner where it meets the base (row y1), on the side
    /// `toward` (+1 right, −1 left).
    static func height(_ pen: inout GridPen, _ id: String, x: Double, from y0: Double, to y1: Double, toward: Double) {
        pen.line(id + "l", [(x, y0), (x, y1)], .ink2, dashed: true)
        let m = 0.6 * toward, up = y1 > y0 ? -0.6 : 0.6
        pen.line(id + "c", [(x + m, y1), (x + m, y1 + up), (x, y1 + up)], .ink2)
    }

    /// A hint's dashed ring round a shape, clear of the names on its sides.
    static func ring(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double) {
        R6.ring(&pen, id, x: x - 2, y: y - 2, w: w + 4, h: h + 4)
    }

    // MARK: geometry

    static func inside(_ pts: [CGPoint], _ q: CGPoint) -> Bool {
        var c = false, j = pts.count - 1
        for i in pts.indices {
            let a = pts[i], b = pts[j]
            if (a.y > q.y) != (b.y > q.y), q.x < (b.x - a.x) * (q.y - a.y) / (b.y - a.y) + a.x { c.toggle() }
            j = i
        }
        return c
    }
    /// The stretches of the line x = k (`vertical`) or y = k strictly inside a shape, along the line.
    static func chords(_ pts: [CGPoint], vertical: Bool, at k: Double) -> [(Double, Double)] {
        func at(_ K: Double) -> [(Double, Double)] {
            var xs: [Double] = []
            for i in pts.indices {
                let p = pts[i], q = pts[(i + 1) % pts.count]
                let pa = vertical ? p.x : p.y, qa = vertical ? q.x : q.y, pl = vertical ? p.y : p.x, ql = vertical ? q.y : q.x
                if (pa > K) != (qa > K) { xs.append(pl + (K - pa) * (ql - pl) / (qa - pa)) }
            }
            xs.sort()
            return stride(from: 0, to: xs.count - 1, by: 2).map { (xs[$0], xs[$0 + 1]) }
        }
        var out: [(Double, Double)] = []
        for a in at(k - 1e-7) { for b in at(k + 1e-7) {
            let lo = max(a.0, b.0), hi = min(a.1, b.1)
            if hi - lo > 1e-3 { out.append(((lo * 1e4).rounded() / 1e4, (hi * 1e4).rounded() / 1e4)) }
        } }
        return out
    }
    static func near(_ a: CGPoint, _ b: CGPoint) -> Bool { abs(a.x - b.x) < 1e-4 && abs(a.y - b.y) < 1e-4 }
    static func onSegment(_ x: CGPoint, _ a: CGPoint, _ b: CGPoint) -> Bool {
        abs((b.x - a.x) * (x.y - a.y) - (b.y - a.y) * (x.x - a.x)) < 1e-6 && x.x >= min(a.x, b.x) - 1e-6 && x.x <= max(a.x, b.x) + 1e-6
            && x.y >= min(a.y, b.y) - 1e-6 && x.y <= max(a.y, b.y) + 1e-6
    }
    /// A shape split along a chord from P to Q (both on its outline).
    static func split(_ pts: [CGPoint], _ P: CGPoint, _ Q: CGPoint) -> [[CGPoint]] {
        var v: [CGPoint] = []
        for i in pts.indices {
            let a = pts[i], b = pts[(i + 1) % pts.count]
            v.append(a)
            v += [P, Q].filter { onSegment($0, a, b) && !near($0, a) && !near($0, b) }.sorted { hypot($0.x - a.x, $0.y - a.y) < hypot($1.x - a.x, $1.y - a.y) }
        }
        guard let iP = v.firstIndex(where: { near($0, P) }), let iQ = v.firstIndex(where: { near($0, Q) }) else { return [pts] }
        func walk(_ s: Int, _ e: Int) -> [CGPoint] { var r: [CGPoint] = [], i = s; while true { r.append(v[i]); if i == e { break }; i = (i + 1) % v.count }; return r }
        return [walk(iP, iQ), walk(iQ, iP)]
    }
    /// Its corners with any in the middle of a straight side left out.
    static func simplify(_ pts: [CGPoint]) -> [CGPoint] {
        var r = pts.enumerated().filter { !near($0.element, pts[($0.offset + 1) % pts.count]) }.map(\.element)
        var again = true
        while again && r.count > 3 {
            again = false
            for i in r.indices {
                let a = r[(i + r.count - 1) % r.count], b = r[i], c = r[(i + 1) % r.count]
                if abs((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)) < 1e-6 { r.remove(at: i); again = true; break }
            }
        }
        return r
    }
    /// A rectangle or a right triangle with its legs along the grid (in units), or neither.
    static func kind(_ pts: [CGPoint]) -> Poly6.Piece? {
        let r = simplify(pts), xs = r.map(\.x), ys = r.map(\.y)
        guard let x0 = xs.min(), let x1 = xs.max(), let y0 = ys.min(), let y1 = ys.max() else { return nil }
        let w = Int((x1 - x0).rounded()), h = Int((y1 - y0).rounded())
        let ax = r.indices.map { i -> Bool in let p = r[i], q = r[(i + 1) % r.count]; return abs(p.x - q.x) < 1e-6 || abs(p.y - q.y) < 1e-6 }
        if r.count == 4 && ax.allSatisfy({ $0 }) { return Poly6.Piece(tri: false, w: w, h: h) }
        if r.count == 3 && ax.filter({ $0 }).count == 2 { return Poly6.Piece(tri: true, w: w, h: h) }
        return nil
    }
    static func centroid(_ pts: [CGPoint]) -> CGPoint {
        CGPoint(x: pts.map(\.x).reduce(0, +) / Double(max(1, pts.count)), y: pts.map(\.y).reduce(0, +) / Double(max(1, pts.count)))
    }
    /// A shape cut into triangles (ear clipping), for filling one that bends in.
    static func triangles(_ pts: [CGPoint]) -> [[CGPoint]] {
        var v = simplify(pts)
        guard v.count > 3 else { return [v] }
        // counter-clockwise on the screen's axes (y down): the signed area's sign
        let area = v.indices.reduce(0.0) { s, i in let a = v[i], b = v[(i + 1) % v.count]; return s + a.x * b.y - b.x * a.y }
        if area < 0 { v.reverse() }
        var out: [[CGPoint]] = [], guardCount = 0
        while v.count > 3 && guardCount < 200 {
            guardCount += 1
            var clipped = false
            for i in v.indices {
                let a = v[(i + v.count - 1) % v.count], b = v[i], c = v[(i + 1) % v.count]
                let cross = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
                guard cross > 1e-9 else { continue }
                let others = v.filter { !near($0, a) && !near($0, b) && !near($0, c) }
                if others.contains(where: { inside([a, b, c], $0) }) { continue }
                out.append([a, b, c]); v.remove(at: i); clipped = true; break
            }
            if !clipped { break }
        }
        out.append(v)
        return out
    }
}
