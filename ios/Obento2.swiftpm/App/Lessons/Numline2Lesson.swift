import SwiftUI

/// Lengths on a number line on the paper, as in the preview (design/prototype/grade2-ch4.html, dNumline): one square is one
/// unit of the story, a tape measure on a strong line (a mark every square, longer every 5, numbered every 10); to 50 the
/// line is 0–50, past 50 a square stands for 2 (still 50 squares) and the page says so beside it. The story on the
/// picture's top rows (its numbers lit, said as the problem opens); each length a bar 3 squares tall over the line from 0,
/// a line inside it every ten. Drag a bar's end from 0 (it snaps a square at a time, the length beside the line); hop from
/// its end, tens then ones, in the 2 squares between the lowest bar and the line (the hops written beside the line as they
/// go, `45 − 10 = 35 … 27`); what the hops found striped (cut off: dashed); then the record 3 rows under the line, Check
/// beside it. Hand while a bar is dragged: "grab", "j", "v" (the length now). Kept: "len<j>" a bar let go short or long.
@MainActor
struct Numline2Lesson: PaperLesson {
    var liveKeys: Set<String> { ["v"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    struct Geo {
        let P: Numline2.Parts, R: Int
        var nb: Int { P.bars.count }
        var LY: Double { (Double(2 * R + 2 + 4 * nb) / 5).rounded(.up) * 5 }
        func barY(_ j: Int) -> Double { LY - Double(4 * nb) - 1 + Double(4 * j) }
        var U: Double { Double(P.per) }
        func X(_ v: Int) -> Double { Double(v) / U }
        var ROW: Double { LY + 6 }
        var recRow: Double { P.kind == .part ? ROW + 3 : ROW }
        var hop: Int { P.drags.count }
    }
    private func geo(_ n: Numbers) -> Geo { let P = Numline2.Parts(n); return Geo(P: P, R: A2.storyRows(P.lines, width: 50).count) }
    func told(_ s: PaperState) -> String? { Numline2.Parts(s.numbers).lines.joined(separator: " ") }
    func recordRow(_ n: Numbers) -> Double? { geo(n).ROW }
    private func toks(_ P: Numline2.Parts) -> [M7.Tok] {
        switch P.kind {
        case .join: return [.n(P.a), .op("+"), .n(P.b), .op("=")]
        case .part: return [.t("?", .chapter), .op("=")]
        default: return [.n(P.a), .op("−"), .n(P.b), .op("=")]
        }
    }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let G = geo(s.numbers)
        guard at(s) > G.hop else { return nil }
        let end = M7.width(toks(G.P) + [.box("x", cells: 3), .w(G.P.u)])
        return CGPoint(x: EG2.ceil5(end + 1), y: G.recRow)
    }

    /// A length as a bar 3 squares tall from column x, a line inside it every ten things (counted from `from`); its number
    /// in the widest ten-cell nearest its middle.
    enum Look { case tint, lit, stripe, dash }
    private func bar(_ pen: inout GridPen, _ id: String, x: Double, y: Double, w: Double, _ look: Look, G: Geo, from: Int = 0, n: Int? = nil, nc: Sketch.Colour = .ink) {
        guard w > 0 else { return }
        switch look {
        case .tint: pen.fill(id + "f", col: x, row: y, w: w, h: 3, .tint(0.2))
        case .lit: pen.fill(id + "f", col: x, row: y, w: w, h: 3, .tint(0.4))
        case .stripe: pen.stripes(id + "f", col: x, row: y, w: w, h: 3)
        case .dash: break
        }
        pen.sketch.box("\(id)o\(look == .dash)\(w)", pen.R(x, y, w, 3), look == .dash ? .ink2 : .chapter, width: Sketch.stroke, dashed: look == .dash)
        var cuts = [x]
        if look == .tint || look == .lit {
            var m = from / 10 * 10 + 10
            while G.X(m - from) < w - 0.01 { let lx = x + G.X(m - from); pen.line("\(id)t\(m)", [(lx, y), (lx, y + 3)], .chapter); cuts.append(lx); m += 10 }
        }
        cuts.append(x + w)
        guard let n, w >= 2 else { return }
        let need = Double("\(n)".count) * 0.9 + 0.8, mid = x + w / 2
        var best: Double?
        for i in 0..<(cuts.count - 1) where cuts[i + 1] - cuts[i] >= need {
            let cx = (cuts[i] + cuts[i + 1]) / 2
            if best.map({ abs(cx - mid) < abs($0 - mid) }) ?? true { best = cx }
        }
        pen.word("\(id)n\(n)", "\(n)", at: best ?? mid, y + 1.5, KK.maths.colour(nc))
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let G = geo(s.numbers), P = G.P, st = at(s), LY = G.LY, hopAt = G.hop
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        A2.tell(&pic, P.lines, width: 50)
        // the tape: a mark every square, longer every 5, numbered every 10
        pic.line("tape", [(0, LY), (50, LY)])
        var ticks: [(CGPoint, CGPoint)] = []
        for k in 0...50 { ticks.append((pic.P(Double(k), LY), pic.P(Double(k), LY + (k % 5 == 0 ? 1 : 0.5)))) }
        pic.sketch.segments("tk", ticks, .ink, width: Sketch.stroke)
        for k in stride(from: 0, through: 50, by: 10) { pic.word("tn\(k)", "\(k * P.per)", at: Double(k), LY + 2, LN2.small) }
        if P.per == 2 { pic.word("each", P.scale, at: 52, LY + 2, LN2.small, anchor: UnitPoint(x: 0, y: 0.5)) }
        // the bars
        let dj: Int? = st < hopAt ? P.drags[st] : nil
        let held = s.grabbed && dj != nil
        for (j, br) in P.bars.enumerated() {
            let y = G.barY(j)
            if br.whole { bar(&pic, "b\(j)", x: 0, y: y, w: G.X(br.v), .dash, G: G, n: br.v); continue }
            let k = P.drags.firstIndex(of: j)
            let made = k.map { st > $0 } ?? true
            var v = br.v
            if !made { v = j == dj ? Int(s.run.kept["len\(j)"] ?? 0) : 0 }
            if let lab = br.lab { pic.label("bl\(j)", lab, KK.words, .left, edge: 0, along: y + 1.5) }
            if j == dj && held {
                let hv = Int(s.h("v") ?? 0)
                bar(&live, "b\(j)", x: 0, y: y, w: G.X(hv), .tint, G: G)
                live.sketch.polygon("hd\(j)", [live.P(G.X(hv) + 0.3, y + 0.9), live.P(G.X(hv) + 1.1, y + 1.5), live.P(G.X(hv) + 0.3, y + 2.1)], .chapter)
                if hv > 0 { EG2.readout(&live, "\(hv) \(P.u)", x: 52, y: y + 1.5); live.reads("\(hv) \(P.u)") }
                continue
            }
            if P.kind == .cut && j == 0 && st > hopAt {
                // cutting off: the piece cut off goes dashed
                bar(&pic, "b0", x: 0, y: y, w: G.X(P.ans), .tint, G: G, n: st > hopAt + 1 ? P.ans : nil, nc: .chapter)
                bar(&pic, "b0cut", x: G.X(P.ans), y: y, w: G.X(P.a) - G.X(P.ans), .dash, G: G)
            } else {
                bar(&pic, "b\(j)", x: 0, y: y, w: G.X(v), .tint, G: G, n: made ? br.v : nil)
            }
            if j == dj { pic.sketch.polygon("hd\(j):\(v)", [pic.P(G.X(v) + 0.3, y + 0.9), pic.P(G.X(v) + 1.1, y + 1.5), pic.P(G.X(v) + 0.3, y + 2.1)], .chapter) }
        }
        // what the hops found: the piece added on, or the gap to the longer end
        if st > hopAt && P.kind != .cut {
            let x1 = G.X(min(P.hopFrom, P.hopTo)), x2 = G.X(max(P.hopFrom, P.hopTo))
            bar(&pic, "found", x: x1, y: G.barY(P.hopRow), w: x2 - x1, .stripe, G: G, n: st > hopAt + 1 && P.kind != .join ? P.ans : nil, nc: .chapter)
        }
        // the hops, tens then ones, in the 2 squares over the line
        let c = st == hopAt ? LN2.chain(s, "h") : st > hopAt ? LN2.Chain(f: P.hopFrom, t: P.hopTo) : nil
        if let c {
            LN2.hops(&pic, "hp", c.f, c.t, x0: 0, per: 1 / G.U, row: LY, height: 0.5, big: 10)
            if st == hopAt, c.t != c.f { let ro = Numline2.Parts.readout(from: c.f, to: c.t); EG2.readout(&pic, ro, x: 52, y: LY - 1); if s.grabbed { live.reads(ro) } }
        }
        // hints: a first miss rings the bar (or the bar to hop from), a second the mark it ends on
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        if let dj {
            if ring { KK.hintBox(&pic, "hr", x: 0, y: G.barY(dj), w: 50, h: 3) }
            if spot { pic.circle("sp", at: G.X(P.bars[dj].v), LY, radius: 1, .chapter, dashed: true) }
        } else if st == hopAt {
            if ring { KK.hintBox(&pic, "hr", x: 0, y: G.barY(P.hopRow), w: G.X(P.hopFrom), h: 3) }
            if spot { pic.circle("sp", at: G.X(P.hopTo), LY, radius: 1, .chapter, dashed: true) }
        }
        // the record 3 rows under the line
        if st > hopAt {
            let r0 = P.kind == .part ? 4.0 : 1.0
            if P.kind == .part { M7.row(&rec, "eq1", [.n(P.b), .op("+"), .t("?", .chapter), .op("="), .n(P.a)], x: 0, line: 1) }
            let last: M7.Tok = st > hopAt + 1 ? .n(P.ans, .chapter) : .box("x", cells: 3)
            let e = M7.row(&rec, "rec", toks(P) + [last, .w(P.u)], x: 0, line: r0)
            if st == hopAt + 1 && ring { KK.hintBox(&pic, "hw", x: G.X(min(P.hopFrom, P.hopTo)), y: LY - 1.5, w: abs(G.X(P.hopTo) - G.X(P.hopFrom)), h: 1.5) }
            if st == hopAt + 1 && spot { A1.note(&rec, "spot", "\(P.ans)", x: e + 0.5, y: r0 + 2.5) }
        }
        let wide = 52 + KK.width(Numline2.Parts.readout(from: P.hopFrom, to: P.hopTo), KK.words)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(-1, 0, wide + 1, LY + 3))
    }

