import SwiftUI

/// Scaled picture and bar graphs on the paper, as in the preview (design/prototype/grade3-ch7.html, dGraphs): the title,
/// four rows 4 squares tall 6 apart with their names at the left, under them the key (a picture graph: a picture is a
/// 4-square cell, up to 9 in a row) or the scale (a bar graph: a line every 6 squares, 0–8 lines). Tap the key: every
/// picture sits up and says what it's worth. Drag along a row: it tints a half picture at a time ("4 pictures and a
/// half"). Tap the scale: its numbers light. Drag a line from a bar's end down to the scale: it snaps to half lines and
/// the readout names the lines either side ("40 | 50"); let go on the scale, the line stays dashed. Write `4 × 2 + 1 =
/// [9]` or `Dogs: [45]` 3 rows under the graph; the second row beside it, then `35 − 20 = [15]` under them (the shorter
/// one's end drops a dashed line across the longer one and the extra is bracketed) or `35 + 20 = [55]`.
///
/// Hand while a row is dragged: "grab", "j", "n" (half pictures); a line: "grab", "j", "h" (half lines), "py".
@MainActor
struct Graphs3Lesson: PaperLesson {
    var liveKeys: Set<String> { ["n", "h", "py"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func geo(_ n: Numbers) -> DK3.Graph { DK3.Graph(type: Graphs3.Parts(n).type) }
    func recordRow(_ n: Numbers) -> Double? { DK3.Graph.RY - 1 }

    /// The row this step reads.
    private func row(_ P: Graphs3.Parts, _ st: Int) -> Int { st <= 2 ? P.x : P.y }
    private func line(_ P: Graphs3.Parts, _ j: Int, _ box: String, right: Bool) -> [M7.Tok] {
        let last: M7.Tok = right ? .n(P.c[j], .chapter) : .box(box, cells: 2)
        if P.pic {
            var t: [M7.Tok] = [.n(P.whole(j)), .op("×"), .n(P.s)]
            if P.half(j) { t.append(.op("+")); t.append(.n(P.s / 2)) }
            t.append(.op("=")); t.append(last)
            return t
        }
        return [.w("\(P.th.names[j]):"), last]
    }
    private func opLine(_ P: Graphs3.Parts, right: Bool) -> [M7.Tok] {
        [.n(P.a), .op(P.ask == 1 ? "−" : "+"), .n(P.b), .op("="), right ? .n(P.answer, .chapter) : .box("op", cells: P.ask == 1 ? 2 : 3)]
    }
    /// Where the second row's line starts: a block past the first line at its widest.
    private func secondCol(_ P: Graphs3.Parts) -> Double { EG2.ceil5(M7.width(line(P, P.x, "x", right: false)) + 3) }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = Graphs3.Parts(s.numbers), st = at(s), RY = DK3.Graph.RY
        switch st {
        case 2: return CGPoint(x: DK3.after(M7.width(line(P, P.x, "x", right: false))), y: RY - 1)
        case 4: return CGPoint(x: DK3.after(secondCol(P) + M7.width(line(P, P.y, "y", right: false))), y: RY - 1)
        case 5: return CGPoint(x: DK3.after(M7.width(opLine(P, right: false))), y: RY + 2)
        case 9: return P.ask > 0 ? CGPoint(x: DK3.after(M7.width(opLine(P, right: true))), y: RY + 2) : CGPoint(x: DK3.after(M7.width(line(P, P.x, "x", right: true))), y: RY - 1)
        default: return nil
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Graphs3.Parts(s.numbers), st = at(s), G = geo(s.numbers), th = P.th, GX = G.GX, AY = G.AY, s2 = P.s
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let read: Set<Int> = {
            var r: Set<Int> = []
            if st >= 2 { r.insert(P.x) }
            if st >= 4 { r.insert(P.y) }
            return r
        }()
        DK3.base(&pic, G, th, s: s2, lit: !P.pic && st >= 1)
        for j in 0..<4 {
            DK3.name(&pic, G, j, th.names[j])
            if P.pic {
                if read.contains(j) { pic.fill("rt\(j)", col: GX, row: G.row(j), w: G.len(P.c[j], s2), h: 4, .tint(0.2)) }
                DK3.picRow(&pic, "p\(j)", G, j, P.halves(j), th, s: s2, worth: st >= 1)
            } else { DK3.bar(&pic, "b\(j)", G, j, G.len(P.c[j], s2), strong: read.contains(j)) }
        }
        // the bars read: their lines down to the scale stay, dashed
        if !P.pic { for j in read { let x = GX + G.len(P.c[j], s2); pic.line("rl\(j)", [(x, G.row(j) + 4), (x, AY)], .ink3, dashed: true) } }
        // the move: a row tints as the finger runs along it, or a line drops from the bar's end
        let dragging = st == 1 || st == 3
        var roomRight = 0.0
        if dragging {
            let w = row(P, st), held = s.grabbed, hj = held ? Int(s.h("j") ?? 0) : w
            if P.pic {
                if held {
                    let n = Int(s.h("n") ?? 0), x = GX + 2 * Double(n)
                    live.fill("dt", col: GX, row: G.row(hj), w: 2 * Double(n), h: 4, .tint(0.4))
                    live.line("dl", [(GX, G.row(hj)), (x, G.row(hj))], .chapter)
                    live.dot("dh", at: x, G.row(hj), radius: 0.7, .chapter, over: true)
                    let ro = Data3.picWords(n)
                    DK3.readout(&live, ro, x: GX + G.W + 2.5, y: G.row(hj) + 2); live.reads(ro)
                } else { pic.dot("dh0", at: GX, G.row(w), radius: 0.55, .chapter, over: true) }
                roomRight = 15
            } else {
                if held {
                    let h = Int(s.h("h") ?? 0), x = GX + 3 * Double(h), y1 = G.row(hj) + 4, y2 = max(y1, min(AY, s.h("py") ?? y1))
                    live.line("dd", [(x, y1), (x, y2)], .chapter, dashed: true)
                    live.dot("dh", at: x, y2, radius: 0.7, .chapter, over: true)
                    let ro = h % 2 == 1 ? "\((h - 1) / 2 * s2) | \((h + 1) / 2 * s2)" : "\(h / 2 * s2)"
                    DK3.readout(&live, ro, x: GX + G.W + 2.5, y: G.row(hj) + 2); live.reads(ro)
                } else { pic.dot("dh0", at: GX + G.len(P.c[w], s2), G.row(w) + 4, radius: 0.55, .chapter, over: true) }
                roomRight = 6
            }
        }
        if P.ask == 1 && st >= 5 { DK3.moreMarks(&pic, "mm", G, longer: P.x, shorter: P.y, G.len(P.a, s2), G.len(P.b, s2)) }
        // hints: a first miss rings the general area, a second the exact spot
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        switch st {
        case 0:
            if P.pic {
                if ring { KK.hintBox(&pic, "hr", x: GX, y: AY - 0.6, w: 18, h: 3.2) }
                if spot { KK.hint(&pic, "hs", GX + 2, AY + 1, radius: 2.2) }
            } else {
                if ring { KK.hintBox(&pic, "hr", x: GX - 1.5, y: AY - 0.4, w: G.W + 3, h: 3) }
                if spot { KK.hint(&pic, "hs", GX + 6, AY + 2, radius: 2.2) }
            }
        case 1, 3:
            let j = row(P, st), end = GX + G.len(P.c[j], s2)
            if ring { KK.hintBox(&pic, "hr", x: GX, y: G.row(j), w: G.W, h: 4) }
            if spot { pic.circle("hs", at: end, P.pic ? G.row(j) : AY + 0.4, radius: 1.3, .chapter, dashed: true) }
        case 2, 4:
            let j = row(P, st), L = G.len(P.c[j], s2)
            if ring { KK.hintBox(&pic, "hr", x: GX, y: G.row(j), w: L, h: P.pic ? 4 : AY - G.row(j)) }
        case 5:
            if ring { KK.hintBox(&pic, "hr", x: GX, y: min(G.row(P.x), G.row(P.y)), w: G.W, h: max(G.row(P.x), G.row(P.y)) + 4 - min(G.row(P.x), G.row(P.y))) }
        default: break
        }
        // the record, 3 rows under the graph: the rows read side by side, the sum or difference under them
        if st >= 2 {
            let e1 = M7.row(&rec, "r1", line(P, P.x, "x", right: st > 2), x: 0, line: 1)
            var e2 = 0.0
            if st >= 4 { e2 = M7.row(&rec, "r2", line(P, P.y, "y", right: st > 4), x: secondCol(P), line: 1) }
            var e3 = 0.0
            if st >= 5 { e3 = M7.row(&rec, "r3", opLine(P, right: st > 5), x: 0, line: 4) }
            if spot {
                if st == 2 { A1.note(&rec, "spot", "\(P.c[P.x])", x: e1 + 0.5, y: 1) }
                if st == 4 { A1.note(&rec, "spot", "\(P.c[P.y])", x: e2 + 0.5, y: 1) }
                if st == 5 { A1.note(&rec, "spot", "\(P.answer)", x: e3 + 0.5, y: 4) }
            }
        }
        let ext = pic.R(0, 0, GX + G.W + 2.5 + roomRight, AY + 3)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Graphs3.Parts(s.numbers), st = at(s), G = geo(s.numbers), GX = G.GX, AY = G.AY, s2 = P.s
        if st == 0 {
            return Hands(tap: { q in
                let onKey = P.pic ? (q.x >= GX && q.x <= GX + 18 && q.y >= AY - 0.6 && q.y <= AY + 2.6)
                    : (q.x >= GX - 1.5 && q.x <= GX + G.W + 1.5 && q.y >= AY - 0.4 && q.y <= AY + 2.6)
                if onKey { return HandMove(hand: [:], missHand: [:], set: [("k", 1)], check: true) }
                if q.x >= GX && q.x <= GX + G.W && q.y >= DK3.Graph.BY && q.y <= DK3.Graph.BY + 22.4 { return HandMove(hand: [:], missHand: [:], set: [("k", 0)], check: true) }
                return nil
            })
        }
        guard st == 1 || st == 3 else { return nil }
        let box = st == 1 ? "dx" : "dy", hs = P.hs
        func halves(_ x: Double) -> Int { max(0, min(16, Int(((x - GX) / (3 * Double(hs))).rounded()) * hs)) }
        func pics(_ x: Double) -> Int { max(0, min(18, Int(((x - GX) / 2).rounded()))) }
        return Hands(
            grab: { q in
                guard let j = G.rowAt(q), q.x >= GX - 2, q.x <= GX + G.W + 2 else { return nil }
                if P.pic { return ["grab": 1, "j": Double(j), "n": Double(pics(q.x))] }
                guard abs(q.x - GX - G.len(P.c[j], s2)) <= 3 else { return nil }
                return ["grab": 1, "j": Double(j), "h": Double(halves(q.x)), "py": q.y]
            },
            drag: { q, h in
                var h = h
                if P.pic { h["n"] = Double(pics(q.x)) } else { h["h"] = Double(halves(q.x)); h["py"] = q.y }
                return h
            },
            release: { h in
                let j = Int(h["j"] ?? 0)
                if P.pic {
                    let n = Int(h["n"] ?? 0)
                    guard n > 0 else { return HandMove(hand: [:]) }
                    return HandMove(hand: [:], missHand: [:], set: [(box, Double(Graphs3.code(row: j, n)))], check: true)
                }
                if (h["py"] ?? 0) < AY - 1.5 { return HandMove(hand: [:], missHand: [:], set: [(box, Double(Graphs3.notDown))], check: true) }
                return HandMove(hand: [:], missHand: [:], set: [(box, Double(Graphs3.code(row: j, Int(h["h"] ?? 0))))], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Graphs3.Parts(s.numbers), st = at(s), G = geo(s.numbers), GX = G.GX, AY = G.AY
        if st == 0 { return [.tap(.picture(CGPoint(x: P.pic ? GX + 2 : GX + 6, y: AY + 1)))] }
        guard st == 1 || st == 3 else { return [] }
        let j = row(P, st), yy = G.row(j) + 2, end = GX + G.len(P.c[j], P.s)
        if P.pic { return [.drag(from: CGPoint(x: GX + 0.6, y: yy), to: CGPoint(x: end, y: yy))] }
        return [.drag(from: CGPoint(x: end - 0.3, y: yy), to: CGPoint(x: end, y: AY + 0.4))]
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Graphs3.Parts(s.numbers), st = at(s)
        if st == 0 { return HandMove(hand: [:], missHand: [:], set: [("k", 0)], check: true) }
        guard st == 1 || st == 3 else { return nil }
        let j = row(P, st), T = P.halves(j), box = st == 1 ? "dx" : "dy"
        let n = P.pic ? (T > 1 ? T - 1 : T + 1) : (T + P.hs <= 16 ? T + P.hs : T - P.hs)
        return HandMove(hand: [:], missHand: [:], set: [(box, Double(Graphs3.code(row: j, n)))], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Graphs3.Parts(s.numbers), st = at(s)
        switch st {
        case 2:
            if P.pic { return ["x": Double(P.whole(P.x))] }
            return ["x": Double(P.half(P.x) ? P.whole(P.x) * P.s : P.c[P.y])]
        case 4: return ["y": Double(P.pic ? P.whole(P.y) : P.c[P.x])]
        case 5: return ["op": Double(P.ask == 1 ? P.a + P.b : abs(P.a - P.b))]
        default: return nil
        }
    }
}
