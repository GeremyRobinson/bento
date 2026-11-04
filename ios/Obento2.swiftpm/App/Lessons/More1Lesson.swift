import SwiftUI

/// How many more? on the paper, as in the preview (design/prototype/grade1-ch2.html, dMore): the story's sentences start the
/// instruction; two rows lined up from one start line on rows 0 and 5, one per child (the first named on top), each child's
/// name and number at the row's end, lines joining the pairs. How many more (or fewer): tap or drag across the counters with
/// no partner; they're ringed and counted. The bigger one unknown: drag that row out from its dashed partners. The smaller
/// one unknown: drag that row back until the extra ones show. Then write on the number row.
///
/// Hand: "grab", "gx", "k0", "k" (a row dragged) or "lit" (counted, bits). Kept: "k", "lit".
@MainActor
struct More1Lesson: PaperLesson {
    var liveKeys: Set<String> { ["k", "lit"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let top = 0.0, bottom = 5.0, under = 10.5, keys = 16.0
    func recordRow(_ n: Numbers) -> Double? { 12 }

    private func bits(_ v: Double?) -> [Int] { let b = Int(v ?? 0); return (0..<20).filter { b & (1 << $0) != 0 } }
    private func rows(_ P: More1.Parts) -> (big: Double, small: Double) { P.topBig ? (Self.top, Self.bottom) : (Self.bottom, Self.top) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = More1.Parts(s.numbers), st = at(s), y = rows(P), found = st > 0
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let held = st == 0 && s.grabbed
        let k = found ? (P.find == .diff ? 0 : P.d) : held ? Int(s.h("k") ?? 0) : Int(s.run.kept["k"] ?? 0)
        let bl = P.find == .big ? P.small + k : P.big, sl = P.find == .small ? P.big - k : P.small
        pic.line("start", [(0, Self.top - 1), (0, Self.bottom + 4)])
        var pen = held ? live : pic
        for j in 0..<bl {
            if P.find == .big && j < P.small && !found { E1.ghost(&pen, "bg\(j)", x: A1.x(j), y: y.big, .chapter) }
            else { A1.counter(&pen, "b\(j)", x: A1.x(j), y: y.big, P.find == .big && j >= P.small ? .striped : .solid) }
        }
        for j in 0..<sl {
            if P.find == .small && !found { E1.ghost(&pen, "sg\(j)", x: A1.x(j), y: y.small, .chapter) }
            else { A1.counter(&pen, "s\(j)", x: A1.x(j), y: y.small, .solid) }
        }
        // lines join the pairs
        pen.sketch.segments("pr\(min(bl, sl))", (0..<min(bl, sl)).map { j in (pen.P(A1.x(j) + 1.5, Self.top + 3), pen.P(A1.x(j) + 1.5, Self.bottom)) }, .chapter, width: Sketch.stroke)
        // the ones with no partner: ringed and counted
        let lit: [Int] = P.find == .diff ? (found ? Array(P.small..<P.big) : bits(held ? s.h("lit") : s.run.kept["lit"]))
            : P.find == .small ? Array((P.big - k)..<P.big) : []
        for j in lit { pen.circle("lit\(j)", at: A1.x(j) + 1.5, y.big + 1.5, radius: 1.65, .chapter) }
        // names at the rows' ends (the unknown child's number only once it's written)
        let known = { (f: More1.Find) in P.find != f || st == 2 }
        pen.word("nb\(known(.big))", known(.big) ? "\(P.Bg) \(P.big)" : P.Bg, at: A1.x(bl) + 1, y.big + 1.5, KK.words, anchor: UnitPoint(x: 0, y: 0.5))
        pen.word("ns\(known(.small))", known(.small) ? "\(P.Sm) \(P.small)" : P.Sm, at: A1.x(sl) + 1, y.small + 1.5, KK.words, anchor: UnitPoint(x: 0, y: 0.5))
        var ro: String?
        if P.find == .diff && !lit.isEmpty { ro = "\(lit.count) \(P.fewerQ ? "fewer" : "more")" }
        if P.find == .big && k > 0 { ro = "\(P.small) and \(k) more" }
        if P.find == .small && k > 0 { ro = "\(k) fewer" }
        if st == 0, let ro { A1.note(&pen, "ro", ro, x: 0, y: Self.under); if held { pen.reads(ro) } }
        if held { live = pen } else { pic = pen }

        let r = P.record
        switch st {
        case 0:
            let ry = P.find == .big ? y.big : y.small, end = P.find == .big ? bl : P.find == .small ? sl : P.small
            if s.on("ring") && !s.on("spot") { KK.hint(&pic, "hr", A1.x(end) - 1.5, (P.find == .diff ? y.small : ry) + 1.5, radius: 2.2) }
            if s.on("spot") {
                let (from, to, row) = P.find == .small ? (0, P.small, y.small) : (P.small, P.big, y.big)
                pic.sketch.box("spot", pic.R(A1.x(from), row, A1.x(to - from), 3), .chapter, width: Sketch.stroke, dashed: true)
            }
        case 1:
            let (v, wrong) = KK.typed(s, "x", want: P.ans)
            A1.record(&rec, "rec", [.n(r.0), .op(r.1), .n(r.2), .op("="), .box(v, wrong: wrong)])
            A1.numberRow(&pic, "nr", y: Self.keys, wrong: wrong ? v : nil, spot: s.on("spot") ? P.ans : nil)
            if s.on("ring") && !s.on("spot") {
                let (from, to, row) = P.find == .diff ? (P.small, P.big, y.big) : P.find == .big ? (0, P.big, y.big) : (0, P.small, y.small)
                KK.hintBox(&pic, "hr", x: A1.x(from), y: row, w: A1.x(to - from), h: 3)
            }
        default: A1.record(&rec, "rec", [.n(r.0), .op(r.1), .n(r.2), .op("="), .n(P.ans, .chapter)])
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = More1.Parts(s.numbers), st = at(s), y = rows(P)
        guard st == 0 else { return st == 1 ? A1.rowHands("x", y: Self.keys) : nil }
        let on = { (q: CGPoint, r: Double) in q.y >= r - 0.5 && q.y <= r + 3.5 }
        let col = { (q: CGPoint) in Int((q.x / 3).rounded(.down)) }
        if P.find == .diff {
            let lit0 = Int(s.run.kept["lit"] ?? 0)
            func add(_ b: Int, _ j: Int) -> Int { (P.small..<P.big).contains(j) ? b | (1 << j) : b }
            func done(_ b: Int) -> HandMove {
                let n = b.nonzeroBitCount
                return HandMove(hand: [:], missHand: [:], set: n == P.d ? [("m", Double(n))] : [], keep: ["lit": Double(b)], check: n == P.d)
            }
            let partner = HandMove(hand: [:], missHand: [:], set: [("m", -1)], check: true)
            return Hands(
                tap: { q in
                    let j = col(q)
                    guard j >= 0 else { return nil }
                    if (on(q, y.big) || on(q, y.small)) && j < P.small { return partner }
                    return on(q, y.big) && j < P.big ? done(add(lit0, j)) : nil
                },
                grab: { q in on(q, y.big) && col(q) >= P.small && col(q) < P.big ? ["grab": 1, "lit": Double(add(lit0, col(q)))] : nil },
                drag: { q, held in
                    var held = held
                    if on(q, y.big) { held["lit"] = Double(add(Int(held["lit"] ?? 0), col(q))) }
                    return held
                },
                release: { held in done(Int(held["lit"] ?? 0)) })
        }
        let big = P.find == .big, k0 = Int(s.run.kept["k"] ?? 0), row = big ? y.big : y.small
        let len = big ? P.small + k0 : P.big - k0, most = big ? min(16, P.big + 1) - P.small : P.big - 1
        return Hands(
            grab: { q in on(q, row) && q.x >= -0.5 && q.x <= A1.x(len) + 3.5 ? ["grab": 1, "gx": q.x, "k0": Double(k0), "k": Double(k0)] : nil },
            drag: { q, held in
                var held = held
                let dk = Int(((q.x - (held["gx"] ?? q.x)) / 3).rounded())
                held["k"] = Double(max(0, min(most, big ? k0 + dk : k0 - dk)))
                return held
            },
            release: { held in
                let k = Int(held["k"] ?? 0)
                guard k != k0 else { return HandMove(hand: [:]) }
                return HandMove(hand: [:], missHand: [:], set: [("m", Double(k))], keep: ["k": Double(k)], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = More1.Parts(s.numbers), y = rows(P)
        switch at(s) {
        case 0:
            switch P.find {
            case .diff:
                let lit = Int(s.run.kept["lit"] ?? 0)
                return (P.small..<P.big).filter { lit & (1 << $0) == 0 }.map { .tap(.picture(CGPoint(x: A1.x($0) + 1.5, y: y.big + 1.5))) }
            case .big:
                let k0 = Int(s.run.kept["k"] ?? 0), x = A1.x(P.small + k0) - 1.5
                return [.drag(from: CGPoint(x: x, y: y.big + 1.5), to: CGPoint(x: x + 3 * Double(P.d - k0), y: y.big + 1.5))]
            case .small:
                let k0 = Int(s.run.kept["k"] ?? 0), x = A1.x(P.big - k0) - 1.5
                return [.drag(from: CGPoint(x: x, y: y.small + 1.5), to: CGPoint(x: x - 3 * Double(P.d - k0), y: y.small + 1.5))]
            }
        case 1: return [.tap(.picture(A1.keySpot(P.ans, y: Self.keys)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = More1.Parts(s.numbers)
        switch at(s) {
        case 0:
            if P.find == .diff { return HandMove(hand: [:], missHand: [:], set: [("m", -1)], check: true) }
            let most = P.find == .big ? min(16, P.big + 1) - P.small : P.big - 1, k = P.d + 1 <= most ? P.d + 1 : P.d - 1
            return HandMove(hand: [:], missHand: [:], set: [("m", Double(k))], keep: ["k": Double(k)], check: true)
        case 1: return A1.slip("x", P.ans)
        default: return nil
        }
    }
}
