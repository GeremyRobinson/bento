import SwiftUI

/// Find the mean on the paper, as in the preview (design/prototype/grade6-ch8.html, dMean): the numbers as bars from the
/// picture's top, 4 squares wide, 2 apart, a square for each one, each number written tight under its bar. Level the
/// bars: drag from inside a bar and the squares above the finger come along (following it), let go on another bar and
/// they stack on it (gliding there); every bar's height reads beside them ("6, 6, 7, 5"). Level, they shade, and the
/// record is written: `(3 + 5 + 7 + 9) ÷ 4 = [24] ÷ [4] = 6`, on two lines when it's long.
///
/// Hand keys: "h<j>" (bar j's height now), "grab", "j" (the bar taken from), "k" (how many squares held), "x", "y"
/// (the finger), "off" (from the finger to the held squares' bottom), "lj", "lx", "ly" (the bar the last ones went onto,
/// and where they were let go).
@MainActor
struct MeanLesson: PaperLesson {
    var liveKeys: Set<String> { ["grab", "x", "y"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    @MainActor struct G {
        let P: Mean6.Parts
        init(_ n: Numbers) { P = Mean6.Parts(n) }
        var BY: Double { 1 + Double(P.tallest) }
        var PW: Double { 6 * Double(P.n) - 2 }
        var room: Double { max(PW + 16, 46) }
        var lead: [M7.Tok] { D8.shared(P.v, by: P.n) }
        func tail(_ T: M7.Tok, _ c: M7.Tok, _ M: M7.Tok) -> [M7.Tok] { [.op("="), T, .op("÷"), c, .op("="), M] }
        var two: Bool { D8.split(lead, tail(.box("T", cells: max(2, "\(P.total)".count)), .box("c", cells: 1), .n(P.mean)), room: room) }
    }

    func recordRow(_ n: Numbers) -> Double? { G(n).BY + 4 }
    func keysFocus(_ s: PaperState) -> CGRect? {
        let g = G(s.numbers)
        return stage(s) == 2 || stage(s) == 3 ? CGRect(x: -1, y: g.BY - 1, width: g.PW + 2, height: 4) : nil
    }

    private func heights(_ s: PaperState, _ P: Mean6.Parts) -> [Int] {
        stage(s) >= 2 ? Array(repeating: P.mean, count: P.n) : P.v.indices.map { Int((s.h("h\($0)") ?? Double(P.v[$0])).rounded()) }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let g = G(s.numbers), P = g.P, at = stage(s), BY = g.BY
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let h = heights(s, P)
        let held = at == 1 && s.grabbed ? s.h("j").map { Int($0) } : nil, k = Int((s.h("k") ?? 0).rounded())
        pic.rule("base", from: -1, to: g.PW + 1, row: BY)
        for j in 0..<P.n {
            let hj = held == j ? h[j] - k : h[j]
            // the squares that just went onto this bar glide from where they were let go
            if at == 1, s.h("lj").map({ Int($0) }) == j, let lx = s.h("lx"), let ly = s.h("ly") {
                let moved = Int((s.h("lk") ?? 0).rounded())
                D8.glide(&pic) { pen in for u in max(0, hj - moved)..<hj { D8.square(&pen, "b\(j)_\(u)", x: lx, y: ly - Double(u - (hj - moved)) - 1, w: 4, h: 1) } }
            }
            D8.bar(&pic, "b\(j)", x: D8.barX(j), base: BY, w: 4, h: hj, at >= 2 ? D8.strong : D8.fill)
            pic.sketch.from = [:]
            D8.under(&pic, "n\(j)", "\(P.v[j])", x: D8.barX(j), base: BY)
        }
        // the held squares, following the finger
        if let j = held, let x = s.h("x"), let y = s.h("y") {
            let left = (x - 2).rounded(), bottom = (y + (s.h("off") ?? 0)).rounded()
            for u in 0..<k { D8.square(&live, "hd\(u)", x: left, y: bottom - Double(u) - 1, w: 4, h: 1, D8.strong) }
            _ = j
        }
        // every bar's height now, beside them
        if at == 1 {
            let now = h.indices.map { held == $0 ? h[$0] - k : h[$0] }.map(String.init).joined(separator: ", ")
            if held != nil { D8.readout(&live, now, x: g.PW + 3, y: 2, held: true) }
            else { pic.word("rd\(now)", now, at: g.PW + 3, 2, D8.lit, anchor: UnitPoint(x: 0, y: 0.5)) }
        }

        // hints: the short bars ringed, then the level they all reach, dashed
        if at == 1 && s.on("ring") {
            for j in 0..<P.n where h[j] < P.mean { R6.ring(&pic, "ring\(j)", x: D8.barX(j), y: BY - Double(P.mean), w: 4, h: Double(P.mean)) }
        }
        if at == 1 && s.on("spot") { pic.line("spot", [(-1, BY - Double(P.mean)), (g.PW + 1, BY - Double(P.mean))], .chapter, dashed: true) }
        if at == 2 && s.on("ring") { R6.ring(&pic, "ring", x: -1, y: BY + 0.3, w: g.PW + 2, h: 2) }
        if at == 2 && s.on("spot") { pic.circle("spot", at: D8.barX(P.n - 1) + 2, BY + 1.2, radius: 1.5, .chapter, dashed: true) }
        if at == 3 && s.on("ring") { R6.ring(&pic, "ring", x: -1, y: BY - Double(P.mean), w: g.PW + 2, h: Double(P.mean)) }
        if at == 3 && s.on("spot") { for j in 0..<P.n { pic.word("cnt\(j)", "\(j + 1)", at: D8.barX(j) + 2, BY - 0.5, D8.small.colour(.ink)) } }

        // the record
        if at >= 2 {
            let T: M7.Tok = at == 2 ? .box("T", cells: max(2, "\(P.total)".count)) : .n(P.total, at >= 4 ? .chapter : .ink)
            let c: M7.Tok = at == 3 ? .box("c", cells: 1) : at >= 4 ? .n(P.n, .chapter) : .gap(Record.boxWidth(cells: 1, commas: true))
            let M: M7.Tok = .n(P.mean, .chapter)
            // keys up, the line being typed goes on a row of its own, so it and what it's read from show at 75%
            let two = g.two || (s.keys && (at == 2 || at == 3))
            if two { M7.row(&rec, "r1", g.lead, x: 0, line: 1); M7.row(&rec, "r2", g.tail(T, c, M), x: 0, line: 4) }
            else { M7.row(&rec, "r", g.lead + g.tail(T, c, M), x: 0, line: 1) }
            // the count's box waits, faint, while the total is written
            if at == 2 { D8.waiting(&rec, "cw", two ? g.tail(T, c, M) : g.lead + g.tail(T, c, M), (two ? 0 : g.lead.count) + 3, x: 0, line: two ? 4 : 1) }
        }
        let ext = pic.R(-1, 0, g.PW + 16, BY + 3)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    func hands(_ s: PaperState) -> Hands? {
        let g = G(s.numbers), P = g.P, BY = g.BY
        guard stage(s) == 1 else { return nil }
        let h = heights(s, P)
        let base: Numbers = Dictionary(uniqueKeysWithValues: h.indices.map { ("h\($0)", Double(h[$0])) })
        return Hands(grab: { q in
            guard let j = D8.barAt(q, n: P.n) else { return nil }
            let u = Int((BY - q.y).rounded(.down))
            guard u >= 0, u < h[j] else { return nil }
            return base.merging(["grab": 1, "j": Double(j), "k": Double(h[j] - u), "off": BY - Double(u) - q.y, "x": q.x, "y": q.y]) { $1 }
        }, drag: { q, hd in var hd = hd; hd["x"] = q.x; hd["y"] = q.y; return hd },
        release: { hd in
            guard let j = hd["j"].map({ Int($0) }), let x = hd["x"], let y = hd["y"] else { return HandMove(hand: base, missHand: base) }
            let k = Int((hd["k"] ?? 0).rounded())
            guard let m = D8.barAt(CGPoint(x: x, y: y), n: P.n, margin: 1), m != j else { return HandMove(hand: base, missHand: base) }
            if h[m] + k > P.tallest { return HandMove(hand: base, missHand: base, set: [("m", -1)], check: true) }
            var out = base
            out["h\(m)"] = Double(h[m] + k); out["h\(j)"] = Double(h[j] - k)
            out["lj"] = Double(m); out["lk"] = Double(k); out["lx"] = (x - 2).rounded(); out["ly"] = (y + (hd["off"] ?? 0)).rounded()
            let level = (0..<P.n).allSatisfy { Int(out["h\($0)"] ?? 0) == P.mean }
            return HandMove(hand: out, missHand: out, set: level ? [("m", Double(P.mean))] : [], check: level)
        })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let g = G(s.numbers), P = g.P, BY = g.BY
        guard stage(s) == 1 else { return [] }
        // the tallest's extra onto the shortest, until every bar is level
        var h = heights(s, P), out: [GhostMove] = []
        for _ in 0..<12 {
            guard let i = h.indices.max(by: { h[$0] < h[$1] }), let j = h.indices.min(by: { h[$0] < h[$1] }), h[i] > P.mean else { break }
            let k = min(h[i] - P.mean, P.mean - h[j])
            out.append(.drag(from: CGPoint(x: D8.barX(i) + 2, y: BY - Double(h[i] - k) - 0.5), to: CGPoint(x: D8.barX(j) + 2, y: BY - Double(h[j]) - 0.5)))
            h[i] -= k; h[j] += k
        }
        return out
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Mean6.Parts(s.numbers)
        guard stage(s) == 1 else { return nil }
        let h = heights(s, P), base: Numbers = Dictionary(uniqueKeysWithValues: h.indices.map { ("h\($0)", Double(h[$0])) })
        return HandMove(hand: base, missHand: base, set: [("m", -1)], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Mean6.Parts(s.numbers)
        switch stage(s) {
        case 2: return ["T": Double(P.total - (P.v.last ?? 0))]
        case 3: return ["c": Double(P.n - 1)]
        default: return nil
        }
    }
}
