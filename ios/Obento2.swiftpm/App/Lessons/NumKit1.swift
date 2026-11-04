import SwiftUI

/// What 1st grade's chapter 3, Numbers to 120, shares on the paper (the preview design/prototype/grade1-ch3.html): the 120
/// chart (K's hundred chart grown to 12 rows, one block a number, ten to a row, so every row is a ten), drawn a few rows
/// at a time from row `r0`; its numbers small in their blocks, or big (one square a digit) with the tens digit lit and the
/// ones underlined; a chart place used as a box written with the digit pad; and the finger's walk, every half square on
/// the way visited, so a quick drag never skips a place.
@MainActor
enum N1 {
    /// Number v's block on the chart drawn from row r0: its top-left, its middle.
    static func block(_ v: Int, _ r0: Int) -> CGPoint { CGPoint(x: 5 * Double((v - 1) % 10), y: 5 * Double(Num1.row(v) - r0)) }
    static func mid(_ v: Int, _ r0: Int) -> CGPoint { let b = block(v, r0); return CGPoint(x: b.x + 2.5, y: b.y + 2.5) }
    /// The number under the finger (nil off the chart), or, `clamped`, the nearest one on it.
    static func at(_ q: CGPoint, _ r0: Int, _ rows: Int, clamped: Bool = false) -> Int? {
        var c = Int((q.x / 5).rounded(.down)), r = Int((q.y / 5).rounded(.down))
        if clamped { c = max(0, min(9, c)); r = max(0, min(rows - 1, r)) }
        guard (0...9).contains(c), (0..<rows).contains(r) else { return nil }
        let v = 10 * (r + r0) + c + 1
        return v <= 120 ? v : nil
    }
    /// The chart's lines: its outside in ink, the places' lines fainter.
    static func lines(_ pen: inout GridPen, _ id: String, _ r0: Int, _ rows: Int) {
        let h = 5 * Double(rows)
        pen.sketch.segments("\(id)i\(r0)-\(rows)", (1..<10).map { i in (pen.P(5 * Double(i), 0), pen.P(5 * Double(i), h)) }
                            + (1..<max(1, rows)).map { r in (pen.P(0, 5 * Double(r)), pen.P(50, 5 * Double(r))) }, .ink3, width: Sketch.stroke)
        pen.sketch.box("\(id)o\(r0)-\(rows)", pen.R(0, 0, 50, h), .ink, width: Sketch.stroke)
    }
    /// A number small in its place.
    static func num(_ pen: inout GridPen, _ id: String, _ v: Int, _ r0: Int, lit: Bool = false) {
        let m = mid(v, r0)
        pen.word("\(id)\(v)-\(r0)\(lit ? "L" : "")", "\(v)", at: m.x, m.y, lit ? KT.smallLit : KT.small)
    }
    /// A number big in its place, one square a digit; `lit`: its tens digit in the chapter's colour, its ones underlined.
    static func big(_ pen: inout GridPen, _ id: String, _ v: Int, _ r0: Int, lit: Bool) {
        let m = mid(v, r0), s = Array(String(v))
        for (i, d) in s.enumerated() {
            let cx = m.x + Double(i) - Double(s.count - 1) / 2, tens = i == s.count - 2
            pen.word("\(id)\(v)d\(i)-\(r0)\(lit && tens ? "L" : "")", String(d), at: cx, m.y, lit && tens ? KK.maths.colour(.chapter) : KK.maths)
            if lit && i == s.count - 1 { pen.line("\(id)\(v)u-\(r0)", [(cx - 0.45, m.y + 1.25), (cx + 0.45, m.y + 1.25)]) }
        }
    }
    /// A place filled.
    static func fill(_ pen: inout GridPen, _ id: String, _ v: Int, _ r0: Int, _ colour: Sketch.Colour = KK.cube) {
        let b = block(v, r0); pen.fill("\(id)\(v)-\(r0)", col: b.x, row: b.y, w: 5, h: 5, colour)
    }

    enum Box { case idle, active, wrong, done }
    /// A chart place that's a box: outlined (ink waiting, the chapter's colour while it's written, red when it's wrong), what
    /// was written in it one square a digit (the right number in the chapter's colour).
    static func box(_ pen: inout GridPen, _ id: String, _ v: Int, _ r0: Int, _ state: Box, value: Int?) {
        let b = block(v, r0), m = mid(v, r0)
        let c: Sketch.Colour = state == .wrong ? KK.red : state == .active ? .chapter : .ink
        pen.sketch.box("\(id)o\(state)", pen.R(b.x, b.y, 5, 5), c, width: Sketch.stroke)
        guard let value else { return }
        let s = Array(String(value)), w: Sketch.Words = state == .wrong ? KK.maths.colour(KK.red) : state == .done ? KK.maths.colour(.chapter) : KK.maths
        for (i, d) in s.enumerated() { pen.word("\(id)d\(i)\(d)\(state)", String(d), at: m.x + Double(i) - Double(s.count - 1) / 2, m.y, w) }
    }
    /// The record's box on its own (4 squares wide, 2 tall) from column x on the row whose middle is `line`: done, the
    /// number in the chapter's colour without the box.
    static func record(_ pen: inout GridPen, _ id: String, _ toks: [M7.Tok], value: Int?, wrong: Bool, done: Int? = nil, x: Double = 0, line: Double) {
        if let done { M7.row(&pen, id, toks + [.n(done, .chapter)], x: x, line: line); return }
        KK.line(&pen, id, toks, value: value, wrong: wrong, x: x, line: line)
    }

    /// The points a finger passed from p to q, every half square, q last.
    static func walk(_ p: CGPoint, _ q: CGPoint) -> [CGPoint] {
        let n = max(1, Int((hypot(q.x - p.x, q.y - p.y) / 0.5).rounded(.up)))
        return (1...n).map { i in CGPoint(x: p.x + (q.x - p.x) * Double(i) / Double(n), y: p.y + (q.y - p.y) * Double(i) / Double(n)) }
    }
    /// A held count's state: how many counted, a place skipped, the finger's last point (snapped to half squares).
    static func held(_ c: Int, _ q: CGPoint, skip: Bool = false, dead: Bool = false) -> Numbers {
        ["grab": 1, "c": Double(c), "skip": skip ? 1 : 0, "dead": dead ? 1 : 0, "lx": (q.x * 2).rounded() / 2, "ly": (q.y * 2).rounded() / 2]
    }
    /// Counting along places `from`…`to` on the chart: the finger at q enters a place; the next counts, a later one in the
    /// same row is a skip (cleared by the next that counts).
    static func enter(_ held: inout Numbers, _ v: Int?, from: Int, to: Int) {
        guard let v else { return }
        let c = Int(held["c"] ?? 0), nx = from + c
        guard c < to - from + 1 else { return }
        if v == nx { held["c"] = Double(c + 1); held["skip"] = 0 }
        else if v > nx && v <= to && Num1.row(v) == Num1.row(nx) { held["skip"] = 1 }
    }
}
