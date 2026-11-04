import SwiftUI

/// What Kindergarten's Shapes chapter shares on the paper (the preview design/prototype/gradeK-ch2.html): shapes as
/// polygons whose corners sit on the paper's crossings, a side lit as a band along it, the number that counts a side or
/// a corner written just outside it, word blocks to tap (a shape's name, rolls or slides), the stick that lays itself on
/// each side in turn, and the record's lines. Solids (3D) are in SolidsKitK.
@MainActor
enum KS {
    typealias Pt = (Double, Double)
    static let lit = Sketch.Colour.tint(0.42), fill = Sketch.Colour.tint(0.2), red = Bars.red

    // MARK: polygons

    static func cg(_ p: [Pt]) -> [CGPoint] { p.map { CGPoint(x: $0.0, y: $0.1) } }
    /// A polygon filled, in squares.
    static func poly(_ pen: inout GridPen, _ id: String, _ p: [Pt], _ colour: Sketch.Colour) { pen.sketch.polygon(id, p.map { pen.P($0.0, $0.1) }, colour) }
    /// A polygon's outline, closed.
    static func outline(_ pen: inout GridPen, _ id: String, _ p: [Pt], _ colour: Sketch.Colour = .ink, dashed: Bool = false) {
        guard let f = p.first else { return }
        pen.line(id, p + [f], colour, dashed: dashed)
    }
    static func area2(_ p: [Pt]) -> Double { p.indices.reduce(0) { s, i in let a = p[i], b = p[(i + 1) % p.count]; return s + a.0 * b.1 - b.0 * a.1 } }
    static func centroid(_ p: [Pt]) -> Pt { (p.map(\.0).reduce(0, +) / Double(max(1, p.count)), p.map(\.1).reduce(0, +) / Double(max(1, p.count))) }
    /// The way out of the shape from side i (corner i to i + 1).
    static func sideOut(_ p: [Pt], _ i: Int) -> Pt {
        let a = p[i], b = p[(i + 1) % p.count], dx = b.0 - a.0, dy = b.1 - a.1, l = max(1e-9, hypot(dx, dy)), s = area2(p) > 0 ? 1.0 : -1
        return (s * dy / l, -s * dx / l)
    }
    /// The way out of the shape from corner i (between its two sides').
    static func cornerOut(_ p: [Pt], _ i: Int) -> Pt {
        let n = p.count, a = sideOut(p, (i - 1 + n) % n), b = sideOut(p, i), x = a.0 + b.0, y = a.1 + b.1, l = max(1e-9, hypot(x, y))
        return (x / l, y / l)
    }
    /// The middle of side i, `out` squares outside it.
    static func sideLabel(_ p: [Pt], _ i: Int, out: Double = 2.3) -> Pt {
        let a = p[i], b = p[(i + 1) % p.count], o = sideOut(p, i)
        return ((a.0 + b.0) / 2 + o.0 * out, (a.1 + b.1) / 2 + o.1 * out)
    }
    static func cornerLabel(_ p: [Pt], _ i: Int, out: Double = 2.6) -> Pt { let o = cornerOut(p, i); return (p[i].0 + o.0 * out, p[i].1 + o.1 * out) }
    /// How far a point is from a segment.
    static func segDist(_ q: Pt, _ a: Pt, _ b: Pt) -> Double {
        let dx = b.0 - a.0, dy = b.1 - a.1, l2 = dx * dx + dy * dy
        let u = l2 > 0 ? max(0, min(1, ((q.0 - a.0) * dx + (q.1 - a.1) * dy) / l2)) : 0
        return hypot(q.0 - a.0 - u * dx, q.1 - a.1 - u * dy)
    }
    static func inside(_ q: Pt, _ p: [Pt]) -> Bool { PutShapes.inside(q, p) }
    /// A band along a side (how a side lights), `w` squares each side of it.
    static func band(_ a: Pt, _ b: Pt, w: Double = 0.55) -> [Pt] {
        let dx = b.0 - a.0, dy = b.1 - a.1, l = max(1e-9, hypot(dx, dy)), nx = -dy / l * w, ny = dx / l * w
        return [(a.0 + nx, a.1 + ny), (b.0 + nx, b.1 + ny), (b.0 - nx, b.1 - ny), (a.0 - nx, a.1 - ny)]
    }
    /// Side i lit: a band just outside it (so it never lies over the shape's own fill), `w` squares wide.
    static func edge(_ p: [Pt], _ i: Int, w: Double = 0.8) -> [Pt] {
        let a = p[i], b = p[(i + 1) % p.count], o = sideOut(p, i)
        return [a, b, (b.0 + o.0 * w, b.1 + o.1 * w), (a.0 + o.0 * w, a.1 + o.1 * w)]
    }
    /// A polygon turned by `a` radians about `c`.
    static func turned(_ p: [Pt], by a: Double, about c: Pt) -> [Pt] {
        let co = cos(a), si = sin(a)
        return p.map { (c.0 + ($0.0 - c.0) * co - ($0.1 - c.1) * si, c.1 + ($0.0 - c.0) * si + ($0.1 - c.1) * co) }
    }
    /// A circle's outline as points.
    static func circlePts(_ c: Pt, _ r: Double, _ n: Int = 48) -> [Pt] { (0..<n).map { i in let a = Double(i) / Double(n) * 2 * .pi; return (c.0 + r * cos(a), c.1 + r * sin(a)) } }
    static func kind(_ p: [Pt], _ pen: GridPen, over: Bool = false) -> Sketch.Kind { over ? .plate(p.map { pen.P($0.0, $0.1) }) : .fill(p.map { pen.P($0.0, $0.1) }) }

