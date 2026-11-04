import SwiftUI

/// What 4th grade's Fractions lessons share (design/grade4.md chapter 4, the preview design/prototype/grade4-ch4.html):
/// 5th grade's bars in the fractions' colour, a whole 48 squares long (Fractions4.whole), 4 tall, 6 rows apart (2 squares
/// between); shaded pieces tinted, the second amount striped, each piece drawn by itself so a moved piece glides; a
/// fraction's name in a column 4 squares wide; the record's lines of fractions, signs, whole numbers and boxes.
@MainActor
enum F4 {
    static let h = Bars.height
    /// A bar's pieces, `pw` squares each, from (x, y): pieces `from` ..< `from + n` drawn one by one with the id `id<i>`,
    /// tinted or striped, outlined in the chapter's colour.
    static func pieces(_ pen: inout GridPen, _ id: String, x: Double, y: Double, pw: Double, _ range: Range<Int>, striped: Bool = false, crossed: Bool = false) {
        for i in range {
            let px = x + Double(i) * pw
            piece(&pen, "\(id)\(i)", x: px, y: y, pw: pw, striped: striped, crossed: crossed)
        }
    }
    /// One piece at (x, y): tinted, or striped; crossed out from its bottom-left to its top-right (taken away).
    static func piece(_ pen: inout GridPen, _ id: String, x: Double, y: Double, pw: Double, striped: Bool = false, crossed: Bool = false, shaded: Bool = true) {
        if striped { pen.stripes(id + "s", col: x, row: y, w: pw, h: h) }
        else if shaded { pen.fill(id + "f", col: x, row: y, w: pw, h: h, Bars.shade) }
        pen.sketch.box(id + "o", pen.R(x, y, pw, h), .chapter, width: Sketch.stroke)
        if crossed { pen.line(id + "x", [(x + 0.5, y + h - 0.5), (x + pw - 0.5, y + 0.5)], .ink) }
    }
    /// A whole bar `W` long cut into `d` pieces at (x, y): the first `on` tinted (or striped); `dash`: only its outline,
    /// dashed (where pieces were slid from); `uncut`: no cuts (a whole, closed).
    static func bar(_ pen: inout GridPen, _ id: String, x: Double = 0, y: Double, W: Int, d: Int, on: Int = 0, striped: Bool = false, dash: Bool = false, uncut: Bool = false) {
        let pw = Double(W) / Double(max(1, d))
        if dash { pen.sketch.box("\(id)od", pen.R(x, y, Double(W), h), .chapter, width: Sketch.stroke, dashed: true); return }
        if on > 0 {
            if striped { pen.stripes("\(id)s\(on)_\(d)", col: x, row: y, w: Double(on) * pw, h: h) }
            else { pen.fill("\(id)f\(on)_\(d)", col: x, row: y, w: Double(on) * pw, h: h, Bars.shade) }
        }
        pen.sketch.box("\(id)o", pen.R(x, y, Double(W), h), .chapter, width: Sketch.stroke)
        if !uncut && d > 1 {
            pen.sketch.segments("\(id)c\(d)", (1..<d).map { i in (pen.P(x + Double(i) * pw, y), pen.P(x + Double(i) * pw, y + h)) }, .chapter, width: Sketch.stroke)
        }
    }
    /// The pieces counted: `from` + 1, … in each, centred.
    static func counts(_ pen: inout GridPen, _ id: String, x: Double = 0, y: Double, pw: Double, _ n: Int, from: Int = 0, at first: Int = 0) {
        for i in 0..<n { pen.word("\(id)\(from + i)", "\(from + i + 1)", at: x + (Double(first + i) + 0.5) * pw, y + h / 2, Bars.count) }
    }

    /// A fraction in a column `w` squares wide from `col`, its line on row `line`, the top centred on the row above, the
    /// bottom on the row below (nil leaves a part empty, for a box).
    static func frac(_ pen: inout GridPen, _ id: String, _ top: String?, _ bottom: String?, col: Double, line: Double, _ c: Sketch.Colour = .ink, w: Double = 4) {
        if let top { pen.word(id + "t", top, at: col + w / 2, line - 1, Bars.maths.colour(c)) }
        pen.rule(id + "bar", from: col, to: col + w, row: line, c)
        if let bottom { pen.word(id + "b", bottom, at: col + w / 2, line + 1, Bars.maths.colour(c)) }
    }

    /// A part of the record: a fraction (4 squares wide, or `w`), one with boxes for its top and bottom, a sign (2 squares),
    /// a whole number written tight, right-aligned in the squares its digits take (G 3 Nov: a number in a line is one
    /// word), or a box for a whole number.
    enum Tok {
        case f(String, String, Sketch.Colour = .ink, w: Double = 4)
        case fb(top: Part, bottom: Part)
        case op(String, Sketch.Colour = .ink)
        case n(Int, Sketch.Colour = .ink)
        case box(String, cells: Int)
        enum Part { case v(Int), box(String) }
        var width: Double {
            switch self {
            case .f(_, _, _, let w): w
            case .fb: 4
            case .op: 2
            case .n(let v, _): 2 * Double(String(v).count)
            case .box(_, let cells): 2 * Double(cells) + 1
            }
        }
    }
    static func width(_ toks: [Tok]) -> Double { toks.reduce(0) { $0 + $1.width } }

    /// A line of the record from column x, its fractions' lines on row `line`. Returns where it ends.
    @discardableResult
    static func row(_ pen: inout GridPen, _ id: String, _ toks: [Tok], x: Double, line: Double) -> Double {
        var cx = x
        for (i, t) in toks.enumerated() {
            let k = "\(id).\(i)"
            switch t {
            case .f(let a, let b, let c, let w): frac(&pen, k, a, b, col: cx, line: line, c, w: w)
            case .fb(let top, let bottom):
                frac(&pen, k, nil, nil, col: cx, line: line)
                for (p, mid, nm) in [(top, line - 1, "t"), (bottom, line + 1, "b")] {
                    switch p {
                    case .v(let v): pen.word(k + nm, "\(v)", at: cx + 2, mid, Bars.maths)
                    case .box(let b): pen.answerBox(b, right: cx + 4, mid: mid, per: 2, cells: 2, centred: true)
                    }
                }
            case .op(let o, let c): pen.word(k + o, o, at: cx + 1, line, Bars.maths.colour(c))
            case .n(let v, let c): pen.word(k + "n\(v)", "\(v)", at: cx + t.width - 0.3, line, Bars.maths.colour(c), anchor: UnitPoint(x: 1, y: 0.5))
            case .box(let b, let cells): pen.answerBox(b, right: cx + 2 * Double(cells), mid: line, per: 2, cells: cells)
            }
            cx += t.width
        }
        return cx
    }

    /// Screenshots and the ghost: a tap at the middle of a piece of the picture.
    static func at(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
}
