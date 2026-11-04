import SwiftUI

/// Comparing decimals (4th grade) on the paper, as in the preview (design/prototype/grade4-ch6.html): two wholes side by
/// side, named by their decimals over them, ? between. Drag across each grid to shade it: whole columns (tenths) left of
/// the finger, then hundredths down the next column, the readout counting them; once it's right its count is written
/// under it. Then tap <, = or >, and the sign goes between the names.
@MainActor
struct CompareDec4Lesson: PaperLesson {
    /// The names' row, the grids' top, and the choices' row.
    static let top = 3.0, choiceRow = top + D6.side + 4
    var liveKeys: Set<String> { ["n"] }
    static let signs = CompareDec4.signs

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private static func x0(_ j: Int) -> Double { j == 0 ? 0 : D6.second }

    /// How many hundredths a finger at p shades on grid j: the columns left of it, then down the column it's in.
    static func count(_ p: CGPoint, _ j: Int) -> Int {
        let dx = p.x - x0(j), dy = p.y - top
        if dx < 0 { return 0 }
        let c = Int((dx / D6.col).rounded(.down))
        if c >= 10 { return 100 }
        let r = dy < 1 ? 0 : min(10, Int((dy / D6.col).rounded(.down)) + 1)
        return min(100, 10 * c + r)
    }
    /// Where a finger shades exactly n hundredths on grid j (Show me's ghost).
    static func spot(_ n: Int, _ j: Int) -> CGPoint {
        let c = n / 10, r = n % 10
        if n >= 100 { return CGPoint(x: x0(j) + D6.side + 0.5, y: top + D6.side / 2) }
        return CGPoint(x: x0(j) + Double(c) * D6.col + 1, y: r == 0 ? top + 0.5 : top + Double(r - 1) * D6.col + 1)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = CompareDec4.Parts(s.numbers), at = stage(s), G = D6.side, X2 = D6.second, top = Self.top, done = at >= 4
        var pic = GridPen(), live = GridPen(stableIds: true)
        let say = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)

        // the shading: the grid being shaded follows the hand (held, at once); a grid already done shows its amount
        for j in 0..<2 {
            let want = j == 0 ? P.a : P.b, shading = at == j + 1
            if at > j + 1 { D6.shade(&pic, "s\(j)", x: Self.x0(j), y: top, want, striped: j == 1) }
            else if shading, let n = s.h("n") {
                if s.grabbed { D6.shade(&live, "s\(j)", x: Self.x0(j), y: top, Int(n.rounded()), striped: j == 1) }
                else { D6.shade(&pic, "s\(j)", x: Self.x0(j), y: top, Int(n.rounded()), striped: j == 1) }
            }
        }
        D6.whole(&pic, "g1", x: 0, y: top); D6.whole(&pic, "g2", x: X2, y: top)
        if (at == 1 || at == 2), s.grabbed, let n = s.h("n") { live.reads(Dec4.hund(Int(n.rounded()))) }

        // the names over the wholes, ? (then the sign) between; each count under its whole once it's shaded right
        pic.label("nX", P.Xs, Bars.maths, .above, edge: top, along: G / 2)
        pic.label("nY", P.Ys, Bars.maths, .above, edge: top, along: X2 + G / 2)
        pic.label("sg\(done)", done ? Self.signs[P.k] : "?", Bars.maths.colour(done ? .chapter : .ink), .above, edge: top, along: G + 2)
        if at >= 2 { pic.label("c1", Dec4.hund(P.a), say, .below, edge: top + G, along: G / 2) }
        if at >= 3 { pic.label("c2", Dec4.hund(P.b), say, .below, edge: top + G, along: X2 + G / 2) }
        // a hint: the decimal to read, ringed
        if (at == 1 || at == 2) && s.on("ring") {
            let cx = at == 1 ? G / 2 : X2 + G / 2
            D6.ring(&pic, "ring", x: cx - 3, y: 0, w: 6, h: 2)
        }
        if at == 3 { Squares.choices(&pic, "ch", Self.signs, x: 0, y: Self.choiceRow, bad: s.h("bad").map { Int($0.rounded()) }) }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, extent: pic.R(0, 0, X2 + G, at == 3 ? Self.choiceRow + 2 : top + G + 3))
    }

    func hands(_ s: PaperState) -> Hands? {
        let at = stage(s), G = D6.side
        switch at {
        case 1, 2:
            let j = at - 1, x = Self.x0(j)
            return Hands(grab: { q in
                             q.x >= x - 1 && q.x <= x + G + 1 && q.y >= Self.top - 1 && q.y <= Self.top + G + 1 ? ["grab": 1, "n": Double(Self.count(q, j))] : nil
                         },
                         drag: { q, _ in ["grab": 1, "n": Double(Self.count(q, j))] },
                         release: { h in
                             let n = h["n"] ?? 0
                             return HandMove(hand: ["n": n], missHand: nil, set: [("n", n)], check: true)
                         })
        case 3:
            return Hands(tap: { q in
                guard let i = Squares.choice(at: q, Self.signs, x: 0, y: Self.choiceRow) else { return nil }
                return HandMove(hand: [:], missHand: ["bad": Double(i)], set: [("c", Double(i))], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = CompareDec4.Parts(s.numbers), at = stage(s)
        switch at {
        case 1, 2:
            let j = at - 1
            return [.drag(from: CGPoint(x: Self.x0(j) + 0.5, y: Self.top + 0.5), to: Self.spot(j == 0 ? P.a : P.b, j))]
        case 3:
            let r = Squares.choiceRects(Self.signs, x: 0, y: Self.choiceRow)[P.k]
            return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
        default: return []
        }
    }

    func messageRows(_ n: Numbers) -> Int { 2 }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = CompareDec4.Parts(s.numbers), at = stage(s)
        switch at {
        case 1, 2:
            // the slip the web names: tenths read as hundredths, hundredths as tenths, only the tenths counted
            let hh = at == 1 ? P.a : P.b, pl = at == 1 ? P.pa : P.pb, tt = hh / 10, uu = hh % 10
            let n = Double(pl == 1 ? tt : tt > 0 ? tt : 10 * uu)
            return HandMove(hand: ["n": n], missHand: nil, set: [("n", n)], check: true)
        case 3:
            let i = P.naive != P.k ? P.naive : (P.k + 1) % 3
            return HandMove(hand: [:], missHand: ["bad": Double(i)], set: [("c", Double(i))], check: true)
        default: return nil
        }
    }
}
