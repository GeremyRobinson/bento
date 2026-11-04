import SwiftUI

/// Story problems on the paper, as in the preview (design/prototype/grade1-ch2.html, dStory): the story's sentences start the
/// instruction (written once, said with it, as chapter 1's stories); the things are counters on one row of places on row 1 (10
/// for a story within 10, else 18); every number in the story names its group with a bracket under the row. Each kind is
/// acted out: slide the new ones (striped, waiting on row 8) onto the row; drag back from the row's end to cross off the
/// ones that go; drag the row out (or back) to the dashed outline of how many now; slide the ones that came back off; drag
/// across the bag's (dotted) ones to count them. Then the story is written with the box where the unknown is, on the
/// number row.
///
/// Hand: "grab", "gx", "gy", "dx", "dy" (a group slid), "k0", "k" (a row dragged), "lit" (counted, bits). Kept: "k", "lit",
/// "lx", "ly" (where a group was let go).
@MainActor
struct Story1Lesson: PaperLesson {
    var liveKeys: Set<String> { ["dx", "dy", "k", "lit"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let row = 1.0, l1 = 4.6, l2 = 7.6, wait = 8.0, under = 12.5, keys = 17.0
    func recordRow(_ n: Numbers) -> Double? { 13 }

    private func bits(_ v: Double?) -> [Int] { let b = Int(v ?? 0); return (0..<20).filter { b & (1 << $0) != 0 } }
    /// Where the waiting (or sliding) group's counters are, before it moves.
    private func home(_ P: Story1.Parts) -> (x0: Int, y: Double) { P.kind == .joinStart ? (P.s, Self.row) : (0, Self.wait) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Story1.Parts(s.numbers), st = at(s), kind = P.kind, sN = P.s, ch = P.ch, e = P.e
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        A1.places(&pic, "row", x: 0, y: Self.row, P.places)
        let held = st == 0 && s.grabbed
        func b1(_ id: String, _ from: Int, _ to: Int, _ label: String, _ p: inout GridPen, say: Bool = false) {
            E1.bracket(&p, id, A1.x(from) + 0.3, A1.x(to) - 0.3, y: Self.l1, label, words: say ? KK.words : KK.maths)
        }
        func b2(_ id: String, _ from: Int, _ to: Int, _ label: String, _ p: inout GridPen, say: Bool = false) {
            E1.bracket(&p, id, A1.x(from) + 0.3, A1.x(to) - 0.3, y: Self.l2, label, words: say ? KK.words : KK.maths)
        }
        var note: String?
        switch kind {
        case .join, .together, .takeStart:
            let base = kind == .takeStart ? e : sN
            for j in 0..<base { A1.counter(&pic, "r\(j)", x: A1.x(j), y: Self.row, .solid) }
            if kind == .takeStart { b1("b1", 0, e, "now \(e)", &pic, say: true) } else { b1("b1", 0, sN, "\(sN)", &pic) }
            if st == 0 {
                if held {
                    let dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0
                    for j in 0..<ch { A1.counter(&live, "g\(j)", x: A1.x(j) + dx, y: Self.wait + dy, .striped) }
                } else {
                    let lx = s.run.kept["lx"], ly = s.run.kept["ly"] ?? 0
                    let was: ((inout GridPen) -> Void)? = lx.map { x in { p in for j in 0..<ch { A1.counter(&p, "g\(j)", x: A1.x(j) + x, y: Self.wait + ly, .striped) } } }
                    KM.seeded(&pic, was: was) { p in for j in 0..<ch { A1.counter(&p, "g\(j)", x: A1.x(j), y: Self.wait, .striped) } }
                    pic.label("gl", "\(ch)", KK.maths, .right, edge: A1.x(ch), along: Self.wait + 1.5)
                }
            } else {
                // onto the row: they fill on from the last counter, one after another, the count running on
                let lx = s.run.kept["lx"] ?? 0, ly = s.run.kept["ly"] ?? 0
                KM.seeded(&pic, was: st == 1 ? { p in for j in 0..<ch { A1.counter(&p, "g\(j)", x: A1.x(j) + lx, y: Self.wait + ly, .striped) } } : nil) { p in
                    for j in 0..<ch {
                        if st == 1 { p.sketch.delay = 0.22 * Double(j) }
                        A1.counter(&p, "g\(j)", x: A1.x(base + j), y: Self.row, .striped)
                    }
                    p.sketch.delay = 0
                }
                pic.sketch.delay = st == 1 ? 0.22 * Double(ch) : 0
                b1("b1n", base, base + ch, "\(ch)", &pic)
                pic.sketch.delay = 0
            }
        case .take, .takeChange:
            let k = st > 0 ? ch : held ? Int(s.h("k") ?? 0) : Int(s.run.kept["k"] ?? 0)
            var pen = held ? live : pic
            for j in 0..<sN { A1.counter(&pen, "r\(j)", x: A1.x(j), y: Self.row, .solid, cross: j >= sN - k) }
            if held { live = pen } else { pic = pen }
            b1("b1", 0, sN, "\(sN)", &pic)
            if kind == .takeChange {
                pic.sketch.box("outl", pic.R(-0.4, Self.row - 0.4, A1.x(e) + 0.8, 3.8), .chapter, width: Sketch.stroke, dashed: true)
                b2("b2", 0, e, "now \(e)", &pic, say: true)
                if k > 0 { note = "\(k) gone" }
            } else {
                if st > 0 { b2("b2", sN - ch, sN, "\(ch)", &pic) }
                if k > 0 { note = E1.run(Array((sN - k)..<sN).reversed()) }
            }
        case .joinChange:
            let k = st > 0 ? ch : held ? Int(s.h("k") ?? 0) : Int(s.run.kept["k"] ?? 0)
            for j in 0..<sN { A1.counter(&pic, "r\(j)", x: A1.x(j), y: Self.row, .solid) }
            var pen = held ? live : pic
            for j in 0..<k { A1.counter(&pen, "n\(j)", x: A1.x(sN + j), y: Self.row, .striped) }
            if held { live = pen } else { pic = pen }
            pic.sketch.box("outl", pic.R(-0.4, Self.row - 0.4, A1.x(e) + 0.8, 3.8), .chapter, width: Sketch.stroke, dashed: true)
            b1("b1", 0, sN, "\(sN)", &pic)
            b2("b2", 0, e, "now \(e)", &pic, say: true)
            if k > 0 { note = "\(k) came" }
        case .joinStart:
            for j in 0..<sN { A1.counter(&pic, "r\(j)", x: A1.x(j), y: Self.row, .solid) }
            if st == 0 {
                if held {
                    let dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0
                    for j in 0..<ch { A1.counter(&live, "g\(j)", x: A1.x(sN + j) + dx, y: Self.row + dy, .striped) }
                } else {
                    let lx = s.run.kept["lx"], ly = s.run.kept["ly"] ?? 0
                    let was: ((inout GridPen) -> Void)? = lx.map { x in { p in for j in 0..<ch { A1.counter(&p, "g\(j)", x: A1.x(sN + j) + x, y: Self.row + ly, .striped) } } }
                    KM.seeded(&pic, was: was) { p in for j in 0..<ch { A1.counter(&p, "g\(j)", x: A1.x(sN + j), y: Self.row, .striped) } }
                }
                b1("b1", sN, e, "\(ch)", &pic)
                b2("b2", 0, e, "now \(e)", &pic, say: true)
            } else {
                // undone: the places they left, dashed; what's left is the start
                for j in 0..<ch { E1.ghost(&pic, "gh\(j)", x: A1.x(sN + j), y: Self.row) }
                b1("b1s", 0, sN, "\(sN)", &pic)
                note = "\(sN) at the start"
            }
        case .apart:
            for j in 0..<sN { A1.counter(&pic, "r\(j)", x: A1.x(j), y: Self.row, .solid) }
            for j in sN..<e { A1.counter(&pic, "p\(j)", x: A1.x(j), y: Self.row, .dotted) }
            b1("b1", 0, sN, "\(sN)", &pic)
            b2("b2", 0, e, "\(e)", &pic)
            let lit = st > 0 ? Array(sN..<e) : bits(held ? s.h("lit") : s.run.kept["lit"])
            var pen = held ? live : pic
            for (i, j) in lit.enumerated() { pen.word("cn\(j)", "\(i + 1)", at: A1.x(j) + 1.5, Self.row - 0.9, KK.lit) }
            if held { live = pen } else { pic = pen }
            if !lit.isEmpty { note = "\(lit.count) in the bag" }
        }
        if st == 0, let note {
            if held { live.reads(note); A1.note(&live, "ro", note, x: 0, y: Self.under) } else { A1.note(&pic, "ro", note, x: 0, y: Self.under) }
        } else if st == 1, kind == .joinStart, let note { A1.note(&pic, "ro", note, x: 0, y: Self.under) }

        let ans = P.ans
        func toks(_ last: A1.Tok) -> [A1.Tok] {
            P.record.map { t -> A1.Tok in switch t { case .n(let v): .n(v); case .op(let o): .op(o); case .box: last } }
        }
        switch st {
        case 0:
            if s.on("ring") && !s.on("spot") { ring(&pic, P, move: true) }
            if s.on("spot") { spot(&pic, P) }
        case 1:
            let (v, wrong) = KK.typed(s, "x", want: ans)
            A1.record(&rec, "rec", toks(.box(v, wrong: wrong)))
            A1.numberRow(&pic, "nr", y: Self.keys, wrong: wrong ? v : nil, spot: s.on("spot") ? ans : nil)
            if s.on("ring") && !s.on("spot") { ring(&pic, P, move: false) }
        default: A1.record(&rec, "rec", toks(.n(ans, .chapter)))
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    /// A first miss's ring: the general area (what to move; at the write, the counters the answer counts).
    private func ring(_ pic: inout GridPen, _ P: Story1.Parts, move: Bool) {
        let (from, to): (Int, Int)
        if move {
            switch P.kind {
            case .join, .together, .takeStart: KK.hintBox(&pic, "hr", x: 0, y: Self.wait, w: A1.x(P.ch), h: 3); return
            case .joinStart: (from, to) = (P.s, P.e)
            case .apart: (from, to) = (P.s, P.e)
            case .joinChange: KK.hint(&pic, "hr", A1.x(P.s) - 1.5, Self.row + 1.5, radius: 2.2); return
            default: KK.hint(&pic, "hr", A1.x(P.s) - 1.5, Self.row + 1.5, radius: 2.2); return
            }
        } else {
            switch P.kind {
            case .join, .together: (from, to) = (0, P.e)
            case .take: (from, to) = (0, P.e)
            case .joinChange, .apart: (from, to) = (P.s, P.e)
            case .takeChange: (from, to) = (P.e, P.s)
            case .joinStart: (from, to) = (0, P.s)
            case .takeStart: (from, to) = (0, P.s)
            }
        }
        KK.hintBox(&pic, "hr", x: A1.x(from), y: Self.row, w: A1.x(to - from), h: 3)
    }
    /// A second miss's spot: exactly where the move ends.
    private func spot(_ pic: inout GridPen, _ P: Story1.Parts) {
        let (from, to): (Int, Int)
        switch P.kind {
        case .join, .together: (from, to) = (P.s, P.e)
        case .takeStart: (from, to) = (P.e, P.s)
        case .take: (from, to) = (P.e, P.s)
        case .takeChange: (from, to) = (P.e, P.s)
        case .joinChange: (from, to) = (P.s, P.e)
        case .joinStart: (from, to) = (P.s, P.e)
        case .apart: (from, to) = (P.s, P.e)
        }
        pic.sketch.box("spot", pic.R(A1.x(from), Self.row, A1.x(to - from), 3), .chapter, width: Sketch.stroke, dashed: true)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Story1.Parts(s.numbers), st = at(s), sN = P.s, ch = P.ch, e = P.e
        guard st == 0 else { return st == 1 ? A1.rowHands("x", y: Self.keys) : nil }
        let onRow = { (q: CGPoint) in q.y >= Self.row - 0.5 && q.y <= Self.row + 3.5 }
        let col = { (q: CGPoint) in Int((q.x / 3).rounded(.down)) }
        let miss = HandMove(hand: [:], missHand: [:], set: [("m", -1)], check: true)
        switch P.kind {
        case .join, .together, .takeStart, .joinStart:
            let h = home(P)
            return Hands(
                grab: { q in
                    if q.y >= h.y - 0.5, q.y <= h.y + 3.5, q.x >= A1.x(h.x0) - 0.25, q.x <= A1.x(h.x0 + ch) + 0.25 { return ["grab": 1, "gx": q.x, "gy": q.y, "dx": 0, "dy": 0] }
                    return nil
                },
                drag: { q, held in
                    var held = held
                    held["dx"] = (q.x - (held["gx"] ?? q.x)).rounded(); held["dy"] = (q.y - (held["gy"] ?? q.y)).rounded()
                    return held
                },
                release: { held in
                    let dx = held["dx"] ?? 0, dy = held["dy"] ?? 0, keep: Numbers = ["lx": dx, "ly": dy]
                    let made = P.kind == .joinStart ? dx * dx + dy * dy >= 9 : Self.wait + dy <= Self.row + 3
                    guard made else { return HandMove(hand: [:], keep: keep) }
                    return HandMove(hand: [:], missHand: [:], set: [("m", Double(ch))], keep: keep, check: true)
                },
                actions: [:]).with(tap: P.kind == .joinStart ? { q in onRow(q) && col(q) >= 0 && col(q) < sN ? miss : nil } : nil)
        case .take, .takeChange, .joinChange:
            let k0 = Int(s.run.kept["k"] ?? 0), out = P.kind == .joinChange
            let end = out ? sN + k0 : sN, most = out ? P.places - sN : sN
            return Hands(
                grab: { q in onRow(q) && q.x >= -0.5 && q.x <= A1.x(end) + 3.5 ? ["grab": 1, "gx": q.x, "k0": Double(k0), "k": Double(k0)] : nil },
                drag: { q, held in
                    var held = held
                    let dk = Int(((q.x - (held["gx"] ?? q.x)) / 3).rounded())
                    held["k"] = Double(max(0, min(most, out ? k0 + dk : k0 - dk)))
                    return held
                },
                release: { held in
                    let k = Int(held["k"] ?? 0)
                    guard k != k0 else { return HandMove(hand: [:]) }
                    return HandMove(hand: [:], missHand: [:], set: [("m", Double(k))], keep: ["k": Double(k)], check: true)
                })
        case .apart:
            let lit0 = Int(s.run.kept["lit"] ?? 0)
            func add(_ bits: Int, _ j: Int) -> Int { (sN..<e).contains(j) ? bits | (1 << j) : bits }
            func done(_ bits: Int) -> HandMove {
                let n = bits.nonzeroBitCount
                return HandMove(hand: [:], missHand: [:], set: n == ch ? [("m", Double(n))] : [], keep: ["lit": Double(bits)], check: n == ch)
            }
            return Hands(
                tap: { q in
                    guard onRow(q), col(q) >= 0, col(q) < e else { return nil }
                    return col(q) < sN ? miss : done(add(lit0, col(q)))
                },
                grab: { q in onRow(q) && col(q) >= sN && col(q) < e ? ["grab": 1, "lit": Double(add(lit0, col(q)))] : nil },
                drag: { q, held in
                    var held = held
                    if onRow(q) { held["lit"] = Double(add(Int(held["lit"] ?? 0), col(q))) }
                    return held
                },
                release: { held in done(Int(held["lit"] ?? 0)) })
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Story1.Parts(s.numbers), sN = P.s, ch = P.ch, y = Self.row + 1.5
        switch at(s) {
        case 0:
            switch P.kind {
            case .join, .together, .takeStart: return [.drag(from: CGPoint(x: 1.5, y: Self.wait + 1.5), to: CGPoint(x: 1.5, y: y))]
            case .joinStart: return [.drag(from: CGPoint(x: A1.x(sN) + 1.5, y: y), to: CGPoint(x: A1.x(sN) + 1.5, y: y + 6))]
            case .take, .takeChange:
                let k0 = Int(s.run.kept["k"] ?? 0), x = A1.x(sN) - 1.5
                return [.drag(from: CGPoint(x: x, y: y), to: CGPoint(x: x - 3 * Double(ch - k0), y: y))]
            case .joinChange:
                let k0 = Int(s.run.kept["k"] ?? 0), x = A1.x(sN + k0) - 1.5
                return [.drag(from: CGPoint(x: x, y: y), to: CGPoint(x: x + 3 * Double(ch - k0), y: y))]
            case .apart:
                let lit = Int(s.run.kept["lit"] ?? 0)
                return (sN..<P.e).filter { lit & (1 << $0) == 0 }.map { .tap(.picture(CGPoint(x: A1.x($0) + 1.5, y: y))) }
            }
        case 1: return [.tap(.picture(A1.keySpot(P.ans, y: Self.keys)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Story1.Parts(s.numbers)
        switch at(s) {
        case 0:
            switch P.kind {
            case .joinStart, .apart: return HandMove(hand: [:], missHand: [:], set: [("m", -1)], check: true)
            case .take, .takeChange, .joinChange:
                let k = P.ch + 1 <= (P.kind == .joinChange ? P.places - P.s : P.s) ? P.ch + 1 : P.ch - 1
                return HandMove(hand: [:], missHand: [:], set: [("m", Double(k))], keep: ["k": Double(k)], check: true)
            default: return nil
            }
        case 1: return A1.slip("x", P.ans)
        default: return nil
        }
    }
}

private extension Hands {
    /// The same hands with a tap too (a touch on the wrong ones that only says a miss).
    func with(tap: ((CGPoint) -> HandMove?)?) -> Hands { var h = self; if let tap { h.tap = tap }; return h }
}
