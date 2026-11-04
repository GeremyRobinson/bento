import SwiftUI

/// Angles add up on the paper, as in the preview (design/prototype/grade4-ch8.html): the corner on a grid point; a right
/// angle's arms along grid lines, 20 squares long, or a straight line 40 across. The part we know is drawn inside with
/// its arc and its size, the missing part's arc dashed with ?. Drag the page corner onto it (one fits a right angle;
/// two side by side fit the straight line: "a square corner: 90°", "two square corners: 180°" beside it), then type the
/// missing part (35° + [55]° = 90°); its arc fills and is named. The fold: a measured whole, read with the protractor
/// first (arms 18 squares, the protractor beside them); or both parts given and the whole typed.
///
/// The picture's squares: the corner at the bottom of the arms, from (0, 0); the record beside it or under it.
@MainActor
struct AnglesAddLesson: PaperLesson {
    typealias Pt = Geo4.Pt
    var liveKeys: Set<String> { ["px", "py"] }

    @MainActor struct Q {
        let p: AnglesAdd.Parts
        let AR: Double, C: Pt, r: Double, pcRest: Pt, prRest: Pt
        init(_ n: Numbers) {
            p = AnglesAdd.Parts(n)
            AR = p.fold == 1 ? ProtractorLesson.ARM : 20
            let wideLeft = p.st || p.T > 90
            C = Pt(wideLeft ? AR : 0, AR)
            r = C.x + AR
            pcRest = Pt(r + 3, 7); prRest = Pt(r + 2 + ProtractorLesson.PR, C.y)
        }
        /// The page corners laid on it, at this stage.
        func laid(_ at: Int) -> Int { p.fold != 0 ? 0 : p.st ? (at >= 4 ? 2 : at == 2 ? 1 : 0) : (at >= 4 ? 1 : 0) }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = Q(s.numbers), p = q.p, at = G8.stage(s), C = q.C, AR = q.AR, done = at >= 5
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let held = s.grabbed, T = Double(p.T), a = Double(p.a)
        func lab(_ id: String, _ t: String, _ from: Double, _ to: Double, _ c: Sketch.Colour) {
            let m = (from + to) / 2, rr = to - from < 25 ? 12.0 : 9, w = Geo4.pol(C, rr, m)
            pic.word(id, t, at: w.x, w.y, G8.say.colour(c))
        }
        for i in 0..<q.laid(at) { G8.pageCorner(&pic, "pc\(i)", at: C, 90 * Double(i)) }
        if p.fold == 1 && at == 3 { G8.protractor(&pic, "pr", C, ProtractorLesson.PR, use: "R") }
        if done && p.miss != nil { G8.wedge(&pic, "mfill", C, 6, a, T) }
        if done && p.fold == 2 { G8.wedge(&pic, "mfill", C, 6, 0, T) }
        G8.seg(&pic, "armR", C, Geo4.pol(C, AR, 0))
        if p.st { G8.seg(&pic, "armL", C, Geo4.pol(C, AR, 180)) } else { G8.seg(&pic, "arm2", C, Geo4.pol(C, AR, T)) }
        G8.seg(&pic, "part", C, Geo4.pol(C, AR, a), p.fold == 2 ? .ink : .ink2)
        let showPart = p.fold != 1 || at >= 4
        G8.arc(&pic, "arcA", C, 5, 0, a)
        if showPart { lab("labA", "\(p.a)°", 0, a, .chapter) }
        if p.fold == 2 {
            G8.arc(&pic, "arcB", C, 5, a, T); lab("labB", "\(p.b)°", a, T, .chapter)
            G8.arc(&pic, "arcT\(done)", C, 12, 0, T, done ? .chapter : .ink2, dashed: !done)
            let w = Geo4.pol(C, 13.6 + (done ? 1.4 : 0), T / 2)
            pic.word("labT", done ? "\(p.T)°" : "?", at: w.x, w.y, G8.say.colour(done ? .chapter : .ink))
        } else {
            G8.arc(&pic, "arcM\(done)", C, 5, a, T, done ? .chapter : .ink2, dashed: !done)
            if showPart { lab("labM\(done)", done ? "\(p.ans)°" : "?", a, T, done ? .chapter : .ink) }
        }
        pic.dot("C", at: C.x, C.y, radius: 0.35, .ink, over: true)
        if p.fold == 0 && (at == 1 || at == 2) {
            let c = Pt(s.h("px") ?? q.pcRest.x, s.h("py") ?? q.pcRest.y)
            if held { G8.pageCorner(&live, "pcr", at: c, 0) } else { G8.pageCorner(&pic, "pcr", at: c, 0) }
        }
        if p.fold == 1 && at == 1 {
            let c = Pt(s.h("px") ?? q.prRest.x, s.h("py") ?? q.prRest.y)
            if held { G8.protractor(&live, "prr", c, ProtractorLesson.PR, use: nil) } else { G8.protractor(&pic, "prr", c, ProtractorLesson.PR, use: nil) }
        }
        // a hint after a second miss: the corner the tool goes on, or where the arm crosses the scale
        if (at == 1 || at == 2) && s.on("spot") { pic.circle("spot", at: C.x, C.y, radius: 1.5, .chapter, dashed: true) }
        if at == 3 && s.on("spot") { let g = Geo4.pol(C, ProtractorLesson.PR - 2.3, T); pic.circle("spot", at: g.x, g.y, radius: 1.5, .chapter, dashed: true) }
        // what the page corners showed, beside it
        if p.fold == 0 && at >= 2 && !(p.st && at == 1) {
            G8.aside(&pic, "fd", p.st && at >= 4 ? "two square corners: 180°" : "a square corner: 90°", x: q.pcRest.x, y: 9, w: 12)
        }

