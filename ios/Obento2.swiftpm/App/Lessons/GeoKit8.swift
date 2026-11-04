import SwiftUI

/// What 4th grade's Lines and shapes lessons share (design/grade4.md chapter 8, the preview design/prototype/grade4-ch8.html):
/// angles and shapes drawn on the grid in squares (Geo4.Pt), every corner on a grid point and a first arm along a grid
/// line, an arm turned off the grid drawn at its true angle. Two tools lie beside the picture and are dragged on: the
/// page corner (a square corner of a sheet, 6 squares a side) and the protractor (a half circle, a tick every degree,
/// longer every 5 and 10, two scales). The tools are paper: they hide the grid under them, and the maths' lines show
/// on top.
@MainActor
enum G8 {
    typealias Pt = Geo4.Pt
    static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)
    static let pencil = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink2)
    static let say = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
    static let pc = 6.0

    static func cg(_ pen: GridPen, _ p: Pt) -> CGPoint { pen.P(p.x, p.y) }
    static func seg(_ pen: inout GridPen, _ id: String, _ a: Pt, _ b: Pt, _ c: Sketch.Colour = .ink, dashed: Bool = false) {
        pen.sketch.line(id, [cg(pen, a), cg(pen, b)], c, width: Sketch.stroke, dashed: dashed)
    }
    static func path(_ pen: inout GridPen, _ id: String, _ pts: [Pt], _ c: Sketch.Colour = .ink, closed: Bool = false, dashed: Bool = false) {
        var q = pts.map { cg(pen, $0) }
        if closed, let f = q.first { q.append(f) }
        if dashed { pen.sketch.segments(id, GridPen.dashes(q), c, width: Sketch.stroke) } else { pen.sketch.line(id, q, c, width: Sketch.stroke) }
    }
    static func fill(_ pen: inout GridPen, _ id: String, _ pts: [Pt], _ c: Sketch.Colour) { pen.sketch.polygon(id, pts.map { cg(pen, $0) }, c) }
    /// Points on an arc counter-clockwise from a0 to a1, about every 3°.
    static func arcPts(_ c: Pt, _ r: Double, _ a0: Double, _ a1: Double) -> [Pt] {
        let n = max(2, Int(((a1 - a0) / 3).rounded(.up)))
        return (0...n).map { Geo4.pol(c, r, a0 + (a1 - a0) * Double($0) / Double(n)) }
    }
    static func arc(_ pen: inout GridPen, _ id: String, _ c: Pt, _ r: Double, _ a0: Double, _ a1: Double, _ col: Sketch.Colour = .chapter, dashed: Bool = false) {
        guard a1 - a0 > 0.01 else { return }
        path(&pen, id, arcPts(c, r, a0, a1), col, dashed: dashed)
    }
    /// The arc closed to its centre, filled.
    static func wedge(_ pen: inout GridPen, _ id: String, _ c: Pt, _ r: Double, _ a0: Double, _ a1: Double, _ col: Sketch.Colour = .tint(0.2)) {
        guard a1 - a0 > 0.01 else { return }
        fill(&pen, id, (a1 - a0 >= 359.9 ? [] : [c]) + arcPts(c, r, a0, a1), col)
    }
    /// An arrowhead at p, pointing along a.
    static func arrow(_ pen: inout GridPen, _ id: String, _ p: Pt, _ a: Double, _ c: Sketch.Colour = .ink) {
        path(&pen, id, [Geo4.pol(p, 1.1, a + 150), p, Geo4.pol(p, 1.1, a - 150)], c)
    }
    /// The square corner's mark at c, between the directions a and a + 90.
    static func cornerMark(_ pen: inout GridPen, _ id: String, _ c: Pt, _ a: Double, _ col: Sketch.Colour = .chapter) {
        let p = Geo4.pol(c, 1.2, a)
        path(&pen, id, [p, Geo4.pol(p, 1.2, a + 90), Geo4.pol(c, 1.2, a + 90)], col)
    }
    /// The page corner's square: its corner at `at`, its edges along a and a + 90.
    static func pcPts(_ at: Pt, _ a: Double) -> [Pt] { let p = Geo4.pol(at, pc, a); return [at, p, Geo4.pol(p, pc, a + 90), Geo4.pol(at, pc, a + 90)] }
    /// `laid`: lying on the picture, it's drawn as its edges only (a fill over the picture's own fills bands on the
    /// screen); moved about or resting, it's a piece of paper hiding the grid.
    static func pageCorner(_ pen: inout GridPen, _ id: String, at: Pt, _ a: Double, laid: Bool = false) {
        let pts = pcPts(at, a)
        if !laid { fill(&pen, id + "s", pts, .paper) }
        path(&pen, id + "o", pts, .ink2, closed: true)
        cornerMark(&pen, id + "m", at, a, .ink2)
    }
    /// A place is on the page corner (a square and a half round it, so a finger can pick it up).
    static func inPC(_ p: Pt, at: Pt, _ a: Double) -> Bool {
        let ux = cos(a * .pi / 180), uy = -sin(a * .pi / 180), dx = p.x - at.x, dy = p.y - at.y, s = dx * ux + dy * uy, t = dx * uy - dy * ux
        return s > -1.5 && s < pc + 1.5 && t > -1.5 && t < pc + 1.5
    }
    /// The protractor upright, its centre on c, radius R: the outer scale counts from 0 on the right, the inner from 0 on
    /// the left. `use` ("R" or "L") lights the scale whose 0 is on the first arm and rings that 0.
    static func protractor(_ pen: inout GridPen, _ id: String, _ c: Pt, _ R: Double, use: String?) {
        let half = arcPts(c, R, 0, 180)
        // its paper is a band round the scales, in pieces that each fill flat: the middle stays clear for the angle's
        // own shading (fills that overlap band on the screen)
        for k in 0..<18 {
            let a0 = Double(10 * k), a1 = a0 + 10
            fill(&pen, "\(id)bg\(k)", [Geo4.pol(c, R, a0), Geo4.pol(c, R, a0 + 5), Geo4.pol(c, R, a1), Geo4.pol(c, 6, a1), Geo4.pol(c, 6, a0)], .paper)
        }
        path(&pen, id + "o", half, .ink2, closed: true)
        var t1: [(CGPoint, CGPoint)] = [], t5: [(CGPoint, CGPoint)] = []
        for d in 0...180 {
            let len = d % 10 == 0 ? 1.2 : d % 5 == 0 ? 0.8 : 0.45, a = Double(d)
            let s = (cg(pen, Geo4.pol(c, R, a)), cg(pen, Geo4.pol(c, R - len, a)))
            if d % 5 == 0 { t5.append(s) } else { t1.append(s) }
        }
        pen.sketch.segments(id + "t1", t1, .ink3, width: 1)
        pen.sketch.segments(id + "t5", t5, .ink2, width: Sketch.stroke)
        func col(_ s: String) -> Sketch.Words { Sketch.Words(size: Sketch.small, weight: .semibold, colour: use == s ? .chapter : use != nil ? .ink3 : .ink2) }
        for d in stride(from: 0, through: 180, by: 10) {
            var po = Geo4.pol(c, R - 2.3, Double(d)), pi = Geo4.pol(c, R - 4.1, Double(d))
            if d == 0 || d == 180 { po.y -= 0.8; pi.y -= 0.8 }
            pen.word("\(id)nR\(d)", "\(d)", at: po.x, po.y, col("R"))
            pen.word("\(id)nL\(d)", "\(180 - d)", at: pi.x, pi.y, col("L"))
        }
        pen.dot(id + "c", at: c.x, c.y, radius: 0.3, .ink2, over: true)
        if use == "R" { let p = Geo4.pol(c, R - 2.3, 0); pen.circle(id + "z", at: p.x, p.y - 0.8, radius: 1.1, .chapter) }
        if use == "L" { let p = Geo4.pol(c, R - 4.1, 180); pen.circle(id + "z", at: p.x, p.y - 0.8, radius: 1.1, .chapter) }
    }
    /// A place is on the protractor resting with its centre at c.
    static func onProtractor(_ p: Pt, _ c: Pt, _ R: Double) -> Bool { Geo4.dist(p, c) <= R && p.y <= c.y + 1 }

    /// Tap a choice: blocks on the paper from (x, y), 2 squares tall and 2 apart; a wrong pick red, the right one
    /// (a hint after a second miss) ringed. Returns each block's place.
    @discardableResult
    static func choices(_ pen: inout GridPen, _ id: String, x: Double, y: Double, _ labels: [String], bad: Int?, ring: Int? = nil, column: Bool = false) -> [CGRect] {
        let out = choiceRects(x: x, y: y, labels, column: column)
        for (i, l) in labels.enumerated() {
            let r = out[i], red = bad == i
            pen.sketch.block("\(id)\(i)\(red)", pen.R(r.minX, r.minY, r.width, 2), red ? Sketch.Block(stroke: Bars.red, text: Bars.red) : .main, centred: l, size: Sketch.wordSize)
            if ring == i { pen.sketch.box("\(id)ring\(i)", pen.R(r.minX - 0.5, r.minY - 0.5, r.width + 1, 3), .chapter, width: Sketch.stroke, dashed: true) }
        }
        return out
    }
    /// The choices' places: in a row 2 squares apart, or one under another (3 rows apart), all as wide as the widest.
    static func choiceRects(x: Double, y: Double, _ labels: [String], column: Bool = false) -> [CGRect] {
        let widest = labels.map { Record.width($0) + 2 }.max() ?? 4
        var cx = x
        return labels.enumerated().map { i, l in
            if column { return CGRect(x: x, y: y + 3 * Double(i), width: widest, height: 2) }
            let w = Record.width(l) + 2; defer { cx += w + 2 }
            return CGRect(x: cx, y: y, width: w, height: 2)
        }
    }
    static func columnWidth(_ labels: [String]) -> Double { labels.map { Record.width($0) + 2 }.max() ?? 4 }
    static func choicesWidth(_ labels: [String]) -> Double { labels.reduce(0) { $0 + Record.width($1) + 4 } - 2 }
    /// The choice a tap is on.
    static func choice(at q: CGPoint, _ rects: [CGRect]) -> Int? { rects.firstIndex { $0.insetBy(dx: -0.3, dy: -0.3).contains(q) } }

    /// Words beside the picture, in the chapter's colour (what a tool showed), wrapped to `w` squares, a row of 2 squares
    /// each; returns the rows.
    @discardableResult
    static func aside(_ pen: inout GridPen, _ id: String, _ s: String, x: Double, y: Double, w: Double, _ words: Sketch.Words = small) -> Int {
        let rows = PaperText.wrap(s, PaperText.font(words.size, words.weight), width: w * Paper.cell)
        for (i, r) in rows.enumerated() { pen.word("\(id)\(i)", r, at: x, y + 2 * Double(i), words, anchor: UnitPoint(x: 0, y: 0.5)) }
        return rows.count
    }

    /// Where the record goes: beside the picture or under it, whichever shows the problem bigger (the preview's placeRec):
    /// the picture's box in squares, the record's width and rows. Returns its left column and its first row's middle.
    /// `head`: the rows over the picture (what to do, what a miss says); the record's first row is 3 under the picture
    /// (or level with row 3 beside it), its blocks 2 under that.
    /// `wBeside`, `hBeside`: its size beside the picture (choices one under another), when that differs.
    static func placeRecord(r: Double, b: Double, w: Double, h: Double, wBeside: Double? = nil, hBeside: Double? = nil, head: Double = 8) -> (x: Double, y: Double, beside: Bool) {
        let under = ProblemGrid.zoom(squares: max(r, w), head + b.rounded(.up) + 3 + h + 1)
        let bx = ((r + 2) / 5).rounded(.up) * 5
        let beside = ProblemGrid.zoom(squares: bx + (wBeside ?? w), head + max(b, 3 + (hBeside ?? h)) + 1)
        return beside > under ? (bx, 3, true) : (0, b.rounded(.up) + 3, false)
    }

    /// The picture's state: its stage.
    static func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static func pt(_ q: CGPoint) -> Pt { Pt(q.x, q.y) }
}
