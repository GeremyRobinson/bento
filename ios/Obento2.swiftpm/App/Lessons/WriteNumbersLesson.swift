import SwiftUI

/// Write numbers 0 to 20 on the paper, as in the preview (design/prototype/gradeK-ch5.html, lWrite). One block is one cell
/// of a ten frame (11–20: two frames, one under the other, a block between). Two blocks right of them, the writing place:
/// 6 × 10 squares a digit. Count the dots (0: a tap on the empty frame); tap the numeral from three keys under the
/// frames; it glides up to the writing place, growing, and waits there faint, its stroke's start dot numbered. Trace it:
/// the ink follows the finger only along the stroke, from the dot; lifted early, the stroke waits where it stopped, and the
/// next stroke's dot shows once one is done. The readout says which stroke ("1 of 2").
///
/// Kept: "o<k>" the dots counted in order, "again" a dot tapped twice. Hand (the trace): "s" the stroke, "p" how far along
/// it (its points), "grab", "dead" (a touch on the numeral away from where to go on: a miss when it's let go).
@MainActor
struct WriteNumbersLesson: PaperLesson {
    var liveKeys: Set<String> { ["s", "p", "grab", "dead"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let wx = 35.0
    private func bottom(_ P: WriteK.Parts) -> Double { P.two ? 25 : 10 }
    /// The three keys: under the frames (4 squares under two, so it shows at 75%).
    private func keysY(_ P: WriteK.Parts) -> Double { bottom(P) + (P.two ? 4 : 5) }
    private func wy(_ P: WriteK.Parts) -> Double { P.two ? 5 : 0 }
    func recordRow(_ n: Numbers) -> Double? { bottom(WriteK.Parts(n)) + 2 }

    private func dot(_ j: Int) -> CGPoint { KT.cell(0, j < 10 ? 0 : 15, j % 10) }
    private func strokes(_ P: WriteK.Parts) -> [[Numerals.Pt]] { Numerals.strokes(P.n, x: Self.wx, y: wy(P)) }
    private func key(_ P: WriteK.Parts, _ i: Int) -> CGPoint { KT.keyAt(i, x: 0, y: keysY(P), w: 5, step: 10) }
    private func stroke(_ s: PaperState) -> (s: Int, p: Int) { (Int((s.h("s") ?? 0).rounded()), Int((s.h("p") ?? 0).rounded())) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = WriteK.Parts(s.numbers), st = at(s), n = P.n
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        KT.frame(&pic, "fr0", x: 0, y: 0)
        if P.two { KT.frame(&pic, "fr1", x: 0, y: 15) }
        let list = KA.list(s, "o"), counted = st == 0 ? list : (list.count == n ? list : Array(0..<n))
        for j in 0..<n {
            let p = dot(j), k = counted.firstIndex(of: j)
            KK.counter(&pic, "dot\(j)", p.x, p.y, num: k.map { $0 + 1 }, ring: st > 0 && k == n - 1)
        }
        let S = strokes(P)
        switch st {
        case 0:
            if let a = KA.kept(s, "again") { KT.again(&pic, "again\(a)", dot(a)) }
            let todo = (0..<n).filter { !counted.contains($0) }
            if s.on("ring") && !s.on("spot") {
                if n == 0 { KK.hintBox(&pic, "hr", x: 0, y: 0, w: 25, h: 10) }
                for j in todo { let p = dot(j); KK.hint(&pic, "hr\(j)", p.x, p.y) }
            }
            if s.on("spot"), let j = todo.first { let p = dot(j); pic.circle("spot", at: p.x, p.y, radius: 2.6, .chapter) }
        case 1:
            let (v, wrong) = KK.typed(s, "p", want: n)
            KT.keys(&pic, "ch", P.choices, x: 0, y: keysY(P), w: 5, step: 10, wrong: wrong ? v : nil, spot: s.on("spot") ? n : nil)
            if s.on("ring") && !s.on("spot") {
                if n == 0 { KK.hintBox(&pic, "hr", x: 0, y: 0, w: 25, h: 10) } else { let p = dot(counted[n - 1]); KK.hint(&pic, "hr", p.x, p.y, radius: 2.8) }
            }
        case 2:
            // the numeral glides up from its key to the writing place, growing, and waits there faint
            let i = P.choices.firstIndex(of: n) ?? 0, k0 = 0.16, from = key(P, i), w0 = 6 * Double(String(n).count) * k0
            let small = Numerals.strokes(n).map { st in st.map { (from.x - w0 / 2 + $0.x * k0, from.y - 0.8 + $0.y * k0) } }
            KM.seeded(&pic, was: { p in for (j, st) in small.enumerated() { KT.strip(&p, "gh\(j)", st, upTo: st.count - 1, .tint(0.16), half: 0.6 * k0) } }) { p in
                KT.band(&p, "gh", S)
            }
            let (si, pi) = stroke(s), grabbed = s.grabbed && s.h("dead") == nil
            for j in 0..<si { KT.ink(&live, "tr\(j)", S[j], upTo: S[j].count - 1) }
            if si < S.count {
                KT.ink(&live, "tr\(si)", S[si], upTo: pi)
                // the stroke's start dot, numbered, until it's begun
                if pi == 0 {
                    let p0 = S[si][0]
                    live.dot("sd\(si)", at: p0.x, p0.y, radius: 0.8, .chapter)
                    live.word("sn\(si)", "\(si + 1)", at: p0.x, p0.y, Sketch.Words(size: Sketch.small, weight: .semibold, colour: .paper))
                }
                if s.on("ring") && !grabbed { let q = S[si][pi]; KK.hint(&live, "hr", q.x, q.y, radius: 1.6) }
            }
            if grabbed { live.reads("\(si + 1) of \(S.count)") }
        default:
            KT.band(&pic, "gh", S)
            for (j, st) in S.enumerated() { KT.ink(&pic, "tr\(j)", st, upTo: st.count - 1) }
            M7.row(&rec, "rec", [.n(n, .chapter), .w(n == 1 ? "dot" : "dots")], x: 0, line: 1)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes,
                            extent: pic.R(0, 0, Self.wx + 6 * Double(String(n).count) + 1, wy(P) + 10))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = WriteK.Parts(s.numbers), st = at(s), n = P.n
        switch st {
        case 0:
            let counted = KA.list(s, "o"), spots = (0..<n).map(dot)
            return Hands(tap: { q in
                if n == 0 {
                    guard q.x >= 0, q.x <= 25, q.y >= 0, q.y <= 10 else { return nil }
                    return HandMove(hand: nil, missHand: nil, set: [("c", 0)], check: true)
                }
                guard let j = KT.hit(q, spots) else { return nil }
                if counted.contains(j) { return HandMove(hand: nil, missHand: nil, set: [("c", -1)], keep: ["again": Double(j)], check: true) }
                let done = counted.count + 1 == n
                return HandMove(hand: nil, missHand: nil, set: done ? [("c", Double(n))] : [], keep: ["o\(counted.count)": Double(j), "again": -1], check: done)
            })
        case 1:
            return Hands(tap: { q in
                KT.keyTapped(q, P.choices, x: 0, y: keysY(P), w: 5, step: 10).map { HandMove(hand: nil, missHand: nil, set: [("p", Double($0))], check: true) }
            })
        case 2:
            let S = strokes(P), (si, pi) = stroke(s)
            func near(_ q: CGPoint, _ p: Numerals.Pt, _ r: Double) -> Bool { hypot(q.x - p.x, q.y - p.y) <= r }
            func base(_ a: Int, _ b: Int) -> Numbers { ["s": Double(a), "p": Double(b)] }
            let onNumeral = { (q: CGPoint) in S.contains { $0.contains { near(q, $0, 1.2) } } }
            let miss = HandMove(hand: base(si, pi), missHand: nil, set: [("t", pi > 0 ? -2 : -1)], check: true)
            return Hands(
                tap: { q in near(q, S[si][pi], 1.6) ? HandMove(hand: base(si, pi)) : onNumeral(q) ? miss : nil },
                grab: { q in
                    if near(q, S[si][pi], 1.6) { return base(si, pi).merging(["grab": 1]) { $1 } }
                    return onNumeral(q) ? base(si, pi).merging(["grab": 1, "dead": 1]) { $1 } : nil
                },
                drag: { q, h in
                    guard h["dead"] == nil else { return h }
                    let a = Int((h["s"] ?? 0).rounded()), pts = S[a]
                    var p = Int((h["p"] ?? 0).rounded()), moved = true
                    // the ink goes on only along the stroke: to the furthest point near the finger, a little way on at a time
                    while moved {
                        moved = false
                        for i in stride(from: min(pts.count - 1, p + 10), to: p, by: -1) where near(q, pts[i], 1.4) { p = i; moved = true; break }
                    }
                    var out = h; out["p"] = Double(p); return out
                },
                release: { h in
                    let a = Int((h["s"] ?? 0).rounded()), p = Int((h["p"] ?? 0).rounded())
                    if h["dead"] != nil { return HandMove(hand: base(a, p), missHand: nil, set: [("t", p > 0 ? -2 : -1)], check: true) }
                    guard p >= S[a].count - 3 else { return HandMove(hand: base(a, p)) }
                    if a + 1 == S.count { return HandMove(hand: base(a, S[a].count - 1), missHand: nil, set: [("t", 1)], check: true) }
                    return HandMove(hand: base(a + 1, 0))
                })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = WriteK.Parts(s.numbers), n = P.n
        switch at(s) {
        case 0:
            if n == 0 { return [.tap(.picture(CGPoint(x: 12.5, y: 5)))] }
            let counted = KA.list(s, "o")
            return (0..<n).filter { !counted.contains($0) }.map { .tap(.picture(dot($0))) }
        case 1: return [.tap(.picture(key(P, P.choices.firstIndex(of: n) ?? 0)))]
        case 2:
            let S = strokes(P), (si, pi) = stroke(s)
            return (si..<S.count).map { a in
                let pts = Array(S[a][(a == si ? pi : 0)...])
                return .path(pts.enumerated().filter { $0.offset % 3 == 0 || $0.offset == pts.count - 1 }.map { CGPoint(x: $0.element.x, y: $0.element.y) })
            }
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = WriteK.Parts(s.numbers), n = P.n
        switch at(s) {
        case 0: return n == 0 ? nil : HandMove(hand: nil, missHand: nil, set: [("c", -1)], keep: ["o0": 0, "again": 0], check: true)
        case 1: return HandMove(hand: nil, missHand: nil, set: [("p", Double(P.choices.first { $0 != n } ?? 0))], check: true)
        case 2: return HandMove(hand: ["s": 0, "p": 0], missHand: nil, set: [("t", -1)], check: true)
        default: return nil
        }
    }
}
