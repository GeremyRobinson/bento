import SwiftUI

/// Line plots with fractions on the paper, as in the preview (design/prototype/grade4-ch7.html): two inches are 48
/// squares, so an inch is 24, a fourth 6 and an eighth 3. The line, its ticks (longer at halves and whole inches, which
/// are named), the X's stacked over it (each 2 × 2), its title over it. The first three problems make the plot: the
/// lengths wait on cards; tap the line where each of the first three goes (an X stacks there and its card is crossed
/// out), and the rest glide down from their cards. Then the question: tap the longest and the shortest (their stacks
/// light), hop from one to the other under the line, a piece at a time, and type the difference; or tap the stack asked
/// about and type its total; or tap each X longer than a length (they light and count), or None.
@MainActor
struct LinePlotLesson: PaperLesson {
    /// The title's row; the cards' first column and row (in three columns beside the plot, so it shows at 75%).
    static let titleRow = 1.0, cardX = 50.0, cardY = 3.0
    var liveKeys: Set<String> { ["len"] }

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    @MainActor struct Q {
        let p: LinePlot4.Parts
        var sp: Double { 48 / Double(2 * p.d) }
        func x(_ u: Int) -> Double { Double(u - p.lo) * sp }
        /// The stacks' top row and the line's row.
        var top: Double { 3 }
        var ly: Double { top + 2 * Double(p.tallest) + 1 }
        /// X i's middle.
        func spot(_ i: Int) -> CGPoint { CGPoint(x: x(p.data[i]), y: ly - 2 * Double(p.level[i]) - 1) }
        func cardAt(_ i: Int) -> CGPoint { CGPoint(x: LinePlotLesson.cardX + 5 * Double(i % 3), y: LinePlotLesson.cardY + 5 * Double(i / 3)) }
        func card(_ i: Int) -> CGPoint { let c = cardAt(i); return CGPoint(x: c.x + 2, y: c.y + 2) }
        /// The tick nearest a place on the line, if it's within half a step.
        func tick(_ c: CGPoint) -> Int? {
            let u = p.lo + Int((c.x / sp).rounded())
            return u >= p.lo && u <= p.top && abs(c.x - x(u)) <= sp / 2 ? u : nil
        }
    }

    private func mix(_ v: Int, _ d: Int, _ c: Sketch.Colour = .ink) -> [M7.Tok] {
        let m = LinePlot4.mixed(v, d)
        return (m.w > 0 || m.n == 0 ? [.n(m.w, c)] : []) + (m.n > 0 ? [.f(m.n, m.d, c)] : [])
    }
    private func bits(_ s: PaperState) -> Int { Int((s.h("lit") ?? 0).rounded()) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = Q(p: LinePlot4.Parts(s.numbers)), p = q.p, at = stage(s), d = p.d, ly = q.ly, th = p.th
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)

        pic.word("title", th.title, at: 0, Self.titleRow, Record.words, anchor: UnitPoint(x: 0, y: 0.5))
        // the line: a tick each fourth or eighth, longer at halves and whole inches, which are named
        pic.rule("pl", from: 0, to: 48, row: ly)
        var ticks: [(CGPoint, CGPoint)] = [], faint: [(CGPoint, CGPoint)] = []
        for u in p.lo...p.top {
            let whole = u % d == 0, half = (2 * u) % d == 0, x = q.x(u)
            let seg = (pic.P(x, ly), pic.P(x, ly + (whole ? 1.2 : half ? 0.9 : 0.5)))
            if whole || half { ticks.append(seg); pic.label("pn\(u)", p.said(u), small, .below, edge: ly + 1.2, along: x) } else { faint.append(seg) }
        }
        pic.sketch.segments("ptk", ticks, .ink, width: Sketch.stroke)
        pic.sketch.segments("ptf", faint, .ink3, width: Sketch.stroke)

        // the cards waiting with the lengths (making the plot): the one to place now in ink, crossed out once placed
        let placed = at == 0 ? 0 : at == 1 ? Int((s.h("placed") ?? 0).rounded()) : p.data.count
        if at <= 1 && p.make {
            for (i, u) in p.data.enumerated() {
                let on = i == placed && at == 1, gone = i < placed, c = q.cardAt(i), x0 = c.x, y0 = c.y
                pic.sketch.box("cd\(i)\(on)", pic.R(x0, y0, 4, 4), on ? .ink : .ink3, width: Sketch.stroke)
                pic.word("cv\(i)\(gone)", p.said(u), at: x0 + 2, y0 + 2, Sketch.Words(size: Sketch.small, weight: .medium, colour: gone ? .ink3 : .ink))
                if gone { pic.line("cx\(i)", [(x0 + 0.5, y0 + 3.5), (x0 + 3.5, y0 + 0.5)], .ink3) }
            }
        }

