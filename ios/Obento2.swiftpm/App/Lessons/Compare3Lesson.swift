import SwiftUI

/// Comparing fractions on the paper, as in the preview (design/prototype/grade3-ch5.html, dCompare): two bars of one whole
/// (48 squares, 8 tall, 2 apart), each named at its right end, the sign's place between the names. Same bottom: tap the one
/// with more pieces (its shaded pieces number). Same top: the bars sit two blocks lower and each first piece lifts out over
/// them, side by side at its real size, named; tap the bigger, and they go home. The same amount: drag the ruler under the
/// bars (it snaps to halves, thirds, fourths, sixths, eighths; the cuts dashed across both, "fourths: 2 in each half") to
/// cut both into the smaller pieces. Then tap the sign (< = >): it's written between the names, which come together into
/// `3/8 < 5/8`; the shading's ends drop dashed lines across the other bar and the extra is outlined.
///
/// Hand: equal "grab", "ru" the ruler's pieces in a whole; sign "bad" the sign picked wrong. Kept "tap" the bar tapped.
@MainActor
struct Compare3Lesson: PaperLesson {
    static let BH = F3P.BH, W = Double(Fr3.whole), NX = 50.0, RY = 22.0
    var liveKeys: Set<String> { ["ru"] }
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func messageRows(_ n: Numbers) -> Int { 2 }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// The bars' tops: two blocks lower while the same top's pieces are lifted over them.
    static func bars(_ P: Compare3.Parts, _ st: Int) -> [Double] { P.kind == 1 && st == 0 ? [12, 22] : [2, 12] }
    static func liftX(_ P: Compare3.Parts) -> [Double] { [0, ((W / Double(P.b) + 4) / 5).rounded(.up) * 5] }
    static let GY = 10.0

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Compare3.Parts(s.numbers), st = at(s), BY = Self.bars(P, st), BH = Self.BH, W = Self.W, NX = Self.NX, GY = BY[0] + BH
        var pic = GridPen(), live = GridPen(stableIds: true)
        let ring = s.on("ring") || s.on("spot"), spot = s.on("spot"), lift = P.kind == 1
        let tapped = s.run.kept["tap"].map { Int($0.rounded()) }, ru = Int((s.h("ru") ?? 1).rounded())
        let FR = [(P.a, P.b), (P.c, P.d)], cut = P.kind == 2 && st >= 1
        for (r, f) in FR.enumerated() {
            let (n, m) = f, y = BY[r], pw = W / Double(m), cuts = cut ? P.D : m, out = lift && st == 0
            // the shading (the first piece lifted out, while it's lifted)
            if out {
                if n > 1 { pic.fill("f\(r)", col: pw, row: y, w: Double(n - 1) * pw, h: BH, F3P.shade) }
                pic.sketch.box("hole\(r)", pic.R(0, y, pw, BH), .ink3, width: Sketch.stroke, dashed: true)
                pic.sketch.box("o\(r)", pic.R(pw, y, W - pw, BH), .ink, width: Sketch.stroke)
            } else {
                pic.fill("f\(r)", col: 0, row: y, w: Double(n) * pw, h: BH, F3P.shade)
                pic.sketch.box("o\(r)", pic.R(0, y, W, BH), .ink, width: Sketch.stroke)
            }
            let cw = W / Double(cuts)
            for i in 1..<max(1, cuts) where !(out && Double(i) * cw < pw - 0.01) { pic.line("c\(r)_\(cuts)_\(i)", [(Double(i) * cw, y), (Double(i) * cw, y + BH)]) }
            // the tapped bar's shaded pieces number
            if P.kind == 0 && tapped == r { for i in 0..<n { pic.word("pn\(r)_\(i)", "\(i + 1)", at: (Double(i) + 0.5) * pw, y + BH / 2, F3P.lit) } }
            // same top: the two pieces lift out over the bars, their real sizes; then they go home
            if lift {
                let lx = Self.liftX(P)[r], home = pic.R(0, y, pw, BH)
                if st == 0 {
                    pic.sketch.from["lp\(r)p"] = .plate([home.origin, CGPoint(x: home.maxX, y: home.minY), CGPoint(x: home.maxX, y: home.maxY), CGPoint(x: home.minX, y: home.maxY)])
                    F3P.lifted(&pic, "lp\(r)", x: lx, y: 2, w: pw, h: BH)
                    pic.label("lpn\(r)", "1/\(m)", F3P.small, .above, edge: 2, along: lx + pw / 2)
                } else {
                    pic.sketch.box("lpo\(r)", home, tapped == r ? .chapter : .ink, width: Sketch.stroke)
                }
            }
            // the names at the right ends; once signed they come together into one line
            let nx = st == 9 ? NX + Double(r) * 7 : NX, ny = st == 9 ? GY + 1 : y + BH / 2
            F4.frac(&pic, "nm\(r)", "\(n)", "\(m)", col: nx, line: ny)
        }
        // the ruler under the bars: one piece's length from the left end, its handle at the right; the cuts dashed across
        if P.kind == 2 && st == 0 {
            let len = W / Double(ru), RY = Self.RY
            live.line("ru", [(0, RY - 0.6), (0, RY), (len, RY), (len, RY - 0.6)], .chapter)
            live.dot("ruh", at: len, RY, radius: s.grabbed ? 0.7 : 0.55, .chapter, over: true)
            if ru > 1 {
                for i in 1..<ru { live.line("dc\(ru)_\(i)", [(Double(i) * len, BY[0] - 0.6), (Double(i) * len, BY[1] + BH + 0.6)], .ink2, dashed: true) }
                let t = P.rulerText(ru)
                live.word("rut\(t)", t, at: 0, RY + 1.4, F3P.smallLit, anchor: UnitPoint(x: 0, y: 0.5))
                if s.grabbed { live.reads(t) }
            }
            if ring { KK.hintBox(&pic, "hr", x: 0, y: RY - 1.5, w: W, h: 2) }
            if spot { for i in 1..<P.D { pic.line("hs\(i)", [(Double(i) * W / Double(P.D), BY[0] - 0.6), (Double(i) * W / Double(P.D), BY[1] + BH + 0.6)], .chapter, dashed: true) } }
        }
        if st == 0 && P.kind != 2 && ring {
            if lift { KK.hintBox(&pic, "hr", x: 0, y: 2, w: Self.liftX(P)[1] + W / Double(P.d), h: BH) }
            else { KK.hintBox(&pic, "hr", x: 0, y: BY[0], w: W, h: BY[1] + BH - BY[0]) }
        }
        // the sign's place between the names, and the signs to tap
        if st != 9 { pic.sketch.box("sp", pic.R(NX + 1, GY, 2, 2), .ink3, width: Sketch.stroke) }
        if st == 1 {
            let bad = s.h("bad").map { Int($0.rounded()) }
            for (i, sym) in Compare3.signs.enumerated() {
                let x = NX + 5 + 5 * Double(i), c: Sketch.Colour = bad == i ? Bars.red : .ink
                pic.sketch.box("sg\(i)o\(bad == i)", pic.R(x, GY, 3, 2), c, width: Sketch.stroke)
                pic.word("sg\(i)s\(bad == i)", sym, at: x + 1.5, GY + 1, Bars.maths.colour(c))
            }
            if ring { KK.hintBox(&pic, "hr", x: NX + 1, y: GY, w: 2, h: 2) }
            if spot { pic.circle("hs", at: NX + 6.5 + 5 * Double(P.right), GY + 1, radius: 2.2, .chapter, dashed: true) }
        }
        if st == 9 {
            pic.sketch.delay = 0.5
            pic.word("sign", Compare3.signs[P.right], at: NX + 5.5, GY + 1, Bars.maths.colour(.chapter))
            // (See) the shading's ends drop dashed lines across the other bar; the extra is outlined
            let e = [Double(P.a) / Double(P.b) * W, Double(P.c) / Double(P.d) * W]
            pic.line("e0", [(e[0], BY[0] - 0.6), (e[0], BY[1] + BH + 0.6)], .ink2, dashed: true)
            if P.s != 0 {
                pic.line("e1", [(e[1], BY[0] - 0.6), (e[1], BY[1] + BH + 0.6)], .ink2, dashed: true)
                let r = P.s > 0 ? 0 : 1, x1 = min(e[0], e[1]), x2 = max(e[0], e[1])
                pic.sketch.box("extra", pic.R(x1 + 0.4, BY[r] + 0.4, x2 - x1 - 0.8, BH - 0.8), .chapter, width: Sketch.stroke)
            }
            pic.sketch.delay = 0
        }
        let wide = st == 1 ? NX + 20 : NX + 4
        let ext = pic.R(0, 0, wide, (P.kind == 2 && st == 0 ? Self.RY + 2 : BY[1] + BH))
        return PaperDrawing(picture: pic.sketch, live: live.sketch, extent: ext)
    }

    func blocksAt(_ s: PaperState) -> CGPoint? { at(s) == 9 ? CGPoint(x: Self.NX, y: Self.GY + 5) : nil }

    func hands(_ s: PaperState) -> Hands? {
        let P = Compare3.Parts(s.numbers), st = at(s), BY = Self.bars(P, st), BH = Self.BH, W = Self.W
        switch st {
        case 0 where P.kind == 0:
            return Hands(tap: { q in
                guard q.x >= 0, q.x <= Self.NX + 4 else { return nil }
                guard let r = (0..<2).first(where: { q.y >= BY[$0] && q.y <= BY[$0] + BH }) else { return nil }
                return HandMove(hand: [:], set: [("t", Double(r))], keep: r == P.first ? ["tap": Double(r)] : [:], check: true)
            })
        case 0 where P.kind == 1:
            let lx = Self.liftX(P)
            return Hands(tap: { q in
                guard q.y >= 2, q.y <= 2 + BH else { return nil }
                guard let r = (0..<2).first(where: { q.x >= lx[$0] && q.x <= lx[$0] + W / Double($0 == 0 ? P.b : P.d) }) else { return nil }
                return HandMove(hand: [:], set: [("t", Double(r))], keep: r == P.first ? ["tap": Double(r)] : [:], check: true)
            })
        case 0:
            let ru0 = Int((s.h("ru") ?? 1).rounded()), RY = Self.RY
            return Hands(
                grab: { q in abs(q.x - W / Double(ru0)) <= 2 && abs(q.y - RY) <= 2 ? ["grab": 1, "ru": Double(ru0)] : nil },
                drag: { q, h in
                    var h = h, best = 1
                    for n in Compare3.sizes where abs(W / Double(n) - q.x) < abs(W / Double(best) - q.x) { best = n }
                    h["ru"] = Double(best)
                    return h
                },
                release: { h in
                    let n = Int((h["ru"] ?? 1).rounded())
                    guard n != ru0, n != 1 else { return HandMove(hand: ["ru": Double(n)]) }
                    return HandMove(hand: ["ru": Double(n)], missHand: ["ru": Double(n)], set: [("r", Double(n))], check: true)
                })
        case 1:
            return Hands(tap: { q in
                guard q.y >= Self.GY - 0.3, q.y <= Self.GY + 2.3 else { return nil }
                guard let i = (0..<3).first(where: { let x = Self.NX + 5 + 5 * Double($0); return q.x >= x - 0.3 && q.x <= x + 3.3 }) else { return nil }
                return HandMove(hand: [:], missHand: ["bad": Double(i)], set: [("c", Double(i))], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Compare3.Parts(s.numbers), st = at(s), BY = Self.bars(P, st), BH = Self.BH, W = Self.W
        switch st {
        case 0 where P.kind == 0: return [.tap(.picture(CGPoint(x: W / 2, y: BY[P.first] + BH / 2)))]
        case 0 where P.kind == 1:
            let r = P.first, pw = W / Double(r == 0 ? P.b : P.d)
            return [.tap(.picture(CGPoint(x: Self.liftX(P)[r] + pw / 2, y: 2 + BH / 2)))]
        case 0:
            let ru = (s.h("ru") ?? 1).rounded()
            return [.drag(from: CGPoint(x: W / ru, y: Self.RY), to: CGPoint(x: W / Double(P.D), y: Self.RY))]
        case 1: return [.tap(.picture(CGPoint(x: Self.NX + 6.5 + 5 * Double(P.right), y: Self.GY + 1)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Compare3.Parts(s.numbers)
        switch at(s) {
        case 0 where P.kind == 2:
            let n = Compare3.sizes.first { $0 != P.D && $0 != 1 && $0 != P.B } ?? 2
            return HandMove(hand: ["ru": Double(n)], missHand: ["ru": Double(n)], set: [("r", Double(n))], check: true)
        case 0: return HandMove(hand: [:], set: [("t", Double(1 - P.first))], check: true)
        case 1:
            let i = P.right == 0 ? 2 : 0
            return HandMove(hand: [:], missHand: ["bad": Double(i)], set: [("c", Double(i))], check: true)
        default: return nil
        }
    }
}
