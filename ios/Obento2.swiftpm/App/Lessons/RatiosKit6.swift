import SwiftUI

/// What 6th grade's Ratios and percents lessons share (design/grade6.md chapter 1, the preview
/// design/prototype/grade6-ch1.html): cells drawn one by one (each its own block, so new rows draw in), the handle a
/// finger holds, a hint's dashed ring, and the first-quadrant plane of Ratio tables (two squares a unit).
@MainActor
enum R6 {
    static let maths = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
    static let words = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
    static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink2)
    static let lit = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)
    static let red = Bars.red

    /// `cols` × `rows` cells of `c` squares from (x, y), each outlined in the chapter's colour, tinted or striped.
    static func cells(_ pen: inout GridPen, _ id: String, x: Double, y: Double, cols: Int, rows: Int, c: Double, striped: Bool = false) {
        for i in 0..<rows {
            if striped { pen.stripes("\(id)s\(i)", col: x, row: y + Double(i) * c, w: Double(cols) * c, h: c) }
            else { pen.fill("\(id)f\(i)", col: x, row: y + Double(i) * c, w: Double(cols) * c, h: c, .tint(0.22)) }
            for j in 0..<cols { pen.sketch.box("\(id)\(i)_\(j)", pen.R(x + Double(j) * c, y + Double(i) * c, c, c), .chapter, width: Sketch.stroke) }
        }
    }
    /// The handle a finger holds: bigger while it's held.
    static func handle(_ pen: inout GridPen, _ id: String, _ x: Double, _ y: Double, held: Bool) {
        pen.dot(id, at: x, y, radius: held ? 0.75 : 0.55, .chapter, over: true)
    }
    /// A hint: a dashed ring round some squares (the general area, after a first miss).
    static func ring(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double) {
        pen.sketch.box(id, pen.R(x - 0.5, y - 0.5, w + 1, h + 1), .chapter, width: Sketch.stroke, dashed: true)
    }
    /// How wide words are, in squares.
    static func width(_ s: String, _ w: Sketch.Words = small) -> Double { PaperText.width(s, PaperText.font(w.size, w.weight, digits: true)) / Paper.cell }

    /// The plane: its corner at (ox, oy), `U` squares a unit, `X` across and `Y` up, with its names.
    struct Plane {
        var ox = 5.0, oy = 25.0, U = 2.0
        var X = RatioTable.across, Y = RatioTable.up
        var xName = "minutes", yName = "laps"
        /// A place (u across, v up, in units) in the picture's squares.
        func at(_ u: Double, _ v: Double) -> CGPoint { CGPoint(x: ox + u * U, y: oy - v * U) }
        /// A finger's place snapped to the nearest grid point (every square), in squares from the corner.
        func snap(_ q: CGPoint) -> (su: Int, sv: Int) {
            (max(0, min(X * Int(U), Int((q.x - ox).rounded()))), max(0, min(Y * Int(U), Int((oy - q.y).rounded()))))
        }
        func holds(_ q: CGPoint, margin m: Double = 1.5) -> Bool {
            q.x >= ox - m && q.x <= ox + Double(X) * U + m && q.y >= oy - Double(Y) * U - m && q.y <= oy + m
        }
        /// The axes, their arrows, ticks and numbers (the ones a point is over lit) and names.
        @MainActor func draw(_ pen: inout GridPen, litX: Int? = nil, litY: Int? = nil) {
            let xe = ox + Double(X) * U + 1.5, ye = oy - Double(Y) * U - 1
            pen.line("pax", [(ox, oy), (xe, oy)]); pen.line("paxa", [(xe - 0.8, oy - 0.8), (xe, oy), (xe - 0.8, oy + 0.8)])
            pen.line("pay", [(ox, oy), (ox, ye)]); pen.line("paya", [(ox - 0.8, ye + 0.8), (ox, ye), (ox + 0.8, ye + 0.8)])
            pen.label("pxn", xName, R6.small, .right, edge: xe + 0.2, along: oy)
            pen.label("pyn", yName, R6.small, .right, edge: ox + 0.7, along: ye + 0.6)
            pen.sketch.segments("pxt", (0...X).map { i in (pen.P(ox + Double(i) * U, oy), pen.P(ox + Double(i) * U, oy + 0.5)) }, .ink, width: Sketch.stroke)
            pen.sketch.segments("pyt", (1...Y).map { j in (pen.P(ox - 0.5, oy - Double(j) * U), pen.P(ox, oy - Double(j) * U)) }, .ink, width: Sketch.stroke)
            for i in 0...X { pen.label("pxl\(i)\(litX == i)", "\(i)", litX == i ? R6.lit : R6.small, .below, edge: oy + 0.4, along: ox + Double(i) * U) }
            for j in 1...Y { pen.label("pyl\(j)\(litY == j)", "\(j)", litY == j ? R6.lit : R6.small, .left, edge: ox - 0.4, along: oy - Double(j) * U) }
        }
        /// Dashed lines from a point down and across to the axes.
        @MainActor func drops(_ pen: inout GridPen, _ id: String, _ u: Double, _ v: Double, _ c: Sketch.Colour = .chapter) {
            let p = at(u, v)
            if v > 0 { pen.line("\(id)dx", [(p.x, p.y), (p.x, oy)], c, dashed: true) }
            if u > 0 { pen.line("\(id)dy", [(p.x, p.y), (ox, p.y)], c, dashed: true) }
        }
        /// A point placed, and its pair beside it.
        @MainActor func mark(_ pen: inout GridPen, _ id: String, _ u: Double, _ v: Double, label: Bool = true, _ c: Sketch.Colour = .chapter) {
            let p = at(u, v)
            pen.dot(id, at: p.x, p.y, radius: 0.45, c, over: true)
            if label { pen.word(id + "l", Ratio6.pair(u, v), at: p.x + 0.9, p.y + 1.1, R6.lit.colour(c), anchor: UnitPoint(x: 0, y: 0.5)) }
        }
        /// The ruler line from 0 through a : b and on to the plane's edge, dashed.
        @MainActor func ray(_ pen: inout GridPen, _ id: String, a: Int, b: Int) -> CGPoint {
            let s = min(Double(X) / Double(b), Double(Y) / Double(a)), e = at(s * Double(b), s * Double(a))
            pen.line(id, [(ox, oy), (e.x, e.y)], .chapter, dashed: true)
            return e
        }
    }
}
