import SwiftUI

/// Heavier and lighter on the paper, as in the preview (design/prototype/gradeK-ch3.html, lHeavier): a pan balance in
/// blocks (a post 3 blocks tall, a beam 9 blocks long on it, a pan 4 blocks wide hanging from each end) and under it the
/// two things, each as long as it is (one block one cube of length). Slide each onto a pan (it snaps in; "1 of 2 on");
/// with both on, the beam tips on a loose spring, past and back, the heavier side a block down at the ends (the same
/// weight stays level). Tap the heavier (or lighter) one, or Same. Both ways: the balance draws out, the two glide onto a
/// start line, tap the longer one. The record is written by the taps.
///
/// Kept: "pan0", "pan1" the thing on each pan, "tipAt" when both were on, "wrong" a pan tapped and wrong, "wrongSame",
/// "wrongLong". Hand: "grab", "g" the thing held, "dx", "dy", "x", "y" (its place now); "bk", "bx", "by" the thing just
/// let go and where (it goes on from there).
@MainActor
struct HeavierLesson: PaperLesson {
    var liveKeys: Set<String> { ["x", "y", "dx", "dy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let PX = [10.0, 55.0], beam = 5.0, tray = 25.0, line = 10.0, rows = [0.0, 10.0]
    static let same = CGRect(x: 25, y: 23, width: 15, height: 4)

    private func pan(_ s: PaperState, _ j: Int) -> Int? {
        if let t = s.run.kept["pan\(j)"], t >= 0 { return Int(t.rounded()) }
        return at(s) >= 1 ? j : nil
    }
    /// The beam's tilt: 1 the left pan down, −1 the right, 0 level (until both are on).
    private func tilt(_ s: PaperState, _ P: Heavier.Parts) -> Double {
        guard at(s) >= 1, !P.level, let a = pan(s, 0), let b = pan(s, 1) else { return 0 }
        return P.T[a].weight > P.T[b].weight ? 1 : -1
    }
    static func panY(_ j: Int, _ tl: Double) -> Double { 15 + (j == 0 ? 5 : -5) * tl }
    static func home(_ P: Heavier.Parts, _ t: Int) -> (x: Double, y: Double) { (t == 1 ? 65 - 5 * Double(P.T[1].len) : 0, tray) }
    /// Thing t in pan j: its corner.
    static func inPan(_ P: Heavier.Parts, _ t: Int, _ j: Int, _ tl: Double) -> (x: Double, y: Double) { (PX[j] - 2.5 * Double(P.T[t].len), panY(j, tl) - 4) }

    /// The balance at a tilt: the post on its foot, the beam on it, a pan hanging from each end by two strings.
    private func balance(_ pen: inout GridPen, _ tl: Double) {
        pen.sketch.box("post", pen.R(30, Self.beam, 5, 15), .ink, width: Sketch.stroke)
        pen.line("foot", [(25, Self.beam + 15), (40, Self.beam + 15)])
        pen.line("beam", [(Self.PX[0], Self.beam + 5 * tl), (Self.PX[1], Self.beam - 5 * tl)])
        pen.dot("piv", at: 32.5, Self.beam, radius: 0.6, .ink)
        for j in 0..<2 {
            let ey = Self.beam + (j == 0 ? 5 : -5) * tl, py = Self.panY(j, tl), x = Self.PX[j]
            pen.line("s\(j)a", [(x, ey), (x - 10, py - 1)], .ink2)
            pen.line("s\(j)b", [(x, ey), (x + 10, py - 1)], .ink2)
            pen.line("pan\(j)", [(x - 10, py - 1), (x - 10, py), (x + 10, py), (x + 10, py - 1)])
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Heavier.Parts(s.numbers), st = at(s), T = P.T
        var pic = GridPen(), live = GridPen(stableIds: true)
        let held = st == 0 && s.grabbed ? Int(s.h("g") ?? -1) : -1, bk = Int(s.h("bk") ?? -1)
        let pans = [pan(s, 0), pan(s, 1)], tl = tilt(s, P), tipAt = s.run.kept["tipAt"] ?? PaperClock.now
        let longStep = st == 2 || (st == 3 && P.both)
        if !longStep {
            // the balance: once both are on, it tips on a loose spring from level (each part swings from where it was)
            pic.sketch.swings = st >= 1; pic.sketch.morphs = st >= 1
            KM.seeded(&pic, was: st >= 1 ? { p in balance(&p, 0) } : nil) { p in balance(&p, tl) }
            for j in 0..<2 {
                guard let t = pans[j], t != held else { continue }
                let c = Self.inPan(P, t, j, tl), wrong = st == 1 && s.run.kept["wrong"] == Double(j)
                let level = Self.inPan(P, t, j, 0)
                let was: ((inout GridPen) -> Void)? = bk == t && st == 0 ? { p in KM.thing(&p, "th\(t)", x: (s.h("bx") ?? c.x), y: (s.h("by") ?? c.y), T[t].len, wrong: wrong) }
                    : st >= 1 ? { p in KM.thing(&p, "th\(t)", x: level.x, y: level.y, T[t].len, wrong: wrong) } : nil
                KM.seeded(&pic, was: was) { p in KM.thing(&p, "th\(t)", x: c.x, y: c.y, T[t].len, wrong: wrong) }
            }
            pic.sketch.swings = false; pic.sketch.morphs = false
            // the names in the pans: written once the beam has settled
            for j in 0..<2 {
                guard let t = pans[j], t != held else { continue }
                let c = Self.inPan(P, t, j, tl)
                if st >= 1 && tl != 0 { pic.sketch.startAt = max(PaperClock.now, tipAt + 1.2) }
                pic.word("pn\(t)\(Int(tl))", T[t].name, at: Self.PX[j], c.y + 0.25, KM.name)
                pic.sketch.startAt = nil
            }
        }
        // what's still in the tray, or held
        if st == 0 {
            for t in 0..<2 where !pans.contains(t) {
                if t == held {
                    let x = s.h("x") ?? 0, y = s.h("y") ?? 0
                    KM.thing(&live, "th\(t)", x: x, y: y, T[t].len)
                    KM.nameAbove(&live, "nt\(t)", T[t].name, x: x, y: y)
                    live.reads("\(pans.compactMap { $0 }.count) of 2 on")
                    continue
                }
                let h = Self.home(P, t)
                let was: ((inout GridPen) -> Void)? = bk == t ? { p in KM.thing(&p, "th\(t)", x: s.h("bx") ?? h.x, y: s.h("by") ?? h.y, T[t].len) } : nil
                KM.seeded(&pic, was: was) { p in KM.thing(&p, "th\(t)", x: h.x, y: h.y, T[t].len) }
                KM.nameAbove(&pic, "nt\(t)", T[t].name, x: h.x, y: h.y)
            }
            // a hint: the pans; a second miss, where a thing goes in the empty pan, dashed
            if s.on("ring") && !s.on("spot") { for j in 0..<2 { KK.hintBox(&pic, "hr\(j)", x: Self.PX[j] - 10, y: 10, w: 20, h: 6) } }
            if s.on("spot"), let j = (0..<2).first(where: { pans[$0] == nil }), let t = (0..<2).first(where: { !pans.contains($0) }) {
                let c = Self.inPan(P, t, j, 0)
                pic.sketch.box("spot", pic.R(c.x, c.y + 1, 5 * Double(T[t].len), 3), .chapter, width: Sketch.stroke, dashed: true)
            }
        }
        if st == 1 {
            KS.blocks(&pic, "same", ["Same"], [Self.same], wrong: s.run.kept["wrongSame"] == 1 ? 0 : nil, spot: s.on("spot") && P.want == 2 ? 0 : nil)
            // a hint: the beam's middle (which way it went); a second miss, the one to tap
            if s.on("ring") && !s.on("spot") { KK.hint(&pic, "hr", 32.5, Self.beam, radius: 3) }
            if s.on("spot"), P.want < 2, let j = pans.firstIndex(of: P.want) {
                let c = Self.inPan(P, P.want, j, tl)
                KK.hintBox(&pic, "spot", x: c.x, y: c.y + 1, w: 5 * Double(T[P.want].len), h: 3)
            }
        }
        if longStep {
            // the balance has drawn out; the two lie on a start line, the left pan's on top
            pic.line("start", [(Self.line, Self.rows[0]), (Self.line, Self.rows[1] + 5)])
            for j in 0..<2 {
                let t = pans[j] ?? j, wrong = st == 2 && s.run.kept["wrongLong"] == Double(j)
                KM.thing(&pic, "th\(t)", x: Self.line, y: Self.rows[j], T[t].len, wrong: wrong)
                pic.sketch.startAt = PaperClock.now + 0.6
                KM.nameAbove(&pic, "nl\(t)", T[t].name, x: Self.line, y: Self.rows[j])
                pic.sketch.startAt = nil
            }
            KS.line(&pic, "rh", [.w(P.heavyLine)], x: 0, line: 19)
            if st == 3 { KS.line(&pic, "rl", [.w(P.longLine)], x: 0, line: 22) }
            if st == 2 {
                let lj = pans.firstIndex(of: P.longer) ?? 0, sj = 1 - lj, lo = Double(T[pans[sj] ?? sj].len), hi = Double(T[P.longer].len)
                if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: Self.line + 5 * lo - 1, y: Self.rows[0], w: 5 * (hi - lo) + 2, h: 15) }
                if s.on("spot") { KK.hintBox(&pic, "spot", x: Self.line, y: Self.rows[lj], w: 5 * hi, h: 5) }
            }
        } else if st == 3 {
            KS.line(&pic, "rh", [.w(P.heavyLine)], x: 0, line: 24)
        }
        let room: CGRect = longStep ? pic.R(0, -1, 50, 15) : pic.R(0, -1, 65, st == 0 ? 31 : 21)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, extent: room)
    }

