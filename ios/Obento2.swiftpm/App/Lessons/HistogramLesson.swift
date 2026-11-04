import SwiftUI

/// Histograms on the paper, as in the preview (design/prototype/grade6-ch8.html, dHist): the question over the plot, the
/// counts up the side two squares a count, the axis across under them 0–49 in five stretches of 10 squares, the answers
/// as cards under it. Put each card in its stretch (tap the stretch for the next card, or drag any card in): a square
/// glides off the card and its bar rises a count ("20–29: 4"); tap the stretches the question asks for (they light,
/// their counts add: "4 + 3 = 7") and Check; write how many: `4 + 3 = [7] kids`.
///
/// The picture's squares: the question from row 1, the axis on `oy`, the cards from `oy + 4`, the record beside them.
/// Hand keys: "p<j>" (card j's place in the order), "grab", "j", "hx", "hy", "dx", "dy", "over" (the stretch under it),
/// "lx", "ly" (where the last went down), "bad"; "lit" (the stretches tapped, bits).
@MainActor
struct HistogramLesson: PaperLesson {
    static let ox = 3.0, RX = 45.0
    var liveKeys: Set<String> { ["grab", "hx", "hy", "over"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    @MainActor struct G {
        let P: Histogram6.Parts
        init(_ n: Numbers) { P = Histogram6.Parts(n) }
        var top: Double { 1 + 2 * Double(D8.rows(P.Q.q, width: 56).count) }
        var oy: Double { top + 1 + 2 * Double(P.tallest) }
        var CY: Double { oy + 4 }
        static func sx(_ s: Int) -> Double { ox + 10 * Double(s) }
        func over(_ q: CGPoint) -> Int? { q.x >= ox && q.x < ox + 50 && q.y > top - 1 && q.y < oy + 2.5 ? min(4, max(0, Int((q.x - ox) / 10))) : nil }
        func cardMid(_ j: Int) -> CGPoint { let c = D8.card(j, y0: CY); return CGPoint(x: c.x + 2, y: c.y + 1) }
    }

    func recordRow(_ n: Numbers) -> Double? { G(n).CY + 3 }
    func blocksLeft(_ n: Numbers) -> Double? { Self.RX }
    /// Check for the stretches tapped, where the record will be.
    func blocksAt(_ s: PaperState) -> CGPoint? { stage(s) == 2 ? CGPoint(x: Self.RX, y: G(s.numbers).CY + 3) : nil }
    private func lit(_ s: PaperState) -> Int { Int((s.h("lit") ?? 0).rounded()) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let g = G(s.numbers), P = g.P, at = stage(s), oy = g.oy, ox = Self.ox, SX = G.sx
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let maxc = P.tallest, yTop = oy - 2 * Double(maxc) - 1.5
        D8.question(&pic, P.Q.q, width: 56)
        let held = at == 1 && s.grabbed ? s.h("j").map { Int($0) } : nil, over = held != nil ? s.h("over").map { Int($0) } : nil
        let order: [Int: Int] = at < 1 ? [:] : at == 1 ? D8.order(s, n: P.n) : Dictionary(uniqueKeysWithValues: (0..<P.n).map { ($0, D8.order(s, n: P.n)[$0] ?? 100 + $0) })
        let counts = (0..<5).map { st in order.keys.filter { P.of(P.data[$0]) == st }.count }
        let lastJ = order.max { $0.value < $1.value }?.key
        let litBits = at == 2 ? lit(s) : at >= 3 ? P.want.reduce(0) { $0 | 1 << $1 } : 0
        // the axes: counts up the side (two squares a count), the five stretches across
        pic.line("ay", [(ox, oy), (ox, yTop)]); pic.line("aya", [(ox - 0.8, yTop + 0.8), (ox, yTop), (ox + 0.8, yTop + 0.8)])
        pic.label("yn", P.Q.who, D8.small, .right, edge: ox + 0.5, along: yTop + 0.4)
        pic.sketch.segments("yt", (1...max(1, maxc)).map { k in (pic.P(ox - 0.5, oy - 2 * Double(k)), pic.P(ox, oy - 2 * Double(k))) }, .ink, width: Sketch.stroke)
        for k in 1...max(1, maxc) { pic.label("yl\(k)", "\(k)", D8.small, .left, edge: ox - 0.5, along: oy - 2 * Double(k)) }
        pic.line("ax", [(ox, oy), (ox + 51.5, oy)]); pic.line("axa", [(ox + 50.7, oy - 0.8), (ox + 51.5, oy), (ox + 50.7, oy + 0.8)])
        pic.label("xu", P.Q.unit, D8.small, .right, edge: ox + 51.8, along: oy)
        pic.sketch.segments("xt", (0...5).map { st in (pic.P(SX(st), oy), pic.P(SX(st), oy + 0.5)) }, .ink, width: Sketch.stroke)
        for st in 0..<5 {
            let on = (over == st && held != nil) || litBits & (1 << st) != 0 || (at == 1 && lastJ.map { P.of(P.data[$0]) == st } == true && held == nil)
            if on && held != nil { live.label("xlv\(st)", Histogram6.stretch(st), D8.lit, .below, edge: oy + 0.5, along: SX(st) + 5) }
            else { pic.label("xl\(st)\(on)", Histogram6.stretch(st), on ? D8.lit : D8.small, .below, edge: oy + 0.5, along: SX(st) + 5) }
            // the stretch's bar, a count at a time; the newest glides off its card
            for k in 0..<counts[st] {
                let top = k == counts[st] - 1 && at == 1 && lastJ.map { P.of(P.data[$0]) == st } == true
                if top, let j = lastJ {
                    let f = s.h("lx").map { CGPoint(x: $0, y: s.h("ly") ?? 0) } ?? D8.card(j, y0: g.CY)
                    D8.glide(&pic) { D8.square(&$0, "hb\(st)_\(k)", x: f.x, y: f.y, w: 4, h: 2) }
                }
                D8.square(&pic, "hb\(st)_\(k)", x: SX(st), y: oy - 2 * Double(k) - 2, w: 10, h: 2)
                pic.sketch.from = [:]
            }
            if litBits & (1 << st) != 0 && counts[st] > 0 { pic.fill("hl\(st)", col: SX(st), row: oy - 2 * Double(counts[st]), w: 10, h: 2 * Double(counts[st]), D8.fill) }
        }
        // the cards
        let next = at == 1 ? (0..<P.n).first { order[$0] == nil && $0 != held } : nil
        for j in 0..<P.n where j != held {
            D8.card(&pic, "cd\(j)", at: D8.card(j, y0: g.CY), P.data[j], at > 1 || order[j] != nil ? .done : j == next ? .now : .idle)
        }
        if let j = held { D8.card(&live, "ch", at: CGPoint(x: (s.h("hx") ?? 0).rounded(), y: (s.h("hy") ?? 0).rounded()), P.data[j], .held) }
        // the readout beside the cards
        var rd: String?
        if at == 1 {
            if let o = over, held != nil { rd = "\(Histogram6.stretch(o)): \(counts[o])" }
            else if let j = lastJ { let st = P.of(P.data[j]); rd = "\(Histogram6.stretch(st)): \(counts[st])" }
        }
        if at == 2 {
            let on = (0..<5).filter { litBits & (1 << $0) != 0 }
            if on.count == 1 { rd = "\(Histogram6.stretch(on[0])): \(counts[on[0]])" }
            if on.count > 1 { rd = on.map { "\(counts[$0])" }.joined(separator: " + ") + " = \(on.reduce(0) { $0 + counts[$1] })" }
        }
        if let rd {
            if held != nil { D8.readout(&live, rd, x: Self.RX, y: g.CY + 1, held: true) }
            else { pic.word("rd\(rd)", rd, at: Self.RX, g.CY + 1, D8.lit, anchor: UnitPoint(x: 0, y: 0.5)) }
        }

        // hints: a first miss rings the general area, a second the exact spot (call of 3 Nov)
        if s.on("ring") {
            switch at {
            case 1:
                let j = s.h("bad").map { Int($0) } ?? next ?? 0, st = P.of(P.data[j]), a = max(0, st - 1), b = min(4, st + 1)
                R6.ring(&pic, "ring", x: SX(a), y: oy + 0.5, w: SX(b + 1) - SX(a), h: 1.5)
            case 2: R6.ring(&pic, "ring", x: ox, y: oy + 0.5, w: 50, h: 1.5)
            case 3: for st in P.want { R6.ring(&pic, "ring\(st)", x: SX(st), y: oy - 2 * Double(counts[st]), w: 10, h: 2 * Double(counts[st])) }
            default: break
            }
        }
        if s.on("spot") {
            switch at {
            case 1:
                let j = s.h("bad").map { Int($0) } ?? next ?? 0, st = P.of(P.data[j])
                R6.ring(&pic, "spot", x: SX(st) + 1, y: oy + 0.6, w: 8, h: 1.2)
            case 2: for st in P.want { R6.ring(&pic, "spot\(st)", x: SX(st) + 1, y: oy + 0.6, w: 8, h: 1.2) }
            case 3: for st in P.want { pic.label("sc\(st)", "\(counts[st])", D8.lit, .above, edge: oy - 2 * Double(counts[st]), along: SX(st) + 5) }
            default: break
            }
        }

        // the record beside the cards
        if at >= 3 {
            let a: M7.Tok = at == 3 ? .box("a", cells: max(2, "\(P.answer)".count)) : .n(P.answer, .chapter)
            let lead: [M7.Tok] = P.want.count > 1 ? D8.plus(P.want.map { counts[$0] }) + [.op("=")] : []
            M7.row(&rec, "r", lead + [a, .w(P.Q.who)], x: Self.RX, line: 1)
        }
        let ext = pic.R(-1, 0, 65, g.CY + D8.cardsHeight(P.n) + 1)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, actions: at == 2 ? ["Check"] : [], extent: ext)
    }

    func hands(_ s: PaperState) -> Hands? {
        let g = G(s.numbers), P = g.P, at = stage(s)
        switch at {
        case 1:
            let order = D8.order(s, n: P.n), base = s.hand.filter { $0.key.hasPrefix("p") }
            func put(_ j: Int, _ st: Int, from l: CGPoint) -> HandMove {
                if P.of(P.data[j]) != st {
                    let h = base.merging(["bad": Double(j)]) { $1 }
                    return HandMove(hand: h, missHand: h, set: [("c", Double(j)), ("u", Double(st))], check: true)
                }
                let r = D8.placing(j, s.hand, placed: order)
                var h = r.hand
                h["lx"] = l.x; h["ly"] = l.y
                if h.keys.filter({ $0.hasPrefix("p") }).count == P.n { return HandMove(hand: h, missHand: h, set: [("c", -1), ("u", 0)], keep: r.keep, check: true) }
                return HandMove(hand: h, missHand: h, keep: r.keep)
            }
            return Hands(tap: { q in
                guard let st = g.over(q), let j = (0..<P.n).first(where: { order[$0] == nil }) else { return nil }
                return put(j, st, from: D8.card(j, y0: g.CY))
            }, grab: { q in
                guard let j = D8.cardAt(q, n: P.n, y0: g.CY, placed: { order[$0] != nil }) else { return nil }
                let c = D8.card(j, y0: g.CY)
                return base.merging(["grab": 1, "j": Double(j), "dx": q.x - c.x, "dy": q.y - c.y, "hx": c.x, "hy": c.y, "over": -1]) { $1 }
            }, drag: { q, h in
                var h = h
                h["hx"] = q.x - (h["dx"] ?? 0); h["hy"] = q.y - (h["dy"] ?? 0)
                h["over"] = g.over(q).map(Double.init) ?? -1
                return h
            }, release: { h in
                guard let j = h["j"].map({ Int($0) }), let st = h["over"].map({ Int($0) }), st >= 0 else { return HandMove(hand: base, missHand: base) }
                return put(j, st, from: CGPoint(x: h["hx"] ?? 0, y: h["hy"] ?? 0))
            })
        case 2:
            let bits = lit(s)
            return Hands(tap: { q in
                guard let st = g.over(q) else { return nil }
                return HandMove(hand: ["lit": Double(bits ^ (1 << st))], missHand: nil)
            }, actions: ["Check": { HandMove(hand: ["lit": Double(bits)], missHand: ["lit": Double(bits)], set: [("x", Double(bits))], check: true) }])
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let g = G(s.numbers), P = g.P
        switch stage(s) {
        case 1:
            let order = D8.order(s, n: P.n)
            return (0..<P.n).filter { order[$0] == nil }.map { j in .tap(.picture(CGPoint(x: G.sx(P.of(P.data[j])) + 5, y: g.oy - 1))) }
        case 2:
            let bits = lit(s)
            var m: [GhostMove] = (0..<5).filter { (bits & (1 << $0) != 0) != P.want.contains($0) }.map { .tap(.picture(CGPoint(x: G.sx($0) + 5, y: g.oy - 1))) }
            m.append(.tap(.action("Check")))
            return m
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Histogram6.Parts(s.numbers)
        switch stage(s) {
        case 1:
            let j = (0..<P.n).first { D8.order(s, n: P.n)[$0] == nil } ?? 0, st = P.of(P.data[j]) == 4 ? 3 : P.of(P.data[j]) + 1
            let h = s.hand.filter { $0.key.hasPrefix("p") }.merging(["bad": Double(j)]) { $1 }
            return HandMove(hand: h, missHand: h, set: [("c", Double(j)), ("u", Double(st))], check: true)
        case 2:
            // one stretch too few (or the wrong one)
            let w = P.want, bits = w.count > 1 ? w.dropFirst().reduce(0) { $0 | 1 << $1 } : 1 << ((w.first ?? 0) == 0 ? 1 : 0)
            return HandMove(hand: ["lit": Double(bits)], missHand: ["lit": Double(bits)], set: [("x", Double(bits))], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Histogram6.Parts(s.numbers)
        return stage(s) == 3 ? ["a": Double(P.want.count > 1 && P.want.count != P.answer ? P.want.count : P.answer + 1)] : nil
    }
}
