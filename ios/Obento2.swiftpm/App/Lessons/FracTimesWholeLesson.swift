import SwiftUI

/// Fraction times a whole number on the paper, as in the preview (design/prototype/grade4-ch5.html): W bars down the left,
/// each a whole with n of its d pieces shaded (the groups take turns plain and striped), braced and named W × n/d to the
/// left; an empty answer bar on the right. Slide the groups over: their pieces pack into the answer bars group after
/// group, counted, spilling into a new bar when one fills, the emptied groups left dashed. Write the top (W × n/d =
/// S × 1/d = S/d). When it can be written another way: tap each full bar and it closes into a whole (the bars under it
/// stepping up), or the last bar and its cuts change to the bigger pieces; then write it.
@MainActor
struct FracTimesWholeLesson: PaperLesson {
    var liveKeys: Set<String> { GroupSlide.liveKeys }
    /// The groups' left edge: the name and the brace are left of it.
    static let g0 = 10.0

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    private struct Lay {
        let P: FracTimesWhole.Parts, at: Int, hand: Numbers
        var Wb: Double { Double(P.Wb) }
        var pw: Double { Double(P.pw) }
        var AX: Double { FracTimesWholeLesson.g0 + Wb + 4 }
        var dropped: Bool { at >= 2 }
        /// Answer bar j closed into a whole (the taps' step: as the hands left it; after it, every full one).
        func closed(_ j: Int) -> Bool { j < P.full && P.more && (at >= 4 || (at == 3 && (hand["c\(j)"] ?? 0) != 0)) }
        var recutDone: Bool { P.recut && (at >= 4 || (at == 3 && (hand["r"] ?? 0) != 0)) }
        /// Answer bar j's row: a closed one takes 3 rows, the others 5.
        func ay(_ j: Int) -> Double { (0..<j).reduce(0.0) { $0 + (closed($1) ? 3 : 5) } }
        /// What's still to tap: the full bars not closed, then the last bar when it changes its cuts.
        var targets: [Int] { (0..<P.full).filter { !closed($0) } + (P.recut && !recutDone ? [P.full] : []) }
    }
    private func lastY(_ P: FracTimesWhole.Parts) -> Double { Double(max(5 * P.W, 5 * P.bars)) - 1 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = FracTimesWhole.Parts(s.numbers), at = stage(s), L = Lay(P: P, at: at, hand: s.hand), d = P.d
        let pw = L.pw, AX = L.AX, g0 = Self.g0, held = at == 1 && s.grabbed, done = at >= 5
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let off = GroupSlide.offset(s)

        // the groups, braced; emptied, they go, and the record is written where they were (so the problem shows at 75%
        // or more)
        if !L.dropped {
            for q in 0..<P.W { M5.frame(&pic, "gb\(q)", x: g0, y: 5 * Double(q), W: P.Wb, d: d) }
            pic.line("brace", [(g0 - 0.5, 0), (g0 - 1, 0), (g0 - 1, 5 * Double(P.W) - 1), (g0 - 0.5, 5 * Double(P.W) - 1)], .ink)
        }
        if at < 2 {
            F4.row(&pic, "nm", [.n(P.W), .op("×"), .f("\(P.n)", "\(d)")], x: 0, line: ((5 * Double(P.W) - 1) / 2).rounded())
        }
        // the answer bars: one to start, all of them once the pieces come
        for j in 0..<(L.dropped ? P.bars : 1) {
            let y = L.ay(j)
            if L.closed(j) { M5.whole(&pic, "ab\(j)w", x: AX, y: y, W: L.Wb) }
            else if j == P.full && L.recutDone {
                let gr = gcd(P.rem, d)
                F4.bar(&pic, "abr\(j)", x: AX, y: y, W: P.Wb, d: d / gr, on: P.rem / gr)
            } else { M5.frame(&pic, "ab\(j)", x: AX, y: y, W: P.Wb, d: d) }
        }
        // the pieces: in their groups, held, or packed into the answer bars one after another, counted
        for k in 0..<P.S {
            let q = k / P.n, i = k % P.n, j = k / d
            if L.dropped {
                if L.closed(j) || (j == P.full && L.recutDone) { continue }
                let x = AX + Double(k % d) * pw, y = L.ay(j)
                F4.piece(&pic, "gp\(k)", x: x, y: y, pw: pw, striped: q % 2 == 1)
                pic.word("gpn\(k)", "\(k + 1)", at: x + pw / 2, y + F4.h / 2, Bars.count)
            } else {
                let x = g0 + Double(i) * pw, y = 5 * Double(q)
                if held { F4.piece(&live, "gp\(k)", x: x + off.x, y: y + off.y, pw: pw, striped: q % 2 == 1) }
                else { F4.piece(&pic, "gp\(k)", x: x, y: y, pw: pw, striped: q % 2 == 1) }
            }
        }
        if held { live.reads(s.h("in") == 1 ? Fractions4.pieces(P.S, d) : "\(P.W) × \(P.n)/\(d)") }
        // hints: the answer bar (dashed round it); the bars to tap (ringed)
        if at == 1 && !held && s.on("target") { M5.target(&pic, "tg", x: AX, y: 0, w: L.Wb, h: F4.h) }
        if at == 3 && s.on("ring") { for j in L.targets { M5.ring(&pic, "ring\(j)", x: AX, y: L.ay(j), w: L.Wb, h: F4.h) } }

        // the record: W × n/d = [T]/d, then = S × 1/d = S/d, then written another way
        if at >= 2 {
            var toks: [F4.Tok] = [.n(P.W), .op("×"), .f("\(P.n)", "\(d)"), .op("=")]
            if at == 2 { toks.append(.fb(top: .box("T"), bottom: .v(d))) }
            else {
                toks += [.n(P.S), .op("×"), .f("1", "\(d)"), .op("="), .f("\(P.S)", "\(d)", P.more ? .ink : .chapter)]
                if P.more && at >= 4 {
                    toks.append(.op("="))
                    if done { toks += M5.mixed(P.whole, P.top, P.bottom, .chapter) }
                    else {
                        if P.boxes.contains("W") { toks.append(.box("W", cells: 1)) }
                        if P.boxes.contains("N") { toks.append(.fb(top: .box("N"), bottom: .box("D"))) }
                    }
                }
            }
            F4.row(&rec, "rec", toks, x: 0, line: 2)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes,
                            extent: pic.R(0, 0, AX + L.Wb, lastY(P) + 1))
    }

