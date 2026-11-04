import SwiftUI

/// One more on the paper, as in the preview (design/prototype/gradeK-ch1.html, lOneMore): the number stairs, trains of
/// cubes one under another, left ends on one start line, each train's number at its right end. Drag the new train out
/// under them a cube at a time (numbered as it grows): let go one past the train above and its last cube lights,
/// "1 more"; write 1 more than n on the number row; then the last cube of each train lights in turn.
///
/// Departure from the preview, so every step shows at 75% or more: the stair shows its last three trains and the new one
/// (the top one's edge dashed, the stair goes on up) on every step, the See included, instead of the last five while the
/// hands work and the whole stair (up to ten trains, about 50% on this iPad) for the See.
@MainActor
struct OneMoreLesson: PaperLesson {
    var liveKeys: Set<String> { ["m", "grab"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// The first train drawn, and where train k's top is.
    private func first(_ n: Int) -> Int { max(1, n - 2) }
    private func rowY(_ n: Int, _ k: Int) -> Double { 5 * Double(k - first(n)) }
    func recordRow(_ x: Numbers) -> Double? { let n = OneMore.Parts(x).n; return rowY(n, n + 1) + 8 }
    private func numbersRow(_ n: Int) -> Double { rowY(n, n + 1) + 13 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let n = OneMore.Parts(s.numbers).n, st = at(s), f = first(n), NY = rowY(n, n + 1)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        // the stair: trains of 1 … n cubes, each named at its right end
        for k in f...n {
            let y = rowY(n, k)
            KK.train(&pic, "t\(k)", x: 0, y: y, k, dashTop: k == f && f > 1)
            pic.label("tn\(k)", "\(k)", KK.maths, .right, edge: Double(k) * 5, along: y + 2.5)
        }
        switch st {
        case 0:
            KK.track(&pic, "new", x: 0, y: NY, dashed: true, .ink3)
            let m = Int((s.h("m") ?? 0).rounded())
            KK.train(&live, "nt", x: 0, y: NY, m, nums: true, red: s.on("ring") && m > n + 1 ? n + 1 : nil)
            if s.grabbed { live.reads("\(m)") }
            // a hint: the train above's end; a second miss, the cube one past it
            if s.on("ring") { KK.hint(&pic, "hr", Double(n - 1) * 5 + 2.5, rowY(n, n) + 2.5) }
            if s.on("spot") { KK.hintBox(&pic, "spot", x: Double(n) * 5, y: NY, w: 5, h: 5) }
        case 1:
            // the new train was following the finger: it stays put, drawn at once (its last cube lighting)
            pic.sketch.pace = 0
            KK.train(&pic, "nt", x: 0, y: NY, n + 1, nums: true, lit: { $0 == n })
            pic.sketch.pace = 1
            pic.label("one", "1 more", KK.lit, .right, edge: Double(n + 1) * 5, along: NY + 2.5)
            let (v, wrong) = KK.typed(s, "x", want: n + 1)
            KK.line(&rec, "rec", [.n(1), .w("more than"), .n(n), .w("is")], value: v, wrong: wrong)
            KK.numberRow(&pic, "nr", y: numbersRow(n), wrong: wrong ? v : nil, spot: s.on("spot") ? n + 1 : nil)
            if s.on("ring") { KK.hint(&pic, "hr", Double(n) * 5 + 2.5, NY + 2.5) }
        default:
            // See: every train's last cube lights in turn, 1 more each time
            KK.train(&pic, "nt", x: 0, y: NY, n + 1)
            pic.label("tn\(n + 1)", "\(n + 1)", KK.maths, .right, edge: Double(n + 1) * 5, along: NY + 2.5)
            for k in f...(n + 1) {
                pic.sketch.startAt = PaperClock.now + 0.5 + 0.33 * Double(k - f)
                // a plate over the cube's own fill (two fills at one height flicker), just inside its lines
                pic.sketch.plate("lit\(k)", pic.R(Double(k - 1) * 5 + 0.1, rowY(n, k) + 0.1, 4.8, 4.8), .tint(0.3))
            }
            pic.sketch.startAt = nil
            M7.row(&rec, "rec", [.n(1), .w("more than"), .n(n), .w("is"), .n(n + 1, .chapter)], x: 0, line: 1)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let n = OneMore.Parts(s.numbers).n, NY = rowY(n, n + 1)
        switch at(s) {
        case 0:
            func held(_ m: Int) -> Numbers { ["grab": 1, "m": Double(m)] }
            func letGo(_ m: Int) -> HandMove {
                m == 0 ? HandMove(hand: ["m": 0]) : HandMove(hand: ["m": Double(m)], missHand: nil, set: [("m", Double(m))], check: true)
            }
            let onRow = { (q: CGPoint) in q.y >= NY - 1 && q.y <= NY + 6 && q.x >= -1 && q.x <= 51 }
            return Hands(
                tap: { q in onRow(q) ? letGo(KK.cubes(at: q.x, rounding: .up)) : nil },
                grab: { q in onRow(q) ? held(KK.cubes(at: q.x, rounding: .up)) : nil },
                drag: { q, _ in held(KK.cubes(at: q.x)) },
                release: { h in letGo(Int((h["m"] ?? 0).rounded())) })
        case 1:
            let y = numbersRow(n)
            return Hands(tap: { q in KK.tapped(q, y: y).map { HandMove(hand: nil, missHand: nil, set: [("x", Double($0))], check: true) } })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let n = OneMore.Parts(s.numbers).n, NY = rowY(n, n + 1)
        switch at(s) {
        case 0: return [.drag(from: CGPoint(x: 2.5, y: NY + 2.5), to: CGPoint(x: Double(n + 1) * 5 - 0.5, y: NY + 2.5))]
        case 1: return [.tap(.picture(KK.keySpot(n + 1, y: numbersRow(n))))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let n = OneMore.Parts(s.numbers).n
        switch at(s) {
        case 0: return HandMove(hand: ["m": Double(n)], missHand: nil, set: [("m", Double(n))], check: true)
        case 1: return HandMove(hand: nil, missHand: nil, set: [("x", Double(n))], check: true)
        default: return nil
        }
    }
}
