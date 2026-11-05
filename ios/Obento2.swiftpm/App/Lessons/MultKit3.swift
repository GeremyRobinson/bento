import SwiftUI

/// What 3rd grade's chapter 1, Multiply and divide, shares on the paper (the preview design/prototype/grade3-ch1.html): an
/// array of things (a dot in a cell of 5, 4 or 3 squares, the cells faint over the paper, its outline in ink), a bracket
/// down its side with its name, the open edge a finger drags a cell at a time (in the chapter colour, a dot to hold it by),
/// the rows lit one by one with their counts at their right ends, and a record line written tight (`6 × 4 = [ ]`).
@MainActor
enum M3 {
    static let maths = KK.maths, lit = KK.lit
    /// The array's top-left: a block in (room for the bracket and its name), 3 rows down (room for its top name), so the
    /// biggest array (30 squares) shows at 75% with its words.
    static let X0 = 5.0, Y0 = 3.0
    static func dotR(_ c: Double) -> Double { c * 0.24 }

    /// rows × cols cells of c squares from (x, y): the faint inner lines, the outline, a dot in each cell (the first `n`);
    /// `over`: the dots as plates, over a lit row's band (two fills over each other fight).
    static func array(_ pen: inout GridPen, _ id: String, x: Double, y: Double, rows: Int, cols: Int, c: Double, outline: Bool = true, dots: Bool = true, n: Int? = nil, over: Bool = false) {
        guard rows > 0, cols > 0 else { return }
        var segs: [(CGPoint, CGPoint)] = []
        for i in 1..<max(1, cols) { segs.append((pen.P(x + Double(i) * c, y), pen.P(x + Double(i) * c, y + Double(rows) * c))) }
        for j in 1..<max(1, rows) { segs.append((pen.P(x, y + Double(j) * c), pen.P(x + Double(cols) * c, y + Double(j) * c))) }
        if !segs.isEmpty { pen.sketch.segments(id + "g\(rows)x\(cols)", segs, .ink3, width: 1) }
        if outline { pen.sketch.box(id + "o", pen.R(x, y, Double(cols) * c, Double(rows) * c), .ink, width: Sketch.stroke) }
        guard dots else { return }
        for i in 0..<rows {
            for j in 0..<cols where n.map({ i * cols + j < $0 }) ?? true {
                pen.dot("\(id)d\(i).\(j)", at: x + (Double(j) + 0.5) * c, y + (Double(i) + 0.5) * c, radius: dotR(c), over: over)
            }
        }
    }

    /// A bracket down the left (`left`) or right side at column x from y1 to y2: dashed while it's still open; its name
    /// beside it, centred on it.
    static func bracket(_ pen: inout GridPen, _ id: String, x: Double, y1: Double, y2: Double, open: Bool, left: Bool = true, name: String?, _ colour: Sketch.Colour = .ink) {
        let t = left ? 0.6 : -0.6
        pen.line("\(id)\(open)", [(x, y1), (x, y2)], .ink, dashed: open)
        pen.line(id + "t1", [(x, y1), (x + t, y1)]); pen.line(id + "t2", [(x, y2), (x + t, y2)])
        if let name { pen.label(id + "n", name, maths.colour(colour), left ? .left : .right, edge: x, along: (y1 + y2) / 2) }
    }
    /// A name still to find: an empty box where its number goes, 4 × 2 squares round (cx, cy).
    static func nameBox(_ pen: inout GridPen, _ id: String, cx: Double, cy: Double) {
        pen.sketch.box(id + "nb", pen.R(cx.rounded() - 2, cy.rounded() - 1, 4, 2), .ink3, width: Sketch.stroke)
    }

    /// The open edge being dragged: the rows' bottom edge (`rows`) or the columns' right edge at `at`, `span` squares long,
    /// in the chapter colour with a dot to hold it by in its middle.
    static func edge(_ pen: inout GridPen, rows: Bool, x: Double, y: Double, at e: Double, span: Double, held: Bool) {
        if rows {
            pen.line("edge", [(x, e), (x + span, e)], .chapter)
            pen.dot("edgeh", at: x + span / 2, e, radius: held ? 0.7 : 0.55)
        } else {
            pen.line("edge", [(e, y), (e, y + span)], .chapter)
            pen.dot("edgeh", at: e, y + span / 2, radius: held ? 0.7 : 0.55)
        }
    }
    /// Is q on the open edge (a finger's width either side, along its length)?
    static func onEdge(_ q: CGPoint, rows: Bool, x: Double, y: Double, at e: Double, span: Double) -> Bool {
        let along = rows ? q.x - x : q.y - y, across = rows ? q.y - e : q.x - e
        return abs(across) <= 2.2 && along >= -2 && along <= span + 2
    }

    /// The rows lit one by one, each count (by `by`) at its right end; the last only when `last`.
    static func countRows(_ pen: inout GridPen, _ id: String, x: Double, y: Double, rows: Int, cols: Int, c: Double, by: Int, last: Bool) {
        for i in 0..<rows {
            pen.fill("\(id)lit\(i)", col: x, row: y + Double(i) * c, w: Double(cols) * c, h: c, .tint(0.2))
            if i < rows - 1 || last { pen.word("\(id)n\(i)", "\((i + 1) * by)", at: x + Double(cols) * c + 0.5, y + (Double(i) + 0.5) * c, lit, anchor: UnitPoint(x: 0, y: 0.5)) }
        }
    }
    /// A thing taken away: crossed out where it sits.
    static func cross(_ pen: inout GridPen, _ id: String, cx: Double, cy: Double, c: Double) {
        let r = c * 0.32
        pen.line(id + "x", [(cx - r, cy + r), (cx + r, cy - r)])
    }

    /// A box, or once it's right its number in the chapter colour.
    static func box(_ id: String, _ want: Int, cells: Int, right: Bool) -> M7.Tok { right ? .n(want, .chapter) : .box(id, cells: cells) }
    /// The cells a typed number needs.
    static func cells(_ v: Int) -> Int { v >= 100 ? 3 : 2 }
}