        // which X's are lit: the stacks tapped, the longer ones found
        var lit = Set<Int>()
        for (i, u) in p.data.enumerated() {
            switch p.ask {
            case 0: if (at >= 3 && u == p.hi) || (at >= 4 && u == p.low) { lit.insert(i) }
            case 1: if at >= 7 && u == p.v { lit.insert(i) }
            default: if (at == 6 && bits(s) & (1 << i) != 0) || (at >= 8 && u > p.v) { lit.insert(i) }
            }
        }
        // the X's: the first three where the hand put them; the rest glide down from their cards
        let drop = p.make && s.index == 2
        for i in 0..<min(placed, p.data.count) {
            let c = q.spot(i), on = lit.contains(i), col: Sketch.Colour = on ? .chapter : .ink
            if on { pic.fill("xl\(i)", col: c.x - 1, row: c.y - 1, w: 2, h: 2, .tint(0.4)) }
            if drop && i >= 3 {
                let o = q.card(i)
                var was = GridPen()
                was.line("xa\(i)\(on)", [(o.x - 0.65, o.y - 0.65), (o.x + 0.65, o.y + 0.65)], col)
                was.line("xb\(i)\(on)", [(o.x - 0.65, o.y + 0.65), (o.x + 0.65, o.y - 0.65)], col)
                for it in was.sketch.items { pic.sketch.from[it.id] = it.kind }
                pic.sketch.delay = 0.16 * Double(i - 3)
            }
            pic.line("xa\(i)\(on)", [(c.x - 0.65, c.y - 0.65), (c.x + 0.65, c.y + 0.65)], col)
            pic.line("xb\(i)\(on)", [(c.x - 0.65, c.y + 0.65), (c.x + 0.65, c.y - 0.65)], col)
            pic.sketch.from = [:]; pic.sketch.delay = 0
        }
        if p.ask == 2 && at >= 6 { pic.line("vmark", [(q.x(p.v), ly - 2 * Double(p.nAt) - 1), (q.x(p.v), ly)], .ink2, dashed: true) }

        // the hop from the shortest to the longest under the line, a piece at a time
        if p.ask == 0 {
            let len = at == 4 ? Int((s.h("len") ?? 0).rounded()) : at >= 7 ? p.hi - p.low : 0
            var pen = at == 4 ? live : pic
            for k in 0..<max(0, len) { pen.hop("hp\(k)", from: q.x(p.low + k), to: q.x(p.low + k + 1), row: ly, height: -0.8) }
            if at == 4 {
                pen.dot("hh", at: q.x(p.low + len), ly, radius: s.grabbed ? 0.75 : 0.55, .ink, over: true)
                if s.grabbed && len > 0 { pen.reads("\(len) \(Fractions4.piece(d, len != 1))") }
                live = pen
            } else { pic = pen }
        }

        // hints: where to look, ringed
        if s.on("ring") {
            let ringAt: Int? = at == 1 && placed < p.data.count ? p.data[placed] : at == 2 || at == 4 ? p.hi : at == 3 ? p.low : at == 5 ? p.v : nil
            if let u = ringAt, s.on("spot") { pic.circle("ring", at: q.x(u), ly, radius: 1.3, .chapter, dashed: true) }
            if at == 6 { M7.ring(&pic, "ring", x: q.x(p.v) + 1, y: ly - 2 * Double(p.tallest), w: 48 - q.x(p.v) - 1, h: 2 * Double(p.tallest)) }
        }

