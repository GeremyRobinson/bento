import SwiftUI

/// Inequalities on the paper, as in the preview (design/prototype/grade6-ch6.html, dIneq): the story's rule written as
/// the picture's name ("You must be older than 8."), and under it a line two squares a one, 20 ones around the story's
/// number. Drag the circle onto the number (tap it to fill it in or leave it open); drag the arrow out of the circle along
/// the line and off its end (the numbers it passes light, the band shades); tap the test numbers that work (each lights on
/// the line); pick the sign and write the number: x > 8.
///
/// The picture's squares: the story on row 1, the line on row `LY`, the test cards on `TY`. Hand keys: "c" (the circle's
/// place), "h" (1 the circle held, 2 the arrow), "tip" (the arrow's end; past the line's end it's hi + 1 or lo − 1),
/// "ok" (the ray let go right, the circle still to fix), "lit" (the cards tapped, bits), "bad" (a card that doesn't work).
@MainActor
struct InequalitiesLesson: PaperLesson {
    static let LY = 4.0, TY = 8.0, CW = 6.0, CG = 2.0
    var liveKeys: Set<String> { ["grab", "c", "h", "tip", "from"] }
    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    static func line(_ P: Ineq6.Parts) -> N6.Line { N6.Line(x0: 2 - 2 * P.lo, y0: LY, U: 2, lo: P.lo, hi: P.hi) }
    static func cardX(_ j: Int) -> Double { 2 + Double(j) * (CW + CG) }
    /// Where the circle waits before it's dragged: 6 from the number, on the line.
    static func start(_ P: Ineq6.Parts) -> Double { P.n + 6 <= P.hi - 1 ? P.n + 6 : P.n - 6 }
    private func filled(_ s: PaperState) -> Bool { (s.run.kept["fill"] ?? 0) == 1 }

