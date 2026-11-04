import SwiftUI

/// Dot plots on the paper, as in the preview (design/prototype/grade6-ch8.html, dDot): the question over the plot, a line
/// 0–10 four squares a one with its unit at its end, a dot (2 × 2) for each answer stacked over its number, the answers
/// as cards under it. First problems pick the question with many answers (two choices, in a column). Put each card on
/// the line (tap the number for the next card, or drag any card there): its dot glides off the card onto its stack and
/// the card is crossed off ("9 of 12"); write how many; tap the tallest stack (it shades); drag a bracket from the least
/// answer to the greatest ("1 to 9"). The record beside the cards: `[12] answers`, `most at 4`, `1 to 9`.
///
/// The picture's squares: the question from row 1, the line on `LY`, the bracket on `LY + 4`, the cards from `LY + 6`.
/// Hand keys: "p<j>" (card j's place in the order they went down), "grab", "j" (the card held), "hx", "hy" (its corner),
/// "dx", "dy" (where it was taken), "over" (the number under it), "lx", "ly" (where the last one was let go), "bad" (the
/// card a miss was on); "a", "b" (the bracket).
@MainActor
struct DotPlotLesson: PaperLesson {
    static let X0 = 2.0, U = 4.0, RX = 45.0
    var liveKeys: Set<String> { ["grab", "hx", "hy", "over", "b"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    @MainActor struct G {
        let P: DotPlot6.Parts
        init(_ n: Numbers) { P = DotPlot6.Parts(n) }
        static func x(_ u: Int) -> Double { X0 + U * Double(u) }
        var qRows: Int { D8.rows(P.Q.many, width: 46).count }
        var top: Double { 1 + 2 * Double(qRows) }
        var LY: Double { top + 2 * Double(P.tallest) }
        var BR: Double { LY + 4 }
        var CY: Double { LY + 6 }
        func val(_ q: CGPoint) -> Int { min(10, max(0, Int(((q.x - X0) / U).rounded()))) }
        func onLine(_ q: CGPoint) -> Bool { q.x > G.x(0) - 2 && q.x < G.x(10) + 2 && q.y > top - 1 && q.y < LY + 2.5 }
        /// Dot j's middle once placed: its stack's number, its height in the order the stack was built.
        func spot(_ j: Int, _ placed: [Int: Int]) -> CGPoint {
            let v = P.data[j], k = placed.filter { $0.key != j && P.data[$0.key] == v && $0.value < (placed[j] ?? 0) }.count
            return CGPoint(x: G.x(v), y: LY - 1 - 2 * Double(k))
        }
        func cardMid(_ j: Int) -> CGPoint { let c = D8.card(j, y0: CY); return CGPoint(x: c.x + 2, y: c.y + 1) }
    }

    func recordRow(_ n: Numbers) -> Double? { G(n).CY }
    func blocksLeft(_ n: Numbers) -> Double? { Self.RX }
    func blocksAt(_ s: PaperState) -> CGPoint? { stage(s) == 1 ? CGPoint(x: 0, y: 0) : nil }

    private func placed(_ s: PaperState, _ g: G) -> [Int: Int] {
        let at = stage(s)
        if at <= 1 { return [:] }
        let o = D8.order(s, n: g.P.n)
        if at > 2 { var all = o; for j in 0..<g.P.n where all[j] == nil { all[j] = 100 + j }; return all }
        return o
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let g = G(s.numbers), P = g.P, at = stage(s), LY = g.LY, X = G.x
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let ext = pic.R(-1, 0, 57, g.CY + D8.cardsHeight(P.n) + 1 - 0)
        // the pick: only the two questions, as choices (the plot comes once it's picked)
        if at == 1 { return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext) }

        D8.question(&pic, P.Q.many, width: 46)
        let held = at == 2 && s.grabbed ? s.h("j").map { Int($0) } : nil, over = held != nil ? s.h("over").map { Int($0) } : nil
        let bracket: (Int, Int)? = at == 5 && s.grabbed ? (Int(s.h("a") ?? 0), Int(s.h("b") ?? 0)) : at >= 6 ? (P.least, P.most) : nil
        // the line 0–10, four squares a one, its unit at its end
        pic.rule("ln", from: X(0) - 2, to: X(10) + 2, row: LY)
        pic.line("lna", [(X(10) + 1.2, LY - 0.8), (X(10) + 2, LY), (X(10) + 1.2, LY + 0.8)])
        pic.sketch.segments("lt", (0...10).map { u in (pic.P(X(u), LY), pic.P(X(u), LY + 0.5)) }, .ink, width: Sketch.stroke)
        for u in 0...10 {
            let on = (over == u && held != nil) || bracket.map { u == min($0.0, $0.1) || u == max($0.0, $0.1) } == true
            if on && (held != nil || at == 5) { live.label("llv\(u)", "\(u)", D8.lit, .below, edge: LY + 0.5, along: X(u)) }
            else { pic.label("ll\(u)\(on)", "\(u)", on ? D8.lit : D8.small, .below, edge: LY + 0.5, along: X(u)) }
        }
        pic.label("lu", P.Q.unit.1, D8.small, .right, edge: X(10) + 2.3, along: LY)

        // the tallest stack, once tapped, on a shaded column
        if at >= 5 { pic.fill("pk", col: X(P.peak) - 1, row: LY - 2 * Double(P.tallest), w: 2, h: 2 * Double(P.tallest), D8.fill) }
        // the dots: each glides off its card onto its stack as it goes down
        let order = placed(s, g), lastJ = order.max { $0.value < $1.value }?.key
        for j in D8.sequence(order, n: P.n) where order[j] != nil {
            let c = g.spot(j, order)
            if at == 2 {
                let f: CGPoint = j == lastJ ? s.h("lx").map { CGPoint(x: $0 + 2, y: (s.h("ly") ?? 0) + 1) } ?? g.cardMid(j) : g.cardMid(j)
                D8.glide(&pic) { $0.dot("d\(j)", at: f.x, f.y, radius: 0.8, .chapter, over: true) }
            }
            pic.dot("d\(j)", at: c.x, c.y, radius: 0.8, .chapter, over: true)
            pic.sketch.from = [:]
        }
        // the cards: the next one in the chapter's colour, the placed ones crossed off, the held one under the finger
        if at <= 2 {
            let next = (0..<P.n).first { order[$0] == nil && $0 != held }
            for j in 0..<P.n where j != held {
                D8.card(&pic, "cd\(j)", at: D8.card(j, y0: g.CY), P.data[j], order[j] != nil ? .done : at == 2 && j == next ? .now : .idle)
            }
            if let j = held { D8.card(&live, "ch", at: CGPoint(x: (s.h("hx") ?? 0).rounded(), y: (s.h("hy") ?? 0).rounded()), P.data[j], .held) }
        } else {
            for j in 0..<P.n { D8.card(&pic, "cd\(j)", at: D8.card(j, y0: g.CY), P.data[j], .done) }
        }
        // the readout beside the stacks: how many are down; the bracket's ends while it's dragged
        if at == 2 {
            let k = order.count
            pic.word("rd\(k)", "\(k) of \(P.n)", at: Self.RX, g.top + 1, D8.lit, anchor: UnitPoint(x: 0, y: 0.5))
            if held != nil { live.reads("\(k) of \(P.n)") }
        }
        // the bracket under the line, its ends turned up
        if let b = bracket, b.0 != b.1 {
            let lo = min(b.0, b.1), hi = max(b.0, b.1)
            var pen = at == 5 ? live : pic
            pen.line("br\(at == 5)", [(X(lo), g.BR - 1), (X(lo), g.BR), (X(hi), g.BR), (X(hi), g.BR - 1)], .chapter)
            if at == 5 { pen.word("rdb", "\(lo) to \(hi)", at: Self.RX, g.top + 1, D8.lit, anchor: UnitPoint(x: 0, y: 0.5)); pen.reads("\(lo) to \(hi)") }
            if at == 5 { live = pen } else { pic = pen }
        }

        // hints: a first miss rings the general area, a second the exact spot (call of 3 Nov)
        let ringAt: Int? = {
            switch at {
            case 2: let j = s.h("bad").map { Int($0) } ?? (0..<P.n).first { order[$0] == nil }; return j.map { P.data[$0] }
            case 4: return P.peak
            default: return nil
            }
        }()
        if s.on("ring") {
            if let u = ringAt {
                let a = max(0, u - 2), b = min(10, u + 2)
                R6.ring(&pic, "ring", x: X(a) - 1, y: at == 4 ? LY - 2 * Double(P.tallest) : LY - 1, w: X(b) - X(a) + 2, h: at == 4 ? 2 * Double(P.tallest) + 1.5 : 3)
            }
            if at == 3 { R6.ring(&pic, "ring", x: X(0) - 1, y: g.top, w: X(10) - X(0) + 2, h: LY - g.top) }
            if at == 5 { R6.ring(&pic, "ring", x: X(P.least) - 1, y: LY - 1, w: X(P.most) - X(P.least) + 2, h: 3) }
        }
        if s.on("spot") {
            if let u = ringAt { pic.circle("spot", at: X(u), at == 4 ? LY - 2 * Double(P.tallest) + 1 : LY, radius: 1.3, .chapter, dashed: true) }
            // each stack's count over it
            if at == 3 { for u in 0...10 where P.counts[u] > 0 { pic.label("sc\(u)", "\(P.counts[u])", D8.lit, .above, edge: LY - 2 * Double(P.counts[u]), along: X(u)) } }
            if at == 5 { for u in [P.least, P.most] { pic.circle("spot\(u)", at: X(u), LY, radius: 1.3, .chapter, dashed: true) } }
        }

        // the record beside the cards
        if at >= 3 {
            let n: M7.Tok = at == 3 ? .box("n", cells: max(2, "\(P.n)".count)) : .n(P.n, .chapter)
            M7.row(&rec, "r1", [n, .w("answers")], x: Self.RX, line: 1)
        }
        if at >= 5 { M7.row(&rec, "r2", [.w("most at"), .n(P.peak, .chapter)], x: Self.RX, line: 4) }
        if at >= 6 { M7.row(&rec, "r3", [.n(P.least, .chapter), .w("to"), .n(P.most, .chapter)], x: Self.RX, line: 7) }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    func hands(_ s: PaperState) -> Hands? {
        let g = G(s.numbers), P = g.P, at = stage(s)
        switch at {
        case 2:
            let order = D8.order(s, n: P.n), base = s.hand.filter { $0.key.hasPrefix("p") }
            /// Card j put on number u, let go at `l` (its corner).
            func put(_ j: Int, _ u: Int, from l: CGPoint) -> HandMove {
                if P.data[j] != u {
                    let h = base.merging(["bad": Double(j)]) { $1 }
                    return HandMove(hand: h, missHand: h, set: [("c", Double(j)), ("u", Double(u))], check: true)
                }
                let r = D8.placing(j, s.hand, placed: order), keep = r.keep
                var h = r.hand
                h["lx"] = l.x; h["ly"] = l.y
                if h.keys.filter({ $0.hasPrefix("p") }).count == P.n { return HandMove(hand: h, missHand: h, set: [("c", -1), ("u", 0)], keep: keep, check: true) }
                return HandMove(hand: h, missHand: h, keep: keep)
            }
            return Hands(tap: { q in
                guard g.onLine(q), let j = (0..<P.n).first(where: { order[$0] == nil }) else { return nil }
                return put(j, g.val(q), from: D8.card(j, y0: g.CY))
            }, grab: { q in
                guard let j = D8.cardAt(q, n: P.n, y0: g.CY, placed: { order[$0] != nil }) else { return nil }
                let c = D8.card(j, y0: g.CY)
                return base.merging(["grab": 1, "j": Double(j), "dx": q.x - c.x, "dy": q.y - c.y, "hx": c.x, "hy": c.y, "over": -1]) { $1 }
            }, drag: { q, h in
                var h = h
                h["hx"] = q.x - (h["dx"] ?? 0); h["hy"] = q.y - (h["dy"] ?? 0)
                h["over"] = g.onLine(q) ? Double(g.val(q)) : -1
                return h
            }, release: { h in
                guard let j = h["j"].map({ Int($0) }), let u = h["over"].map({ Int($0) }), u >= 0 else { return HandMove(hand: base, missHand: base) }
                return put(j, u, from: CGPoint(x: h["hx"] ?? 0, y: h["hy"] ?? 0))
            })
        case 4:
            return Hands(tap: { q in
                guard g.onLine(q) else { return nil }
                return HandMove(hand: [:], missHand: [:], set: [("x", Double(g.val(q)))], check: true)
            })
        case 5:
            return Hands(grab: { q in
                guard q.x > G.x(0) - 2, q.x < G.x(10) + 2, q.y > g.LY - 1.5, q.y < g.BR + 1.5 else { return nil }
                let u = Double(g.val(q)); return ["grab": 1, "a": u, "b": u]
            }, drag: { q, h in var h = h; h["b"] = Double(g.val(q)); return h },
            release: { h in
                let a = h["a"] ?? 0, b = h["b"] ?? 0
                if a == b { return HandMove(hand: [:], missHand: [:]) }
                return HandMove(hand: [:], missHand: [:], set: [("a", min(a, b)), ("b", max(a, b))], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let g = G(s.numbers), P = g.P
        switch stage(s) {
        case 2:
            // the next cards tapped onto their numbers, one after another
            let order = D8.order(s, n: P.n)
            return (0..<P.n).filter { order[$0] == nil }.map { j in .tap(.picture(CGPoint(x: G.x(P.data[j]), y: g.LY - 1))) }
        case 4: return [.tap(.picture(CGPoint(x: G.x(P.peak), y: g.LY - 1)))]
        case 5: return [.drag(from: CGPoint(x: G.x(P.least), y: g.LY + 1), to: CGPoint(x: G.x(P.most), y: g.LY + 1))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = DotPlot6.Parts(s.numbers)
        switch stage(s) {
        case 2:
            let j = (0..<P.n).first { D8.order(s, n: P.n)[$0] == nil } ?? 0, u = P.data[j] == 10 ? 9 : P.data[j] + 1
            let h = s.hand.filter { $0.key.hasPrefix("p") }.merging(["bad": Double(j)]) { $1 }
            return HandMove(hand: h, missHand: h, set: [("c", Double(j)), ("u", Double(u))], check: true)
        case 4: return HandMove(hand: [:], missHand: [:], set: [("x", Double(P.counts.indices.first { P.counts[$0] > 0 && $0 != P.peak } ?? 0))], check: true)
        case 5: return HandMove(hand: [:], missHand: [:], set: [("a", Double(min(P.least + 1, P.most - 1))), ("b", Double(P.most))], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? { stage(s) == 3 ? ["n": Double(DotPlot6.Parts(s.numbers).n - 1)] : nil }
}
