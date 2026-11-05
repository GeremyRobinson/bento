import SwiftUI

/// Measure with two units on the paper, as in the preview (design/prototype/grade2-ch4.html, dTwoUnits): Inches and
/// centimeters' scale, so the two rulers match as in life. The inch ruler over the thing (its marks hang down to it), the
/// centimeter ruler under it, both from its left end, dashed lines from its ends. Hop the inch ruler (the hops arc under
/// it), write `[6] in`; hop the centimeter ruler (over it), write `[15] cm` beside; tap the bigger unit: one inch and one
/// centimeter lift out of the rulers and lie side by side under the record.
@MainActor
struct TwoUnits2Lesson: PaperLesson {
    static let IY = 0.0, TY = 5.0, CY = 9.0, ROW = 15.0, PY = 19.0
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { Self.ROW }
    private static let inPart: [M7.Tok] = [.box("in", cells: 2), .w("in")]
    private static var cmX: Double { EG2.ceil5(M7.width(inPart) + 1) }
    private static var checkX: Double { EG2.ceil5(cmX + M7.width([.box("cm", cells: 2), .w("cm")]) + 1) }
    func blocksAt(_ s: PaperState) -> CGPoint? { [1, 3, 5].contains(at(s)) ? CGPoint(x: Self.checkX, y: Self.ROW) : nil }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = TwoUnits2.Parts(s.numbers), st = at(s), W = 5 * Double(P.imax)
        let IY = Self.IY, CY = Self.CY
        var pic = GridPen(), rec = GridPen(), live = GridPen(stableIds: true)
        LN2.thing(&pic, "t", P.name, x0: 0, x1: 5 * Double(P.n), y: Self.TY)
        pic.line("d0", [(0, IY + 3), (0, CY)], .ink3, dashed: true)
        pic.line("d1", [(5 * Double(P.n), IY + 3), (5 * Double(P.n), CY)], .ink3, dashed: true)
        let ci = st == 0 ? LN2.chain(s, "hi") : LN2.Chain(f: 0, t: P.n)
        let cc = st < 2 ? nil : st == 2 ? LN2.chain(s, "hc") : LN2.Chain(f: 0, t: P.cm)
        func lit(_ c: LN2.Chain?) -> [Int] { c.map { $0.t != $0.f ? [$0.f, $0.t] : [$0.f] } ?? [] }
        LN2.ruler(&pic, "ri", x0: 0, y: IY, per: 5, max: P.imax, below: true, lit: lit(ci))
        LN2.ruler(&pic, "rc", x0: 0, y: CY, per: 2, max: P.cmax, lit: lit(cc))
        // the hops: under the inch ruler's marks, over the centimeter ruler's
        if let ci { LN2.hops(&pic, &live, held: s.grabbed, "hi", ci.f, ci.t, x0: 0, per: 5, row: IY + 3, height: -1.2) }
        if let cc { LN2.hops(&pic, &live, held: s.grabbed, "hc", cc.f, cc.t, x0: 0, per: 2, row: CY, height: 0.6) }
        if st == 0, let c = ci, c.t != c.f { EG2.readout(&pic, "\(abs(c.t - c.f)) in", x: W + 2, y: IY + 1.5); if s.grabbed { live.reads("\(abs(c.t - c.f)) in") } }
        if st == 2, let c = cc, c.t != c.f { EG2.readout(&pic, "\(abs(c.t - c.f)) cm", x: W + 2, y: CY + 1.5); if s.grabbed { live.reads("\(abs(c.t - c.f)) cm") } }
        // hints: a first miss rings the ruler (or both rulers' first space), a second the mark to start on (or one inch)
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        switch st {
        case 0, 2:
            let y = st == 0 ? IY : CY
            if ring { KK.hintBox(&pic, "hr", x: 0, y: y, w: W, h: 3) }
            if spot { pic.circle("sp", at: 0, st == 0 ? IY + 3 : CY, radius: 1, .chapter, dashed: true) }
        case 4:
            if ring { KK.hintBox(&pic, "hr1", x: 0, y: IY, w: 5, h: 3); KK.hintBox(&pic, "hr2", x: 0, y: CY, w: 2, h: 3) }
            if spot { KK.hintBox(&pic, "sp", x: 0, y: IY, w: 5, h: 3) }
        default: break
        }
        // the record: [6] in, then [15] cm
        if st >= 1 {
            let e = M7.row(&rec, "rin", [st == 1 ? .box("in", cells: 2) : .n(P.n, .chapter), .w("in")], x: 0, line: 1)
            if st == 1 && spot { A1.note(&rec, "spi", "\(P.n)", x: e - 2, y: 3.5) }
        }
        if st >= 3 {
            let e = M7.row(&rec, "rcm", [st == 3 ? .box("cm", cells: 2) : .n(P.cm, .chapter), .w("cm")], x: Self.cmX, line: 1)
            if st == 3 && spot { A1.note(&rec, "spc", "\(P.cm)", x: e - 2, y: 3.5) }
        }
        if st == 1 && ring { KK.hintBox(&pic, "hw", x: 0, y: IY + 3, w: 5 * Double(P.n), h: 1.5) }
        if st == 3 && ring { KK.hintBox(&pic, "hw", x: 0, y: CY - 1, w: 2 * Double(P.cm), h: 1) }
        // one inch and one centimeter lift out of the rulers and lie side by side
        if st == 5 {
            let PY = Self.PY
            func pieces(_ p: inout GridPen, _ yi: Double, _ yc: Double, _ xc: Double) {
                p.fill("pinf", col: 0, row: yi, w: 5, h: 3, .tint(0.4)); p.sketch.box("pino", p.R(0, yi, 5, 3), .chapter, width: Sketch.stroke)
                p.fill("pcmf", col: xc, row: yc, w: 2, h: 3, .tint(0.4)); p.sketch.box("pcmo", p.R(xc, yc, 2, 3), .chapter, width: Sketch.stroke)
            }
            L5.seeded(&pic, was: { p in pieces(&p, IY, CY, 0) }) { p in pieces(&p, PY, PY, 8) }
            pic.label("pinl", "1 in", KK.lit, .below, edge: PY + 3, along: 2.5)
            pic.label("pcml", "1 cm", KK.lit, .below, edge: PY + 3, along: 9)
        }
        let wide = W + 2 + KK.width("\(P.cmax) cm", KK.words)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(-1, 0, wide + 1, CY + 3))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = TwoUnits2.Parts(s.numbers), st = at(s), W = 5 * Double(P.imax)
        switch st {
        case 0:
            let top = P.imax
            return LN2.hopHands(s, "hi", box: "hi", band: (Self.IY - 0.5)...Self.TY, xr: 0...W,
                                at: { x in max(0, min(top, Int((x / 5).rounded()))) }, clears: { f, _ in f != 0 })
        case 2:
            let top = P.cmax
            return LN2.hopHands(s, "hc", box: "hc", band: (Self.TY + 2)...(Self.CY + 3.5), xr: 0...W,
                                at: { x in max(0, min(top, Int((x / 2).rounded()))) }, clears: { f, _ in f != 0 })
        case 4:
            return Hands(tap: { q in
                if q.x >= -0.3, q.x <= W + 0.3, q.y >= Self.IY - 0.3, q.y <= Self.IY + 3.3 { return HandMove(hand: nil, missHand: nil, set: [("b", 1)], check: true) }
                if q.x >= -0.3, q.x <= W + 0.3, q.y >= Self.CY - 0.3, q.y <= Self.CY + 3.3 { return HandMove(hand: nil, missHand: nil, set: [("b", 2)], check: true) }
                return nil
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = TwoUnits2.Parts(s.numbers)
        switch at(s) {
        case 0: return [.drag(from: CGPoint(x: 0, y: Self.IY + 3.5), to: CGPoint(x: 5 * Double(P.n), y: Self.IY + 3.5))]
        case 2: return [.drag(from: CGPoint(x: 0, y: Self.CY - 0.5), to: CGPoint(x: 2 * Double(P.cm), y: Self.CY - 0.5))]
        case 4: return [.tap(.picture(CGPoint(x: 2.5, y: Self.IY + 1.5)))]
        default: return []
        }
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = TwoUnits2.Parts(s.numbers)
        switch at(s) {
        case 0: return LN2.hopMove("hi", box: "hi", from: 0, to: P.n - 1)
        case 2: return LN2.hopMove("hc", box: "hc", from: 0, to: P.cm + 1)
        case 4: return HandMove(hand: nil, missHand: nil, set: [("b", 2)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = TwoUnits2.Parts(s.numbers)
        switch at(s) {
        case 1: return ["in": Double(P.cm)]
        case 3: return ["cm": Double(P.n)]
        default: return nil
        }
    }
}
