import SwiftUI

/// Which number is more? on the paper, as in the preview (design/prototype/gradeK-ch1.html, lNumCompare): two numerals,
/// big, each at the start of an empty ten track (they're what to build). Make each number: drag out a train on each
/// track (let go on another number: "That’s 7. Make 6.", the extra cubes in red). Then a dashed line drops from the
/// shorter train's end and the longer one's extra cubes are ringed, "2 more"; tap the number that's more (or less): the
/// tap writes the record.
@MainActor
struct CompareNumbersLesson: PaperLesson {
    var liveKeys: Set<String> { ["m0", "m1", "row", "grab"] }
    static let rows = [0.0, 10.0]
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func made(_ s: PaperState, _ r: Int) -> Bool { at(s) > 0 || s.run.kept["made\(r)"] == 1 }
    func recordRow(_ n: Numbers) -> Double? { 18 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = CompareNumbers.Parts(s.numbers), st = at(s), V = P.value
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let wrong = st == 1 ? s.run.kept["wrong"].map { Int($0.rounded()) } : nil
        for r in 0..<2 {
            let y = Self.rows[r], v = V[r], bad = wrong == r
            KK.track(&pic, "trk\(r)", x: 0, y: y)
            // the number at the start of its track; once the tap writes the record, the record carries it
            if st < 2 {
                if bad { pic.sketch.box("nb\(r)", pic.R(-5, y, 5, 5), KK.red, width: Sketch.stroke) }
                pic.word("num\(r)\(bad)", "\(v)", at: -2.5, y + 2.5, bad ? KK.maths.colour(KK.red) : KK.maths)
            }
            if made(s, r) {
                // the train just made was following the finger: it stays put, drawn at once
                if st == 1 { pic.sketch.pace = 0 }
                KK.train(&pic, "tr\(r)", x: 0, y: y, v, nums: true)
                pic.sketch.pace = 1
            } else {
                let m = Int((s.h("m\(r)") ?? 0).rounded())
                KK.train(&live, "tr\(r)", x: 0, y: y, m, nums: true, red: s.on("over") && m > v ? v : nil)
                if s.grabbed, s.h("row") == Double(r) { live.reads("\(m)") }
                if s.on("spot") { pic.line("spot\(r)", [(Double(v) * 5, y - 1), (Double(v) * 5, y + 6)], .chapter, dashed: true) }
            }
        }
        if st >= 1 {
            // See: a dashed line drops from the shorter train's end; the longer one's extra cubes are ringed, "2 more"
            let x = Double(P.small) * 5, long = Self.rows[P.a > P.b ? 0 : 1]
            pic.line("drop", [(x, -1), (x, 16)], .chapter, dashed: true)
            pic.sketch.startAt = st == 1 ? PaperClock.now + 0.5 : nil
            KK.stadium(&pic, "extra", x: x + 0.5, y: long + 0.5, w: Double(P.extra) * 5 - 1, h: 4)
            pic.label("extraw", "\(P.extra) more", KK.lit, .right, edge: 50, along: long + 2.5)
            pic.sketch.startAt = nil
        }
        if st == 1 {
            if s.on("ring") { KK.hintBox(&pic, "hr", x: Double(P.small) * 5, y: Self.rows[P.a > P.b ? 0 : 1], w: Double(P.extra) * 5, h: 5) }
            if s.on("spot") { KK.hintBox(&pic, "spot", x: -5, y: Self.rows[P.want], w: 5, h: 5) }
        }
        if st == 2 {
            let toks: [M7.Tok] = P.less ? [.n(P.small, .chapter), .w("is less than"), .n(P.big, .chapter)] : [.n(P.big, .chapter), .w("is more than"), .n(P.small, .chapter)]
            M7.row(&rec, "rec", toks, x: 0, line: 1)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = CompareNumbers.Parts(s.numbers), V = P.value
        switch at(s) {
        case 0:
            let hand = s.hand
            let doneRows = (0..<2).map { made(s, $0) }
            return Hands(
                grab: { q in
                    guard let r = Self.rows.firstIndex(where: { q.y >= $0 - 1 && q.y <= $0 + 6 }), !doneRows[r], q.x >= -1, q.x <= 51 else { return nil }
                    var h = hand; h["grab"] = 1; h["row"] = Double(r); h["m\(r)"] = Double(KK.cubes(at: q.x, rounding: .up))
                    return h
                },
                drag: { q, h in var h = h; h["m\(Int(h["row"] ?? 0))"] = Double(KK.cubes(at: q.x)); return h },
                release: { h in
                    let r = Int(h["row"] ?? 0), m = Int((h["m\(r)"] ?? 0).rounded())
                    var after = h; after["grab"] = nil
                    if m == 0 { return HandMove(hand: after) }
                    if m == V[r] {
                        let both = doneRows[1 - r]
                        return HandMove(hand: after, missHand: nil, set: both ? [("w", 0)] : [], keep: ["made\(r)": 1], check: both)
                    }
                    return HandMove(hand: after, missHand: nil, set: [("w", CompareNumbers.Parts.code(row: r, m: m))], check: true)
                })
        case 1:
            return Hands(tap: { q in
                guard let r = Self.rows.firstIndex(where: { q.y >= $0 && q.y <= $0 + 5 }), q.x >= -5, q.x <= Double(V[r]) * 5 + 1 else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("p", Double(r))], keep: ["wrong": r == P.want ? -1 : Double(r)], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = CompareNumbers.Parts(s.numbers), V = P.value
        switch at(s) {
        case 0:
            return (0..<2).filter { !made(s, $0) }.map { r in
                .drag(from: CGPoint(x: 2.5, y: Self.rows[r] + 2.5), to: CGPoint(x: Double(V[r]) * 5 - 0.5, y: Self.rows[r] + 2.5))
            }
        case 1: return [.tap(.picture(CGPoint(x: -2.5, y: Self.rows[P.want] + 2.5)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = CompareNumbers.Parts(s.numbers)
        switch at(s) {
        case 0:
            let m = P.a == 10 ? 9 : P.a + 1
            return HandMove(hand: ["m0": Double(m)], missHand: nil, set: [("w", CompareNumbers.Parts.code(row: 0, m: m))], check: true)
        case 1: return HandMove(hand: nil, missHand: nil, set: [("p", Double(1 - P.want))], keep: ["wrong": Double(1 - P.want)], check: true)
        default: return nil
        }
    }
}
