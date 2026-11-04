import SwiftUI

/// Adding within 10 on the paper, as in the preview (design/prototype/gradeK-ch4.html, lAdd): the ten track two blocks
/// under a waiting striped train (b cubes, at the right, named b), a train of a cubes on the track from the start line,
/// named a. Slide the striped train on right after the first (the readout says "Right after 3", "2 to go"); let go
/// anywhere else and it slides home. The track then rises a block; count on: each tap on the next striped cube writes
/// a + 1, a + 2, … with a hop over it from the one before, the a on the first train's last cube, the last ringed. Write
/// how many in all on the number row.
///
/// Kept: "lx", "ly" where the train was let go, "c" how many counted on, "again" a cube tapped that's wrong.
@MainActor
struct AddLesson: PaperLesson {
    var liveKeys: Set<String> { ["x", "y"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// The track's top: row 10 while it waits for the train, then risen a block (room for the hops above it).
    static let low = 10.0, high = 5.0
    func recordRow(_ n: Numbers) -> Double? { 13 }
    static let keys = 18.0

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = AddK.Parts(s.numbers), st = at(s), a = P.a, b = P.b
        let slide = KSlide(a: a, b: b, track: Self.low)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let ty = st == 0 ? Self.low : Self.high
        KK.track(&pic, "trk", x: 0, y: ty)
        let counted = st == 0 ? 0 : st == 1 ? Int(s.run.kept["c"] ?? 0) : b
        let again = st == 1 ? KA.kept(s, "again") : nil
        for j in 0..<a { KA.cube(&pic, "a\(j)", x: Double(j) * 5, y: ty, num: st > 0 && j == a - 1 ? a : nil) }
        if st == 0 {
            pic.label("an", "\(a)", KK.maths, .right, edge: Double(a) * 5, along: ty + 2.5)
            if s.grabbed {
                // in the hand: it follows the finger square by square
                let p = slide.at(s)
                for k in 0..<b { KA.cube(&live, "b\(k)", x: p.x + Double(k) * 5, y: p.y, striped: true) }
                live.label("bn", "\(b)", KK.maths, .right, edge: p.x + Double(b) * 5, along: p.y + 2.5)
                if let r = slide.readout(p) { live.reads(r) }
            } else {
                // waiting at home, or sliding home from where it was let go
                let h = slide.home, from = slide.letGo(s)
                KM.seeded(&pic, was: from.map { f in { p in for k in 0..<b { KA.cube(&p, "b\(k)", x: f.x + Double(k) * 5, y: f.y, striped: true) } } }) { p in
                    for k in 0..<b { KA.cube(&p, "b\(k)", x: h.x + Double(k) * 5, y: h.y, striped: true) }
                }
                pic.label("bn", "\(b)", KK.maths, .right, edge: h.x + Double(b) * 5, along: h.y + 2.5)
            }
        } else {
            // on the track right after the first train: from where it was let go, rising with the track
            let from = slide.letGo(s)
            KM.seeded(&pic, was: st == 1 ? from.map { f in { p in for k in 0..<b { KA.cube(&p, "b\(k)", x: f.x + Double(k) * 5, y: f.y, striped: true) } } } : nil) { p in
                for k in 0..<b {
                    KA.cube(&p, "b\(k)", x: Double(a + k) * 5, y: ty, striped: true, num: k < counted ? a + k + 1 : nil,
                            ring: counted == b && k == b - 1)
                }
            }
            for k in 0..<counted { KA.hop(&pic, "hop\(k)", a + k, y: ty) }
            // a cube tapped that's wrong: outlined red over its own lines until the next right tap
            if let j = again { pic.sketch.box("again\(j)", pic.R(Double(j) * 5, ty, 5, 5), KK.red, width: Sketch.stroke) }
        }

        switch st {
        case 0:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: slide.home.x, y: slide.home.y, w: 5 * Double(b) + 3, h: 5) }
            if s.on("spot") { pic.sketch.box("spot", pic.R(Double(a) * 5, Self.low, Double(b) * 5, 5), .chapter, width: Sketch.stroke, dashed: true) }
        case 1:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: Double(a) * 5, y: ty, w: 5 * Double(b), h: 5) }
            if s.on("spot"), counted < b { KK.hint(&pic, "spot", Double(a + counted) * 5 + 2.5, ty + 2.5) }
        case 2:
            let (v, wrong) = KK.typed(s, "x", want: P.sum)
            KA.line(&rec, "rec", [.n(a), .op("+"), .n(b), .op("=")], value: v, wrong: wrong)
            KK.numberRow(&pic, "nr", y: Self.keys, wrong: wrong ? v : nil, spot: s.on("spot") ? P.sum : nil)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: Double(a) * 5, y: ty, w: 5 * Double(b), h: 5) }
        default:
            M7.row(&rec, "rec", [.n(a), .op("+"), .n(b), .op("="), .n(P.sum, .chapter)], x: 0, line: 1)
        }
        // the room it keeps while the train moves: the track, what waits above it and the names at its right end
        let room = st == 0 ? pic.R(0, 0, 53, Self.low + 5) : nil
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: room)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = AddK.Parts(s.numbers), a = P.a, b = P.b
        switch at(s) {
        case 0: return KSlide(a: a, b: b, track: Self.low).hands(s, box: "l")
        case 1:
            let counted = Int(s.run.kept["c"] ?? 0), ty = Self.high
            return Hands(tap: { q in
                guard q.y >= ty, q.y <= ty + 5, q.x >= 0, q.x < Double(P.sum) * 5 else { return nil }
                let j = Int(q.x / 5), k = j - a
                if k < 0 || k < counted { return HandMove(hand: nil, missHand: nil, set: [("n", k < 0 ? -1 : -2)], keep: ["again": Double(j)], check: true) }
                if k > counted { return HandMove(hand: nil, missHand: nil, set: [("n", -3)], keep: ["again": Double(j)], check: true) }
                let c = counted + 1
                return HandMove(hand: nil, missHand: nil, set: c == b ? [("n", Double(b))] : [], keep: ["c": Double(c), "again": -1], check: c == b)
            })
        case 2:
            return Hands(tap: { q in KK.tapped(q, y: Self.keys).map { HandMove(hand: nil, missHand: nil, set: [("x", Double($0))], check: true) } })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = AddK.Parts(s.numbers)
        switch at(s) {
        case 0: return [KSlide(a: P.a, b: P.b, track: Self.low).demo]
        case 1:
            let c = Int(s.run.kept["c"] ?? 0)
            return (P.a + c..<P.sum).map { .tap(.picture(CGPoint(x: Double($0) * 5 + 2.5, y: Self.high + 2.5))) }
        case 2: return [.tap(.picture(KK.keySpot(P.sum, y: Self.keys)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = AddK.Parts(s.numbers)
        switch at(s) {
        case 0: return KSlide(a: P.a, b: P.b, track: Self.low).wrong
        case 1: return HandMove(hand: nil, missHand: nil, set: [("n", -1)], keep: ["again": 0], check: true)
        case 2: return HandMove(hand: nil, missHand: nil, set: [("x", Double(P.sum < 10 ? P.sum + 1 : P.sum - 1))], check: true)
        default: return nil
        }
    }
}
