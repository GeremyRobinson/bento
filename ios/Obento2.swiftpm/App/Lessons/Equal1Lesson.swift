import SwiftUI

/// True or false? on the paper, as in the preview (design/prototype/grade1-ch2.html, dEqual): the equation written once, big,
/// on the picture's top rows; under it each side's amount as counters from one start line, the left side on row 4, the right
/// on row 8. A sum's second part (striped) sits a block to the right; a take away's last counters are crossed out.
/// True or false: slide each side into one row (the striped part left against its first, the crossed-out ones away), then
/// a dashed line drops from the shorter row's end ("5 and 7") and True or False is tapped; the word is written after the
/// equation. Make it true: drag the box's row (striped) until it ends level with the other row's end (dashed), then write
/// the box on the number row.
///
/// Hand: "grab", "side" (0 left, 1 right), "gx", "gy", "dx", "dy" (a part slid), or "k0", "k" (the box's row). Kept: "jL",
/// "jR" a side made one row, "pick" the word tapped, "k" the box's row as let go.
@MainActor
struct Equal1Lesson: PaperLesson {
    var liveKeys: Set<String> { ["dx", "dy", "k"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let rows = [4.0, 8.0], gap = 5.0, under = 13.0, keys = 15.0
    func recordRow(_ n: Numbers) -> Double? { 14 }

    private func toks(_ side: Equal1.Side, _ box: A1.Tok) -> [A1.Tok] {
        let n: (Int) -> A1.Tok = { $0 < 0 ? box : .n($0) }
        return side.t == 0 ? [n(side.p0)] : [n(side.p0), .op(side.sign), n(side.p1)]
    }
    private func joined(_ s: PaperState, _ i: Int, _ side: Equal1.Side) -> Bool {
        side.t == 0 || at(s) > 0 || s.run.kept[i == 0 ? "jL" : "jR"] == 1
    }
    /// The box's counters: k while held, else as let go (the answer once the drag is done).
    private func k(_ s: PaperState, _ P: Equal1.Parts) -> Int {
        if at(s) > 0 { return P.x }
        if s.grabbed, let k = s.h("k") { return Int(k) }
        return Int(s.run.kept["k"] ?? 0)
    }
    /// The box's row: its length and where the box's own counters are.
    private func boxRun(_ P: Equal1.Parts, _ k: Int) -> (len: Int, from: Int) {
        switch P.form {
        case .box, .boxMinus: (k, 0)
        case .boxPlus: (k + P.d, 0)
        case .plusBox: (P.d + k, P.d)
        case .minusBox: (P.d, P.d - k)
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Equal1.Parts(s.numbers), st = at(s)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let held = s.grabbed && s.h("side") != nil ? Int(s.h("side") ?? 0) : nil
        // the equation, once, on the top rows; True or False written after it
        var box: A1.Tok = .box(nil, wrong: false)
        if P.make {
            if st == 1 { let (v, wrong) = KK.typed(s, "x", want: P.x); box = .box(v, wrong: wrong) }
            if st == 2 { box = .n(P.x, .chapter) }
        }
        let end = A1.record(&pic, "eq", toks(P.L, box) + [.op("=")] + toks(P.R, box), line: 1)
        if !P.make && st == 2 { pic.word("verdict", P.truth ? "True" : "False", at: end + 1.5, 1, KK.words.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5)) }
        pic.line("start", [(0, Self.rows[0] - 1), (0, Self.rows[1] + 4)])

        for (i, side) in P.sides.enumerated() {
            let y = Self.rows[i], key = i == 0 ? "L" : "R"
            if P.make && side.box { drawBox(&pic, &live, s, P, y: y); continue }
            let j = joined(s, i, side)
            switch side.t {
            case 0: for c in 0..<side.p0 { A1.counter(&pic, "\(key)a\(c)", x: A1.x(c), y: y, .solid) }
            case 1:
                for c in 0..<side.p0 { A1.counter(&pic, "\(key)a\(c)", x: A1.x(c), y: y, .solid) }
                if P.make {
                    for c in 0..<side.p1 { A1.counter(&pic, "\(key)b\(c)", x: A1.x(side.p0 + c), y: y, .dotted) }
                } else if held == i {
                    let g = s.h("dx") ?? Self.gap
                    for c in 0..<side.p1 { A1.counter(&live, "\(key)b\(c)", x: A1.x(side.p0 + c) + g, y: y, .striped) }
                } else {
                    let g = j ? 0 : Self.gap
                    let was: ((inout GridPen) -> Void)? = j && st == 0 ? { p in for c in 0..<side.p1 { A1.counter(&p, "\(key)b\(c)", x: A1.x(side.p0 + c) + 1, y: y, .striped) } } : nil
                    KM.seeded(&pic, was: was) { p in for c in 0..<side.p1 { A1.counter(&p, "\(key)b\(c)", x: A1.x(side.p0 + c) + g, y: y, .striped) } }
                }
            default:
                let left = side.p0 - side.p1
                for c in 0..<left { A1.counter(&pic, "\(key)a\(c)", x: A1.x(c), y: y, .solid) }
                if P.make { for c in left..<side.p0 { E1.ghost(&pic, "\(key)x\(c)", x: A1.x(c), y: y, crossed: true) } }
                else if held == i {
                    let dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0
                    for c in left..<side.p0 { A1.counter(&live, "\(key)x\(c)", x: A1.x(c) + dx, y: y + dy, .solid, cross: true) }
                } else if !j { for c in left..<side.p0 { A1.counter(&pic, "\(key)x\(c)", x: A1.x(c), y: y, .solid, cross: true) } }
            }
            if !P.make && j && st < 2 || !P.make && st == 2 { pic.label("lv\(key)", "\(side.value())", KK.maths, .right, edge: A1.x(side.value()), along: y + 1.5) }
        }

        if P.make {
            // the other row's end, dropped through both rows: the box's row ends level with it
            pic.line("lvl", [(A1.x(P.T), Self.rows[0] - 0.6), (A1.x(P.T), Self.rows[1] + 3.6)], .ink3, dashed: true)
            switch st {
            case 0:
                let kr = P.boxLeft ? 1 : 0
                if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: Self.rows[kr], w: A1.x(P.K.count), h: 3) }
                if s.on("spot") { pic.sketch.box("spot", pic.R(0, Self.rows[1 - kr], A1.x(P.T), 3), .chapter, width: Sketch.stroke, dashed: true) }
            case 1:
                let (v, wrong) = KK.typed(s, "x", want: P.x)
                A1.numberRow(&pic, "nr", y: Self.keys, wrong: wrong ? v : nil, spot: s.on("spot") ? P.x : nil)
                if s.on("ring") && !s.on("spot") {
                    let r = boxRun(P, P.x), n = P.form == .minusBox ? P.x : P.x
                    KK.hintBox(&pic, "hr", x: A1.x(r.from), y: Self.rows[P.boxLeft ? 0 : 1], w: A1.x(n), h: 3)
                }
            default: break
            }
        } else if st >= 1 {
            // a dashed line drops from the shorter row's end; "5 and 7"
            let m = min(P.vL, P.vR)
            pic.sketch.delay = 0.3
            pic.line("drop\(m)", [(A1.x(m), Self.rows[0] - 0.6), (A1.x(m), Self.rows[1] + 3.6)], .chapter, dashed: true)
            A1.note(&pic, "ro", "\(P.vL) and \(P.vR)", x: 0, y: Self.under)
            pic.sketch.delay = 0
            if st == 1 {
                let pick = s.run.kept["pick"].map { Int($0) }
                E1.block(&pic, "bt", x: 0, y: Self.keys, w: 10, "True", wrong: pick == 1 && !P.truth)
                E1.block(&pic, "bf", x: 15, y: Self.keys, w: 10, "False", wrong: pick == 0 && P.truth)
                if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: A1.x(m) - 3, y: Self.rows[0], w: 6, h: Self.rows[1] - Self.rows[0] + 3) }
                if s.on("spot") { KK.hintBox(&pic, "spot", x: P.truth ? 0 : 15, y: Self.keys, w: 10, h: 4) }
            }
        } else if st == 0 {
            if s.on("ring") || s.on("spot") {
                for (i, side) in P.sides.enumerated() where side.t != 0 && !joined(s, i, side) {
                    let x = side.t == 1 ? A1.x(side.p0) + Self.gap : A1.x(side.p0 - side.p1)
                    KK.hintBox(&pic, "hr\(i)", x: x, y: Self.rows[i], w: A1.x(side.p1), h: 3)
                }
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    /// The box's row, with k counters for the box (striped), and its readout.
    private func drawBox(_ pic: inout GridPen, _ live: inout GridPen, _ s: PaperState, _ P: Equal1.Parts, y: Double) {
        let k = k(s, P), d = P.d, holding = s.grabbed && s.h("k") != nil
        var pen = holding ? live : pic
        switch P.form {
        case .box: for j in 0..<k { A1.counter(&pen, "Bk\(j)", x: A1.x(j), y: y, .striped) }
        case .boxPlus:
            for j in 0..<k { A1.counter(&pen, "Bk\(j)", x: A1.x(j), y: y, .striped) }
            for j in 0..<d { A1.counter(&pen, "Bd\(j)", x: A1.x(k + j), y: y, .solid) }
        case .plusBox:
            for j in 0..<d { A1.counter(&pen, "Bd\(j)", x: A1.x(j), y: y, .solid) }
            for j in 0..<k { A1.counter(&pen, "Bk\(j)", x: A1.x(d + j), y: y, .striped) }
        case .boxMinus: for j in 0..<k { A1.counter(&pen, "Bk\(j)", x: A1.x(j), y: y, .striped, cross: j >= k - d) }
        case .minusBox:
            for j in 0..<(d - k) { A1.counter(&pen, "Bd\(j)", x: A1.x(j), y: y, .solid) }
            for j in (d - k)..<d { E1.ghost(&pen, "Bx\(j)", x: A1.x(j), y: y, crossed: true) }
        }
        let ro: String
        switch P.form {
        case .box: ro = "\(k)"
        case .boxPlus: ro = "\(k) and \(d) make \(k + d)"
        case .plusBox: ro = "\(d) and \(k) make \(d + k)"
        case .boxMinus: ro = k >= d ? "\(k) take away \(d) is \(k - d)" : "\(k)"
        case .minusBox: ro = "\(d) take away \(k) is \(d - k)"
        }
        if k > 0 || P.form == .minusBox {
            if holding { pen.reads(ro) }
            A1.note(&pen, "bro", ro, x: 0, y: Self.under)
        }
        if holding { live = pen } else { pic = pen }
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Equal1.Parts(s.numbers), st = at(s)
        if P.make {
            switch st {
            case 0:
                let y = Self.rows[P.boxLeft ? 0 : 1], k0 = k(s, P), len = boxRun(P, k0).len
                let minus = P.form == .minusBox, most = P.kmax
                return Hands(
                    grab: { q in
                        guard q.y >= y - 0.5, q.y <= y + 3.5, q.x >= -0.5, q.x <= A1.x(len) + 3.5 else { return nil }
                        return ["grab": 1, "gx": q.x, "k0": Double(k0), "k": Double(k0)]
                    },
                    drag: { q, held in
                        var held = held
                        let dk = Int(((q.x - (held["gx"] ?? q.x)) / 3).rounded()), k0 = Int(held["k0"] ?? 0)
                        held["k"] = Double(max(0, min(most, minus ? k0 - dk : k0 + dk)))
                        return held
                    },
                    release: { held in
                        let k = Int(held["k"] ?? 0)
                        guard k != Int(held["k0"] ?? 0) else { return HandMove(hand: [:]) }
                        return HandMove(hand: [:], missHand: [:], set: [("k", Double(k))], keep: ["k": Double(k)], check: true)
                    })
            case 1: return A1.rowHands("x", y: Self.keys)
            default: return nil
            }
        }
        switch st {
        case 0 where P.slides:
            func joinedNow(_ i: Int) -> Bool { joined(s, i, P.sides[i]) }
            return Hands(
                grab: { q in
                    for (i, side) in P.sides.enumerated() where side.t != 0 && !joinedNow(i) {
                        let y = Self.rows[i]
                        guard q.y >= y - 0.5, q.y <= y + 3.5 else { continue }
                        if side.t == 1, q.x >= A1.x(side.p0) + Self.gap - 0.5, q.x <= A1.x(side.p0 + side.p1) + Self.gap + 0.5 {
                            return ["grab": 1, "side": Double(i), "gx": q.x, "gy": q.y, "dx": Self.gap]
                        }
                        if side.t == 2, q.x >= A1.x(side.p0 - side.p1) - 0.5, q.x <= A1.x(side.p0) + 0.5 {
                            return ["grab": 1, "side": Double(i), "gx": q.x, "gy": q.y, "dx": 0, "dy": 0]
                        }
                    }
                    return nil
                },
                drag: { q, held in
                    var held = held
                    let i = Int(held["side"] ?? 0), dx = (q.x - (held["gx"] ?? q.x)).rounded(), dy = (q.y - (held["gy"] ?? q.y)).rounded()
                    if P.sides[i].t == 1 { var g = max(0, min(Self.gap + 3, Self.gap + dx)); if g < 1.5 { g = 0 }; held["dx"] = g }
                    else { held["dx"] = dx; held["dy"] = dy }
                    return held
                },
                release: { held in
                    let i = Int(held["side"] ?? 0), side = P.sides[i]
                    let made = side.t == 1 ? (held["dx"] ?? 1) == 0 : ((held["dx"] ?? 0) * (held["dx"] ?? 0) + (held["dy"] ?? 0) * (held["dy"] ?? 0)) > 16
                    guard made else { return HandMove(hand: [:]) }
                    let key = i == 0 ? "jL" : "jR"
                    let all = P.sides.indices.allSatisfy { $0 == i || joinedNow($0) }
                    return HandMove(hand: [:], set: all ? [("j", 1)] : [], keep: [key: 1], check: all)
                })
        case 0, 1:
            return Hands(tap: { q in
                guard q.y >= Self.keys, q.y <= Self.keys + 4 else { return nil }
                let v: Int? = q.x >= 0 && q.x <= 10 ? 1 : q.x >= 15 && q.x <= 25 ? 0 : nil
                return v.map { HandMove(hand: nil, missHand: nil, set: [("tf", Double($0))], keep: ["pick": Double($0)], check: true) }
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Equal1.Parts(s.numbers), st = at(s)
        if P.make {
            switch st {
            case 0:
                let y = Self.rows[P.boxLeft ? 0 : 1] + 1.5, k0 = k(s, P), len = boxRun(P, k0).len
                let from = max(1.5, A1.x(len) - 1.5), dk = Double(P.x - k0) * (P.form == .minusBox ? -3 : 3)
                return [.drag(from: CGPoint(x: from, y: y), to: CGPoint(x: from + dk, y: y))]
            case 1: return [.tap(.picture(A1.keySpot(P.x, y: Self.keys)))]
            default: return []
            }
        }
        if st == 0 && P.slides {
            return P.sides.enumerated().compactMap { i, side -> GhostMove? in
                guard side.t != 0, !joined(s, i, side) else { return nil }
                let y = Self.rows[i] + 1.5
                if side.t == 1 { let x = A1.x(side.p0) + Self.gap + 1.5; return .drag(from: CGPoint(x: x, y: y), to: CGPoint(x: x - Self.gap, y: y)) }
                let x = A1.x(side.p0 - side.p1) + 1.5
                return .drag(from: CGPoint(x: x, y: y), to: CGPoint(x: x + 8, y: y))
            }
        }
        if st <= 1 { return [.tap(.picture(CGPoint(x: P.truth ? 5 : 20, y: Self.keys + 2)))] }
        return []
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Equal1.Parts(s.numbers), st = at(s)
        if P.make {
            switch st {
            case 0: let k = P.x + 1 <= P.kmax ? P.x + 1 : P.x - 1; return HandMove(hand: [:], missHand: [:], set: [("k", Double(k))], keep: ["k": Double(k)], check: true)
            case 1: return A1.slip("x", P.x)
            default: return nil
            }
        }
        if st == 0 && P.slides { return nil }
        guard st <= 1 else { return nil }
        let v = P.truth ? 0 : 1
        return HandMove(hand: nil, missHand: nil, set: [("tf", Double(v))], keep: ["pick": Double(v)], check: true)
    }
}
