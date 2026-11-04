import SwiftUI

/// What 1st grade's chapter 1, Add and take away to 20, shares on the paper (the preview design/prototype/grade1-ch1.html):
/// a counter is a dot in a 3 × 3 cell (solid, striped: the second amount, dotted: the third; crossed out once taken), a row
/// of ten is 30 squares so the strong lines fall after every fifth; rows of dashed places (solid in the chapter's colour
/// once full); the number line 0 to 20, 3 squares a step, every 5 on a strong line; a hop with its arrowhead; the record
/// line with its boxes; and the number row 0–20 (K's, 5 × 4 squares a key: 0–10 on one row, each teen under its ones).
@MainActor
enum A1 {
    enum Style { case solid, striped, dotted }
    static let r = 1.3
    /// Column of number n on the line, of counter n's left edge in a row.
    static func x(_ n: Int) -> Double { 3 * Double(n) }

    /// A counter in the cell from (x, y). `cross`: taken away. `red`: tapped or slid and wrong.
    static func counter(_ pen: inout GridPen, _ id: String, x: Double, y: Double, _ style: Style, cross: Bool = false, red: Bool = false) {
        let cx = x + 1.5, cy = y + 1.5
        switch style {
        case .solid: pen.dot(id + "d", at: cx, cy, radius: r, .chapter)
        case .striped:
            let pts = (0..<32).map { i in let a = Double(i) / 32 * 2 * .pi; return pen.P(cx + r * cos(a), cy + r * sin(a)) }
            pen.sketch.polygon(id + "f", pts, .tint(0.2))
            var segs: [(CGPoint, CGPoint)] = []
            for k in -2...2 {
                let d = Double(k) * 0.7
                guard abs(d) < r - 0.1 else { continue }
                let half = (r * r - d * d).squareRoot() / 2.0.squareRoot(), mx = cx + d / 2.0.squareRoot(), my = cy - d / 2.0.squareRoot()
                segs.append((pen.P(mx - half, my - half), pen.P(mx + half, my + half)))
            }
            pen.sketch.segments(id + "s", segs, .tint(0.6), width: Sketch.stroke)
        case .dotted:
            let pts = (0..<32).map { i in let a = Double(i) / 32 * 2 * .pi; return pen.P(cx + r * cos(a), cy + r * sin(a)) }
            pen.sketch.polygon(id + "f", pts, .tint(0.2))
            for (k, o) in [(0.0, 0.0), (-0.55, -0.55), (0.55, -0.55), (-0.55, 0.55), (0.55, 0.55)].enumerated() {
                pen.dot("\(id)p\(k)", at: cx + o.0, cy + o.1, radius: 0.17, .chapter, over: true)
            }
        }
        if style != .solid || red { pen.circle(id + "o\(red)", at: cx, cy, radius: r, red ? KK.red : .chapter) }
        if cross { pen.line(id + "x", [(x + 0.4, y + 2.6), (x + 2.6, y + 0.4)]) }
    }
    /// A counter's place left behind once it's given away: its outline dashed, so the row still reads as its number.
    static func gone(_ pen: inout GridPen, _ id: String, x: Double, y: Double) { pen.circle(id, at: x + 1.5, y + 1.5, radius: r, .ink3, dashed: true) }

    /// A row of n places from (x, y): dashed 3 × 3 cells, or solid in the chapter's colour once full.
    static func places(_ pen: inout GridPen, _ id: String, x: Double, y: Double, _ n: Int = 10, full: Bool = false) {
        let c: Sketch.Colour = full ? .chapter : .ink3
        pen.sketch.box("\(id)o\(full)", pen.R(x, y, 3 * Double(n), 3), c, width: Sketch.stroke, dashed: !full)
        let segs = (1..<n).map { i in (pen.P(x + 3 * Double(i), y), pen.P(x + 3 * Double(i), y + 3)) }
        if full { pen.sketch.segments("\(id)d\(full)", segs, c, width: Sketch.stroke) }
        else { for (i, s) in segs.enumerated() { pen.line("\(id)d\(i)", [(s.0.x / GridPen.sq, s.0.y / GridPen.sq), (s.1.x / GridPen.sq, s.1.y / GridPen.sq)], c, dashed: true) } }
    }

    /// The number line 0 to 20 on row y: a tick every 3 squares (longer on the fives), each number under its tick; `lit`
    /// numbers in the chapter's colour, `ring` ringed.
    static func line(_ pen: inout GridPen, _ id: String, y: Double, lit: Set<Int> = [], ring: Int? = nil) {
        pen.line(id, [(0, y), (60, y)])
        pen.sketch.segments(id + "t", (0...20).map { n in (pen.P(x(n), y), pen.P(x(n), y + (n % 5 == 0 ? 1 : 0.5))) }, .ink, width: Sketch.stroke)
        for n in 0...20 { pen.word("\(id)n\(n)\(lit.contains(n) ? "L" : "")", "\(n)", at: x(n), y + 1.85, lit.contains(n) ? KT.smallLit : KT.small) }
        if let ring { pen.circle("\(id)r\(ring)", at: x(ring), y + 1.85, radius: 1.15, .chapter) }
    }

