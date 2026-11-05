import SwiftUI

/// Make a graph on the paper, as in the preview (design/prototype/grade2-ch5.html, dMakeGraph): a vote is a block along its
/// row, so the scale's numbers sit on the strong lines. The title over the graph; four rows 4 squares tall a square apart,
/// each row's little picture, its name and its tally marks at its left (the tally chart beside the graph, so it shows at
/// 75%); the row's dashed holder until it's made. A picture graph: tap a row and each tap puts the next picture in its
/// next block. A bar graph (the scale 0–8 under it): drag each bar's end, a block at a time. A finished row ticks its tally;
/// the readout at the title row's right end. Then the record 3 rows under, Check beside it. The missing row: its tally is a
/// ?, the other bars are drawn; drag it, the readout counts the whole graph.
///
/// Kept: "s<j>" a row's pictures or bar length, "cur" the row a picture went in last. Hand: "grab", "j", "v" (a bar held);
/// after a miss, "over" (row + 1) a picture past the tally, drawn red until the next touch.
@MainActor
struct MakeGraph2Lesson: PaperLesson {
    var liveKeys: Set<String> { ["v"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    @MainActor struct Geo {
        let P: MakeGraph2.Parts
        /// The tally marks' column, after the longest name; the graph's left edge on a block line after them.
        var TX: Double {
            var w = 0.0
            for n in P.th.names { w = max(w, KK.width(n, DK2.say)) }
            return ((3.3 + w + 0.6) * 2).rounded(.up) / 2
        }
        var GX: Double { EG2.ceil5(DK2.tallyEnd(P.c.max() ?? 8, x: TX) + 2.2) }
        static let BY = 5.0
        func rowY(_ j: Int) -> Double { Self.BY + 5 * Double(j) }
        var SY: Double { Self.BY + 20 }
        var ROW: Double { P.pics ? Self.BY + 22 : SY + 5 }
        func rowAt(_ q: CGPoint) -> Int? {
            for j in 0..<4 where q.y >= rowY(j) - 0.4 && q.y <= rowY(j) + 4.4 && q.x >= -1 && q.x <= GX + 41 { return j }
            return nil
        }
        func blocks(_ x: Double) -> Int { max(0, min(8, Int(((x - GX) / 5).rounded()))) }
    }
    private func geo(_ n: Numbers) -> Geo { Geo(P: MakeGraph2.Parts(n)) }
    func recordRow(_ n: Numbers) -> Double? { geo(n).ROW }
    private func toks(_ P: MakeGraph2.Parts) -> [M7.Tok] {
        if P.missing { return [.n(P.total), .op("−"), .n(P.base), .op("=")] }
        var out: [M7.Tok] = []
        for (j, v) in P.c.enumerated() { if j > 0 { out.append(.op("+")) }; out.append(.n(v)) }
        out.append(.op("="))
        return out
    }
    private func recordEnd(_ P: MakeGraph2.Parts) -> Double {
        var t = toks(P) + [M7.Tok.box("x", cells: 2)]
        if !P.missing { t.append(.w("in all")) }
        return M7.width(t)
    }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let G = geo(s.numbers)
        guard at(s) >= 1 else { return nil }
        return CGPoint(x: EG2.ceil5(recordEnd(G.P) + 1), y: G.ROW)
    }

    /// Each row as it is now: its pictures or its bar's length (the missing row's others are drawn).
    private func shown(_ s: PaperState, _ P: MakeGraph2.Parts) -> [Int] {
        var out: [Int] = []
        for j in 0..<4 {
            if at(s) >= 1 { out.append(P.c[j]) }
            else if P.missing && j != P.mx { out.append(P.c[j]) }
            else { out.append(Int(s.run.kept["s\(j)"] ?? 0)) }
        }
        return out
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let G = geo(s.numbers), P = G.P, st = at(s), GX = G.GX, TX = G.TX, th = P.th
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let sh = shown(s, P), heldJ: Int? = s.grabbed ? s.h("j").map { Int($0) } : nil
        pic.word("title", th.title, at: GX + 20, 2, DK2.say)
        for j in 0..<4 {
            let y = G.rowY(j), mid = y + 2
            // the tally chart beside the row: a picture, a name, the marks (or the missing row's ?)
            L5.icon(&pic, "ri\(j)", th.icons[j], 1.5, mid, sc: 0.8)
            pic.word("rn\(j)", th.names[j], at: 3.3, mid, DK2.say, anchor: UnitPoint(x: 0, y: 0.5))
            if P.missing && j == P.mx && st < 2 { pic.word("tq\(j)", "?", at: TX + 1.5, mid, KK.maths.colour(.chapter)) }
            else { DK2.tally(&pic, "tm\(j):", P.c[j], x: TX, y: y + 0.5) }
            let made = sh[j] == P.c[j] && !(P.missing && j != P.mx)
            if made { DK2.tick(&pic, "tk\(j)", x: DK2.tallyEnd(P.c[j], x: TX) + 0.6, y: mid) }
            // the row's holder, dashed, until it's made
            if st == 0 && sh[j] != P.c[j] { pic.sketch.box("h\(j)", pic.R(GX, y, 40, 4), .ink3, width: Sketch.stroke, dashed: true) }
            if P.pics {
                for k in 0..<sh[j] { L5.icon(&pic, "p\(j):\(k)", th.icons[j], GX + 5 * Double(k) + 2.5, mid) }
                if st == 0, Int(s.h("over") ?? 0) == j + 1 { L5.icon(&pic, "pover\(j)", th.icons[j], GX + 5 * Double(sh[j]) + 2.5, mid, edge: Bars.red) }
            } else if j == heldJ {
                let v = Int(s.h("v") ?? 0)
                DK2.bar(&live, "b\(j)", x: GX, y: y, v, lit: true)
                DK2.handle(&live, "hd\(j)", x: GX + 5 * Double(v), y: y)
            } else {
                DK2.bar(&pic, "b\(j)", x: GX, y: y, sh[j])
                if st == 0 && sh[j] != P.c[j] { DK2.handle(&pic, "hd\(j):\(sh[j])", x: GX + 5 * Double(sh[j]), y: y) }
            }
        }
        if !P.pics { DK2.scale(&pic, x: GX, top: Geo.BY - 1, y: G.SY, max: 8) }
        // the readout at the title row's right end
        if st == 0 {
            var ro: String?
            if let j = heldJ { let v = Int(s.h("v") ?? 0); ro = P.missing ? "\(P.base + v) in all" : "\(v)" }
            else if P.pics, let c = s.run.kept["cur"] { let j = Int(c); ro = "\(th.names[j]): \(sh[j])" }
            if let ro {
                if heldJ != nil { DK2.readoutEnd(&live, ro, x: GX + 40, y: 2); live.reads(ro) } else { DK2.readoutEnd(&pic, ro, x: GX + 40, y: 2) }
            }
        }
        // hints: a first miss rings the row to make and its tally; a second rings the block it ends in
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        let todo = (0..<4).first { sh[$0] != P.c[$0] }
        if st == 0, let j = todo {
            if ring { KK.hintBox(&pic, "hr\(j)", x: TX, y: G.rowY(j), w: GX + 40 - TX, h: 4) }
            if spot { KK.hint(&pic, "sp\(j)", GX + 5 * Double(P.c[j]) - 2.5, G.rowY(j) + 2) }
        }
        // the record: 7 + 4 + 6 + 3 = [20] in all, or 20 − 17 = [3]
        if st >= 1 {
            let last: M7.Tok = st == 2 ? .n(P.answer, .chapter) : .box("x", cells: 2)
            var t = toks(P) + [last]
            if !P.missing { t.append(.w("in all")) }
            let end = M7.row(&rec, "rec", t, x: 0, line: 1)
            if st == 1 && ring {
                if P.missing { KK.hintBox(&pic, "hw", x: GX, y: G.rowY(P.mx), w: 5 * Double(P.c[P.mx]), h: 4) }
                else { KK.hintBox(&pic, "hw", x: TX, y: Geo.BY, w: 10, h: 19) }
            }
            if st == 1 && spot { A1.note(&rec, "spot", "\(P.answer)", x: end + 0.5, y: 3.5) }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, GX + 41, G.SY + 3))
    }