        // the record, a row at a time
        var rows: [[M7.Tok]] = []
        let box: (String) -> [M7.Tok] = { [.box($0, cells: 3), .op("°")] }
        if p.fold == 1 && at == 3 { rows.append([.w("whole"), .op("=")] + box("W")) }
        if p.fold == 1 && at >= 4 { rows.append([.w("whole"), .op("="), .t("\(p.T)°")]) }
        if at == 4 { rows.append(p.fold == 2 ? [.t("\(p.a)°"), .op("+"), .t("\(p.b)°"), .op("=")] + box("R") : [.t("\(p.a)°"), .op("+")] + box("R") + [.op("="), .t("\(p.T)°")]) }
        if done { rows.append(p.fold == 2 ? [.t("\(p.a)°"), .op("+"), .t("\(p.b)°"), .op("="), .t("\(p.T)°", .chapter)]
                              : [.t("\(p.T)°"), .op("−"), .t("\(p.a)°"), .op("="), .t("\(p.ans)°", .chapter)]) }
        for (i, r) in rows.enumerated() { M7.row(&rec, "rr\(i)\(r.count)", r, x: 0, line: 2 + 3 * Double(i)) }
        let right = p.fold == 1 ? q.prRest.x + ProtractorLesson.PR : q.pcRest.x + (p.fold == 0 ? 12 : 0)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, right, C.y))
    }

    func recordBeside(_ n: Numbers) -> Double? { 1 }
    func recordRow(_ n: Numbers) -> Double? { Q(n).C.y + 1 }

    func hands(_ s: PaperState) -> Hands? {
        let q = Q(s.numbers), p = q.p, at = G8.stage(s), C = q.C
        if p.fold == 0 && (at == 1 || at == 2) {
            let c = Pt(s.h("px") ?? q.pcRest.x, s.h("py") ?? q.pcRest.y)
            return Hands(grab: { g in
                G8.inPC(G8.pt(g), at: c, 0) ? ["grab": 1, "ox": g.x - c.x, "oy": g.y - c.y, "px": c.x, "py": c.y, "fx": c.x, "fy": c.y] : nil
            }, drag: { g, h in
                var h = h; h["px"] = g.x - (h["ox"] ?? 0); h["py"] = g.y - (h["oy"] ?? 0); return h
            }, release: { h in
                let to = Pt(h["px"] ?? c.x, h["py"] ?? c.y)
                if Geo4.dist(to, Pt(h["fx"] ?? c.x, h["fy"] ?? c.y)) < 0.5 { return HandMove(hand: [:]) }
                return HandMove(hand: [:], missHand: [:], set: [("k", Geo4.dist(to, C) <= 2.5 ? 1 : 0)], check: true)
            })
        }
        if p.fold == 1 && at == 1 {
            let c = Pt(s.h("px") ?? q.prRest.x, s.h("py") ?? q.prRest.y)
            return Hands(grab: { g in
                G8.onProtractor(G8.pt(g), c, ProtractorLesson.PR) ? ["grab": 1, "ox": g.x - c.x, "oy": g.y - c.y, "px": c.x, "py": c.y, "fx": c.x, "fy": c.y] : nil
            }, drag: { g, h in
                var h = h; h["px"] = g.x - (h["ox"] ?? 0); h["py"] = g.y - (h["oy"] ?? 0); return h
            }, release: { h in
                let to = Pt(h["px"] ?? c.x, h["py"] ?? c.y)
                if Geo4.dist(to, Pt(h["fx"] ?? c.x, h["fy"] ?? c.y)) < 0.5 { return HandMove(hand: [:]) }
                return HandMove(hand: [:], missHand: [:], set: [("p", Geo4.dist(to, C) <= 2.5 ? 1 : 0)], check: true)
            })
        }
        return nil
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = Q(s.numbers), p = q.p, at = G8.stage(s), C = q.C
        if p.fold == 0 && (at == 1 || at == 2) {
            let c = Pt(s.h("px") ?? q.pcRest.x, s.h("py") ?? q.pcRest.y)
            return [.drag(from: CGPoint(x: c.x + 3, y: c.y - 3), to: CGPoint(x: C.x + 3, y: C.y - 3))]
        }
        if p.fold == 1 && at == 1 {
            let c = Pt(s.h("px") ?? q.prRest.x, s.h("py") ?? q.prRest.y)
            return [.drag(from: CGPoint(x: c.x, y: c.y - 3), to: CGPoint(x: C.x, y: C.y - 3))]
        }
        return []
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let p = AnglesAdd.Parts(s.numbers), at = G8.stage(s)
        if p.fold == 0 && (at == 1 || at == 2) { return HandMove(hand: [:], missHand: [:], set: [("k", 0)], check: true) }
        if p.fold == 1 && at == 1 { return HandMove(hand: [:], missHand: [:], set: [("p", 0)], check: true) }
        return nil
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let p = AnglesAdd.Parts(s.numbers)
        switch G8.stage(s) {
        case 3: return ["W": Double(180 - p.T)]
        case 4: return ["R": p.fold == 2 ? Double(abs(p.a - p.b)) : Double(p.T + p.a)]
        default: return nil
        }
    }
}
