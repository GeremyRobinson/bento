import SwiftUI

/// Equal fractions on the paper, as in the preview (design/prototype/grade3-ch5.html, dEquiv, dWholes). Same point: two lines
/// 0 to 1, 48 squares, six rows apart; the top cut in b with its point at a/b, named over it; the bottom cut in d with a
/// point at 0. Drag the point under a/b: it snaps to the bottom's ticks, "5 eighths" beside it, and a dashed line drops
/// from the top point as it nears. Write `3/4 = [6]/[8]` under the lines; both points ring, the coarser cuts drop dashed
/// across and each coarser piece says how many finer ones it holds ("2 eighths"). Wholes: one line 0 to 2 (a whole of 24)
/// or 0 to 4 in wholes (12 each); hop from 0 to the point, write `2 = [8]/[4]`; the point is named 8/4.
///
/// Hand: same point "grab", "m" the bottom point's tick; wholes "grab", "n" the hops.
@MainActor
struct Equiv3Lesson: PaperLesson {
    static let Y1 = 4.0, Y2 = 10.0, LY = 7.0, W = Double(Fr3.whole)
    var liveKeys: Set<String> { ["m", "n"] }
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func messageRows(_ n: Numbers) -> Int { 2 }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Equiv3.Parts(s.numbers)
        return P.kind == 1 ? wholes(s, P) : same(s, P)
    }

    private func same(_ s: PaperState, _ P: Equiv3.Parts) -> PaperDrawing {
        let st = at(s), Y1 = Self.Y1, Y2 = Self.Y2, t1 = Double(P.t1), t2 = Double(P.t2), X1 = Double(P.a) * t1
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let ring = s.on("ring") || s.on("spot"), spot = s.on("spot")
        let m = st == 0 ? Int((s.h("m") ?? 0).rounded()) : P.c, X2 = Double(m) * t2
        F3L.line(&pic, "A", y: Y1, wholes: 1, per: Self.W, b: P.b, above: true)
        F3L.line(&pic, "B", y: Y2, wholes: 1, per: Self.W, b: P.d)
        pic.dot("pA", at: X1, Y1, radius: 0.5, .chapter, over: true)
        pic.label("pAn", "\(P.a)/\(P.b)", F3P.smallLit, .above, edge: Y1 - 1.6, along: X1)
        // a dashed line drops from the top point as the bottom one nears it
        if st != 0 || abs(X2 - X1) <= t2 + 0.01 {
            if st == 0 { live.line("drop", [(X1, Y1 + 0.6), (X1, Y2 - 0.6)], .ink2, dashed: true) }
            else { pic.line("drop", [(X1, Y1 + 0.6), (X1, Y2 - 0.6)], .ink2, dashed: true) }
        }
        if st == 0 {
            live.dot("pB", at: X2, Y2, radius: s.grabbed ? 0.7 : 0.55, .ink, over: true)
            let t = "\(m) \(Fr3.pname(m, P.d))"
            if m > 0 { F3P.beside(&live, "ro\(m)", t, x: Self.W + 1.5, y: Y2) }
            if s.grabbed { live.reads(t) }
            if ring { KK.hintBox(&pic, "hr", x: Double(P.a - 1) * t1, y: Y2 - 2, w: t1, h: 2) }
            if spot { pic.circle("hs", at: X1, Y2, radius: 1.3, .chapter, dashed: true) }
        } else {
            pic.dot("pB", at: X2, Y2, radius: 0.5, .chapter, over: true)
        }
        if st == 1 {
            if ring { KK.hintBox(&pic, "hr", x: 0, y: Y2 - 2, w: X1, h: 2) }
            if spot { for i in 1...P.c { pic.label("hs\(i)", "\(i)", F3P.smallLit, .below, edge: Y2 + 2, along: (Double(i) - 0.5) * t2) } }
        }
        if st == 9 {
            pic.circle("rA", at: X1, Y1, radius: 0.95, .chapter); pic.circle("rB", at: X2, Y2, radius: 0.95, .chapter)
            // (See) the coarser cuts drop across, and each coarser piece holds D/B of the finer ones
            let B = min(P.b, P.d), D = max(P.b, P.d), wB = Self.W / Double(B), cy = (Y1 + Y2) / 2
            for i in 1..<max(1, B) where abs(Double(i) * wB - X1) > 0.01 { pic.line("dd\(i)", [(Double(i) * wB, Y1 + 0.6), (Double(i) * wB, Y2 - 0.6)], .ink3, dashed: true) }
            for i in 0..<B {
                pic.sketch.delay = 0.3 + Double(i) * 0.2
                pic.word("gp\(i)", "\(D / B) \(Fr3.pname(2, D))", at: (Double(i) + 0.5) * wB, cy, F3P.smallLit)
            }
            pic.sketch.delay = 0
        }
        if st >= 1 { F3P.record(&rec, "rec", [.f(P.a, P.b)], top: "t", bottom: "b", (P.c, P.d), right: st == 9, x: 0, line: Y2 + 7) }
        let ext = pic.R(0, 0, Self.W + (st == 0 ? 10 : 0), Y2 + 2)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    private func wholes(_ s: PaperState, _ P: Equiv3.Parts) -> PaperDrawing {
        let st = at(s), LY = Self.LY, ts = Double(P.ts), per = Double(P.per), xp = Double(P.n) * per
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let ring = s.on("ring") || s.on("spot"), spot = s.on("spot"), n = Int((s.h("n") ?? 0).rounded())
        F3L.line(&pic, "nl", y: LY, wholes: P.Lw, per: per, b: P.b)
        if st == 0 {
            F3L.hops(&live, "h", y: LY, ts: ts, n: n)
            F3L.handle(&live, x: Double(n) * ts, y: LY, held: s.grabbed)
            if n > 0 { F3P.beside(&live, "ro\(n)", Fr3.plural(n, "hop", "hops"), x: Self.W + 1.5, y: LY) }
            if s.grabbed { live.reads(Fr3.plural(n, "hop", "hops")) }
            if ring { KK.hintBox(&pic, "hr", x: xp - per, y: LY - 4, w: per, h: 4) }
            if spot { pic.circle("hs", at: xp, LY, radius: 1.3, .chapter, dashed: true) }
        } else if st == 1 {
            F3L.hops(&pic, "h", y: LY, ts: ts, n: P.A)
            if ring { KK.hintBox(&pic, "hr", x: 0, y: LY - 4, w: per, h: 4) }
            if spot { for i in 1...P.b { pic.label("hs\(i)", "\(i)", F3P.smallLit, .below, edge: LY + 2, along: (Double(i) - 0.5) * ts) } }
        }
        pic.dot("pt\(st == 9)", at: xp, LY, radius: 0.5, st == 9 ? .chapter : .ink, over: true)
        if st == 9 {
            pic.circle("ringP", at: xp, LY, radius: 0.95, .chapter)
            pic.word("tnA", "\(P.A)/\(P.b)", at: xp, LY - 2.45, F3P.smallLit)
        }
        if st >= 1 { F3P.record(&rec, "rec", [.n(P.n)], top: "t", bottom: "b", (P.A, P.b), right: st == 9, x: 0, line: LY + 7) }
        let ext = pic.R(0, LY - 4.5, Self.W + (st == 0 ? 8 : 0), 6.5)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Equiv3.Parts(s.numbers)
        guard at(s) == 0 else { return nil }
        if P.kind == 1 { return F3L.hands(s, y: Self.LY, ts: Double(P.ts), max: P.Lw * P.b, key: "h", want: P.A) }
        let t2 = Double(P.t2), Y2 = Self.Y2, m0 = Int((s.h("m") ?? 0).rounded())
        return Hands(
            grab: { q in abs(q.x - Double(m0) * t2) <= 2.5 && abs(q.y - Y2) <= 2.5 ? ["grab": 1, "m": Double(m0)] : nil },
            drag: { q, h in var h = h; h["m"] = Double(max(0, min(P.d, Int((q.x / t2).rounded())))); return h },
            release: { h in
                let m = Int((h["m"] ?? 0).rounded())
                guard m != m0, m > 0 else { return HandMove(hand: ["m": Double(m)]) }
                return HandMove(hand: ["m": Double(m)], missHand: ["m": Double(m)], set: [("m", Double(m))], check: true)
            })
    }
    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Equiv3.Parts(s.numbers)
        guard at(s) == 0 else { return [] }
        if P.kind == 1 {
            let n = (s.h("n") ?? 0).rounded(), ts = Double(P.ts)
            return [.drag(from: CGPoint(x: n * ts, y: Self.LY), to: CGPoint(x: Double(P.A) * ts, y: Self.LY))]
        }
        let m = (s.h("m") ?? 0).rounded(), t2 = Double(P.t2)
        return [.drag(from: CGPoint(x: m * t2, y: Self.Y2), to: CGPoint(x: Double(P.c) * t2, y: Self.Y2))]
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Equiv3.Parts(s.numbers)
        guard at(s) == 0 else { return nil }
        if P.kind == 1 { let n = Double(min(P.Lw * P.b, P.A + 1)); return HandMove(hand: ["n": n], missHand: ["n": 0], set: [("h", n)], check: true) }
        let m = Double(P.c > 1 ? P.c - 1 : P.c + 1)
        return HandMove(hand: ["m": m], missHand: ["m": m], set: [("m", m)], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Equiv3.Parts(s.numbers)
        guard at(s) == 1 else { return nil }
        return P.kind == 1 ? ["t": Double(P.n), "b": Double(P.b)] : ["t": Double(P.a), "b": Double(P.d)]
    }
}
