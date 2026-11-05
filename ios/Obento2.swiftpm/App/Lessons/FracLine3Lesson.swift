import SwiftUI

/// Fractions on a number line on the paper, as in the preview (design/prototype/grade3-ch5.html, dFracLine): the line is 48
/// squares, 0 to 1 a whole of 48 or 0 to 2 with a whole of 24, a tick every whole / b, the point a dot on its tick. Hop from 0
/// to 1: drag the handle, the hops snap a tick at a time and count over their middles ("4 hops" beside the line); hop from 0
/// to the point (the first hops faint); write `point = [3]/[4]` under the line; then every tick is named 1/4, 2/4, 3/4, 4/4
/// over it and the point rings.
///
/// Hand: "grab", "n" the hops.
@MainActor
struct FracLine3Lesson: PaperLesson {
    static let LY = 7.0, W = Double(Fr3.whole)
    var liveKeys: Set<String> { ["n"] }
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func messageRows(_ n: Numbers) -> Int { 2 }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = FracLine3.Parts(s.numbers), st = at(s), LY = Self.LY, ts = Double(P.ts), per = Double(P.per)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let ring = s.on("ring") || s.on("spot"), spot = s.on("spot"), n = Int((s.h("n") ?? 0).rounded())
        F3L.line(&pic, "nl", y: LY, wholes: P.w, per: per, b: P.b)
        if st == 0 {
            F3L.hops(&live, "h1", y: LY, ts: ts, n: n)
            F3L.handle(&live, x: Double(n) * ts, y: LY, held: s.grabbed)
        } else if st < 9 {
            F3L.hops(&pic, "h1f", y: LY, ts: ts, n: P.b, faint: true, quiet: true)
            if st == 1 { F3L.hops(&live, "h2", y: LY, ts: ts, n: n); F3L.handle(&live, x: Double(n) * ts, y: LY, held: s.grabbed) }
            else { F3L.hops(&pic, "h2", y: LY, ts: ts, n: P.a) }
        }
        pic.dot("pt\(st == 9)", at: Double(P.a) * ts, LY, radius: 0.5, st == 9 ? .chapter : .ink, over: true)
        if st <= 1 {
            if n > 0 { F3P.beside(&live, "ro\(n)", Fr3.plural(n, "hop", "hops"), x: Self.W + 1.5, y: LY) }
            if s.grabbed { live.reads(Fr3.plural(n, "hop", "hops")) }
        }
        // hints: the stretch to find (a first miss), then the tick itself (a second)
        if st == 0 {
            if ring { KK.hintBox(&pic, "hr", x: 0, y: LY - 4, w: per, h: 4) }
            if spot { pic.circle("hs", at: per, LY, radius: 1.3, .chapter, dashed: true) }
        }
        if st == 1 {
            if ring { KK.hintBox(&pic, "hr", x: P.a > P.b ? per : 0, y: LY - 4, w: per, h: 4) }
            if spot { pic.circle("hs", at: Double(P.a) * ts, LY, radius: 1.3, .chapter, dashed: true) }
        }
        if st == 2 {
            if ring { KK.hintBox(&pic, "hr", x: 0, y: LY - 4, w: Double(P.a) * ts, h: 4) }
            if spot { for i in 1...P.b { pic.label("hs\(i)", "\(i)", F3P.smallLit, .below, edge: LY + 2, along: (Double(i) - 0.5) * ts) } }
        }
        if st == 9 {
            pic.circle("ringP", at: Double(P.a) * ts, LY, radius: 0.95, .chapter)
            // (See) every tick named
            for i in 1...P.N {
                pic.sketch.delay = 0.2 + Double(i) * 0.08
                pic.word("tn\(i)", "\(i)/\(P.b)", at: Double(i) * ts, LY - 2.45, i == P.a ? F3P.smallLit : F3P.small.colour(.ink2))
            }
            pic.sketch.delay = 0
        }
        if st >= 2 { F3P.record(&rec, "rec", [.w("point")], top: "t", bottom: "b", (P.a, P.b), right: st == 9, x: 0, line: LY + 7) }
        let ext = pic.R(0, LY - 4.5, Self.W + (st <= 1 ? 8 : 0), 6.5)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = FracLine3.Parts(s.numbers)
        switch at(s) {
        case 0: return F3L.hands(s, y: Self.LY, ts: Double(P.ts), max: P.N, key: "s", want: P.b)
        case 1: return F3L.hands(s, y: Self.LY, ts: Double(P.ts), max: P.N, key: "j", want: P.a)
        default: return nil
        }
    }
    func demo(_ s: PaperState) -> [GhostMove] {
        let P = FracLine3.Parts(s.numbers), st = at(s), ts = Double(P.ts), n = (s.h("n") ?? 0).rounded()
        guard st <= 1 else { return [] }
        return [.drag(from: CGPoint(x: n * ts, y: Self.LY), to: CGPoint(x: Double(st == 0 ? P.b : P.a) * ts, y: Self.LY))]
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = FracLine3.Parts(s.numbers), st = at(s)
        guard st <= 1 else { return nil }
        let n = Double(st == 0 ? P.b + 1 : min(P.N, P.a + 1))
        return HandMove(hand: ["n": n], missHand: ["n": 0], set: [(st == 0 ? "s" : "j", n)], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = FracLine3.Parts(s.numbers)
        return at(s) == 2 ? ["t": Double(P.a), "b": Double(P.b + 1)] : nil
    }
}
