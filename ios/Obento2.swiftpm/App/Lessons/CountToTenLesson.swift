import SwiftUI

/// Count to 10 on the paper, as in the preview (design/prototype/gradeK-ch1.html, lCount). How many? The dots on a field
/// of 10 × 4 blocks, an empty ten track a block under them. Tap each dot: it gets the next number (the order is kept, so
/// the picture shows what the child did); a dot tapped again is ringed red: "You counted that one." Once every dot has
/// its number the track rises to the field's top and the dots glide onto it in the order they were counted, the last
/// ringed; "Write how many." is answered on the number row. Make 7: drag along the track; cubes fill from the start line,
/// numbered; let go on 8: "That’s 8. Make 7.", the 8th cube in red.
@MainActor
struct CountToTenLesson: PaperLesson {
    var liveKeys: Set<String> { ["m", "grab"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// The ten track's top on the counting step: a block under the field's lowest dots.
    private func trackTop(_ P: CountToTen.Parts) -> Double { Double(P.rows) * 5 + 5 }
    private func dot(_ P: CountToTen.Parts, _ j: Int) -> CGPoint { CGPoint(x: Double(P.places[j].col) * 5 + 2.5, y: Double(P.places[j].row) * 5 + 2.5) }
    /// The dots in the order they were counted (kept, so later steps glide them there).
    private func order(_ s: PaperState) -> [Int] {
        var out: [Int] = []
        while let j = s.run.kept["o\(out.count)"] { out.append(Int(j.rounded())) }
        return out
    }
    /// The record's row and the number row's, in the picture's rows (the track risen to the top).
    static let record = 8.0, row = 13.0
    func recordRow(_ n: Numbers) -> Double? { CountToTen.Parts(n).kind == .make ? 8 : Self.record }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = CountToTen.Parts(s.numbers), st = at(s), n = P.n
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        if P.kind == .make {
            KK.track(&pic, "trk", x: 0, y: 0)
            if st == 3 {
                let m = Int((s.h("m") ?? 0).rounded())
                KK.train(&live, "mk", x: 0, y: 0, m, nums: true, red: s.on("over") && m > n ? n : nil)
                if s.grabbed { live.reads("\(m)") }
                if s.on("spot") { pic.line("spot", [(Double(n) * 5, -1), (Double(n) * 5, 6)], .chapter, dashed: true) }
            } else {
                // the train was following the finger: it stays put, drawn at once
                pic.sketch.pace = 0
                KK.train(&pic, "mk", x: 0, y: 0, n, nums: true)
                pic.sketch.pace = 1
                pic.circle("mkr", at: Double(n - 1) * 5 + 2.5, 2.5, radius: 2.05, .chapter)
                M7.row(&rec, "rec", [.n(n, .chapter)], x: 0, line: 1)
            }
            return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
        }
        let counted = order(s), T = trackTop(P)
        if st == 0 {
            KK.track(&pic, "trk", x: 0, y: T)
            for j in 0..<n {
                let p = dot(P, j), k = counted.firstIndex(of: j)
                KK.counter(&pic, "dot\(j)", p.x, p.y, num: k.map { $0 + 1 })
            }
            // a dot tapped again: ringed red until the next one is counted
            if let a = s.run.kept["again"], a >= 0 { let p = dot(P, Int(a.rounded())); pic.circle("again\(Int(a))", at: p.x, p.y, radius: 2.05, KK.red) }
            // a hint: the dots still to count, ringed; a second miss, the next one to tap
            if s.on("ring") { for j in 0..<n where !counted.contains(j) { let p = dot(P, j); KK.hint(&pic, "hr\(j)", p.x, p.y) } }
            if s.on("spot"), let j = next(P, counted) { let p = dot(P, j); pic.circle("spot", at: p.x, p.y, radius: 2.6, .chapter) }
        } else {
            // the track rises to the top, and the dots glide onto it one after another in the order they were counted
            KK.track(&pic, "trk", x: 0, y: 0)
            let all = counted.count == n ? counted : Array(0..<n)
            for (k, j) in all.enumerated() {
                let p = dot(P, j), x = Double(k) * 5 + 2.5, delay = 0.35 + 0.16 * Double(k)
                pic.sketch.delay = delay
                // the last one counted was still uncounted on the last drawing: it starts where it was
                if k == n - 1 { KK.from(&pic) { KK.counter(&$0, "dot\(j)", p.x, p.y, num: n) } }
                pic.sketch.startAt = k == n - 1 ? PaperClock.now + delay + 0.4 : nil
                KK.counter(&pic, "dot\(j)", x, 2.5, num: k + 1, ring: k == n - 1)
                pic.sketch.startAt = nil; pic.sketch.from = [:]
            }
            pic.sketch.delay = 0
            if st == 1 {
                let (v, wrong) = KK.typed(s, "n", want: n)
                KK.box(&rec, "box", x: 0, line: 1, value: v, wrong: wrong)
                KK.numberRow(&pic, "nr", y: Self.row, wrong: wrong ? v : nil, spot: s.on("spot") ? n : nil)
                if s.on("ring") { KK.hint(&pic, "hr", Double(n - 1) * 5 + 2.5, 2.5, radius: 2.8) }
            } else {
                M7.row(&rec, "rec", [.n(n, .chapter)], x: 0, line: 1)
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    /// The next dot to count: the first not counted, reading along the rows.
    private func next(_ P: CountToTen.Parts, _ counted: [Int]) -> Int? {
        (0..<P.n).filter { !counted.contains($0) }.min { (P.places[$0].row, P.places[$0].col) < (P.places[$1].row, P.places[$1].col) }
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = CountToTen.Parts(s.numbers), st = at(s), n = P.n
        switch st {
        case 0:
            let counted = order(s)
            return Hands(tap: { q in
                guard let j = (0..<n).first(where: { let p = dot(P, $0); return abs(q.x - p.x) <= 2.5 && abs(q.y - p.y) <= 2.5 }) else { return nil }
                if counted.contains(j) { return HandMove(hand: nil, missHand: nil, set: [("c", -1)], keep: ["again": Double(j)], check: true) }
                let k = counted.count
                // counted: its number; a red ring from before goes (-1: none)
                return HandMove(hand: nil, missHand: nil, set: k + 1 == n ? [("c", Double(n))] : [], keep: ["o\(k)": Double(j), "again": -1], check: k + 1 == n)
            })
        case 1:
            return Hands(tap: { q in
                guard let v = KK.tapped(q, y: Self.row) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("n", Double(v))], check: true)
            })
        case 3:
            func held(_ m: Int) -> Numbers { ["grab": 1, "m": Double(m)] }
            func letGo(_ m: Int) -> HandMove {
                m == 0 ? HandMove(hand: ["m": 0]) : HandMove(hand: ["m": Double(m)], missHand: nil, set: [("m", Double(m))], check: true)
            }
            let onTrack = { (q: CGPoint) in q.y >= -1 && q.y <= 6 && q.x >= -1 && q.x <= 51 }
            return Hands(
                tap: { q in onTrack(q) ? letGo(KK.cubes(at: q.x, rounding: .up)) : nil },
                grab: { q in onTrack(q) ? held(KK.cubes(at: q.x, rounding: .up)) : nil },
                drag: { q, _ in held(KK.cubes(at: q.x)) },
                release: { h in letGo(Int((h["m"] ?? 0).rounded())) })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = CountToTen.Parts(s.numbers), n = P.n
        switch at(s) {
        case 0:
            var counted = order(s), moves: [GhostMove] = []
            while let j = next(P, counted) { moves.append(.tap(.picture(dot(P, j)))); counted.append(j) }
            return moves
        case 1: return [.tap(.picture(KK.keySpot(n, y: Self.row)))]
        case 3: return [.drag(from: CGPoint(x: 2.5, y: 2.5), to: CGPoint(x: Double(n) * 5 - 0.5, y: 2.5))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = CountToTen.Parts(s.numbers), n = P.n
        switch at(s) {
        case 0:
            // a dot counted, then tapped again
            let j = next(P, order(s)) ?? 0
            return HandMove(hand: nil, missHand: nil, set: [("c", -1)], keep: ["o0": Double(j), "again": Double(j)], check: true)
        case 1: return HandMove(hand: nil, missHand: nil, set: [("n", Double(n == 10 ? 9 : n + 1))], check: true)
        case 3: let m = n == 10 ? 9 : n + 1; return HandMove(hand: ["m": Double(m)], missHand: nil, set: [("m", Double(m))], check: true)
        default: return nil
        }
    }
}
