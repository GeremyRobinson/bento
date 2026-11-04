import SwiftUI

/// Two quantities on the paper, as in the preview (design/prototype/grade6-ch6.html, dDep): the plane's own squares,
/// across 0–10 at 4 squares a one, up 0–30 squares (a square a one, or 5 for rules that grow by 5, 10 or 15), named by
/// the story ("hours (h)" across, "miles (m)" up), a handle on the across axis. The story and the table (the record)
/// beside it. Drag the handle to 2, 4 and 6: the point rides the rule's line above it and the table writes a column at
/// each stop; write the rule; use it past the paper (or backwards: which h makes m = 45).
///
/// The picture's squares: the plane's corner at (`ox`, `oy`), the story and table from column `TX`; the record (the
/// table and the lines under it) is in the same squares (recordRow 0). The table's columns are 4 squares, each number
/// written tight and centred on the column's middle grid line (the preview's 5-square columns put it half a square off). Hand keys: "hh" (the handle, in ones), "grab"; kept: "cols" (the stops made,
/// bits for 2, 4, 6).
@MainActor
struct TwoQuantitiesLesson: PaperLesson {
    static let ox = 3.0, oy = 32.0, U = 4.0, TX = 50.0, TY = 5.0, CW = 4.0, H = 2.0
    static let ruleRow = TY + 8, pastRow = TY + 12
    var liveKeys: Set<String> { ["hh", "grab", "from"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static func at(_ P: Depend6.Parts, _ h: Double, _ y: Double) -> CGPoint { CGPoint(x: ox + U * h, y: oy - y / Double(P.ys)) }
    private func cols(_ s: PaperState) -> Int { stage(s) >= 4 ? 7 : Int(s.run.kept["cols"] ?? 0) }
    private func stops(_ mask: Int) -> [Int] { Depend6.stops.indices.filter { mask & (1 << $0) != 0 }.map { Depend6.stops[$0] } }
    /// Where the handle waits: on the last stop made.
    private func rest(_ s: PaperState) -> Double { Double(stops(cols(s)).max() ?? 0) }

    func recordRow(_ n: Numbers) -> Double? { 0 }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        switch stage(s) {
        case 4: return CGPoint(x: Self.TX, y: Self.ruleRow + 2)
        case 5, 6: return CGPoint(x: Self.TX, y: Self.pastRow + 5)
        default: return nil
        }
    }
    func keysFocus(_ s: PaperState) -> CGRect? {
        stage(s) == 4 ? CGRect(x: Self.TX, y: Self.TY, width: 2 + 3 * Self.CW, height: 2 * Self.H) : nil
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Depend6.Parts(s.numbers), S = P.S, at = stage(s), ox = Self.ox, oy = Self.oy, U = Self.U
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let moving = at >= 1 && at <= 3, held = moving && s.grabbed, mask = cols(s)
        let h = moving ? s.h("hh") ?? rest(s) : rest(s)
        // the plane: across 0–10, up 0–30 squares
        pic.line("ax", [(ox, oy), (ox + 41.5, oy)]); pic.line("axa", [(ox + 40.7, oy - 0.8), (ox + 41.5, oy), (ox + 40.7, oy + 0.8)])
        pic.line("ay", [(ox, oy), (ox, oy - 31.5)]); pic.line("aya", [(ox - 0.8, oy - 30.7), (ox, oy - 31.5), (ox + 0.8, oy - 30.7)])
        pic.sketch.segments("xt", (0...10).map { i in (pic.P(ox + U * Double(i), oy), pic.P(ox + U * Double(i), oy + 0.5)) }, .ink, width: Sketch.stroke)
        pic.sketch.segments("yt", stride(from: 5, through: 30, by: 5).map { j in (pic.P(ox - 0.5, oy - Double(j)), pic.P(ox, oy - Double(j))) }, .ink, width: Sketch.stroke)
        for i in 0...10 {
            let on = held && Double(i) == h
            if on { live.label("xlh\(i)", "\(i)", E6.lit, .below, edge: oy + 0.4, along: ox + U * Double(i)) }
            else { pic.label("xl\(i)", "\(i)", E6.small, .below, edge: oy + 0.4, along: ox + U * Double(i)) }
        }
        for j in stride(from: 5, through: 30, by: 5) { pic.label("yl\(j)", "\(j * P.ys)", E6.small, .left, edge: ox - 0.4, along: oy - Double(j)) }
        // the across axis's name right of its arrow (under the numbers it'd make the problem too tall for 75%)
        pic.label("xn", "\(S.X) (\(S.xl))", E6.small, .right, edge: ox + 41.7, along: oy)
        pic.word("yn", "\(S.Y) (\(S.yl))", at: ox + 1.2, oy - 31, E6.small, anchor: UnitPoint(x: 0, y: 0.5))

        // the rule's line, as far as the handle has been; the stops' points; the point riding over the handle
        let reach = at >= 5 ? 10.0 : max(rest(s), moving ? h : 0)
        if reach > 0 {
            let a = Self.at(P, 0, Double(P.f(0))), b = Self.at(P, reach, Double(P.f(Int(reach))))
            if moving && h > rest(s) { live.line("rl", [(a.x, a.y), (b.x, b.y)], .chapter) } else { pic.line("rl\(Int(reach))", [(a.x, a.y), (b.x, b.y)], .chapter) }
        }
        for st in stops(mask) { let p = Self.at(P, Double(st), Double(P.f(st))); pic.dot("pt\(st)", at: p.x, p.y, radius: 0.45, .chapter, over: true) }
        if moving {
            let p = Self.at(P, h, Double(P.f(Int(h))))
            if held || h > 0 {
                live.line("drop", [(p.x, p.y), (p.x, oy)], .chapter, dashed: true)
                live.dot("pp", at: p.x, p.y, radius: 0.45, .chapter, over: true)
            }
            R6.handle(&live, "hh", p.x, oy, held: held)
            if held {
                let r = P.read(Int(h))
                live.word("rd", r, at: h > 7 ? p.x - 1 : p.x + 1, p.y - 1.2, E6.lit, anchor: UnitPoint(x: h > 7 ? 1 : 0, y: 0.5)); live.reads(r)
            }
        }

        // the story, and the table (the record): a column at each stop, in order
        let story = PaperText.wrap(S.s, PaperText.font(Sketch.wordSize, .medium), width: 16 * Paper.cell)
        for (i, l) in story.enumerated() { rec.word("st\(i)", l, at: Self.TX, 1 + 2 * Double(i) - (story.count > 1 ? 1 : 0), E6.words, anchor: UnitPoint(x: 0, y: 0.5)) }
        let TX = Self.TX, TY = Self.TY, CW = Self.CW, H = Self.H, right = TX + 2 + 3 * CW
        rec.sketch.box("tbo", rec.R(TX, TY, 2 + 3 * CW, 2 * H), .ink, width: Sketch.stroke)
        rec.rule("tbm", from: TX, to: right, row: TY + H)
        rec.sketch.segments("tbc", (0..<3).map { j in (rec.P(TX + 2 + CW * Double(j), TY), rec.P(TX + 2 + CW * Double(j), TY + 2 * H)) }, .ink, width: Sketch.stroke)
        rec.word("tbx", S.xl, at: TX + 1, TY + 1, E6.maths)
        rec.word("tby", S.yl, at: TX + 1, TY + 3, E6.maths)
        for (j, st) in Depend6.stops.enumerated() where mask & (1 << j) != 0 {
            let cx = TX + 2 + CW * Double(j), y = P.f(st)
            // written tight, as a number in a line is, centred on the column's middle grid line (ch1's table)
            rec.word("tcx\(st)", "\(st)", at: cx + CW / 2, TY + 1, E6.maths)
            rec.word("tcy\(st)", "\(y)", at: cx + CW / 2, TY + 3, E6.maths.colour(.chapter))
        }
        // the rule, then past the paper
        if at >= 4 {
            let r: M7.Tok = at == 4 ? .box("r", cells: 2) : .n(P.times ? P.k : P.c, .chapter)
            M7.row(&rec, "r1", P.times ? [.t(S.yl), .op("="), r, .op("×"), .t(S.xl)] : [.t(S.yl), .op("="), .t(S.xl), .op("+"), r], x: TX, line: Self.ruleRow)
        }
        if at >= 5 {
            let ans = P.back ? P.xs : P.ysv
            let v: M7.Tok = at == 5 ? .box("p", cells: max(2, "\(ans)".count)) : .n(ans, .chapter)
            M7.row(&rec, "r2", P.back ? [.t(S.yl), .op("="), .n(P.ysv)] : [.t(S.xl), .op("="), .n(P.xs)], x: TX, line: Self.pastRow)
            M7.row(&rec, "r3", P.back ? [.t(S.xl), .op("="), v] : [.t(S.yl), .op("="), v], x: TX, line: Self.pastRow + 3)
        }

        // hints: a first miss rings the general area, a second the exact spot (call of 3 Nov)
        switch at {
        case 1, 2, 3:
            let next = Depend6.stops.indices.first { mask & (1 << $0) == 0 }.map { Depend6.stops[$0] } ?? 2
            if s.on("ring") { R6.ring(&pic, "ring", x: ox, y: oy - 1, w: U * 6, h: 2) }
            if s.on("spot") { pic.circle("spot", at: ox + U * Double(next), oy, radius: 1.3, .chapter, dashed: true) }
        case 4:
            if s.on("ring") { R6.ring(&rec, "ring", x: TX, y: TY, w: 2 + 3 * CW, h: 2 * H) }
            if s.on("spot") {
                let t = P.times ? "\(P.f(2)) ÷ 2 = \(P.k)" : "\(P.f(2)) − 2 = \(P.c)"
                rec.label("spot", t, E6.lit, .below, edge: TY + 2 * H + 0.2, along: TX + 2 + CW / 2)
            }
        case 5:
            if s.on("ring") { R6.ring(&rec, "ring", x: TX, y: Self.ruleRow - 1, w: 12, h: 2) }
            if s.on("spot") {
                let t = P.back ? (P.times ? "\(P.ysv) ÷ \(P.k)" : "\(P.ysv) − \(P.c)") : (P.times ? "\(P.k) × \(P.xs)" : "\(P.xs) + \(P.c)")
                rec.word("spot", t, at: TX + 12, Self.pastRow + 3, E6.lit, anchor: UnitPoint(x: 0, y: 0.5))
            }
        default: break
        }
        let ext = pic.R(-1, -0.5, right + 3, oy + 2.3)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Depend6.Parts(s.numbers), at = stage(s)
        guard at >= 1 && at <= 3 else { return nil }
        let mask = cols(s), now = s.h("hh") ?? rest(s)
        return Hands(grab: { q in
            abs(q.x - (Self.ox + Self.U * now)) < 1.8 && abs(q.y - Self.oy) < 2 ? ["grab": 1, "hh": now, "from": now] : nil
        }, drag: { q, h in
            var h = h; h["hh"] = Double(min(10, max(0, Int(((q.x - Self.ox) / Self.U).rounded())))); return h
        }, release: { h in
            // (the hands are asked again as the finger moves: where it started is in the hand)
            let v = h["hh"] ?? now, iv = Int(v)
            if v == h["from"] || iv == 0 { return HandMove(hand: ["hh": v]) }
            if let j = Depend6.stops.firstIndex(of: iv) {
                // a stop already made: nothing new to write
                if mask & (1 << j) != 0 { return HandMove(hand: ["hh": v]) }
                return HandMove(hand: ["hh": v], missHand: ["hh": v], set: [("h", v)], keep: ["cols": Double(mask | 1 << j)], check: true)
            }
            _ = P
            return HandMove(hand: ["hh": v], missHand: ["hh": v], set: [("h", v)], check: true)
        })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard (1...3).contains(stage(s)) else { return [] }
        let mask = cols(s), now = s.h("hh") ?? rest(s)
        guard let j = Depend6.stops.indices.first(where: { mask & (1 << $0) == 0 }) else { return [] }
        return [.drag(from: CGPoint(x: Self.ox + Self.U * now, y: Self.oy), to: CGPoint(x: Self.ox + Self.U * Double(Depend6.stops[j]), y: Self.oy))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard (1...3).contains(stage(s)) else { return nil }
        let v = rest(s) + 1
        return HandMove(hand: ["hh": v], missHand: ["hh": v], set: [("h", v)], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Depend6.Parts(s.numbers)
        switch stage(s) {
        case 4: return ["r": Double(P.times ? (2 * P.k - 2 != P.k ? 2 * P.k - 2 : P.k + 1) : P.c + 1)]
        case 5: return ["p": Double(P.back ? P.f(P.ysv) : 20 + (P.times ? P.k : P.c) + 1)]
        default: return nil
        }
    }
}
