import SwiftUI

/// Box plots on the paper, as in the preview (design/prototype/grade6-ch8.html, dBox): the question over a dot plot of
/// 11–15 answers already stacked on a line 0–20 (two squares a one, a dot 2 × 2), and a strip under it for the box. Tap
/// the middle answer (it's ringed, a dashed line drops from it to the strip; "6 below, 6 above"); then the middle of each
/// half (each half shades as it's found, the median left out of both); the box draws from one middle to the other, the
/// median across it, the whiskers out to the least and the greatest; write `IQR = 12 − 6 = [6]`.
///
/// Hand keys: "lo", "hi" (each half's middle found).
@MainActor
struct BoxPlotLesson: PaperLesson {
    static let X0 = 2.0, U = 2.0
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    @MainActor struct G {
        let P: BoxPlot6.Parts
        init(_ n: Numbers) { P = BoxPlot6.Parts(n) }
        static func x(_ v: Double) -> Double { X0 + U * v }
        var top: Double { 1 + 2 * Double(D8.rows(P.Q.q, width: 46).count) }
        var LY: Double { top + 2 * Double(P.counts.max() ?? 1) }
        var BT: Double { LY + 4 }
        var LX1: Double { G.x(20) + 2 }
        func first(_ v: Int) -> Int { P.s.firstIndex(of: v) ?? 0 }
        /// Sorted answer k's middle: its number, its place in its stack.
        func dot(_ k: Int) -> CGPoint { let v = P.s[k]; return CGPoint(x: G.x(Double(v)), y: LY - 1 - 2 * Double(k - first(v))) }
        /// The sorted answer under a finger.
        func at(_ q: CGPoint) -> Int? {
            let v = Int(((q.x - X0) / U).rounded())
            guard (0...20).contains(v), P.counts[v] > 0, abs(q.x - G.x(Double(v))) <= 1.1 else { return nil }
            let k = Int(((LY - q.y) / 2).rounded(.down))
            return k >= 0 && k < P.counts[v] ? first(v) + k : nil
        }
    }

