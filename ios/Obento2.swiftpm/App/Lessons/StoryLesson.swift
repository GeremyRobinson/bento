import SwiftUI

/// Story problems within 10 on the paper, as in the preview (design/prototype/gradeK-ch4.html, lStory): one block is one
/// thing in the story, a counter on the ten track. The story's first two sentences are the instruction (the counters go
/// on one after another as they're read, named a), with "More than 5" and "Fewer than 5" under the track. Then the
/// second sentence stays while the hand acts it out: going away, each tap on the counters takes the last one off into
/// the strip, crossed out, and the count left is written at their end; coming (or the second person's), the striped
/// ones wait above at the right and slide on right after the first, then count on by themselves, numbered. Then the
/// question, written on the number row.
///
/// Departure: the preview reads the first sentence alone while the counters go on, then the second; here both are the
/// first instruction (spoken together), as nothing waits for the child between them.
///
/// Kept: "wrongPick", "n" and "t<k>" (taken, as Taking away), "lx", "ly", "lt" (slid, as Adding).
@MainActor
struct StoryLesson: PaperLesson {
    var liveKeys: Set<String> { ["x", "y"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// Going away: the track on top, the strip (and the blocks) 2 blocks under it. Coming: the striped ones on top, the
    /// track 2 blocks under them (risen to the top once they're on: no hops here, so no room is kept over it), the blocks
    /// 2 blocks under that.
    struct Place {
        let P: StoryK.Parts
        var track0: Double { P.take ? 0 : 10 }
        func track(_ st: Int) -> Double { P.take || st < 2 ? track0 : 0 }
        var blocks: Double { track0 + 10 }
        var record: Double { P.take ? 18 : 8 }
        var keys: Double { record + 5 }
        var slide: KSlide { KSlide(a: P.a, b: P.b, track: 10) }
        func choice(_ j: Int) -> CGRect { CGRect(x: Double(j) * 20, y: blocks, width: 15, height: 4) }
    }
    func recordRow(_ n: Numbers) -> Double? { Place(P: StoryK.Parts(n)).record }
    static let strip = 10.0

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = StoryK.Parts(s.numbers), Pl = Place(P: P), st = at(s), a = P.a, b = P.b, now = PaperClock.now
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let ty = Pl.track(st)
        KK.track(&pic, "trk", x: 0, y: ty)
        let taken = P.take ? (st == 0 ? 0 : st == 1 ? Int(s.run.kept["n"] ?? 0) : b) : 0, on = a - taken
        // the start: a counters, put on one after another as the story is read
        for j in 0..<on {
            pic.sketch.startAt = st == 0 ? now + 0.4 + 0.22 * Double(j) : nil
            KA.dot(&pic, "d\(j)", Double(j) * 5 + 2.5, ty + 2.5)
        }
        pic.sketch.startAt = st == 0 ? now + 0.5 + 0.22 * Double(a) : nil
        if P.take { pic.label("an", "\(on)", KK.maths, .right, edge: Double(on) * 5, along: ty + 2.5) }
        else if st == 0 { pic.label("an", "\(a)", KK.maths, .right, edge: Double(a) * 5, along: ty + 2.5) }
        pic.sketch.startAt = nil

        if P.take {
            // going away: each taken one dropped from its own block into the strip, crossed out once it lands
            if st == 1 { KA.strip(&pic, "st", y: Self.strip, on) }
            for k in 0..<taken {
                let j = a - 1 - k, cx = Double(j) * 5 + 2.5, went = s.run.kept["t\(k)"] ?? 0
                KM.seeded(&pic, was: { p in KA.dot(&p, "t\(k)", cx, 2.5) }) { p in KA.dot(&p, "t\(k)", cx, Self.strip + 2.5) }
                pic.sketch.startAt = max(now, went + 0.45)
                pic.line("t\(k)x", [(cx - 1.6, Self.strip + 4.1), (cx + 1.6, Self.strip + 0.9)])
                pic.sketch.startAt = nil
            }
        } else {
            // coming: waiting above at the right, in the hand, sliding home, or on (numbered as the count runs on)
            let slide = Pl.slide, h = slide.home
            if st <= 1 && s.grabbed {
                let p = slide.at(s)
                for k in 0..<b { KA.dot(&live, "b\(k)", p.x + Double(k) * 5 + 2.5, p.y + 2.5, striped: true) }
                live.label("bn", "\(b)", KK.maths, .right, edge: p.x + Double(b) * 5, along: p.y + 2.5)
                if let r = slide.readout(p) { live.reads(r) }
            } else if st <= 1 {
                pic.sketch.startAt = st == 0 ? now + 0.8 + 0.22 * Double(a) : nil
                let from = st == 1 ? slide.letGo(s) : nil
                KM.seeded(&pic, was: from.map { f in { p in for k in 0..<b { KA.dot(&p, "b\(k)", f.x + Double(k) * 5 + 2.5, f.y + 2.5, striped: true) } } }) { p in
                    for k in 0..<b { KA.dot(&p, "b\(k)", h.x + Double(k) * 5 + 2.5, h.y + 2.5, striped: true) }
                }
                pic.label("bn", "\(b)", KK.maths, .right, edge: h.x + Double(b) * 5, along: h.y + 2.5)
                pic.sketch.startAt = nil
            } else {
                let from = st == 2 ? slide.letGo(s) : nil, went = s.run.kept["lt"] ?? now
                KM.seeded(&pic, was: from.map { f in { p in for k in 0..<b { KA.dot(&p, "b\(k)", f.x + Double(k) * 5 + 2.5, f.y + 2.5, striped: true) } } }) { p in
                    for k in 0..<b { KA.dot(&p, "b\(k)", Double(a + k) * 5 + 2.5, ty + 2.5, striped: true) }
                }
                // the count runs on by itself, a number on each one that came
                for k in 0..<b {
                    pic.sketch.startAt = max(now, went + 0.9 + 0.42 * Double(k))
                    pic.word("bc\(k)", "\(a + k + 1)", at: Double(a + k) * 5 + 2.5, ty + 2.5, KK.count)
                }
                pic.sketch.startAt = nil
            }
        }

        switch st {
        case 0:
            let wrong = KA.kept(s, "wrongPick")
            pic.sketch.startAt = now + 0.9 + 0.22 * Double(a)
            KS.blocks(&pic, "pk", P.choices, [Pl.choice(0), Pl.choice(1)], wrong: wrong, spot: s.on("spot") ? P.want : nil, ring: s.on("ring") && !s.on("spot"))
            pic.sketch.startAt = nil
        case 1:
            if P.take {
                if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: 0, w: 5 * Double(on), h: 5) }
                if s.on("spot"), on > 0 { KK.hint(&pic, "spot", Double(on - 1) * 5 + 2.5, 2.5) }
            } else {
                let h = Pl.slide.home
                if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: h.x, y: h.y, w: 5 * Double(b) + 3, h: 5) }
                if s.on("spot") { pic.sketch.box("spot", pic.R(Double(a) * 5, 10, Double(b) * 5, 5), .chapter, width: Sketch.stroke, dashed: true) }
            }
        case 2:
            let (v, wrong) = KK.typed(s, "x", want: P.end)
            KA.line(&rec, "rec", [.n(a), .op(P.sign), .n(b), .op("=")], value: v, wrong: wrong)
            KK.numberRow(&pic, "nr", y: Pl.keys, wrong: wrong ? v : nil, spot: s.on("spot") ? P.end : nil)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: ty, w: max(5, 5 * Double(P.take ? on : P.end)), h: 5) }
        default:
            M7.row(&rec, "rec", [.n(a), .op(P.sign), .n(b), .op("="), .n(P.end, .chapter)], x: 0, line: 1)
        }
        let room = st <= 1 ? pic.R(0, 0, 53, (P.take ? Self.strip : 10) + 5) : nil
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: room)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = StoryK.Parts(s.numbers), Pl = Place(P: P), a = P.a, b = P.b
        switch at(s) {
        case 0:
            return Hands(tap: { q in
                guard let j = KS.hit(q, [Pl.choice(0), Pl.choice(1)]) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("c", Double(j))], keep: ["wrongPick": j == P.want ? -1 : Double(j)], check: true)
            })
        case 1:
            if !P.take { return Pl.slide.hands(s, box: "l") }
            let taken = Int(s.run.kept["n"] ?? 0), on = a - taken
            return Hands(tap: { q in
                if q.y >= 0, q.y <= 5, q.x >= 0, q.x <= Double(on) * 5, on > 0 {
                    let n = taken + 1
                    return HandMove(hand: nil, missHand: nil, set: n >= b ? [("t", Double(n))] : [], keep: ["n": Double(n), "t\(taken)": PaperClock.now], check: n >= b)
                }
                if q.y >= Self.strip, q.y <= Self.strip + 5, q.x >= Double(on) * 5, q.x <= Double(a) * 5, taken > 0 {
                    return HandMove(hand: nil, missHand: nil, keep: ["n": Double(taken - 1), "t\(taken - 1)": -1])
                }
                return nil
            })
        case 2:
            return Hands(tap: { q in KK.tapped(q, y: Pl.keys).map { HandMove(hand: nil, missHand: nil, set: [("x", Double($0))], check: true) } })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = StoryK.Parts(s.numbers), Pl = Place(P: P)
        switch at(s) {
        case 0: let r = Pl.choice(P.want); return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
        case 1:
            if !P.take { return [Pl.slide.demo] }
            let taken = Int(s.run.kept["n"] ?? 0)
            return (taken..<P.b).map { k in .tap(.picture(CGPoint(x: Double(P.a - 1 - k) * 5 + 2.5, y: 2.5))) }
        case 2: return [.tap(.picture(KK.keySpot(P.end, y: Pl.keys)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = StoryK.Parts(s.numbers)
        switch at(s) {
        case 0: return HandMove(hand: nil, missHand: nil, set: [("c", Double(1 - P.want))], keep: ["wrongPick": Double(1 - P.want)], check: true)
        case 1: return P.take ? nil : Place(P: P).slide.wrong
        case 2: return HandMove(hand: nil, missHand: nil, set: [("x", Double(P.b == P.end ? P.a : P.b))], check: true)
        default: return nil
        }
    }
}
