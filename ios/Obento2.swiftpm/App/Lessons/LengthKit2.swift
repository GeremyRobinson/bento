import SwiftUI

/// What 2nd grade's chapter 4, Length, shares on the paper (the preview design/prototype/grade2-ch4.html): an inch is a
/// block and a centimeter 2 squares. The ruler (a strip 3 squares tall, its marks hanging from the edge next to the thing,
/// a short mark halfway along each inch, the numbers past them, small); the things measured (line drawings 2 squares tall,
/// softly tinted, the preview's shapes); the measuring pieces (a paper clip, a centimeter cube, a foot ruler, a meter
/// stick, a yardstick); and Hop along a ruler: a drag from a mark lays hops a space at a time to where the finger is, and
/// a drag from the last hop's end goes on from there.
///
/// Hand while a hop is dragged: "grab", "f" the mark it started on, "t" the mark the finger is on. Kept after a hop that
/// missed but may go on: "<p>f", "<p>t" (f −1: none).
@MainActor
enum LN2 {
    static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink2)
    static let say = KK.words.colour(.chapter)

    // MARK: the ruler

    /// A ruler from mark 0 at column x0 on row y (its strip's top), `per` squares a unit, to `max`. `below`: the thing lies
    /// under it (its marks hang from its bottom edge).
    static func ruler(_ pen: inout GridPen, _ id: String, x0: Double, y: Double, per: Double, max: Int, below: Bool = false, lit: [Int] = []) {
        let W = per * Double(max), e = below ? y + 3 : y, d = below ? -1.0 : 1.0
        pen.sketch.box(id + "s", pen.R(x0 - 1, y, W + 2, 3), .ink, width: Sketch.stroke)
        var segs: [(CGPoint, CGPoint)] = []
        for v in 0...max {
            let x = x0 + Double(v) * per
            segs.append((pen.P(x, e), pen.P(x, e + d)))
            if per >= 4 && v < max { segs.append((pen.P(x + per / 2, e), pen.P(x + per / 2, e + d * 0.5))) }
        }
        pen.sketch.segments(id + "m", segs, .ink, width: Sketch.stroke)
        for v in 0...max {
            let on = lit.contains(v)
            pen.word("\(id)n\(v)\(on)", "\(v)", at: x0 + Double(v) * per, e + 2 * d, on ? KK.lit : small)
        }
    }

    // MARK: the things

    private static func outline(_ pen: inout GridPen, _ id: String, _ pts: [(Double, Double)], fill: Bool = true) {
        let ps = pts.map { pen.P($0.0, $0.1) }
        if fill { pen.sketch.polygon(id + "f", ps, .tint(0.2)) }
        pen.sketch.line(id + "o", ps + [ps[0]], .ink, width: Sketch.stroke)
    }
    private static func ring(_ pen: inout GridPen, _ id: String, _ cx: Double, _ cy: Double, _ rx: Double, _ ry: Double, fill: Sketch.Colour? = .tint(0.2)) {
        var pts: [(Double, Double)] = []
        for k in 0..<32 { let a = Double(k) / 32 * 2 * .pi; pts.append((cx + rx * cos(a), cy + ry * sin(a))) }
        let ps = pts.map { pen.P($0.0, $0.1) }
        if let fill { pen.sketch.polygon(id + "f", ps, fill) }
        pen.sketch.line(id + "o", ps + [ps[0]], .ink, width: Sketch.stroke)
    }
    /// How far a thing's tip runs past its name's middle (the name sits in its body).
    static let tip: [String: Double] = ["pencil": 1.6, "crayon": 1.4, "marker": 1]

    /// A thing lying from column x0 to x1, its top on row y, 2 squares tall; its name inside when one is given.
    static func thing(_ pen: inout GridPen, _ id: String, _ name: String, x0: Double, x1: Double, y: Double, label: String? = nil) {
        let K = "\(id)\(name)\(x0):\(x1):\(y)", m = y + 1, w = x1 - x0
        func ln(_ j: String, _ a: Double, _ b: Double, _ c: Double, _ d: Double) { pen.line(K + "l" + j, [(a, b), (c, d)]) }
        func box(_ t: Double, _ b: Double) { outline(&pen, K, [(x0, t), (x1, t), (x1, b), (x0, b)]) }
        switch name {
        case "pencil":
            outline(&pen, K, [(x0, y), (x1 - 1.6, y), (x1, m), (x1 - 1.6, y + 2), (x0, y + 2)])
            ln("1", x0 + 1.2, y, x0 + 1.2, y + 2); ln("2", x1 - 1.6, y, x1 - 1.6, y + 2)
        case "crayon":
            outline(&pen, K, [(x0, y + 0.2), (x1 - 1.4, y + 0.2), (x1 - 1.4, y + 0.5), (x1, y + 0.85), (x1, y + 1.15), (x1 - 1.4, y + 1.5), (x1 - 1.4, y + 1.8), (x0, y + 1.8)])
            ln("1", x0 + 1, y + 0.2, x0 + 1, y + 1.8)
        case "marker":
            outline(&pen, K, [(x0, y + 0.2), (x1 - 1, y + 0.2), (x1 - 1, y + 0.6), (x1, y + 0.8), (x1, y + 1.2), (x1 - 1, y + 1.4), (x1 - 1, y + 1.8), (x0, y + 1.8)])
            ln("1", x1 - 3, y + 0.2, x1 - 3, y + 1.8)
        case "ribbon": outline(&pen, K, [(x0, y), (x1, y), (x1 - 0.8, m), (x1, y + 2), (x0, y + 2), (x0 + 0.8, m)])
        case "straw": box(y + 0.3, y + 1.7)
        case "key":
            ring(&pen, K + "c1", x0 + 1, m, 1, 1); ring(&pen, K + "c2", x0 + 1, m, 0.35, 0.35, fill: .paper)
            outline(&pen, K, [(x0 + 2, y + 0.7), (x1, y + 0.7), (x1, y + 1.6), (x1 - 0.6, y + 1.6), (x1 - 0.6, y + 1.3), (x1 - 1.2, y + 1.3),
                              (x1 - 1.2, y + 1.6), (x1 - 1.8, y + 1.6), (x1 - 1.8, y + 1.3), (x0 + 2, y + 1.3)])
        case "spoon":
            ring(&pen, K + "b", x1 - 1.8, m, 1.8, 1)
            outline(&pen, K, [(x0, y + 0.7), (x1 - 3.6, y + 0.8), (x1 - 3.6, y + 1.2), (x0, y + 1.3)])
        case "book": box(y, y + 2); ln("1", x0 + 0.6, y + 0.6, x1, y + 0.6); ln("2", x0 + 0.6, y + 1.4, x1, y + 1.4)
        case "ruler":
            box(y + 0.4, y + 1.6)
            var i = 5.0
            while i < w { ln("t\(i)", x0 + i, y + 0.4, x0 + i, y + 0.9); i += 5 }
        case "eraser": box(y + 0.3, y + 1.7); ln("1", x0 + w * 0.4, y + 0.3, x0 + w * 0.3, y + 1.7)
        case "shoe":
            outline(&pen, K, [(x0, y + 2), (x0, y), (x0 + w * 0.3, y), (x0 + w * 0.42, y + 0.9), (x1 - 1.2, y + 1.1), (x1, y + 1.6), (x1, y + 2)])
            ln("1", x0, y + 1.6, x1, y + 1.6)
        case "paper clip":
            outline(&pen, K + "o", [(x0, y + 0.5), (x1, y + 0.5), (x1, y + 1.5), (x0, y + 1.5)], fill: false)
            outline(&pen, K + "i", [(x0 + 0.5, y + 0.8), (x1 - 0.8, y + 0.8), (x1 - 0.8, y + 1.2), (x0 + 0.5, y + 1.2)], fill: false)
        case "desk": box(y, y + 0.6); ln("1", x0 + 0.6, y + 0.6, x0 + 0.6, y + 2); ln("2", x1 - 0.6, y + 0.6, x1 - 0.6, y + 2)
        case "rug": box(y + 0.8, y + 2); ln("1", x0 + 0.5, y + 1.4, x1 - 0.5, y + 1.4)
        case "bed":
            // an L: filled as two boxes (a fill is drawn as a fan, so it can't take a corner that turns in)
            pen.fill(K + "f1", col: x0, row: y, w: 0.6, h: 2, .tint(0.2)); pen.fill(K + "f2", col: x0 + 0.6, row: y + 0.8, w: w - 0.6, h: 1.2, .tint(0.2))
            outline(&pen, K, [(x0, y), (x0 + 0.6, y), (x0 + 0.6, y + 0.8), (x1, y + 0.8), (x1, y + 2), (x0, y + 2)], fill: false); ln("1", x0 + 0.6, y + 1.4, x1, y + 1.4)
        case "door": box(y + 0.2, y + 1.8); ring(&pen, K + "k", x1 - 1.2, m, 0.3, 0.3)
        case "board": box(y + 0.5, y + 1.5); ln("1", x0 + 1, m, x1 - 1, m)
        case "car":
            outline(&pen, K, [(x0, y + 1.5), (x0, y + 0.9), (x0 + w * 0.2, y + 0.8), (x0 + w * 0.32, y + 0.1), (x1 - w * 0.3, y + 0.1), (x1 - w * 0.15, y + 0.8), (x1, y + 0.9), (x1, y + 1.5)])
            ring(&pen, K + "w1", x0 + w * 0.22, y + 1.5, 0.5, 0.5); ring(&pen, K + "w2", x1 - w * 0.22, y + 1.5, 0.5, 0.5)
        case "log": box(y + 0.2, y + 1.8); ring(&pen, K + "e", x1 - 0.4, m, 0.4, 0.8, fill: nil)
        default: box(y + 0.3, y + 1.7)
        }
        if let label { pen.word(K + "t", label, at: (x0 + x1 - (tip[name] ?? 0)) / 2, m, Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink)) }
    }

    // MARK: the measuring pieces

    static let toolLength: [String: Double] = ["clip": 5, "cube": 2, "foot": 5, "meter": 10, "yard": 15]
    /// A paper clip (a block long), a cube (2 × 2), a foot ruler, a meter stick or a yardstick (its feet marked), from (x, y);
    /// a count or a name written on it.
    static func tool(_ pen: inout GridPen, _ id: String, _ kind: String, x: Double, y: Double, n: Int? = nil, name: String? = nil) {
        let w = toolLength[kind] ?? 5
        if kind == "clip" { thing(&pen, id, "paper clip", x0: x, x1: x + 5, y: y - 0.5) }
        else if kind == "cube" { pen.fill(id + "f", col: x, row: y, w: 2, h: 2, .tint(0.2)); pen.sketch.box(id + "o", pen.R(x, y, 2, 2), .ink, width: Sketch.stroke) }
        else {
            pen.fill(id + "f", col: x, row: y, w: w, h: 2, .tint(0.2))
            pen.sketch.box(id + "o", pen.R(x, y, w, 2), .ink, width: Sketch.stroke)
            if kind == "yard" { for f in [5.0, 10.0] { pen.line(id + "y\(f)", [(x + f, y), (x + f, y + 1)]) } }
        }
        let mid = kind == "clip" ? y + 1.8 : y + 1
        let ink = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink)
        if let n { pen.word("\(id)n\(n)", "\(n)", at: x + w / 2, mid, ink) } else if let name { pen.word("\(id)w\(name)", name, at: x + w / 2, mid, ink) }
    }

    // MARK: hop along a ruler

    struct Chain { let f: Int, t: Int }
    /// The hop being made (held) or kept from a miss that may go on.
    static func chain(_ s: PaperState, _ p: String) -> Chain? {
        if s.grabbed, let f = s.h("f"), let t = s.h("t") { return Chain(f: Int(f), t: Int(t)) }
        if let f = s.run.kept[p + "f"], f >= 0, let t = s.run.kept[p + "t"] { return Chain(f: Int(f), t: Int(t)) }
        return nil
    }
    /// The hands for a hop: a drag in `band` (rows) between columns xr starts a hop on the mark under the finger (or goes on
    /// from the kept hop's end when it's within `near`); let go, it sets `box` to the hop's code and is checked. `clears`:
    /// a miss that starts over (a wrong start).
    static func hopHands(_ s: PaperState, _ p: String, box: String, band: ClosedRange<Double>, xr: ClosedRange<Double>, near: Int = 0,
                         at: @escaping (Double) -> Int, clears: @escaping (Int, Int) -> Bool) -> Hands {
        let kept = s.run.kept[p + "f"].flatMap { $0 >= 0 ? Chain(f: Int($0), t: Int(s.run.kept[p + "t"] ?? 0)) : nil }
        return Hands(
            grab: { q in
                guard band.contains(q.y), q.x >= xr.lowerBound - 1.5, q.x <= xr.upperBound + 1.5 else { return nil }
                let v = at(q.x)
                let f = kept.map { abs(v - $0.t) <= near ? $0.f : v } ?? v
                return ["grab": 1, "f": Double(f), "t": Double(v)]
            },
            drag: { q, held in var h = held; h["t"] = Double(at(q.x)); return h },
            release: { held in
                let f = Int(held["f"] ?? 0), t = Int(held["t"] ?? 0)
                guard f != t else { return HandMove(hand: [:]) }
                let c = clears(f, t)
                return HandMove(hand: [:], missHand: [:], set: [(box, Double(Len2.code(f, t)))],
                                keep: [p + "f": c ? -1 : Double(f), p + "t": Double(t)], check: true)
            })
    }
    /// A hop's move for screenshots (-wrong) and Show me's start.
    static func hopMove(_ p: String, box: String, from: Int, to: Int) -> HandMove {
        HandMove(hand: [:], missHand: [:], set: [(box, Double(Len2.code(from, to)))], keep: [p + "f": Double(from), p + "t": Double(to)], check: true)
    }
    /// Hops of one unit from a to b over row `row` (down when height < 0), `per` squares a unit.
    static func hops(_ pen: inout GridPen, _ id: String, _ a: Int, _ b: Int, x0: Double, per: Double, row: Double, height: Double, big: Int = 1, restInOne: Bool = false) {
        for (p, q) in Len2.hops(a, b, big: big, restInOne: restInOne) {
            let hgt = abs(q - p) >= 10 && big >= 10 ? height * 3 : height
            pen.hop("\(id)\(p):\(q)", from: x0 + Double(p) * per, to: x0 + Double(q) * per, row: row, height: hgt)
        }
    }
}
