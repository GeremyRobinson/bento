import SwiftUI

/// What 6th grade's Negative numbers lessons share (design/grade6.md chapter 4, the preview
/// design/prototype/grade6-ch4.html): a number line through 0, across or upright, U squares a one; the plane in four
/// quadrants, two squares a unit; points in three shades (full, half, an outline) so two or three on one line are told
/// apart; and the new hand move, the fold: part of the paper is dragged over a grid line, turning about it (seen in
/// perspective, its plain back past upright), and let go past upright it lands, prints what it carries on the other side,
/// and lies back.
@MainActor
enum N6 {
    static let small = R6.small, lit = R6.lit
    static let quiet = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink2)

    /// A number line through 0 at (x0, y0), U squares a one, from lo to hi; across, or upright (`up`).
    @MainActor struct Line {
        var x0: Double, y0: Double, U: Double, lo: Double, hi: Double, up = false
        func at(_ v: Double) -> CGPoint { up ? CGPoint(x: x0, y: y0 - v * U) : CGPoint(x: x0 + v * U, y: y0) }
        /// The value under a finger, snapped to `step` and kept on the line.
        func val(_ q: CGPoint, step: Double = 1) -> Double {
            let s = up ? (y0 - q.y) / U : (q.x - x0) / U
            return min(hi, max(lo, (s / step).rounded() * step))
        }
        func near(_ q: CGPoint, _ m: Double = 2.5) -> Bool {
            up ? abs(q.x - x0) <= m && q.y >= y0 - hi * U - m && q.y <= y0 - lo * U + m
               : abs(q.y - y0) <= m && q.x >= x0 + lo * U - m && q.x <= x0 + hi * U + m
        }
        /// Its two halves (each a piece of paper a fold can lift: `keep` leaves out what's lifted), a tick on every one
        /// (0's longer), numbers on the fives (every second one on a long upright line, or `labels`), the one a point is over lit.
        func draw(_ pen: inout GridPen, _ id: String, keep: (CGPoint) -> Bool = { _ in true }, labels: [Double]? = nil, lit: Double? = nil) {
            let Z = at(0)
            for (s, end) in [(-1.0, lo), (1.0, hi)] {
                let E = at(end), X = up ? CGPoint(x: x0, y: E.y - s) : CGPoint(x: E.x + s, y: y0)
                guard keep(CGPoint(x: (Z.x + E.x) / 2, y: (Z.y + E.y) / 2)) else { continue }
                pen.line("\(id)h\(Int(s))", [(Z.x, Z.y), (X.x, X.y)])
                if up { pen.line("\(id)a\(Int(s))", [(X.x - 0.8, X.y + 0.8 * s), (X.x, X.y), (X.x + 0.8, X.y + 0.8 * s)]) }
                else { pen.line("\(id)a\(Int(s))", [(X.x - 0.8 * s, X.y - 0.8), (X.x, X.y), (X.x - 0.8 * s, X.y + 0.8)]) }
            }
            var ticks: [(CGPoint, CGPoint)] = []
            for v in stride(from: lo.rounded(.up), through: hi, by: 1) {
                let p = at(v), t = v == 0 ? 0.9 : 0.5
                guard keep(p) else { continue }
                ticks.append(up ? (pen.P(x0 - t, p.y), pen.P(x0 + t, p.y)) : (pen.P(p.x, y0 - t), pen.P(p.x, y0 + t)))
            }
            pen.sketch.segments("\(id)t\(keep(at(lo)))\(keep(at(hi)))", ticks, .ink, width: Sketch.stroke)
            // numbers on the fives; a long upright line (a square a one) numbers every second tick, so it reads at a glance
            let every: Double = up && hi - lo >= 20 ? 2 : 5
            let ls = labels ?? stride(from: lo.rounded(.up), through: hi, by: 1).filter { $0.truncatingRemainder(dividingBy: every) == 0 }
            for v in ls {
                // kept by where its words are (beside the line), not by the line's point
                let p = at(v), on = lit == v
                guard keep(up ? CGPoint(x: x0 - 1, y: p.y) : CGPoint(x: p.x, y: y0 + 1)) else { continue }
                if up { pen.label("\(id)l\(fmt(v))\(on)", fmt(v), on ? N6.lit : N6.small, .left, edge: x0 - 0.6, along: p.y) }
                else { pen.label("\(id)l\(fmt(v))\(on)", fmt(v), on ? N6.lit : N6.small, .below, edge: y0 + 0.5, along: p.x) }
            }
        }
    }

    /// The plane in four quadrants: origin (ox, oy), U squares a unit, −X to X across and −Y to Y up.
    @MainActor struct Plane {
        var ox: Double, oy: Double, U = 2.0, X = Neg6.X, Y = Neg6.Y
        func at(_ u: Double, _ v: Double) -> CGPoint { CGPoint(x: ox + u * U, y: oy - v * U) }
        /// A finger snapped to the nearest grid point (every square: half units), kept on the plane.
        func snap(_ q: CGPoint) -> (u: Double, v: Double) {
            let su = min(Double(X) * U, max(-Double(X) * U, (q.x - ox).rounded())), sv = min(Double(Y) * U, max(-Double(Y) * U, (oy - q.y).rounded()))
            return (su / U, sv / U)
        }
        func holds(_ q: CGPoint, _ m: Double = 1.5) -> Bool { abs(q.x - ox) <= Double(X) * U + m && abs(q.y - oy) <= Double(Y) * U + m }
        var width: Double { Double(X) * U + 1 }
        var height: Double { Double(Y) * U + 1 }
        /// The axes with arrows, a tick every unit, numbers on the even ones, 0 at the corner, x and y named, and the
        /// quadrants' numbers small in their outer corners (left out where a point sits, `avoid`).
        func draw(_ pen: inout GridPen, _ id: String, keep: (CGPoint) -> Bool = { _ in true }, avoid: [CGPoint] = []) {
            let xe = width, ye = height
            for s in [-1.0, 1.0] {
                if keep(CGPoint(x: ox + s, y: oy)) {
                    pen.line("\(id)ax\(Int(s))", [(ox, oy), (ox + s * xe, oy)])
                    pen.line("\(id)axa\(Int(s))", [(ox + s * (xe - 0.8), oy - 0.8), (ox + s * xe, oy), (ox + s * (xe - 0.8), oy + 0.8)])
                }
                if keep(CGPoint(x: ox, y: oy - s)) {
                    pen.line("\(id)ay\(Int(s))", [(ox, oy), (ox, oy - s * ye)])
                    pen.line("\(id)aya\(Int(s))", [(ox - 0.8, oy - s * (ye - 0.8)), (ox, oy - s * ye), (ox + 0.8, oy - s * (ye - 0.8))])
                }
            }
            if keep(CGPoint(x: ox + xe, y: oy)) { pen.label("\(id)xn", "x", N6.small, .right, edge: ox + xe + 0.2, along: oy) }
            if keep(CGPoint(x: ox, y: oy - ye)) { pen.label("\(id)yn", "y", N6.small, .right, edge: ox + 0.7, along: oy - ye + 0.6) }
            if keep(CGPoint(x: ox - 0.9, y: oy + 1)) { pen.word("\(id)o", "0", at: ox - 0.9, oy + 1, N6.small) }
            var ticks: [(CGPoint, CGPoint)] = []
            for i in -X...X where i != 0 {
                let x = ox + Double(i) * U
                guard keep(CGPoint(x: x, y: oy)) else { continue }
                ticks.append((pen.P(x, oy - 0.5), pen.P(x, oy + 0.5)))
                if i % 2 == 0, keep(CGPoint(x: x, y: oy + 1)) { pen.label("\(id)xl\(i)", fmt(Double(i)), N6.small, .below, edge: oy + 0.5, along: x) }
            }
            for j in -Y...Y where j != 0 {
                let y = oy - Double(j) * U
                guard keep(CGPoint(x: ox, y: y)) else { continue }
                ticks.append((pen.P(ox - 0.5, y), pen.P(ox + 0.5, y)))
                if j % 2 == 0, keep(CGPoint(x: ox - 1, y: y)) { pen.label("\(id)yl\(j)", fmt(Double(j)), N6.small, .left, edge: ox - 0.6, along: y) }
            }
            pen.sketch.segments("\(id)t\(keep(at(-1, 0)))\(keep(at(1, 0)))\(keep(at(0, 1)))\(keep(at(0, -1)))", ticks, .ink, width: Sketch.stroke)
            for (n, a, b) in [("I", 1.0, 1.0), ("II", -1.0, 1.0), ("III", -1.0, -1.0), ("IV", 1.0, -1.0)] {
                let x = ox + a * (Double(X) * U - 2), y = oy - b * (Double(Y) * U - 1.5)
                if avoid.contains(where: { abs($0.x - x) < 9 && abs($0.y - y) < 3 }) || !keep(CGPoint(x: x, y: y)) { continue }
                pen.word("\(id)q\(n)", n, at: x, y, N6.small)
            }
        }
        /// Dotted lines from a point to both axes.
        func drops(_ pen: inout GridPen, _ id: String, _ u: Double, _ v: Double) {
            let p = at(u, v)
            if v != 0 { pen.line("\(id)dx", [(p.x, p.y), (p.x, oy)], .chapter, dashed: true) }
            if u != 0 { pen.line("\(id)dy", [(p.x, p.y), (ox, p.y)], .chapter, dashed: true) }
        }
        /// A point's pair on its outer side, away from both axes and their numbers (beside it at the top or bottom edge).
        func pair(_ pen: inout GridPen, _ id: String, _ u: Double, _ v: Double, _ w: Sketch.Words = N6.lit) {
            let p = at(u, v), left = u < 0, edge = abs(v) >= Double(Y) - 1
            let y = edge ? p.y : v > 0 ? p.y - 1.3 : p.y + 1.4, x = edge ? p.x + (left ? -1.1 : 1.1) : p.x + (left ? -0.4 : 0.4)
            pen.word(id, Neg6.pair(u, v), at: x, y, w, anchor: UnitPoint(x: left ? 1 : 0, y: 0.5))
        }
    }

    /// A point in one of three shades (the first full, the second half, the third an outline), bigger while held.
    static func point(_ pen: inout GridPen, _ id: String, _ p: CGPoint, shade: Int = 0, held: Bool = false, _ c: Sketch.Colour = .chapter) {
        let r = held ? 0.7 : 0.55
        if shade == 0 { pen.dot(id, at: p.x, p.y, radius: r, c, over: true); return }
        pen.dot(id + "f", at: p.x, p.y, radius: r - 0.04, shade == 1 ? .tint(0.45) : .paper, over: true)
        let pts = (0...32).map { k -> CGPoint in let a = Double(k) / 32 * 2 * .pi; return pen.P(p.x + (r - 0.04) * cos(a), p.y + (r - 0.04) * sin(a)) }
        pen.sketch.overLine(id + "o", pts, c, width: Sketch.stroke)
    }
    /// A point's number beside it: above it on a line across, right of it upright.
    static func readout(_ pen: inout GridPen, _ id: String, _ p: CGPoint, _ s: String, up: Bool, quiet: Bool = false) {
        let w = quiet ? N6.quiet : N6.lit
        if up { pen.word(id, s, at: p.x + 1.1, p.y, w, anchor: UnitPoint(x: 0, y: 0.5)) }
        else { pen.word(id, s, at: p.x, p.y - 1.6, w) }
    }
    /// A bracket from a to b over a line across at row y (its ends half a square over the line), its words over it.
    static func bracket(_ pen: inout GridPen, _ id: String, from a: Double, to b: Double, line y: Double, level: Double, _ text: String?) {
        pen.line(id, [(a, y - 0.7), (a, level), (b, level), (b, y - 0.7)], .chapter)
        if let text, a != b { pen.word(id + "w", text, at: (a + b) / 2, level - 0.9, N6.lit) }
    }

    /// A fold about a grid line: up the paper at x = `at` (`vertical`), or across it at y = `at`; the other way its middle
    /// is `mid` (what the perspective grows from); `side` is the half lifted (+1 right or below).
    struct Fold {
        var vertical: Bool, at: Double, mid: Double, side: Double, eye = 120.0
        /// Where a place on the lifted half is with the half turned by `th` (0 flat, π lying over the other side), seen in
        /// perspective: what turns toward you grows a little.
        func map(_ th: Double) -> (CGPoint) -> CGPoint {
            { p in
                let d = vertical ? p.x - at : p.y - at, k = eye / (eye - abs(d) * sin(th))
                return vertical ? CGPoint(x: at + d * cos(th) * k, y: mid + (p.y - mid) * k) : CGPoint(x: mid + (p.x - mid) * k, y: at + d * cos(th) * k)
            }
        }
        func lifted(_ p: CGPoint) -> Bool { ((vertical ? p.x : p.y) - at) * side > 1e-6 }
        /// What the turning sheet carries: what's on its half, and what sits on the fold line itself (an axis, a tick
        /// across the line), which stays where it is as the sheet turns and lies over the sheet's paper flat.
        func carries(_ p: CGPoint) -> Bool { ((vertical ? p.x : p.y) - at) * side > -1e-6 }
        /// Where the finger is in the fold's terms: how far past the line on the lifted side.
        func past(_ q: CGPoint) -> Double { ((vertical ? q.x : q.y) - at) * side }
        /// The fold's angle for a finger that grabbed `g` squares from the line and is now at q.
        func angle(_ q: CGPoint, grab g: Double) -> Double { acos(min(1, max(-1, past(q) / max(0.5, g)))) }
        /// A place on the lifted half printed on the other side: its mirror in the line.
        func mirror(_ p: CGPoint) -> CGPoint { vertical ? CGPoint(x: 2 * at - p.x, y: p.y) : CGPoint(x: p.x, y: 2 * at - p.y) }
    }
    /// The turning half: its sheet `rect` (squares) with the grid's squares and what it carries (`content`, drawn flat on
    /// a pen of its own), turned by `th`; past upright its plain back. `from`: the angle it starts at, morphing to `th`
    /// (lying back flat after it's let go). `landed`: let go past upright, it first finishes its turn to 180° on the
    /// spring (lying over the other side, where the print fades in under it), then lies back flat (as the preview does).
    /// A landed half: how long until it lies over the other side (when the print fades in), and until it's flat again.
    static let printAt = SketchDrawer.morphTime
    static let overTime = SketchDrawer.morphTime * 2 + SketchDrawer.viaRest
    static let minor = Sketch.Colour.hex(Ink.mix(0xF3F2EF, 0x1A1A19, 0.045), Ink.mix(0x121211, 0xECEBE7, 0.035))
    static let major = Sketch.Colour.hex(Ink.mix(0xF3F2EF, 0x1A1A19, 0.09), Ink.mix(0x121211, 0xECEBE7, 0.07))
    static func flap(_ pen: inout GridPen, _ id: String, _ f: Fold, rect r: CGRect, th: Double, from: Double? = nil, landed: Bool = false, gridTop: Double, content: (inout GridPen) -> Void) {
        var sheet = GridPen(stableIds: pen.stableIds)
        let front = th <= .pi / 2
        let corners = [(r.minX, r.minY), (r.maxX, r.minY), (r.maxX, r.maxY), (r.minX, r.maxY)].map { sheet.P($0.0, $0.1) }
        sheet.sketch.plate(id + "s\(front)", corners, front ? .paper : .line)
        if front {
            // the grid's own lines, the strong ones on the block lines, so it lies back flat as the paper it was
            var thin: [(CGPoint, CGPoint)] = [], strong: [(CGPoint, CGPoint)] = []
            func five(_ v: Double) -> Bool { Int(v.rounded()) % 5 == 0 }
            for x in stride(from: r.minX.rounded(.up), through: r.maxX, by: 1) { (five(x) ? { strong.append($0) } : { thin.append($0) })((sheet.P(x, r.minY), sheet.P(x, r.maxY))) }
            for y in stride(from: r.minY.rounded(.up), through: r.maxY, by: 1) { (five(y + gridTop) ? { strong.append($0) } : { thin.append($0) })((sheet.P(r.minX, y), sheet.P(r.maxX, y))) }
            // as thin plates, so what the sheet carries lies over them
            func plates(_ segs: [(CGPoint, CGPoint)]) -> [[CGPoint]] {
                segs.map { a, b in
                    let h = 0.5, v = a.x == b.x
                    return v ? [CGPoint(x: a.x - h, y: a.y), CGPoint(x: a.x + h, y: a.y), CGPoint(x: b.x + h, y: b.y), CGPoint(x: b.x - h, y: b.y)]
                        : [CGPoint(x: a.x, y: a.y - h), CGPoint(x: b.x, y: b.y - h), CGPoint(x: b.x, y: b.y + h), CGPoint(x: a.x, y: a.y + h)]
                }
            }
            for (i, q) in plates(thin).enumerated() { sheet.sketch.plate(id + "g\(i)", q, minor) }
            for (i, q) in plates(strong).enumerated() { sheet.sketch.plate(id + "G\(i)", q, major) }
            content(&sheet)
        }
        // its edge while it turns; lying back flat it's the paper again
        if from == nil { sheet.sketch.line(id + "o", corners + [corners[0]], .ink3, width: Sketch.stroke) }
        let sq = Paper.cell
        func inPoints(_ m: @escaping (CGPoint) -> CGPoint) -> (CGPoint) -> CGPoint { { p in let q = m(CGPoint(x: p.x / sq, y: p.y / sq)); return CGPoint(x: q.x * sq, y: q.y * sq) } }
        let over = landed && from != nil
        pen.sketch.append(sheet.sketch.lifted(inPoints(f.map(th)), words: front, from: from.map { inPoints(f.map($0)) },
                                              via: over ? inPoints(f.map(.pi)) : nil, wordsAt: over ? PaperClock.now + N6.overTime : nil,
                                              tag: from.map { "~\(Int($0 * 100))" } ?? ""))
    }
}
