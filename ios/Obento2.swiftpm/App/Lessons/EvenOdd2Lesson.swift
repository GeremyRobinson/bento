import SwiftUI

/// Even and odd on the paper, as in the preview (design/prototype/grade2-ch3.html, dEvenOdd): a dot is a 3 × 3 counter.
/// The dots lie loose on a field of three rows of ten places (30 × 11, dashed), the number at its right end; Facts to 20's
/// pair frame (two rows of ten) 3 rows under it. Each tapped dot (or each one a dragging finger meets) takes the next
/// number and glides into the frame, top then bottom, column by column; each full column rings as a pair, and the readout
/// beside the frame counts by 2s ("2, 4 … 12"), then "6 pairs and 1", the last dot ringed alone. Once all are in, the
/// frame glides up into the field's place; even or odd is picked under it; then the record 3 rows under the frame,
/// `13 = [ ] + [ ] + 1`, and the word (odd) at the frame's right end.
///
/// Kept: "o0", "o1"… the dots in the order they were counted. Hand: "grab", "t0"… the dots a drag has met.
@MainActor
struct EvenOdd2Lesson: PaperLesson {
    static let PL = 3.0, RX = 32.0
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    func recordRow(_ n: Numbers) -> Double? { 10 }
    /// Even and odd, word blocks under the frame (the preview's), answered on the tap.
    private static let picks = [CGRect(x: 0, y: 10, width: 8, height: 4), CGRect(x: 10, y: 10, width: 8, height: 4)]
    /// The frame's top: under the field while counting, then in its place.
    private func fy(_ st: Int) -> Double { st == 0 ? 14 : 0 }
    private func place(_ P: EvenOdd2.Parts, _ j: Int) -> CGPoint {
        let p = P.places[j]
        return CGPoint(x: Self.PL * Double(p % 10), y: 4 * Double(p / 10))
    }
    private func slot(_ k: Int, _ fy: Double) -> CGPoint { CGPoint(x: Self.PL * Double(k / 2), y: fy + (k % 2 == 1 ? 4 : 0)) }
    /// The dots in the order they were counted: kept, then the drag's; past the counting step, all of them.
    private func order(_ s: PaperState, _ P: EvenOdd2.Parts) -> [Int] {
        var out: [Int] = []
        while let j = s.run.kept["o\(out.count)"] { out.append(Int(j.rounded())) }
        var t = 0
        while let j = s.hand["t\(t)"] { if !out.contains(Int(j)) { out.append(Int(j)) }; t += 1 }
        if at(s) > 0 && out.count < P.n { out += (0..<P.n).filter { !out.contains($0) } }
        return out
    }
    private func dotAt(_ P: EvenOdd2.Parts, _ q: CGPoint, _ counted: [Int]) -> Int? {
        (0..<P.n).first { j in
            let p = place(P, j)
            return !counted.contains(j) && q.x >= p.x - 0.3 && q.x <= p.x + Self.PL + 0.3 && q.y >= p.y - 0.3 && q.y <= p.y + Self.PL + 0.3
        }
    }
    private static func dot(_ pen: inout GridPen, _ id: String, _ p: CGPoint, num: Int?, fy: Double) {
        let cx = p.x + 1.5, cy = p.y + 1.5
        pen.dot(id + "f", at: cx, cy, radius: 1.2, .tint(0.42))
        pen.circle(id + "o", at: cx, cy, radius: 1.2, .chapter)
        if let num { pen.word("\(id)n\(num).\(Int(cy))", "\(num)", at: cx, cy, A2.small.colour(.ink)) }
    }
    /// A pair's ring: a tall rounded outline round a column of the frame.
    private static func pairRing(_ pen: inout GridPen, _ id: String, x: Double, y: Double) {
        let w = 2.7, h = 7.3, r = w / 2
        var pts: [(Double, Double)] = []
        for i in 0...12 { let a = Double.pi + Double(i) / 12 * .pi; pts.append((x + r + r * cos(a), y + r + r * sin(a))) }
        for i in 0...12 { let a = Double(i) / 12 * .pi; pts.append((x + r + r * cos(a), y + h - r + r * sin(a))) }
        pts.append(pts[0])
        pen.line(id, pts, .chapter)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = EvenOdd2.Parts(s.numbers), st = at(s), n = P.n, FY = fy(st), PL = Self.PL
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let counted = order(s, P), k = counted.count
        // the field's places while dots lie on it
        if st == 0 {
            for p in 0..<30 { pic.sketch.box("fp\(p)", pic.R(PL * Double(p % 10), 4 * Double(p / 10), PL, PL), .ink3, width: Sketch.stroke, dashed: true) }
        }
        // the frame and what's in it glide (up into the field's place once all are counted)
        pic.sketch.morphs = true
        for b in 0..<2 { A1.places(&pic, "pp\(b)", x: 0, y: FY + 4 * Double(b)) }
        for c in 0..<k / 2 { Self.pairRing(&pic, "pr\(c)", x: PL * Double(c) + 0.15, y: FY - 0.15) }
        if k == n && P.odd { pic.circle("lone", at: PL * Double(P.pairs) + 1.5, FY + 1.5, radius: 1.5, .chapter) }
        for j in 0..<n {
            if let o = counted.firstIndex(of: j) { Self.dot(&pic, "d\(j)", slot(o, FY), num: o + 1, fy: FY) }
            else { Self.dot(&pic, "d\(j)", place(P, j), num: nil, fy: FY) }
        }
        pic.sketch.morphs = false
        // the number at the right end: the field's, then the frame's; written in the record from the pick on
        if st <= 1 { N2.number(&pic, "num\(st)", n, x: Self.RX, row: st == 0 ? 5.5 : 1.5) }
        // the readout beside the frame: counting by 2s, then the pairs and the one left; the word once picked
        let evens = (0..<k / 2).map { 2 * ($0 + 1) }
        let pairs = G2.count(P.pairs, "pair") + (P.odd ? " and 1" : "")
        if st == 0 && (k >= 2 || k == n) {
            let ro = k == n ? pairs : E1.run(evens)
            if s.grabbed { EG2.readout(&live, ro, x: Self.RX, y: FY + 5.5) } else { EG2.readout(&pic, ro, x: Self.RX, y: FY + 5.5) }
            if s.grabbed { live.reads(ro) }
        }
        if st == 1 { EG2.readout(&pic, pairs, x: Self.RX, y: 5.5) }
        if st >= 2 { pic.word("word", P.word, at: Self.RX, 5.5, EG2.say, anchor: UnitPoint(x: 0, y: 0.5)) }
        // hints: counting, a miss rings the dots left and a second the next; picking, the last column; writing, the top row
        let ring = s.on("ring") || s.on("spot"), spot = s.on("spot")
        if st == 0 {
            let left = (0..<n).filter { !counted.contains($0) }
            if ring { for j in left { let p = place(P, j); KK.hint(&pic, "hr\(j)", p.x + 1.5, p.y + 1.5, radius: 1.9) } }
            if spot, let j = left.first { let p = place(P, j); pic.circle("sp", at: p.x + 1.5, p.y + 1.5, radius: 1.9, .chapter) }
        }
        if st == 1 {
            let wrong = s.run.kept["pick"].map { Int($0.rounded()) }
            for (i, w) in ["even", "odd"].enumerated() { let r = Self.picks[i]; E1.block(&pic, "pk\(i)", x: r.minX, y: r.minY, w: r.width, w, wrong: wrong == i) }
            if spot { let r = Self.picks[P.odd ? 1 : 0]; KK.hintBox(&pic, "hk", x: r.minX, y: r.minY, w: r.width, h: r.height) }
        }
        if st == 1 && ring { KK.hintBox(&pic, "hp", x: PL * Double((n - 1) / 2), y: 0, w: PL, h: 7) }
        if st == 2 && ring { KK.hintBox(&pic, "hw", x: 0, y: 0, w: 30, h: 3) }
        if st == 2 && spot { A1.note(&pic, "spw", "\(P.pairs)", x: 31, y: 1.5) }
        // the record: 13 = [ ] + [ ] + 1
        if st >= 2 {
            let done = st == 3
            var toks: [M7.Tok] = [.n(n), .op("="), done ? .n(P.pairs, .chapter) : .box("a", cells: 2), .op("+"), done ? .n(P.pairs, .chapter) : .box("b", cells: 2)]
            if P.odd { toks += [.op("+"), .n(1)] }
            M7.row(&rec, "rec", toks, x: 0, line: 1)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = EvenOdd2.Parts(s.numbers), n = P.n
        if at(s) == 1 {
            return Hands(tap: { q in
                guard let i = Self.picks.firstIndex(where: { $0.insetBy(dx: -0.3, dy: -0.3).contains(q) }) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("c", Double(i))], keep: ["pick": i == (P.odd ? 1 : 0) ? -1 : Double(i)], check: true)
            })
        }
        guard at(s) == 0 else { return nil }
        var kept: [Int] = []
        while let j = s.run.kept["o\(kept.count)"] { kept.append(Int(j.rounded())) }
        func count(_ all: [Int]) -> HandMove {
            var keep: Numbers = [:]
            for (i, j) in all.enumerated() { keep["o\(i)"] = Double(j) }
            let done = all.count == n
            return HandMove(hand: [:], missHand: [:], set: done ? [("k", Double(n))] : [], keep: keep, check: done)
        }
        func met(_ h: Numbers) -> [Int] { var out: [Int] = [], t = 0; while let j = h["t\(t)"] { out.append(Int(j)); t += 1 }; return out }
        return Hands(
            tap: { q in dotAt(P, q, kept).map { count(kept + [$0]) } },
            grab: { q in dotAt(P, q, kept).map { ["grab": 1, "t0": Double($0)] } },
            drag: { q, h in
                var h = h
                let m = met(h)
                if let j = dotAt(P, q, kept + m) { h["t\(m.count)"] = Double(j) }
                return h
            },
            release: { h in count(kept + met(h)) })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = EvenOdd2.Parts(s.numbers)
        if at(s) == 1 { let r = Self.picks[P.odd ? 1 : 0]; return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))] }
        guard at(s) == 0 else { return [] }
        let counted = order(s, P)
        // along the field's rows, left to right
        let left = (0..<P.n).filter { !counted.contains($0) }.sorted { P.places[$0] < P.places[$1] }
        return left.map { let p = place(P, $0); return .tap(.picture(CGPoint(x: p.x + 1.5, y: p.y + 1.5))) }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = EvenOdd2.Parts(s.numbers)
        guard at(s) == 1 else { return nil }
        let i = P.odd ? 0 : 1
        return HandMove(hand: nil, missHand: nil, set: [("c", Double(i))], keep: ["pick": Double(i)], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = EvenOdd2.Parts(s.numbers)
        guard at(s) == 2 else { return nil }
        return P.odd ? ["a": Double(P.pairs + 1), "b": Double(P.pairs + 1)] : ["a": Double(P.pairs), "b": Double(P.pairs - 1)]
    }
}
