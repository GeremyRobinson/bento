import SwiftUI

/// What 2nd grade's chapter 2, Numbers to 1000, shares on the paper (the preview design/prototype/grade2-ch2.html): base
/// ten in squares (a one a square, a ten a strip 1 × 10, a hundred a flat 10 × 10, each tinted with faint inner lines and
/// the chapter's outline), a number written tight in a line with one of its digits ringed, and the lines that open place
/// by place (Rounding's), a block a hundred, ten or one.
@MainActor
enum N2 {
    static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink2)
    static let words = KK.words

    /// A base-ten piece from (x, y): w × h squares tinted, its inner squares' lines faint, a bold outline.
    static func piece(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double, bold: Bool = false) {
        pen.fill(id + "f", col: x, row: y, w: w, h: h, .tint(0.4))
        var segs: [(CGPoint, CGPoint)] = []
        if w > 1 { for i in 1..<Int(w) { segs.append((pen.P(x + Double(i), y), pen.P(x + Double(i), y + h))) } }
        if h > 1 { for j in 1..<Int(h) { segs.append((pen.P(x, y + Double(j)), pen.P(x + w, y + Double(j)))) } }
        if !segs.isEmpty { pen.sketch.segments(id + "i", segs, .tint(0.7), width: 1) }
        pen.sketch.box(id + "o", pen.R(x, y, w, h), .chapter, width: bold ? 3 : Sketch.stroke)
    }
    /// A place waiting for the next piece: dashed, faint.
    static func place(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double) {
        pen.sketch.box(id, pen.R(x, y, w, h), .ink3, width: Sketch.stroke, dashed: true)
    }

    /// A number written tight in a line (Record.tight) from column x: its digit `i`'s middle.
    static func digitX(_ n: Int, _ i: Int, x: Double) -> Double {
        let s = "\(n)", w = Record.width(.n(n)), tw = Record.tightWidth(n)
        return x + w / 2 - tw / 2 + tw * (Double(i) + 0.5) / Double(s.count)
    }
    /// A number written tight from column x (in the whole squares Record.width gives it), a digit at a time so a ring or
    /// a colour can pick one out; `colour` for each digit.
    static func number(_ pen: inout GridPen, _ id: String, _ n: Int, x: Double, row: Double, _ colour: (Int) -> Sketch.Colour = { _ in .ink }) {
        for (i, ch) in "\(n)".enumerated() { pen.word("\(id)d\(i)\(ch)", String(ch), at: digitX(n, i, x: x), row, KK.maths.colour(colour(i))) }
    }
    /// A ring round one digit of a number written tight from column x on the row whose middle is `row`.
    static func ringDigit(_ pen: inout GridPen, _ id: String, _ n: Int, _ i: Int, x: Double, row: Double, _ colour: Sketch.Colour = .chapter, dashed: Bool = false) {
        // tall and narrow, so it holds one digit of a number written tight and not its neighbours
        let cx = digitX(n, i, x: x)
        pen.line(id, (0...32).map { k in let a = Double(k) / 32 * 2 * .pi; return (cx + 0.62 * cos(a), row + 0.98 * sin(a)) }, colour, dashed: dashed)
    }

    /// A line from column 0 to `w` on row y, its tick every `step` squares (taller every `tall`th).
    static func line(_ pen: inout GridPen, _ id: String, y: Double, w: Double, step: Double, tall: Int, ends: Bool = true) {
        pen.line(id, [(0, y), (w, y)])
        let n = Int((w / step).rounded())
        pen.sketch.segments(id + "t", (0...n).map { i in
            let x = Double(i) * step, big = i % tall == 0 || (ends && (i == 0 || i == n))
            return (pen.P(x, y - (big ? 1.5 : 0.7)), pen.P(x, y))
        }, .ink, width: Sketch.stroke)
    }
}
