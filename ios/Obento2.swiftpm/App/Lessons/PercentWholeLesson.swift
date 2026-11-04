import SwiftUI

/// Find the whole on the paper, as in the preview (design/prototype/grade6-ch1.html, dPctWhole): the same bar, 2.5% a
/// square. The 100% bar is dashed and named "?"; the known piece sits at its left end, shaded, holding P. Lay copies of it
/// end to end (a tap lays one, a drag lays as many as reach the finger): each holds P, its end is labelled with the
/// percent so far, hops arc over them, "4 blocks · 100%"; past 100% they're red. Then `P × k = [ ]` is written and the
/// bar is named the whole.
@MainActor
struct PercentWholeLesson: PaperLesson {
    static let x0 = 0.0, y0 = 3.0, bh = 4.0, bw = Double(PercentOf.bar)
    var liveKeys: Set<String> { [] }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func count(_ s: PaperState, _ P: PercentWhole.Parts) -> Int { stage(s) >= 2 ? P.k : Int((s.h("c") ?? 1).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { Self.y0 + Self.bh + 3 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = PercentWhole.Parts(s.numbers), at = stage(s), done = at >= 3
        let x0 = Self.x0, y0 = Self.y0, bh = Self.bh, bw = Self.bw, pw = Double(P.width), c = count(s, P)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        // the rest of the 100% bar, dashed, and its name
        let laid = Double(min(c, P.k)) * pw
        if laid < bw {
            pic.line("bart\(laid)", [(x0 + laid, y0), (x0 + bw, y0)], .ink, dashed: true)
            pic.line("barb\(laid)", [(x0 + laid, y0 + bh), (x0 + bw, y0 + bh)], .ink, dashed: true)
            pic.line("barr", [(x0 + bw, y0), (x0 + bw, y0 + bh)], .ink, dashed: true)
        }
        let end = x0 + max(bw, Double(c) * pw)
        pic.label("barn\(done)", done ? "\(P.whole)" : "?", done ? R6.maths.colour(.chapter) : R6.maths, .right, edge: end, along: y0 + bh / 2)
        // the blocks laid: each holds P, its end labelled; past 100% in red
        for j in 0..<c {
            let x = x0 + Double(j) * pw, over = j >= P.k
            if !over { pic.fill("cpf\(j)", col: x, row: y0, w: pw, h: bh, Bars.shade) }
            pic.sketch.box("cp\(j)\(over)", pic.R(x, y0, pw, bh), over ? R6.red : .chapter, width: Sketch.stroke)
            pic.word("cv\(j)\(over)", "\(P.P)", at: x + pw / 2, y0 + bh / 2, R6.maths.colour(over ? R6.red : .ink))
            let lab = j == P.k - 1 ? R6.lit : over ? R6.lit.colour(R6.red) : R6.small
            pic.label("cl\(j)\(over)\(j == P.k - 1)", "\((j + 1) * P.p)%", lab, .below, edge: y0 + bh, along: x + pw)
            if j > 0 { pic.hop("hop\(j)", from: x - pw / 2, to: x + pw / 2, row: y0 - 0.3, height: min(1.5, pw / 6 + 0.5) * 2, over ? R6.red : .chapter) }
        }
        if at == 1 {
            let ro = "\(c) block\(c == 1 ? "" : "s") · \(c * P.p)%"
            pic.word("ro\(c)", ro, at: x0, y0 + bh + 3, R6.lit, anchor: UnitPoint(x: 0, y: 0.5))
            if s.grabbed { live.reads(ro) }
            // a hint: the bar's end ringed; a second miss, where each block of the 100% ends
            if s.on("ring") { R6.ring(&pic, "ring", x: x0 + bw + 0.3, y: y0, w: 2, h: bh) }
            if s.on("spot") { for j in 1..<P.k { pic.line("spot\(j)", [(x0 + Double(j) * pw, y0 - 1), (x0 + Double(j) * pw, y0)], .chapter) } }
        }
        if at == 2 && s.on("ring") { R6.ring(&pic, "ring", x: x0, y: y0, w: bw, h: bh) }
        if at == 2 && s.on("spot") { pic.label("spot", "\(P.k) blocks", R6.lit, .right, edge: end + 3, along: y0 + bh / 2) }
        if at >= 2 {
            let ans: M7.Tok = done ? .n(P.whole, .chapter) : .box("x", cells: String(P.whole).count)
            M7.row(&rec, "rec", [.n(P.P), .op("×"), .n(P.k), .op("="), ans], x: 0, line: 1)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes,
                            extent: at <= 1 ? pic.R(0, 0, x0 + Double(P.most) * pw + 4, y0 + bh + 4) : nil)
    }

    func hands(_ s: PaperState) -> Hands? {
        guard stage(s) == 1 else { return nil }
        let P = PercentWhole.Parts(s.numbers), c = count(s, P), pw = Double(P.width), x0 = Self.x0, y0 = Self.y0, bh = Self.bh
        func inside(_ q: CGPoint) -> Bool { q.y >= y0 - 4 && q.y <= y0 + bh + 2 && q.x >= x0 - 1 && q.x <= x0 + Double(P.most) * pw + 2 }
        func lay(_ n: Int) -> HandMove {
            if n == P.k { return HandMove(hand: ["c": Double(n)], missHand: nil, set: [("x", Double(n))], check: true) }
            if n == 1 { return HandMove(hand: ["c": 1], missHand: nil) }
            return HandMove(hand: ["c": Double(n)], missHand: n > P.k ? ["c": 1] : nil, set: [("x", Double(n))], check: true)
        }
        return Hands(
            // a tap lays one more
            tap: { q in inside(q) && c < P.k ? (c + 1 == P.k ? lay(c + 1) : HandMove(hand: ["c": Double(c + 1)], missHand: nil)) : nil },
            grab: { q in inside(q) ? ["grab": 1, "c": Double(c), "from": Double(c)] : nil },
            drag: { q, h in ["grab": 1, "from": h["from"] ?? Double(c), "c": Double(max(1, min(P.most, Int(((q.x - x0) / pw).rounded()))))] },
            release: { h in
                let n = Int((h["c"] ?? 1).rounded())
                // let go where it began: nothing to check
                guard Double(n) != h["from"] else { return HandMove(hand: ["c": Double(n)], missHand: nil) }
                return lay(n)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard stage(s) == 1 else { return [] }
        let P = PercentWhole.Parts(s.numbers), pw = Double(P.width), y = Self.y0 + Self.bh / 2
        return [.drag(from: CGPoint(x: Self.x0 + Double(count(s, P)) * pw, y: y), to: CGPoint(x: Self.x0 + Double(P.k) * pw, y: y))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard stage(s) == 1 else { return nil }
        let P = PercentWhole.Parts(s.numbers), n = P.k > 2 ? P.k - 1 : P.k + 1
        return HandMove(hand: ["c": Double(n)], missHand: n > P.k ? ["c": 1] : nil, set: [("x", Double(n))], check: true)
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        guard stage(s) == 2 else { return nil }
        let P = PercentWhole.Parts(s.numbers)
        return ["x": Double(P.P * P.k - P.P)]
    }
}
