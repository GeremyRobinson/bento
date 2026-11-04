import SwiftUI

/// Adding with regrouping on the paper, as in the preview (design/prototype/grade2-ch1.html, dRegroup): a at the left as
/// ten rows and a ones row (tinted), b at the right the same (striped), rows 3 squares apart; the column form beside them.
/// Slide b's ones onto a's: they go in after a's ones, counting on, a full row and the rest under it ("7 + 8 = 15"). Tap the
/// full row: its counters close into one ten under a's tens (10 at its end), the small 1 over the tens in the column. Slide
/// b's tens under them ("4 + 3 + 1 = 8 tens"); write the sum in the column. The story kind's lines take the top rows, its
/// stacks named May and June, and + Add / − Take away is picked first.
///
/// Hand: "grab", "gx", "gy", "dx", "dy", "w" what's carried (1 b's ones, 2 b's tens, 0 a dead grab: the tens before the ones).
/// Kept: "lx", "ly", "lw" where the last carry was let go.
@MainActor
struct Regroup2Lesson: PaperLesson {
    static let RX = 25.0
    var liveKeys: Set<String> { ["dx", "dy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static func top(_ P: Regroup2.Parts) -> Double { P.story ? 2 * Double(A2.storyRows(P.lines, width: 44).count) + 3 : 0 }
    /// Rows 3 squares apart, or touching (2) when a tall stack under a story would show under 75% (1st grade's Tens and ones).
    static func row(_ P: Regroup2.Parts) -> Double { top(P) + 3 * Double(P.T + 1) <= 34 ? 3 : 2 }
    private func Y(_ P: Regroup2.Parts, _ r: Int) -> Double { Self.top(P) + Self.row(P) * Double(r) }

    func told(_ s: PaperState) -> String? { let P = Regroup2.Parts(s.numbers); return P.story ? P.lines.joined(separator: " ") : nil }
    func recordBeside(_ n: Numbers) -> Double? { Self.top(Regroup2.Parts(n)) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Regroup2.Parts(s.numbers), st = at(s), RX = Self.RX
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        if P.story {
            A2.tell(&pic, P.lines, width: 44)
            pic.word("nmA", "May", at: 10, Self.top(P) - 1.2, A2.small)
            pic.word("nmB", "June", at: RX + 10, Self.top(P) - 1.2, A2.small)
        }
        let held = s.grabbed && (s.h("w") ?? 0) != 0, w = Int(s.h("w") ?? 0), dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0
        let onesIn = st >= 1, closed = st >= 2, tensIn = st >= 3
        // where the last carry was let go: what it carried starts from there
        let k = s.run.kept
        if !held, let lw = k["lw"], (lw == 1 && st == 1) || (lw == 2 && st == 3) {
            let lx = k["lx"] ?? 0, ly = k["ly"] ?? 0
            pic.sketch.from = A2.kinds { p in
                if lw == 1 { for j in 0..<P.bo { A2.counter(&p, "B.o\(j)", x: RX + 2 * Double(j) + lx, y: Y(P, P.bt) + ly, .striped) } }
                else { for r in 0..<P.bt { A2.ten(&p, "B.t\(r)", x: RX + lx, y: Y(P, r) + ly, .striped) } }
            }
        }
        // the left: a's tens, the new ten, b's tens; then the ones in rows of ten
        var tens = (0..<P.at).map { ("A.t\($0)", A2.Style.solid) }
        if closed { tens.append(("N.t0", .solid)) }
        if tensIn { tens += (0..<P.bt).map { ("B.t\($0)", A2.Style.striped) } }
        for (r, t) in tens.enumerated() { A2.ten(&pic, t.0, x: 0, y: Y(P, r), t.1) }
        if st == 2 && !held { pic.word("n10", "10", at: 20.5, Y(P, P.at) + 1, A2.carry, anchor: UnitPoint(x: 0, y: 0.5)) }
        var ones = (0..<P.ao).map { ("A.o\($0)", A2.Style.solid, nil as Int?) }
        if onesIn { ones += (0..<P.bo).map { ("B.o\($0)", A2.Style.striped, st == 1 ? P.ao + 1 + $0 : nil) } }
        if closed { ones = Array(ones.dropFirst(10)) }
        for (j, o) in ones.enumerated() { A2.counter(&pic, o.0, x: 2 * Double(j % 10), y: Y(P, tens.count + j / 10), o.1, n: o.2) }
        if st == 1 { pic.sketch.box("fullrow", pic.R(0, Y(P, P.at), 20, 2), .chapter, width: Sketch.stroke) }
        pic.sketch.from = [:]
        // the right: b's tens and ones at home, or carried
        if !tensIn { for r in 0..<P.bt { if held && w == 2 { A2.ten(&live, "B.t\(r)", x: RX + dx, y: Y(P, r) + dy, .striped) } else { A2.ten(&pic, "B.t\(r)", x: RX, y: Y(P, r), .striped) } } }
        if !onesIn { for j in 0..<P.bo { if held && w == 1 { A2.counter(&live, "B.o\(j)", x: RX + 2 * Double(j) + dx, y: Y(P, P.bt) + dy, .striped) } else { A2.counter(&pic, "B.o\(j)", x: RX + 2 * Double(j), y: Y(P, P.bt), .striped) } } }
        if held { live.reads(readout(P, w, over(P, w, dx, dy))) }

        // hints: a first miss rings the general area, a second the exact place
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        switch st {
        case 0:
            if ring { KK.hintBox(&pic, "hr", x: 0, y: Y(P, P.at), w: 20, h: 2) }
            if spot { pic.sketch.box("spot", pic.R(2 * Double(P.ao), Y(P, P.at), 2 * Double(min(P.bo, 10 - P.ao)), 2), .chapter, width: Sketch.stroke, dashed: true) }
        case 1:
            if ring { KK.hintBox(&pic, "hr", x: 0, y: Y(P, P.at), w: 20, h: P.left > 0 ? 5 : 2) }
            if spot { KK.hintBox(&pic, "spot", x: -0.5, y: Y(P, P.at) - 0.5, w: 21, h: 3) }
        case 2:
            if ring { KK.hintBox(&pic, "hr", x: 0, y: Y(P, 0), w: 20, h: Self.row(P) * Double(P.at + 1) - 1) }
            if spot { pic.sketch.box("spot", pic.R(0, Y(P, P.at + 1), 20, Self.row(P) * Double(P.bt) - 1), .chapter, width: Sketch.stroke, dashed: true) }
        case 3: if ring { KK.hintBox(&pic, "hr", x: 0, y: Y(P, 0), w: 20, h: Self.row(P) * Double(P.T) + 2) }
        default: break
        }

        // the record: the column form, the small 1 over the tens once the ten is made
        if st >= 0 {
            let mid = A2.column(&rec, "col", x: 0, y: 1, [P.a, P.b], sign: "+")
            if closed { rec.word("carry", "1", at: 3, 0.4, A2.carry) }
            if st == 3 { A2.answer(&rec, "ans", x: 0, mid: mid, done: nil); if spot { A1.note(&rec, "spot", "\(P.sum)", x: 7, y: mid) } }
            else if st == 4 { A2.answer(&rec, "ans", x: 0, mid: mid, done: P.sum) }
            else { rec.sketch.box("answ", rec.R(2, mid - 1, 4, 2), .ink3, width: Sketch.stroke) }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    /// Where carried rows would land: 1 a's ones, 2 a's tens, 0 nowhere.
    private func over(_ P: Regroup2.Parts, _ w: Int, _ dx: Double, _ dy: Double) -> Int {
        let cx = Self.RX + dx + (w == 1 ? Double(P.bo) : 10)
        let cy = (w == 1 ? Y(P, P.bt) + 1 : Y(P, 0) + (Self.row(P) * Double(P.bt) - 1) / 2) + dy
        guard cx > -3, cx < 23 else { return 0 }
        return cy >= Y(P, P.at) - 1.5 ? 1 : 2
    }
    private func readout(_ P: Regroup2.Parts, _ w: Int, _ o: Int) -> String {
        w == 1 ? (o == 1 ? "\(P.ao) + \(P.bo) = \(P.O)" : G2.count(P.bo, "one")) : (o != 0 ? "\(P.at) + \(P.bt) + 1 = \(G2.count(P.T, "ten"))" : G2.count(P.bt, "ten"))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Regroup2.Parts(s.numbers), RX = Self.RX, st = at(s)
        func inBox(_ q: CGPoint, _ x: Double, _ y: Double, _ w: Double, _ h: Double) -> Bool { q.x >= x - 0.5 && q.x <= x + w + 0.5 && q.y >= y - 0.5 && q.y <= y + h + 0.5 }
        let tensBox = (RX, Y(P, 0), 20.0, Self.row(P) * Double(P.bt) - 1)
        func carry(_ what: Int) -> Hands {
            Hands(
                grab: { q in
                    if what == 1 && inBox(q, RX, Y(P, P.bt), 2 * Double(P.bo), 2) { return ["grab": 1, "w": 1, "gx": q.x, "gy": q.y, "dx": 0, "dy": 0] }
                    if inBox(q, tensBox.0, tensBox.1, tensBox.2, tensBox.3) { return what == 2 ? ["grab": 1, "w": 2, "gx": q.x, "gy": q.y, "dx": 0, "dy": 0] : ["grab": 1, "w": 0] }
                    return nil
                },
                drag: { q, held in
                    var h = held; guard (held["w"] ?? 0) != 0 else { return h }
                    h["dx"] = q.x - (held["gx"] ?? q.x); h["dy"] = q.y - (held["gy"] ?? q.y); return h
                },
                release: { held in
                    let w = Int(held["w"] ?? 0)
                    if w == 0 { return HandMove(hand: [:], missHand: [:], set: [("o", -2)], check: true) }
                    let dx = held["dx"] ?? 0, dy = held["dy"] ?? 0, o = over(P, w, dx, dy), moved = hypot(dx, dy) > 2
                    let keep: Numbers = ["lx": dx, "ly": dy, "lw": Double(w)]
                    let box = w == 1 ? "o" : "t", right = Double(w == 1 ? P.O : P.bt)
                    if (w == 1 && o == 1) || (w == 2 && o != 0) { return HandMove(hand: [:], missHand: [:], set: [(box, right)], keep: keep, check: true) }
                    if moved { return HandMove(hand: [:], missHand: [:], set: [(box, -1)], keep: keep, check: true) }
                    return HandMove(hand: [:])
                })
        }
        switch st {
        case 0: return carry(1)
        case 1:
            return Hands(tap: { q in
                guard q.x >= -0.5, q.x <= 20.5 else { return nil }
                let c = Int(((q.y - Self.top(P) + 0.5) / Self.row(P)).rounded(.down)) - P.at
                if c == 0 { return HandMove(hand: nil, missHand: nil, set: [("g", 1)], check: true) }
                if c == 1 && P.left > 0 { return HandMove(hand: nil, missHand: nil, set: [("g", -1)], check: true) }
                return nil
            })
        case 2: return carry(2)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Regroup2.Parts(s.numbers), RX = Self.RX
        switch at(s) {
        case 0: return [.drag(from: CGPoint(x: RX + 1, y: Y(P, P.bt) + 1), to: CGPoint(x: 1, y: Y(P, P.at) + 1))]
        case 1: return [.tap(.picture(CGPoint(x: 10, y: Y(P, P.at) + 1)))]
        case 2: return [.drag(from: CGPoint(x: RX + 10, y: Y(P, 0) + 1), to: CGPoint(x: 10, y: Y(P, P.at + 1) + 1))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        switch at(s) {
        case 0: return HandMove(hand: [:], missHand: [:], set: [("o", -1)], check: true)
        case 1: return HandMove(hand: nil, missHand: nil, set: [("g", -1)], check: true)
        case 2: return HandMove(hand: [:], missHand: [:], set: [("t", -1)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        at(s) == 3 ? ["x": Double(Regroup2.Parts(s.numbers).slips[0].0)] : nil
    }
}
