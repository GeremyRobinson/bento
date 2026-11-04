import SwiftUI

/// Equivalent ratios on the paper, as in the preview (design/prototype/grade6-ch1.html, dRatio): one thing is a cell
/// (3 × 3 squares; 2 × 2 past 6 times, so every problem shows at 75%). Two rectangles a block apart, a cells and b cells
/// wide (the left tinted, the right striped), one row each, `a : b` over their tops, "?" under the left and b·k under the
/// right. Drag the bottom edge down: both grow a row at a time, each row one more a : b, "4 rows · 12" beside it. Let go
/// at b·k; the rows number down the side, every left row a and every right row b; then `a : b = a × k : b × k = [ ] : b·k`
/// is written.
@MainActor
struct EquivRatioLesson: PaperLesson {
    static let x0 = 5.0, y0 = 3.0
    var liveKeys: Set<String> { ["r"] }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// A cell's squares: 3, or 2 when the rows would run past the screen.
    static func c(_ P: EquivRatio.Parts) -> Double { P.k <= 6 ? 3 : 2 }
    private func geo(_ P: EquivRatio.Parts) -> (C: Double, xr: Double, re: Double) {
        let C = Self.c(P), xr = Self.x0 + C * Double(P.a) + 5
        return (C, xr, xr + C * Double(P.b))
    }
    private func bot(_ P: EquivRatio.Parts, _ r: Int) -> Double { Self.y0 + Self.c(P) * Double(r) }
    private func rows(_ s: PaperState, _ P: EquivRatio.Parts) -> Int { stage(s) >= 2 ? P.k : Int((s.h("r") ?? 1).rounded()) }

    func recordRow(_ n: Numbers) -> Double? { let P = EquivRatio.Parts(n); return bot(P, P.k) + 4 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = EquivRatio.Parts(s.numbers), at = stage(s), done = at >= 3, moving = at <= 1
        let (C, xr, re) = geo(P), x0 = Self.x0, y0 = Self.y0, r = rows(s, P)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        // a : b over their tops
        pic.label("ta", "\(P.a)", R6.maths, .above, edge: y0, along: x0 + C * Double(P.a) / 2)
        pic.label("tc", ":", R6.maths, .above, edge: y0, along: xr - 2.5)
        pic.label("tb", "\(P.b)", R6.maths, .above, edge: y0, along: xr + C * Double(P.b) / 2)
        // the rows: following the hand while it drags, then still
        func body(_ p: inout GridPen) {
            R6.cells(&p, "L", x: x0, y: y0, cols: P.a, rows: r, c: C)
            R6.cells(&p, "R", x: xr, y: y0, cols: P.b, rows: r, c: C, striped: true)
            p.label("ql", done ? "\(P.left)" : "?", done ? R6.maths.colour(.chapter) : R6.maths, .below, edge: bot(P, r), along: x0 + C * Double(P.a) / 2)
            p.label("qr", "\(P.total)", R6.maths, .below, edge: bot(P, r), along: xr + C * Double(P.b) / 2)
        }
        if moving { body(&live) } else { body(&pic) }
        if at == 1 {
            R6.handle(&live, "h", re, bot(P, r), held: s.grabbed)
            let ro = "\(r) row\(r == 1 ? "" : "s") · \(r * P.b)"
            live.label("ro", ro, R6.lit, .right, edge: re + 0.8, along: bot(P, r))
            if s.grabbed { live.reads(ro) }
            // a hint: the total to reach ringed; a second miss, the row it's reached at
            if s.on("ring") { R6.ring(&pic, "ring", x: xr + C * Double(P.b) / 2 - 1.5, y: bot(P, P.k) + 0.8, w: 3, h: 1.8) }
            if s.on("spot") { pic.line("spot", [(x0 - 1, bot(P, P.k)), (re + 1, bot(P, P.k))], .chapter, dashed: true) }
        }
        // See: the rows number down the side; every left row is a, every right row b
        if at >= 2 {
            for j in 0..<P.k {
                let y = y0 + C * Double(j) + C / 2
                pic.label("rn\(j)", "\(j + 1)", R6.small, .left, edge: x0 - 0.5, along: y)
                let left = at == 2 && s.on("spot") ? "\(P.a * (j + 1))" : "\(P.a)"
                pic.label("rva\(j)\(left)", left, R6.lit, .right, edge: x0 + C * Double(P.a) + 0.3, along: y)
                pic.label("rvb\(j)", "\(P.b)", R6.lit, .right, edge: re + 0.3, along: y)
            }
            if at == 2 && s.on("ring") { R6.ring(&pic, "ringL", x: x0 + C * Double(P.a) / 2 - 1.5, y: bot(P, P.k) + 0.8, w: 3, h: 1.8) }
            let ans: M7.Tok = done ? .n(P.left, .chapter) : .box("x", cells: String(P.left).count)
            M7.row(&rec, "rec", [.n(P.a), .op(" : "), .n(P.b), .op("="), .n(P.a), .op("×"), .n(P.k), .op(" : "), .n(P.b), .op("×"), .n(P.k), .op("="), ans, .op(" : "), .n(P.total)], x: 0, line: 1)
        }
        let reach = bot(P, P.maxRows) + 2
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes,
                            extent: moving ? pic.R(0, 0, re + 1 + R6.width("\(P.maxRows) rows · \(P.maxRows * P.b)") + 1, reach) : nil)
    }

    func hands(_ s: PaperState) -> Hands? {
        guard stage(s) == 1 else { return nil }
        let P = EquivRatio.Parts(s.numbers), (C, _, re) = geo(P), r = rows(s, P), y = bot(P, r), x0 = Self.x0, y0 = Self.y0
        return Hands(
            grab: { q in abs(q.y - y) <= 2 && q.x >= x0 - 1 && q.x <= re + 2 ? ["grab": 1, "r": Double(r)] : nil },
            drag: { q, _ in ["grab": 1, "r": Double(max(1, min(P.maxRows, Int(((q.y - y0) / C).rounded()))))] },
            release: { h in
                let r = Int((h["r"] ?? 1).rounded())
                guard r != 1 else { return HandMove(hand: ["r": 1], missHand: nil) }
                // past the total: the rows go back to one
                return HandMove(hand: ["r": Double(r)], missHand: r > P.k ? ["r": 1] : nil, set: [("x", Double(r))], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard stage(s) == 1 else { return [] }
        let P = EquivRatio.Parts(s.numbers), re = geo(P).re
        return [.drag(from: CGPoint(x: re, y: bot(P, rows(s, P))), to: CGPoint(x: re, y: bot(P, P.k)))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard stage(s) == 1 else { return nil }
        let P = EquivRatio.Parts(s.numbers), r = P.k > 2 ? P.k - 1 : P.k + 1
        return HandMove(hand: ["r": Double(r)], missHand: r > P.k ? ["r": 1] : nil, set: [("x", Double(r))], check: true)
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = EquivRatio.Parts(s.numbers)
        return stage(s) == 2 ? ["x": Double(P.a + P.total - P.b)] : nil
    }

    func messageRows(_ n: Numbers) -> Int { 1 }
}
