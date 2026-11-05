import SwiftUI

/// Inches and centimeters on the paper, as in the preview (design/prototype/grade2-ch4.html, dMeasure): an inch is a block,
/// a centimeter 2 squares. The ruler (inches 0–10, 50 squares; centimeters 0–15, 30) lies under the thing with 2 squares
/// between for the hops; dashed lines drop from the thing's ends to the marks. Hop from end to end (a drag lays the hops a
/// space at a time, the numbers under the two ends lit, the length beside the ruler); then `9 − 2 = [7] cm` 3 rows under
/// the ruler, Check beside it. The fold: two things from 0, the shorter under the longer; hop the part sticking out.
@MainActor
struct Measure2Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func RY(_ P: Measure2.Parts) -> Double { P.fold ? 7 : 4 }
    private func X(_ P: Measure2.Parts, _ v: Int) -> Double { P.per * Double(v) }
    func recordRow(_ n: Numbers) -> Double? { RY(Measure2.Parts(n)) + 6 }
    private func toks(_ P: Measure2.Parts) -> [M7.Tok] { P.minus ? [.n(P.to), .op("−"), .n(P.from), .op("=")] : [] }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = Measure2.Parts(s.numbers)
        guard at(s) >= 1 else { return nil }
        let end = M7.width(toks(P) + [.box("x", cells: 2), .w(P.u)])
        return CGPoint(x: EG2.ceil5(end + 1), y: RY(P) + 6)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Measure2.Parts(s.numbers), st = at(s), RY = RY(P), W = X(P, P.top)
        var pic = GridPen(), rec = GridPen(), live = GridPen(stableIds: true)
        // the things, lying just above the ruler; dashed lines drop from their ends to the marks
        if P.fold {
            LN2.thing(&pic, "t1", P.name, x0: 0, x1: X(P, P.to), y: 0, label: P.name)
            LN2.thing(&pic, "t2", P.name2, x0: 0, x1: X(P, P.from), y: 3, label: P.name2)
            pic.line("d1", [(X(P, P.to), 2), (X(P, P.to), RY)], .ink3, dashed: true)
            pic.line("d2", [(X(P, P.from), 5), (X(P, P.from), RY)], .ink3, dashed: true)
        } else {
            LN2.thing(&pic, "t", P.name, x0: X(P, P.from), x1: X(P, P.to), y: 0, label: P.name)
            pic.line("d1", [(X(P, P.from), 2), (X(P, P.from), RY)], .ink3, dashed: true)
            pic.line("d2", [(X(P, P.to), 2), (X(P, P.to), RY)], .ink3, dashed: true)
        }
        let c = st == 0 ? LN2.chain(s, "h") : LN2.Chain(f: P.from, t: P.to)
        let lit = c.map { $0.t != $0.f ? [$0.f, $0.t] : [$0.f] } ?? []
        LN2.ruler(&pic, "r", x0: 0, y: RY, per: P.per, max: P.top, lit: lit)
        // the hops, one space each, over the ruler's top edge
        if let c { LN2.hops(&pic, &live, held: s.grabbed, "h", c.f, c.t, x0: 0, per: P.per, row: RY, height: P.per > 2 ? 1.2 : 0.6) }
        if st == 0, let c, c.t != c.f {
            let ro = "\(abs(c.t - c.f)) \(P.u)"
            EG2.readout(&pic, ro, x: W + 2, y: RY + 1.5)
            if s.grabbed { live.reads(ro) }
        }
        // hints: a first miss rings the thing's stretch of the ruler, a second the mark to start on
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        if st == 0 {
            if ring { KK.hintBox(&pic, "hr", x: X(P, P.from), y: RY, w: X(P, P.to) - X(P, P.from), h: 3) }
            if spot { pic.circle("sp", at: X(P, P.from), RY, radius: 1, .chapter, dashed: true) }
        }
        // the record: 9 − 2 = [7] cm
        if st >= 1 {
            let last: M7.Tok = st == 2 ? .n(P.L, .chapter) : .box("x", cells: 2)
            let end = M7.row(&rec, "rec", toks(P) + [last, .w(P.u)], x: 0, line: 1)
            if st == 1 && ring { KK.hintBox(&pic, "hw", x: X(P, P.from), y: RY - 1, w: X(P, P.to) - X(P, P.from), h: 1) }
            if st == 1 && spot { A1.note(&rec, "spot", "\(P.L)", x: end + 0.5, y: 3.5) }
        }
        let wide = W + 2 + KK.width("\(P.top) \(P.u)", KK.words)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(-1, 0, wide + 1, RY + 3))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Measure2.Parts(s.numbers)
        guard at(s) == 0 else { return nil }
        let per = P.per, top = P.top
        return LN2.hopHands(s, "h", box: "h", band: -1...(RY(P) + 3.5), xr: 0...X(P, top),
                            at: { x in max(0, min(top, Int((x / per).rounded()))) },
                            clears: { f, _ in f != P.from })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Measure2.Parts(s.numbers)
        guard at(s) == 0 else { return [] }
        return [.drag(from: CGPoint(x: X(P, P.from), y: RY(P) - 0.5), to: CGPoint(x: X(P, P.to), y: RY(P) - 0.5))]
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Measure2.Parts(s.numbers)
        guard at(s) == 0 else { return nil }
        return LN2.hopMove("h", box: "h", from: P.from, to: P.to - 1)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Measure2.Parts(s.numbers)
        guard at(s) == 1 else { return nil }
        return ["x": Double(P.slips.first?.0 ?? P.L + 1)]
    }
}
