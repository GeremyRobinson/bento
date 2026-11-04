import SwiftUI

/// Count to 100 on the paper, as in the preview (design/prototype/gradeK-ch5.html, lCount100). One block is one number: the
/// hundred chart, 10 × 10 blocks, numbers small (20) in their blocks; the three rows in play are drawn. Count on: the chart
/// written up to the start (ringed); tap the next empty block, then the next, each writing its number in the chapter's
/// colour (a tap anywhere else: "41 comes next. It starts the next row.", that block red). Which goes here?: the rows
/// written but one block, dashed; tap its number from three under the chart (a wrong one: that number's block lights where
/// it really is). Then the See, as the preview's: the words and the record step aside and the camera frames the whole chart
/// alone (the rows glide down to their places, the rest drawing in), the last column lights, 10, 20, … 100; then back to
/// the three rows with the last line (call of 4 Nov: the chart alone shows at 66%+, not 53% under the words).
///
/// Kept: "w" how many are written (count on), "bad" a block tapped that's wrong, "seeAt" when the right move was made.
@MainActor
struct CountHundredLesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let keys = 20.0

    /// The chart's block for v, when its first row drawn is `top` (the done step draws every row, top 0).
    static func block(_ v: Int, top: Int) -> CGPoint { CGPoint(x: 5 * Double((v - 1) % 10), y: 5 * Double(CountTo100.row(v) - top)) }
    static func mid(_ v: Int, top: Int) -> CGPoint { let b = block(v, top: top); return CGPoint(x: b.x + 2.5, y: b.y + 2.5) }
    private func key(_ i: Int) -> CGPoint { KT.keyAt(i, x: 5, y: Self.keys, w: 10, step: 15) }
    /// How long the whole chart shows alone: the glide, the column lighting row by row, a rest.
    static let see = 5.6
    /// After the see: Next problem three rows under the three rows in play.
    func blocksAt(_ s: PaperState) -> CGPoint? { at(s) == 2 ? CGPoint(x: 0, y: 18) : nil }
    func alone(_ s: PaperState) -> Bool { at(s) == 2 && PaperClock.now - (s.run.kept["seeAt"] ?? -100) < Self.see }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = CountTo100.Parts(s.numbers), st = at(s), done = st == 2, see = done && alone(s)
        let top = see ? 0 : P.top, r0 = see ? 0 : P.top, r1 = see ? 9 : P.top + 2
        let w = done ? P.m : Int((s.run.kept["w"] ?? 0).rounded())
        let (pick, wrong) = KK.typed(s, "x", want: P.n)
        let gap = !P.on && !done ? P.n : nil
        var pic = GridPen()
        // each row's lines as one part (it glides down when the whole chart is drawn); the missing number's block dashed
        for r in r0...r1 {
            var segs: [(CGPoint, CGPoint)] = []
            let y = 5 * Double(r - top)
            for c in 0..<10 {
                let v = 10 * r + c + 1, x = 5 * Double(c)
                func edge(_ a: (Double, Double), _ b: (Double, Double), _ other: Int?) {
                    if let g = gap, v == g || other == g { return }
                    segs.append((pic.P(a.0, a.1), pic.P(b.0, b.1)))
                }
                edge((x, y), (x + 5, y), r > 0 ? v - 10 : nil)
                if r == r1 { edge((x, y + 5), (x + 5, y + 5), r < 9 ? v + 10 : nil) }
                edge((x, y), (x, y + 5), c > 0 ? v - 1 : nil)
                if c == 9 { edge((x + 5, y), (x + 5, y + 5), nil) }
            }
            pic.sketch.segments("row\(r)", segs, .ink, width: Sketch.stroke)
        }
        if let g = gap { let b = Self.block(g, top: top); pic.sketch.box("gap", pic.R(b.x, b.y, 5, 5), .ink3, width: Sketch.stroke, dashed: true) }
        // the last column lights, a row after another (the see)
        if done {
            for r in r0...r1 {
                pic.sketch.delay = see ? 0.9 + 0.28 * Double(r) : 0
                pic.fill("lit\(r)", col: 45, row: 5 * Double(r - top), w: 5, h: 5, KK.litCube)
            }
            pic.sketch.delay = 0
        }
        // the numbers: written up to the start and those counted (count on), all but the gap (which)
        for r in r0...r1 {
            for c in 0..<10 {
                let v = 10 * r + c + 1, b = Self.block(v, top: top)
                let counted = P.on && v > P.s && v <= P.s + w, lit = done && c == 9
                let shown = P.on ? v <= P.s + w || lit : v != gap
                let mine = counted || lit || (!P.on && v == P.n)
                if (counted || (!P.on && v == P.n && done)) && !lit { pic.fill("cf\(v)", col: b.x, row: b.y, w: 5, h: 5, KK.cube) }
                if lit && see { pic.sketch.delay = 0.9 + 0.28 * Double(r) }
                if shown { pic.word("cn\(v)\(mine ? "c" : "")", "\(v)", at: b.x + 2.5, b.y + 2.5, mine ? KT.smallLit : KT.small) }
                pic.sketch.delay = 0
            }
        }
        if P.on {
            let a = Self.mid(P.s, top: top); pic.circle("start", at: a.x, a.y, radius: 2.05, .chapter)
            if done && !see { let e = Self.mid(P.e, top: top); pic.circle("end", at: e.x, e.y, radius: 2.05, .chapter) }
        }
        if !done {
            if let bad = KA.kept(s, "bad"), P.on { let b = Self.block(bad, top: top); pic.sketch.box("bad\(bad)", pic.R(b.x, b.y, 5, 5), KK.red, width: Sketch.stroke) }
            if P.on {
                let next = P.s + w + 1
                if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: 5 * Double(CountTo100.row(next) - top), w: 50, h: 5) }
                if s.on("spot") { let m = Self.mid(next, top: top); KK.hint(&pic, "spot", m.x, m.y) }
            } else {
                // a wrong pick: where that number really is, lit
                if wrong, let v = pick { let b = Self.block(v, top: top); pic.fill("wl\(v)", col: b.x, row: b.y, w: 5, h: 5, KK.litCube) }
                KT.keys(&pic, "ch", P.choices, x: 5, y: Self.keys, w: 10, step: 15, wrong: wrong ? pick : nil, spot: s.on("spot") ? P.n : nil)
                if s.on("ring") && !s.on("spot") {
                    for v in [P.n - 1, P.n + 1] where (1...100).contains(v) { let m = Self.mid(v, top: top); KK.hint(&pic, "hr\(v)", m.x, m.y) }
                }
            }
        }
        return PaperDrawing(picture: pic.sketch)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = CountTo100.Parts(s.numbers), top = P.top
        switch at(s) {
        case 0:
            let w = Int((s.run.kept["w"] ?? 0).rounded()), next = P.s + w + 1
            return Hands(tap: { q in
                guard q.x >= 0, q.x < 50, q.y >= 0, q.y < 15 else { return nil }
                let v = 10 * (top + Int(q.y / 5)) + Int(q.x / 5) + 1
                if v == next {
                    let full = w + 1 == P.m
                    return HandMove(hand: nil, missHand: nil, set: full ? [("k", Double(P.m))] : [], keep: ["w": Double(w + 1), "bad": -1, "seeAt": PaperClock.now], check: full)
                }
                // the start and what's written already are tapped for nothing
                if v <= P.s + w { return HandMove(hand: nil) }
                return HandMove(hand: nil, missHand: nil, set: [("k", Double(-next))], keep: ["bad": Double(v)], check: true)
            })
        case 1:
            return Hands(tap: { q in KT.keyTapped(q, P.choices, x: 5, y: Self.keys, w: 10, step: 15).map { HandMove(hand: nil, missHand: nil, set: [("x", Double($0))], keep: ["seeAt": PaperClock.now], check: true) } })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = CountTo100.Parts(s.numbers)
        switch at(s) {
        case 0:
            let w = Int((s.run.kept["w"] ?? 0).rounded())
            return ((P.s + w + 1)...P.e).map { .tap(.picture(Self.mid($0, top: P.top))) }
        case 1: return [.tap(.picture(key(P.choices.firstIndex(of: P.n) ?? 0)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = CountTo100.Parts(s.numbers)
        switch at(s) {
        case 0:
            // a tap a block too far on
            let next = P.s + 1, v = next + 1
            return HandMove(hand: nil, missHand: nil, set: [("k", Double(-next))], keep: ["bad": Double(v)], check: true)
        case 1: return HandMove(hand: nil, missHand: nil, set: [("x", Double(P.choices.first { $0 != P.n } ?? 0))], check: true)
        default: return nil
        }
    }
}
