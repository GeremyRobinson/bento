import SwiftUI

/// Longer and shorter on the paper, as in the preview (design/prototype/gradeK-ch3.html, lLength): two things on two
/// block rows (one block one cube of length), a start line two blocks in from the picture's left edge through both. The
/// top one touches it; slide the bottom one's end onto it (block by block; the line darkens when it's there; let go off
/// it and it waits there), tap the longer one or Same; then the See draws in: a dashed line drops from the shorter one's
/// end, what sticks out is ringed and its cubes count 1, 2, 3, each thing's length goes at its end; write how many stick
/// out on the number row (its keys from the start line). Taller (from index 6, every third): two things stand on a floor,
/// the raised one slides down onto it; the record and the number row stand at their right.
///
/// Kept: "off" where the mover was let go (blocks off the line), "wrong" a thing tapped and wrong, "wrongSame", "seeAt".
/// Hand: "grab", "gx", "gy", "g0", "o" (its offset now).
@MainActor
struct LengthLesson: PaperLesson {
    var liveKeys: Set<String> { ["o", "gx", "gy", "g0"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let line = 10.0, rows = [0.0, 10.0], cols = [5.0, 15.0], rx = 30.0

    /// Where everything goes for a problem.
    struct Place {
        let P: LengthK.Parts
        /// Standing: the floor's row.
        var floor: Double { Double(P.height) * 5 }
        /// The record's top row and the number row's.
        var recordY: Double { P.tall ? max(1, floor - 11) : 18 }
        var keysY: Double { recordY + 5 }
        var keysX: Double { P.tall ? LengthLesson.rx : LengthLesson.line }
        var keys: ClosedRange<Int> { 1...(P.tall ? 7 : 10) }
        var recordX: Double { P.tall ? LengthLesson.rx : 0 }
        /// Thing j's start (lying: its left end's column; standing: its foot's row), `off` blocks out of line.
        func from(_ j: Int, _ off: Int) -> Double { P.tall ? floor - 5 * Double(off) : LengthLesson.line + 5 * Double(off) }
        func to(_ j: Int, _ off: Int) -> Double { P.tall ? from(j, off) - 5 * Double(P.len[j]) : from(j, off) + 5 * Double(P.len[j]) }
        /// The most the mover goes out of line, each way.
        var range: ClosedRange<Int> { P.tall ? 0...max(0, P.height - P.len[P.mover]) : -2...max(-2, 11 - P.len[P.mover]) }
    }

    /// The mover's offset now: held, let go, or lined up once that's done.
    private func off(_ s: PaperState, _ P: LengthK.Parts, _ j: Int, live: Bool) -> Int {
        guard j == P.mover, at(s) == 0 else { return 0 }
        if live, let o = s.h("o") { return Int(o.rounded()) }
        return Int((s.run.kept["off"] ?? Double(P.shift)).rounded())
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = LengthK.Parts(s.numbers), Pl = Place(P: P), st = at(s), held = st == 0 && s.grabbed
        var pic = GridPen(), live = GridPen(stableIds: true)
        let m = P.mover, oNow = off(s, P, m, live: true), on = oNow == 0
        // the start line (the floor): darker once the moving one's end is on it (live while it's held)
        func startLine(_ pen: inout GridPen, _ id: String, _ c: Sketch.Colour) {
            if P.tall { pen.line(id, [(0, Pl.floor), (25, Pl.floor)], c) } else { pen.line(id, [(Self.line, Self.rows[0]), (Self.line, Self.rows[1] + 5)], c) }
        }
        let still = off(s, P, m, live: false)
        startLine(&pic, "start\(st > 0 || still == 0)", st > 0 || still == 0 ? .ink : .ink3)
        if held && on { startLine(&live, "startL", .ink) }
        let wrongThing = st == 1 ? s.run.kept["wrong"].map { Int($0.rounded()) }.flatMap { $0 >= 0 ? $0 : nil } : nil
        for j in 0..<2 {
            let isLive = held && j == m, o = off(s, P, j, live: isLive), f = Pl.from(j, o)
            if isLive {
                if P.tall { KM.thing(&live, "t\(j)", x: Self.cols[j], y: f, P.len[j], stand: true) }
                else { KM.thing(&live, "t\(j)", x: f, y: Self.rows[j], P.len[j]); KM.nameAbove(&live, "nm\(j)", P.names[j], x: f, y: Self.rows[j]) }
                live.reads(o == 0 ? (P.tall ? "On the floor" : "On the line") : o > 0 ? "\(o) to go" : "\(-o) past")
                continue
            }
            // the mover, let go: shown at once where the finger left it (never drawn in again under it)
            let build: (inout GridPen) -> Void = { p in
                if P.tall { KM.thing(&p, "t\(j)", x: Self.cols[j], y: f, P.len[j], stand: true, wrong: wrongThing == j) }
                else { KM.thing(&p, "t\(j)", x: f, y: Self.rows[j], P.len[j], wrong: wrongThing == j) }
            }
            KM.seeded(&pic, was: j == m ? build : nil, build)
            if !P.tall { KM.nameAbove(&pic, "nm\(j)", P.names[j], x: f, y: Self.rows[j]) }
        }
        if P.tall { for j in 0..<2 { pic.word("nm\(j)", P.names[j], at: Self.cols[j] + 2.5, Pl.floor + 1.2, KM.name) } }

        // the See (from the write step on, or the same's last step): drawn in from when the longer one was tapped
        let seeAt = s.run.kept["seeAt"] ?? PaperClock.now
        if st >= 2 {
            let lo = Double(P.lo), d = Double(P.extra), lj = P.longer
            pic.sketch.startAt = seeAt + 0.2
            if P.tall { pic.line("dash", [(0, Pl.floor - 5 * lo), (25, Pl.floor - 5 * lo)], .ink2, dashed: true) }
            else { pic.line("dash", [(Self.line + 5 * lo, Self.rows[0]), (Self.line + 5 * lo, Self.rows[1] + 5)], .ink2, dashed: true) }
            if !P.same {
                pic.sketch.startAt = seeAt + 0.6
                if P.tall {
                    let x = Self.cols[lj] + 0.5, y = Pl.floor - 5 * Double(P.hi) + 0.5
                    KM.capsule(&pic, "so", x: x, y: y, w: 4, h: 5 * d - 1)
                } else { KK.stadium(&pic, "so", x: Self.line + 5 * lo + 0.5, y: Self.rows[lj] + 0.5, w: 5 * d - 1, h: 4) }
                for j in 1...P.extra {
                    pic.sketch.startAt = seeAt + 0.9 + 0.45 * Double(j - 1)
                    if P.tall { pic.word("sn\(j)", "\(j)", at: Self.cols[lj] + 2.5, Pl.floor - 5 * lo - 5 * Double(j - 1) - 2.5, KK.count.colour(.chapter)) }
                    else { pic.word("sn\(j)", "\(j)", at: Self.line + 5 * lo + 5 * Double(j - 1) + 2.5, Self.rows[lj] + 2.5, KK.count.colour(.chapter)) }
                }
            }
            pic.sketch.startAt = seeAt + (P.same ? 0.7 : 0.9 + 0.45 * d)
            for j in 0..<2 {
                if P.tall { pic.label("len\(j)", "\(P.len[j])", KK.maths, j == 0 ? .left : .right, edge: j == 0 ? Self.cols[0] + 1 : Self.cols[1] + 4, along: Pl.to(j, 0) + 2.5) }
                else { pic.label("len\(j)", "\(P.len[j])", KK.maths, .right, edge: Pl.to(j, 0), along: Self.rows[j] + 2.5) }
            }
            pic.sketch.startAt = nil
        }

        switch st {
        case 0:
            // a hint: the thing to slide ringed; a second miss, where it goes, dashed
            if s.on("ring") {
                if P.tall { KK.hintBox(&pic, "hr", x: Self.cols[m] + 1, y: Pl.to(m, still), w: 3, h: 5 * Double(P.len[m])) }
                else { KK.hintBox(&pic, "hr", x: Pl.from(m, still), y: Self.rows[m] - 0.5, w: 5 * Double(P.len[m]), h: 4.5) }
            }
            if s.on("spot") {
                if P.tall { pic.sketch.box("spot", pic.R(Self.cols[m] + 1, Pl.to(m, 0), 3, 5 * Double(P.len[m])), .chapter, width: Sketch.stroke, dashed: true) }
                else { pic.sketch.box("spot", pic.R(Self.line, Self.rows[m] + 1, 5 * Double(P.len[m]), 3), .chapter, width: Sketch.stroke, dashed: true) }
            }
        case 1:
            let r = sameRect(Pl)
            KS.blocks(&pic, "same", ["Same"], [r], wrong: s.run.kept["wrongSame"] == 1 ? 0 : nil, spot: s.on("spot") && P.same ? 0 : nil)
            // a hint: the things' ends; a second miss, the one to tap
            if s.on("ring") && !s.on("spot") {
                if P.tall { KK.hintBox(&pic, "hr", x: Self.cols[0], y: Pl.to(P.longer, 0) - 1, w: 15, h: 5 * Double(P.extra) + 2) }
                else { KK.hintBox(&pic, "hr", x: Self.line + 5 * Double(P.lo) - 1, y: Self.rows[0], w: 5 * Double(P.extra) + 2, h: 15) }
            }
            if s.on("spot") && !P.same {
                let j = P.longer
                if P.tall { KK.hintBox(&pic, "spot", x: Self.cols[j], y: Pl.to(j, 0), w: 5, h: 5 * Double(P.len[j])) }
                else { KK.hintBox(&pic, "spot", x: Self.line, y: Self.rows[j], w: 5 * Double(P.len[j]), h: 5) }
            }
        case 2:
            let (v, wrong) = KK.typed(s, "x", want: P.extra)
            KM.boxLine(&pic, "rec", pre: P.recordWords, value: v, wrong: wrong, post: P.unit, x: Pl.recordX, line: Pl.recordY + 1)
            KK.numberRow(&pic, "nr", y: Pl.keysY, x0: Pl.keysX, wrong: wrong ? v : nil, spot: s.on("spot") ? P.extra : nil, keys: Pl.keys)
            if s.on("ring") && !s.on("spot") {
                if P.tall { KK.hintBox(&pic, "hr", x: Self.cols[P.longer], y: Pl.floor - 5 * Double(P.hi), w: 5, h: 5 * Double(P.extra)) }
                else { KK.hintBox(&pic, "hr", x: Self.line + 5 * Double(P.lo), y: Self.rows[P.longer], w: 5 * Double(P.extra), h: 5) }
            }
        default:
            let toks: [M7.Tok] = P.same ? [.w(P.recordWords)] : [.w(P.recordWords), .n(P.extra, .chapter), .w(P.unit)]
            KS.line(&pic, "rec", toks, x: Pl.recordX, line: Pl.recordY + 1)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, extent: room(s, P, Pl, pic))
    }

    private func sameRect(_ Pl: Place) -> CGRect { CGRect(x: Pl.keysX, y: Pl.P.tall ? Pl.keysY : Pl.recordY, width: 10, height: 4) }

    /// The room the camera frames: what's drawn, with the slide's reach (so it holds still while the thing moves).
    private func room(_ s: PaperState, _ P: LengthK.Parts, _ Pl: Place, _ pic: GridPen) -> CGRect {
        var r = CGRect(x: 0, y: 0, width: 1, height: 1)
        if P.tall {
            r = CGRect(x: 0, y: 0, width: 25, height: Pl.floor + 2.5)
        } else {
            let reach = Self.line + 5 * Double(max(P.a, P.b + max(0, P.shift))), left = Self.line + 5 * Double(min(0, P.shift))
            r = CGRect(x: min(0, left), y: -1, width: reach + 3 - min(0, left), height: 15)
        }
        return pic.R(r.minX, r.minY, r.width, r.height)
    }

    /// Done on a standing problem: Next problem under the record, at the right.
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = LengthK.Parts(s.numbers), Pl = Place(P: P)
        return at(s) == 3 && P.tall ? CGPoint(x: Pl.recordX, y: Pl.recordY + 5) : nil
    }

    /// Thing j's box on the paper (for taps), lined up.
    private func thingRect(_ Pl: Place, _ j: Int) -> CGRect {
        let P = Pl.P
        if P.tall { return CGRect(x: Self.cols[j], y: Pl.to(j, 0) - 1, width: 5, height: 5 * Double(P.len[j]) + 1) }
        return CGRect(x: Self.line - 1, y: Self.rows[j], width: 5 * Double(P.len[j]) + 2, height: 5)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = LengthK.Parts(s.numbers), Pl = Place(P: P), m = P.mover
        switch at(s) {
        case 0:
            let o0 = off(s, P, m, live: false), f = Pl.from(m, o0), e = Pl.to(m, o0)
            return Hands(
                grab: { q in
                    let ok = P.tall ? q.x >= Self.cols[m] - 1 && q.x <= Self.cols[m] + 6 && q.y >= e - 2 && q.y <= f + 2
                        : q.y >= Self.rows[m] - 1 && q.y <= Self.rows[m] + 6 && q.x >= f - 2 && q.x <= e + 2
                    return ok ? ["grab": 1, "gx": q.x, "gy": q.y, "g0": Double(o0), "o": Double(o0)] : nil
                },
                drag: { q, h in
                    var h = h
                    let g0 = h["g0"] ?? 0, d = P.tall ? -(q.y - (h["gy"] ?? q.y)) / 5 : (q.x - (h["gx"] ?? q.x)) / 5
                    h["o"] = Double(max(Pl.range.lowerBound, min(Pl.range.upperBound, Int((g0 + d).rounded()))))
                    return h
                },
                release: { h in
                    let o = h["o"] ?? 0
                    // not moved: nothing (a tap)
                    if o == h["g0"] { return HandMove(hand: [:]) }
                    return HandMove(hand: [:], missHand: [:], set: [("l", o)], keep: ["off": o], check: true)
                })
        case 1:
            let r = sameRect(Pl)
            return Hands(tap: { q in
                if r.contains(q) { return HandMove(hand: nil, missHand: nil, set: [("c", 2)], keep: P.same ? ["seeAt": PaperClock.now, "wrongSame": 0, "wrong": -1] : ["wrongSame": 1, "wrong": -1], check: true) }
                guard let j = (0..<2).first(where: { thingRect(Pl, $0).contains(q) }) else { return nil }
                let right = j == P.right
                return HandMove(hand: nil, missHand: nil, set: [("c", Double(j))], keep: right ? ["seeAt": PaperClock.now, "wrong": -1, "wrongSame": 0] : ["wrong": Double(j), "wrongSame": 0], check: true)
            })
        case 2:
            return Hands(tap: { q in KK.tapped(q, y: Pl.keysY, x0: Pl.keysX, keys: Pl.keys).map { HandMove(hand: nil, missHand: nil, set: [("x", Double($0))], check: true) } })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = LengthK.Parts(s.numbers), Pl = Place(P: P), m = P.mover
        switch at(s) {
        case 0:
            let o = off(s, P, m, live: false)
            if P.tall {
                let y = Pl.to(m, o) + 2.5
                return [.drag(from: CGPoint(x: Self.cols[m] + 2.5, y: y), to: CGPoint(x: Self.cols[m] + 2.5, y: y + 5 * Double(o)))]
            }
            let x = Pl.from(m, o) + 2.5
            return [.drag(from: CGPoint(x: x, y: Self.rows[m] + 2.5), to: CGPoint(x: x - 5 * Double(o), y: Self.rows[m] + 2.5))]
        case 1:
            if P.same { let r = sameRect(Pl); return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))] }
            let r = thingRect(Pl, P.longer)
            return [.tap(.picture(CGPoint(x: P.tall ? r.midX : r.minX + 3.5, y: P.tall ? r.maxY - 2.5 : r.midY)))]
        case 2: return [.tap(.picture(KK.keySpot(P.extra, y: Pl.keysY, x0: Pl.keysX)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = LengthK.Parts(s.numbers)
        switch at(s) {
        case 0:
            let o = Double(P.tall ? 1 : (P.shift == 1 ? -1 : 1))
            return HandMove(hand: [:], missHand: [:], set: [("l", o)], keep: ["off": o], check: true)
        case 1:
            if P.same { return HandMove(hand: nil, missHand: nil, set: [("c", 0)], keep: ["wrong": 0], check: true) }
            return HandMove(hand: nil, missHand: nil, set: [("c", Double(P.shorter))], keep: ["wrong": Double(P.shorter)], check: true)
        case 2: return HandMove(hand: nil, missHand: nil, set: [("x", Double(P.hi))], check: true)
        default: return nil
        }
    }
}
