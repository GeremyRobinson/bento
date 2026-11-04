import SwiftUI

/// What 1st grade's chapter 4, Adding and taking away tens, shares on the paper (the preview
/// design/prototype/grade1-ch4.html): a number is its tens and its ones. A ten is ten counters in a closed row (faint dashed
/// inner lines, the chapter's outline), tens stacked touching; the ones a square under them, each counter in its own
/// outlined place. The second number stands a block to the right (from column 35), striped. The names on the row whose
/// middle is `line`: a at its stack's right end, the sign in the gap, b at its stack's start; the record goes on after b.
@MainActor
enum T1 {
    static let line = 1.0, top = 3.0, bx = 35.0, signX = 32.5
    /// The pad (a grid) and the readouts beside a stack: from column 35, under the readout row.
    static let padY = 7.0, noteY = 4.5

    /// A closed ten from (x, y): its counters (ids "\(id)-0"…"\(id)-9", or `ids`), dashed inner lines, the outline.
    static func ten(_ pen: inout GridPen, _ id: String, x: Double, y: Double, _ styles: [A1.Style], ids: [String]? = nil, cross: Bool = false) {
        for j in 0..<10 { A1.counter(&pen, ids?[j] ?? "\(id)-\(j)", x: x + A1.x(j), y: y, styles[min(j, styles.count - 1)], cross: cross) }
        for j in 1..<10 { pen.line("\(id)d\(j)", [(x + A1.x(j), y), (x + A1.x(j), y + 3)], .ink3, dashed: true) }
        pen.sketch.box("\(id)g", pen.R(x, y, 30, 3), .chapter, width: Sketch.stroke)
    }
    /// A loose one: a counter in its own outlined place.
    static func one(_ pen: inout GridPen, _ id: String, x: Double, y: Double, _ style: A1.Style) {
        pen.sketch.box("\(id)p", pen.R(x, y, 3, 3), .ink2, width: Sketch.stroke)
        A1.counter(&pen, id, x: x, y: y, style)
    }
    /// The names line: a ending at column 30, the sign in the gap, b from column 35. Returns where the record goes on.
    @discardableResult
    static func names(_ pen: inout GridPen, _ a: Int, _ sign: String, _ b: Int) -> Double {
        pen.word("na\(a)", "\(a)", at: 30, line, KK.maths, anchor: UnitPoint(x: 1, y: 0.5))
        pen.word("ns", sign, at: signX, line, KK.maths)
        pen.word("nb\(b)", "\(b)", at: bx, line, KK.maths, anchor: UnitPoint(x: 0, y: 0.5))
        return (bx + KK.width("\(b)", KK.maths) + 0.5).rounded(.up)
    }
    /// Each part `draw` makes, by id, as it would be drawn: where parts start from (Sketch.from) or pass through (via).
    static func kinds(_ draw: (inout GridPen) -> Void) -> [String: Sketch.Kind] {
        var p = GridPen()
        draw(&p)
        var out: [String: Sketch.Kind] = [:]
        for it in p.sketch.items where out[it.id] == nil { out[it.id] = it.kind }
        return out
    }
    /// "1 ten, 2 tens, 3 tens".
    static func tensRun(_ k: Int) -> String { Tens1.tensRun(k) }
}