    /// Where the groups were, once they're emptied into the answer bars: the record from the top, the blocks under it.
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func blocksLeft(_ n: Numbers) -> Double? { 0 }
    /// A story's choices under the answer bar, one under another, beside the tall column of groups.
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = FracTimesWhole.Parts(s.numbers)
        return s.picking ? CGPoint(x: Self.g0 + Double(P.Wb) + 4, y: F4.h + 2) : nil
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = FracTimesWhole.Parts(s.numbers), at = stage(s), L = Lay(P: P, at: at, hand: s.hand), AX = L.AX, Wb = L.Wb
        switch at {
        case 1:
            return GroupSlide(from: CGRect(x: Self.g0 - 0.5, y: -0.5, width: Wb + 1, height: 5 * Double(P.W)),
                              over: { p in p.x >= AX - 1 && p.x <= AX + Wb + 1 }).hands()
        case 3:
            let hand = s.hand
            return Hands(tap: { p in
                guard p.x >= AX, p.x <= AX + Wb,
                      let j = (0..<P.bars).first(where: { p.y >= L.ay($0) - 0.5 && p.y <= L.ay($0) + (L.closed($0) ? M5.wh : F4.h) + 0.5 }),
                      !L.closed(j) else { return nil }
                var h = hand
                if j < P.full { h["c\(j)"] = 1 }
                else if j == P.full && P.recut && !L.recutDone { h["r"] = 1 }
                else { return HandMove(hand: nil, missHand: nil, set: [("t", -1)], check: true) }
                let left = Lay(P: P, at: 3, hand: h).targets
                return left.isEmpty ? HandMove(hand: h, missHand: nil, set: [("t", 1)], check: true) : HandMove(hand: h, missHand: nil)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = FracTimesWhole.Parts(s.numbers), at = stage(s), L = Lay(P: P, at: at, hand: s.hand)
        switch at {
        case 1: return [.drag(from: CGPoint(x: Self.g0 + Double(P.n) * L.pw / 2, y: 2), to: CGPoint(x: L.AX + L.Wb / 2, y: 2))]
        case 3:
            // each from the bottom up, so the rows above don't move before they're tapped
            return L.targets.reversed().map { .tap(.picture(CGPoint(x: L.AX + L.Wb / 2, y: L.ay($0) + 2))) }
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        switch stage(s) {
        case 1: return HandMove(hand: [:], missHand: [:], set: [("s", 0)], check: true)
        case 3: return HandMove(hand: nil, missHand: nil, set: [("t", -1)], check: true)
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = FracTimesWhole.Parts(s.numbers)
        switch stage(s) {
        // the bottom multiplied too
        case 2: return ["T": Double(P.W * P.d)]
        // the right amount, not written another way
        case 4:
            if P.rem == 0 { return ["W": Double(P.S)] }
            return P.S > P.d ? ["W": 0, "N": Double(P.S), "D": Double(P.d)] : ["N": Double(P.S), "D": Double(P.d)]
        default: return nil
        }
    }
}