        // the question's line under the plot
        let fin = p.fin
        let ans: [M7.Tok] = at >= 8 ? mix(fin, d, .chapter) : (p.boxes.contains("W") ? [.box("W", cells: 1), .gap(1)] : []) + [.fb("N", "D")]
        let unit: M7.Tok = .w("in", at >= 8 ? .chapter : .ink)
        if p.ask == 0 && at >= 7 { M7.row(&rec, "rec", mix(p.hi, d) + [.op("−")] + mix(p.low, d) + [.op("=")] + ans + [unit], x: 0, line: 2) }
        if p.ask == 1 && at >= 7 { M7.row(&rec, "rec", [.n(p.nAt), .op("×")] + mix(p.v, d) + [.op("=")] + ans + [unit], x: 0, line: 2) }
        if p.ask == 2 && at >= 8 {
            let n = p.longer
            M7.row(&rec, "rec", [.n(n, .chapter), .w("\(n == 1 ? "\(th.one) is" : "\(th.many) are") \(th.more) than")] + mix(p.v, d) + [.w("in")], x: 0, line: 2)
        }
        let extent = pic.R(0, 0, 49, ly + 3)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, actions: at == 6 ? ["None"] : [], extent: extent)
    }

    func recordRow(_ n: Numbers) -> Double? { Q(p: LinePlot4.Parts(n)).ly + 3 }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let q = Q(p: LinePlot4.Parts(s.numbers))
        return stage(s) == 6 ? CGPoint(x: 0, y: q.ly + 4) : nil
    }

    func hands(_ s: PaperState) -> Hands? {
        let q = Q(p: LinePlot4.Parts(s.numbers)), p = q.p, at = stage(s), ly = q.ly
        switch at {
        case 1:
            let placed = Int((s.h("placed") ?? 0).rounded())
            return Hands(tap: { c in
                guard placed < p.data.count, let u = q.tick(c), c.y >= q.top - 1, c.y <= ly + 2.5 else { return nil }
                let want = p.data[placed]
                if u != want { return HandMove(hand: ["placed": Double(placed)], missHand: nil, set: [("k", Double(placed)), ("u", Double(u))], check: true) }
                if placed + 1 >= 3 { return HandMove(hand: ["placed": Double(placed + 1)], missHand: nil, set: [("k", 2), ("u", Double(u))], check: true) }
                return HandMove(hand: ["placed": Double(placed + 1)], missHand: nil)
            })
        case 2, 3, 5:
            return Hands(tap: { c in
                guard let u = q.tick(c), p.count(u) > 0, c.y >= ly - 2 * Double(p.count(u)) - 1.5, c.y <= ly + 2 else { return nil }
                return HandMove(hand: [:], missHand: nil, set: [("u", Double(u))], check: true)
            })
        case 4:
            let len = s.h("len") ?? 0, x0 = q.x(p.low), most = Double(p.top - p.low)
            return Hands(grab: { c in abs(c.x - (x0 + len * q.sp)) < 2 && abs(c.y - ly) < 2.5 ? ["grab": 1, "len": len, "from": len] : nil },
                         drag: { c, h in ["grab": 1, "len": min(most, max(0, ((c.x - x0) / q.sp).rounded())), "from": h["from"] ?? 0] },
                         release: { h in
                             let l2 = h["len"] ?? 0
                             if l2 == 0 || l2 == h["from"] { return HandMove(hand: ["len": l2], missHand: nil) }
                             return HandMove(hand: ["len": l2], missHand: nil, set: [("h", l2)], check: true)
                         })
        case 6:
            let b = bits(s), longer = p.longer
            return Hands(tap: { c in
                guard let i = p.data.indices.first(where: { i in let o = q.spot(i); return abs(c.x - o.x) <= 1.1 && abs(c.y - o.y) <= 1.1 }) else { return nil }
                let u = p.data[i]
                if u <= p.v { return HandMove(hand: ["lit": Double(b)], missHand: nil, set: [("x", Double(u))], check: true) }
                if b & (1 << i) != 0 { return nil }
                let nb = b | (1 << i)
                if nb.nonzeroBitCount == longer { return HandMove(hand: ["lit": Double(nb)], missHand: nil, set: [("x", LinePlot4.allLit)], check: true) }
                return HandMove(hand: ["lit": Double(nb)], missHand: nil)
            }, actions: ["None": { HandMove(hand: ["lit": Double(b)], missHand: nil, set: [("x", -1)], check: true) }])
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = Q(p: LinePlot4.Parts(s.numbers)), p = q.p, ly = q.ly
        func stack(_ u: Int) -> GhostMove { .tap(.picture(CGPoint(x: q.x(u), y: ly - 1))) }
        switch stage(s) {
        case 1:
            let placed = Int((s.h("placed") ?? 0).rounded())
            return (placed..<3).map { i in .tap(.picture(CGPoint(x: q.x(p.data[i]), y: ly - 1))) }
        case 2: return [stack(p.hi)]
        case 3: return [stack(p.low)]
        case 4: return [.drag(from: CGPoint(x: q.x(p.low) + (s.h("len") ?? 0) * q.sp, y: ly), to: CGPoint(x: q.x(p.hi), y: ly))]
        case 5: return [stack(p.v)]
        case 6:
            if p.longer == 0 { return [.tap(.action("None"))] }
            let b = bits(s)
            return p.data.indices.filter { p.data[$0] > p.v && b & (1 << $0) == 0 }.map { .tap(.picture(q.spot($0))) }
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let p = LinePlot4.Parts(s.numbers)
        switch stage(s) {
        case 1: let u = p.data[0] == p.lo + 1 ? p.data[0] + 1 : p.data[0] - 1; return HandMove(hand: [:], missHand: nil, set: [("k", 0), ("u", Double(u))], check: true)
        case 2: return HandMove(hand: [:], missHand: nil, set: [("u", Double(p.data.filter { $0 < p.hi }.max() ?? p.low))], check: true)
        case 3: return HandMove(hand: [:], missHand: nil, set: [("u", Double(p.data.filter { $0 > p.low }.min() ?? p.hi))], check: true)
        case 4: return HandMove(hand: ["len": Double(p.hi - p.low - 1)], missHand: nil, set: [("h", Double(p.hi - p.low - 1))], check: true)
        case 5: return HandMove(hand: [:], missHand: nil, set: [("u", Double(p.data.first { $0 != p.v } ?? p.v))], check: true)
        case 6: return HandMove(hand: [:], missHand: nil, set: [("x", Double(p.v))], check: true)
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let p = LinePlot4.Parts(s.numbers)
        guard stage(s) == 7 else { return nil }
        // the marks counted, not the spaces (or the stack's count as the answer)
        let v = p.ask == 0 ? p.hi - p.low + 1 : (p.nAt - 1) * p.v, m = LinePlot4.mixed(v, p.d)
        var out: [String: Double] = ["N": Double(m.n), "D": Double(m.n == 0 ? p.d : m.d)]
        if p.boxes.contains("W") { out["W"] = Double(m.w) }
        return out
    }
}
