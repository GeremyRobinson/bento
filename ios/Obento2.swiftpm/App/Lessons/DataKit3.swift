import SwiftUI

/// What 3rd grade's chapter 7, Data, shares on the paper (the preview design/prototype/grade3-ch7.html): the graph (its
/// title, four rows 4 squares tall 6 apart with their names at the left, and under them the scale, a line every 6 squares
/// 0–8 lines, or the key, a picture a 4-square cell up to 9 in a row); a picture graph's pictures (a star, an apple, a
/// paw, a cookie; half a picture is its left half); the bars; how many more (the shorter one's end dropped across the
/// longer one, the extra bracketed); an inch ruler marked in halves and fourths; an X in its cell; the things measured.
@MainActor
enum DK3 {
    static let say = KK.words
    static let small = F3P.small
    static let smallLit = KK.lit
    static let faint = Sketch.Colour.ink3

    /// The graph's squares: the title row, the rows' top, the names' right edge, the scale's row, the record's row.
    struct Graph {
        let type: Int
        static let TT = 1.0, BY = 3.0, GX = 10.0, AY = 26.0, RY = 32.0
        var GX: Double { Self.GX }
        var AY: Double { Self.AY }
        var W: Double { type == 1 ? 48 : 36 }
        /// A picture's cell, or a line's squares.
        var per: Double { type == 1 ? 6 : 4 }
        func row(_ j: Int) -> Double { Self.BY + 6 * Double(j) }
        /// A count's length along its row, in squares.
        func len(_ c: Int, _ s: Int) -> Double { Double(c) / Double(s) * per }
        /// The row under a point, or nil.
        func rowAt(_ q: CGPoint) -> Int? {
            let j = Int(((q.y - Self.BY + 1) / 6).rounded(.down))
            guard j >= 0, j < 4, q.y >= row(j) - 1, q.y <= row(j) + 5 else { return nil }
            return j
        }
    }

    /// The title, the axis and the scale (its numbers lit in the chapter colour), or the key.
    static func base(_ pen: inout GridPen, _ G: Graph, _ th: Data3.Theme, s: Int, lit: Bool = false) {
        pen.word("gtitle", th.title, at: G.GX + G.W / 2, Graph.TT, say)
        pen.line("gax", [(G.GX, Graph.BY - 1), (G.GX, G.AY)])
        if G.type == 1 {
            var segs: [(CGPoint, CGPoint)] = []
            for k in 1...8 { segs.append((pen.P(G.GX + 6 * Double(k), Graph.BY - 1), pen.P(G.GX + 6 * Double(k), G.AY))) }
            pen.sketch.segments("gl", segs, faint, width: 1)
            pen.line("gsc", [(G.GX, G.AY), (G.GX + G.W, G.AY)])
            var ticks: [(CGPoint, CGPoint)] = []
            for k in 0...8 { ticks.append((pen.P(G.GX + 6 * Double(k), G.AY), pen.P(G.GX + 6 * Double(k), G.AY + 0.8))) }
            pen.sketch.segments("gt", ticks, .ink, width: Sketch.stroke)
            for k in 0...8 { pen.label("gn\(k)\(lit)", "\(k * s)", lit ? smallLit : small, .below, edge: G.AY + 0.8, along: G.GX + 6 * Double(k)) }
        } else {
            icon(&pen, "gkey", th.icon, G.GX + 2, G.AY + 1, sc: 0.8)
            pen.word("gkeyt", "= \(s) \(th.things)", at: G.GX + 4, G.AY + 1, say, anchor: UnitPoint(x: 0, y: 0.5))
        }
    }
    /// A row's name at the left of the graph, level with its middle.
    static func name(_ pen: inout GridPen, _ G: Graph, _ j: Int, _ text: String) {
        pen.word("nm\(j)", text, at: G.GX - 0.5, G.row(j) + 2, say, anchor: UnitPoint(x: 1, y: 0.5))
    }
    /// A row of n2 half pictures; `worth`: each picture sits up and says what it's worth, small.
    static func picRow(_ pen: inout GridPen, _ id: String, _ G: Graph, _ j: Int, _ n2: Int, _ th: Data3.Theme, s: Int, worth: Bool) {
        let y = G.row(j)
        var p = 0
        while p * 2 < n2 {
            let half = p * 2 + 1 == n2, cx = G.GX + 4 * Double(p) + 2
            if worth {
                icon(&pen, "\(id)i\(p)w", th.icon, cx, y + 1.5, sc: 0.8, half: half)
                pen.word("\(id)v\(p)\(half)", half ? "\(s / 2)" : "\(s)", at: half ? cx - 1 : cx, y + 3.35, smallLit)
            } else { icon(&pen, "\(id)i\(p)", th.icon, cx, y + 2, sc: 1.05, half: half) }
            p += 1
        }
    }
    /// A bar L squares long on row j: tinted (strong once it's read or done), its outline in the chapter colour.
    static func bar(_ pen: inout GridPen, _ id: String, _ G: Graph, _ j: Int, _ L: Double, strong: Bool) {
        guard L > 0 else { return }
        pen.fill("\(id)f\(strong)", col: G.GX, row: G.row(j), w: L, h: 4, strong ? .tint(0.4) : .tint(0.2))
        pen.sketch.box("\(id)o", pen.R(G.GX, G.row(j), L, 4), .chapter, width: Sketch.stroke)
    }
    /// How many more: the shorter one's end drops a dashed line across the longer one; the extra is bracketed under
    /// the longer row (over it when it's the last row).
    static func moreMarks(_ pen: inout GridPen, _ id: String, _ G: Graph, longer jl: Int, shorter js: Int, _ Ll: Double, _ Ls: Double) {
        let dn = jl < 3, by = dn ? G.row(jl) + 4.8 : G.row(jl) - 0.8, t = dn ? -0.6 : 0.6, xs = G.GX + Ls, xe = G.GX + Ll
        let top = min(G.row(jl), G.row(js)) - 0.6, bot = max(G.row(jl), G.row(js)) + 4.6
        pen.line("\(id)cut", [(xs, top), (xs, bot)], .chapter, dashed: true)
        pen.line("\(id)br", [(xs, by + t), (xs, by), (xe, by), (xe, by + t)], .chapter)
    }

