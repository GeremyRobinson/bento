import SwiftUI

/// What 3rd grade's chapter 4, Shapes and area, shares on the paper (the preview design/prototype/grade3-ch4.html): a
/// rectangle of tiles c squares a side (5, 4 or 3, the biggest that shows the problem at 75%; its inner lines faint, its
/// outline ink, tiles tinted), the side names (`name`) and counts (`num`) in words-size type, a tick on
/// every unit of a fence, and the record's word lines.
@MainActor
enum S3P {
    static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink)
    static let lit = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)
    static let tint = Sketch.Colour.tint(0.2)
    static let name = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
    static let num = Sketch.Words(size: Sketch.wordSize, weight: .semibold, colour: .chapter)
    static let numInk = Sketch.Words(size: Sketch.wordSize, weight: .semibold, colour: .ink)

    /// rows × cols tiles of c squares from (x, y): the faint inner lines and the ink outline (`outline`).
    static func tiles(_ pen: inout GridPen, _ id: String, x: Double, y: Double, rows: Int, cols: Int, c: Double, outline: Bool = true) {
        M3.array(&pen, id, x: x, y: y, rows: rows, cols: cols, c: c, outline: outline, dots: false)
    }
    /// Tints the first `n` tiles of the row from (x, y), one by one (each its own, so they draw in as they're laid).
    static func lay(_ pen: inout GridPen, _ id: String, x: Double, y: Double, n: Int, c: Double) {
        for j in 0..<max(0, n) { pen.fill("\(id)\(j)", col: x + Double(j) * c, row: y, w: c, h: c, tint) }
    }
    /// A count at a row's right end (y its middle), in the chapter colour.
    static func count(_ pen: inout GridPen, _ id: String, _ text: String, x: Double, y: Double) {
        pen.word(id, text, at: x + 0.6, y, num, anchor: UnitPoint(x: 0, y: 0.5))
    }
    /// A tick across the outline at every unit (c squares) of a p × q rectangle from (x, y): the fence counted.
    static func fence(_ pen: inout GridPen, _ id: String, x: Double, y: Double, p: Int, q: Int, c: Double) {
        var segs: [(CGPoint, CGPoint)] = []
        let t = 0.4 + 0.1 * c, X1 = x + Double(p) * c, Y1 = y + Double(q) * c
        for j in 1..<max(1, p) { for yy in [y, Y1] { segs.append((pen.P(x + Double(j) * c, yy - t), pen.P(x + Double(j) * c, yy + t))) } }
        for i in 1..<max(1, q) { for xx in [x, X1] { segs.append((pen.P(xx - t, y + Double(i) * c), pen.P(xx + t, y + Double(i) * c))) } }
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
