import SwiftUI

/// Add to take away on the paper, as in the preview (design/prototype/grade1-ch2.html, dRelated): the whole as a row of c
/// places outlined in ink on row 0, named at its end; under it on row 4 the a counters, the rest of that row empty; the
/// problem c − a as the record's first line. Drag the bottom row's end out: striped counters fill in behind the finger,
/// counted 1, 2, 3 under them ("8 + 4"). Let go level with the whole's end: the row lifts into the whole, which shows a | b.
/// Write the take away on the number row; the other facts of the family draw in under it.
///
/// Hand: "grab", "gx", "k0", "k" the striped counters while held. Kept: "k" where the row was let go.
@MainActor
struct Related1Lesson: PaperLesson {
    var liveKeys: Set<String> { ["k"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let whole = 0.0, row = 4.0, keys = 14.0
    func recordRow(_ n: Numbers) -> Double? { 10 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Related1.Parts(s.numbers), st = at(s), a = P.a, b = P.b, c = P.c
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        E1.whole(&pic, "wh", x: 0, y: Self.whole, c)
        pic.label("wc", "\(c)", KK.maths, .right, edge: A1.x(c), along: Self.whole + 1.5)
        if st == 0 {
            for j in 0..<a { A1.counter(&pic, "A\(j)", x: A1.x(j), y: Self.row, .solid) }
            if s.grabbed {
                let k = Int(s.h("k") ?? 0)
                for j in 0..<k { A1.counter(&live, "B\(j)", x: A1.x(a + j), y: Self.row, .striped) }
                E1.counts(&live, "cn", from: a, k, y: Self.row + 4)
                if k > 0 { live.reads("\(a) + \(k)") }
            } else {
                let k = Int(s.run.kept["k"] ?? 0)
                for j in 0..<k { A1.counter(&pic, "B\(j)", x: A1.x(a + j), y: Self.row, .striped) }
            }
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: Self.whole, w: A1.x(c), h: 3) }
            if s.on("spot") { pic.sketch.box("spot", pic.R(A1.x(a), Self.row, A1.x(b), 3), .chapter, width: Sketch.stroke, dashed: true) }
        } else {
            // lifted into the whole: it shows a | b
            let was: (inout GridPen) -> Void = { p in
                for j in 0..<a { A1.counter(&p, "A\(j)", x: A1.x(j), y: Self.row, .solid) }
                for j in 0..<b { A1.counter(&p, "B\(j)", x: A1.x(a + j), y: Self.row, .striped) }
            }
            KM.seeded(&pic, was: st == 1 ? was : nil) { p in
                for j in 0..<a { A1.counter(&p, "A\(j)", x: A1.x(j), y: Self.whole, .solid) }
                for j in 0..<b { A1.counter(&p, "B\(j)", x: A1.x(a + j), y: Self.whole, .striped) }
            }
            pic.sketch.delay = 0.5
            pic.line("split", [(A1.x(a), Self.whole - 0.6), (A1.x(a), Self.whole + 3.6)], .chapter)
            E1.bracket(&pic, "pa", 0.3, A1.x(a) - 0.3, y: Self.whole + 3.6, "\(a)")
            E1.bracket(&pic, "pb", A1.x(a) + 0.3, A1.x(c) - 0.3, y: Self.whole + 3.6, "\(b)", .chapter, words: KK.maths.colour(.chapter))
            pic.sketch.delay = 0
        }

        switch st {
        case 0: A1.record(&rec, "rec", [.n(c), .op("−"), .n(a)])
        case 1:
            let (v, wrong) = KK.typed(s, "x", want: b)
            A1.record(&rec, "rec", [.n(c), .op("−"), .n(a), .op("="), .box(v, wrong: wrong)])
            A1.numberRow(&pic, "nr", y: Self.keys, wrong: wrong ? v : nil, spot: s.on("spot") ? b : nil)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: A1.x(a), y: Self.whole, w: A1.x(b), h: 3) }
        default:
            A1.record(&rec, "rec", [.n(c), .op("−"), .n(a), .op("="), .n(b, .chapter)])
            // the family draws in under it, one after another
            let fam: [[A1.Tok]] = [[.n(a), .op("+"), .n(b), .op("="), .n(c)], [.n(b), .op("+"), .n(a), .op("="), .n(c)], [.n(c), .op("−"), .n(b), .op("="), .n(a)]]
            for (i, t) in fam.enumerated() {
                rec.sketch.delay = 0.4 + 0.4 * Double(i)
                A1.record(&rec, "fam\(i)", t, line: 1 + 3 * Double(i + 1))
            }
            rec.sketch.delay = 0
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Related1.Parts(s.numbers)
        switch at(s) {
        case 0:
            let k0 = Int(s.run.kept["k"] ?? 0), most = P.c + 1 - P.a
            return Hands(
                grab: { q in
                    guard q.y >= Self.row - 0.5, q.y <= Self.row + 3.5, q.x >= -0.5, q.x <= A1.x(P.a + k0) + 3.5 else { return nil }
                    return ["grab": 1, "gx": q.x, "k0": Double(k0), "k": Double(k0)]
                },
                drag: { q, held in
                    var held = held
                    let dk = Int(((q.x - (held["gx"] ?? q.x)) / 3).rounded())
                    held["k"] = Double(max(0, min(most, Int(held["k0"] ?? 0) + dk)))
                    return held
                },
                release: { held in
                    let k = Int(held["k"] ?? 0)
                    guard k > 0 else { return HandMove(hand: [:], keep: ["k": 0]) }
                    return HandMove(hand: [:], missHand: [:], set: [("k", Double(k))], keep: ["k": Double(k)], check: true)
                })
        case 1: return A1.rowHands("x", y: Self.keys)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Related1.Parts(s.numbers)
        switch at(s) {
        case 0:
            let k0 = Int(s.run.kept["k"] ?? 0), from = A1.x(P.a + k0) - 1.5
            return [.drag(from: CGPoint(x: from, y: Self.row + 1.5), to: CGPoint(x: from + 3 * Double(P.b - k0), y: Self.row + 1.5))]
        case 1: return [.tap(.picture(A1.keySpot(P.b, y: Self.keys)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Related1.Parts(s.numbers)
        switch at(s) {
        case 0: return HandMove(hand: [:], missHand: [:], set: [("k", Double(P.b + 1))], keep: ["k": Double(P.b + 1)], check: true)
        case 1: return A1.slip("x", P.b)
        default: return nil
        }
    }
}
