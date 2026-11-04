import SwiftUI

/// What Kindergarten's lessons share (design/gradeK.md "What every K lesson shares", the preview
/// design/prototype/gradeK-ch1.html), built once for K and 1st grade: one block (5 × 5 squares) is one thing: a counter
/// is a dot 3 squares across in the middle of its block, a cube fills its block; the ten track (ten outlined blocks) is
/// K's number line; and every number a child writes is tapped on **the number row**, a row of number blocks drawn on the
/// paper under the record (0–10, each a block wide and 4 squares tall, 0 a block left of the start line so 1–10 sit
/// under the track's blocks). The tapped number fills the record's box; no keyboard.
@MainActor
enum KK {
    static let maths = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)
    /// A number written on a thing as it's counted.
    static let count = Sketch.Words(size: Sketch.wordSize, weight: .semibold, colour: .ink)
    static let words = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)
    static let lit = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .chapter)
    static let red = Bars.red
    /// A cube, and a lit one.
    static let cube = Sketch.Colour.tint(0.2), litCube = Sketch.Colour.tint(0.45)

    // MARK: things counted

    /// A counter: a dot 3 squares across centred at (cx, cy). Not counted yet, it's solid; counted, it's lighter, outlined,
    /// and carries its number. `ring`: the last number, ringed (it names the group).
    static func counter(_ pen: inout GridPen, _ id: String, _ cx: Double, _ cy: Double, num: Int?, ring: Bool = false) {
        if let num {
            pen.dot(id + "c", at: cx, cy, radius: 1.5, .tint(0.42))
            pen.circle(id + "o", at: cx, cy, radius: 1.5, .chapter)
            pen.word(id + "n", "\(num)", at: cx, cy, count)
        } else {
            pen.dot(id + "d", at: cx, cy, radius: 1.5, .chapter)
        }
        if ring { pen.circle(id + "r", at: cx, cy, radius: 2.05, .chapter) }
    }

    /// The ten track: a row of ten outlined blocks from (x, y); dashed blocks when it waits for a train.
    static func track(_ pen: inout GridPen, _ id: String, x: Double, y: Double, dashed: Bool = false, _ colour: Sketch.Colour = .ink) {
        if dashed {
            for i in 0..<10 { pen.sketch.box("\(id)b\(i)", pen.R(x + Double(i) * 5, y, 5, 5), colour, width: Sketch.stroke, dashed: true) }
            return
        }
        pen.sketch.box(id + "o", pen.R(x, y, 50, 5), colour, width: Sketch.stroke)
        pen.sketch.segments(id + "l", (1..<10).map { i in (pen.P(x + Double(i) * 5, y), pen.P(x + Double(i) * 5, y + 5)) }, colour, width: Sketch.stroke)
    }

    /// A train of `m` cubes from (x, y), a block each: filled (lit ones darker), outlined in the chapter's colour, each
    /// numbered when `nums`. `dashTop`: its top edge dashed (a stair that goes on up). `red`: cubes from this one on are
    /// too many (outlined and numbered in red, the colour of wrong).
    static func train(_ pen: inout GridPen, _ id: String, x: Double, y: Double, _ m: Int, nums: Bool = false, lit: (Int) -> Bool = { _ in false },
                      dashTop: Bool = false, red: Int? = nil) {
        guard m > 0 else { return }
        for j in 0..<m {
            let l = lit(j)
            pen.fill("\(id)f\(j)\(l ? "L" : "")", col: x + Double(j) * 5, row: y, w: 5, h: 5, l ? litCube : cube)
            if nums { pen.word("\(id)n\(j)", "\(j + 1)", at: x + Double(j) * 5 + 2.5, y + 2.5, red.map { j >= $0 } == true ? count.colour(KK.red) : count) }
        }
        let good = min(m, red ?? m), end = x + Double(good) * 5
        if dashTop { pen.line("\(id)top", [(x, y), (end, y)], .chapter, dashed: true) } else { pen.line("\(id)top\(good)", [(x, y), (end, y)], .chapter) }
        pen.line("\(id)bot\(good)", [(x, y + 5), (end, y + 5)], .chapter)
        pen.sketch.segments("\(id)v\(good)", (0...good).map { j in (pen.P(x + Double(j) * 5, y), pen.P(x + Double(j) * 5, y + 5)) }, .chapter, width: Sketch.stroke)
        if let r = red, m > r {
            for j in r..<m { pen.sketch.box("\(id)x\(j)", pen.R(x + Double(j) * 5, y, 5, 5), KK.red, width: Sketch.stroke) }
        }
    }

    /// The cubes a drag along a track has made, from where the finger is (`x` squares from the start line): a whole
    /// cube for each block passed, 0 to 10.
    static func cubes(at x: Double, from x0: Double = 0, rounding: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> Int {
        max(0, min(10, Int(((x - x0) / 5).rounded(rounding))))
    }

    // MARK: rings and labels

    /// A hint: a dashed ring round a place (the general area after a first miss, the exact spot after a second).
    static func hint(_ pen: inout GridPen, _ id: String, _ cx: Double, _ cy: Double, radius: Double = 2.6) {
        pen.circle(id, at: cx, cy, radius: radius, .chapter, dashed: true)
    }
    /// A dashed ring round some squares.
    static func hintBox(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double) {
        pen.sketch.box(id, pen.R(x - 0.5, y - 0.5, w + 1, h + 1), .chapter, width: Sketch.stroke, dashed: true)
    }
    /// A ring round a run of things in a row (the dots with no partner, the extra cubes): a long rounded outline.
    static func stadium(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double, _ colour: Sketch.Colour = .chapter) {
        let r = h / 2
        var pts: [(Double, Double)] = []
        for i in 0...12 { let a = -Double.pi / 2 + Double(i) / 12 * .pi; pts.append((x + w - r + r * cos(a), y + r + r * sin(a))) }
        for i in 0...12 { let a = Double.pi / 2 + Double(i) / 12 * .pi; pts.append((x + r + r * cos(a), y + r + r * sin(a))) }
        pts.append(pts[0])
        pen.line(id, pts, colour)
    }
    /// How wide words are, in squares.
    static func width(_ s: String, _ w: Sketch.Words) -> Double { PaperText.width(s, PaperText.font(w.size, w.weight, digits: true)) / Paper.cell }

    // MARK: the number row

    /// The number row's top-left corner for 0 is a block left of `x0`; each key is a block wide.
    static func key(_ v: Int, x0: Double = 0) -> CGRect { CGRect(x: x0 + Double(v - 1) * 5, y: 0, width: 5, height: 4) }
    /// The number row on row `y`: 0–10 in blocks, the one tapped that's wrong in red (red only for wrong); a hint's
    /// dashed ring round `spot`.
    static func numberRow(_ pen: inout GridPen, _ id: String, y: Double, x0: Double = 0, wrong: Int? = nil, spot: Int? = nil) {
        // the wrong one last, so its red edges lie over its neighbours' ink
        for v in CountK.row.filter({ $0 != wrong }) + CountK.row.filter({ $0 == wrong }) {
            let r = key(v, x0: x0), bad = wrong == v
            pen.sketch.box("\(id)k\(v)\(bad)", pen.R(r.minX, y, 5, 4), bad ? KK.red : .ink, width: Sketch.stroke)
            pen.word("\(id)t\(v)\(bad)", "\(v)", at: r.midX, y + 2, bad ? maths.colour(KK.red) : maths)
        }
        if let spot { let r = key(spot, x0: x0); hintBox(&pen, "\(id)spot", x: r.minX, y: y, w: 5, h: 4) }
    }
    /// The number tapped on the row at `y` (nil: not on a key).
    static func tapped(_ q: CGPoint, y: Double, x0: Double = 0) -> Int? {
        guard q.y >= y, q.y <= y + 4 else { return nil }
        return CountK.row.first { key($0, x0: x0).contains(CGPoint(x: q.x, y: q.y - y)) }
    }
    /// The middle of key `v` on the row at `y`: where the ghost finger taps.
    static func keySpot(_ v: Int, y: Double, x0: Double = 0) -> CGPoint { let r = key(v, x0: x0); return CGPoint(x: r.midX, y: y + 2) }

    // MARK: the record

    /// The record's box, 4 squares wide and 2 tall, from column x on the row whose middle is `line`: what was tapped in it
    /// (red when it's wrong), or empty.
    static func box(_ pen: inout GridPen, _ id: String, x: Double, line: Double, value: Int?, wrong: Bool) {
        let c: Sketch.Colour = wrong ? KK.red : .ink
        pen.sketch.box("\(id)b\(wrong)", pen.R(x, line - 1, 4, 2), c, width: Sketch.stroke)
        if let value { pen.word("\(id)v\(value)\(wrong)", "\(value)", at: x + 2, line, maths.colour(c)) }
    }
    /// A record line with the box at its end: its words and numbers (M7's tight line), then the box half a square on.
    static func line(_ pen: inout GridPen, _ id: String, _ toks: [M7.Tok], value: Int?, wrong: Bool, x: Double = 0, line: Double = 1) {
        let end = toks.isEmpty ? x : M7.row(&pen, id, toks, x: x, line: line)
        box(&pen, id + "box", x: toks.isEmpty ? x : (end + 0.5).rounded(.up), line: line, value: value, wrong: wrong)
    }
    /// What's been tapped into a step's box, and whether it's wrong (it isn't what the step wants).
    static func typed(_ s: PaperState, _ box: String, want: Int) -> (value: Int?, wrong: Bool) {
        guard let t = s.typed[box], let v = Double(t) else { return (nil, false) }
        let x = Int(v.rounded())
        return (x, x != want)
    }

    // MARK: seeds

    /// Parts new to a drawing start from where `build` draws them (Sketch.from): the last dot counted glides from where it
    /// was, as the dots counted before it do.
    static func from(_ pen: inout GridPen, _ build: (inout GridPen) -> Void) {
        var was = GridPen()
        build(&was)
        for it in was.sketch.items { pen.sketch.from[it.id] = it.kind }
    }
}
