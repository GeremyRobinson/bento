import SwiftUI

/// Mean absolute deviation on the paper, as in the preview (design/prototype/grade6-ch8.html, dMad): Find the mean's bars
/// and a level line across them with a handle at its end. Drag the line ("5 above, 3 below": the squares over it and
/// the gaps under it) and let go where they balance (the mean). Tap each bar to measure it from the line: the part over
/// it shades, the gap under it dashes, its distance written over it ("3 away, 7 in all"). Then the distances slide off
/// the bars into a row of their own (2 squares wide, 3 apart, beside the bars), rest a beat, and level out (Find the
/// mean's levelling); the record: `(3 + 1 + 0 + 2 + 4 + 2) ÷ 6 = [12] ÷ 6 = [2]`, on two lines when it's long.
///
/// Hand keys: "L" (the line's level, while it's dragged and after a miss), "grab", "t" (the bars measured, bits),
/// "last" (the bar measured last).
@MainActor
struct MadLesson: PaperLesson {
    var liveKeys: Set<String> { ["grab", "L"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    @MainActor struct G {
        let P: Mad6.Parts
        init(_ n: Numbers) { P = Mad6.Parts(n) }
        var BY: Double { 1 + Double(P.tallest) }
        var PW: Double { 6 * Double(P.n) - 2 }
        /// The distances' row starts on the block line past the bars and their handle.
        var DX: Double { ((PW + 4) / 5).rounded(.up) * 5 }
        /// The row's columns: 3 squares apart, or 2 (touching) when that keeps the problem 73 squares wide or less (75%).
        var step: Double { DX + 3 * Double(P.n) <= 71 ? 3 : 2 }
        var W: Double { max(DX + step * Double(P.n), PW + 14, 44) }
        var lead: [M7.Tok] { D8.shared(P.d, by: P.n) }
        func tail(_ T: M7.Tok, _ A: M7.Tok) -> [M7.Tok] { [.op("="), T, .op("÷"), .n(P.n), .op("="), A] }
        var two: Bool { D8.split(lead, tail(.box("T", cells: max(2, "\(P.dTotal)".count)), .box("A", cells: 1)), room: W) }
        func dx(_ j: Int) -> Double { DX + step * Double(j) }
    }

    func recordRow(_ n: Numbers) -> Double? { G(n).BY + 4 }
    private func bits(_ s: PaperState) -> Int { Int((s.h("t") ?? 0).rounded()) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let g = G(s.numbers), P = g.P, at = stage(s), BY = g.BY, M = P.mean, n = P.n
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        pic.rule("base", from: -1, to: g.PW + 1, row: BY)
        for j in 0..<n { D8.bar(&pic, "b\(j)", x: D8.barX(j), base: BY, w: 4, h: P.v[j]); D8.under(&pic, "n\(j)", "\(P.v[j])", x: D8.barX(j), base: BY) }
        // what each measured bar is from the line: the part over it shaded, the gap under it dashed, its distance over it
        let measured = at == 2 ? bits(s) : at > 2 ? (1 << n) - 1 : 0
        for j in 0..<n where measured & (1 << j) != 0 {
            let x = D8.barX(j), v = P.v[j]
            if v > M { pic.fill("up\(j)", col: x, row: BY - Double(v), w: 4, h: Double(v - M), D8.strong) }
            if v < M { pic.sketch.box("gp\(j)", pic.R(x, BY - Double(M), 4, Double(M - v)), .chapter, width: Sketch.stroke, dashed: true) }
            pic.label("dl\(j)", "\(P.d[j])", D8.lit, .above, edge: BY - Double(max(v, M)), along: x + 2)
        }
        // the level line: the hand's while it's found, then on the mean
        if at <= 1 {
            let L = Int((s.h("L") ?? Double(P.l0)).rounded()), (a, b) = P.ab(L), y = BY - Double(L)
            var pen = at == 1 ? live : pic
            pen.line("lv", [(-1, y), (g.PW + 1, y)], .chapter)
            if at == 1 {
                R6.handle(&pen, "lh", g.PW + 1, y, held: s.grabbed)
                D8.readout(&pen, "\(a) above, \(b) below", x: g.PW + 2.5, y: y, held: s.grabbed)
                live = pen
            } else { pic = pen }
        } else { pic.line("lv", [(-1, BY - Double(M)), (g.PW + 1, BY - Double(M))], .chapter) }
        if at == 2, let j = s.h("last").map({ Int($0) }) {
            let all = (0..<n).filter { measured & (1 << $0) != 0 }.reduce(0) { $0 + P.d[$1] }, rd = "\(P.d[j]) away, \(all) in all"
            pic.word("rd\(rd)", rd, at: g.PW + 2.5, BY - Double(M), D8.lit, anchor: UnitPoint(x: 0, y: 0.5))
        }

        // the distances in a row of their own: they slide off the bars, rest a beat, then level out
        if at >= 3 {
            pic.rule("dbase", from: g.DX - 1, to: g.dx(n - 1) + 3, row: BY)
            var sources: [(Int, Int)] = [], targets: [(Int, Int)] = []
            for j in 0..<n { for u in 0..<P.d[j] where u >= P.mad { sources.append((j, u)) } }
            for j in 0..<n { for u in 0..<P.mad where u >= P.d[j] { targets.append((j, u)) } }
            let moved = Dictionary(uniqueKeysWithValues: zip(targets.map { "\($0.0)_\($0.1)" }, sources))
            for j in 0..<n {
                for u in 0..<P.mad {
                    let src = moved["\(j)_\(u)"] ?? (j, u), sj = src.0, su = src.1, id = "dd\(j)_\(u)"
                    if at == 3 {
                        let by = P.v[sj] > M ? BY - Double(M) - Double(su) - 1 : BY - Double(P.v[sj]) - Double(su) - 1
                        D8.glide(&pic) { D8.square(&$0, id, x: D8.barX(sj), y: by, w: 4, h: 1, D8.strong) }
                        D8.via(&pic) { D8.square(&$0, id, x: g.dx(sj), y: BY - Double(su) - 1, w: 2, h: 1, D8.strong) }
                        pic.sketch.delay = 0.4
                    }
                    D8.square(&pic, id, x: g.dx(j), y: BY - Double(u) - 1, w: 2, h: 1, D8.strong)
                    pic.sketch.from = [:]; pic.sketch.via = [:]; pic.sketch.delay = 0
                }
                pic.label("dn\(j)", "\(P.d[j])", D8.small, .below, edge: BY, along: g.dx(j) + 1)
            }
        }

        // hints: a first miss rings the general area, a second the exact spot (call of 3 Nov)
        let top = Double(max(P.mad, P.d.max() ?? 0))
        switch at {
        case 1:
            if s.on("ring") { R6.ring(&pic, "ring", x: -1, y: BY - Double(max(M, P.l0)) - 1, w: g.PW + 2, h: Double(abs(M - P.l0)) + 2) }
            if s.on("spot") { pic.line("spot", [(-1, BY - Double(M)), (g.PW + 1, BY - Double(M))], .chapter, dashed: true) }
        case 3:
            if s.on("ring") { R6.ring(&pic, "ring", x: g.DX - 1, y: BY - top, w: g.step * Double(n) + 1, h: top + 2) }
            if s.on("spot") { for j in 0..<n where P.v[j] < M { pic.circle("spot\(j)", at: g.dx(j) + 1, BY + 1.2, radius: 1.2, .chapter, dashed: true) } }
        case 4:
            if s.on("ring") { R6.ring(&pic, "ring", x: g.DX - 1, y: BY - top, w: g.step * Double(n) + 1, h: top) }
            if s.on("spot") { pic.line("spot", [(g.DX - 1, BY - Double(P.mad)), (g.dx(n - 1) + 3, BY - Double(P.mad))], .chapter, dashed: true) }
        default: break
        }

        // the record
        if at >= 3 {
            let T: M7.Tok = at == 3 ? .box("T", cells: max(2, "\(P.dTotal)".count)) : .n(P.dTotal, at >= 5 ? .chapter : .ink)
            let A: M7.Tok = at == 4 ? .box("A", cells: max(1, "\(P.mad)".count)) : at >= 5 ? .n(P.mad, .chapter) : .gap(Record.boxWidth(cells: 1, commas: true))
            // keys up, the line being typed goes on a row of its own, so it and what it's read from show at 75%
            let two = g.two || (s.keys && (at == 3 || at == 4))
            if two { M7.row(&rec, "r1", g.lead, x: 0, line: 1); M7.row(&rec, "r2", g.tail(T, A), x: 0, line: 4) }
            else { M7.row(&rec, "r", g.lead + g.tail(T, A), x: 0, line: 1) }
            if at == 3 { D8.waiting(&rec, "aw", two ? g.tail(T, A) : g.lead + g.tail(T, A), (two ? 0 : g.lead.count) + 5, x: 0, line: two ? 4 : 1) }
        }
        let ext = pic.R(-1, 0, g.W + 2, BY + 3)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    func hands(_ s: PaperState) -> Hands? {
        let g = G(s.numbers), P = g.P, BY = g.BY
        switch stage(s) {
        case 1:
            let L = s.h("L") ?? Double(P.l0)
            return Hands(grab: { q in
                abs(q.y - (BY - L)) < 1.4 && q.x > -1.5 && q.x < g.PW + 3 ? ["grab": 1, "L": L, "from": L] : nil
            }, drag: { q, h in var h = h; h["L"] = Double(min(P.tallest, max(0, Int((BY - q.y).rounded())))); return h },
            release: { h in
                let l = h["L"] ?? L
                if l == h["from"] { return HandMove(hand: ["L": l], missHand: ["L": l]) }
                return HandMove(hand: ["L": l], missHand: ["L": l], set: [("l", l)], check: true)
            })
        case 2:
            let b = bits(s)
            return Hands(tap: { q in
                guard let j = D8.barAt(q, n: P.n, margin: 0.5), q.y > 0, q.y < BY + 3, b & (1 << j) == 0 else { return nil }
                let nb = b | (1 << j), h: Numbers = ["t": Double(nb), "last": Double(j)]
                let all = nb == (1 << P.n) - 1
                return HandMove(hand: h, missHand: h, set: all ? [("t", Double(P.n))] : [], check: all)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let g = G(s.numbers), P = g.P, BY = g.BY
        switch stage(s) {
        case 1:
            let L = s.h("L") ?? Double(P.l0)
            return [.drag(from: CGPoint(x: g.PW + 1, y: BY - L), to: CGPoint(x: g.PW + 1, y: BY - Double(P.mean)))]
        case 2:
            let b = bits(s)
            return (0..<P.n).filter { b & (1 << $0) == 0 }.map { .tap(.picture(CGPoint(x: D8.barX($0) + 2, y: BY - 0.5))) }
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Mad6.Parts(s.numbers)
        guard stage(s) == 1 else { return nil }
        let l = Double(P.l0)
        return HandMove(hand: ["L": l], missHand: ["L": l], set: [("l", l)], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Mad6.Parts(s.numbers)
        switch stage(s) {
        case 3: return ["T": P.v.contains { $0 < P.mean } ? 0 : Double(P.dTotal - 1)]
        case 4: return ["A": Double(P.dTotal)]
        default: return nil
        }
    }
}
