import SwiftUI

/// Draw a bar graph on the paper, as in the preview (design/prototype/grade3-ch7.html, dDraw): the empty graph with its
/// scale (or key); each row starts with its name and its count ("Dogs 35"). A bar is dragged out from the axis by its open
/// edge (half lines for scales of 2 and 10, whole lines for 5; "35 dogs" beside the graph); a picture row is tapped a
/// picture at a time (tap the last again: a half, for a key of 2; then gone; "4 pictures and a half · 9"). A row done turns
/// solid and is ticked. Then how many more or fewer (the dashed line and the bracket), `35 − 20 = [15]`, or two steps,
/// `35 + 20 = [55]` and `55 − 15 = [40]` beside it, 3 rows under the graph.
///
/// Kept: "n<j>" a row's units (half lines, whole lines or half pictures), "last" the row touched last (+ 1). Hand while a
/// bar is dragged: "grab", "j", "v".
@MainActor
struct DrawGraph3Lesson: PaperLesson {
    var liveKeys: Set<String> { ["v"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func geo(_ n: Numbers) -> DK3.Graph { DK3.Graph(type: DrawGraph3.Parts(n).type) }
    func recordRow(_ n: Numbers) -> Double? { DK3.Graph.RY - 1 }

    /// Each row's units as it is now (every row at its count once the drawing is done).
    private func units(_ s: PaperState, _ P: DrawGraph3.Parts) -> [Int] {
        var out: [Int] = []
        for j in 0..<4 { out.append(at(s) >= 1 ? P.units(j) : Int(s.run.kept["n\(j)"] ?? 0)) }
        return out
    }
    /// A row's drawn length in squares.
    private func length(_ P: DrawGraph3.Parts, _ n: Int) -> Double {
        if P.pic { return 4 * Double((n + 1) / 2) - (n % 2 == 1 ? 2 : 0) }
        return Double(n * P.unit)
    }
    private func opLine(_ P: DrawGraph3.Parts, right: Bool) -> [M7.Tok] {
        [.n(P.a), .op("−"), .n(P.b), .op("="), right ? .n(P.a - P.b, .chapter) : .box("op", cells: 2)]
    }
    private func sumLine(_ P: DrawGraph3.Parts, right: Bool) -> [M7.Tok] {
        [.n(P.a), .op("+"), .n(P.b), .op("="), right ? .n(P.sum, .chapter) : .box("sum", cells: 3)]
    }
    private func diffLine(_ P: DrawGraph3.Parts, right: Bool) -> [M7.Tok] {
        [.n(P.sum), .op("−"), .n(P.cz), .op("="), right ? .n(P.diff, .chapter) : .box("diff", cells: 3)]
    }
    private func diffCol(_ P: DrawGraph3.Parts) -> Double { EG2.ceil5(M7.width([.n(P.a), .op("+"), .n(P.b), .op("="), .n(100)]) + 3) }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = DrawGraph3.Parts(s.numbers), st = at(s), RY = DK3.Graph.RY
        guard st >= 1, P.ask > 0 else { return nil }
        if P.ask == 1 { return CGPoint(x: DK3.after(M7.width(opLine(P, right: st == 9))), y: RY - 1) }
        if st == 1 { return CGPoint(x: DK3.after(M7.width(sumLine(P, right: false))), y: RY - 1) }
        return CGPoint(x: DK3.after(diffCol(P) + M7.width(diffLine(P, right: st == 9))), y: RY - 1)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = DrawGraph3.Parts(s.numbers), st = at(s), G = geo(s.numbers), th = P.th, GX = G.GX, s2 = P.s, drawing = st == 0
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let n = units(s, P), heldJ: Int? = s.grabbed ? s.h("j").map { Int($0) } : nil
        DK3.base(&pic, G, th, s: s2)
        for j in 0..<4 {
            let y = G.row(j), yy = y + 2, ok = n[j] == P.units(j)
            pic.word("nm\(j)", th.names[j], at: 0, yy, DK3.say, anchor: UnitPoint(x: 0, y: 0.5))
            pic.word("ct\(j)", "\(P.c[j])", at: GX - 1.3, yy, DK3.say, anchor: UnitPoint(x: 1, y: 0.5))
            var lit = false
            if P.ask == 1 && st >= 1 { lit = j == P.x || j == P.y }
            if P.ask == 2 && st >= 1 { lit = st == 1 ? (j == P.x || j == P.y) : true }
            if P.pic {
                // the row's empty holder, dashed, until it's done
                if drawing && !ok { pic.sketch.box("hold\(j)", pic.R(GX, y, G.W, 4), .ink3, width: Sketch.stroke, dashed: true) }
                if drawing ? ok : lit { pic.fill("rt\(j)", col: GX, row: y, w: length(P, n[j]), h: 4, .tint(0.2)) }
                DK3.picRow(&pic, "p\(j)", G, j, n[j], th, s: s2, worth: false)
            } else if j == heldJ {
                let v = Int(s.h("v") ?? 0), e = GX + Double(v * P.unit)
                DK3.bar(&live, "b\(j)", G, j, Double(v * P.unit), strong: true)
                live.line("e\(j)", [(e, y), (e, y + 4)], .chapter)
                live.dot("eh\(j)", at: e, yy, radius: 0.7, .chapter, over: true)
            } else {
                DK3.bar(&pic, "b\(j)", G, j, Double(n[j] * P.unit), strong: drawing ? ok : lit)
                // the open edge with its dot, until the bar is done
                if drawing && !ok {
                    let e = GX + Double(n[j] * P.unit)
                    pic.line("e\(j):\(n[j])", [(e, y), (e, y + 4)], .chapter)
                    pic.dot("eh\(j):\(n[j])", at: e, yy, radius: 0.55, .chapter, over: true)
                }
            }
            if ok { DK2.tick(&pic, "tk\(j)", x: GX + length(P, n[j]) + 0.8, y: yy) }
        }
        // the readout beside the graph, level with the row
        if drawing {
            if let j = heldJ {
                let ro = P.readout(j, Int(s.h("v") ?? 0))
                DK3.readout(&live, ro, x: GX + G.W + 3, y: G.row(j) + 2); live.reads(ro)
            } else if let l = s.run.kept["last"], Int(l) > 0 {
                let j = Int(l) - 1
                if n[j] > 0 { DK3.readout(&pic, P.readout(j, n[j]), x: GX + G.W + 3, y: G.row(j) + 2) }
            }
        }
        if P.ask == 1 && st >= 1 { DK3.moreMarks(&pic, "mm", G, longer: P.x, shorter: P.y, G.len(P.a, s2), G.len(P.b, s2)) }
        // hints: a first miss rings the row to make, a second the place its end goes
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        if drawing, let j = (0..<4).first(where: { n[$0] != P.units($0) }) {
            if ring { KK.hintBox(&pic, "hr\(j)", x: GX, y: G.row(j), w: G.W, h: 4) }
            if spot { pic.circle("hs\(j)", at: GX + G.len(P.c[j], s2), G.row(j) + 2, radius: 1.3, .chapter, dashed: true) }
        }
        if st >= 1 && ring {
            let top = min(G.row(P.x), G.row(P.y)), bot = max(G.row(P.x), G.row(P.y)) + 4
            if P.ask == 2 && st == 2 { KK.hintBox(&pic, "hq", x: GX, y: G.row(P.z), w: G.len(P.cz, s2), h: 4) }
            else { KK.hintBox(&pic, "hq", x: GX, y: top, w: G.W, h: bot - top) }
        }
        // the record: 35 − 20 = [15], or 35 + 20 = [55] and 55 − 15 = [40] beside it
        if st >= 1 && P.ask > 0 {
            if P.ask == 1 {
                let e = M7.row(&rec, "r1", opLine(P, right: st == 9), x: 0, line: 1)
                if st == 1 && spot { A1.note(&rec, "spot", "\(P.a - P.b)", x: e + 0.5, y: 1) }
            } else {
                let e1 = M7.row(&rec, "r1", sumLine(P, right: st >= 2), x: 0, line: 1)
                if st == 1 && spot { A1.note(&rec, "spot", "\(P.sum)", x: e1 + 0.5, y: 1) }
                if st >= 2 {
                    let e2 = M7.row(&rec, "r2", diffLine(P, right: st == 9), x: diffCol(P), line: 1)
                    if st == 2 && spot { A1.note(&rec, "spot", "\(P.diff)", x: e2 + 0.5, y: 1) }
                }
            }
        }
        let ext = pic.R(0, 0, GX + G.W + (drawing ? (P.pic ? 20 : 11) : 0), G.AY + 3)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = DrawGraph3.Parts(s.numbers), G = geo(s.numbers), GX = G.GX
        guard at(s) == 0 else { return nil }
        let n = units(s, P)
        func allDone(_ j: Int, _ v: Int) -> Bool { (0..<4).allSatisfy { $0 == j ? v == P.units($0) : n[$0] == P.units($0) } }
        /// A row's new units judged: done (and maybe all done), past its count (a miss), or short (nothing yet).
        func judged(_ j: Int, _ v: Int, tapped: Bool) -> HandMove {
            let keep: Numbers = ["n\(j)": Double(v), "last": Double(j + 1)]
            let value = P.value(v)
            if value == P.c[j] { return HandMove(hand: [:], missHand: [:], set: allDone(j, v) ? [("r", Double(DrawGraph3.allMade))] : [], keep: keep, check: allDone(j, v)) }
            if value == 0 || (tapped && value < P.c[j]) { return HandMove(hand: [:], keep: keep) }
            let code = tapped ? DrawGraph3.tapCode(j, value) : DrawGraph3.dragCode(j, value)
            return HandMove(hand: [:], missHand: [:], set: [("r", Double(code))], keep: keep, check: true)
        }
        if P.pic {
            return Hands(tap: { q in
                guard let j = G.rowAt(q), q.x >= GX, q.x <= GX + G.W else { return nil }
                let k = n[j], lastX = GX + 4 * Double((k + 1) / 2) - 4, lastW = k % 2 == 1 ? 2.0 : 4.0
                if k > 0 && q.x >= lastX && q.x <= lastX + lastW {
                    let v = P.s == 2 && k % 2 == 0 ? k - 1 : k - (k % 2 == 1 ? 1 : 2)
                    return judged(j, max(0, v), tapped: true)
                }
                return judged(j, min(18, k % 2 == 1 ? k + 1 : k + 2), tapped: true)
            })
        }
        let maxN = 48 / P.unit
        return Hands(
            grab: { q in
                guard let j = G.rowAt(q), n[j] != P.units(j), abs(q.x - GX - Double(n[j] * P.unit)) <= 2.5 else { return nil }
                return ["grab": 1, "j": Double(j), "v": Double(n[j])]
            },
            drag: { q, h in var h = h; h["v"] = Double(max(0, min(maxN, Int(((q.x - GX) / Double(P.unit)).rounded())))); return h },
            release: { h in judged(Int(h["j"] ?? 0), Int(h["v"] ?? 0), tapped: false) })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = DrawGraph3.Parts(s.numbers), G = geo(s.numbers), GX = G.GX
        guard at(s) == 0 else { return [] }
        let n = units(s, P)
        var out: [GhostMove] = []
        for j in 0..<4 where n[j] != P.units(j) {
            let yy = G.row(j) + 2
            if P.pic {
                // (a row past its count: the last picture tapped away first; a key of 2 ends on a half by tapping the last)
                var k = n[j], u = P.units(j), guardSteps = 0
                func lastCell(_ k: Int) -> Double { GX + 4 * Double((k + 1) / 2) - 2 }
                while k != u && guardSteps < 40 {
                    guardSteps += 1
                    if k > u {
                        out.append(.tap(.picture(CGPoint(x: lastCell(k), y: yy))))
                        k = P.s == 2 && k % 2 == 0 ? k - 1 : k - (k % 2 == 1 ? 1 : 2)
                    } else {
                        let next = min(18, k % 2 == 1 ? k + 1 : k + 2)
                        out.append(.tap(.picture(CGPoint(x: lastCell(next), y: yy)))); k = next
                    }
                }
            } else {
                out.append(.drag(from: CGPoint(x: GX + Double(n[j] * P.unit), y: yy), to: CGPoint(x: GX + Double(P.units(j) * P.unit), y: yy)))
            }
        }
        return out
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = DrawGraph3.Parts(s.numbers)
        guard at(s) == 0 else { return nil }
        let j = 0, u = P.units(j), v = P.pic && P.s != 2 ? u + 2 : u + 1
        let code = P.pic ? DrawGraph3.tapCode(j, P.value(v)) : DrawGraph3.dragCode(j, P.value(v))
        return HandMove(hand: [:], missHand: [:], set: [("r", Double(code))], keep: ["n\(j)": Double(v), "last": Double(j + 1)], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = DrawGraph3.Parts(s.numbers), st = at(s)
        guard st >= 1, st < 9 else { return nil }
        if P.ask == 1 { return ["op": Double(P.a + P.b)] }
        return st == 1 ? ["sum": Double(abs(P.a - P.b))] : ["diff": Double(P.sum + P.cz)]
    }
}