    func recordRow(_ n: Numbers) -> Double? { Self.TY + 5 }
    func keysFocus(_ s: PaperState) -> CGRect? {
        let P = Ineq6.Parts(s.numbers), N = Self.line(P), c = N.at(P.n)
        return stage(s) == 5 ? CGRect(x: c.x - 6, y: Self.LY - 1, width: 12, height: 3) : nil
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Ineq6.Parts(s.numbers), at = stage(s), N = Self.line(P), LY = Self.LY
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let X0 = N.at(P.lo).x, X1 = N.at(P.hi).x
        let heldC = at == 1 && s.grabbed && s.h("h") == 1, heldR = at == 2 && s.grabbed && s.h("h") == 2
        let c = at >= 2 ? P.n : s.h("c") ?? Self.start(P), C = N.at(c)
        // the ray: the child's while it's made, then for good off the line's end
        let tip: Double? = at >= 3 ? (P.big ? P.hi + 1 : P.lo - 1) : at == 2 ? s.h("tip") : nil
        let rayLive = at == 2

        pic.word("story", P.story, at: 0, 1, E6.words, anchor: UnitPoint(x: 0, y: 0.5))
        N.draw(&pic, "nl", labels: [])
        // the band from the circle to the arrow's end, running off the line's end with an arrow
        if let t = tip, t != P.n {
            let tx = t > P.hi ? X1 + 1 : t < P.lo ? X0 - 1 : N.at(t).x, a = min(C.x, tx), b = max(C.x, tx)
            if rayLive { live.fill("band", col: a, row: LY - 0.5, w: b - a, h: 1, .tint(0.42)) } else { pic.fill("band", col: a, row: LY - 0.5, w: b - a, h: 1, .tint(0.42)) }
            if t > P.hi || t < P.lo {
                let ax = t > P.hi ? X1 + 1 : X0 - 1, sd = t > P.hi ? 1.0 : -1.0, pts = [(ax - 0.8 * sd, LY - 0.8), (ax, LY), (ax - 0.8 * sd, LY + 0.8)]
                if rayLive { live.line("ra", pts, .chapter) } else { pic.line("ra\(sd)", pts, .chapter) }
            }
        }
        // the line's numbers: every one (every other from the story's number when two-digit negatives crowd it), lit
        // where the band passes or under the circle being held
        func inBand(_ v: Double) -> Bool {
            guard let t = tip, v != P.n else { return false }
            return (t > P.n && v > P.n && v <= t) || (t < P.n && v < P.n && v >= t)
        }
        let wide = P.lo <= -10
        var lits: [(Double, Bool)] = []
        for v in stride(from: P.lo, through: P.hi, by: 1) where !wide || Int((v - P.n).rounded()) % 2 == 0 {
            lits.append((v, inBand(v) || (heldC && v == c)))
        }
        for (v, on) in lits {
            let p = N.at(v)
            if on && (rayLive || heldC) { live.label("nlv\(fmt(v))", fmt(v), E6.lit, .below, edge: LY + 0.5, along: p.x) }
            else { pic.label("nl\(fmt(v))\(on)", fmt(v), on ? E6.lit : E6.small, .below, edge: LY + 0.5, along: p.x) }
        }
        // the circle: open (paper inside) or filled
        if heldC { N6.point(&live, "circ", C, shade: filled(s) ? 0 : 2, held: true); live.reads(fmt(c)) }
        // over the band being dragged out of it
        else if at == 2 { N6.point(&live, "circ\(filled(s))", C, shade: filled(s) ? 0 : 2) }
        else { N6.point(&pic, "circ\(filled(s))", C, shade: filled(s) ? 0 : 2) }
        if at == 2, let t = tip, t != P.n, (s.h("ok") ?? 0) == 0 {
            let tx = t > P.hi ? X1 + 2 : t < P.lo ? X0 - 2 : N.at(t).x
            R6.handle(&live, "rh", tx, LY, held: heldR)
            if heldR { live.reads(t > P.hi || t < P.lo ? "every \(P.noun) \(P.big ? "past" : "under") \(P.N)" : fmt(t)) }
        }
        // the test numbers that work, lit on the line; the cards
        let lit: Int = at == 3 ? Int(s.h("lit") ?? 0) : at > 3 ? P.working.reduce(0) { $0 | 1 << $1 } : 0
        for j in P.tests.indices where lit & (1 << j) != 0 {
            let p = N.at(P.tests[j])
            pic.dot("lit\(j)", at: p.x, p.y, radius: 0.4, at == 3 ? Bars.green : .chapter, over: true)
        }
        if at >= 3 {
            for (j, v) in P.tests.enumerated() {
                let on = lit & (1 << j) != 0, bad = at == 3 && s.h("bad") == Double(j)
                let style: Sketch.Block = bad ? Sketch.Block(stroke: Bars.red, text: Bars.red)
                    : on ? (at == 3 ? Sketch.Block(stroke: Bars.green, text: Bars.green) : Sketch.Block(stroke: .chapter, text: .chapter)) : .main
                pic.sketch.block("tv\(j)\(on)\(bad)", pic.R(Self.cardX(j), Self.TY, Self.CW, 2), style, centred: P.hs(v), size: Sketch.wordSize)
            }
        }

        // hints: a first miss rings the general area, a second the exact spot (call of 3 Nov)
        let E = N.at(P.big ? P.hi : P.lo)
        switch at {
        case 1:
            if s.on("ring") { let p = N.at(P.n); R6.ring(&pic, "ring", x: p.x - 6, y: LY - 1, w: 12, h: 3) }
            if s.on("spot") { let p = N.at(P.n); pic.circle("spot", at: p.x, p.y, radius: 1.3, .chapter, dashed: true) }
        case 2:
            let p = N.at(P.n)
            if s.on("ring") { R6.ring(&pic, "ring", x: min(p.x, E.x), y: LY - 1, w: abs(E.x - p.x), h: 3) }
            if s.on("spot") { pic.circle("spot", at: E.x + (P.big ? 2 : -2), LY, radius: 1.3, .chapter, dashed: true); pic.circle("spotc", at: p.x, p.y, radius: 1.3, .chapter, dashed: true) }
        case 3:
            let p = N.at(P.n)
            if s.on("ring") { R6.ring(&pic, "ring", x: min(p.x, E.x), y: LY - 1, w: abs(E.x - p.x), h: 3) }
            if s.on("spot") { for j in P.working { pic.sketch.box("spot\(j)", pic.R(Self.cardX(j) - 0.5, Self.TY - 0.5, Self.CW + 1, 3), .chapter, width: Sketch.stroke, dashed: true) } }
        case 4, 5:
            let p = N.at(P.n)
            if s.on("ring") { pic.circle("ring", at: p.x, p.y, radius: 1.3, .chapter, dashed: true) }
            if s.on("spot") { R6.ring(&pic, "spot", x: min(p.x, E.x), y: LY - 1, w: abs(E.x - p.x) + 2, h: 3) }
        default: break
        }

        // the record: x, the sign, the number
        if at >= 4 {
            let sign: M7.Tok = at == 4 ? .gap(1) : .op(P.S, at > 5 ? .chapter : .ink)
            let num: M7.Tok = at == 5 ? .box("x", cells: max(2, P.N.count)) : at > 5 ? .t(P.N, .chapter) : .gap(0)
            M7.row(&rec, "r", [.t("x"), sign, num], x: 0, line: 1)
            if at == 4 { rec.sketch.box("slot", rec.R(2, 0, 2, 2), .ink3, width: Sketch.stroke) }
        }
        let ext = pic.R(-1, -1, X1 + 5, Self.TY + 3)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Ineq6.Parts(s.numbers), N = Self.line(P), at = stage(s), LY = Self.LY
        let X0 = N.at(P.lo).x, X1 = N.at(P.hi).x, fill = filled(s)
        let c = at >= 2 ? P.n : s.h("c") ?? Self.start(P), C = N.at(c)
        func onCircle(_ q: CGPoint) -> Bool { abs(q.x - C.x) < 1.6 && abs(q.y - LY) < 2 }
        // the ray as it stands, let go: right, the wrong way, short of the end, or the circle to fix
        func ray(_ t: Double, fill: Bool) -> Double {
            if (t > P.n) != P.big { return Double(Ineq6.Parts.rayWrongWay) }
            if t <= P.hi && t >= P.lo { return Double(Ineq6.Parts.rayShort) }
            if fill == P.strict { return Double(P.strict ? Ineq6.Parts.rayFilled : Ineq6.Parts.rayOpen) }
            return Double(Ineq6.Parts.rayRight)
        }
        switch at {
        case 1:
            return Hands(tap: { q in onCircle(q) ? HandMove(hand: s.hand, keep: ["fill": fill ? 0 : 1]) : nil },
                         grab: { q in onCircle(q) ? ["grab": 1, "h": 1, "c": c, "from": c] : nil },
                         drag: { q, h in var h = h; h["c"] = N.val(q); return h },
                         release: { h in
                             // (the hands are asked again as the finger moves: where it started is in the hand)
                             let v = h["c"] ?? c
                             if v == h["from"] { return HandMove(hand: ["c": v]) }
                             return HandMove(hand: ["c": v], missHand: ["c": v], set: [("c", v)], check: true)
                         })
        case 2:
            let tip = s.h("tip"), ok = (s.h("ok") ?? 0) == 1
            return Hands(tap: { q in
                guard onCircle(q) else { return nil }
                let f = !fill
                // the ray already let go right: the circle fixed checks it again
                if ok, let t = tip { return HandMove(hand: ["tip": t, "ok": 1], missHand: ["tip": t, "ok": 1], set: [("r", ray(t, fill: f))], keep: ["fill": f ? 1 : 0], check: true) }
                return HandMove(hand: s.hand, keep: ["fill": f ? 1 : 0])
            }, grab: { q in
                if let t = tip, t != P.n {
                    let tx = t > P.hi ? X1 + 2 : t < P.lo ? X0 - 2 : N.at(t).x
                    if abs(q.x - tx) < 1.8 && abs(q.y - LY) < 2 { return ["grab": 1, "h": 2, "tip": t] }
                }
                return onCircle(q) && !ok ? ["grab": 1, "h": 2, "tip": P.n] : nil
            }, drag: { q, h in
                var h = h; h["tip"] = q.x > X1 + 0.6 ? P.hi + 1 : q.x < X0 - 0.6 ? P.lo - 1 : N.val(q); return h
            }, release: { h in
                guard let t = h["tip"], t != P.n else { return HandMove(hand: [:]) }
                let r = ray(t, fill: fill)
                let keepRay = r == Double(Ineq6.Parts.rayFilled) || r == Double(Ineq6.Parts.rayOpen)
                return HandMove(hand: ["tip": t], missHand: keepRay ? ["tip": t, "ok": 1] : [:], set: [("r", r)], check: true)
            })
        case 3:
            let lit = Int(s.h("lit") ?? 0)
            return Hands(tap: { q in
                guard q.y >= Self.TY - 0.5, q.y <= Self.TY + 2.5,
                      let j = P.tests.indices.first(where: { q.x >= Self.cardX($0) - 0.5 && q.x <= Self.cardX($0) + Self.CW + 0.5 }) else { return nil }
                if lit & (1 << j) != 0 { return nil }
                guard P.works(P.tests[j]) else { return HandMove(hand: ["lit": Double(lit), "bad": Double(j)], missHand: ["lit": Double(lit), "bad": Double(j)], set: [("t", -Double(j + 1))], check: true) }
                let now = lit | 1 << j
                if P.working.allSatisfy({ now & (1 << $0) != 0 }) { return HandMove(hand: ["lit": Double(now)], missHand: ["lit": Double(now)], set: [("t", Double(P.working.count))], check: true) }
                return HandMove(hand: ["lit": Double(now)])
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Ineq6.Parts(s.numbers), N = Self.line(P), LY = Self.LY
        switch stage(s) {
        case 1:
            let c = s.h("c") ?? Self.start(P)
            var m: [GhostMove] = [.drag(from: N.at(c), to: N.at(P.n))]
            // filled for at least and at most
            if ((s.run.kept["fill"] ?? 0) == 1) == P.strict { m.append(.tap(.picture(N.at(P.n)))) }
            return m
        case 2:
            let end = P.big ? N.at(P.hi).x + 3 : N.at(P.lo).x - 3
            var m: [GhostMove] = []
            if ((s.run.kept["fill"] ?? 0) == 1) == P.strict { m.append(.tap(.picture(N.at(P.n)))) }
            m.append(.drag(from: N.at(P.n), to: CGPoint(x: end, y: LY)))
            return m
        case 3:
            let lit = Int(s.h("lit") ?? 0)
            return P.working.filter { lit & (1 << $0) == 0 }.map { .tap(.picture(CGPoint(x: Self.cardX($0) + Self.CW / 2, y: Self.TY + 1))) }
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Ineq6.Parts(s.numbers)
        switch stage(s) {
        case 1: let v = P.n + (P.n + 2 <= P.hi ? 2 : -2); return HandMove(hand: ["c": v], missHand: ["c": v], set: [("c", v)], check: true)
        case 2: return HandMove(hand: [:], missHand: [:], set: [("r", Double(Ineq6.Parts.rayWrongWay))], check: true)
        case 3:
            let j = P.tests.firstIndex(of: P.n) ?? 0, bad = P.works(P.n) ? P.tests.indices.first { !P.works(P.tests[$0]) } ?? j : j
            return HandMove(hand: ["lit": 0, "bad": Double(bad)], missHand: ["lit": 0, "bad": Double(bad)], set: [("t", -Double(bad + 1))], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Ineq6.Parts(s.numbers)
        return stage(s) == 5 ? ["x": P.n + 1] : nil
    }
}
