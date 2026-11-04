import SwiftUI

/// Taking away within 10 on the paper, as in the preview (design/prototype/gradeK-ch4.html, lSub): the ten track with a
/// train of a cubes, named a; two blocks under it, a dashed strip. Each tap on the train takes its last cube: it drops
/// into the strip under its own block and is crossed out (a tap on one in the strip puts it back). Then count what's
/// left (each tap numbers a cube still on the track, the last ringed; a crossed-out one: "That one is taken away."),
/// and write it on the number row. None left: "None left." is said with the write.
///
/// Kept: "n" how many taken, "t<k>" when the k-th went, "o<i>" the cubes counted in order, "again" a cube tapped twice.
@MainActor
struct TakeAwayLesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let strip = 10.0, keys = 23.0
    func recordRow(_ n: Numbers) -> Double? { 18 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = TakeAwayK.Parts(s.numbers), st = at(s), a = P.a, b = P.b, now = PaperClock.now
        var pic = GridPen(), rec = GridPen()
        let taken = st == 0 ? Int(s.run.kept["n"] ?? 0) : b, on = a - taken
        let counted = st == 0 ? [] : st == 1 ? KA.list(s, "o") : Array(0..<P.left)
        let again = st == 1 ? KA.kept(s, "again") : nil
        KK.track(&pic, "trk", x: 0, y: 0)
        for j in 0..<on {
            let k = counted.firstIndex(of: j)
            KA.cube(&pic, "c\(j)", x: Double(j) * 5, y: 0, num: k.map { $0 + 1 }, ring: P.left > 0 && counted.count == P.left && k == P.left - 1, red: again == j)
        }
        if st <= 1 { pic.label("an", "\(a)", KK.maths, .right, edge: Double(a) * 5, along: 2.5) }
        // the strip: dashed blocks while taking; each taken cube dropped from its own block, crossed out once it lands
        if st == 0 { KA.strip(&pic, "st", y: Self.strip, on) }
        for k in 0..<taken {
            let j = a - 1 - k, x = Double(j) * 5, went = s.run.kept["t\(k)"] ?? 0
            KM.seeded(&pic, was: { p in KA.cube(&p, "t\(k)", x: x, y: 0) }) { p in KA.cube(&p, "t\(k)", x: x, y: Self.strip) }
            pic.sketch.startAt = max(now, went + 0.45)
            pic.line("t\(k)x", [(x + 0.8, Self.strip + 4.2), (x + 4.2, Self.strip + 0.8)])
            pic.sketch.startAt = nil
        }

        switch st {
        case 0:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: 0, w: 5 * Double(on), h: 5) }
            if s.on("spot"), on > 0 { KK.hint(&pic, "spot", Double(on - 1) * 5 + 2.5, 2.5) }
        case 1:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: 0, w: 5 * Double(on), h: 5) }
            if s.on("spot"), let j = (0..<on).first(where: { !counted.contains($0) }) { KK.hint(&pic, "spot", Double(j) * 5 + 2.5, 2.5) }
        case 2:
            let (v, wrong) = KK.typed(s, "x", want: P.left)
            KA.line(&rec, "rec", [.n(a), .op("−"), .n(b), .op("=")], value: v, wrong: wrong)
            KK.numberRow(&pic, "nr", y: Self.keys, wrong: wrong ? v : nil, spot: s.on("spot") ? P.left : nil)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: 0, w: max(5, 5 * Double(on)), h: 5) }
        default:
            M7.row(&rec, "rec", [.n(a), .op("−"), .n(b), .op("="), .n(P.left, .chapter)], x: 0, line: 1)
        }
        return PaperDrawing(picture: pic.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, 53, Self.strip + 5))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = TakeAwayK.Parts(s.numbers), a = P.a, b = P.b
        switch at(s) {
        case 0:
            let taken = Int(s.run.kept["n"] ?? 0), on = a - taken
            return Hands(tap: { q in
                // a tap on the train takes its last cube
                if q.y >= 0, q.y <= 5, q.x >= 0, q.x <= Double(on) * 5, on > 0 {
                    let n = taken + 1
                    return HandMove(hand: nil, missHand: nil, set: n >= b ? [("t", Double(n))] : [], keep: ["n": Double(n), "t\(taken)": PaperClock.now], check: n >= b)
                }
                // a tap on one in the strip puts the last taken back
                if q.y >= Self.strip, q.y <= Self.strip + 5, q.x >= Double(on) * 5, q.x <= Double(a) * 5, taken > 0 {
                    return HandMove(hand: nil, missHand: nil, keep: ["n": Double(taken - 1), "t\(taken - 1)": -1])
                }
                return nil
            })
        case 1:
            let counted = KA.list(s, "o"), on = P.left
            return Hands(tap: { q in
                if q.y >= 0, q.y <= 5, q.x >= 0, q.x < Double(on) * 5 {
                    let j = Int(q.x / 5)
                    if counted.contains(j) { return HandMove(hand: nil, missHand: nil, set: [("n", -1)], keep: ["again": Double(j)], check: true) }
                    let done = counted.count + 1 == on
                    return HandMove(hand: nil, missHand: nil, set: done ? [("n", Double(on))] : [], keep: ["o\(counted.count)": Double(j), "again": -1], check: done)
                }
                if q.y >= Self.strip, q.y <= Self.strip + 5, q.x >= Double(on) * 5, q.x <= Double(a) * 5 {
                    return HandMove(hand: nil, missHand: nil, set: [("n", -2)], check: true)
                }
                return nil
            })
        case 2:
            return Hands(tap: { q in KK.tapped(q, y: Self.keys).map { HandMove(hand: nil, missHand: nil, set: [("x", Double($0))], check: true) } })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = TakeAwayK.Parts(s.numbers)
        switch at(s) {
        case 0:
            let taken = Int(s.run.kept["n"] ?? 0)
            return (taken..<P.b).map { k in .tap(.picture(CGPoint(x: Double(P.a - 1 - k) * 5 + 2.5, y: 2.5))) }
        case 1:
            let counted = KA.list(s, "o")
            return (0..<P.left).filter { !counted.contains($0) }.map { .tap(.picture(CGPoint(x: Double($0) * 5 + 2.5, y: 2.5))) }
        case 2: return [.tap(.picture(KK.keySpot(P.left, y: Self.keys)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = TakeAwayK.Parts(s.numbers)
        switch at(s) {
        case 1: return HandMove(hand: nil, missHand: nil, set: [("n", -2)], check: true)
        case 2: return HandMove(hand: nil, missHand: nil, set: [("x", Double(P.b))], check: true)
        default: return nil
        }
    }
}
