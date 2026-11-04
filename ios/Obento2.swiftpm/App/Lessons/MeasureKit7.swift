import SwiftUI

/// What 4th grade's Measurement lessons share (design/grade4.md chapter 7, the preview design/prototype/grade4-ch7.html):
/// a line of the record or a name written as words are (G 3 Nov, design/README.md "Calls made" 1): numbers tight with
/// their commas, a time or a price as one word ("3:45", "$2.75"), units as words ("ft", "mL"), fractions three squares
/// wide, signs and boxes, each in the fewest whole squares it fits.
@MainActor
enum M7 {
    enum Tok {
        case n(Int, Sketch.Colour = .ink)
        /// Maths written tight as one word: a time, a price, a decimal.
        case t(String, Sketch.Colour = .ink)
        /// A unit or a word, as the line's words.
        case w(String, Sketch.Colour = .ink)
        case op(String, Sketch.Colour = .ink)
        /// A fraction three squares wide, its line on the row's line.
        case f(Int, Int, Sketch.Colour = .ink)
        /// An answer box for a number `cells` digits long.
        case box(String, cells: Int)
        /// A fraction four squares wide whose top and bottom are boxes.
        case fb(String, String)
        case gap(Double)
        @MainActor var width: Double {
            switch self {
            case .n(let v, _): Record.width(.n(v))
            case .t(let s, _): (PaperText.width(s, PaperText.font(Sketch.maths, .medium, digits: true)) / Paper.cell + 0.5).rounded(.up)
            case .w(let s, _): Record.width(s)
            case .op(let o, _): Record.opWidth(o)
            case .f: 3
            case .box(_, let cells): Record.boxWidth(cells: cells, commas: true)
            case .fb: 4
            case .gap(let g): g
            }
        }
    }
    static func width(_ toks: [Tok]) -> Double { toks.reduce(0) { $0 + $1.width } }

    /// A line from column x on the row whose middle is `line`. Returns where it ends.
    @discardableResult
    static func row(_ pen: inout GridPen, _ id: String, _ toks: [Tok], x: Double, line: Double) -> Double {
        var cx = x
        for (i, t) in toks.enumerated() {
            let k = "\(id).\(i)", w = t.width
            switch t {
            case .n(let v, let c): Record.tight(&pen, k + "n\(v)", v, right: cx + w, row: line, c)
            case .t(let s, let c): pen.word(k + "t", s, at: cx + w / 2, line, Bars.maths.colour(c))
            case .w(let s, let c): pen.word(k + "w", s, at: cx + 0.5, line, Record.words.colour(c), anchor: UnitPoint(x: 0, y: 0.5))
            case .op(let o, let c): pen.word(k + o, o, at: cx + w / 2, line, Bars.maths.colour(c))
            case .f(let a, let b, let c): F4.frac(&pen, k, "\(a)", "\(b)", col: cx, line: line, c, w: 3)
            case .box(let b, _): pen.answerBox(b, right: cx + w, mid: line, per: 2, cells: 1, commas: true, word: w)
            case .fb(let a, let b):
                F4.frac(&pen, k, nil, nil, col: cx, line: line)
                pen.answerBox(a, right: cx + 4, mid: line - 1, per: 2, cells: 2, centred: true)
                pen.answerBox(b, right: cx + 4, mid: line + 1, per: 2, cells: 2, centred: true)
            case .gap: break
            }
            cx += w
        }
        return cx
    }

    /// A hint: a dashed ring round some squares.
    static func ring(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double) {
        pen.sketch.box(id, pen.R(x - 0.5, y - 0.5, w + 1, h + 1), .chapter, width: Sketch.stroke, dashed: true)
    }
}
