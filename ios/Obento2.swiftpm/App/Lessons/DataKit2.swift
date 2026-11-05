import SwiftUI

/// What 2nd grade's chapter 5, Data, shares on the paper (the preview design/prototype/grade2-ch5.html): a vote is a block
/// along its bar, so the scale's numbers sit on the strong lines; tally marks a square apart, 3 squares tall, four and the
/// fifth across them a bundle a block wide; the bars (a block for each vote, a line between blocks); the scale under them;
/// an X a cell a block wide on a line plot. The rows' little pictures are 1st grade's (`L5.icon`).
@MainActor
enum DK2 {
    static let say = KK.words
    static let small = LN2.small

    /// n tally marks from column x, their top on row y (3 squares tall).
    static func tally(_ pen: inout GridPen, _ id: String, _ n: Int, x: Double, y: Double, _ c: Sketch.Colour = .ink) {
        for i in 0..<n {
            let bx = x + 5 * Double(i / 5), j = i % 5
            if j < 4 { pen.line("\(id)\(i)", [(bx + 0.5 + Double(j), y), (bx + 0.5 + Double(j), y + 3)], c) }
            else { pen.line("\(id)\(i)", [(bx - 0.2, y + 2.6), (bx + 3.7, y + 0.4)], c) }
        }
    }
    /// The right edge of n tally marks from column x.
    static func tallyEnd(_ n: Int, x: Double) -> Double {
        guard n > 0 else { return x }
        let m = n - 1
        return x + 5 * Double(m / 5) + (m % 5 == 4 ? 3.7 : Double(m % 5) + 0.5)
    }
    /// A tick in green (right), from (x, y) about 1.5 squares wide.
    static func tick(_ pen: inout GridPen, _ id: String, x: Double, y: Double) {
        pen.line(id, [(x, y), (x + 0.5, y + 0.5), (x + 1.5, y - 0.6)], Bars.green)
    }

    /// A bar of n blocks from column x on row y, 4 squares tall: tinted (lit: darker), the chapter's outline, a line between
    /// blocks.
    static func bar(_ pen: inout GridPen, _ id: String, x: Double, y: Double, _ n: Int, lit: Bool = false) {
        guard n > 0 else { return }
        let w = 5 * Double(n)
        pen.fill("\(id)f\(lit)", col: x, row: y, w: w, h: 4, .tint(lit ? 0.4 : 0.2))
        pen.sketch.box("\(id)o\(n)", pen.R(x, y, w, 4), .chapter, width: Sketch.stroke)
        var segs: [(CGPoint, CGPoint)] = []
        for k in 1..<max(1, n) { segs.append((pen.P(x + 5 * Double(k), y), pen.P(x + 5 * Double(k), y + 4))) }
        if !segs.isEmpty { pen.sketch.segments("\(id)l\(n)", segs, .chapter, width: Sketch.stroke) }
    }
    /// A bar's end to drag: a small triangle pointing right, in the middle of its row.
    static func handle(_ pen: inout GridPen, _ id: String, x: Double, y: Double) {
        pen.sketch.polygon(id, [pen.P(x + 0.3, y + 1.4), pen.P(x + 1.1, y + 2), pen.P(x + 0.3, y + 2.6)], .chapter)
    }
    /// The scale: an up line from row top at column x to row y, then 0 to max along row y a block apart, numbered under
    /// (lit numbers in the chapter colour).
    static func scale(_ pen: inout GridPen, x: Double, top: Double, y: Double, max: Int, lit: Set<Int> = []) {
        pen.line("ax", [(x, top), (x, y)])
        pen.line("sc", [(x, y), (x + 5 * Double(max), y)])
        var segs: [(CGPoint, CGPoint)] = []
        for v in 0...max { segs.append((pen.P(x + 5 * Double(v), y), pen.P(x + 5 * Double(v), y + 1))) }
        pen.sketch.segments("sk", segs, .ink, width: Sketch.stroke)
        for v in 0...max {
            let on = lit.contains(v)
            pen.word("sn\(v)\(on)", "\(v)", at: x + 5 * Double(v), y + 2, on ? KK.lit : small)
        }
    }
    /// An X in its cell (a block wide, h squares tall), its top-left at (x, top).
    static func xMark(_ pen: inout GridPen, _ id: String, x: Double, top: Double, h: Double, _ c: Sketch.Colour = .ink) {
        let cx = x + 2.5, i = h >= 3 ? 0.5 : 0.35, d = h >= 3 ? 1.0 : 0.8
        pen.line(id + "a", [(cx - d, top + i), (cx + d, top + h - i)], c)
        pen.line(id + "b", [(cx - d, top + h - i), (cx + d, top + i)], c)
    }
    /// The readout, in the chapter colour, its right end at column x (the title row's right end).
    static func readoutEnd(_ pen: inout GridPen, _ text: String, x: Double, y: Double) {
        pen.word("ro", text, at: x, y, KK.words.colour(.chapter), anchor: UnitPoint(x: 1, y: 0.5))
    }
}