    /// A hop: an arc from column x1 to x2 standing on row y, h squares high, its arrowhead where it lands.
    static func hop(_ pen: inout GridPen, _ id: String, from x1: Double, to x2: Double, y: Double, h: Double) {
        let pts = (0...16).map { i -> (Double, Double) in
            let t = Double(i) / 16, u = 1 - t
            return (u * u * x1 + 2 * u * t * (x1 + x2) / 2 + t * t * x2, u * u * y + 2 * u * t * (y - 2 * h) + t * t * y)
        }
        pen.line(id, pts, .chapter)
        let tx = x2 - (x1 + x2) / 2, ty = 2 * h, l = (tx * tx + ty * ty).squareRoot(), ux = tx / l, uy = ty / l, a = 0.6
        func p(_ s: Double, _ n: Double) -> (Double, Double) { (x2 - ux * a * s - uy * a * n, y - uy * a * s + ux * a * n) }
        pen.line(id + "a", [p(1, 0.6), (x2, y), p(1, -0.6)], .chapter)
    }

    /// Words written small in the chapter's colour from (x, row), or centred on x: a readout left on the paper.
    static func note(_ pen: inout GridPen, _ id: String, _ text: String, x: Double, y: Double, centred: Bool = false) {
        pen.word("\(id):\(text)", text, at: x, y, KK.lit, anchor: centred ? .center : UnitPoint(x: 0, y: 0.5))
    }

    // MARK: the record

    enum Tok { case n(Int, Sketch.Colour = .ink), op(String), box(Int?, wrong: Bool) }
    /// A record line from column 0 on the row whose middle is `line`: numbers and signs written tight (M7's), boxes 4
    /// squares wide half a square on.
    static func record(_ pen: inout GridPen, _ id: String, _ toks: [Tok], x x0: Double = 0, line: Double = 1) {
        var x = x0, run: [M7.Tok] = [], k = 0
        func flush() {
            guard !run.isEmpty else { return }
            x = M7.row(&pen, "\(id)r\(k)", run, x: x, line: line); run = []; k += 1
        }
        for t in toks {
            switch t {
            case .n(let v, let c): run.append(.n(v, c))
            case .op(let o): run.append(.op(o))
            case .box(let v, let wrong):
                flush()
                let bx = x == x0 ? x0 : (x + 0.5).rounded(.up)
                KK.box(&pen, "\(id)b\(k)", x: bx, line: line, value: v, wrong: wrong)
                x = bx + 4.5; k += 1
            }
        }
        flush()
    }

    // MARK: the number row 0–20

    /// 0–10 on row y from column 0 (0's key on 0–5), 11–20 on the row a block under it, each teen under its ones.
    static let x0 = 5.0
    static func numberRow(_ pen: inout GridPen, _ id: String, y: Double, wrong: Int? = nil, spot: Int? = nil) {
        KK.numberRow(&pen, id + "a", y: y, x0: x0, wrong: wrong.flatMap { $0 <= 10 ? $0 : nil }, spot: spot.flatMap { $0 <= 10 ? $0 : nil }, keys: 0...10)
        KK.numberRow(&pen, id + "b", y: y + 5, x0: x0 - 50, wrong: wrong.flatMap { $0 > 10 ? $0 : nil }, spot: spot.flatMap { $0 > 10 ? $0 : nil }, keys: 11...20)
    }
    static func tapped(_ q: CGPoint, y: Double) -> Int? { KK.tapped(q, y: y, x0: x0, keys: 0...10) ?? KK.tapped(q, y: y + 5, x0: x0 - 50, keys: 11...20) }
    static func keySpot(_ v: Int, y: Double) -> CGPoint { v <= 10 ? KK.keySpot(v, y: y, x0: x0) : KK.keySpot(v, y: y + 5, x0: x0 - 50) }
    /// The number row's hands: a key tapped writes it in `box` and checks it.
    static func rowHands(_ box: String, y: Double) -> Hands {
        Hands(tap: { q in tapped(q, y: y).map { HandMove(hand: nil, missHand: nil, set: [(box, Double($0))], check: true) } })
    }
    /// A slip tapped on the row: one more than the answer (one less at 20).
    static func slip(_ box: String, _ want: Int) -> HandMove { HandMove(hand: nil, missHand: nil, set: [(box, Double(want < 20 ? want + 1 : want - 1))], check: true) }
}