    func recordRow(_ n: Numbers) -> Double? { G(n).BT + 6 }
    func keysFocus(_ s: PaperState) -> CGRect? {
        let g = G(s.numbers)
        return stage(s) == 3 ? CGRect(x: G.x(g.P.q1) - 2, y: g.BT - 1, width: G.x(g.P.q3) - G.x(g.P.q1) + 4, height: 6) : nil
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let g = G(s.numbers), P = g.P, at = stage(s), LY = g.LY, BT = g.BT, X = G.x, n = P.n, h = P.h
        var pic = GridPen(), rec = GridPen()
        D8.question(&pic, P.Q.q, width: 46)
        pic.rule("ln", from: X(0) - 2, to: g.LX1, row: LY)
        pic.line("lna", [(g.LX1 - 0.8, LY - 0.8), (g.LX1, LY), (g.LX1 - 0.8, LY + 0.8)])
        pic.sketch.segments("lt", (0...20).map { u in (pic.P(X(Double(u)), LY), pic.P(X(Double(u)), LY + 0.5)) }, .ink, width: Sketch.stroke)
        for u in 0...20 { pic.label("ll\(u)", "\(u)", D8.small, .below, edge: LY + 0.5, along: X(Double(u))) }
        pic.label("lu", P.Q.unit, D8.small, .right, edge: g.LX1 + 0.3, along: LY)

        let lo = at == 2 ? (s.h("lo") ?? 0) != 0 : at > 2, hi = at == 2 ? (s.h("hi") ?? 0) != 0 : at > 2
        // each half shades once its middle is found
        for k in 0..<n {
            let c = g.dot(k)
            if (lo && k < h) || (hi && k >= n - h) { pic.fill("sh\(k)", col: c.x - 1, row: c.y - 1, w: 2, h: 2, D8.fill) }
            pic.dot("d\(k)", at: c.x, c.y, radius: 0.8, .chapter, over: true)
        }
        // the middles ringed, a dashed line from each down to the strip
        var marks: [(String, Double, [Int])] = []
        if at >= 2 { marks.append(("md", P.median, BoxPlot6.Parts.mids(0, n))) }
        if lo { marks.append(("q1", P.q1, BoxPlot6.Parts.mids(0, h))) }
        if hi { marks.append(("q3", P.q3, BoxPlot6.Parts.mids(n - h, h))) }
        for (key, v, ks) in marks {
            for k in ks { let c = g.dot(k); pic.circle("\(key)r\(k)", at: c.x, c.y, radius: 1.05, .chapter) }
            pic.line("\(key)dl", [(X(v), LY + 2.5), (X(v), BT)], .chapter, dashed: true)
        }
        // the box: from the lower middle to the upper middle, the median across it, the whiskers out to the ends
        if at >= 3 {
            let y = BT + 2
            pic.sketch.box("bx", pic.R(X(P.q1), BT, X(P.q3) - X(P.q1), 4), .chapter, width: Sketch.stroke)
            pic.line("bm", [(X(P.median), BT), (X(P.median), BT + 4)], .chapter)
            pic.line("wl", [(X(Double(P.least)), y), (X(P.q1), y)], .chapter); pic.line("wr", [(X(P.q3), y), (X(Double(P.most)), y)], .chapter)
            pic.line("we0", [(X(Double(P.least)), y - 1), (X(Double(P.least)), y + 1)], .chapter)
            pic.line("we1", [(X(Double(P.most)), y - 1), (X(Double(P.most)), y + 1)], .chapter)
        }
        if at == 2 { let b = n / 2; pic.word("rd", "\(b) below, \(b) above", at: g.LX1 + 1, LY + 3, D8.lit, anchor: UnitPoint(x: 0, y: 0.5)) }

        // hints: a first miss rings the general area, a second the exact spot (call of 3 Nov)
        func ringDots(_ id: String, _ ks: ClosedRange<Int>) {
            let a = g.dot(ks.lowerBound), b = g.dot(ks.upperBound), tall = Double(P.counts.max() ?? 1) * 2
            R6.ring(&pic, id, x: a.x - 1, y: LY - tall, w: b.x - a.x + 2, h: tall)
        }
        switch at {
        case 1:
            let m = BoxPlot6.Parts.mids(0, n)
            if s.on("ring") { ringDots("ring", max(0, m[0] - 2)...min(n - 1, m.last! + 2)) }
            if s.on("spot") { for k in m { let c = g.dot(k); pic.circle("spot\(k)", at: c.x, c.y, radius: 1.4, .chapter, dashed: true) } }
        case 2:
            if s.on("ring") { if !lo { ringDots("ringl", 0...(h - 1)) }; if !hi { ringDots("ringh", (n - h)...(n - 1)) } }
            if s.on("spot") {
                for k in (lo ? [] : BoxPlot6.Parts.mids(0, h)) + (hi ? [] : BoxPlot6.Parts.mids(n - h, h)) { let c = g.dot(k); pic.circle("spot\(k)", at: c.x, c.y, radius: 1.4, .chapter, dashed: true) }
            }
        case 3:
            if s.on("ring") { R6.ring(&pic, "ring", x: X(P.q1), y: BT, w: X(P.q3) - X(P.q1), h: 4) }
            if s.on("spot") { for v in [P.q1, P.q3] { pic.label("sp\(v)", fmt(v), D8.lit, .below, edge: BT + 4, along: X(v)) } }
        default: break
        }

        // the record
        if at >= 3 {
            let A: M7.Tok = at == 3 ? .box("A", cells: max(1, fmt(P.iqr).count)) : .t(fmt(P.iqr), .chapter)
            M7.row(&rec, "r", [.w("IQR"), .op("="), .t(fmt(P.q3)), .op("−"), .t(fmt(P.q1)), .op("="), A], x: 0, line: 1)
        }
        let ext = pic.R(-1, 0, 57, BT + 5)
        return PaperDrawing(picture: pic.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    func hands(_ s: PaperState) -> Hands? {
        let g = G(s.numbers), P = g.P
        switch stage(s) {
        case 1:
            return Hands(tap: { q in g.at(q).map { HandMove(hand: [:], missHand: [:], set: [("k", Double($0))], check: true) } })
        case 2:
            let now: Numbers = ["lo": s.h("lo") ?? 0, "hi": s.h("hi") ?? 0]
            return Hands(tap: { q in
                guard let k = g.at(q) else { return nil }
                let r = P.half(k)
                guard let side = r.side else { return HandMove(hand: now, missHand: now, set: [("k", Double(k))], check: true) }
                var h = now
                h[side == 0 ? "lo" : "hi"] = 1
                let both = h["lo"] == 1 && h["hi"] == 1
                return HandMove(hand: h, missHand: h, set: both ? [("k", -1)] : [], check: both)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let g = G(s.numbers), P = g.P
        switch stage(s) {
        case 1: return [.tap(.picture(g.dot(BoxPlot6.Parts.mids(0, P.n)[0])))]
        case 2:
            var out: [GhostMove] = []
            if (s.h("lo") ?? 0) == 0 { out.append(.tap(.picture(g.dot(BoxPlot6.Parts.mids(0, P.h)[0])))) }
            if (s.h("hi") ?? 0) == 0 { out.append(.tap(.picture(g.dot(BoxPlot6.Parts.mids(P.n - P.h, P.h)[0])))) }
            return out
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = BoxPlot6.Parts(s.numbers)
        switch stage(s) {
        case 1:
            // one beside the middle, as a child counting in would land
            let m = BoxPlot6.Parts.mids(0, P.n)[0], k = (0..<P.n).filter { P.middle($0) != nil }.min { abs($0 - m) < abs($1 - m) } ?? 0
            return HandMove(hand: [:], missHand: [:], set: [("k", Double(k))], check: true)
        case 2:
            let now: Numbers = ["lo": s.h("lo") ?? 0, "hi": s.h("hi") ?? 0]
            let m = BoxPlot6.Parts.mids(0, P.h)[0], k = (0..<P.n).filter { P.half($0).miss != nil }.min { abs($0 - m) < abs($1 - m) } ?? 0
            return HandMove(hand: now, missHand: now, set: [("k", Double(k))], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = BoxPlot6.Parts(s.numbers)
        return stage(s) == 3 ? ["A": Double(P.most - P.least)] : nil
    }
}
