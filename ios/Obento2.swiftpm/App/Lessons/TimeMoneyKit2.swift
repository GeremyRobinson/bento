import SwiftUI

/// What 2nd grade's chapter 6, Time and money, shares on the paper (the preview design/prototype/grade2-ch6.html): the coins
/// (a rim, a bumpy or smooth edge, a star for heads or two leaves for tails, no name or number) in their own soft colours, the
/// penny copper and the rest silver (call of 3 Nov: telling coins apart is the maths here); a cent, the 3 × 3 counter, crossed
/// out when it's spent; the dollar square (10 × 10 cents in four quarter blocks); a bill 10 × 4; the readout beside a picture.
@MainActor
enum TMK {
    static func ring(_ cx: Double, _ cy: Double, _ r: Double, _ n: Int = 48) -> [(Double, Double)] {
        var out: [(Double, Double)] = []
        for k in 0...n { let a = Double(k) / Double(n) * 2 * .pi; out.append((cx + r * cos(a), cy + r * sin(a))) }
        return out
    }
    /// A coin's own colour, faint: the penny copper, the others silver (lifted for the dark paper).
    static func colour(_ c: Int) -> Sketch.Colour {
        c == TM2.penny ? .hex(Ink.mix(0xF3F2EF, 0xB87333, 0.3), Ink.mix(0x121211, 0xD68C50, 0.34))
            : .hex(Ink.mix(0xF3F2EF, 0x8C8C96, 0.16), Ink.mix(0x121211, 0xC8C8D2, 0.14))
    }
    /// A coin `c` centred at (cx, cy), r squares across its middle to the rim.
    /// `under`: the coin lying over this one in a fanned row (its centre and radius): only what shows past it is drawn.
    static func coin(_ pen: inout GridPen, _ id: String, _ c: Int, cx: Double, cy: Double, r: Double, side: Int, rim: Sketch.Colour = .ink,
                     under: (x: Double, y: Double, r: Double)? = nil) {
        let C = TM2.coins[c], ri = r - max(0.5, r * 0.1)
        func shows(_ x: Double, _ y: Double) -> Bool { under.map { hypot(x - $0.x, y - $0.y) > $0.r } ?? true }
        // a ring in the runs of it that show
        func arcs(_ key: String, _ rr: Double, _ colour: Sketch.Colour) {
            var run: [(Double, Double)] = [], k = 0
            for p in ring(cx, cy, rr, 96) {
                if shows(p.0, p.1) { run.append(p); continue }
                if run.count > 1 { pen.line("\(key)\(k)", run, colour); k += 1 }
                run = []
            }
            if run.count > 1 { pen.line("\(key)\(k)", run, colour) }
        }
        pen.sketch.polygon(id + "f", ring(cx, cy, r).map { pen.P($0.0, $0.1) }, colour(c))
        if under == nil { pen.line(id + "r\(rim)", ring(cx, cy, r), rim); pen.line(id + "i", ring(cx, cy, ri)) }
        else { arcs(id + "r\(rim)", r, rim); arcs(id + "i", ri, .ink) }
        if C.bumpy {
            let n = Int((2 * .pi * r / 0.6).rounded())
            var segs: [(CGPoint, CGPoint)] = []
            for j in 0..<n {
                let a = 2 * .pi * Double(j) / Double(n)
                if shows(cx + r * cos(a), cy + r * sin(a)) { segs.append((pen.P(cx + ri * cos(a), cy + ri * sin(a)), pen.P(cx + r * cos(a), cy + r * sin(a)))) }
            }
            if !segs.isEmpty { pen.sketch.segments(id + "e", segs, .ink, width: Sketch.stroke) }
        }
        // the face's art only on a coin nothing lies over
        guard under == nil else { return }
        let k = r * 0.42
        if side == 0 {
            var star: [(Double, Double)] = []
            for i in 0...10 { let a = -Double.pi / 2 + Double(i % 10) * .pi / 5, rr = i % 2 == 1 ? 0.42 : 1; star.append((cx + k * rr * cos(a), cy + k * rr * sin(a))) }
            pen.line(id + "a", star)
        } else {
            // two leaves on a stem
            func leaf(_ s: Double) -> [(Double, Double)] {
                var out: [(Double, Double)] = []
                for i in 0...10 { let t = Double(i) / 10; out.append(quad((0, 0.9), (s * -1.05, 0.55 + 0.0), (s * -0.75, -0.8), t)) }
                for i in 1...10 { let t = Double(i) / 10; out.append(quad((s * -0.75, -0.8), (s * 0.2, -0.35), (0, 0.9), t)) }
                return out.map { (cx + k * $0.0, cy + k * $0.1) }
            }
            pen.line(id + "a", leaf(1)); pen.line(id + "b", leaf(-1))
            pen.line(id + "s", [(cx, cy + k * 0.9), (cx, cy + k * 1.15)])
        }
    }
    private static func quad(_ a: (Double, Double), _ b: (Double, Double), _ c: (Double, Double), _ t: Double) -> (Double, Double) {
        let u = 1 - t
        return (u * u * a.0 + 2 * u * t * b.0 + t * t * c.0, u * u * a.1 + 2 * u * t * b.1 + t * t * c.1)
    }
    /// A cent: the counter in a 3 × 3 cell (x, y its top-left); lit darker; crossed out when it's spent.
    static func cent(_ pen: inout GridPen, _ id: String, x: Double, y: Double, lit: Bool = false, ink: Bool = false, cross: Bool = false) {
        pen.dot(id + "f\(lit)", at: x + 1.5, y + 1.5, radius: 1.15, .tint(lit ? 0.42 : 0.2))
        pen.circle(id + "o\(ink)", at: x + 1.5, y + 1.5, radius: 1.15, ink ? .ink : .chapter)
        if cross {
            pen.line(id + "x1", [(x + 0.5, y + 0.5), (x + 2.5, y + 2.5)])
            pen.line(id + "x2", [(x + 2.5, y + 0.5), (x + 0.5, y + 2.5)])
        }
    }
    /// The dollar square from (x, y): 30 × 30, its four quarter blocks.
    static func dollarSquare(_ pen: inout GridPen, x: Double, y: Double) {
        pen.sketch.box("dsq", pen.R(x, y, 30, 30), .ink, width: Sketch.stroke)
        pen.line("dsv", [(x + 15, y), (x + 15, y + 30)], .ink3)
        pen.line("dsh", [(x, y + 15), (x + 30, y + 15)], .ink3)
    }
    /// The n-th cent's cell in the dollar square at (x, y).
    static func centAt(_ n: Int, x: Double, y: Double) -> CGPoint { let p = TM2.centAt(n); return CGPoint(x: x + Double(p.x), y: y + Double(p.y)) }
    /// A bill, 10 × 4 squares, its value at its top-left (the part a fanned row still shows).
    static func bill(_ pen: inout GridPen, _ id: String, _ v: Int, x: Double, y: Double) {
        pen.fill(id + "bg", col: x, row: y, w: 10, h: 4, .paper)
        pen.fill(id + "f", col: x, row: y, w: 10, h: 4, colour(TM2.dime))
        pen.sketch.box(id + "o", pen.R(x, y, 10, 4), .ink, width: Sketch.stroke)
        var oval: [(Double, Double)] = []
        for k in 0...32 { let a = Double(k) / 32 * 2 * .pi; oval.append((x + 6 + 1.6 * cos(a), y + 2 + 1.2 * sin(a))) }
        pen.line(id + "p", oval)
        pen.word(id + "v", "$\(v)", at: x + 0.4, y + 1, LN2.small.colour(.ink), anchor: UnitPoint(x: 0, y: 0.5))
    }
    /// The readout beside a picture, in the chapter colour, from column x.
    static func readout(_ pen: inout GridPen, _ text: String, x: Double, y: Double) {
        pen.word("ro", text, at: x, y, KK.words.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5))
    }
}