    func hands(_ s: PaperState) -> Hands? {
        let G = geo(s.numbers), P = G.P
        guard at(s) == 0 else { return nil }
        let sh = shown(s, P)
        let done = (0..<4).map { sh[$0] == P.c[$0] }
        if P.pics {
            let cur = s.run.kept["cur"].map { Int($0) }
            return Hands(tap: { q in
                guard let j = G.rowAt(q) else { return nil }
                if done[j] { return HandMove(hand: [:], missHand: ["over": Double(j + 1)], set: [("r", Double(MakeGraph2.code(row: j, shown: P.c[j] + 1)))], check: true) }
                let keep: Numbers = ["s\(j)": Double(sh[j] + 1), "cur": Double(j)]
                if let r = cur, r != j, !done[r], sh[r] > 0 {
                    return HandMove(hand: [:], missHand: [:], set: [("r", Double(MakeGraph2.code(row: r, shown: sh[r])))], keep: keep, check: true)
                }
                let all = (0..<4).allSatisfy { $0 == j ? sh[j] + 1 == P.c[j] : done[$0] }
                return HandMove(hand: [:], missHand: [:], set: all ? [("r", Double(MakeGraph2.allMade))] : [], keep: keep, check: all)
            })
        }
        return Hands(
            grab: { q in
                guard let j = G.rowAt(q), !done[j], !P.missing || j == P.mx else { return nil }
                return ["grab": 1, "j": Double(j), "v": Double(G.blocks(q.x))]
            },
            drag: { q, h in var h = h; h["v"] = Double(G.blocks(q.x)); return h },
            release: { h in
                let j = Int(h["j"] ?? 0), v = Int(h["v"] ?? 0)
                guard v > 0 else { return HandMove(hand: [:]) }
                let keep: Numbers = ["s\(j)": Double(v)]
                if P.missing { return HandMove(hand: [:], missHand: [:], set: [("r", Double(v))], keep: keep, check: true) }
                if v != P.c[j] { return HandMove(hand: [:], missHand: [:], set: [("r", Double(MakeGraph2.code(row: j, shown: v)))], keep: keep, check: true) }
                let all = (0..<4).allSatisfy { $0 == j || done[$0] }
                return HandMove(hand: [:], missHand: [:], set: all ? [("r", Double(MakeGraph2.allMade))] : [], keep: keep, check: all)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let G = geo(s.numbers), P = G.P
        guard at(s) == 0 else { return [] }
        let sh = shown(s, P)
        var out: [GhostMove] = []
        for j in 0..<4 where sh[j] < P.c[j] || (!P.pics && sh[j] != P.c[j]) {
            let y = G.rowY(j) + 2
            if P.pics { for k in sh[j]..<P.c[j] { out.append(.tap(.picture(CGPoint(x: G.GX + 5 * Double(k) + 2.5, y: y)))) } }
            else { out.append(.drag(from: CGPoint(x: G.GX + 5 * Double(max(0, sh[j])) + 0.5, y: y), to: CGPoint(x: G.GX + 5 * Double(P.c[j]), y: y))) }
        }
        return out
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = geo(s.numbers).P
        guard at(s) == 0 else { return nil }
        if P.missing { return HandMove(hand: [:], missHand: [:], set: [("r", Double(P.c[P.mx] - 1))], keep: ["s\(P.mx)": Double(P.c[P.mx] - 1)], check: true) }
        let v = P.c[0] > 1 ? P.c[0] - 1 : 2
        return HandMove(hand: [:], missHand: [:], set: [("r", Double(MakeGraph2.code(row: 0, shown: v)))], keep: ["s0": Double(v), "cur": 0], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = geo(s.numbers).P
        guard at(s) == 1 else { return nil }
        return ["x": Double(P.slips.first?.0 ?? P.answer + 1)]
    }
}
