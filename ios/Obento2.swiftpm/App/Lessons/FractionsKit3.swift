import SwiftUI

/// What 3rd grade's chapter 5, Fractions, shares on the paper (the preview design/prototype/grade3-ch5.html): a whole of
/// 48 squares (Fr3.whole), bars 8 tall with their shading in the chapter's colour, a number line with taller ticks at the
/// wholes (named under it), hops that count over their middles, words beside a picture, and a fraction's record line.
@MainActor
enum F3P {
    static let BH = 8.0
    static let words = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
    static let lit = Sketch.Words(size: Sketch.wordSize, weight: .semibold, colour: .chapter)
    static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink)
    static let smallLit = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)
    static let shade = Bars.shade
    static let tint = Sketch.Colour.tint(0.2)

    /// Words beside a picture, from column x, centred on row y.
    static func beside(_ pen: inout GridPen, _ id: String, _ text: String, x: Double, y: Double, _ w: Sketch.Words = words) {
        pen.word(id, text, at: x, y, w, anchor: UnitPoint(x: 0, y: 0.5))
    }
    /// A fraction's record line from column x, its line on row `line`: words, =, then the child's two boxes, or once
    /// right the fraction in the chapter colour.
    static func record(_ pen: inout GridPen, _ id: String, _ lead: [M7.Tok], top: String, bottom: String, _ want: (Int, Int), right: Bool, x: Double, line: Double) {
        var toks = lead
        toks.append(.op("="))
        toks.append(right ? .f(want.0, want.1, .chapter) : .fb(top, bottom))
        M7.row(&pen, id, toks, x: x, line: line)
    }
    /// A piece of a bar, lifted out of it: paper under it (so it sits over what it passes), tinted, outlined.
    static func piece(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double, shaded: Bool = true, _ c: Sketch.Colour = .ink) {
        pen.fill(id + "p", col: x, row: y, w: w, h: h, .paper)
        if shaded { pen.fill(id + "s", col: x, row: y, w: w, h: h, shade) }
        pen.sketch.box(id + "o", pen.R(x, y, w, h), c, width: Sketch.stroke)
    }
    /// A piece lifted over the picture (over its lines too): a plate tinted (or paper), its inner tile lines every `c`
    /// squares (rows × cols of them; none when c is 0) and its outline drawn over it.
    static func lifted(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double, c: Double = 0, shaded: Bool = true, _ colour: Sketch.Colour = .ink) {
        pen.sketch.plate(id + "p", pen.R(x, y, w, h), shaded ? shade : .paper)
        if c > 0 {
            var j = c
            while j < w - 0.01 { pen.sketch.overLine("\(id)v\(j)", [pen.P(x + j, y), pen.P(x + j, y + h)], .ink3, width: 1); j += c }
            var i = c
            while i < h - 0.01 { pen.sketch.overLine("\(id)h\(i)", [pen.P(x, y + i), pen.P(x + w, y + i)], .ink3, width: 1); i += c }
        }
        pen.sketch.overLine(id + "o", [pen.P(x, y), pen.P(x + w, y), pen.P(x + w, y + h), pen.P(x, y + h), pen.P(x, y)], colour, width: Sketch.stroke)
    }
    /// Where a piece was: paper over what's there, a dashed outline; `top`: only the part from that row down shows (a
    /// piece lifted over the rest of it covers it, and two plates over each other fight).
    static func hole(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double, top: Double? = nil) {
        let t = top ?? y
        pen.sketch.plate(id + "p", pen.R(x, t, w, y + h - t), .paper)
        var pts = [pen.P(x, t), pen.P(x, y + h), pen.P(x + w, y + h), pen.P(x + w, t)]
        if top == nil { pts.append(pen.P(x, t)) }
        for (n, d) in GridPen.dashes(pts).enumerated() { pen.sketch.overLine("\(id)d\(n)", [d.0, d.1], .ink3, width: Sketch.stroke) }
    }
    /// A choice block 4 squares wide (Yes, No), red when picked wrong.
    static func choice(_ pen: inout GridPen, _ id: String, x: Double, y: Double, _ label: String, wrong: Bool) {
        T3.block(&pen, id, x: x, y: y, w: 4, label, wrong: wrong)
    }
}
