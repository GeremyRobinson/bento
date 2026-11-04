import SwiftUI

/// What Kindergarten's Measure and sort chapter shares on the paper (the preview design/prototype/gradeK-ch3.html): a
/// thing drawn in thin lines as long as it is (one block one cube of length, 3 squares thick in the middle of its block
/// row or column, its cubes faint across it), its name small beside it, the things a pile is sorted into (a button, a
/// leaf, a block; a circle, a square, a triangle: one colour, so only the shape tells them apart), the record's line
/// with its box in the middle, and parts that start where they were (Sketch.from).
@MainActor
enum KM {
    static let name = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)

    /// A thing `n` cubes long. Lying: from (x, y), y its block row's top. Standing: x its block column's left, y its foot.
    /// `wrong`: tapped and wrong (its outline red).
    static func thing(_ pen: inout GridPen, _ id: String, x: Double, y: Double, _ n: Int, stand: Bool = false, wrong: Bool = false) {
        let L = Double(n) * 5
        if stand {
            pen.fill(id + "f", col: x + 1, row: y - L, w: 3, h: L, .tint(0.2))
            if n > 1 { pen.sketch.segments(id + "l", (1..<n).map { j in (pen.P(x + 1, y - Double(j) * 5), pen.P(x + 4, y - Double(j) * 5)) }, .ink3, width: Sketch.stroke) }
            pen.sketch.box(id + "o", pen.R(x + 1, y - L, 3, L), wrong ? KK.red : .ink, width: Sketch.stroke)
        } else {
            pen.fill(id + "f", col: x, row: y + 1, w: L, h: 3, .tint(0.2))
            if n > 1 { pen.sketch.segments(id + "l", (1..<n).map { j in (pen.P(x + Double(j) * 5, y + 1), pen.P(x + Double(j) * 5, y + 4)) }, .ink3, width: Sketch.stroke) }
            pen.sketch.box(id + "o", pen.R(x, y + 1, L, 3), wrong ? KK.red : .ink, width: Sketch.stroke)
        }
    }
    /// A ring round a run of cubes, lying or standing (what sticks out): a long rounded outline.
    static func capsule(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, h: Double) {
        if w >= h { KK.stadium(&pen, id, x: x, y: y, w: w, h: h); return }
        let r = w / 2
        var pts: [(Double, Double)] = []
        for i in 0...12 { let a = Double.pi + Double(i) / 12 * .pi; pts.append((x + r + r * cos(a), y + r + r * sin(a))) }
        for i in 0...12 { let a = Double(i) / 12 * .pi; pts.append((x + r + r * cos(a), y + h - r + r * sin(a))) }
        pts.append(pts[0])
        pen.line(id, pts, .chapter)
    }
    /// A lying thing's name, small just above its left end.
    static func nameAbove(_ pen: inout GridPen, _ id: String, _ text: String, x: Double, y: Double) {
        pen.word(id, text, at: x + 0.5, y + 0.25, name, anchor: UnitPoint(x: 0, y: 0.5))
    }

    /// What `build` draws starts where `was` draws it (the same ids, in another place or shape) and goes to its own on the
    /// paper's spring (or swinging, when the sketch swings).
    static func seeded(_ pen: inout GridPen, was: ((inout GridPen) -> Void)?, _ build: (inout GridPen) -> Void) {
        if let was {
            var p = GridPen()
            was(&p)
            for it in p.sketch.items { pen.sketch.from[it.id] = it.kind }
        }
        build(&pen)
        pen.sketch.from = [:]
    }

    /// A record line with its box in the middle: `pre`, the box, `post` ("The pencil is longer by [3] cubes."). Returns
    /// the box's left column.
    @discardableResult
    static func boxLine(_ pen: inout GridPen, _ id: String, pre: String, value: Int?, wrong: Bool, post: String, x: Double, line: Double) -> Double {
        let end = M7.row(&pen, id, [.w(pre)], x: x, line: line), bx = (end + 0.5).rounded(.up)
        KK.box(&pen, id + "box", x: bx, line: line, value: value, wrong: wrong)
        _ = M7.row(&pen, id + "u", [.w(post)], x: bx + 4, line: line)
        return bx
    }
    static func boxLineWidth(pre: String, post: String) -> Double { (M7.width([.w(pre)]) + 0.5).rounded(.up) + 4 + M7.width([.w(post)]) }

    // MARK: sorting

    /// A thing to sort, centred at (cx, cy) in its block: one colour, so only its shape tells it apart; `detail` the little
    /// marks that help (a button's holes, a leaf's vein, a block's square), left off where a number is written on it.
    static func glyph(_ pen: inout GridPen, _ id: String, _ g: String, _ cx: Double, _ cy: Double, fill: Sketch.Colour = .tint(0.2),
                      edge: Sketch.Colour = .chapter, detail: Bool = true, over: Bool = false) {
        // its fill and outline (over a lit block: as plates and lines over them, since two fills at one height flicker);
        // the little marks always lie over it
        func body(_ pts: [CGPoint]) {
            if over { pen.sketch.plate(id + "f", pts, fill); pen.sketch.overLine(id + "o", pts + [pts[0]], edge, width: Sketch.stroke) }
            else { pen.sketch.polygon(id + "f", pts, fill); pen.sketch.line(id + "o", pts + [pts[0]], edge, width: Sketch.stroke) }
        }
        func ring(_ r: Double, _ n: Int = 32) -> [CGPoint] { (0..<n).map { i in let a = Double(i) / Double(n) * 2 * .pi; return pen.P(cx + r * cos(a), cy + r * sin(a)) } }
        switch g {
        case "button", "circle":
            body(ring(1.7))
            if detail && g == "button" {
                for (j, d) in [(-0.5, -0.5), (0.5, -0.5), (-0.5, 0.5), (0.5, 0.5)].enumerated() {
                    let hole = (0...12).map { i -> CGPoint in let a = Double(i) / 12 * 2 * .pi; return pen.P(cx + d.0 + 0.11 * cos(a), cy + d.1 + 0.11 * sin(a)) }
                    pen.sketch.overLine("\(id)h\(j)", hole, edge, width: 0.22 * GridPen.sq)
                }
            }
        case "square", "block":
            body([pen.P(cx - 1.6, cy - 1.6), pen.P(cx + 1.6, cy - 1.6), pen.P(cx + 1.6, cy + 1.6), pen.P(cx - 1.6, cy + 1.6)])
            if detail && g == "block" { pen.sketch.overLine(id + "i", [pen.P(cx - 0.02, cy), pen.P(cx + 0.02, cy)], edge, width: 1.16 * GridPen.sq) }
        case "triangle":
            body([pen.P(cx, cy - 1.8), pen.P(cx + 1.95, cy + 1.5), pen.P(cx - 1.95, cy + 1.5)])
        default:
            // a leaf: two curves bulging 1.1 squares either side of the line from its stalk end to its tip, a vein down it
            let a = (cx - 1.75, cy + 1.0), b = (cx + 1.75, cy - 1.0)
            let mx = (a.0 + b.0) / 2, my = (a.1 + b.1) / 2, dx = b.0 - a.0, dy = b.1 - a.1, L = hypot(dx, dy), nx = -dy / L, ny = dx / L
            var pts: [CGPoint] = []
            for side in [1.0, -1.0] {
                let c = (mx + side * nx * 2.2, my + side * ny * 2.2)
                let curve = (0...12).map { i -> CGPoint in
                    let t = Double(i) / 12, u = 1 - t
                    return pen.P(u * u * a.0 + 2 * u * t * c.0 + t * t * b.0, u * u * a.1 + 2 * u * t * c.1 + t * t * b.1)
                }
                pts += side > 0 ? curve : Array(curve.reversed().dropFirst().dropLast())
            }
            body(pts)
            if detail { pen.sketch.overLine(id + "v", [pen.P(a.0 + 0.35, a.1 - 0.2), pen.P(b.0 - 0.35, b.1 + 0.2)], edge, width: Sketch.stroke) }
        }
    }
}