    // MARK: the pictures

    private static func circle(_ cx: Double, _ cy: Double, _ r: Double, _ n: Int = 24) -> [CGPoint] {
        (0...n).map { i in let a = Double(i) / Double(n) * 2 * .pi; return CGPoint(x: cx + r * cos(a), y: cy + r * sin(a)) }
    }
    private static func cubic(_ a: CGPoint, _ c1: CGPoint, _ c2: CGPoint, _ b: CGPoint, _ n: Int = 12) -> [CGPoint] {
        (1...n).map { i in let t = Double(i) / Double(n), u = 1 - t
            return CGPoint(x: u * u * u * a.x + 3 * u * u * t * c1.x + 3 * u * t * t * c2.x + t * t * t * b.x,
                           y: u * u * u * a.y + 3 * u * u * t * c1.y + 3 * u * t * t * c2.y + t * t * t * b.y) }
    }
    /// A picture's outlines in squares about its middle (the first its body, tinted): 2nd grade's, and a star and a paw.
    static func shapes(_ name: String) -> [[CGPoint]] {
        switch name {
        case "star":
            var pts: [CGPoint] = []
            for i in 0..<10 {
                let a = (-90 + 36 * Double(i)) * Double.pi / 180, r = i % 2 == 1 ? 0.62 : 1.5
                pts.append(CGPoint(x: r * cos(a), y: r * sin(a) + 0.12))
            }
            pts.append(pts[0])
            return [pts]
        case "paw":
            func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
            var body = [p(0, -0.05)]
            body += cubic(p(0, -0.05), p(0.75, -0.05), p(1.15, 0.75), p(1.05, 1.05))
            body += cubic(p(1.05, 1.05), p(0.9, 1.4), p(0.4, 1.25), p(0, 1.25))
            body += cubic(p(0, 1.25), p(-0.4, 1.25), p(-0.9, 1.4), p(-1.05, 1.05))
            body += cubic(p(-1.05, 1.05), p(-1.15, 0.75), p(-0.75, -0.05), p(0, -0.05))
            return [body, circle(-1.1, -0.35, 0.34, 12), circle(-0.42, -1.0, 0.34, 12), circle(0.42, -1.0, 0.34, 12), circle(1.1, -0.35, 0.34, 12)]
        default: return L5.shapes(name)
        }
    }
    /// The part of a polygon left of its middle (x ≤ 0), closed again along the cut.
    private static func leftHalf(_ pts: [CGPoint]) -> [CGPoint] {
        var out: [CGPoint] = []
        guard pts.count > 1 else { return pts }
        for i in 0..<pts.count {
            let a = pts[i], b = pts[(i + 1) % pts.count], ain = a.x <= 0, bin = b.x <= 0
            if ain { out.append(a) }
            if ain != bin {
                let t = (0 - a.x) / (b.x - a.x)
                out.append(CGPoint(x: 0, y: a.y + (b.y - a.y) * t))
            }
        }
        return out
    }
    /// The runs of a polyline left of the middle, each cut at the middle.
    private static func leftRuns(_ pts: [CGPoint]) -> [[CGPoint]] {
        var out: [[CGPoint]] = [], cur: [CGPoint] = []
        for i in 0..<pts.count {
            let a = pts[i]
            if a.x <= 0 { cur.append(a) }
            if i + 1 < pts.count {
                let b = pts[i + 1]
                if (a.x <= 0) != (b.x <= 0) {
                    let t = (0 - a.x) / (b.x - a.x), m = CGPoint(x: 0, y: a.y + (b.y - a.y) * t)
                    cur.append(m)
                    if a.x <= 0 { out.append(cur); cur = [] }
                }
            }
        }
        if cur.count > 1 { out.append(cur) }
        return out
    }
    /// A picture centred at (cx, cy), `sc` squares a unit: its body tinted, its lines in the chapter colour (a paw's toes
    /// tinted too). `half`: only its left half. `edge`: another colour for its lines (red: one too many).
    static func icon(_ pen: inout GridPen, _ id: String, _ name: String, _ cx: Double, _ cy: Double, sc: Double = 1, half: Bool = false, edge: Sketch.Colour = .chapter) {
        let s = shapes(name)
        func pts(_ l: [CGPoint]) -> [CGPoint] { l.map { pen.P(cx + $0.x * sc, cy + $0.y * sc) } }
        for (k, l) in s.enumerated() {
            let filled = k == 0 || name == "paw"
            if half {
                if filled {
                    let h = leftHalf(l)
                    if h.count > 2 { pen.sketch.polygon("\(id)f\(k)h", pts(h), .tint(0.2)); pen.sketch.line("\(id)l\(k)h", pts(h + [h[0]]), edge, width: Sketch.stroke) }
                } else {
                    for (r, run) in leftRuns(l).enumerated() { pen.sketch.line("\(id)l\(k)r\(r)", pts(run), edge, width: Sketch.stroke) }
                }
            } else {
                if filled { pen.sketch.polygon("\(id)f\(k)", pts(l), .tint(0.2)) }
                pen.sketch.line("\(id)l\(k)", pts(l), edge, width: Sketch.stroke)
            }
        }
    }

