import SwiftUI

/// What 1st grade's chapter 5, Length, time and graphs, shares on the paper (the preview design/prototype/grade1-ch5.html):
/// a thing lying as a plain bar (one block one cube of length) with its name at its right end; the rows' small pictures
/// (3 squares across, thin chapter lines over a faint tint, as K draws its things); a tally mark every 2 squares, the fifth
/// across its four; and parts that start where they were let go (Sketch.from).
@MainActor
enum L5 {
    static let name = KK.words
    /// A thing lying from (x, y) (y its block row's top), `n` blocks long: a bar `thick` squares thick whose foot is on the
    /// row's block line (4) or in the row's middle (3, 2: from y + 1).
    static func bar(_ pen: inout GridPen, _ id: String, x: Double, y: Double, _ n: Int, thick: Double = 4, colour: Sketch.Colour = .ink, fill: Sketch.Colour = .tint(0.2)) {
        let L = 5 * Double(n)
        pen.fill(id + "f", col: x, row: y + 1, w: L, h: thick, fill)
        pen.sketch.box(id + "o", pen.R(x, y + 1, L, thick), colour, width: Sketch.stroke)
    }
    /// A thing's name, its left end half a square past (x), centred on row `mid`.
    static func label(_ pen: inout GridPen, _ id: String, _ s: String, x: Double, mid: Double, _ w: Sketch.Words = name) {
        pen.word(id, s, at: x + 0.5, mid, w, anchor: UnitPoint(x: 0, y: 0.5))
    }
    static func width(_ s: String) -> Double { KK.width(s, name) }
    static func smallWidth(_ s: String) -> Double { KK.width(s, KK.lit) }

    /// Parts `build` draws start where `was` drew them.
    static func seeded(_ pen: inout GridPen, was: ((inout GridPen) -> Void)?, _ build: (inout GridPen) -> Void) { KM.seeded(&pen, was: was, build) }

    // MARK: the rows' small pictures

