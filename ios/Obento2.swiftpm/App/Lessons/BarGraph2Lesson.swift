import SwiftUI

/// Bar graphs on the paper, as in the preview (design/prototype/grade2-ch5.html, dBarGraph): a vote is a block, as in Make a
/// graph. The web's question on the picture's top rows (said as the problem opens), the title under it from the left (a hop
/// over the top bar clears it), four bars 4 squares
/// tall a square apart with their names at their left, the scale 0–10 under them on the strong lines. Drop a line: grab the
/// graph and drag; a dashed line drops from the bar under the finger to the scale and the number it lands on lights (the
/// bar lights while it's read; the readout at the title row's right end). How many more: the shorter bar's end drops a
/// dashed line across the longer one, the part sticking out shades, hop along it a block a hop. In all: tap the second bar,
/// each tap counts on from the first one's number. Then the record 3 rows under the scale, Check beside it.
///
/// Hand while a line is dropped: "grab", "j", "v". Kept: "n" counted on; the hop's (LN2).
@MainActor
struct BarGraph2Lesson: PaperLesson {
    var liveKeys: Set<String> { ["j", "v"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let GX = 10.0, TT = 3.5, BY = 5.0
    static func rowY(_ j: Int) -> Double { BY + 5 * Double(j) }
    static let SY = BY + 20, ROW = SY + 5
    static func blocks(_ x: Double) -> Int { max(0, min(10, Int(((x - GX) / 5).rounded()))) }
    func told(_ s: PaperState) -> String? { BarGraph2.Parts(s.numbers).question }
    func recordRow(_ n: Numbers) -> Double? { Self.ROW }
    private func toks(_ P: BarGraph2.Parts) -> [M7.Tok] { [.n(P.a), .op(P.more ? "−" : "+"), .n(P.b), .op("=")] }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        guard at(s) >= 3 else { return nil }
        return CGPoint(x: EG2.ceil5(M7.width(toks(BarGraph2.Parts(s.numbers)) + [.box("x", cells: 2)]) + 1), y: Self.ROW)
    }
    private func counted(_ s: PaperState, _ P: BarGraph2.Parts) -> Int { at(s) > 2 ? P.b : Int(s.run.kept["n"] ?? 0) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = BarGraph2.Parts(s.numbers), st = at(s), GX = Self.GX, SY = Self.SY
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        A2.tell(&pic, [P.question], width: 60)
        pic.word("title", P.th.title, at: 0, Self.TT, DK2.say, anchor: UnitPoint(x: 0, y: 0.5))
        let held = s.grabbed && st < 2, hj = held ? Int(s.h("j") ?? 0) : -1, hv = Int(s.h("v") ?? 0)
        for j in 0..<4 {
            let y = Self.rowY(j)
            pic.word("n\(j)", P.th.names[j], at: GX - 0.5, y + 2, DK2.say, anchor: UnitPoint(x: 1, y: 0.5))
            if j == hj { DK2.bar(&live, "bl\(j)", x: GX, y: y, P.v[j], lit: true) } else { DK2.bar(&pic, "b\(j)", x: GX, y: y, P.v[j]) }
        }
        // the scale; the numbers read light, and the dashed lines dropped stay
        var lit: Set<Int> = []
        if st > 0 { lit.insert(P.a); pic.line("dla", [(GX + 5 * Double(P.a), Self.rowY(P.x) + 4), (GX + 5 * Double(P.a), SY)], .ink3, dashed: true) }
        if st > 1 { lit.insert(P.b); pic.line("dlb", [(GX + 5 * Double(P.b), Self.rowY(P.y) + 4), (GX + 5 * Double(P.b), SY)], .ink3, dashed: true) }
        DK2.scale(&pic, x: GX, top: Self.BY - 1, y: SY, max: 10, lit: lit)
        if held {
            live.line("dd\(hj):\(hv)", [(GX + 5 * Double(hv), Self.rowY(hj) + 2), (GX + 5 * Double(hv), SY)], .chapter, dashed: true)
            live.word("lit\(hv)", "\(hv)", at: GX + 5 * Double(hv), SY + 2, KK.lit)
            let ro = "\(P.th.names[hj]): \(hv)"
            DK2.readoutEnd(&live, ro, x: GX + 50, y: Self.TT); live.reads(ro)
        }
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        if st < 2 {
            let j = st == 0 ? P.x : P.y
            if ring { KK.hintBox(&pic, "hr", x: GX, y: Self.rowY(j), w: 5 * Double(P.v[j]), h: 4) }
            if spot { KK.hint(&pic, "sp", GX + 5 * Double(P.v[j]), SY + 2, radius: 1.3) }
        }
        let xs = Self.rowY(P.x)
        if st >= 2 && P.more {
            // the shorter bar's end across the longer one; the part sticking out, striped; the hops over it
            let top = min(xs, Self.rowY(P.y)), bot = max(xs, Self.rowY(P.y)) + 4, cx = GX + 5 * Double(P.b)
            pic.line("cut", [(cx, top - 0.5), (cx, bot + 0.5)], .chapter, dashed: true)
            pic.stripes("out", col: cx, row: xs, w: 5 * Double(P.a - P.b), h: 4)
            let c = st == 2 ? LN2.chain(s, "h") : LN2.Chain(f: P.b, t: P.a)
            if let c {
                LN2.hops(&pic, &live, held: s.grabbed, "hp", c.f, c.t, x0: GX, per: 5, row: xs, height: 0.8)
                if st == 2, c.t != c.f {
                    let ro = "\(abs(c.t - c.f))"
                    if s.grabbed { DK2.readoutEnd(&live, ro, x: GX + 50, y: Self.TT); live.reads(ro) } else { DK2.readoutEnd(&pic, ro, x: GX + 50, y: Self.TT) }
                }
            }
            if st == 2 && ring { KK.hintBox(&pic, "hh", x: cx, y: xs, w: 5 * Double(P.a - P.b), h: 4) }
            if st == 2 && spot { pic.circle("sh", at: cx, xs, radius: 1, .chapter, dashed: true) }
        }
        if st >= 2 && !P.more {
            // counted on along the second bar from the first one's number
            let n = counted(s, P), ys = Self.rowY(P.y)
            for k in 0..<n { pic.word("cn\(k)", "\(P.a + k + 1)", at: GX + 5 * Double(k) + 2.5, ys + 2, KK.maths.colour(.chapter)) }
            if st == 2 && n > 0 {
                var l: [Int] = []
                for k in 0..<n { l.append(P.a + k + 1) }
                DK2.readoutEnd(&pic, Data2.landings(l), x: GX + 50, y: Self.TT)
            }
            if st == 2 && ring { KK.hintBox(&pic, "hc", x: GX, y: ys, w: 5 * Double(P.b), h: 4) }
            if st == 2 && spot && n < P.b { KK.hint(&pic, "sc", GX + 5 * Double(n) + 2.5, ys + 2, radius: 2.2) }
        }
        if st >= 3 {
            let last: M7.Tok = st == 4 ? .n(P.answer, .chapter) : .box("x", cells: 2)
            let end = M7.row(&rec, "rec", toks(P) + [last], x: 0, line: 1)
            if st == 3 && ring {
                if P.more { KK.hintBox(&pic, "hw", x: GX + 5 * Double(P.b), y: xs, w: 5 * Double(P.a - P.b), h: 4) }
                else { KK.hintBox(&pic, "hw", x: GX, y: Self.rowY(P.y), w: 5 * Double(P.b), h: 4) }
            }
            if st == 3 && spot { A1.note(&rec, "spot", "\(P.answer)", x: end + 0.5, y: 3.5) }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, GX + 51, SY + 3))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = BarGraph2.Parts(s.numbers), st = at(s), GX = Self.GX
        if st < 2 {
            let box = st == 0 ? "a" : "b"
            return Hands(
                grab: { q in
                    guard q.x >= GX - 1, q.x <= GX + 51, q.y >= Self.BY - 0.5, q.y <= Self.SY + 3 else { return nil }
                    let j = max(0, min(3, Int(((q.y - Self.BY + 0.5) / 5).rounded(.down))))
                    return ["grab": 1, "j": Double(j), "v": Double(Self.blocks(q.x))]
                },
                drag: { q, h in var h = h; h["v"] = Double(Self.blocks(q.x)); return h },
                release: { h in
                    HandMove(hand: [:], missHand: [:], set: [(box, Double(BarGraph2.drop(Int(h["j"] ?? 0), Int(h["v"] ?? 0))))], check: true)
                })
        }
        guard st == 2 else { return nil }
        if P.more {
            let xs = Self.rowY(P.x)
            return LN2.hopHands(s, "h", box: "h", band: (xs - 1.5)...(xs + 4.5), xr: GX...(GX + 50), at: { Self.blocks($0) },
                                clears: { f, _ in f != P.b })
        }
        let n = counted(s, P)
        return Hands(tap: { q in
            for j in 0..<4 where q.y >= Self.rowY(j) - 0.3 && q.y <= Self.rowY(j) + 4.3 && q.x >= GX - 0.3 && q.x <= GX + 5 * Double(P.v[j]) + 0.3 {
                if j != P.y { return HandMove(hand: [:], missHand: [:], set: [("k", Double(50 + j))], check: true) }
                guard n < P.b else { return HandMove(hand: [:]) }
                let all = n + 1 == P.b
                return HandMove(hand: [:], missHand: [:], set: all ? [("k", Double(P.b))] : [], keep: ["n": Double(n + 1)], check: all)
            }
            return nil
        })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = BarGraph2.Parts(s.numbers), st = at(s), GX = Self.GX
        if st < 2 {
            let j = st == 0 ? P.x : P.y, x = GX + 5 * Double(P.v[j])
            return [.drag(from: CGPoint(x: x - 0.5, y: Self.rowY(j) + 2), to: CGPoint(x: x, y: Self.SY + 0.5))]
        }
        guard st == 2 else { return [] }
        if P.more {
            let y = Self.rowY(P.x) - 0.5
            return [.drag(from: CGPoint(x: GX + 5 * Double(P.b), y: y), to: CGPoint(x: GX + 5 * Double(P.a), y: y))]
        }
        let n = counted(s, P)
        var out: [GhostMove] = []
        for k in n..<P.b { out.append(.tap(.picture(CGPoint(x: GX + 5 * Double(k) + 2.5, y: Self.rowY(P.y) + 2)))) }
        return out
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = BarGraph2.Parts(s.numbers), st = at(s)
        if st < 2 {
            let j = st == 0 ? P.x : P.y, v = P.v[j] < 10 ? P.v[j] + 1 : P.v[j] - 1
            return HandMove(hand: [:], missHand: [:], set: [(st == 0 ? "a" : "b", Double(BarGraph2.drop(j, v)))], check: true)
        }
        guard st == 2 else { return nil }
        if P.more { return LN2.hopMove("h", box: "h", from: P.b, to: P.a - 1 > P.b ? P.a - 1 : P.a + 1) }
        return HandMove(hand: [:], missHand: [:], set: [("k", Double(50 + P.x))], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = BarGraph2.Parts(s.numbers)
        guard at(s) == 3 else { return nil }
        return ["x": Double(P.slips.first?.0 ?? P.answer + 1)]
    }
}
