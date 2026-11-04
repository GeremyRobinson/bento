import SwiftUI

/// What 1st grade's chapter 2, Equations and stories, adds to chapter 1's kit (A1) on the paper (the preview
/// design/prototype/grade1-ch2.html): the whole as a row of places outlined in ink; a bracket under (or over) a run with its
/// number; a place a counter left, dashed (crossed once it's gone); the flag on the line; a word block (True / False).
@MainActor
enum E1 {
    /// The whole as a row of n places from (x, y), outlined in ink, its places dashed.
    static func whole(_ pen: inout GridPen, _ id: String, x: Double, y: Double, _ n: Int) {
        pen.sketch.box("\(id)o\(n)", pen.R(x, y, 3 * Double(n), 3), .ink, width: Sketch.stroke)
        for i in 1..<max(1, n) { pen.line("\(id)d\(i)", [(x + 3 * Double(i), y), (x + 3 * Double(i), y + 3)], .ink3, dashed: true) }
    }
    /// A bracket under a run from x1 to x2 on row y (its ticks up toward the run), its name under it; `up`: over the run,
    /// its name over it.
    static func bracket(_ pen: inout GridPen, _ id: String, _ x1: Double, _ x2: Double, y: Double, _ label: String?, up: Bool = false,
                        _ colour: Sketch.Colour = .ink2, words: Sketch.Words = KK.maths) {
        let t = up ? 0.6 : -0.6
        pen.line("\(id)\(x1)_\(x2)", [(x1, y + t), (x1, y), (x2, y), (x2, y + t)], colour)
        if let label { pen.word("\(id)t\(x1)_\(x2)", label, at: (x1 + x2) / 2, y + (up ? -1.1 : 1.3), words) }
    }
    /// A place a counter left, or a partner still to come: a dashed empty circle, crossed once it's gone.
    static func ghost(_ pen: inout GridPen, _ id: String, x: Double, y: Double, crossed: Bool = false, _ colour: Sketch.Colour = .ink3) {
        pen.circle(id, at: x + 1.5, y + 1.5, radius: A1.r, colour, dashed: true)
        if crossed { pen.line(id + "x", [(x + 0.4, y + 2.6), (x + 2.6, y + 0.4)], .ink3) }
    }
    /// The flag on the number line at column x (the line on row y): the end you hop to.
    static func flag(_ pen: inout GridPen, _ id: String, x: Double, y: Double) {
        pen.line(id + "p", [(x, y), (x, y - 4.5)])
        pen.sketch.polygon(id + "f", [pen.P(x, y - 4.5), pen.P(x + 2, y - 3.8), pen.P(x, y - 3.1)], .tint(0.45))
        pen.line(id + "o", [(x, y - 4.5), (x + 2, y - 3.8), (x, y - 3.1)])
    }
    /// A word block on the paper (True / False), w × 4 squares, its word in the middle; green once picked right, red wrong.
    static func block(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, _ label: String, right: Bool = false, wrong: Bool = false) {
        let c: Sketch.Colour = wrong ? KK.red : right ? Bars.green : .ink
        pen.sketch.box("\(id)o\(right)\(wrong)", pen.R(x, y, w, 4), c, width: Sketch.stroke)
        pen.word("\(id)w\(right)\(wrong)", label, at: x + w / 2, y + 2, KK.words.colour(c))
    }
    /// The numbers 1, 2, 3… written small over (or under) a run of counters from counter `from`, row y: counted as they come.
    static func counts(_ pen: inout GridPen, _ id: String, from: Int, _ n: Int, y: Double) {
        for j in 0..<n { pen.word("\(id)\(j)", "\(j + 1)", at: A1.x(from + j) + 1.5, y, KK.lit) }
    }
    /// A run of numbers for a readout: "6, 7, 8" or "6, 7 … 12".
    static func run(_ ns: [Int]) -> String {
        ns.count > 4 ? "\(ns[0]), \(ns[1]) … \(ns[ns.count - 1])" : ns.map(String.init).joined(separator: ", ")
    }
}
