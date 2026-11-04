import SwiftUI

/// Subtracting with regrouping on the paper, as in the preview (design/prototype/grade2-ch1.html, dSubRegroup): a at the
/// left as ten rows and a ones row (tinted); b at the right drawn dashed, its ones row level with a's. As the step opens, b's
/// dashed ones slide over a's by themselves, hang past the end and slide back: not enough ones. Tap a ten: its counters
/// drop to a loose row of ten over the ones (in the column the tens digit is crossed with one less over it, the ones made
/// 12). Slide the dashed ones over the loose row (each one under them crossed out, "12 − 7 = 5"); slide the dashed tens over
/// ten rows (crossed, "4 − 2 = 2 tens"); write what's left. The story kind picks + Add or − Take away first.
///
/// Hand: "grab", "gx", "gy", "dx", "dy", "w" (1 the dashed ones, 2 the dashed tens, 0 a dead grab). Kept: "r" the ten opened,
/// "p" where the dashed ones sit on the loose row, "lx", "ly", "lw" where the last carry was let go.
@MainActor
struct SubRegroup2Lesson: PaperLesson {
    static let RX = 25.0
    var liveKeys: Set<String> { ["dx", "dy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static func top(_ P: SubRegroup2.Parts) -> Double { P.story ? 2 * Double(A2.storyRows(P.lines, width: 44).count) + 3 : 0 }
    private func Y(_ P: SubRegroup2.Parts, _ r: Int) -> Double { Self.top(P) + A2.row * Double(r) }

    func told(_ s: PaperState) -> String? { let P = SubRegroup2.Parts(s.numbers); return P.story ? P.lines.joined(separator: " ") : nil }
    func recordBeside(_ n: Numbers) -> Double? { Self.top(SubRegroup2.Parts(n)) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = SubRegroup2.Parts(s.numbers), st = at(s), RX = Self.RX, k = s.run.kept
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        if P.story {
            A2.tell(&pic, P.lines, width: 44)
            pic.word("nmA", "on the sheet", at: 10, Self.top(P) - 1.2, A2.small)
            pic.word("nmB", "used", at: RX + 10, Y(P, P.at - P.bt) - 1.2, A2.small)
        }
        let held = s.grabbed && (s.h("w") ?? 0) != 0, w = Int(s.h("w") ?? 0), dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0
        let opened = st >= 1, r0 = Int(k["r"] ?? Double(P.at - 1)), onesOn = st >= 2, tensOn = st >= 3
        let p = Int(k["p"] ?? Double(10 - P.bo))
        // a's tens: the opened one gone, the rest closing up; the ones b's dashed tens cover crossed out
        let tens = (0..<P.at).filter { !opened || $0 != r0 }
        for (r, id) in tens.enumerated() { A2.ten(&pic, "A.t\(id)", x: 0, y: Y(P, r), .solid, cross: tensOn && r >= P.at - 1 - P.bt) }
        // the opened ten: a loose row of ten over the ones, its counters starting where the ten was
        if opened {
            if st == 1 { pic.sketch.from = A2.kinds { q in for j in 0..<10 { A2.counter(&q, "L.o\(j)", x: 2 * Double(j), y: Y(P, r0), .solid) } } }
            for j in 0..<10 { A2.counter(&pic, "L.o\(j)", x: 2 * Double(j), y: Y(P, P.at - 1), .solid, cross: onesOn && j >= p && j < p + P.bo) }
            pic.sketch.from = [:]
        }
        for j in 0..<P.ao { A2.counter(&pic, "A.o\(j)", x: 2 * Double(j), y: Y(P, P.at), .solid) }
        // where the last carry was let go: what it carried starts from there
        if !held, let lw = k["lw"], (lw == 1 && st == 2) || (lw == 2 && st == 3) {
            let lx = k["lx"] ?? 0, ly = k["ly"] ?? 0
            pic.sketch.from = A2.kinds { q in
                if lw == 1 { for j in 0..<P.bo { A2.counter(&q, "B.o\(j)", x: RX + 2 * Double(j) + lx, y: Y(P, P.at) + ly, .dashed) } }
                else { for r in 0..<P.bt { A2.ten(&q, "B.t\(r)", x: RX + lx, y: Y(P, P.at - P.bt + r) + ly, .dashed) } }
            }
        }
        // b, dashed: its tens (home, carried, or over a's tens), its ones (home, carried, or over the loose row)
        for r in 0..<P.bt {
            if tensOn { A2.ten(&pic, "B.t\(r)", x: 0, y: Y(P, P.at - 1 - P.bt + r), .dashed) }
            else if held && w == 2 { A2.ten(&live, "B.t\(r)", x: RX + dx, y: Y(P, P.at - P.bt + r) + dy, .dashed) }
            else { A2.ten(&pic, "B.t\(r)", x: RX, y: Y(P, P.at - P.bt + r), .dashed) }
        }
        let ask = st == 0 && !opened
        for j in 0..<P.bo {
            let id = ask ? "B.o\(j)a" : "B.o\(j)"
            if onesOn { A2.counter(&pic, id, x: 2 * Double(p + j), y: Y(P, P.at - 1), .dashed) }
            else if held && w == 1 { A2.counter(&live, id, x: RX + 2 * Double(j) + dx, y: Y(P, P.at) + dy, .dashed) }
            else {
                if ask {
                    // Ask: they slide over a's ones by themselves, hang past the end, and slide back
                    let home = A2.kinds { q in A2.counter(&q, id, x: RX + 2 * Double(j), y: Y(P, P.at), .dashed) }
                    let over = A2.kinds { q in A2.counter(&q, id, x: 2 * Double(j), y: Y(P, P.at), .dashed) }
                    for (pid, kd) in home { pic.sketch.from[pid] = kd }
                    for (pid, kd) in over { pic.sketch.via[pid] = kd }
                    pic.sketch.delay = 1.2
                }
                A2.counter(&pic, id, x: RX + 2 * Double(j), y: Y(P, P.at), .dashed)
            }
        }
        pic.sketch.from = [:]; pic.sketch.via = [:]; pic.sketch.delay = 0
        if held { live.reads(readout(P, w, over(P, w, dx, dy))) }

        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        switch st {
        case 0:
            if ring { KK.hintBox(&pic, "hr", x: 0, y: Y(P, 0), w: 20, h: A2.row * Double(P.at) - 1) }
            if spot { KK.hintBox(&pic, "spot", x: 0, y: Y(P, P.at - 1), w: 20, h: 2) }
        case 1:
            if ring { KK.hintBox(&pic, "hr", x: 0, y: Y(P, P.at - 1), w: 20, h: 5) }
            if spot { pic.sketch.box("spot", pic.R(2 * Double(10 - P.bo), Y(P, P.at - 1), 2 * Double(P.bo), 2), .chapter, width: Sketch.stroke, dashed: true) }
        case 2:
            if ring { KK.hintBox(&pic, "hr", x: 0, y: Y(P, 0), w: 20, h: A2.row * Double(P.at - 1) - 1) }
            if spot { pic.sketch.box("spot", pic.R(0, Y(P, P.at - 1 - P.bt), 20, A2.row * Double(P.bt) - 1), .chapter, width: Sketch.stroke, dashed: true) }
        case 3: if ring { KK.hintBox(&pic, "hr", x: 0, y: Y(P, 0), w: 20, h: A2.row * Double(P.at) + 2) }
        default: break
        }

        // the record: the column form with its trade marks
        if st >= 0 {
            let mid = A2.column(&rec, "col", x: 0, y: 1, [P.a, P.b], sign: "−")
            if opened {
                rec.line("xT", [(2.4, 2.6), (3.6, 1.4)]); rec.word("nT", "\(P.at - 1)", at: 3, 0.4, A2.carry)
                rec.line("xO", [(4.4, 2.6), (5.6, 1.4)]); rec.word("nO", "1\(P.ao)", at: 5.3, 0.4, A2.carry)
            }
            if st == 3 { A2.answer(&rec, "ans", x: 0, mid: mid, done: nil); if spot { A1.note(&rec, "spot", "\(P.diff)", x: 7, y: mid) } }
            else if st == 4 { A2.answer(&rec, "ans", x: 0, mid: mid, done: P.diff) }
            else { rec.sketch.box("answ", rec.R(2, mid - 1, 4, 2), .ink3, width: Sketch.stroke) }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    /// Where carried dashed rows would land: 1 over the ones, 2 over the tens, 0 nowhere.
    private func over(_ P: SubRegroup2.Parts, _ w: Int, _ dx: Double, _ dy: Double) -> Int {
        let cx = Self.RX + dx + (w == 1 ? Double(P.bo) : 10)
        let cy = (w == 1 ? Y(P, P.at) + 1 : Y(P, P.at - P.bt) + (A2.row * Double(P.bt) - 1) / 2) + dy
        guard cx > -3, cx < 23, cy > Y(P, 0) - 2, cy < Y(P, P.at) + 4 else { return 0 }
        return cy >= Y(P, P.at - 1) - 0.5 ? 1 : 2
    }
    private func readout(_ P: SubRegroup2.Parts, _ w: Int, _ o: Int) -> String {
        w == 1 ? (o == 1 ? "\(P.O) − \(P.bo) = \(P.onesLeft)" : G2.count(P.bo, "one")) : (o == 2 ? "\(P.at - 1) − \(P.bt) = \(G2.count(P.tensLeft, "ten"))" : G2.count(P.bt, "ten"))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = SubRegroup2.Parts(s.numbers), RX = Self.RX, st = at(s)
        func inBox(_ q: CGPoint, _ x: Double, _ y: Double, _ w: Double, _ h: Double) -> Bool { q.x >= x - 0.5 && q.x <= x + w + 0.5 && q.y >= y - 0.5 && q.y <= y + h + 0.5 }
        func carry(_ what: Int) -> Hands {
            Hands(
                grab: { q in
                    if what == 1 && inBox(q, RX, Y(P, P.at), 2 * Double(P.bo), 2) { return ["grab": 1, "w": 1, "gx": q.x, "gy": q.y, "dx": 0, "dy": 0] }
                    if inBox(q, RX, Y(P, P.at - P.bt), 20, A2.row * Double(P.bt) - 1) { return what == 2 ? ["grab": 1, "w": 2, "gx": q.x, "gy": q.y, "dx": 0, "dy": 0] : ["grab": 1, "w": 0] }
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
                    var keep: Numbers = ["lx": dx, "ly": dy, "lw": Double(w)]
                    let box = w == 1 ? "o" : "t"
                    if o == w {
                        if w == 1 { keep["p"] = Double(max(0, min(10 - P.bo, Int(((RX + dx) / 2).rounded())))) }
                        return HandMove(hand: [:], missHand: [:], set: [(box, 1)], keep: keep, check: true)
                    }
                    if moved { return HandMove(hand: [:], missHand: [:], set: [(box, -1)], keep: keep, check: true) }
                    return HandMove(hand: [:])
                })
        }
        switch st {
        case 0:
            return Hands(tap: { q in
                guard q.x >= -0.5, q.x <= 20.5 else { return nil }
                let r = Int(((q.y - Self.top(P) + 0.5) / A2.row).rounded(.down))
                if r == P.at { return HandMove(hand: nil, missHand: nil, set: [("k", -1)], check: true) }
                guard r >= 0, r < P.at else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("k", 1)], keep: ["r": Double(r)], check: true)
            })
        case 1: return carry(1)
        case 2: return carry(2)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = SubRegroup2.Parts(s.numbers), RX = Self.RX
        switch at(s) {
        case 0: return [.tap(.picture(CGPoint(x: 10, y: Y(P, P.at - 1) + 1)))]
        case 1: return [.drag(from: CGPoint(x: RX + 1, y: Y(P, P.at) + 1), to: CGPoint(x: 1 + 2 * Double(10 - P.bo), y: Y(P, P.at - 1) + 1))]
        case 2: return [.drag(from: CGPoint(x: RX + 10, y: Y(P, P.at - P.bt) + 1), to: CGPoint(x: 10, y: Y(P, P.at - 1 - P.bt) + 1))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        switch at(s) {
        case 0: return HandMove(hand: nil, missHand: nil, set: [("k", -1)], check: true)
        case 1: return HandMove(hand: [:], missHand: [:], set: [("o", -1)], check: true)
        case 2: return HandMove(hand: [:], missHand: [:], set: [("t", -1)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        at(s) == 3 ? ["x": Double(SubRegroup2.Parts(s.numbers).slips[0].0)] : nil
    }
}
