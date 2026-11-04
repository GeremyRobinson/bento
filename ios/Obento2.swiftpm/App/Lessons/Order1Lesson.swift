import SwiftUI

/// Longest to shortest on the paper, as in the preview (design/prototype/grade1-ch5.html, dOrder3): three things as bars 4
/// squares thick on every other block row (0, 10, 20), each starting 1–3 blocks past the dashed start line, its name at its
/// right end. Slide each one's end to the line (near it, it snaps on; elsewhere it slides back, said); then drag them into
/// order, longest on top (drop one on another's row and they swap; a swap that puts the shorter on top slides back, said),
/// the top and bottom rows named "longest" and "shortest"; the record names them.
/// Use a go-between (dBetween): the rug lies across the paper, the desk stands up its side on a floor, both stuck; a string
/// a little longer than the longer one moves: laid along the first, a mark goes where that thing stops; laid along the
/// second, it stands up beside it and the mark lands before or past its end, the gap counted in blocks; tap the longer one.
///
/// Kept: "L<k>" thing k lined up, "r<k>" its row; the last let go "rk" and where ("rx", "ry"); a swapped one "ok", "oy".
/// Go-between: "lx", "ly" where the string was let go, "bad" the thing tapped and wrong. Hand: "grab", "t", "gx", "gy",
/// "d" (the offset now); the string's "sx", "sy", "up", "x0", "y0", "qx".
@MainActor
struct Order1Lesson: PaperLesson {
    var liveKeys: Set<String> { ["d", "sx", "sy", "up", "qx", "gx", "gy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    // MARK: three things

    private func lined(_ s: PaperState, _ k: Int) -> Bool { at(s) > 0 || s.run.kept["L\(k)"] == 1 }
    private func row(_ s: PaperState, _ k: Int) -> Int { at(s) == 0 ? k : Int((s.run.kept["r\(k)"] ?? Double(k)).rounded()) }
    private func x0(_ s: PaperState, _ P: Order1.Parts, _ k: Int) -> Double { lined(s, k) ? 0 : 5 * Double(P.shifts[k]) }
    private func tagX(_ P: Order1.Parts, _ k: Int) -> Double { (5 * Double(P.lens[k]) + 1 + L5.width(P.names[k])).rounded(.up) }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = Order1.Parts(s.numbers)
        return P.between && at(s) == 3 ? CGPoint(x: 0, y: 12) : nil
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Order1.Parts(s.numbers)
        if P.between { return drawBetween(s, P) }
        let st = at(s)
        var pic = GridPen(), live = GridPen(stableIds: true)
        let held = st < 2 && s.grabbed ? Int(s.h("t") ?? -1) : -1, d = s.h("d") ?? 0
        let k = s.run.kept, rk = k["rk"].map { Int($0) } ?? -1, ok = k["ok"].map { Int($0) } ?? -1
        pic.line("start", [(0, 0), (0, 25)], .ink2, dashed: true)
        for t in 0..<3 where t != held {
            let x = x0(s, P, t), y = 10 * Double(row(s, t))
            let build: (inout GridPen) -> Void = { p in
                L5.bar(&p, "t\(t)", x: x, y: y, P.lens[t])
                L5.label(&p, "n\(t)", P.names[t], x: x + 5 * Double(P.lens[t]), mid: y + 3)
            }
            var was: ((inout GridPen) -> Void)?
            if t == rk || t == ok {
                let wx = t == rk && st == 0 ? (k["rx"] ?? x) : x
                let wy = t == rk && st >= 1 ? (k["ry"] ?? y) : t == ok && st >= 1 ? (k["oy"] ?? y) : y
                was = { p in
                    L5.bar(&p, "t\(t)", x: wx, y: wy, P.lens[t])
                    L5.label(&p, "n\(t)", P.names[t], x: wx + 5 * Double(P.lens[t]), mid: wy + 3)
                }
            }
            L5.seeded(&pic, was: was, build)
        }
        if held >= 0 {
            let x = st == 0 ? x0(s, P, held) + d : 0, y = 10 * Double(row(s, held)) + (st == 1 ? d : 0)
            L5.bar(&live, "t\(held)", x: x, y: y, P.lens[held])
            L5.label(&live, "n\(held)", P.names[held], x: x + 5 * Double(P.lens[held]), mid: y + 3)
            if st == 0 {
                let o = Int((x / 5).rounded())
                live.reads(abs(x) <= 2.5 ? "On the line" : o > 0 ? "\(o) to go" : "\(-o) past")
            } else {
                let r = max(0, min(2, Int((y / 10).rounded())))
                live.reads(r == 0 ? "longest" : r == 2 ? "shortest" : "in the middle")
            }
        }
        // the top and bottom rows named, beside the names
        if st >= 1 {
            for (r, w) in [(0, "longest"), (2, "shortest")] {
                guard let t = (0..<3).first(where: { row(s, $0) == r }), t != held else { continue }
                A1.note(&pic, "ro\(w)\(t)", w, x: tagX(P, t), y: 10 * Double(r) + 3)
            }
        }
        switch st {
        case 0:
            let todo = (0..<3).filter { !lined(s, $0) }
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: -1, y: 0, w: 2, h: 25) }
            if s.on("spot"), let t = todo.first { pic.sketch.box("spot\(t)", pic.R(0, 10 * Double(t) + 1, 5 * Double(P.lens[t]), 4), .chapter, width: Sketch.stroke, dashed: true) }
        case 1:
            let ends = (0..<3).map { 5 * Double(P.lens[$0]) }
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: (ends.min() ?? 0) - 1, y: 0, w: (ends.max() ?? 0) - (ends.min() ?? 0) + 2, h: 25) }
            if s.on("spot"), let r = (0..<3).first(where: { row(s, P.order[$0]) != $0 }) {
                pic.sketch.box("spot\(r)", pic.R(0, 10 * Double(r) + 1, 5 * Double(P.lens[P.order[r]]), 4), .chapter, width: Sketch.stroke, dashed: true)
            }
        default:
            pic.word("rec", P.record, at: 0, 29, KK.words, anchor: UnitPoint(x: 0, y: 0.5))
        }
        // room for every place a thing can be, and its names, so the camera holds still while they move
        var right = 0.0
        for t in 0..<3 {
            let a: Double = 5 * Double(P.lens[t] + P.shifts[t]) + 0.5 + L5.width(P.names[t])
            let b: Double = tagX(P, t) + L5.smallWidth("shortest")
            right = max(right, a, b)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, extent: pic.R(0, 0, right, 26))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Order1.Parts(s.numbers)
        if P.between { return handsBetween(s, P) }
        let st = at(s)
        guard st < 2 else { return nil }
        func thing(_ q: CGPoint) -> Int? {
            (0..<3).first { t in
                let x = x0(s, P, t), y = 10 * Double(row(s, t))
                return q.x >= x - 0.5 && q.x <= x + 5 * Double(P.lens[t]) + 0.5 && q.y >= y + 0.5 && q.y <= y + 5.5
            }
        }
        return Hands(
            grab: { q in
                guard let t = thing(q), st == 1 || !lined(s, t) else { return nil }
                return ["grab": 1, "t": Double(t), "gx": q.x, "gy": q.y, "d": 0]
            },
            drag: { q, h in
                var h = h
                let t = Int(h["t"] ?? 0)
                if st == 0 {
                    h["d"] = max(-8 - x0(s, P, t), (q.x - (h["gx"] ?? q.x)).rounded())
                } else {
                    let y = 10 * Double(row(s, t))
                    h["d"] = max(-4 - y, min(24 - y, (q.y - (h["gy"] ?? q.y)).rounded()))
                }
                return h
            },
            release: { h in
                let t = Int(h["t"] ?? 0), d = h["d"] ?? 0
                if st == 0 {
                    let x = x0(s, P, t) + d, keep: Numbers = ["rk": Double(t), "rx": x, "ok": -1]
                    if abs(x) <= 2.5 {
                        var kp = keep; kp["L\(t)"] = 1
                        let all = (0..<3).filter { lined(s, $0) || $0 == t }.count == 3
                        return HandMove(hand: [:], missHand: [:], set: all ? [("l", 3)] : [], keep: kp, check: all)
                    }
                    guard abs(d) > 0.5 else { return HandMove(hand: [:], keep: keep) }
                    return HandMove(hand: [:], missHand: [:], set: [("l", -1)], keep: keep, check: true)
                }
                let r0 = row(s, t), y = 10 * Double(r0) + d, r = max(0, min(2, Int((y / 10).rounded())))
                var keep: Numbers = ["rk": Double(t), "ry": y, "ok": -1]
                guard r != r0, let o = (0..<3).first(where: { row(s, $0) == r }) else { return HandMove(hand: [:], keep: keep) }
                let up = r < r0 ? t : o, dn = up == t ? o : t
                if P.lens[up] < P.lens[dn] { return HandMove(hand: [:], missHand: [:], set: [("o", Double(100 + 10 * dn + up))], keep: keep, check: true) }
                keep["r\(t)"] = Double(r); keep["r\(o)"] = Double(r0); keep["ok"] = Double(o); keep["oy"] = 10 * Double(r)
                var rows = (0..<3).map { row(s, $0) }
                rows[t] = r; rows[o] = r0
                let done = (0..<3).allSatisfy { rows[P.order[$0]] == $0 }
                return HandMove(hand: [:], missHand: [:], set: done ? [("o", 1)] : [], keep: keep, check: done)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Order1.Parts(s.numbers)
        if P.between { return demoBetween(s, P) }
        switch at(s) {
        case 0:
            return (0..<3).filter { !lined(s, $0) }.map { t in
                let x = x0(s, P, t) + 2.5, y = 10 * Double(t) + 3
                return .drag(from: CGPoint(x: x, y: y), to: CGPoint(x: x - x0(s, P, t), y: y))
            }
        case 1:
            var rows = (0..<3).map { row(s, $0) }, out: [GhostMove] = []
            for r in 0..<2 {
                let t = P.order[r], r0 = rows[t]
                guard r0 != r, let o = (0..<3).first(where: { rows[$0] == r }) else { continue }
                out.append(.drag(from: CGPoint(x: 2.5, y: 10 * Double(r0) + 3), to: CGPoint(x: 2.5, y: 10 * Double(r) + 3)))
                rows[o] = r0; rows[t] = r
            }
            return out
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Order1.Parts(s.numbers)
        if P.between {
            switch at(s) {
            case 0, 1: return HandMove(hand: [:], missHand: [:], set: [(at(s) == 0 ? "a" : "b", -1)], check: true)
            case 2: return HandMove(hand: nil, missHand: nil, set: [("c", Double(1 - P.longer))], keep: ["bad": Double(1 - P.longer)], check: true)
            default: return nil
            }
        }
        switch at(s) {
        case 0: return HandMove(hand: [:], missHand: [:], set: [("l", -1)], check: true)
        case 1:
            // the shortest dragged onto the top row
            let sh = P.order[2], top = (0..<3).first { row(s, $0) == 0 } ?? 0
            return sh == top ? nil : HandMove(hand: [:], missHand: [:], set: [("o", Double(100 + 10 * top + sh))], check: true)
        default: return nil
        }
    }

    // MARK: the go-between

    private struct Pl {
        let P: Order1.Parts
        var big: Int { max(P.a, P.b) }
        var L: Double { 5 * Double(big) + 2 }
        var foot: Double { L }
        static let home = CGPoint(x: 10, y: 12.5), lying = CGPoint(x: 0, y: 5.5), bx = 51.0, sx = 55.5
        var standing: CGPoint { CGPoint(x: Self.sx, y: foot) }
    }
    /// The string as a closed strip a square wide, from its start along its way (up: standing).
    private func string(_ pen: inout GridPen, _ id: String, _ L: Double, at p: CGPoint, up: Bool, mark: Double?) {
        let pts: [(Double, Double)] = up ? [(p.x - 0.5, p.y), (p.x - 0.5, p.y - L), (p.x + 0.5, p.y - L), (p.x + 0.5, p.y), (p.x - 0.5, p.y)]
            : [(p.x, p.y - 0.5), (p.x + L, p.y - 0.5), (p.x + L, p.y + 0.5), (p.x, p.y + 0.5), (p.x, p.y - 0.5)]
        pen.line(id, pts)
        if let m = mark {
            if up { pen.line(id + "m", [(p.x - 1.5, p.y - m), (p.x + 1.5, p.y - m)], .chapter) } else { pen.line(id + "m", [(p.x + m, p.y - 1.5), (p.x + m, p.y + 1.5)], .chapter) }
        }
    }

    private func drawBetween(_ s: PaperState, _ P: Order1.Parts) -> PaperDrawing {
        let st = at(s), Q = Pl(P: P), A = P.names[0], B = P.names[1]
        var pic = GridPen(), live = GridPen(stableIds: true)
        let bad = st == 2 ? s.run.kept["bad"].map { Int($0) } : nil
        L5.bar(&pic, "A\(bad == 0)", x: 0, y: 0, P.a, thick: 3, colour: bad == 0 ? KK.red : .ink)
        L5.label(&pic, "An", A, x: 5 * Double(P.a), mid: 2.5)
        pic.line("floor", [(Pl.bx - 3, Q.foot), (Pl.bx + 9, Q.foot)])
        pic.fill("Bf", col: Pl.bx, row: Q.foot - 5 * Double(P.b), w: 3, h: 5 * Double(P.b), .tint(0.2))
        pic.sketch.box("Bo\(bad == 1)", pic.R(Pl.bx, Q.foot - 5 * Double(P.b), 3, 5 * Double(P.b)), bad == 1 ? KK.red : .ink, width: Sketch.stroke)
        pic.word("Bn", B, at: Pl.bx + 1.5, Q.foot - 5 * Double(P.b) - 1.5, KK.words)
        let mark: Double? = st >= 1 ? 5 * Double(P.a) : nil
        let k = s.run.kept, held = st < 2 && s.grabbed
        if held {
            let up = s.h("up") == 1
            string(&live, "str", Q.L, at: CGPoint(x: s.h("sx") ?? 0, y: s.h("sy") ?? 0), up: up, mark: mark)
        } else {
            let rest = st == 0 ? Pl.home : st == 1 ? Pl.lying : Q.standing, up = st >= 2
            var was: ((inout GridPen) -> Void)?
            if let lx = k["lx"], let ly = k["ly"] {
                let wasUp = k["lu"] == 1
                was = { p in string(&p, "str", Q.L, at: CGPoint(x: lx, y: ly), up: wasUp, mark: mark) }
            }
            L5.seeded(&pic, was: was) { p in string(&p, "str", Q.L, at: rest, up: up, mark: mark) }
        }
        if st >= 2 {
            let lo = Double(min(P.a, P.b)), hi = Double(Q.big)
            pic.fill("gap", col: Pl.sx - 0.5, row: Q.foot - 5 * hi, w: 1, h: 5 * (hi - lo), .tint(0.45))
            A1.note(&pic, "gp", Len1.pl(P.gap, "block", "blocks"), x: Pl.sx + 2, y: Q.foot - 2.5 * Double(P.a + P.b))
        }
        switch st {
        case 0:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: 0, w: 5 * Double(P.a), h: 5) }
            if s.on("spot") { pic.sketch.box("spot", pic.R(0, 5, Q.L, 1), .chapter, width: Sketch.stroke, dashed: true) }
        case 1:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: Pl.bx, y: Q.foot - 5 * Double(P.b), w: 3, h: 5 * Double(P.b)) }
            if s.on("spot") { pic.sketch.box("spot", pic.R(Pl.sx - 0.5, 0, 1, Q.L), .chapter, width: Sketch.stroke, dashed: true) }
        case 2:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: Pl.bx, y: Q.foot - 5 * Double(Q.big) - 1, w: 7, h: 5 * Double(P.gap) + 2) }
            if s.on("spot") {
                if P.longer == 0 { KK.hintBox(&pic, "spot", x: 0, y: 1, w: 5 * Double(P.a), h: 3) }
                else { KK.hintBox(&pic, "spot", x: Pl.bx, y: Q.foot - 5 * Double(P.b), w: 3, h: 5 * Double(P.b)) }
            }
        default:
            pic.word("rec", P.betweenRecord, at: 0, 9, KK.words, anchor: UnitPoint(x: 0, y: 0.5))
        }
        let right = max(Pl.sx + 2 + L5.smallWidth("6 blocks"), Pl.bx + 1.5 + L5.width(B) / 2, 5 * Double(P.a) + 0.5 + L5.width(A), Pl.home.x + Q.L)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, extent: pic.R(0, 0, right + 1, Q.foot + 1))
    }

    private func handsBetween(_ s: PaperState, _ P: Order1.Parts) -> Hands? {
        let st = at(s), Q = Pl(P: P)
        switch st {
        case 0, 1:
            let p = st == 0 ? Pl.home : Pl.lying
            return Hands(
                grab: { q in
                    guard q.x >= p.x - 1, q.x <= p.x + Q.L + 1, abs(q.y - p.y) <= 2 else { return nil }
                    return ["grab": 1, "gx": q.x, "gy": q.y, "x0": p.x, "y0": p.y, "sx": p.x, "sy": p.y, "up": 0, "qx": q.x]
                },
                drag: { q, h in
                    var h = h
                    let up = st == 1 && q.x > 45
                    h["up"] = up ? 1 : 0; h["qx"] = q.x
                    if up { h["sx"] = Pl.sx; h["sy"] = max(Q.L, min(Q.foot + 2, (q.y + Q.L / 2).rounded())) }
                    else { h["sx"] = ((h["x0"] ?? 0) + q.x - (h["gx"] ?? q.x)).rounded(); h["sy"] = ((h["y0"] ?? 0.5) - 0.5 + q.y - (h["gy"] ?? q.y)).rounded() + 0.5 }
                    return h
                },
                release: { h in
                    let sx = h["sx"] ?? p.x, sy = h["sy"] ?? p.y, up = h["up"] == 1
                    let moved = hypot(sx - p.x, sy - p.y) > 0.5
                    let keep: Numbers = ["lx": sx, "ly": sy, "lu": up ? 1 : 0]
                    if st == 0 {
                        if hypot(sx - Pl.lying.x, sy - Pl.lying.y) <= 3 { return HandMove(hand: [:], missHand: [:], set: [("a", 1)], keep: keep, check: true) }
                    } else if moved && (up || sx > 35 || (h["qx"] ?? 0) > 43) {
                        return HandMove(hand: [:], missHand: [:], set: [("b", 1)], keep: keep, check: true)
                    }
                    guard moved else { return HandMove(hand: [:]) }
                    return HandMove(hand: [:], missHand: [:], set: [(st == 0 ? "a" : "b", -1)], keep: keep, check: true)
                })
        case 2:
            return Hands(tap: { q in
                let onA = q.x >= -0.3 && q.x <= 5 * Double(P.a) + 1 + L5.width(P.names[0]) && q.y >= -0.3 && q.y <= 5.3
                let onB = q.x >= Pl.bx - 1.3 && q.x <= Pl.bx + 4.3 && q.y >= Q.foot - 5 * Double(P.b) - 3 && q.y <= Q.foot + 0.3
                guard onA || onB else { return nil }
                let j = onA ? 0 : 1
                return HandMove(hand: nil, missHand: nil, set: [("c", Double(j))], keep: ["bad": j == P.longer ? -1 : Double(j)], check: true)
            })
        default: return nil
        }
    }

    private func demoBetween(_ s: PaperState, _ P: Order1.Parts) -> [GhostMove] {
        let Q = Pl(P: P)
        switch at(s) {
        case 0: return [.drag(from: CGPoint(x: Pl.home.x + 3, y: Pl.home.y), to: CGPoint(x: Pl.lying.x + 3, y: Pl.lying.y))]
        case 1: return [.drag(from: CGPoint(x: Pl.lying.x + 3, y: Pl.lying.y), to: CGPoint(x: Pl.sx, y: Q.foot - Q.L / 2))]
        case 2:
            return [.tap(.picture(P.longer == 0 ? CGPoint(x: 2.5, y: 2.5) : CGPoint(x: Pl.bx + 1.5, y: Q.foot - 2.5)))]
        default: return []
        }
    }
}
