import SwiftUI

/// Doubles and near doubles on the paper, as in the preview (design/prototype/grade1-ch1.html, dDoubles): a counters
/// (solid) on row 0 from the start line, b striped on row 5 two blocks to the right, each named at its right end. Slide the
/// bottom row to the start line (it follows the finger square by square and snaps there; let go anywhere else it slides
/// back): a line joins each pair, an extra one stands alone, ringed, "6 pairs and 1 more". Write the double, or a near
/// double's 6 + 6 + 1 = [12] + 1 = [13], on the number row.
///
/// Hand: "grab", "gx", "x0", "x" where the row is. Kept: "lx" where it was let go.
@MainActor
struct Doubles1Lesson: PaperLesson {
    var liveKeys: Set<String> { ["x"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let top = 0.0, bottom = 5.0, home = 10.0, keys = 18.0
    func recordRow(_ n: Numbers) -> Double? { 14 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Doubles1.Parts(s.numbers), st = at(s), a = P.a, b = P.b, writing = st > 0
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        pic.line("start", [(0, -1), (0, Self.bottom + 4)])
        for j in 0..<a { A1.counter(&pic, "A\(j)", x: A1.x(j), y: Self.top, .solid) }
        if !writing { pic.label("la", "\(a)", KK.maths, .right, edge: A1.x(a), along: Self.top + 1.5) }
        if st == 0 && s.grabbed {
            let x = s.h("x") ?? Self.home
            for j in 0..<b { A1.counter(&live, "B\(j)", x: x + A1.x(j), y: Self.bottom, .striped) }
            live.label("lb", "\(b)", KK.maths, .right, edge: x + A1.x(b), along: Self.bottom + 1.5)
            if x == 0 { live.reads(P.readout) }
        } else {
            let x = st == 0 ? Self.home : 0
            let was: ((inout GridPen) -> Void)? = s.run.kept["lx"].map { f in { p in for j in 0..<b { A1.counter(&p, "B\(j)", x: f + A1.x(j), y: Self.bottom, .striped) } } }
            KM.seeded(&pic, was: was) { p in for j in 0..<b { A1.counter(&p, "B\(j)", x: x + A1.x(j), y: Self.bottom, .striped) } }
            if !writing { pic.label("lb", "\(b)", KK.maths, .right, edge: x + A1.x(b), along: Self.bottom + 1.5) }
        }
        if writing {
            // lined up: a line joins each pair, the extra one ringed
            pic.sketch.delay = 0.3
            pic.sketch.segments("pairs", (0..<P.d).map { j in (pic.P(A1.x(j) + 1.5, Self.top + 3), pic.P(A1.x(j) + 1.5, Self.bottom)) }, .chapter, width: Sketch.stroke)
            if !P.dbl { pic.circle("extra", at: A1.x(P.d) + 1.5, (a > b ? Self.top : Self.bottom) + 1.5, radius: 1.65, .chapter) }
            A1.note(&pic, "ro", P.readout, x: 0, y: Self.bottom + 5.5)
            pic.sketch.delay = 0
        }

        let dv = KK.typed(s, "d", want: 2 * P.d), xv = KK.typed(s, "x", want: P.dbl ? 2 * P.d : P.sum)
        switch st {
        case 0:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: Self.home, y: Self.bottom, w: A1.x(b), h: 3) }
            if s.on("spot") { pic.sketch.box("spot", pic.R(0, Self.bottom, A1.x(b), 3), .chapter, width: Sketch.stroke, dashed: true) }
        case 1, 2:
            let want = st == 1 ? 2 * P.d : P.sum, (v, wrong) = st == 1 && !P.dbl ? dv : xv
            if P.dbl {
                A1.record(&rec, "rec", [.n(a), .op("+"), .n(b), .op("="), .box(v, wrong: wrong)])
            } else {
                let first: A1.Tok = st == 1 ? .box(v, wrong: wrong) : .box(2 * P.d, wrong: false)
                A1.record(&rec, "rec", [.n(a), .op("+"), .n(b), .op("="), .n(P.d), .op("+"), .n(P.d), .op("+"), .n(1), .op("="), first, .op("+"), .n(1), .op("="),
                                        .box(st == 2 ? v : nil, wrong: st == 2 && wrong)])
            }
            A1.numberRow(&pic, "nr", y: Self.keys, wrong: wrong ? v : nil, spot: s.on("spot") ? want : nil)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: Self.top, w: A1.x(P.d), h: Self.bottom + 3) }
        default:
            if P.dbl { A1.record(&rec, "rec", [.n(a), .op("+"), .n(b), .op("="), .n(P.sum, .chapter)]) }
            else {
                A1.record(&rec, "rec", [.n(a), .op("+"), .n(b), .op("="), .n(P.d), .op("+"), .n(P.d), .op("+"), .n(1), .op("="), .n(2 * P.d), .op("+"), .n(1), .op("="), .n(P.sum, .chapter)])
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Doubles1.Parts(s.numbers)
        switch at(s) {
        case 0:
            return Hands(
                grab: { q in
                    guard q.y >= Self.bottom - 0.5, q.y <= Self.bottom + 3.5, q.x >= Self.home - 0.5, q.x <= Self.home + A1.x(P.b) + 0.5 else { return nil }
                    return ["grab": 1, "gx": q.x, "x0": Self.home, "x": Self.home]
                },
                drag: { q, held in
                    var held = held
                    var x = max(0, min(Self.home + 5, ((held["x0"] ?? 0) + q.x - (held["gx"] ?? q.x)).rounded()))
                    if x <= 2 { x = 0 }
                    held["x"] = x
                    return held
                },
                release: { held in
                    let x = held["x"] ?? Self.home
                    guard x == 0 else { return HandMove(hand: [:], keep: ["lx": x]) }
                    return HandMove(hand: [:], missHand: [:], set: [("l", 0)], keep: ["lx": 0], check: true)
                })
        case 1: return A1.rowHands(P.dbl ? "x" : "d", y: Self.keys)
        case 2: return A1.rowHands("x", y: Self.keys)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Doubles1.Parts(s.numbers)
        switch at(s) {
        case 0: return [.drag(from: CGPoint(x: Self.home + 1.5, y: Self.bottom + 1.5), to: CGPoint(x: 1.5, y: Self.bottom + 1.5))]
        case 1: return [.tap(.picture(A1.keySpot(2 * P.d, y: Self.keys)))]
        case 2: return [.tap(.picture(A1.keySpot(P.sum, y: Self.keys)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Doubles1.Parts(s.numbers)
        switch at(s) {
        case 1: return HandMove(hand: nil, missHand: nil, set: [(P.dbl ? "x" : "d", Double(P.d))], check: true)
        case 2: return HandMove(hand: nil, missHand: nil, set: [("x", Double(2 * P.d))], check: true)
        default: return nil
        }
    }
}
