import SwiftUI

/// Make 10 on the paper, as in the preview (design/prototype/gradeK-ch4.html, lMake10): a big ten frame, one cell 2 × 2
/// blocks (50 × 20 squares), its dots 6 squares across in the middle of their cells. Tap each dot to count it (numbered
/// in the order tapped, the last ringed); fill the frame (a tap on each empty cell drops a striped dot in from above,
/// numbered 1, 2, 3: how many more); full, the frame is named 10 at its right end; write how many more on the number row.
///
/// Kept: "o<i>" the dots counted in order, "f<k>" the cells filled in order and "ft<k>" when, "again" a cell tapped that's
/// wrong.
@MainActor
struct MakeTenLesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let r = 3.0, keys = 28.0
    func recordRow(_ n: Numbers) -> Double? { 23 }
    /// Cell j's top-left corner: five across, two down.
    static func cell(_ j: Int) -> CGPoint { CGPoint(x: 10 * Double(j % 5), y: 10 * Double(j / 5)) }
    static func hit(_ q: CGPoint) -> Int? {
        guard q.x >= 0, q.x < 50, q.y >= 0, q.y < 20 else { return nil }
        return Int(q.x / 10) + 5 * Int(q.y / 10)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = MakeTenK.Parts(s.numbers), st = at(s), have = P.have, need = P.need, now = PaperClock.now
        var pic = GridPen(), rec = GridPen()
        pic.sketch.box("fr", pic.R(0, 0, 50, 20), .ink, width: Sketch.stroke)
        pic.sketch.segments("fl", (1..<5).map { c in (pic.P(10 * Double(c), 0), pic.P(10 * Double(c), 20)) } + [(pic.P(0, 10), pic.P(50, 10))], .ink, width: Sketch.stroke)
        let counted = st == 0 ? KA.list(s, "o") : Array(0..<have)
        let filled = st == 0 ? [] : st == 1 ? KA.list(s, "f") : Array(have..<10)
        let again = st <= 1 ? KA.kept(s, "again") : nil
        for j in 0..<have {
            let c = Self.cell(j), k = counted.firstIndex(of: j)
            if let k {
                pic.sketch.polygon("d\(j)c", circle(pic, c.x + 5, c.y + 5, Self.r), .tint(0.42))
                pic.circle("d\(j)o", at: c.x + 5, c.y + 5, radius: Self.r, .chapter)
                pic.word("d\(j)n\(k + 1)", "\(k + 1)", at: c.x + 5, c.y + 5, KK.maths)
                if counted.count == have && k == have - 1 { pic.circle("d\(j)r", at: c.x + 5, c.y + 5, radius: Self.r + 0.6, .chapter) }
            } else {
                pic.dot("d\(j)", at: c.x + 5, c.y + 5, radius: Self.r, .chapter)
            }
        }
        // the striped dots dropped in, numbered once they land; the last ringed
        let times = st == 1 ? (0..<filled.count).map { s.run.kept["ft\($0)"] ?? now } : filled.map { _ in now - 10 }
        for (k, j) in filled.enumerated() {
            let c = Self.cell(j), cx = c.x + 5, cy = c.y + 5
            KM.seeded(&pic, was: { p in stripedDot(&p, "e\(j)", cx, cy - 5) }) { p in stripedDot(&p, "e\(j)", cx, cy) }
            pic.sketch.startAt = max(now, times[k] + 0.45)
            pic.word("e\(j)n", "\(k + 1)", at: cx, cy, KK.maths)
            if k == need - 1 { pic.circle("e\(j)r", at: cx, cy, radius: Self.r + 0.6, .chapter) }
            pic.sketch.startAt = nil
        }
        if let j = again { let c = Self.cell(j); pic.sketch.box("again\(j)", pic.R(c.x + 0.5, c.y + 0.5, 9, 9), KK.red, width: Sketch.stroke) }
        // full: the frame's name at its right end
        if st >= 2 { pic.label("ten", "10", KK.maths, .right, edge: 50, along: 10) }

        switch st {
        case 0:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: 0, w: 50, h: have > 5 ? 20 : 10) }
            if s.on("spot"), let j = (0..<have).first(where: { !counted.contains($0) }) { let c = Self.cell(j); KK.hint(&pic, "spot", c.x + 5, c.y + 5, radius: Self.r + 1) }
        case 1:
            if s.on("ring") && !s.on("spot") { ringEmpty(&pic, have) }
            if s.on("spot"), let j = (have..<10).first(where: { !filled.contains($0) }) { let c = Self.cell(j); KK.hint(&pic, "spot", c.x + 5, c.y + 5, radius: Self.r + 1) }
        case 2:
            let (v, wrong) = KK.typed(s, "x", want: need)
            KA.line(&rec, "rec", [.n(have), .op("+")], value: v, wrong: wrong, [.op("="), .n(10)])
            KK.numberRow(&pic, "nr", y: Self.keys, wrong: wrong ? v : nil, spot: s.on("spot") ? need : nil)
            if s.on("ring") && !s.on("spot") { ringEmpty(&pic, have) }
        default:
            M7.row(&rec, "rec", [.n(have), .op("+"), .n(need, .chapter), .op("="), .n(10)], x: 0, line: 1)
        }
        return PaperDrawing(picture: pic.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, 53, 20))
    }

    private func circle(_ pen: GridPen, _ cx: Double, _ cy: Double, _ r: Double) -> [CGPoint] {
        (0..<32).map { i in let a = Double(i) / 32 * 2 * .pi; return pen.P(cx + r * cos(a), cy + r * sin(a)) }
    }
    /// A dot dropped into an empty cell: striped, as the second amount is (KA.dot's, twice the size).
    private func stripedDot(_ pen: inout GridPen, _ id: String, _ cx: Double, _ cy: Double) {
        pen.sketch.polygon(id + "f", circle(pen, cx, cy, Self.r), .tint(0.2))
        var segs: [(CGPoint, CGPoint)] = []
        let r = Self.r, s2 = 2.0.squareRoot()
        for k in Int((cx - cy - r * s2).rounded(.up))...Int((cx - cy + r * s2).rounded(.down)) {
            let d = (Double(k) - (cx - cy)) / s2
            guard abs(d) < r - 0.05 else { continue }
            let half = (r * r - d * d).squareRoot() / s2, mx = cx + d / s2, my = cy - d / s2
            segs.append((pen.P(mx - half, my - half), pen.P(mx + half, my + half)))
        }
        pen.sketch.segments(id + "s", segs, .tint(0.6), width: Sketch.stroke)
        pen.circle(id + "o", at: cx, cy, radius: r, .chapter)
    }
    /// A hint: the empty cells, ringed together (they're always the end of the second row, and maybe more).
    private func ringEmpty(_ pen: inout GridPen, _ have: Int) {
        // just inside the frame, clear of its name at the right end
        let r = have >= 5 ? pen.R(Self.cell(have).x + 0.5, 10.5, 49 - Self.cell(have).x, 9) : pen.R(0.5, 0.5, 49, 19)
        pen.sketch.box("hr", r, .chapter, width: Sketch.stroke, dashed: true)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = MakeTenK.Parts(s.numbers), have = P.have
        switch at(s) {
        case 0:
            let counted = KA.list(s, "o")
            return Hands(tap: { q in
                guard let j = Self.hit(q) else { return nil }
                if j >= have { return HandMove(hand: nil, missHand: nil, set: [("c", -1)], keep: ["again": Double(j)], check: true) }
                if counted.contains(j) { return HandMove(hand: nil, missHand: nil, set: [("c", -2)], keep: ["again": Double(j)], check: true) }
                let done = counted.count + 1 == have
                return HandMove(hand: nil, missHand: nil, set: done ? [("c", Double(have))] : [], keep: ["o\(counted.count)": Double(j), "again": -1], check: done)
            })
        case 1:
            let filled = KA.list(s, "f")
            return Hands(tap: { q in
                guard let j = Self.hit(q) else { return nil }
                if j < have || filled.contains(j) { return HandMove(hand: nil, missHand: nil, set: [("f", -1)], keep: ["again": Double(j)], check: true) }
                let done = filled.count + 1 == P.need
                return HandMove(hand: nil, missHand: nil, set: done ? [("f", Double(P.need))] : [],
                                keep: ["f\(filled.count)": Double(j), "ft\(filled.count)": PaperClock.now, "again": -1], check: done)
            })
        case 2:
            return Hands(tap: { q in KK.tapped(q, y: Self.keys).map { HandMove(hand: nil, missHand: nil, set: [("x", Double($0))], check: true) } })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = MakeTenK.Parts(s.numbers)
        func spot(_ j: Int) -> GhostMove { let c = Self.cell(j); return .tap(.picture(CGPoint(x: c.x + 5, y: c.y + 5))) }
        switch at(s) {
        case 0: let counted = KA.list(s, "o"); return (0..<P.have).filter { !counted.contains($0) }.map(spot)
        case 1: let filled = KA.list(s, "f"); return (P.have..<10).filter { !filled.contains($0) }.map(spot)
        case 2: return [.tap(.picture(KK.keySpot(P.need, y: Self.keys)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = MakeTenK.Parts(s.numbers)
        switch at(s) {
        case 0: return HandMove(hand: nil, missHand: nil, set: [("c", -1)], keep: ["again": Double(P.have)], check: true)
        case 1: return HandMove(hand: nil, missHand: nil, set: [("f", -1)], keep: ["again": 0], check: true)
        case 2: return HandMove(hand: nil, missHand: nil, set: [("x", Double(P.have))], check: true)
        default: return nil
        }
    }
}
