import SwiftUI

/// Count to 20 on the paper, as in the preview (design/prototype/gradeK-ch5.html, lCount20). One block is one dot: the
/// twenty track (two ten tracks touching, 50 × 10 squares), the top row full. Count the top row: each dot tapped gets its
/// number; then "Keep counting.": the top row's numbers go, all but the 10 (written at the row's right end too), and the
/// bottom row is counted on from 11. Write how many on the number row grown to 20 (1–10 under the track's blocks, 11–20
/// under them). The ring (from index 6, every third problem): the dots spread round a 6 × 6 square of blocks, counted all
/// the way round; the record and the keys (1–20, five to a row) beside it.
///
/// Kept: "o<k>" the dots counted in order, "again" a dot tapped that's wrong.
@MainActor
struct CountTwentyLesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// The rows kind: the record's row and the number rows'; the ring: the keys beside it.
    static let record = 13.0, keys = 18.0, ringX = 35.0, ringKeys = 5.0
    func recordRow(_ n: Numbers) -> Double? { Count20K.Parts(n).ring ? 0 : Self.record }
    func blocksLeft(_ n: Numbers) -> Double? { Count20K.Parts(n).ring ? Self.ringX : nil }

    private func dot(_ P: Count20K.Parts, _ j: Int) -> CGPoint { let p = P.place(j); return CGPoint(x: Double(p.col) * 5 + 2.5, y: Double(p.row) * 5 + 2.5) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Count20K.Parts(s.numbers), st = at(s), n = P.n
        var pic = GridPen(), rec = GridPen()
        let list = KA.list(s, "o"), after = st == 2 || st == 3
        // the order they were counted in (on later steps every dot is counted: in order, if the list was made elsewhere)
        let counted = after ? (list.count == n ? list : Array(0..<n)) : list, order = counted
        if !P.ring {
            KK.track(&pic, "trk", x: 0, y: 0)
            KK.track(&pic, "trk2", x: 0, y: 5)
        }
        // past the top row, its numbers go, all but the 10
        let last = after ? order[n - 1] : nil
        for j in 0..<n {
            let p = dot(P, j)
            if let k = counted.firstIndex(of: j) {
                if !P.ring && st != 0 && k < 9 { KT.counted(&pic, "dot\(j)", p.x, p.y) }
                else { KK.counter(&pic, "dot\(j)", p.x, p.y, num: k + 1, ring: j == last) }
            } else {
                KK.counter(&pic, "dot\(j)", p.x, p.y, num: nil)
            }
        }
        if !P.ring && st != 0 { pic.label("ten", "10", KK.maths, .right, edge: 50, along: 2.5) }
        if st <= 1 || st == 4, let a = KA.kept(s, "again") { KT.again(&pic, "again\(a)", dot(P, a)) }

        let (v, wrong) = KK.typed(s, "x", want: n)
        switch st {
        case 0, 1, 4:
            // a hint: the dots still to count in this row (or round the ring), ringed; a second miss, the next one
            let todo = (st == 0 ? Array(0..<10) : st == 1 ? Array(10..<n) : Array(0..<n)).filter { !counted.contains($0) }
            if s.on("ring") && !s.on("spot") { for j in todo { let p = dot(P, j); KK.hint(&pic, "hr\(j)", p.x, p.y) } }
            if s.on("spot"), let j = todo.first { let p = dot(P, j); pic.circle("spot", at: p.x, p.y, radius: 2.6, .chapter) }
        case 2:
            if P.ring {
                KK.box(&rec, "box", x: Self.ringX, line: 1, value: v, wrong: wrong)
                for r in 0..<4 {
                    KT.keys(&pic, "kg\(r)", Array((5 * r + 1)...(5 * r + 5)), x: Self.ringX, y: Self.ringKeys + 5 * Double(r), w: 5, step: 5,
                            wrong: wrong ? v : nil, spot: s.on("spot") ? n : nil)
                }
            } else {
                KK.box(&rec, "box", x: 0, line: 1, value: v, wrong: wrong)
                KT.twenty(&pic, "nr", y: Self.keys, wrong: wrong ? v : nil, spot: s.on("spot") ? n : nil)
            }
            if s.on("ring") && !s.on("spot") { let p = dot(P, order[n - 1]); KK.hint(&pic, "hr", p.x, p.y, radius: 2.8) }
        default:
            M7.row(&rec, "rec", [.n(n, .chapter)], x: P.ring ? Self.ringX : 0, line: 1)
        }
        return PaperDrawing(picture: pic.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    /// The ring's keys: 1–20 in 4 rows of five beside it (the second half of each ten under the first).
    private func ringKeys() -> [(Int, CGPoint)] {
        (1...20).map { v in (v, CGPoint(x: Self.ringX + 5 * Double((v - 1) % 5) + 2.5, y: Self.ringKeys + 5 * Double((v - 1) / 5) + 2)) }
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Count20K.Parts(s.numbers), st = at(s), n = P.n
        let spots = (0..<n).map { dot(P, $0) }
        switch st {
        case 0, 1, 4:
            let counted = KA.list(s, "o"), box = st == 1 ? "d" : "c", goal = st == 0 ? 10 : n
            return Hands(tap: { q in
                guard let j = KT.hit(q, spots) else { return nil }
                func wrong(_ code: Int) -> HandMove { HandMove(hand: nil, missHand: nil, set: [(box, Double(code))], keep: ["again": Double(j)], check: true) }
                if st == 0 && j >= 10 { return wrong(-2) }
                if counted.contains(j) { return wrong(st == 1 && j < 10 ? -3 : -1) }
                let done = counted.count + 1 == goal
                return HandMove(hand: nil, missHand: nil, set: done ? [(box, Double(goal))] : [], keep: ["o\(counted.count)": Double(j), "again": -1], check: done)
            })
        case 2:
            return Hands(tap: { q in
                let v = P.ring ? ringKeys().first { abs(q.x - $0.1.x) <= 2.5 && q.y >= $0.1.y - 2 && q.y <= $0.1.y + 2 }?.0 : KT.tappedTwenty(q, y: Self.keys)
                return v.map { HandMove(hand: nil, missHand: nil, set: [("x", Double($0))], check: true) }
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Count20K.Parts(s.numbers), st = at(s), n = P.n
        switch st {
        case 0, 1, 4:
            let counted = KA.list(s, "o"), all = st == 0 ? Array(0..<10) : st == 1 ? Array(10..<n) : Array(0..<n)
            return all.filter { !counted.contains($0) }.map { .tap(.picture(dot(P, $0))) }
        case 2: return [.tap(.picture(P.ring ? ringKeys()[n - 1].1 : KT.twentySpot(n, y: Self.keys)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Count20K.Parts(s.numbers), st = at(s), n = P.n
        switch st {
        case 0: return HandMove(hand: nil, missHand: nil, set: [("c", -2)], keep: ["again": Double(n - 1)], check: true)
        case 1: return HandMove(hand: nil, missHand: nil, set: [("d", -3)], keep: ["again": 3], check: true)
        case 4: return HandMove(hand: nil, missHand: nil, set: [("c", -1)], keep: ["o0": 0, "again": 0], check: true)
        case 2: return HandMove(hand: nil, missHand: nil, set: [("x", Double(P.ring ? n - 1 : P.rest))], check: true)
        default: return nil
        }
    }
}
