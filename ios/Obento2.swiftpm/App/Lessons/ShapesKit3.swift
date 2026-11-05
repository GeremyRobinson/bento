import SwiftUI

/// What 3rd grade's chapter 4, Shapes and area, shares on the paper (the preview design/prototype/grade3-ch4.html): a
/// rectangle of tiles where one square of the grid is one square unit (its inner lines faint, its outline ink, tiles
/// tinted), the side names and counts in small words, a tick on every square of a fence, and the record's word lines.
@MainActor
enum S3P {
    static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink)
    static let lit = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)
    static let tint = Sketch.Colour.tint(0.2)

    /// rows × cols squares from (x, y): the faint inner lines and the ink outline (`outline`).
    static func tiles(_ pen: inout GridPen, _ id: String, x: Double, y: Double, rows: Int, cols: Int, outline: Bool = true) {
        M3.array(&pen, id, x: x, y: y, rows: rows, cols: cols, c: 1, outline: outline, dots: false)
    }
    /// Tints the first `n` squares of the row from (x, y), one by one (each its own, so they draw in as they're laid).
    static func lay(_ pen: inout GridPen, _ id: String, x: Double, y: Double, n: Int) {
        for j in 0..<max(0, n) { pen.fill("\(id)\(j)", col: x + Double(j), row: y, w: 1, h: 1, tint) }
    }
    /// A count at a row's right end, in the chapter colour.
    static func count(_ pen: inout GridPen, _ id: String, _ text: String, x: Double, y: Double) {
        pen.word(id, text, at: x + 0.5, y, lit, anchor: UnitPoint(x: 0, y: 0.5))
    }
    /// A tick across the outline at every square of a p × q rectangle from (x, y): the fence counted.
    static func fence(_ pen: inout GridPen, _ id: String, x: Double, y: Double, p: Int, q: Int) {
        var segs: [(CGPoint, CGPoint)] = []
        for j in 1..<max(1, p) { for yy in [y, y + Double(q)] { segs.append((pen.P(x + Double(j), yy - 0.4), pen.P(x + Double(j), yy + 0.4))) } }
        for i in 1..<max(1, q) { for xx in [x, x + Double(p)] { segs.append((pen.P(xx - 0.4, y + Double(i)), pen.P(xx + 0.4, y + Double(i)))) } }
        if !segs.isEmpty { pen.sketch.segments("\(id)\(p)x\(q)", segs, .ink, width: Sketch.stroke) }
    }
    /// A record line of words (the quadrilateral's "2 square corners"), its number then its words.
    static func wordLine(_ pen: inout GridPen, _ id: String, _ n: Int?, _ words: String, colour: Sketch.Colour = .ink, x: Double = 0, line: Double) {
        var toks: [M7.Tok] = []
        if let n { toks.append(.n(n)) }
        toks.append(.w(words, colour))
        M7.row(&pen, id, toks, x: x, line: line)
    }
}
