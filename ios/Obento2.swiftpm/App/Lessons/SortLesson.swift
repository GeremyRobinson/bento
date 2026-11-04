import SwiftUI

/// Sort and count on the paper, as in the preview (design/prototype/gradeK-ch3.html, lSort): the mixed-up pile on a
/// field of 7 × 3 blocks (one block one thing; one colour, so only the shape tells them apart), a block under it one empty
/// row per kind, each row's first block holding its kind's key and the rows starting on one line. Tap each thing of the
/// kind asked (the circled one's kind first, its key lit): it flies into its row and takes the next number; one of another
/// kind shakes ("That’s a leaf. …"). Then the field draws out and the rows rise; tap the row with the most (or the
/// fewest); the rows slide into order, most at the top; the record under them.
///
/// Kept: "o<i>" thing i's place in its row, "t<i>" when it went, "bad" the thing of another kind tapped last and "badN"
/// how many so far, "wrongRow" a row tapped and wrong.
@MainActor
struct SortLesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let rows0 = Double(SortK.down) * 5 + 5, rows1 = 0.0

    /// Thing i's place in the pile (its middle).
    static func pile(_ P: SortK.Parts, _ i: Int) -> (Double, Double) {
        let c = P.cells[i]; return (Double(c % SortK.across) * 5 + 2.5, Double(c / SortK.across) * 5 + 2.5)
    }
    private func slot(_ s: PaperState, _ i: Int) -> Int? { s.run.kept["o\(i)"].map { Int($0.rounded()) }.flatMap { $0 >= 0 ? $0 : nil } }
    /// Row i's top: under the field while sorting, risen after, in count order once seen.
    private func rowY(_ s: PaperState, _ P: SortK.Parts, _ i: Int) -> Double {
        switch at(s) {
        case 0: return Self.rows0 + 5 * Double(i)
        case 1: return Self.rows1 + 5 * Double(i)
        default: return Self.rows1 + 5 * Double(P.rank.firstIndex(of: i) ?? i)
        }
    }
    private func kindNow(_ s: PaperState, _ P: SortK.Parts) -> Int { P.order[min(P.K - 1, Int((s.picture["kind"] ?? 0).rounded()))] }
    private func inRow(_ s: PaperState, _ P: SortK.Parts, _ k: Int) -> Int { (0..<P.total).filter { P.kindOf[$0] == k && slot(s, $0) != nil }.count }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = SortK.Parts(s.numbers), st = at(s), kinds = P.kinds, now = PaperClock.now
        var pic = GridPen()
        let want = kindNow(s, P), bad = s.run.kept["bad"].map { Int($0.rounded()) } ?? -1, badN = Int(s.run.kept["badN"] ?? 0)
        if st == 0 {
            pic.sketch.box("field", pic.R(0, 0, Double(SortK.across) * 5, Double(SortK.down) * 5), .ink, width: Sketch.stroke)
            for i in 0..<P.total where slot(s, i) == nil {
                let (cx, cy) = Self.pile(P, i), g = kinds[P.kindOf[i]].glyph
                if i == bad {
                    // the one of another kind tapped: it shakes where it is (swinging in from a square aside), outlined red
                    pic.sketch.swings = true
                    KM.seeded(&pic, was: { p in KM.glyph(&p, "it\(i)x\(badN)", g, cx + 0.9, cy, edge: KK.red) }) { p in KM.glyph(&p, "it\(i)x\(badN)", g, cx, cy, edge: KK.red) }
                    pic.sketch.swings = false
                } else { KM.glyph(&pic, "it\(i)", g, cx, cy) }
                if i == P.circled { pic.circle("circ", at: cx, cy, radius: 2.3, .chapter) }
            }
        }
        // the rows: a key in each one's first block, the start line after it; the things counted into it, numbered
        let ys = (0..<P.K).map { rowY(s, P, $0) }
        pic.line("rstart", [(5, ys.min() ?? 0), (5, (ys.max() ?? 0) + 5)])
        let wrongRow = st == 1 ? s.run.kept["wrongRow"].map { Int($0.rounded()) }.flatMap { $0 >= 0 ? $0 : nil } : nil
        for i in 0..<P.K {
            let y = ys[i], lit = st == 0 && i == want, badRow = wrongRow == i
            if lit { pic.fill("keyl\(i)", col: 0, row: y, w: 5, h: 5, .tint(0.42)) }
            pic.sketch.box("key\(i)\(badRow)", pic.R(0, y, 5, 5), badRow ? KK.red : .ink, width: Sketch.stroke)
            KM.glyph(&pic, "kg\(i)", kinds[i].glyph, 2.5, y + 2.5, over: true)
            let things = (0..<P.total).filter { P.kindOf[$0] == i && slot(s, $0) != nil }.sorted { (slot(s, $0) ?? 0) < (slot(s, $1) ?? 0) }
            for it in things {
                let k = slot(s, it) ?? 0, tx = 5 + 5 * Double(k) + 2.5, ty = y + 2.5, (px, py) = Self.pile(P, it), g = kinds[i].glyph
                // it flies from its place in the pile into its row (from the pile's place, the first time it's drawn)
                KM.seeded(&pic, was: st == 0 ? { p in KM.glyph(&p, "rg\(it)", g, px, py, fill: .tint(0.42), detail: false) } : nil) { p in
                    KM.glyph(&p, "rg\(it)", g, tx, ty, fill: .tint(0.42), detail: false)
                }
                pic.sketch.startAt = max(now, (s.run.kept["t\(it)"] ?? 0) + 0.6)
                pic.word("rn\(it)", "\(k + 1)", at: tx, ty, KK.count)
                pic.sketch.startAt = nil
            }
            if things.count == P.counts[i] {
                let n = P.counts[i]
                pic.circle("rr\(i)", at: 5 + 5 * Double(n - 1) + 2.5, y + 2.5, radius: 2.05, .chapter)
                pic.label("rc\(i)", "\(n)", badRow ? KK.maths.colour(KK.red) : KK.maths, .right, edge: 5 + 5 * Double(n), along: y + 2.5)
            }
        }
        let maxC = Double(P.counts.max() ?? 1)
        switch st {
        case 0:
            // a hint: the kind's key; a second miss, the next one of it in the pile
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: ys[want], w: 5, h: 5) }
            if s.on("spot"), let i = (0..<P.total).first(where: { P.kindOf[$0] == want && slot(s, $0) == nil }) {
                let (cx, cy) = Self.pile(P, i); KK.hint(&pic, "spot", cx, cy)
            }
        case 1:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 5, y: ys.min() ?? 0, w: 5 * maxC + 3, h: 5 * Double(P.K)) }
            if s.on("spot") { KK.hintBox(&pic, "spot", x: 0, y: ys[P.right], w: 5 + 5 * Double(P.counts[P.right]) + 3, h: 5) }
        default:
            KS.line(&pic, "rec", [.w(P.record)], x: 0, line: Self.rows1 + 5 * Double(P.K) + 4)
        }
        let w = max(st == 0 ? Double(SortK.across) * 5 : 0, 5 + 5 * maxC + 3)
        let room = st == 0 ? pic.R(0, 0, w, Self.rows0 + 5 * Double(P.K)) : pic.R(0, 0, w, 5 * Double(P.K))
        return PaperDrawing(picture: pic.sketch, extent: room)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = SortK.Parts(s.numbers)
        switch at(s) {
        case 0:
            let want = kindNow(s, P), j = Int((s.picture["kind"] ?? 0).rounded()), have = inRow(s, P, want)
            return Hands(tap: { q in
                guard let i = (0..<P.total).first(where: { slot(s, $0) == nil && abs(q.x - Self.pile(P, $0).0) <= 2.5 && abs(q.y - Self.pile(P, $0).1) <= 2.5 }) else { return nil }
                let k = P.kindOf[i]
                if k != want {
                    return HandMove(hand: nil, missHand: nil, set: [("s\(j)", Double(-(k + 1)))], keep: ["bad": Double(i), "badN": (s.run.kept["badN"] ?? 0) + 1], check: true)
                }
                let done = have + 1 == P.counts[want]
                return HandMove(hand: nil, missHand: nil, set: done ? [("s\(j)", Double(P.counts[want]))] : [],
                                keep: ["o\(i)": Double(have), "t\(i)": PaperClock.now, "bad": -1], check: done)
            })
        case 1:
            return Hands(tap: { q in
                guard let i = (0..<P.K).first(where: { let y = rowY(s, P, $0); return q.y >= y && q.y <= y + 5 && q.x >= 0 && q.x <= 5 + 5 * Double(P.counts[$0]) + 3 }) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("c", Double(i))], keep: ["wrongRow": i == P.right ? -1 : Double(i)], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = SortK.Parts(s.numbers)
        switch at(s) {
        case 0:
            let want = kindNow(s, P)
            return (0..<P.total).filter { P.kindOf[$0] == want && slot(s, $0) == nil }.map { i in let (x, y) = Self.pile(P, i); return .tap(.picture(CGPoint(x: x, y: y))) }
        case 1: return [.tap(.picture(CGPoint(x: 2.5, y: rowY(s, P, P.right) + 2.5)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = SortK.Parts(s.numbers)
        switch at(s) {
        case 0:
            let want = kindNow(s, P), j = Int((s.picture["kind"] ?? 0).rounded())
            guard let i = (0..<P.total).first(where: { P.kindOf[$0] != want && slot(s, $0) == nil }) else { return nil }
            return HandMove(hand: nil, missHand: nil, set: [("s\(j)", Double(-(P.kindOf[i] + 1)))], keep: ["bad": Double(i), "badN": (s.run.kept["badN"] ?? 0) + 1], check: true)
        case 1:
            let i = (P.right + 1) % P.K
            return HandMove(hand: nil, missHand: nil, set: [("c", Double(i))], keep: ["wrongRow": Double(i)], check: true)
        default: return nil
        }
    }
}