    private static func circle(_ cx: Double, _ cy: Double, _ r: Double, _ n: Int = 24) -> [CGPoint] {
        (0...n).map { i in let a = Double(i) / Double(n) * 2 * .pi; return CGPoint(x: cx + r * cos(a), y: cy + r * sin(a)) }
    }
    private static func quad(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ n: Int = 10) -> [CGPoint] {
        (1...n).map { i in let t = Double(i) / Double(n), u = 1 - t
            return CGPoint(x: u * u * a.x + 2 * u * t * c.x + t * t * b.x, y: u * u * a.y + 2 * u * t * c.y + t * t * b.y) }
    }
    private static func cubic(_ a: CGPoint, _ c1: CGPoint, _ c2: CGPoint, _ b: CGPoint, _ n: Int = 12) -> [CGPoint] {
        (1...n).map { i in let t = Double(i) / Double(n), u = 1 - t
            return CGPoint(x: u * u * u * a.x + 3 * u * u * t * c1.x + 3 * u * t * t * c2.x + t * t * t * b.x,
                           y: u * u * u * a.y + 3 * u * u * t * c1.y + 3 * u * t * t * c2.y + t * t * t * b.y) }
    }
    /// An arc of radius r from a to b, turning clockwise (on the paper, y down), the short way.
    private static func arc(_ a: CGPoint, _ b: CGPoint, _ r: Double, _ n: Int = 10) -> [CGPoint] {
        let mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2, dx = b.x - a.x, dy = b.y - a.y, d = max(0.0001, hypot(dx, dy))
        let h = (max(0, r * r - d * d / 4)).squareRoot()
        for sgn in [1.0, -1.0] {
            let cx = mx - sgn * dy / d * h, cy = my + sgn * dx / d * h
            let a0 = atan2(a.y - cy, a.x - cx)
            var dl = atan2(b.y - cy, b.x - cx) - a0
            while dl <= -.pi { dl += 2 * .pi }
            while dl > .pi { dl -= 2 * .pi }
            if dl > 0 || sgn < 0 {
                return (1...n).map { i in let t = a0 + dl * Double(i) / Double(n); return CGPoint(x: cx + r * cos(t), y: cy + r * sin(t)) }
            }
        }
        return [b]
    }
    private static func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x, y: y) }
    /// A picture's outlines in squares about its middle: the first is its body (tinted), the rest drawn over it.
    static func shapes(_ name: String) -> [[CGPoint]] {
        switch name {
        case "apple":
            return [circle(0, 0.25, 1.15), [p(0, -0.9)] + quad(p(0, -0.9), p(0.05, -1.25), p(0.35, -1.45)),
                    [p(0.05, -1)] + quad(p(0.05, -1), p(0.6, -1.5), p(1, -1.05)) + quad(p(1, -1.05), p(0.5, -0.75), p(0.05, -1))]
        case "banana":
            return [[p(-1.35, -0.75)] + quad(p(-1.35, -0.75), p(-1.15, 1.3), p(1.4, 0.5)) + quad(p(1.4, 0.5), p(-0.35, 0.45), p(-0.75, -0.95)) + [p(-1.35, -0.75)]]
        case "grapes":
            return [circle(0, 0.55, 0.6), circle(-0.6, -0.5, 0.6), circle(0.6, -0.5, 0.6), [p(0, -1.1), p(0.2, -1.45)]]
        case "dog":
            let ear: (Double) -> [CGPoint] = { s in [p(-0.8 * s, -0.5)] + quad(p(-0.8 * s, -0.5), p(-1.6 * s, -0.4), p(-1.35 * s, 0.75)) + quad(p(-1.35 * s, 0.75), p(-0.9 * s, 0.65), p(-0.85 * s, 0.1)) + [p(-0.8 * s, -0.5)] }
            return [circle(0, 0.15, 1), ear(1), ear(-1), circle(0, 0.5, 0.18, 10)]
        case "cat":
            return [circle(0, 0.3, 1.05), [p(-0.95, -0.15), p(-0.85, -1.35), p(-0.2, -0.72), p(-0.95, -0.15)], [p(0.95, -0.15), p(0.85, -1.35), p(0.2, -0.72), p(0.95, -0.15)]]
        case "fish":
            return [[p(-1.45, 0)] + quad(p(-1.45, 0), p(-0.4, -1.05), p(0.65, 0)) + quad(p(0.65, 0), p(-0.4, 1.05), p(-1.45, 0)),
                    [p(0.55, 0), p(1.45, -0.75), p(1.45, 0.75), p(0.55, 0)], circle(-0.85, -0.1, 0.12, 8)]
        case "sun":
            return [circle(0, 0, 0.75)] + (0..<8).map { i in let a = Double(i) * .pi / 4; return [p(1.05 * cos(a), 1.05 * sin(a)), p(1.45 * cos(a), 1.45 * sin(a))] }
        case "rain":
            return [[p(0, -1.4)] + cubic(p(0, -1.4), p(0.6, -0.5), p(1, 0), p(1, 0.45)) + arc(p(1, 0.45), p(-1, 0.45), 1, 14)
                    + cubic(p(-1, 0.45), p(-1, 0), p(-0.6, -0.5), p(0, -1.4))]
        case "cloud":
            let a = p(-0.95, 0.7), b = p(-1.05, -0.4), c = p(0.45, -0.8), d = p(1.15, 0), e = p(1, 0.7)
            return [[a] + arc(a, b, 0.6) + arc(b, c, 0.8) + arc(c, d, 0.65) + arc(d, e, 0.38) + [a]]
        case "cracker":
            return [[p(-1.1, -1.1), p(1.1, -1.1), p(1.1, 1.1), p(-1.1, 1.1), p(-1.1, -1.1)]] + [(-0.5, -0.5), (0.5, -0.5), (-0.5, 0.5), (0.5, 0.5)].map { circle($0.0, $0.1, 0.13, 8) }
        case "popcorn":
            return [[p(-0.95, -0.2), p(0.95, -0.2), p(0.65, 1.4), p(-0.65, 1.4), p(-0.95, -0.2)], circle(-0.55, -0.6, 0.5, 14), circle(0.55, -0.6, 0.5, 14), circle(0, -0.95, 0.5, 14)]
        default: // pretzel
            return [[p(0, 0.95)] + cubic(p(0, 0.95), p(-1.9, -0.35), p(-0.95, -1.75), p(0, -0.55)) + cubic(p(0, -0.55), p(0.95, -1.75), p(1.9, -0.35), p(0, 0.95)),
                    [p(-0.95, 1.25), p(0.45, -0.15)], [p(0.95, 1.25), p(-0.45, -0.15)]]
        }
    }
    /// A row's picture centred at (cx, cy), `sc` squares a unit: its body tinted (lit: darker), its lines in the chapter's
    /// colour (faint: a thing already counted, `edge` another colour).
    static func icon(_ pen: inout GridPen, _ id: String, _ name: String, _ cx: Double, _ cy: Double, sc: Double = 1, lit: Bool = false,
                     edge: Sketch.Colour = .chapter, faint: Bool = false) {
        let s = shapes(name)
        func pts(_ l: [CGPoint]) -> [CGPoint] { l.map { pen.P(cx + $0.x * sc, cy + $0.y * sc) } }
        let e: Sketch.Colour = faint ? .ink3 : edge
        if let body = s.first, !faint { pen.sketch.polygon(id + "f\(lit)", pts(body), lit ? .tint(0.45) : .tint(0.2)) }
        for (k, l) in s.enumerated() { pen.sketch.line("\(id)l\(k)\(faint)", pts(l), e, width: Sketch.stroke) }
    }

    // MARK: tally marks

    /// Mark i's right edge, so what follows a row of n marks starts after it.
    static func markRight(_ n: Int, x0: Double) -> Double {
        guard n > 0 else { return x0 }
        let b = Double((n - 1) / 5), j = (n - 1) % 5
        return j == 4 ? x0 + 10 * (b + 1) : x0 + 10 * b + 2 + 2 * Double(j)
    }
    /// Mark i of a row whose top is y: four up, the fifth across them.
    static func mark(_ pen: inout GridPen, _ id: String, _ i: Int, x0: Double, y: Double, _ c: Sketch.Colour = .ink) {
        let b = Double(i / 5), j = i % 5
        if j < 4 { pen.line(id, [(x0 + 10 * b + 1 + 2 * Double(j), y + 1), (x0 + 10 * b + 1 + 2 * Double(j), y + 4)], c) }
        else { pen.line(id, [(x0 + 10 * b + 0.2, y + 3.6), (x0 + 10 * b + 7.8, y + 1.4)], c) }
    }
}
