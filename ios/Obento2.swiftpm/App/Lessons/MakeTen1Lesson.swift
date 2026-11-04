import SwiftUI

/// Make a ten to add on the paper, as in the preview (design/prototype/grade1-ch1.html, dTen): two rows of ten places, a
/// square apart; a counters in the top row from the left, b striped in the bottom, each row's number at its right end.
/// Slide counters up (the one grabbed and every one left of it go together, the readout "8 and 2 make 10"): those that fit
/// snap into the top row's next empty places, the rest slide back. Full, the top row goes solid, says 10 and the bottom
/// row what's left ("8 and 2 make 10" stays written); then what's left slides to the start of the bottom row, under the
/// ten, and a + b = 10 + left is written on the number row. Sliding past full isn't a miss (the row fills, the rest go
/// back); its line, "The top row is full. That's 10.", is said before the write step's.
///
/// Hand: "grab", "g" the counter grabbed, "gx", "gy", "dx", "dy" how far it's carried. Kept: "m" how many went up, "lg",
/// "lx", "ly" the last carry let go (it glides from there), "over" a carry past full.
@MainActor
struct MakeTen1Lesson: PaperLesson {
    var liveKeys: Set<String> { ["dx", "dy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let top = 0.0, bottom = 4.0, keys = 16.0
    func recordRow(_ n: Numbers) -> Double? { 12 }

    func say(_ s: PaperState) -> String? {
        at(s) == 1 && s.run.kept["over"] == 1 ? MakeTen1.Parts.full + " " + G1.tap : nil
    }

    private func moved(_ s: PaperState) -> Int { at(s) == 0 ? Int(s.run.kept["m"] ?? 0) : MakeTen1.Parts(s.numbers).need }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = MakeTen1.Parts(s.numbers), st = at(s), m = moved(s), writing = st > 0
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let full = P.a + m == 10
        A1.places(&pic, "pt", x: 0, y: Self.top, full: full)
        A1.places(&pic, "pb", x: 0, y: Self.bottom)
        for j in 0..<P.a { A1.counter(&pic, "A\(j)", x: A1.x(j), y: Self.top, .solid) }
        // carried now (in the hand) or let go last (it glides from there)
        let held = st == 0 && s.grabbed ? Int(s.h("g") ?? 0) : nil
        let carry = held.map { Array(m...$0) } ?? []
        if held != nil {
            let dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0
            for j in carry { A1.counter(&live, "B\(j)", x: A1.x(j) + dx, y: Self.bottom + dy, .striped) }
            let have = P.a + m, c = carry.count
            A1.note(&live, "ro", "\(have) and \(c) make \(have + c)", x: 0, y: Self.bottom + 4.5)
            live.reads("\(have) and \(c) make \(have + c)")
        }
        let was: ((inout GridPen) -> Void)? = st == 0 ? s.run.kept["lg"].map { g in
            let lx = s.run.kept["lx"] ?? 0, ly = s.run.kept["ly"] ?? 0
            return { p in for j in 0...Int(g) { A1.counter(&p, "B\(j)", x: A1.x(j) + lx, y: Self.bottom + ly, .striped) } }
        } : nil
        KM.seeded(&pic, was: was) { p in
            for j in 0..<P.b where !carry.contains(j) {
                if j < m { A1.counter(&p, "B\(j)", x: A1.x(P.a + j), y: Self.top, .striped); continue }
                // the see: what's left slides to the start of the bottom row, one after another
                if writing { p.sketch.delay = 0.5 + 0.06 * Double(j - m) }
                A1.counter(&p, "B\(j)", x: A1.x(writing ? j - m : j), y: Self.bottom, .striped)
                p.sketch.delay = 0
            }
        }
        if !writing {
            if full {
                pic.label("lt10", "10", KK.maths.colour(.chapter), .right, edge: 30, along: Self.top + 1.5)
                pic.label("lb\(P.left)", "\(P.left)", KK.maths, .right, edge: 30, along: Self.bottom + 1.5)
            } else {
                pic.label("lta", "\(P.a + m)", KK.maths, .right, edge: 30, along: Self.top + 1.5)
                pic.label("lbb", "\(P.b - m)", KK.maths, .right, edge: 30, along: Self.bottom + 1.5)
            }
        }
        if held == nil && (full || writing) { A1.note(&pic, "rof", "\(P.a) and \(P.need) make 10", x: 0, y: Self.bottom + 4.5) }

        switch st {
        case 0:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: A1.x(P.a + m), y: Self.top, w: A1.x(10 - P.a - m), h: 3) }
            if s.on("spot"), m < P.need { pic.sketch.box("spot", pic.R(A1.x(m), Self.bottom, A1.x(P.need - m), 3), .chapter, width: Sketch.stroke, dashed: true) }
        case 1:
            let (v, wrong) = KK.typed(s, "x", want: P.sum)
            A1.record(&rec, "rec", [.n(P.a), .op("+"), .n(P.b), .op("="), .n(10), .op("+"), .n(P.left), .op("="), .box(v, wrong: wrong)])
            A1.numberRow(&pic, "nr", y: Self.keys, wrong: wrong ? v : nil, spot: s.on("spot") ? P.sum : nil)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: Self.top, w: 30, h: 7) }
        default:
            A1.record(&rec, "rec", [.n(P.a), .op("+"), .n(P.b), .op("="), .n(10), .op("+"), .n(P.left), .op("="), .n(P.sum, .chapter)])
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = MakeTen1.Parts(s.numbers)
        switch at(s) {
        case 0:
            let m = moved(s)
            return Hands(
                grab: { q in
                    guard q.y >= Self.bottom - 0.5, q.y <= Self.bottom + 3.5, q.x >= A1.x(m) - 0.25 else { return nil }
                    let j = Int(q.x / 3)
                    guard j >= m, j < P.b else { return nil }
                    return ["grab": 1, "g": Double(j), "gx": q.x, "gy": q.y, "dx": 0, "dy": 0]
                },
                drag: { q, held in
                    var held = held
                    held["dx"] = (q.x - (held["gx"] ?? q.x)).rounded()
                    held["dy"] = max(-6, min(6, (q.y - (held["gy"] ?? q.y)).rounded()))
                    return held
                },
                release: { held in
                    let g = Int(held["g"] ?? 0), dx = held["dx"] ?? 0, dy = held["dy"] ?? 0, c = g - m + 1
                    var keep: Numbers = ["lg": Double(g), "lx": dx, "ly": dy]
                    // not up at the top row: back it goes
                    guard Self.bottom + dy <= Self.top + 2 else { return HandMove(hand: [:], keep: keep) }
                    let go = min(c, P.need - m)
                    keep["m"] = Double(m + go)
                    if c > go { keep["over"] = 1 }
                    guard m + go == P.need else { return HandMove(hand: [:], keep: keep) }
                    return HandMove(hand: [:], missHand: [:], set: [("f", Double(P.need))], keep: keep, check: true)
                })
        case 1: return A1.rowHands("x", y: Self.keys)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = MakeTen1.Parts(s.numbers)
        switch at(s) {
        case 0:
            let x = A1.x(P.need - 1) + 1.5
            return [.drag(from: CGPoint(x: x, y: Self.bottom + 1.5), to: CGPoint(x: x, y: Self.top + 1.5))]
        case 1: return [.tap(.picture(A1.keySpot(P.sum, y: Self.keys)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        at(s) == 1 ? HandMove(hand: nil, missHand: nil, set: [("x", Double(MakeTen1.Parts(s.numbers).left))], check: true) : nil
    }
}