    // MARK: the stick

    /// The stick (a square's or rectangle's first side, lifted off): it lies on side 0, then lays itself on each side in
    /// turn (Sketch.vias, a beat each); each side it fits stays lit, and on a shorter side the part that hangs past is
    /// marked, dashed. Returns how long it takes.
    @discardableResult
    static func stick(_ pen: inout GridPen, _ id: String, _ p: [Pt], start: Double) -> Double {
        guard p.count >= 3 else { return 0 }
        let n = p.count, len = { (i: Int) in hypot(p[(i + 1) % n].0 - p[i].0, p[(i + 1) % n].1 - p[i].1) }, L = len(0)
        /// Where the stick lies on side i: from its start, or, on a shorter side, from whichever end leaves what hangs
        /// past it lower on the paper (never up through the words).
        func lay(_ i: Int) -> (from: Pt, to: Pt, end: Pt) {
            let a = p[i], b = p[(i + 1) % n], d = (b.0 - a.0, b.1 - a.1), l = max(1e-9, hypot(d.0, d.1)), u = (d.0 / l, d.1 / l)
            let fwd = (a.0 + u.0 * L, a.1 + u.1 * L), back = (b.0 - u.0 * L, b.1 - u.1 * L)
            if abs(l - L) < 0.01 || fwd.1 > back.1 + 0.01 || (abs(fwd.1 - back.1) <= 0.01 && fwd.0 >= back.0) { return (a, fwd, b) }
            return (b, back, a)
        }
        func on(_ i: Int) -> [Pt] { let w = lay(i); return band(w.from, w.to, w: 0.7) }
        let beat = SketchDrawer.morphTime + SketchDrawer.viaRest
        for i in 0..<n {
            pen.sketch.startAt = start + max(0, Double(i) * beat - SketchDrawer.viaRest)
            // a side it fits stays lit (on a shorter one, the stick itself hangs past it while it's there)
            if abs(len(i) - L) < 0.01 { poly(&pen, "\(id)fit\(i)", edge(p, i), lit) }
        }
        pen.sketch.startAt = start
        // round every side, and home again to the side it came from
        pen.sketch.from["\(id)s"] = kind(on(0), pen, over: true)
        pen.sketch.via["\(id)s"] = kind(on(1), pen, over: true)
        pen.sketch.vias["\(id)s"] = (2..<n).map { kind(on($0), pen, over: true) }
        pen.sketch.plate("\(id)s", on(0).map { pen.P($0.0, $0.1) }, .tint(0.7))
        pen.sketch.from = [:]; pen.sketch.via = [:]; pen.sketch.vias = [:]; pen.sketch.startAt = nil
        return Double(n) * beat
    }

    // MARK: word blocks

    /// Word blocks to tap: each a block `w` squares wide and 4 tall, in a column (5 apart), a row (`w` + 1 apart) or two
    /// by two. The wrong one tapped is red (red only for wrong); a hint rings one (`spot`) or all of them (`ring`).
    enum Lay { case column, row, grid }
    static func rects(_ count: Int, x: Double, y: Double, w: Double, _ lay: Lay) -> [CGRect] {
        (0..<count).map { j in
            switch lay {
            case .column: CGRect(x: x, y: y + Double(j) * 5, width: w, height: 4)
            case .row: CGRect(x: x + Double(j) * (w + 1), y: y, width: w, height: 4)
            case .grid: CGRect(x: x + Double(j % 2) * (w + 1), y: y + Double(j / 2) * 5, width: w, height: 4)
            }
        }
    }
    static func blocks(_ pen: inout GridPen, _ id: String, _ words: [String], _ r: [CGRect], wrong: Int? = nil, spot: Int? = nil, ring: Bool = false, picked: Int? = nil) {
        for (j, s) in words.enumerated() where j != wrong {
            if picked == j { pen.fill("\(id)p\(j)", col: r[j].minX, row: r[j].minY, w: r[j].width, h: r[j].height, fill) }
            pen.sketch.box("\(id)b\(j)", pen.R(r[j].minX, r[j].minY, r[j].width, r[j].height), .ink, width: Sketch.stroke)
            pen.word("\(id)t\(j)", s, at: r[j].midX, r[j].midY, KK.words)
        }
        // the wrong one last, so its red edges lie over its neighbours'
        if let j = wrong, words.indices.contains(j) {
            pen.sketch.box("\(id)x\(j)", pen.R(r[j].minX, r[j].minY, r[j].width, r[j].height), red, width: Sketch.stroke)
            pen.word("\(id)xt\(j)", words[j], at: r[j].midX, r[j].midY, KK.words.colour(red))
        }
        if ring, let a = r.first, let b = r.last { KK.hintBox(&pen, "\(id)ring", x: a.minX, y: a.minY, w: b.maxX - a.minX, h: b.maxY - a.minY) }
        if let j = spot, r.indices.contains(j) { KK.hintBox(&pen, "\(id)spot", x: r[j].minX, y: r[j].minY, w: r[j].width, h: r[j].height) }
    }
    static func hit(_ q: CGPoint, _ r: [CGRect]) -> Int? { r.firstIndex { $0.contains(q) } }

    // MARK: the record

    /// A record line of words (maths size), numbers in the chapter's colour, from (x, line's middle).
    static func line(_ pen: inout GridPen, _ id: String, _ toks: [M7.Tok], x: Double, line: Double) { _ = M7.row(&pen, id, toks, x: x, line: line) }
    /// "3 sides · 3 corners".
    static func sidesCorners(_ n: Int) -> [M7.Tok] { [.n(n, .chapter), .w("sides ·"), .n(n, .chapter), .w("corners")] }
}
