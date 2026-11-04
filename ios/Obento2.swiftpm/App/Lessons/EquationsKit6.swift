import SwiftUI

/// What 6th grade's Equations lessons share (design/grade6.md chapter 6, the preview design/prototype/grade6-ch6.html):
/// cells in a row, each its own outlined square (tinted, strongly tinted, or crossed off with a stroke and no fill), and
/// a value of cells written as the record writes it (a number, or a whole number and a fraction). The rest is borrowed:
/// chapter 5's letter strip (X6.strip), chapter 1's handle and ring (R6), chapter 4's line (N6.Line).
@MainActor
enum E6 {
    static let small = R6.small, lit = R6.lit, maths = R6.maths, words = R6.words

    /// `n` cells of `c` squares from (x, y): outlined in the chapter's colour, tinted (`strong` more), the ones from
    /// `crossFrom` on crossed off (a stroke through, no fill).
    static func cells(_ pen: inout GridPen, _ id: String, x: Double, y: Double, n: Int, c: Double, strong: Bool = false, crossFrom: Int? = nil) {
        guard n > 0 else { return }
        let kept = min(n, crossFrom ?? n)
        if kept > 0 { pen.fill(id + "f\(kept)", col: x, row: y, w: Double(kept) * c, h: c, strong ? .tint(0.42) : .tint(0.22)) }
        for j in 0..<n { pen.sketch.box("\(id)\(j)", pen.R(x + Double(j) * c, y, c, c), .chapter, width: Sketch.stroke) }
        if kept < n {
            let segs = (kept..<n).map { j in let cx = x + Double(j) * c; return (pen.P(cx + 0.35, y + c - 0.35), pen.P(cx + c - 0.35, y + 0.35)) }
            pen.sketch.segments(id + "x\(kept)", segs, .chapter, width: Sketch.stroke)
        }
    }

    /// A value of cells as the record writes it: "2.75", or 2 and 3/4 as a whole number and a fraction.
    /// `then`: something follows on the line, so a fraction keeps a square clear of it.
    static func value(_ P: OneStep6.Parts, _ cells: Int, _ c: Sketch.Colour = .ink, then: Bool = false) -> [M7.Tok] {
        guard P.fr else { return [.t(P.V(cells), c)] }
        let q = Int((Double(cells) * P.cv * 4).rounded()), w = q / 4, r = q % 4, g = r == 2 ? 2 : 1
        if r == 0 { return [.n(w, c)] }
        return (w > 0 ? [.t("\(w)", c)] : []) + [.f(r / g, 4 / g, c)] + (then ? [.gap(1)] : [])
    }
}
