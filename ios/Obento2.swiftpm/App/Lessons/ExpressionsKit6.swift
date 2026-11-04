import SwiftUI

/// What 6th grade's Expressions lessons share (design/grade6.md chapter 5, the preview design/prototype/grade6-ch5.html):
/// a written line whose parts a tap can pick (each token's columns known), a letter's strip (a plain bar whose end is
/// dashed while its length isn't known, its cells drawn once it is), and Unit cubes' blocks seen from the tilted view.
@MainActor
enum X6 {
    static let small = R6.small, lit = R6.lit, maths = R6.maths, words = R6.words

    /// Where each token of a line starting at column x runs, left to right (M7.row lays them the same way).
    static func columns(_ toks: [M7.Tok], x: Double) -> [(Double, Double)] {
        var cx = x
        return toks.map { t in let a = cx; cx += t.width; return (a, cx) }
    }
    /// The token whose columns are nearest a finger at column x (nil off the line).
    static func token(at x: Double, _ cols: [(Double, Double)]) -> Int? {
        guard let first = cols.first, let last = cols.last, x >= first.0 - 1, x <= last.1 + 1 else { return nil }
        return cols.indices.min { abs((cols[$0].0 + cols[$0].1) / 2 - x) < abs((cols[$1].0 + cols[$1].1) / 2 - x) }
    }

    /// A letter's strip from (x, y), `len` squares long and `h` tall: tinted (or striped), its end dashed while its length
    /// isn't known, its cells (`cell` squares) drawn once it is, its letter (or the number swapped in) in its middle.
    static func strip(_ pen: inout GridPen, _ id: String, x: Double, y: Double, len: Double, h: Double, known: Bool = false, cell: Double? = nil,
                      label: String?, striped: Bool = false, held: Bool = false) {
        if striped { pen.stripes(id + "s", col: x, row: y, w: len, h: h) } else { pen.fill(id + "f", col: x, row: y, w: len, h: h, held ? .tint(0.38) : .tint(0.22)) }
        pen.line(id + "e", [(x + len, y), (x, y), (x, y + h), (x + len, y + h)], .chapter)
        pen.line(id + "r\(known)", [(x + len, y), (x + len, y + h)], .chapter, dashed: !known)
        if let c = cell, c > 0 {
            let segs = stride(from: c, to: len - 0.01, by: c).map { j in (pen.P(x + j, y), pen.P(x + j, y + h)) }
            pen.sketch.segments(id + "c\(len)", segs, .chapter, width: Sketch.stroke)
        }
        // in the middle, or in a middle cell when its cells are drawn (never on a cell's line)
        let mid = cell.map { c in c > 0 ? x + ((len / c / 2).rounded(.down) + 0.5) * c : x + len / 2 } ?? x + len / 2
        if let label, len >= 1 { pen.word(id + "L", label, at: min(mid, x + len - 0.5), y + h / 2, X6.small.colour(.ink)) }
    }

    /// A dashed ring round a part of a written line, or round anything (a hint).
    static func ring(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double) { R6.ring(&pen, id, x: x, y: y, w: w, h: h) }

    // MARK: Unit cubes' blocks, seen from the tilted 3D lesson's angle (drawn on the paper, as the fold is)

    /// The tilted view about a pivot on the paper (its floor's middle), moved down by `dy` squares: a place on the paper
    /// (x across, y down) at height z (squares) seen at Unit cubes' 52° tilt, turned 28°.
    struct View {
        var px: Double, py: Double, dy = 0.0
        static let axes = PaperView3D(elevation: PaperView3D.tilted.elevation, azimuth: PaperView3D.tilted.azimuth).axes
        func at(_ x: Double, _ y: Double, _ z: Double) -> CGPoint {
            let v = Vec3(x - px, z, y - py), a = View.axes
            return CGPoint(x: px + v.dot(a.right), y: py + dy - v.dot(a.up))
        }
        /// The bounds of a box from (x0, y0) to (x1, y1), z0 to z1 high.
        func bounds(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ z1: Double) -> CGRect {
            let pts = [x0, x1].flatMap { x in [y0, y1].flatMap { y in [0, z1].map { at(x, y, $0) } } }
            let xs = pts.map(\.x), ys = pts.map(\.y)
            return CGRect(x: xs.min()!, y: ys.min()!, width: xs.max()! - xs.min()!, height: ys.max()! - ys.min()!)
        }
    }
    static let cubeTop = Sketch.Colour.tint(0.18), cubeFront = Sketch.Colour.tint(0.34), cubeSide = Sketch.Colour.tint(0.52)
}
