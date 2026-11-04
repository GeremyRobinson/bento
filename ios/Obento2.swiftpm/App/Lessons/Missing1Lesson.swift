import SwiftUI

/// Missing numbers on the paper, as in the preview (design/prototype/grade1-ch2.html, dMissing): the problem a + ? = c (or
/// ? + a = c) as the record's first line; the line 0 to 20 on row 7, a ringed as the start and c flagged as the end. Hop up
/// to 10 (drag from a, or tap where to land; "+2"), then on to the flag ("+3"); one bracket over both hops, "2 + 3"; write the
/// missing number on the number row.
///
/// Hand: "grab", "n" where the hop would land.
@MainActor
struct Missing1Lesson: PaperLesson {
    var liveKeys: Set<String> { ["n"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let line = 7.0, keys = 16.0
    func recordRow(_ n: Numbers) -> Double? { 12 }
    static func arc(_ n: Int) -> Double { min(3.4, 1 + 0.3 * Double(n)) }

    private func hop(_ pen: inout GridPen, _ id: String, _ from: Int, _ to: Int) {
        let h = Self.arc(to - from)
        A1.hop(&pen, "\(id)-\(to)", from: A1.x(from), to: A1.x(to), y: Self.line, h: h)
        A1.note(&pen, "\(id)r\(to)", "+\(to - from)", x: (A1.x(from) + A1.x(to)) / 2, y: Self.line - h - 0.9, centred: true)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Missing1.Parts(s.numbers), st = at(s), a = P.a, c = P.c
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let n = s.grabbed ? s.h("n").map { Int($0) } : nil
        E1.flag(&pic, "fl", x: A1.x(c), y: Self.line)
        if st >= 1 { hop(&pic, "h1", a, 10) }
        if st >= 2 {
            hop(&pic, "h2", 10, c)
            let H = max(Self.arc(P.up), Self.arc(P.rest))
            pic.sketch.delay = 0.4
            E1.bracket(&pic, "both", A1.x(a), A1.x(c), y: Self.line - H - 2.4, "\(P.up) + \(P.rest)", up: true, .chapter, words: KK.lit)
            pic.sketch.delay = 0
        }
        if let n {
            let from = st == 0 ? a : 10
            if n > from { hop(&live, "hl", from, n); live.reads("+\(n - from)") }
        }
        var lit: Set<Int> = [a]
        if st >= 1 { lit.insert(10) }
        if st >= 2 { lit.insert(c) }
        A1.line(&pic, "nl", y: Self.line, lit: lit, ring: a)

        let q: A1.Tok
        switch st {
        case 0, 1:
            q = .op("?")
            let to = st == 0 ? 10 : c, from = st == 0 ? a : 10
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: A1.x(from), y: Self.line - 4, w: A1.x(to - from) + 3, h: 7) }
            if s.on("spot") { KK.hint(&pic, "spot", A1.x(to), Self.line + 1.85, radius: 1.6) }
        case 2:
            let (v, wrong) = KK.typed(s, "x", want: P.ans)
            q = .box(v, wrong: wrong)
            A1.numberRow(&pic, "nr", y: Self.keys, wrong: wrong ? v : nil, spot: s.on("spot") ? P.ans : nil)
            if s.on("ring") && !s.on("spot") {
                // the two hops' numbers ringed: add them
                for (f, t) in [(a, 10), (10, c)] { KK.hint(&pic, "hr\(t)", (A1.x(f) + A1.x(t)) / 2, Self.line - Self.arc(t - f) - 0.9, radius: 1.5) }
            }
        default: q = .n(P.ans, .chapter)
        }
        A1.record(&rec, "rec", P.first ? [q, .op("+"), .n(a), .op("="), .n(c)] : [.n(a), .op("+"), q, .op("="), .n(c)])
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    private func land(_ P: Missing1.Parts, _ st: Int, _ n: Int) -> HandMove {
        let from = st == 0 ? P.a : 10
        guard n > from else { return HandMove(hand: [:]) }
        return HandMove(hand: [:], missHand: [:], set: [(st == 0 ? "t" : "e", Double(n))], check: true)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Missing1.Parts(s.numbers), st = at(s)
        switch st {
        case 0, 1:
            let from = st == 0 ? P.a : 10
            let band = { (q: CGPoint) in q.y >= Self.line - 8 && q.y <= Self.line + 3 }
            return Hands(
                tap: { q in
                    guard band(q), q.x >= A1.x(from) + 1.5, q.x <= A1.x(20) + 1.5 else { return nil }
                    return land(P, st, min(20, Int((q.x / 3).rounded())))
                },
                grab: { q in abs(q.x - A1.x(from)) <= 2.5 && band(q) ? ["grab": 1, "n": Double(from)] : nil },
                drag: { q, held in
                    var held = held
                    held["n"] = Double(max(from, min(20, Int((q.x / 3).rounded()))))
                    return held
                },
                release: { held in land(P, st, Int(held["n"] ?? Double(from))) })
        case 2: return A1.rowHands("x", y: Self.keys)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Missing1.Parts(s.numbers), y = Self.line - 1
        switch at(s) {
        case 0: return [.drag(from: CGPoint(x: A1.x(P.a), y: y), to: CGPoint(x: A1.x(10), y: y))]
        case 1: return [.drag(from: CGPoint(x: A1.x(10), y: y), to: CGPoint(x: A1.x(P.c), y: y))]
        case 2: return [.tap(.picture(A1.keySpot(P.ans, y: Self.keys)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Missing1.Parts(s.numbers)
        switch at(s) {
        case 0: return land(P, 0, 11)
        case 1: return land(P, 1, P.c < 20 ? P.c + 1 : P.c - 1 > 10 ? P.c - 1 : P.c)
        case 2: return A1.slip("x", P.ans)
        default: return nil
        }
    }
}
