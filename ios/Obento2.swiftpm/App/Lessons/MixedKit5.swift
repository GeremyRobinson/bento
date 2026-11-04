import SwiftUI

/// What 4th grade's Mixed numbers lessons share (design/grade4.md chapter 5, the preview design/prototype/grade4-ch5.html):
/// chapter 4's pieces (F4) on bars half as long, so a mixed number stands in one column and two numbers stand side by
/// side, the second (striped) 4 squares to the right of the first, each named under its column. A whole bar, all shaded,
/// is 2 squares tall (it has no pieces to count); bars in a column are a square apart.
@MainActor
enum M5 {
    /// A whole bar's height, and the rows from one whole to the next.
    static let wh = 2.0, step = 3.0
    /// A whole bar `W` long at (x, y): shaded or striped, outlined in the chapter's colour; crossed out from its
    /// bottom-left to its top-right when taken away.
    static func whole(_ pen: inout GridPen, _ id: String, x: Double, y: Double, W: Double, striped: Bool = false, crossed: Bool = false) {
        if striped { pen.stripes(id + "s", col: x, row: y, w: W, h: wh) } else { pen.fill(id + "f", col: x, row: y, w: W, h: wh, Bars.shade) }
        pen.sketch.box(id + "o", pen.R(x, y, W, wh), .chapter, width: Sketch.stroke)
        if crossed { pen.line(id + "x", [(x + 0.5, y + wh - 0.25), (x + W - 0.5, y + 0.25)], .ink) }
    }
    /// A whole bar opened into its `d` pieces (G: never remove an animation): the same bar, shaded, grown to a part
    /// bar's height along a spring's path, its cuts growing down it as it opens (as the preview's does).
    static func opened(_ pen: inout GridPen, _ id: String, x: Double, y: Double, W: Double, d: Int) {
        let pw = W / Double(max(1, d))
        func cuts(_ h: Double) -> [(CGPoint, CGPoint)] { (1..<max(2, d)).map { i in (pen.P(x + Double(i) * pw, y), pen.P(x + Double(i) * pw, y + h)) } }
        pen.sketch.morphs = true
        pen.fill(id + "f", col: x, row: y, w: W, h: F4.h, Bars.shade)
        pen.sketch.box(id + "o", pen.R(x, y, W, F4.h), .chapter, width: Sketch.stroke)
        pen.sketch.from[id + "c"] = .segments(cuts(wh), width: Sketch.stroke)
        pen.sketch.segments(id + "c", cuts(F4.h), .chapter, width: Sketch.stroke)
        pen.sketch.from = [:]
        pen.sketch.morphs = false
    }
    /// A full bar of pieces closed into a whole (G: never remove an animation): the whole starts as the full bar, 4
    /// tall where the pieces were, and shrinks to a whole's 2 along a spring's path while the pieces' cuts go.
    static func closed(_ pen: inout GridPen, _ id: String, x: Double, y: Double, W: Double) {
        let r = pen.R(x, y, W, F4.h)
        pen.sketch.from[id + "f"] = .fill([CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)])
        pen.sketch.from[id + "o"] = .line([CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.minX, y: r.minY)], width: Sketch.stroke, dashed: false)
        whole(&pen, id, x: x, y: y, W: W)
        pen.sketch.from = [:]
    }
    /// Where a whole bar was (slid away): its outline, dashed.
    static func gone(_ pen: inout GridPen, _ id: String, x: Double, y: Double, W: Double, h: Double = wh) {
        pen.sketch.box(id, pen.R(x, y, W, h), .chapter, width: Sketch.stroke, dashed: true)
    }
    /// A bar's outline and cuts with no shading (its pieces are drawn on it one by one, so they glide); dashed when its
    /// pieces have been slid away.
    static func frame(_ pen: inout GridPen, _ id: String, x: Double, y: Double, W: Int, d: Int, dash: Bool = false) {
        if dash { F4.bar(&pen, id, x: x, y: y, W: W, d: d, dash: true); return }
        F4.bar(&pen, id, x: x, y: y, W: W, d: d)
    }
    /// A mixed number as the record writes it: its whole number written tight, then its fraction (no whole number when
    /// it's 0).
    static func mixed(_ w: Int, _ n: Int, _ d: Int, _ c: Sketch.Colour = .ink) -> [F4.Tok] {
        (w > 0 ? [.n(w, c)] : []) + (n > 0 || w == 0 ? [.f("\(n)", "\(d)", c)] : [])
    }
    /// A number named under its column, centred on it, its fraction's line on row `line`.
    static func name(_ pen: inout GridPen, _ id: String, _ toks: [F4.Tok], col x: Double, W: Double, line: Double) {
        let w = F4.width(toks)
        F4.row(&pen, id, toks, x: x + ((W - w) / 2).rounded(.down), line: line)
    }
    /// A hint: a dashed outline where something goes, half a square inside it.
    static func target(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double) {
        pen.sketch.box(id, pen.R(x + 0.5, y + 0.5, w - 1, h - 1), .chapter, width: Sketch.stroke, dashed: true)
    }
    /// A hint: a dashed ring round a bar, half a square outside it.
    static func ring(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double) {
        pen.sketch.box(id, pen.R(x - 0.5, y - 0.5, w + 1, h + 1), .chapter, width: Sketch.stroke, dashed: true)
    }
}

/// A group slid from where it is onto something else (the wholes under the left's, the pieces into a bar, the groups
/// into the answer bar): grabbed inside `from` (the picture's squares), it follows the finger a square at a time; over
/// the target (the finger's place, `over`) it's ready to drop. Let go there, the step's box is `value`; anywhere else
/// it goes back (0), which the lesson's Core check says as a notice.
@MainActor
struct GroupSlide {
    let from: CGRect
    let over: @MainActor (CGPoint) -> Bool
    var box = "s"
    var value = 1.0

    func hands(tap: ((CGPoint) -> HandMove?)? = nil) -> Hands {
        let from = self.from, over = self.over, box = self.box, value = self.value
        return Hands(
            tap: tap,
            grab: { p in from.contains(p) ? ["grab": 1, "fx": p.x, "fy": p.y, "dx": 0, "dy": 0, "in": over(p) ? 1 : 0] : nil },
            drag: { p, h in
                let fx = h["fx"] ?? 0, fy = h["fy"] ?? 0
                return ["grab": 1, "fx": fx, "fy": fy, "dx": (p.x - fx).rounded(), "dy": (p.y - fy).rounded(), "in": over(p) ? 1 : 0]
            },
            release: { h in
                h["in"] == 1 ? HandMove(hand: [:], missHand: [:], set: [(box, value)], check: true)
                             : HandMove(hand: [:], missHand: [:], set: [(box, 0)], check: true)
            })
    }
    /// How far the group is held from where it was.
    static func offset(_ s: PaperState) -> (x: Double, y: Double) { (s.h("dx") ?? 0, s.h("dy") ?? 0) }
    static let liveKeys: Set<String> = ["fx", "fy", "dx", "dy", "in"]
    /// Screenshots only (-wrong): let go off the target.
    var wrongMove: HandMove { HandMove(hand: [:], missHand: [:], set: [(box, 0)], check: true) }
}
