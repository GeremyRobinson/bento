import SwiftUI

/// Line plots on the paper, as in the preview (design/prototype/grade2-ch5.html, dLinePlot): an inch is a block, as on the
/// ruler. The web's question on the picture's top rows (said as it opens), the title under it, the inch line from lo − 1 to
/// lo + 6 with each X a cell a block wide and 3 squares tall (2 past a stack of 6), stacked over its number. Plot one more:
/// the new pencil and its length at the title row's right, its X past the line's end; drag it above its length, then tap
/// its stack to count it. The tallest stack: tap it. Longer than: tap each X right of 6. Longest take away shortest: hop
/// under the line from the X farthest left to the farthest right. Then the record 3 rows under the line, Check beside it.
/// The fold: the plot drawn on the inch ruler itself (its X's stack on the ruler's top edge), the five things lying under it
/// from 0, each with its X at its end; put each X above its length, then tap the tallest stack.
///
/// Hand while an X is dragged: "grab", "i", "px", "py", "u" (−1: off the line). Kept: "pl<i>" an X placed, "q<n>" the stack
/// the n-th count tapped; the hop's (LN2).
@MainActor
struct LinePlot2Lesson: PaperLesson {
    var liveKeys: Set<String> { ["px", "py", "u"] }
    private func kind(_ s: PaperState) -> LinePlot2.Kind { LinePlot2.Kind(rawValue: Int((s.picture["at"] ?? 0).rounded())) ?? .write }
    @MainActor struct Geo {
        let P: LinePlot2.Parts, R: Int
        var fold: Bool { P.fold }
        var XH: Double { fold ? 2 : P.tallest <= 6 ? 3 : 2 }
        var PX: Double { fold ? 0 : 5 - 5 * Double(P.lo - 1) }
        func X(_ u: Int) -> Double { PX + 5 * Double(u) }
        var lo: Int { fold ? 0 : P.lo - 1 }
        var hi: Int { fold ? 10 : P.lo + 6 }
        var TT: Double { fold ? 1 : Double(2 * R) + 1.5 }
        /// The line (the fold: the ruler's top edge) the X's stand on.
        var LY: Double { fold ? 9 : (TT + 1.5 + XH * Double(P.tallest)).rounded(.up) }
        func thingY(_ i: Int) -> Double { LY + 4 + 3 * Double(i) }
        var ROW: Double { fold ? thingY(4) + 5 : LY + 5 }
        func thingEnd(_ i: Int) -> Double { X(P.data[i]) + (P.past.count > i && P.past[i] ? 1 : 0) }
        /// Where X number i waits: at its thing's end (the fold), or past the line's end.
        func holder(_ i: Int) -> CGPoint { fold ? CGPoint(x: thingEnd(i) + 1, y: thingY(i)) : CGPoint(x: X(hi) + 3, y: TT + 2) }
        func col(_ x: Double) -> Int { max(lo, min(hi, Int(((x - PX) / 5).rounded()))) }
        /// The mark an X let go at (px, py) goes over, or nil off the line.
        func over(_ px: Double, _ py: Double) -> Int? {
            let top = fold ? LY + 0.5 : LY + 1
            return py < top && py > TT + 1 && px > X(lo) - 2.5 && px < X(hi) + 2.5 ? col(px) : nil
        }
    }
    private func geo(_ n: Numbers) -> Geo {
        let P = LinePlot2.Parts(n)
        return Geo(P: P, R: P.question.map { A2.storyRows([$0], width: 50).count } ?? 0)
    }
    func told(_ s: PaperState) -> String? { LinePlot2.Parts(s.numbers).question }
    func recordRow(_ n: Numbers) -> Double? { geo(n).ROW }
    private func toks(_ P: LinePlot2.Parts) -> [M7.Tok] { !P.fold && P.ask == 3 ? [.n(P.hi), .op("−"), .n(P.lw), .op("=")] : [] }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let G = geo(s.numbers), k = kind(s)
        guard k == .write || k == .done else { return nil }
        return CGPoint(x: EG2.ceil5(M7.width(toks(G.P) + [.box("x", cells: 2), .w(G.P.unit)]) + 1), y: G.ROW)
    }

    private func placed(_ s: PaperState, _ G: Geo, _ i: Int) -> Bool {
        let k = kind(s)
        if G.P.toPlace == 0 { return true }
        return k != .place || s.run.kept["pl\(i)"] != nil
    }
    /// The stacks drawn now: each mark's X's, bottom up (ids: "d<i>", the new one "new").
    private func stacks(_ s: PaperState, _ G: Geo) -> [Int: [String]] {
        var out: [Int: [String]] = [:]
        for (i, u) in G.P.data.enumerated() where !G.fold || placed(s, G, i) { out[u, default: []].append("d\(i)") }
        if !G.fold && G.P.ask == 0 && placed(s, G, 0) { out[G.P.v, default: []].append("new") }
        return out
    }
    /// The X's numbered as they were counted.
    private func numbered(_ s: PaperState, _ G: Geo) -> [String: Int] {
        let st = stacks(s, G)
        var used: [Int: Int] = [:], out: [String: Int] = [:], n = 0
        let past = kind(s).rawValue > LinePlot2.Kind.count.rawValue
        if past && G.P.steps.contains(.count) {
            // once counted, every X counted stays numbered, in order
            for u in st.keys.sorted() where G.P.ask == 0 ? u == G.P.v : u > G.P.v { for id in st[u] ?? [] { n += 1; out[id] = n } }
            return out
        }
        while let q = s.run.kept["q\(n)"] {
            let u = Int(q), k = used[u] ?? 0
            if let ids = st[u], k < ids.count { out[ids[k]] = n + 1 }
            used[u] = k + 1; n += 1
        }
        return out
    }

    private func item(_ pen: inout GridPen, _ id: String, _ P: LinePlot2.Parts, x0: Double, x1: Double, y: Double) {
        let one = P.th.one
        if one == "pencil" || one == "ribbon" { LN2.thing(&pen, id, one, x0: x0, x1: x1, y: y); return }
        let K = "\(id)\(one)\(x0):\(x1):\(y)", m = y + 1
        var pts: [CGPoint] = []
        if one == "leaf" {
            for k in 0...12 { let t = Double(k) / 12, u = 1 - t; pts.append(pen.P(u * u * x0 + 2 * u * t * (x0 + x1) / 2 + t * t * x1, u * u * m + 2 * u * t * (y - 0.6) + t * t * m)) }
            for k in 1...12 { let t = Double(k) / 12, u = 1 - t; pts.append(pen.P(u * u * x1 + 2 * u * t * (x0 + x1) / 2 + t * t * x0, u * u * m + 2 * u * t * (y + 2.6) + t * t * m)) }
            pen.sketch.polygon(K + "f", pts, .tint(0.2)); pen.sketch.line(K + "o", pts, .ink, width: Sketch.stroke)
            pen.line(K + "r", [(x0 + 0.5, m), (x1 - 0.8, m)])
        } else {
            let r = 0.6
            for k in 0...8 { let a = -Double.pi / 2 + Double(k) / 8 * .pi; pts.append(pen.P(x1 - r + r * cos(a), m + r * sin(a))) }
            for k in 0...8 { let a = Double.pi / 2 + Double(k) / 8 * .pi; pts.append(pen.P(x0 + r + r * cos(a), m + r * sin(a))) }
            pts.append(pts[0])
            pen.sketch.polygon(K + "f", pts, .tint(0.2)); pen.sketch.line(K + "o", pts, .ink, width: Sketch.stroke)
            var sx = x0 + 1.5, segs: [(CGPoint, CGPoint)] = []
            while sx < x1 - 1 { segs.append((pen.P(sx, y + 0.4), pen.P(sx, y + 1.6))); sx += 1.5 }
            if !segs.isEmpty { pen.sketch.segments(K + "s", segs, .ink3, width: Sketch.stroke) }
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let G = geo(s.numbers), P = G.P, k = kind(s), LY = G.LY, XH = G.XH
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        if let q = P.question { A2.tell(&pic, [q], width: 50) }
        pic.word("title", P.th.title, at: G.fold ? 25 : G.X(P.lo) + 12.5, G.TT, DK2.say)
        let held = s.grabbed && k == .place, hu = held ? Int(s.h("u") ?? -1) : -1
        // the line (or the fold's ruler, under the X's, its marks hanging to the things under it)
        var lit: Set<Int> = []
        if !G.fold && (P.ask == 0 || P.ask == 2) { lit.insert(P.v) }
        if k.rawValue > LinePlot2.Kind.tall.rawValue && (G.fold || P.ask == 1) { lit.insert(P.mode) }
        if P.ask == 3 && !G.fold && k != .hop { lit.insert(P.lw); lit.insert(P.hi) }
        let c = k == .hop ? LN2.chain(s, "h") : nil
        if let c { lit.insert(c.f); lit.insert(c.t) }
        if G.fold {
            for (i, _) in P.data.enumerated() { item(&pic, "f\(i)", P, x0: 0, x1: G.thingEnd(i), y: G.thingY(i)) }
            LN2.ruler(&pic, "ru", x0: 0, y: LY, per: 5, max: 10, below: true, lit: Array(lit))
            pic.word("lunit", "inches", at: G.X(10) + 2, LY + 1, DK2.small, anchor: UnitPoint(x: 0, y: 0.5))
        } else {
            pic.line("ln", [(G.X(G.lo) - 1, LY), (G.X(G.hi) + 1, LY)])
            var segs: [(CGPoint, CGPoint)] = []
            for u in G.lo...G.hi { segs.append((pic.P(G.X(u), LY), pic.P(G.X(u), LY + 1))) }
            pic.sketch.segments("lk", segs, .ink, width: Sketch.stroke)
            for u in G.lo...G.hi { let on = lit.contains(u) || u == hu; pic.word("lnum\(u)\(on)", "\(u)", at: G.X(u), LY + 2.3, on ? KK.lit : DK2.small) }
            pic.word("lunit", "inches", at: G.X(G.hi) + 2, LY + 2.3, DK2.small, anchor: UnitPoint(x: 0, y: 0.5))
            if held && hu >= 0 { live.word("lnum\(hu)l", "\(hu)", at: G.X(hu), LY + 2.3, KK.lit) }
        }
        // the stacks: an X in a cell over its number; the new one, the counted ones and the tallest in the chapter colour
        let st = stacks(s, G), nums = numbered(s, G)
        let tallLit = k.rawValue > LinePlot2.Kind.tall.rawValue && (G.fold || P.ask == 1) ? P.mode : nil
        for (u, ids) in st {
            for (j, id) in ids.enumerated() {
                let top = LY - XH * Double(j + 1), n = nums[id], on = id == "new" || n != nil || tallLit == u
                DK2.xMark(&pic, "x\(id)\(on)", x: G.X(u) - 2.5, top: top, h: XH, on ? .chapter : .ink)
                if let n { pic.word("xn\(id)\(n)", "\(n)", at: G.X(u) + 1.8, top + XH / 2, KK.lit, anchor: UnitPoint(x: 0, y: 0.5)) }
            }
        }
        // the new thing at the title row's right, with its length
        if !G.fold && P.ask == 0 {
            let NX = G.X(G.hi) - 8
            item(&pic, "new", P, x0: NX, x1: NX + 10, y: G.TT - 1)
            pic.word("newl", "\(P.v) inches", at: NX + 10.5, G.TT, DK2.say, anchor: UnitPoint(x: 0, y: 0.5))
        }
        // the X's to place, each in its dashed holder; the one held follows the finger
        if k == .place {
            for i in 0..<P.toPlace where !placed(s, G, i) {
                let h = G.holder(i)
                pic.sketch.box("xh\(i)", pic.R(h.x, h.y, 5, XH), .ink3, width: Sketch.stroke, dashed: true)
                if held && Int(s.h("i") ?? -1) == i {
                    DK2.xMark(&live, "xp\(i)", x: (s.h("px") ?? 0) - 2.5, top: (s.h("py") ?? 0) - XH / 2, h: XH, .chapter)
                } else { DK2.xMark(&pic, "xp\(i)", x: h.x, top: h.y, h: XH, .chapter) }
            }
        }
        // the readouts beside the plot, at the line's right end
        let rx = G.X(G.hi) + 2, ry = LY - 1.5
        if held && hu >= 0 { EG2.readout(&live, "\(hu) in", x: rx, y: ry); live.reads("\(hu) in") }
        if k == .count && !nums.isEmpty { EG2.readout(&pic, "\(nums.count)", x: rx, y: ry) }
        // the hops under the line, an inch a hop
        let hp = c ?? (P.ask == 3 && !G.fold && k.rawValue > LinePlot2.Kind.hop.rawValue ? LN2.Chain(f: P.lw, t: P.hi) : nil)
        if let hp {
            LN2.hops(&pic, &live, held: s.grabbed, "hp", hp.f, hp.t, x0: G.PX, per: 5, row: LY, height: -0.8)
            if k == .hop, hp.t != hp.f {
                let ro = "\(abs(hp.t - hp.f)) in"
                if s.grabbed { EG2.readout(&live, ro, x: rx, y: ry); live.reads(ro) } else { EG2.readout(&pic, ro, x: rx, y: ry) }
            }
        }
        // hints: a first miss rings the general area, a second the exact place
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        let plotTop = LY - XH * Double(P.tallest), plotW = G.X(G.hi) - G.X(G.lo) + 5
        switch k {
        case .place:
            let next = (0..<P.toPlace).first { !placed(s, G, $0) } ?? 0, w = P.home(next)
            if ring { KK.hintBox(&pic, "hp", x: G.X(G.lo) - 1.5, y: LY, w: plotW - 3, h: 3) }
            if spot { pic.circle("sp", at: G.X(w), G.fold ? LY + 1 : LY + 2.3, radius: 1.2, .chapter, dashed: true) }
        case .count:
            let u0 = P.ask == 0 ? P.v : P.v + 1, u1 = P.ask == 0 ? P.v : P.lo + 5
            if ring { KK.hintBox(&pic, "hc", x: G.X(u0) - 2.5, y: plotTop, w: G.X(u1) - G.X(u0) + 5, h: LY - plotTop) }
            if spot, let u = (u0...u1).first(where: { u in (st[u] ?? []).contains { nums[$0] == nil } }), let ids = st[u], let j = ids.firstIndex(where: { nums[$0] == nil }) {
                KK.hint(&pic, "sc", G.X(u), LY - XH * (Double(j) + 0.5), radius: 2)
            }
        case .tall:
            if ring { KK.hintBox(&pic, "ht", x: G.X(G.lo) - 2.5, y: plotTop, w: plotW, h: LY - plotTop) }
            if spot { KK.hintBox(&pic, "hs", x: G.X(P.mode) - 2.5, y: LY - XH * Double(P.stack(P.mode)), w: 5, h: XH * Double(P.stack(P.mode))) }
        case .hop:
            if ring { KK.hintBox(&pic, "hh", x: G.X(P.lw) - 2.5, y: LY - 1, w: G.X(P.hi) - G.X(P.lw) + 5, h: 4) }
            if spot { pic.circle("sh", at: G.X(P.lw), LY, radius: 1, .chapter, dashed: true) }
        default: break
        }
        // the record: [4] pencils, [5] inches, 8 − 4 = [4] in
        if k == .write || k == .done {
            let last: M7.Tok = k == .done ? .n(P.answer, .chapter) : .box("x", cells: 2)
            let end = M7.row(&rec, "rec", toks(P) + [last, .w(P.unit)], x: 0, line: 1)
            if k == .write && ring { KK.hintBox(&pic, "hw", x: G.X(G.lo) - 2.5, y: plotTop, w: plotW, h: LY - plotTop) }
            if k == .write && spot { A1.note(&rec, "spot", "\(P.answer)", x: end + 0.5, y: 3.5) }
        }
        let right = G.fold ? G.X(10) + 7 : G.X(G.hi) + 9
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, right, G.fold ? G.thingY(4) + 2 : LY + 3))
    }

    func hands(_ s: PaperState) -> Hands? {
        let G = geo(s.numbers), P = G.P, k = kind(s), XH = G.XH
        switch k {
        case .place:
            return Hands(
                grab: { q in
                    for i in 0..<P.toPlace where !placed(s, G, i) {
                        let h = G.holder(i)
                        if q.x >= h.x - 0.6, q.x <= h.x + 5.6, q.y >= h.y - 0.6, q.y <= h.y + XH + 0.6 {
                            return ["grab": 1, "i": Double(i), "px": q.x, "py": q.y, "u": -1]
                        }
                    }
                    return nil
                },
                drag: { q, h in var h = h; h["px"] = q.x; h["py"] = q.y; h["u"] = Double(G.over(q.x, q.y) ?? -1); return h },
                release: { h in
                    let i = Int(h["i"] ?? 0), u = Int(h["u"] ?? -1)
                    guard u >= 0 else { return HandMove(hand: [:]) }
                    if u != P.home(i) { return HandMove(hand: [:], missHand: [:], set: [("p", Double(100 * i + u))], check: true) }
                    let all = (0..<P.toPlace).allSatisfy { $0 == i || placed(s, G, $0) }
                    return HandMove(hand: [:], missHand: [:], set: all ? [("p", Double(LinePlot2.allPlaced))] : [], keep: ["pl\(i)": 1], check: all)
                })
        case .count, .tall:
            let st = stacks(s, G), nums = numbered(s, G)
            return Hands(tap: { q in
                let u = G.col(q.x)
                guard abs(q.x - G.X(u)) <= 2.6, let ids = st[u], q.y >= G.LY - XH * Double(ids.count) - 0.6, q.y <= G.LY + 0.5 else { return nil }
                if k == .tall { return HandMove(hand: [:], missHand: [:], set: [("t", Double(u))], check: true) }
                let ok = P.ask == 0 ? u == P.v : u > P.v
                if !ok { return HandMove(hand: [:], missHand: [:], set: [("k", Double(100 + u))], check: true) }
                guard ids.contains(where: { nums[$0] == nil }) else { return HandMove(hand: [:]) }
                let n = nums.count, all = n + 1 == P.counted
                return HandMove(hand: [:], missHand: [:], set: all ? [("k", Double(P.counted))] : [], keep: ["q\(n)": Double(u)], check: all)
            })
        case .hop:
            return LN2.hopHands(s, "h", box: "h", band: (G.LY - 1.5)...(G.LY + 3), xr: G.X(G.lo)...G.X(G.hi), at: { G.col($0) },
                                clears: { f, _ in f != P.lw })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let G = geo(s.numbers), P = G.P, k = kind(s), XH = G.XH
        switch k {
        case .place:
            var out: [GhostMove] = [], heights: [Int: Int] = [:]
            for (u, ids) in stacks(s, G) { heights[u] = ids.count }
            for i in 0..<P.toPlace where !placed(s, G, i) {
                let h = G.holder(i), u = P.home(i), n = heights[u] ?? 0
                out.append(.drag(from: CGPoint(x: h.x + 2.5, y: h.y + XH / 2), to: CGPoint(x: G.X(u), y: G.LY - XH * (Double(n) + 0.5))))
                heights[u] = n + 1
            }
            return out
        case .count:
            let st = stacks(s, G), nums = numbered(s, G)
            var out: [GhostMove] = []
            for u in st.keys.sorted() where P.ask == 0 ? u == P.v : u > P.v {
                for (j, id) in (st[u] ?? []).enumerated() where nums[id] == nil { out.append(.tap(.picture(CGPoint(x: G.X(u), y: G.LY - XH * (Double(j) + 0.5))))) }
            }
            return out
        case .tall: return [.tap(.picture(CGPoint(x: G.X(P.mode), y: G.LY - XH / 2)))]
        case .hop: return [.drag(from: CGPoint(x: G.X(P.lw), y: G.LY + 0.5), to: CGPoint(x: G.X(P.hi), y: G.LY + 0.5))]
        default: return []
        }
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = geo(s.numbers).P
        switch kind(s) {
        case .place:
            let w = P.home(0), u = P.fold && P.past.first == true ? w + 1 : (w > P.lo ? w - 1 : w + 1)
            return HandMove(hand: [:], missHand: [:], set: [("p", Double(u))], check: true)
        case .count:
            let u = P.ask == 0 ? (P.data.contains(P.v - 1) ? P.v - 1 : P.v + 1) : P.v
            return HandMove(hand: [:], missHand: [:], set: [("k", Double(100 + u))], check: true)
        case .tall:
            let u = P.data.first { $0 != P.mode } ?? P.mode
            return HandMove(hand: [:], missHand: [:], set: [("t", Double(u))], check: true)
        case .hop: return LN2.hopMove("h", box: "h", from: P.lw, to: P.hi - 1)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = geo(s.numbers).P
        guard kind(s) == .write else { return nil }
        return ["x": Double(P.slips.first?.0 ?? P.answer + 1)]
    }
}
