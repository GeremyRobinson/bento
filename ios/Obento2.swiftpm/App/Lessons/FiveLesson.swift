import SwiftUI

/// Facts to 5 on the paper, as in the preview (design/prototype/gradeK-ch4.html, lFive): a hand in blocks, one finger a
/// block wide and a block apart (a palm 9 × 2 blocks; a finger up 4 blocks tall and filled, a finger down folded to one
/// block and outlined; the thumb on the left a block shorter), and the fact as the record from the start, its first
/// number the fingers up. Help fades across the page: the first three tap fingers up (striped) or down (crossed), then
/// write; the next write first and the hand shows it after ("Watch the hand."); later ones are the fact alone, the hand
/// drawn under it only once it's answered. The number row (0–5) is beside the record.
///
/// Departure, so every step shows at 75% or more (it was 69%): the palm is a block tall, not 2.
///
/// Kept: "ch<k>" finger k changed (1), "again" a finger tapped that's wrong.
@MainActor
struct FiveLesson: PaperLesson {
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// Where the hand's top and the record's row go: the hand first, or (the fact alone) the record first.
    struct Place {
        let P: FactsToFive.Parts
        var hand: Double { P.mode == 2 ? 7 : 0 }
        var record: Double { P.mode == 2 ? 1 : 28 }
        var keys: Double { record - 1 }
        static let keysX = 25.0
    }
    static func top(_ k: Int, _ hy: Double) -> Double { hy + (k == 0 ? 5 : 0) }

    private func changed(_ s: PaperState) -> [Int] { (0..<5).filter { (s.run.kept["ch\($0)"] ?? 0) == 1 } }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = FactsToFive.Parts(s.numbers), Pl = Place(P: P), st = at(s), now = PaperClock.now
        var pic = GridPen()
        let tapping = st == 0
        // the fingers changed now: the child's taps, or all of them (the hand shows the fact after it's written)
        let shown = P.mode == 0 ? (st == 0 ? changed(s) : P.moves) : (st == 2 ? P.moves : [])
        let drawHand = !(P.mode == 2 && st < 2)
        let again = tapping ? KA.kept(s, "again") : nil
        if drawHand {
            let hy = Pl.hand
            pic.fill("palmf", col: 0, row: hy + 20, w: 45, h: 5, KK.cube)
            pic.sketch.box("palm", pic.R(0, hy + 20, 45, 5), .chapter, width: Sketch.stroke)
            for k in 0..<5 {
                let x = Double(k) * 10, ch = shown.contains(k), up = (k < P.a) != ch, top = Self.top(k, hy)
                // shown after the write: each change waits its turn, one after another
                let i = P.mode != 0 && st == 2 ? P.moves.firstIndex(of: k) : nil
                let wait = i.map { (P.mode == 2 ? 0.9 : 0.35) + 0.45 * Double($0) } ?? 0
                let rect = up ? pic.R(x, top, 5, hy + 20 - top) : pic.R(x, hy + 20, 5, 0)
                let edge = up ? pic.R(x, top, 5, hy + 20 - top) : pic.R(x, hy + 15, 5, 5)
                // where it was before the change (the morph starts there)
                let wasUp = k < P.a
                let wasRect = wasUp ? pic.R(x, top, 5, hy + 20 - top) : pic.R(x, hy + 20, 5, 0)
                let wasEdge = wasUp ? pic.R(x, top, 5, hy + 20 - top) : pic.R(x, hy + 15, 5, 5)
                pic.sketch.morphs = true; pic.sketch.delay = wait
                if ch, i != nil {
                    var was = GridPen(); was.sketch.fill("f\(k)f", wasRect, KK.cube); was.sketch.box("f\(k)o", wasEdge, .chapter, width: Sketch.stroke)
                    for it in was.sketch.items { pic.sketch.from[it.id] = it.kind }
                }
                pic.sketch.fill("f\(k)f", rect, KK.cube)
                pic.sketch.box("f\(k)o", edge, .chapter, width: Sketch.stroke)
                pic.sketch.from = [:]; pic.sketch.morphs = false; pic.sketch.delay = 0
                // tapped and wrong: outlined red over its own lines
                if again == k { pic.sketch.box("f\(k)red", edge, KK.red, width: Sketch.stroke) }
                // a finger raised is striped (the second amount); one folded is crossed out
                if ch {
                    pic.sketch.startAt = i != nil ? now + wait + 0.45 : nil
                    if up { pic.stripeLines("f\(k)s", col: x, row: top, w: 5, h: hy + 20 - top) }
                    else { pic.line("f\(k)x", [(x + 0.8, hy + 19.2), (x + 4.2, hy + 15.8)]) }
                    pic.sketch.startAt = nil
                }
            }
            if tapping {
                let can = (0..<5).filter { P.plus ? $0 >= P.a : $0 < P.a }
                if s.on("ring") && !s.on("spot"), let f = can.first, let l = can.last {
                    KK.hintBox(&pic, "hr", x: Double(f) * 10, y: hy, w: Double(l - f) * 10 + 5, h: 20)
                }
                if s.on("spot"), let k = P.moves.first(where: { !shown.contains($0) }) {
                    let top = P.plus ? hy + 15 : Self.top(k, hy)
                    KK.hintBox(&pic, "spot", x: Double(k) * 10, y: top, w: 5, h: hy + 20 - top)
                }
            }
        }