    // MARK: line plots

    /// An inch ruler: a strip 3 squares tall from 0 to `max` inches, `per` squares an inch; its marks hang from its top
    /// edge (inches long, halves middle, fourths short; `to` 2 leaves the fourths off) and the inches are numbered in it
    /// (`lit`: that inch in the chapter colour).
    static func ruler(_ pen: inout GridPen, _ id: String, x0: Double, y: Double, per: Double, max: Int, to: Int, lit: Int? = nil) {
        pen.sketch.box(id + "s", pen.R(x0 - 1, y, per * Double(max) + 2, 3), .ink, width: Sketch.stroke)
        var segs: [(CGPoint, CGPoint)] = []
        for i in 0...(max * 4) {
            if to == 2 && i % 2 == 1 { continue }
            let h = i % 4 == 0 ? 1.6 : (i % 2 == 0 ? 1.1 : 0.6), x = x0 + Double(i) * per / 4
            segs.append((pen.P(x, y), pen.P(x, y + h)))
        }
        pen.sketch.segments(id + "m", segs, .ink, width: Sketch.stroke)
        for v in 0...max { pen.word("\(id)n\(v)\(lit == v)", "\(v)", at: x0 + Double(v) * per, y + 2.35, lit == v ? smallLit : small) }
    }
    /// An X in its cell (3 squares wide, 2 tall), centred over its mark.
    static func xMark(_ pen: inout GridPen, _ id: String, cx: Double, top: Double, _ c: Sketch.Colour = .ink) {
        pen.line(id + "a", [(cx - 0.6, top + 0.35), (cx + 0.6, top + 1.65)], c)
        pen.line(id + "b", [(cx - 0.6, top + 1.65), (cx + 0.6, top + 0.35)], c)
    }
    /// A thing measured, lying from column x0 to x1 (its very end), its top on row y, 2 squares tall, softly tinted: a
    /// crayon (2nd grade's), a leaf, a shell or a bug.
    static func thing(_ pen: inout GridPen, _ id: String, _ name: String, x0: Double, x1: Double, y: Double) {
        if name == "crayon" { LN2.thing(&pen, id, "crayon", x0: x0, x1: x1, y: y); return }
        let K = "\(id)\(name)\(x0):\(x1)", m = y + 1
        var pts: [CGPoint] = []
        switch name {
        case "leaf":
            for k in 0...12 { let t = Double(k) / 12, u = 1 - t; pts.append(pen.P(u * u * x0 + 2 * u * t * (x0 + x1) / 2 + t * t * x1, u * u * m + 2 * u * t * (y - 0.9) + t * t * m)) }
            for k in 1...12 { let t = Double(k) / 12, u = 1 - t; pts.append(pen.P(u * u * x1 + 2 * u * t * (x0 + x1) / 2 + t * t * x0, u * u * m + 2 * u * t * (y + 2.9) + t * t * m)) }
            pen.sketch.polygon(K + "f", pts, .tint(0.2)); pen.sketch.line(K + "o", pts, .ink, width: Sketch.stroke)
            pen.line(K + "r", [(x0 + 0.5, m), (x1 - 1, m)])
        case "shell":
            pts.append(pen.P(x0, y + 1.9))
            for k in 1...10 { let t = Double(k) / 10, u = 1 - t; pts.append(pen.P(u * u * x0 + 2 * u * t * (x0 + 0.4) + t * t * (x0 + x1) / 2, u * u * (y + 1.9) + 2 * u * t * (y + 0.1) + t * t * (y + 0.1))) }
            for k in 1...10 { let t = Double(k) / 10, u = 1 - t; pts.append(pen.P(u * u * (x0 + x1) / 2 + 2 * u * t * (x1 - 0.4) + t * t * x1, u * u * (y + 0.1) + 2 * u * t * (y + 0.1) + t * t * (y + 1.9))) }
            pts.append(pts[0])
            pen.sketch.polygon(K + "f", pts, .tint(0.2)); pen.sketch.line(K + "o", pts, .ink, width: Sketch.stroke)
            var ridges: [(CGPoint, CGPoint)] = []
            for i in 1..<4 { let x = x0 + (x1 - x0) * Double(i) / 4; ridges.append((pen.P(x, y + 0.5), pen.P(x, y + 1.9))) }
            pen.sketch.segments(K + "r", ridges, .ink3, width: Sketch.stroke)
        default: // a bug: a long body, a round head at the far end, legs
            let hx = x1 - 0.8, bx1 = hx - 0.7, r = 0.6
            var body: [CGPoint] = []
            for k in 0...8 { let a = -Double.pi / 2 + Double(k) / 8 * .pi; body.append(pen.P(bx1 - r + r * cos(a), m + r * sin(a))) }
            for k in 0...8 { let a = Double.pi / 2 + Double(k) / 8 * .pi; body.append(pen.P(x0 + r + r * cos(a), m + r * sin(a))) }
            body.append(body[0])
            pen.sketch.polygon(K + "bf", body, .tint(0.2)); pen.sketch.line(K + "bo", body, .ink, width: Sketch.stroke)
            let head = circle(0, 0, 1, 20).map { pen.P(hx + 0.8 * $0.x, m + 0.8 * $0.y) }
            pen.sketch.polygon(K + "hf", head, .tint(0.2)); pen.sketch.line(K + "ho", head, .ink, width: Sketch.stroke)
            var legs: [(CGPoint, CGPoint)] = []
            for i in 1...3 { let lx = x0 + (hx - x0) * Double(i) / 4; legs.append((pen.P(lx, y + 0.4), pen.P(lx - 0.4, y))); legs.append((pen.P(lx, y + 1.6), pen.P(lx - 0.4, y + 2))) }
            pen.sketch.segments(K + "legs", legs, .ink, width: Sketch.stroke)
        }
    }
    /// The readout beside the picture, in the chapter colour, from column x on row y.
    static func readout(_ pen: inout GridPen, _ text: String, x: Double, y: Double) {
        pen.word("ro", text, at: x, y, say.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5))
    }
    /// A block's column past a record line's end: two squares on, on the next block line.
    static func after(_ end: Double) -> Double { EG2.ceil5(end + 2) }
}
