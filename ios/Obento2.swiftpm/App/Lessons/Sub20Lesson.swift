import SwiftUI

/// Subtract within 20 on the paper, as in the preview (design/prototype/grade1-ch1.html, dSub20): the line 0 to 20 on row
/// 8 with a counters over it from 0 (the tenth ends on the strong line at 10); the problem written once, a − b, as the
/// record's first line. Hop back to 10: drag left from a (it snaps a step at a time, crossing out the counters it passes,
/// "−4"), or tap where to land; then hop back the rest from 10 ("6 taken"). Write a − b = a − first − rest = 10 − rest on
/// the number row.
///
/// Hand: "grab", "n" where the hop would land. Kept: "e1", "e2" where the hops landed.
@MainActor
struct Sub20Lesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let line = 8.0, row = 5.0, keys = 16.0
    func recordRow(_ n: Numbers) -> Double? { 12 }
    static func arc(_ n: Int) -> Double { min(3.6, 1 + 0.3 * Double(n)) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Sub20.Parts(s.numbers), st = at(s), a = P.a
        var pic = GridPen(), rec = GridPen(), lv = GridPen(stableIds: true)
        let n = s.grabbed ? s.h("n").map { Int($0) } : nil
        let e1: Int? = st >= 1 ? 10 : n, e2: Int? = st >= 2 ? P.left : st == 1 ? n : nil
        for k in 0..<a {
            let crossed = (e1.map { k >= $0 } ?? false) || (e2.map { k >= $0 && k < 10 } ?? false)
            A1.counter(&pic, "A\(k)", x: A1.x(k), y: Self.row, .solid, cross: crossed)
        }
        // the hops, over the counters, each with what it takes
        if let e = e1, e < a {
            let h = Self.arc(a - e)
            A1.hop(&pic, "h1-\(e)", from: A1.x(a), to: A1.x(e), y: Self.row, h: h)
            A1.note(&pic, "h1r\(e)", "−\(a - e)", x: (A1.x(a) + A1.x(e)) / 2, y: Self.row - h - 0.9, centred: true)
        }
        if let e = e2, e < 10 {
            let h = Self.arc(10 - e), held = st == 1
            A1.hop(&pic, "h2-\(e)", from: A1.x(10), to: A1.x(e), y: Self.row, h: h)
            A1.note(&pic, "h2r\(e)\(held)", held ? "\(P.first + 10 - e) taken" : "−\(10 - e)", x: (A1.x(10) + A1.x(e)) / 2, y: Self.row - h - 0.9, centred: true)
        }
        var lit: Set<Int> = [a]
        if st >= 1 { lit.insert(10) }
        if st >= 2 { lit.insert(P.left) }
        A1.line(&pic, "nl", y: Self.line, lit: lit, ring: st == 3 ? P.left : st == 0 ? a : nil)
        if let n { live(&lv, P, st, n) }

        let full: [A1.Tok] = [.n(a), .op("−"), .n(P.b), .op("="), .n(a), .op("−"), .n(P.first), .op("−"), .n(P.rest), .op("="), .n(10), .op("−"), .n(P.rest), .op("=")]
        switch st {
        case 0, 1:
            A1.record(&rec, "rec", [.n(a), .op("−"), .n(P.b)])
            let from = st == 0 ? a : 10, to = st == 0 ? 10 : P.left
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: A1.x(to) - 3, y: Self.line - 0.5, w: A1.x(from - to) + 6, h: 3.5) }
            if s.on("spot") { KK.hint(&pic, "spot", A1.x(to), Self.line + 1.85, radius: 1.6) }
        case 2:
            let (v, wrong) = KK.typed(s, "x", want: P.left)
            A1.record(&rec, "rec", full + [.box(v, wrong: wrong)])
            A1.numberRow(&pic, "nr", y: Self.keys, wrong: wrong ? v : nil, spot: s.on("spot") ? P.left : nil)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: Self.row, w: A1.x(10), h: 3) }
        default:
            A1.record(&rec, "rec", full + [.n(P.left, .chapter)])
        }
        return PaperDrawing(picture: pic.sketch, live: lv.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    /// The readout while a hop is held.
    private func live(_ pic: inout GridPen, _ P: Sub20.Parts, _ st: Int, _ n: Int) {
        if st == 0, n < P.a { pic.reads("−\(P.a - n)") }
        if st == 1, n < 10 { pic.reads("\(P.first + 10 - n) taken") }
    }

    private func land(_ P: Sub20.Parts, _ st: Int, _ n: Int) -> HandMove {
        let from = st == 0 ? P.a : 10
        guard n != from else { return HandMove(hand: [:]) }
        if st == 0 { return HandMove(hand: [:], missHand: [:], set: [("t", Double(n))], check: true) }
        return HandMove(hand: [:], missHand: [:], set: [("r", Double(P.first + 10 - n))], check: true)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Sub20.Parts(s.numbers), st = at(s)
        switch st {
        case 0, 1:
            let from = st == 0 ? P.a : 10
            let band = { (q: CGPoint) in q.y >= Self.line - 8 && q.y <= Self.line + 3 }
            return Hands(
                tap: { q in
                    guard band(q), q.x <= A1.x(from) - 1.5, q.x >= -1.5 else { return nil }
                    return land(P, st, max(0, Int((q.x / 3).rounded())))
                },
                grab: { q in abs(q.x - A1.x(from)) <= 2.5 && band(q) ? ["grab": 1, "n": Double(from)] : nil },
                drag: { q, held in
                    var held = held
                    held["n"] = Double(max(0, min(from, Int((q.x / 3).rounded()))))
                    return held
                },
                release: { held in land(P, st, Int(held["n"] ?? Double(from))) })
        case 2: return A1.rowHands("x", y: Self.keys)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Sub20.Parts(s.numbers)
        switch at(s) {
        case 0: return [.drag(from: CGPoint(x: A1.x(P.a), y: Self.row + 1.5), to: CGPoint(x: A1.x(10), y: Self.row + 1.5))]
        case 1: return [.drag(from: CGPoint(x: A1.x(10), y: Self.row + 1.5), to: CGPoint(x: A1.x(P.left), y: Self.row + 1.5))]
        case 2: return [.tap(.picture(A1.keySpot(P.left, y: Self.keys)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Sub20.Parts(s.numbers)
        switch at(s) {
        case 0: return land(P, 0, P.a > 11 ? 11 : 9)
        case 1: return land(P, 1, P.left > 0 ? P.left - 1 : P.left + 1)
        case 2: return A1.slip("x", P.left)
        default: return nil
        }
    }
}