    func hands(_ s: PaperState) -> Hands? {
        let G = geo(s.numbers), P = G.P, st = at(s), U = G.U
        let at: (Double) -> Int = { x in max(0, min(50 * P.per, Int((x * U).rounded()))) }
        if st < G.hop {
            let j = P.drags[st], y = G.barY(j)
            return Hands(
                grab: { q in q.y >= y - 0.8 && q.y <= y + 3.8 && q.x >= -0.8 && q.x <= 50.8 ? ["grab": 1, "j": Double(j), "v": Double(at(q.x))] : nil },
                drag: { q, h in var h = h; h["v"] = Double(at(q.x)); return h },
                release: { h in
                    let v = Int(h["v"] ?? 0)
                    guard v > 0 else { return HandMove(hand: [:]) }
                    return HandMove(hand: [:], missHand: [:], set: [("d\(j)", Double(v))], keep: ["len\(j)": Double(v)], check: true)
                })
        }
        guard st == G.hop else { return nil }
        return LN2.hopHands(s, "h", box: "h", band: (G.LY - 2.5)...(G.LY + 2.5), xr: 0...50, near: P.per, at: at,
                            clears: { f, t in P.clears(Len2.code(f, t)) })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let G = geo(s.numbers), P = G.P, st = at(s)
        if st < G.hop {
            let j = P.drags[st], y = G.barY(j) + 1.5
            return [.drag(from: CGPoint(x: 0.5, y: y), to: CGPoint(x: G.X(P.bars[j].v), y: y))]
        }
        guard st == G.hop else { return [] }
        return [.drag(from: CGPoint(x: G.X(P.hopFrom), y: G.LY - 0.5), to: CGPoint(x: G.X(P.hopTo), y: G.LY - 0.5))]
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let G = geo(s.numbers), P = G.P, st = at(s)
        if st < G.hop {
            let j = P.drags[st], v = P.bars[j].v - 1
            return HandMove(hand: [:], missHand: [:], set: [("d\(j)", Double(v))], keep: ["len\(j)": Double(v)], check: true)
        }
        guard st == G.hop else { return nil }
        let s1 = P.hopTo > P.hopFrom ? 1 : -1
        return LN2.hopMove("h", box: "h", from: P.hopFrom, to: P.hopTo + s1)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let G = geo(s.numbers)
        guard at(s) == G.hop + 1 else { return nil }
        return ["x": Double(G.P.slips.first?.0 ?? G.P.ans + 1)]
    }
}