    private func panRect(_ P: Heavier.Parts, _ t: Int, _ j: Int, _ tl: Double) -> CGRect {
        let c = Self.inPan(P, t, j, tl)
        return CGRect(x: c.x - 1, y: c.y - 1, width: 5 * Double(P.T[t].len) + 2, height: 6)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Heavier.Parts(s.numbers), T = P.T, pans = [pan(s, 0), pan(s, 1)]
        switch at(s) {
        case 0:
            return Hands(
                grab: { q in
                    for t in 0..<2 where !pans.contains(t) {
                        let h = Self.home(P, t)
                        guard q.x >= h.x - 1, q.x <= h.x + 5 * Double(T[t].len) + 1, q.y >= h.y - 1, q.y <= h.y + 6 else { continue }
                        return ["grab": 1, "g": Double(t), "dx": q.x - h.x, "dy": q.y - h.y, "x": h.x, "y": h.y]
                    }
                    return nil
                },
                drag: { q, h in
                    var h = h
                    h["x"] = (q.x - (h["dx"] ?? 0)).rounded(); h["y"] = (q.y - (h["dy"] ?? 0)).rounded()
                    return h
                },
                release: { h in
                    let t = Int(h["g"] ?? 0), x = h["x"] ?? 0, y = h["y"] ?? 0, home = Self.home(P, t)
                    let cx = x + 2.5 * Double(T[t].len), cy = y + 2.5, back: Numbers = ["bk": Double(t), "bx": x, "by": y]
                    guard let j = (0..<2).first(where: { abs(cx - Self.PX[$0]) <= 12 && cy >= Self.panY($0, 0) - 13 && cy <= Self.panY($0, 0) + 5 }) else {
                        // let go off the pans: back to the tray (a miss only when it was really moved)
                        if abs(x - home.x) + abs(y - home.y) <= 1 { return HandMove(hand: [:]) }
                        return HandMove(hand: back, missHand: back, set: [("p", -1)], check: true)
                    }
                    if pans[j] != nil { return HandMove(hand: back, missHand: back, set: [("p", -2)], check: true) }
                    if pans[1 - j] != nil { return HandMove(hand: [:], missHand: [:], set: [("p", 1)], keep: ["pan\(j)": Double(t), "tipAt": PaperClock.now], check: true) }
                    return HandMove(hand: back, missHand: back, keep: ["pan\(j)": Double(t)])
                })
        case 1:
            let tl = tilt(s, P)
            return Hands(tap: { q in
                if Self.same.contains(q) { return HandMove(hand: nil, missHand: nil, set: [("c", 2)], keep: ["wrongSame": P.want == 2 ? 0 : 1, "wrong": -1], check: true) }
                for j in 0..<2 {
                    guard let t = pans[j], panRect(P, t, j, tl).contains(q) else { continue }
                    return HandMove(hand: nil, missHand: nil, set: [("c", Double(t))], keep: ["wrong": t == P.want ? -1 : Double(j), "wrongSame": 0], check: true)
                }
                return nil
            })
        case 2:
            return Hands(tap: { q in
                for j in 0..<2 {
                    let t = pans[j] ?? j
                    guard CGRect(x: Self.line - 1, y: Self.rows[j], width: 5 * Double(T[t].len) + 2, height: 5).contains(q) else { continue }
                    return HandMove(hand: nil, missHand: nil, set: [("g", Double(t))], keep: ["wrongLong": t == P.longer ? -1 : Double(j)], check: true)
                }
                return nil
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Heavier.Parts(s.numbers), T = P.T, pans = [pan(s, 0), pan(s, 1)]
        switch at(s) {
        case 0:
            var free = (0..<2).filter { pans[$0] == nil }, moves: [GhostMove] = []
            for t in 0..<2 where !pans.contains(t) {
                guard !free.isEmpty else { break }
                let j = free.contains(t) ? t : free[0]
                free.removeAll { $0 == j }
                let h = Self.home(P, t), from = CGPoint(x: h.x + 2.5 * Double(T[t].len), y: h.y + 2.5)
                moves.append(.drag(from: from, to: CGPoint(x: Self.PX[j], y: Self.panY(j, 0) - 1.5)))
            }
            return moves
        case 1:
            if P.want == 2 { return [.tap(.picture(CGPoint(x: Self.same.midX, y: Self.same.midY)))] }
            guard let j = pans.firstIndex(of: P.want) else { return [] }
            let r = panRect(P, P.want, j, tilt(s, P))
            return [.tap(.picture(CGPoint(x: r.midX, y: r.midY + 0.5)))]
        case 2:
            let j = pans.firstIndex(of: P.longer) ?? 0
            return [.tap(.picture(CGPoint(x: Self.line + 2.5, y: Self.rows[j] + 2.5)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Heavier.Parts(s.numbers), pans = [pan(s, 0), pan(s, 1)]
        switch at(s) {
        case 0:
            let t: Int = (0..<2).first(where: { !pans.contains($0) }) ?? 0, back: Numbers = ["bk": Double(t), "bx": 27, "by": 18]
            return HandMove(hand: back, missHand: back, set: [("p", -1)], check: true)
        case 1:
            if P.want == 2 { return HandMove(hand: nil, missHand: nil, set: [("c", 0)], keep: ["wrong": Double(pans.firstIndex(of: 0) ?? 0)], check: true) }
            let t = 1 - P.want
            return HandMove(hand: nil, missHand: nil, set: [("c", Double(t))], keep: ["wrong": Double(pans.firstIndex(of: t) ?? t)], check: true)
        case 2:
            let t = 1 - P.longer
            return HandMove(hand: nil, missHand: nil, set: [("g", Double(t))], keep: ["wrongLong": Double(pans.firstIndex(of: t) ?? t)], check: true)
        default: return nil
        }
    }
}
