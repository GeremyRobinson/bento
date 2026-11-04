import SwiftUI

/// What Kindergarten's Teens and tens chapter shares on the paper (the preview design/prototype/gradeK-ch5.html): a ten
/// frame (5 × 2 blocks, one cell a block), counters in its cells (chapter 1's, KK), the number row grown to 20 (1–10, or
/// 0–10, on one row and 11–20 on the row under it, each key under its block), number keys to pick one numeral, and the
/// numerals' strokes, waiting faint to be traced. The digit pad (DigitPad) writes the numbers past 20.
@MainActor
enum KT {
    static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink)
    static let smallLit = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)

    /// A ten frame from (x, y): 25 × 10 squares, its cells' lines in ink.
    static func frame(_ pen: inout GridPen, _ id: String, x: Double, y: Double) {
        pen.sketch.box(id + "o", pen.R(x, y, 25, 10), .ink, width: Sketch.stroke)
        pen.sketch.segments(id + "l", (1..<5).map { c in (pen.P(x + 5 * Double(c), y), pen.P(x + 5 * Double(c), y + 10)) } + [(pen.P(x, y + 5), pen.P(x + 25, y + 5))],
                            .ink, width: Sketch.stroke)
    }
    /// Cell j (0–9) of the ten frame at (x, y): its middle.
    static func cell(_ x: Double, _ y: Double, _ j: Int) -> CGPoint { CGPoint(x: x + 5 * Double(j % 5) + 2.5, y: y + 5 * Double(j / 5) + 2.5) }

    /// A counter that's been counted but no longer carries its number (the top row once the bottom row is counted on).
    static func counted(_ pen: inout GridPen, _ id: String, _ cx: Double, _ cy: Double) {
        pen.dot(id + "c", at: cx, cy, radius: 1.5, .tint(0.42))
        pen.circle(id + "o", at: cx, cy, radius: 1.5, .chapter)
    }
    /// A counter tapped that's wrong (counted already, or not to count yet): ringed red until the next right tap.
    static func again(_ pen: inout GridPen, _ id: String, _ p: CGPoint) { pen.circle(id, at: p.x, p.y, radius: 2.05, KK.red) }

    /// The index of the thing under the finger, from their middles (a block each).
    static func hit(_ q: CGPoint, _ at: [CGPoint]) -> Int? { at.firstIndex { abs(q.x - $0.x) <= 2.5 && abs(q.y - $0.y) <= 2.5 } }

    // MARK: the number row grown to 20

    /// `lo`–10 on row y (key v under block v), 11–20 on the row a block under it (11 under block 1).
    static func twenty(_ pen: inout GridPen, _ id: String, y: Double, lo: Int = 1, wrong: Int? = nil, spot: Int? = nil) {
        KK.numberRow(&pen, id + "a", y: y, wrong: wrong.flatMap { $0 <= 10 ? $0 : nil }, spot: spot.flatMap { $0 <= 10 ? $0 : nil }, keys: lo...10)
        KK.numberRow(&pen, id + "b", y: y + 5, x0: -50, wrong: wrong.flatMap { $0 > 10 ? $0 : nil }, spot: spot.flatMap { $0 > 10 ? $0 : nil }, keys: 11...20)
    }
    static func tappedTwenty(_ q: CGPoint, y: Double, lo: Int = 1) -> Int? {
        KK.tapped(q, y: y, keys: lo...10) ?? KK.tapped(q, y: y + 5, x0: -50, keys: 11...20)
    }
    static func twentySpot(_ v: Int, y: Double) -> CGPoint { v <= 10 ? KK.keySpot(v, y: y) : KK.keySpot(v, y: y + 5, x0: -50) }

    // MARK: number keys to pick from

    /// Keys in a row, each `w` squares wide and 4 tall, `gap` apart, from (x, y): the wrong one picked in red.
    static func keys(_ pen: inout GridPen, _ id: String, _ vals: [Int], x: Double, y: Double, w: Double, step: Double, wrong: Int? = nil, spot: Int? = nil) {
        for (i, v) in vals.enumerated() {
            let kx = x + step * Double(i), bad = wrong == v
            pen.sketch.box("\(id)k\(v)\(bad)", pen.R(kx, y, w, 4), bad ? KK.red : .ink, width: Sketch.stroke)
            pen.word("\(id)t\(v)\(bad)", "\(v)", at: kx + w / 2, y + 2, bad ? KK.maths.colour(KK.red) : KK.maths)
            if spot == v { KK.hintBox(&pen, "\(id)spot", x: kx, y: y, w: w, h: 4) }
        }
    }
    static func keyTapped(_ q: CGPoint, _ vals: [Int], x: Double, y: Double, w: Double, step: Double) -> Int? {
        guard q.y >= y, q.y <= y + 4 else { return nil }
        return vals.indices.first { q.x >= x + step * Double($0) && q.x <= x + step * Double($0) + w }.map { vals[$0] }
    }
    static func keyAt(_ i: Int, x: Double, y: Double, w: Double, step: Double) -> CGPoint { CGPoint(x: x + step * Double(i) + w / 2, y: y + 2) }

    // MARK: numerals to trace

    /// A numeral's strokes as the paper's points.
    static func points(_ pen: GridPen, _ stroke: [Numerals.Pt]) -> [CGPoint] { stroke.map { pen.P($0.x, $0.y) } }
    /// The numeral waiting faint where it's traced: each stroke a wide pale band (1.2 squares).
    static func band(_ pen: inout GridPen, _ id: String, _ strokes: [[Numerals.Pt]], _ colour: Sketch.Colour = .tint(0.16)) {
        for (i, s) in strokes.enumerated() { pen.sketch.line("\(id)\(i)", points(pen, s), colour, width: 24) }
    }
    /// The traced part of a stroke: the band darker and the line through it in the chapter's colour.
    static func ink(_ pen: inout GridPen, _ id: String, _ stroke: [Numerals.Pt], upTo k: Int) {
        guard k > 0 else { return }
        let pts = points(pen, Array(stroke[0...min(k, stroke.count - 1)]))
        pen.sketch.line(id + "b", pts, .tint(0.34), width: 24)
        pen.sketch.line(id + "l", pts, .chapter, width: Sketch.stroke)
    }
}
