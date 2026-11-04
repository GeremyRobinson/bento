import SwiftUI

/// Add and subtract within 1000 on the paper, as in the preview (design/prototype/grade2-ch2.html, dWithin): the web's hops
/// by place, on Comparing's lines, each to scale. Line 1 is 0 to 1000, a block (5 squares) a hundred, `245`'s point on it
/// and `+ 132` beside it, split `100 + 30 + 2` (the place being hopped lit). Drag the point a hundred at a time; the block
/// it lands in and the next open below into line 2 (two hundreds, 3 squares a ten; taking away, the one below), and the
/// point drops to its place there; the tens, then line 3 (two tens, 3 squares a one) and the ones. Each hop is written as it
/// lands, the three in one row under the lines (`245 + 100 = 345   345 + 30 = 375   375 + 2 = 377`), so the problem shows at
/// 75% and more; then `245 + 132 = [377]` under them.
///
/// The sum is written 5 rows under the hops, so with the keys up a miss written over it has its rows clear.
/// Hand: "grab", "gx", "k" the hops made on the line being hopped.
@MainActor
struct Within2Lesson: PaperLesson {
    static let RY = 24.0, SY = 32.0
    struct Line { let y: Double, base: Int, per: Double, unit: Int, step: Double, w: Double }
    var liveKeys: Set<String> { ["k"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func blocksAt(_ s: PaperState) -> CGPoint? { at(s) >= 3 ? CGPoint(x: 25, y: Self.SY - 1) : nil }
    private static func lines(_ P: Within2.Parts) -> [Line] {
        [Line(y: 4, base: 0, per: 0.05, unit: 100, step: 5, w: 50), Line(y: 12, base: P.base2, per: 0.3, unit: 10, step: 3, w: 60),
         Line(y: 20, base: P.base3, per: 3, unit: 1, step: 3, w: 60)]
    }
    private static func x(_ L: Line, _ v: Int) -> Double { Double(v - L.base) * L.per }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Within2.Parts(s.numbers), st = at(s), LN = Self.lines(P), n = min(st, 2), open = min(st, 2) + 1
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let held = s.grabbed && st <= 2, k = st <= 2 ? Int(s.h("k") ?? 0) : 0
        // + 132 beside line 1, split as the web splits it, the place being hopped lit
        let y0 = LN[0].y
        M7.row(&pic, "bsum", [.op(P.sg), .n(P.b)], x: 55, line: y0 - 1)
        var sx = 55.0
        for i in 0..<3 {
            let t = "\(P.part(i))", c: Sketch.Colour = i == n && st <= 2 ? .chapter : i < n || st > 2 ? .ink3 : .ink2
            pic.word("sp\(i)\(t)\(c == .chapter)", t, at: sx, y0 + 1.5, Sketch.Words(size: Sketch.small, weight: .semibold, colour: c), anchor: UnitPoint(x: 0, y: 0.5))
            sx += KK.width(t, N2.small) + 0.4
            if i < 2 { pic.word("spp\(i)", "+", at: sx, y0 + 1.5, N2.small, anchor: UnitPoint(x: 0, y: 0.5)); sx += KK.width("+", N2.small) + 0.4 }
        }
        for j in 0..<open {
            let L = LN[j], y = L.y
            N2.line(&pic, "ln\(j)", y: y, w: L.w, step: L.step, tall: j == 0 ? 10 : 10)
            if j == 0 { pic.label("e0", "0", N2.small, .below, edge: y, along: 0); pic.label("e1", "1000", N2.small, .below, edge: y, along: 50) }
            else { for i in 0...2 { pic.label("e\(j).\(L.base).\(i)", "\(L.base + i * 10 * L.unit)", N2.small, .below, edge: y, along: Double(i) * 30) } }
            // the two blocks that open into the next line
            if j + 1 < open {
                let nb = LN[j + 1], x1 = Self.x(L, nb.base), x2 = Self.x(L, nb.base + Int(nb.w / nb.per))
                pic.fill("op\(j)", col: x1, row: y - 1.5, w: x2 - x1, h: 1.5, .tint(0.2))
                pic.line("mgL\(j)", [(x1, y + 1.6), (0, nb.y - 4.2)], .chapter, dashed: true)
                pic.line("mgR\(j)", [(x2, y + 1.6), (nb.w, nb.y - 4.2)], .chapter, dashed: true)
            }
            // the hops made on this line, and where they started
            let done = j < n || st >= 3, kk = done ? P.s * P.B[j] : j == n ? k : 0, x0 = Self.x(L, P.starts[j])
            pic.label("st\(j)", "\(P.starts[j])", KK.maths.colour(j > 0 ? .chapter : .ink), .above, edge: y - 2.6, along: x0)
            let sgn = kk >= 0 ? 1.0 : -1.0
            for u in 0..<abs(kk) {
                let a = x0 + sgn * Double(u) * L.step
                if done { pic.hop("hp\(j).\(u)\(sgn)", from: a, to: a + sgn * L.step, row: y - 0.2, height: L.step * 0.36) }
                else { live.hop("hp\(j).\(u)\(sgn)", from: a, to: a + sgn * L.step, row: y - 0.2, height: L.step * 0.36) }
            }
            if done && j == 2 { let xe = Self.x(L, P.r); pic.label("end", "\(P.r)", KK.maths.colour(.chapter), .above, edge: y - (abs(xe - x0) < 5 ? 5.4 : 2.6), along: xe) }
        }
        // the point: on the line being hopped; it drops to the next line as that opens
        let L = LN[n], pv = st <= 2 ? P.starts[n] + k * L.unit : P.r
        if held { live.dot("pt", at: Self.x(L, pv), L.y, radius: 0.75) } else { pic.dot("pt", at: Self.x(L, pv), L.y, radius: 0.55, over: true) }
        if held {
            var ro = "\(pv)"
            if n == 1 && pv / 100 != P.starts[1] / 100 { ro += P.sub ? ": a hundred is 10 tens." : ": 10 tens make a hundred." }
            if n == 2 && pv / 10 != P.starts[2] / 10 { ro += P.sub ? ": a ten is 10 ones." : ": 10 ones make a ten." }
            live.reads(ro)
        }
        // hints: a first miss rings the line, a second the place the hops land
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        if st <= 2 {
            if ring { KK.hintBox(&pic, "hr\(n)", x: 0, y: L.y - 2, w: L.w, h: 2) }
            if spot { pic.circle("spot", at: Self.x(L, P.ends[n]), L.y, radius: 1, .chapter, dashed: true) }
        }
        // the record under the lines: each hop as it lands, in one row, then the sum
        var rx = 0.0
        for i in 0..<min(st, 3) {
            let end = M7.row(&rec, "row\(i)", [.n(P.starts[i]), .op(P.sg), .n(P.part(i)), .op("="), .n(P.ends[i], .chapter)], x: rx, line: Self.RY)
            if i == 2 && st == 3 && ring { KK.hintBox(&rec, "hw", x: rx, y: Self.RY - 1, w: end - rx, h: 2) }
            rx = ((end + 1) / 5).rounded(.up) * 5
        }
        if st >= 3 {
            let toks: [M7.Tok] = [.n(P.a), .op(P.sg), .n(P.b), .op("=")] + [st == 4 ? .n(P.r, .chapter) : .box("x", cells: 3)]
            let end = M7.row(&rec, "sum", toks, x: 0, line: Self.SY)
            if st == 3 && spot { A1.note(&rec, "spot", "\(P.r)", x: end + 1, y: Self.SY) }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Within2.Parts(s.numbers), st = at(s)
        guard st <= 2 else { return nil }
        let L = Self.lines(P)[st], x0 = Self.x(L, P.starts[st])
        let lo = max(-9, Int((Double(L.base - P.starts[st]) / Double(L.unit)).rounded(.up)))
        let hi = min(9, Int((Double(L.base) + L.w / L.per - Double(P.starts[st])) / Double(L.unit)))
        return Hands(
            grab: { q in abs(q.x - x0) <= 2.5 && abs(q.y - L.y) <= 2.5 ? ["grab": 1, "gx": q.x, "k": 0] : nil },
            drag: { q, held in var h = held; h["k"] = Double(max(lo, min(hi, Int(((q.x - (held["gx"] ?? q.x)) / L.step).rounded())))); return h },
            release: { held in
                let k = Int(held["k"] ?? 0)
                return k != 0 ? HandMove(hand: [:], missHand: [:], set: [("h\(st)", Double(k))], check: true) : HandMove(hand: [:])
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Within2.Parts(s.numbers), st = at(s)
        guard st <= 2 else { return [] }
        let L = Self.lines(P)[st]
        return [.drag(from: CGPoint(x: Self.x(L, P.starts[st]), y: L.y), to: CGPoint(x: Self.x(L, P.ends[st]), y: L.y))]
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Within2.Parts(s.numbers), st = at(s)
        guard st <= 2 else { return nil }
        let k = P.s * (P.B[st] < 9 ? P.B[st] + 1 : P.B[st] - 1)
        return HandMove(hand: [:], missHand: [:], set: [("h\(st)", Double(k))], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Within2.Parts(s.numbers)
        guard at(s) == 3 else { return nil }
        return ["x": Double(P.slips.first { $0.0 != P.r }?.0 ?? P.r + 1)]
    }
}
