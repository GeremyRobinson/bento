import SwiftUI

/// What 4th grade's Decimals lessons share (design/grade4.md chapter 6, the preview design/prototype/grade4-ch6.html): a
/// whole is a bold square 20 × 20 squares, so a tenth is a column 2 × 20 and a hundredth 2 × 2 (5th grade's Multiplying
/// decimals had it first). Its outline in ink, the tenths' lines in the chapter's colour, the hundredths' rows finer;
/// tenths not yet opened have no hundredths' lines. Two wholes stand 4 squares apart.
@MainActor
enum D6 {
    /// A whole's side, a tenth's width, and where the second whole starts.
    static let side = 20.0, col = 2.0, second = 24.0

    /// A whole at (x, y): the first `bare` columns without their hundredths' lines (each column's own, so opening them
    /// draws them in down those columns).
    static func whole(_ pen: inout GridPen, _ id: String, x: Double, y: Double, bare: Int = 0) {
        pen.sketch.segments(id + "c", (1..<10).map { c in (pen.P(x + Double(c) * col, y), pen.P(x + Double(c) * col, y + side)) }, .chapter, width: Sketch.stroke)
        for c in bare..<10 {
            pen.sketch.segments("\(id)h\(c)", (1..<10).map { r in (pen.P(x + Double(c) * col, y + Double(r) * col), pen.P(x + Double(c + 1) * col, y + Double(r) * col)) },
                                .tint(0.45), width: 1)
        }
        pen.sketch.box(id + "o", pen.R(x, y, side, side), .ink, width: Sketch.stroke)
    }
    /// Where the s-th hundredth of a whole at (x0, y0) sits: counted down a column, then on to the next.
    static func cell(_ s: Int, x0: Double, y0: Double) -> (x: Double, y: Double) {
        (x0 + Double(s / 10) * col, y0 + Double(s % 10) * col)
    }
    /// n hundredths shaded down the columns: whole columns, then the rest of the next; striped for the second amount.
    static func shade(_ pen: inout GridPen, _ id: String, x: Double, y: Double, _ n: Int, striped: Bool = false) {
        let c = n / 10, r = n % 10
        func fill(_ k: String, _ cx: Double, _ w: Double, _ h: Double) {
            if striped { pen.stripes(k, col: cx, row: y, w: w, h: h) } else { pen.fill(k, col: cx, row: y, w: w, h: h, Bars.shade) }
        }
        if c > 0 { fill("\(id)F\(c)", x, Double(c) * col, side) }
        if r > 0 { fill("\(id)P\(c)_\(r)", x + Double(c) * col, col, Double(r) * col) }
    }
    /// A hint: a dashed outline half a square outside some squares.
    static func ring(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double) {
        pen.sketch.box(id, pen.R(x - 0.5, y - 0.5, w + 1, h + 1), .chapter, width: Sketch.stroke, dashed: true)
    }
}
