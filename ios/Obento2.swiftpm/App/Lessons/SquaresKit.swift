import SwiftUI

/// What 4th grade's Factors and patterns lessons share (the preview design/prototype/grade4-ch3.html): a square of the
/// picture (one is one), tinted and outlined in the chapter's colour, a leftover dashed, a found rectangle green; the
/// blocks that hold a choice (Yes, No; Prime, Composite; Odd, Even), red when the wrong one is tapped; a list of
/// numbers with commas, some ringed; the handle the hand drags.
@MainActor
enum Squares {
    static let red = Sketch.Colour.hex(0xC8372D, 0xFF6B5E), green = Sketch.Colour.hex(0x178A57, 0x3CCF8E)
    /// Green, lightly, on the paper (as the chapter's tint is).
    static let greenTint = Sketch.Colour.hex(0xC7DCCE, 0x234333)
    static let named = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
    static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)
    static let count = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)

    /// A square at (x, y): `over`, left over (dashed, pencil grey); `green`, part of a rectangle found; `fill`, its tint.
    static func cell(_ pen: inout GridPen, _ id: String, _ x: Double, _ y: Double, over: Bool = false, green: Bool = false, fill: Sketch.Colour = .tint(0.2)) {
        if over { dashed(&pen, id + "d", x, y, .ink2); return }
        pen.fill(id + "f", col: x, row: y, w: 1, h: 1, green ? greenTint : fill)
        pen.sketch.box(id + "o", pen.R(x, y, 1, 1), green ? Self.green : .chapter, width: Sketch.stroke)
    }
    /// A square dashed: each side's ends and middle, so its corners show (a leftover; a hint's place for one).
    static func dashed(_ pen: inout GridPen, _ id: String, _ x: Double, _ y: Double, _ colour: Sketch.Colour) {
        var segs: [(CGPoint, CGPoint)] = []
        for (a, b) in [((0.0, 0.0), (1.0, 0.0)), ((1, 0), (1, 1)), ((1, 1), (0, 1)), ((0, 1), (0, 0))] {
            for (u, v) in [(0.0, 0.22), (0.39, 0.61), (0.78, 1.0)] {
                segs.append((pen.P(x + a.0 + (b.0 - a.0) * u, y + a.1 + (b.1 - a.1) * u), pen.P(x + a.0 + (b.0 - a.0) * v, y + a.1 + (b.1 - a.1) * v)))
            }
        }
        pen.sketch.segments(id, segs, colour, width: Sketch.stroke)
    }

    /// The handle the hand drags: a dot, bigger while it's held.
    static func handle(_ live: inout GridPen, _ s: PaperState, at x: Double, _ y: Double) {
        live.dot("hd", at: x, y, radius: s.grabbed ? 0.75 : 0.55, .ink, over: true)
    }

    /// A row of choice blocks from (x, y), 2 squares tall, 2 apart, each as wide as its word and a square either side.
    static func choiceRects(_ labels: [String], x: Double, y: Double) -> [CGRect] {
        var cx = x, out: [CGRect] = []
        for l in labels {
            let w = Record.width(l) + 2
            out.append(CGRect(x: cx, y: y, width: w, height: 2)); cx += w + 2
        }
        return out
    }
    /// The choices drawn (`bad`: the one tapped wrong, in red).
    static func choices(_ pen: inout GridPen, _ id: String, _ labels: [String], x: Double, y: Double, bad: Int?) {
        for (i, r) in choiceRects(labels, x: x, y: y).enumerated() {
            let wrong = bad == i
            pen.sketch.block("\(id)\(i)\(wrong)", pen.R(r.minX, r.minY, r.width, r.height), wrong ? Sketch.Block(stroke: red, text: red) : .main,
                             centred: labels[i], size: Sketch.wordSize)
        }
    }
    /// Which choice a tap at q is on (in the same squares).
    static func choice(at q: CGPoint, _ labels: [String], x: Double, y: Double) -> Int? {
        choiceRects(labels, x: x, y: y).firstIndex { $0.insetBy(dx: -0.3, dy: -0.3).contains(q) }
    }

    /// Numbers with commas between, laid out as words (G 3 Nov): each written tight with its comma after it, starting a
    /// quarter square into the fewest whole squares it fits, the next on the following square, from column x on the row
    /// whose middle is y; `ringed` ones ringed, `tail` written after ("…"). Returns where it ends.
    @discardableResult
    static func list(_ pen: inout GridPen, _ id: String, _ vals: [Int], x: Double, y: Double, ringed: Set<Int> = [], tail: String? = nil) -> Double {
        var cx = x
        let font = PaperText.font(Sketch.maths, .medium, digits: true)
        for (i, v) in vals.enumerated() {
            let comma = i < vals.count - 1 || tail != nil, text = BigNumbers.commas(v) + (comma ? "," : "")
            let w = (PaperText.width(text, font) / Paper.cell + 0.5).rounded(.up)
            pen.word("\(id)n\(i)", text, at: cx + 0.25, y, Record.maths, anchor: UnitPoint(x: 0, y: 0.5))
            if ringed.contains(v) { let tw = Record.tightWidth(v); pen.ring("\(id)r\(i)", col: cx + 0.25 - 0.45, row: y - 1.25, w: tw + 0.9, h: 2.5) }
            cx += w
        }
        if let tail { pen.word("\(id)t", tail, at: cx + 1, y, Record.maths); cx += 2 }
        return cx
    }
}
