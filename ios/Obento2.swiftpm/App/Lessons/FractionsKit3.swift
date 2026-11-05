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
    static func lifted(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double, c: Double = 0, shaded: Bool = true, fill: Sketch.Colour? = nil, _ colour: Sketch.Colour = .ink) {
        pen.sketch.plate(id + "p", pen.R(x, y, w, h), fill ?? (shaded ? shade : .paper))
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

/// The number line and its hops (chapter 5's): `wholes` wholes of `per` squares from column 0 on row y, a tick every per / b
/// squares (taller at the wholes, which are named under it, or over it).
@MainActor
enum F3L {
    static func line(_ pen: inout GridPen, _ id: String, y: Double, wholes: Int, per: Double, b: Int, above: Bool = false) {
        pen.line(id + "l", [(0, y), (Double(wholes) * per, y)])
        let ts = per / Double(b)
        for i in 0...(wholes * b) {
            let whole = i % b == 0, x = Double(i) * ts
            pen.line("\(id)t\(i)", [(x, y - (whole ? 1.6 : 1)), (x, y)])
            if whole { pen.label("\(id)w\(i)", "\(i / b)", F3P.small, above ? .above : .below, edge: above ? y - 1.6 : y, along: x) }
        }
    }
    /// The peak of a hop `ts` squares long.
    static func peak(_ ts: Double) -> Double { min(3, ts * 0.4) }
    /// n hops of ts squares from 0 on row y, each counted over its middle (`quiet`: not counted), in the chapter's colour
    /// or faint.
    static func hops(_ pen: inout GridPen, _ id: String, y: Double, ts: Double, n: Int, faint: Bool = false, quiet: Bool = false) {
        guard n > 0 else { return }
        let H = peak(ts)
        for i in 1...n {
            let x1 = Double(i - 1) * ts, x2 = Double(i) * ts
            pen.hop("\(id)a\(i)", from: x1, to: x2, row: y, height: H, faint ? .ink3 : .chapter)
            if !quiet { pen.word("\(id)n\(i)", "\(i)", at: (x1 + x2) / 2, y - H - 0.9, F3P.smallLit) }
        }
    }
    /// The handle at the end of the last hop.
    static func handle(_ pen: inout GridPen, x: Double, y: Double, held: Bool) { pen.dot("hh", at: x, y, radius: held ? 0.7 : 0.55, .ink, over: true) }

    /// Hops dragged from 0: grabbed a finger's width round the end of the last, snapping a hop at a time; let go, `said`
    /// answers it (nil: nothing to check).
    static func hands(_ s: PaperState, y: Double, ts: Double, max: Int, key: String, want: Int) -> Hands {
        let n0 = Int((s.h("n") ?? 0).rounded())
        return Hands(
            grab: { q in abs(q.x - Double(n0) * ts) <= 2.5 && abs(q.y - y) <= 3 ? ["grab": 1, "n": Double(n0)] : nil },
            drag: { q, h in var h = h; h["n"] = Double(Swift.max(0, Swift.min(max, Int((q.x / ts).rounded())))); return h },
            release: { h in
                let n = Int((h["n"] ?? 0).rounded())
                guard n != n0, n > 0 else { return HandMove(hand: ["n": Double(n)]) }
                return HandMove(hand: ["n": Double(n)], missHand: ["n": Double(n > want ? n0 : n)], set: [(key, Double(n))], check: true)
            })
    }
}
