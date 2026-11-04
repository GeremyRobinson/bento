import SwiftUI

/// Compare two-digit numbers on the paper, as in the preview (design/prototype/grade1-ch3.html, dCompare). Both numbers as
/// tens (closed rows of ten, touching) and ones (a square under them), side by side, a block and a square between; each
/// number written over its stack, so the problem is the picture's names and the record is that line. Tap a number (or its
/// stack): the one with more tens (same tens: the ones, lit). It's ringed. Then tap the sign, < = and > in the gap: it's
/// written between them. The readouts beside the numbers say their tens (and ones, once they decide).
///
/// Kept: "wp" a side picked that's wrong (0 left, 1 right), "ws" a sign tapped that's wrong.
@MainActor
struct Compare1Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let line = 1.0, top = 3.0, bx = 36.0, gx = 31.0
    /// The ones a square under the tens (touching them under 9 tens, so 9 tens and 9 ones show at 75%).
    static func gap(_ t: Int) -> Double { t > 0 && t < 9 ? 1 : 0 }
    static func hOf(_ t: Int, _ o: Int) -> Double { 3 * Double(t) + (o > 0 ? 3 + gap(t) : 0) }
    static func signY(_ i: Int) -> Double { top + 5 * Double(i) }

    private func width(_ v: Int) -> Double { KK.width("\(v)", KK.maths) }
    /// The middle of a side's number on the record line.
    private func numMid(_ side: Int, _ P: Compare1.Parts) -> CGPoint {
        side == 0 ? CGPoint(x: 30 - width(P.a) / 2, y: Self.line) : CGPoint(x: Self.bx + width(P.b) / 2, y: Self.line)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Compare1.Parts(s.numbers), st = at(s)
        var pic = GridPen()
        let onesLit = st > 0 && P.same
        func stack(_ K: String, _ x: Double, _ t: Int, _ o: Int) {
            for r in 0..<t {
                let y = Self.top + 3 * Double(r)
                for j in 0..<10 { A1.counter(&pic, "\(K)c\(r)-\(j)", x: x + A1.x(j), y: y, .solid) }
                for j in 1..<10 { pic.line("\(K)d\(r)-\(j)", [(x + A1.x(j), y), (x + A1.x(j), y + 3)], .ink3, dashed: true) }
                pic.sketch.box("\(K)g\(r)", pic.R(x, y, 30, 3), .chapter, width: Sketch.stroke)
            }
            let y = Self.top + 3 * Double(t) + Self.gap(t)
            for j in 0..<o {
                pic.sketch.box("\(K)oo\(j)", pic.R(x + A1.x(j), y, 3, 3), .ink2, width: Sketch.stroke)
                A1.counter(&pic, "\(K)o\(j)", x: x + A1.x(j), y: y, .solid)
            }
            if onesLit && o > 0 { pic.sketch.box("\(K)lit", pic.R(x - 0.5, y - 0.5, A1.x(o) + 1, 4), .chapter, width: Sketch.stroke, dashed: true) }
        }
        stack("A", 0, P.ta, P.ao); stack("B", Self.bx, P.tb, P.bo)
        // the record: the numbers over their stacks (a wrong pick red), the sign between them once it's found
        let wp = st < 2 ? KA.kept(s, "wp") : nil
        pic.word("nA\(wp == 0)", "\(P.a)", at: 30, Self.line, wp == 0 ? KK.maths.colour(KK.red) : KK.maths, anchor: UnitPoint(x: 1, y: 0.5))
        pic.word("nB\(wp == 1)", "\(P.b)", at: Self.bx, Self.line, wp == 1 ? KK.maths.colour(KK.red) : KK.maths, anchor: UnitPoint(x: 0, y: 0.5))
        if st >= 2 && P.a != P.b { let m = numMid(P.big, P); pic.circle("pk\(P.big)", at: m.x, m.y, radius: max(2.05, width(P.bn) / 2 + 0.6), .chapter) }
        if st == 3 { pic.word("sg", Compare1.signs[P.sign], at: Self.gx + 2, Self.line, KK.maths) }
        // the readouts: each number's tens (and ones, once they decide), beside it
        if st > 0 && st < 3 {
            let both = onesLit
            func ro(_ t: Int, _ o: Int) -> String { both ? "\(Num1.pl(t, "ten", "tens")), \(Num1.pl(o, "one", "ones"))" : Num1.pl(t, "ten", "tens") }
            pic.word("roA\(both)", ro(P.ta, P.ao), at: 30 - width(P.a) - 2.5, Self.line, KK.lit, anchor: UnitPoint(x: 1, y: 0.5))
            pic.word("roB\(both)", ro(P.tb, P.bo), at: Self.bx + width(P.b) + 2.5, Self.line, KK.lit, anchor: UnitPoint(x: 0, y: 0.5))
        }
        switch st {
        case 0, 1:
            if s.on("ring") && !s.on("spot") {
                if st == 0 {
                    KK.hintBox(&pic, "hrA", x: 0, y: Self.top, w: 30, h: max(3, 3 * Double(P.ta)))
                    KK.hintBox(&pic, "hrB", x: Self.bx, y: Self.top, w: 30, h: max(3, 3 * Double(P.tb)))
                } else {
                    let y = Self.top + 3 * Double(P.ta) + Self.gap(P.ta)
                    // the ones, lit already: the ring is round them
                    if P.ao > 0 { KK.hintBox(&pic, "hrA", x: 0, y: y, w: A1.x(P.ao), h: 3) }
                    if P.bo > 0 { KK.hintBox(&pic, "hrB", x: Self.bx, y: Self.top + 3 * Double(P.tb) + Self.gap(P.tb), w: A1.x(P.bo), h: 3) }
                }
            }
            if s.on("spot") { let m = numMid(P.big, P); KK.hint(&pic, "spot", m.x, m.y) }
        case 2:
            let ws = KA.kept(s, "ws")
            for (i, g) in Compare1.signs.enumerated() {
                let y = Self.signY(i), bad = ws == i
                pic.sketch.box("sb\(i)\(bad)", pic.R(Self.gx, y, 4, 4), bad ? KK.red : .ink, width: Sketch.stroke)
                pic.word("st\(i)\(bad)", g, at: Self.gx + 2, y + 2, bad ? KK.maths.colour(KK.red) : KK.maths)
            }
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: Self.gx, y: Self.signY(0), w: 4, h: 14) }
            if s.on("spot") { KK.hintBox(&pic, "spot", x: Self.gx, y: Self.signY(P.sign), w: 4, h: 4) }
        default: break
        }
        return PaperDrawing(picture: pic.sketch)
    }

    /// The side tapped: its number or its stack.
    private func side(_ q: CGPoint, _ P: Compare1.Parts) -> Int? {
        let bottom = { (t: Int, o: Int) in Self.top + max(3, Self.hOf(t, o)) }
        if q.x >= -0.5, q.x <= 30.5, q.y >= 0.5, q.y <= bottom(P.ta, P.ao) { return 0 }
        if q.x >= Self.bx - 0.5, q.x <= Self.bx + 30.5, q.y >= 0.5, q.y <= bottom(P.tb, P.bo) { return 1 }
        return nil
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Compare1.Parts(s.numbers), st = at(s)
        switch st {
        case 0, 1:
            return Hands(tap: { q in
                guard let k = side(q, P) else { return nil }
                let any = st == 0 ? P.same : P.ao == P.bo
                let right = any || k == P.big
                return HandMove(hand: nil, missHand: nil, set: [("p", Double(k))], keep: ["wp": right ? -1 : Double(k)], check: true)
            })
        case 2:
            return Hands(tap: { q in
                guard q.x >= Self.gx, q.x <= Self.gx + 4,
                      let i = (0..<3).first(where: { q.y >= Self.signY($0) && q.y <= Self.signY($0) + 4 }) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("g", Double(i))], keep: ["ws": i == P.sign ? -1 : Double(i)], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Compare1.Parts(s.numbers)
        switch at(s) {
        case 0, 1: return [.tap(.picture(numMid(P.big, P)))]
        case 2: return [.tap(.picture(CGPoint(x: Self.gx + 2, y: Self.signY(P.sign) + 2)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Compare1.Parts(s.numbers), st = at(s)
        switch st {
        case 0, 1:
            let any = st == 0 ? P.same : P.ao == P.bo
            guard !any else { return nil }
            return HandMove(hand: nil, missHand: nil, set: [("p", Double(1 - P.big))], keep: ["wp": Double(1 - P.big)], check: true)
        case 2:
            let g = P.sign == 0 ? 2 : 0
            return HandMove(hand: nil, missHand: nil, set: [("g", Double(g))], keep: ["ws": Double(g)], check: true)
        default: return nil
        }
    }
}
