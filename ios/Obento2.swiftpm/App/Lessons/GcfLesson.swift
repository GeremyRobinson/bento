import SwiftUI

/// Factor out the GCF on the paper, as in the preview (design/prototype/grade6-ch2.html, dGcf): one square a number (two
/// when both are 24 or less), two bars A and B squares long, named at their right ends. The ruler under them: its handle
/// sets one piece's length (any whole length up to the shorter bar), the cuts it would make dashed across both bars, and
/// at each bar's end a dot, green when a cut lands there, red with what's over ("2 over"); "pieces of 6"; Cut commits.
/// Then the cuts turn solid and each bar's pieces are numbered, and `GCF(18, 30) = 6`, `18 + 30 = 6([ ] + [ ])` are
/// written.
@MainActor
struct GcfLesson: PaperLesson {
    static let H = 4.0
    /// Bars too long for their numbers beside them at 75% (72 squares) have them over their right ends, the bars further
    /// apart for it.
    static func above(_ P: Gcf6.Parts) -> Bool { Double(P.long * P.U) + 5 > 73 }
    static func ys(_ P: Gcf6.Parts) -> [Double] { above(P) ? [2, 10] : [0, 6] }
    /// The ruler's row.
    static func RY(_ P: Gcf6.Parts) -> Double { ys(P)[1] + H + 2 }
    var liveKeys: Set<String> { ["p", "grab"] }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func piece(_ s: PaperState) -> Int { Int((s.h("p") ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { Self.ys(Gcf6.Parts(n))[1] + Self.H + 3 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Gcf6.Parts(s.numbers), at = stage(s), U = Double(P.U), g = P.g, cut = at >= 2, H = Self.H
        func xv(_ v: Int) -> Double { Double(v) * U }
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        var actions: [String] = []
        let ys = Self.ys(P), above = Self.above(P)
        for (k, len) in [P.A, P.B].enumerated() {
            let y = ys[k]
            if k == 0 { pic.fill("b0f", col: 0, row: y, w: xv(len), h: H, Bars.shade) } else { pic.stripes("b1s", col: 0, row: y, w: xv(len), h: H) }
            pic.sketch.box("b\(k)o", pic.R(0, y, xv(len), H), .chapter, width: Sketch.stroke)
            // its number at its right end, clear of the end's dot
            if above { pic.label("b\(k)n", "\(len)", R6.maths, .above, edge: y, along: xv(len) - R6.width("\(len)", R6.maths) / 2) }
            else { pic.label("b\(k)n", "\(len)", R6.maths, .right, edge: xv(len) + 0.7, along: y + H / 2) }
            if cut {
                // See: the cuts turn solid and each bar's pieces count 1, 2, 3…
                pic.sketch.segments("sc\(k)", stride(from: g, to: len, by: g).map { v in (pic.P(xv(v), y), pic.P(xv(v), y + H)) }, .chapter, width: Sketch.stroke)
                for j in 0..<(len / g) { pic.word("pn\(k)_\(j)", "\(j + 1)", at: xv(g * j) + xv(g) / 2, y + H / 2, Bars.count) }
                if at == 2 && s.on("spot") { pic.circle("spot\(k)", at: xv(len) - xv(g) / 2, y + H / 2, radius: 1.1, .chapter, dashed: true) }
            }
        }
        if at == 1 {
            let p = piece(s)
            if p > 0 {
                for (k, len) in [P.A, P.B].enumerated() {
                    let y = ys[k], over = len % p
                    for v in stride(from: p, to: len, by: p) { live.line("dc\(k)_\(v)", [(xv(v), y - 0.6), (xv(v), y + H + 0.6)], .ink2, dashed: true) }
                    live.dot("end\(k)", at: xv(len), y + H / 2, radius: 0.45, over > 0 ? Bars.red : Bars.green, over: true)
                    if over > 0 { live.word("ov\(k)", "\(over) over", at: xv(len), y + H + 1, R6.small.colour(Bars.red), anchor: UnitPoint(x: 1, y: 0.5)) }
                }
            }
            // the ruler under the bars
            let RY = Self.RY(P)
            live.line("ruler", [(0, RY - 0.6), (0, RY), (xv(p), RY), (xv(p), RY - 0.6)], .chapter)
            R6.handle(&live, "rh", xv(p), RY, held: s.grabbed)
            if p > 0 {
                live.word("rro", "pieces of \(p)", at: 0, RY + 1.6, R6.lit, anchor: UnitPoint(x: 0, y: 0.5))
                if s.grabbed { live.reads("pieces of \(p)") }
            }
            if s.on("ring") { R6.ring(&pic, "ring", x: 0.5, y: ys[0], w: xv(P.long) - 1, h: ys[1] + H - ys[0]) }
            if s.on("spot") { pic.line("spot", [(xv(g), ys[0] - 1), (xv(g), ys[1] + H + 1)], .chapter, dashed: true) }
            actions = ["Cut"]
        }
        if at == 2 && s.on("ring") { R6.ring(&pic, "ring", x: 0.5, y: ys[0], w: xv(P.long) - 1, h: ys[1] + H - ys[0]) }
        if cut {
            M7.row(&rec, "r1", [.t("GCF(\(P.A), \(P.B))"), .op("="), .n(g, .chapter)], x: 0, line: 1)
            func box(_ id: String, _ v: Int) -> M7.Tok { at >= 3 ? .n(v, .chapter) : .box(id, cells: 1) }
            M7.row(&rec, "r2", [.n(P.A), .op("+"), .n(P.B), .op("="), .n(g), .t("("), box("m", P.m), .op("+"), box("n", P.n), .t(")")], x: 0, line: 4)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, actions: actions,
                            extent: at <= 1 ? pic.R(0, 0, above ? xv(P.long) + 0.5 : xv(P.long) + 1.2 + R6.width("\(P.long)", R6.maths), Self.RY(P) + 2.3) : nil)
    }

    func hands(_ s: PaperState) -> Hands? {
        guard stage(s) == 1 else { return nil }
        let P = Gcf6.Parts(s.numbers), U = Double(P.U), p = piece(s), long = Double(P.long) * U
        func snap(_ x: Double) -> Double { Double(max(1, min(P.short, Int((x / U).rounded())))) }
        return Hands(
            grab: { q in q.y >= Self.ys(P)[0] - 1 && q.y <= Self.RY(P) + 1.5 && q.x >= -1 && q.x <= long + 2 ? ["grab": 1, "p": snap(q.x)] : nil },
            drag: { q, _ in ["grab": 1, "p": snap(q.x)] },
            release: { h in HandMove(hand: ["p": h["p"] ?? Double(p)], missHand: nil) },
            actions: ["Cut": { HandMove(hand: nil, missHand: nil, set: [("x", Double(p))], check: true) }])
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard stage(s) == 1 else { return [] }
        let P = Gcf6.Parts(s.numbers), U = Double(P.U), p = piece(s)
        let RY = Self.RY(P)
        return (p == P.g ? [] : [.drag(from: CGPoint(x: Double(p) * U, y: RY), to: CGPoint(x: Double(P.g) * U, y: RY))]) + [.tap(.action("Cut"))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard stage(s) == 1 else { return nil }
        let P = Gcf6.Parts(s.numbers)
        // a length that leaves some over
        let p = (2...max(2, P.short)).first { P.A % $0 != 0 || P.B % $0 != 0 } ?? 1
        return HandMove(hand: ["p": Double(p)], missHand: nil, set: [("x", Double(p))], check: true)
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Gcf6.Parts(s.numbers)
        return stage(s) == 2 ? ["m": Double(P.A), "n": Double(P.B)] : nil
    }
}