        // the fact: the record from the start, its box filled on the number row beside it
        let line = Pl.record + 1, toks: [M7.Tok] = [.n(P.a), .op(P.sign), .n(P.b), .op("=")]
        switch st {
        case 0 where P.mode == 0:
            KA.line(&pic, "rec", toks, value: nil, wrong: false, line: line)
        case 2:
            M7.row(&pic, "rec", toks + [.n(P.c, .chapter)], x: 0, line: line)
        default:
            let (v, wrong) = KK.typed(s, "x", want: P.c)
            KA.line(&pic, "rec", toks, value: v, wrong: wrong, line: line)
            KK.numberRow(&pic, "nr", y: Pl.keys, x0: Place.keysX, wrong: wrong ? v : nil, spot: s.on("spot") ? P.c : nil, keys: 0...5)
            if s.on("ring") && !s.on("spot"), drawHand {
                let ups = (0..<5).filter { $0 < P.a }
                if let l = ups.last { KK.hintBox(&pic, "hr", x: 0, y: Pl.hand, w: Double(l) * 10 + 5, h: 20) }
                else { KK.hintBox(&pic, "hr", x: 0, y: Pl.hand + 15, w: 45, h: 5) }
            }
        }
        let room = pic.R(-5, 0, 55, max(Pl.hand + 25, Pl.record + 4))
        return PaperDrawing(picture: pic.sketch, extent: drawHand || st == 2 ? room : nil)
    }

    /// Done: Next problem beside the fact, where the number row was.
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = FactsToFive.Parts(s.numbers), Pl = Place(P: P)
        return at(s) == 2 ? CGPoint(x: 20, y: Pl.record) : nil
    }

    private func finger(_ q: CGPoint, _ hy: Double) -> Int? {
        guard q.y >= hy - 1, q.y <= hy + 21 else { return nil }
        let k = Int(floor(q.x / 10))
        guard (0..<5).contains(k), q.x - Double(k) * 10 <= 5.5 else { return nil }
        return k
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = FactsToFive.Parts(s.numbers), Pl = Place(P: P), st = at(s)
        if st == 0 {
            let ch = changed(s)
            return Hands(tap: { q in
                guard let k = finger(q, Pl.hand) else { return nil }
                // a changed one tapped: it goes back
                if ch.contains(k) { return HandMove(hand: nil, missHand: nil, keep: ["ch\(k)": 0, "again": -1]) }
                if P.plus && k < P.a { return HandMove(hand: nil, missHand: nil, set: [("f", -1)], keep: ["again": Double(k)], check: true) }
                if !P.plus && k >= P.a { return HandMove(hand: nil, missHand: nil, set: [("f", -2)], keep: ["again": Double(k)], check: true) }
                let n = ch.count + 1
                return HandMove(hand: nil, missHand: nil, set: n >= P.b ? [("f", Double(n))] : [], keep: ["ch\(k)": 1, "again": -1], check: n >= P.b)
            })
        }
        guard st == 1 else { return nil }
        return Hands(tap: { q in KK.tapped(q, y: Pl.keys, x0: Place.keysX, keys: 0...5).map { HandMove(hand: nil, missHand: nil, set: [("x", Double($0))], check: true) } })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = FactsToFive.Parts(s.numbers), Pl = Place(P: P), st = at(s)
        if st == 0 {
            let ch = changed(s)
            return P.moves.filter { !ch.contains($0) }.map { k in .tap(.picture(CGPoint(x: Double(k) * 10 + 2.5, y: Pl.hand + 17.5))) }
        }
        if st == 1 { return [.tap(.picture(KK.keySpot(P.c, y: Pl.keys, x0: Place.keysX)))] }
        return []
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = FactsToFive.Parts(s.numbers), st = at(s)
        if st == 0 {
            if P.plus, P.a > 0 { return HandMove(hand: nil, missHand: nil, set: [("f", -1)], keep: ["again": 0], check: true) }
            if !P.plus, P.a < 5 { return HandMove(hand: nil, missHand: nil, set: [("f", -2)], keep: ["again": 4], check: true) }
            return nil
        }
        guard st == 1 else { return nil }
        let w = [P.a, P.b, P.c + 1, P.c - 1].first { $0 != P.c && (0...5).contains($0) } ?? 0
        return HandMove(hand: nil, missHand: nil, set: [("x", Double(w))], check: true)
    }
}
