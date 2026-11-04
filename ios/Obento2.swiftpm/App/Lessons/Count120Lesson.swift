import SwiftUI

/// Count to 120 on the paper, as in the preview (design/prototype/grade1-ch3.html, dCountOn and dHowMany).
/// Count on: the rows of the 120 chart the count passes, and one above and below; the start ringed, the next places empty,
/// two of them boxed. Drag (or tap) along the empty places from the start: each fills and its number is written in the
/// chapter's colour, the count read out under the chart ("98, 99, 100, 101"). Then the boxes are written with the digit pad
/// under the chart, one after the other.
/// How many?: the chart from 1, its first n places shaded and their numbers left off, four rows showing (they turn on by
/// three as the count goes down). Tap each full row: it's outlined and its ten is written at its end, 10, 20 …; drag along
/// the rest; write how many in the box under the chart.
///
/// Kept: "w" places counted (count on), "rows" full rows tapped and "w" ones counted (how many), "chk0", "chk1", "chk" what
/// was last checked. Hand while a count is held: "grab", "c", "skip", "dead", "lx", "ly".
@MainActor
struct Count120Lesson: PaperLesson {
    /// The places counted ("c") are drawn on the picture as they light, over its lines; only the finger's walk is live.
    var liveKeys: Set<String> { ["skip", "dead", "lx", "ly"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// Count on's pad: a block under its chart. How many's record line and pad, under its four rows.
    private func padY(_ P: Count120.Parts) -> Double { P.many ? 25 : 5 * Double(P.rows) + 5 }
    static let manyLine = 22.0

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = Count120.Parts(s.numbers), st = at(s)
        let writing = P.many ? st == 2 : st == 1 || st == 2
        if writing { return DigitPad.checkAt(x: 0, y: padY(P)) }
        return st == 3 ? CGPoint(x: 0, y: padY(P)) : nil
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        Count120.Parts(s.numbers).many ? drawMany(s) : drawOn(s)
    }
    func hands(_ s: PaperState) -> Hands? {
        Count120.Parts(s.numbers).many ? handsMany(s) : handsOn(s)
    }

    // MARK: count on

    private func drawOn(_ s: PaperState) -> PaperDrawing {
        let P = Count120.Parts(s.numbers), st = at(s), r0 = P.r0, rows = P.rows
        var pic = GridPen(), live = GridPen(stableIds: true)
        let w = st == 0 ? Int(s.run.kept["w"] ?? 0) : P.m
        let held = st == 0 && s.grabbed, c = held ? Int(s.h("c") ?? Double(w)) : w
        for v in (10 * r0 + 1)...min(120, 10 * (r0 + rows)) {
            let place = v > P.s && v <= P.last
            if !place { N1.num(&pic, "cn", v, r0); continue }
            guard v <= P.s + c else { continue }
            // counted: filled, its number in the chapter's colour (a boxed place waits to be written)
            N1.fill(&pic, "lit", v, r0)
            if !P.boxed.contains(v) { N1.num(&pic, "cn", v, r0, lit: true) }
        }
        N1.lines(&pic, "ch", r0, rows)
        for (i, v) in P.boxed.enumerated() {
            let (val, wrong) = DigitPad.typed(s, "x\(i)", want: v, chk: "chk\(i)")
            let state: N1.Box = st > i + 1 ? .done : st == i + 1 ? (wrong ? .wrong : .active) : .idle
            N1.box(&pic, "bx\(i)", v, r0, state, value: state == .done ? v : st == i + 1 ? val : nil)
        }
        let a = N1.mid(P.s, r0)
        pic.circle("start", at: a.x, a.y, radius: 2.05, .chapter)
        let bottom = 5 * Double(rows)
        switch st {
        case 0:
            if c > 0 {
                let ro = Num1.run(Array((P.s + 1)...(P.s + c)))
                if held { A1.note(&live, "ro", ro, x: 0, y: bottom + 1.5); live.reads(ro) } else { A1.note(&pic, "ro", ro, x: 0, y: bottom + 1.5) }
            }
            let next = P.s + w + 1
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: 5 * Double(Num1.row(next) - r0), w: 50, h: 5) }
            if s.on("spot") { let m = N1.mid(next, r0); KK.hint(&pic, "spot", m.x, m.y) }
        case 1, 2:
            DigitPad.draw(&pic, "pad", x: 0, y: padY(P))
            let v = P.boxed[st - 1], b = N1.block(v, r0)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: b.y, w: 50, h: 5) }
            // a second miss: the number that goes there, beside its row
            if s.on("spot") { A1.note(&pic, "spot", "\(v)", x: 50.5, y: b.y + 2.5) }
        default: break
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, actions: st == 1 || st == 2 ? ["Check"] : [])
    }

    private func handsOn(_ s: PaperState) -> Hands? {
        let P = Count120.Parts(s.numbers), st = at(s), r0 = P.r0, rows = P.rows
        if st == 1 || st == 2 {
            let i = st - 1
            return DigitPad.hands(s, "x\(i)", want: P.boxed[i], x: 0, y: padY(P), chk: "chk\(i)", most: 5)
        }
        guard st == 0 else { return nil }
        let w = Int(s.run.kept["w"] ?? 0), from = P.s + 1, to = P.last
        func done(_ held: Numbers) -> HandMove {
            let c = Int(held["c"] ?? Double(w))
            if (held["dead"] ?? 0) != 0 || (held["skip"] ?? 0) != 0 && c < P.m {
                return HandMove(hand: [:], missHand: [:], set: [("k", -1)], keep: ["w": Double(c)], check: true)
            }
            if c == P.m { return HandMove(hand: [:], missHand: [:], set: [("k", Double(P.m))], keep: ["w": Double(c)], check: true) }
            return HandMove(hand: [:], missHand: [:], keep: ["w": Double(c)])
        }
        return Hands(
            tap: { q in
                guard let v = N1.at(q, r0, rows) else { return nil }
                if v == from + w { return done(["c": Double(w + 1)]) }
                if v > from + w && v <= to { return done(["c": Double(w), "dead": 1]) }
                return nil
            },
            grab: { q in
                guard let v = N1.at(q, r0, rows) else { return nil }
                let nx = from + w
                if v > nx && v <= to { return N1.held(w, q, dead: true) }
                guard v == nx || (v >= P.s && v < nx) else { return nil }
                var h = N1.held(w, q)
                N1.enter(&h, v, from: from, to: to)
                return h
            },
            drag: { q, held in
                guard (held["dead"] ?? 0) == 0 else { return held }
                var h = held
                for p in N1.walk(CGPoint(x: held["lx"] ?? q.x, y: held["ly"] ?? q.y), q) { N1.enter(&h, N1.at(p, r0, rows), from: from, to: to) }
                h["lx"] = (q.x * 2).rounded() / 2; h["ly"] = (q.y * 2).rounded() / 2
                return h
            },
            release: done)
    }

    // MARK: how many

    private func rowsDone(_ s: PaperState, _ P: Count120.Parts) -> Int { at(s) == 0 ? Int(s.run.kept["rows"] ?? 0) : P.T }
    private func window(_ s: PaperState, _ P: Count120.Parts) -> Int {
        Count120.Parts.window(at(s) == 0 ? rowsDone(s, P) : P.o > 0 ? P.T : P.T - 1)
    }

    private func drawMany(_ s: PaperState) -> PaperDrawing {
        let P = Count120.Parts(s.numbers), st = at(s), r0 = window(s, P), done = rowsDone(s, P)
        var pic = GridPen(), live = GridPen(stableIds: true)
        let w = st == 1 ? Int(s.run.kept["w"] ?? 0) : st > 1 ? P.o : 0
        let held = st == 1 && s.grabbed, c = held ? Int(s.h("c") ?? Double(w)) : w
        for v in (10 * r0 + 1)...min(120, 10 * (r0 + 4)) {
            if v <= P.n { N1.fill(&pic, "sh", v, r0) }
            if v > 10 * P.T && v <= 10 * P.T + c { N1.num(&pic, "cn", v, r0) }
        }
        N1.lines(&pic, "ch", r0, 4)
        // the counted rows: outlined, their tens at the row's end
        for r in max(r0, 0)..<max(r0, min(done, r0 + 4)) {
            let y = 5 * Double(r - r0)
            pic.sketch.box("rw\(r)-\(r0)", pic.R(0, y, 50, 5), .chapter, width: Sketch.stroke)
            A1.note(&pic, "rt\(r)-\(r0)", "\(10 * (r + 1))", x: 50.5, y: y + 2.5)
        }
        if held && c > w { let ro = Num1.run(Array((10 * P.T + 1)...(10 * P.T + c))); live.reads(ro) }
        switch st {
        case 0:
            let ry = 5 * Double(done - r0)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: ry, w: 50, h: 5 * Double(max(1, min(4, P.T - r0) - (done - r0)))) }
            if s.on("spot") && done < P.T { KK.hintBox(&pic, "spot", x: 0, y: ry, w: 50, h: 5) }
        case 1:
            let ry = 5 * Double(P.T - r0)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: ry, w: 50, h: 5) }
            if s.on("spot") { let m = N1.mid(10 * P.T + w + 1, r0); KK.hint(&pic, "spot", m.x, m.y) }
        case 2:
            let (v, wrong) = DigitPad.typed(s, "x", want: P.n)
            N1.record(&pic, "rec", [], value: v, wrong: wrong, line: Self.manyLine)
            DigitPad.draw(&pic, "pad", x: 0, y: padY(P))
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: 0, w: 50, h: 20) }
            if s.on("spot") { A1.note(&pic, "spot", "\(P.n)", x: 5, y: Self.manyLine) }
        default:
            N1.record(&pic, "rec", [], value: nil, wrong: false, done: P.n, line: Self.manyLine)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, actions: st == 2 ? ["Check"] : [])
    }

    private func handsMany(_ s: PaperState) -> Hands? {
        let P = Count120.Parts(s.numbers), st = at(s), r0 = window(s, P)
        switch st {
        case 0:
            let done = rowsDone(s, P)
            return Hands(tap: { q in
                guard let v = N1.at(q, r0, 4) else { return nil }
                let r = Num1.row(v)
                if r < done { return nil }
                if r == done && r < P.T {
                    let all = done + 1 == P.T
                    return HandMove(hand: nil, missHand: nil, set: all ? [("r", Double(P.T))] : [], keep: ["rows": Double(done + 1)], check: all)
                }
                if r < P.T { return HandMove(hand: nil, missHand: nil, set: [("r", -1)], check: true) }
                if r == P.T && P.o > 0 { return HandMove(hand: nil, missHand: nil, set: [("r", -2)], check: true) }
                return nil
            })
        case 1:
            let w = Int(s.run.kept["w"] ?? 0), from = 10 * P.T + 1, to = P.n
            func done(_ held: Numbers) -> HandMove {
                let c = Int(held["c"] ?? Double(w))
                if (held["dead"] ?? 0) != 0 || (held["skip"] ?? 0) != 0 && c < P.o {
                    return HandMove(hand: [:], missHand: [:], set: [("k", -1)], keep: ["w": Double(c)], check: true)
                }
                if c == P.o { return HandMove(hand: [:], missHand: [:], set: [("k", Double(P.o))], keep: ["w": Double(c)], check: true) }
                return HandMove(hand: [:], missHand: [:], keep: ["w": Double(c)])
            }
            return Hands(
                tap: { q in
                    guard let v = N1.at(q, r0, 4), Num1.row(v) == P.T else { return nil }
                    if v == from + w { return done(["c": Double(w + 1)]) }
                    if v > from + w && v <= to { return done(["c": Double(w), "dead": 1]) }
                    return nil
                },
                grab: { q in
                    guard let v = N1.at(q, r0, 4), Num1.row(v) == P.T, v <= to else { return nil }
                    let nx = from + w
                    if v > nx { return N1.held(w, q, dead: true) }
                    var h = N1.held(w, q)
                    N1.enter(&h, v, from: from, to: to)
                    return h
                },
                drag: { q, held in
                    guard (held["dead"] ?? 0) == 0 else { return held }
                    var h = held
                    for p in N1.walk(CGPoint(x: held["lx"] ?? q.x, y: held["ly"] ?? q.y), q) { N1.enter(&h, N1.at(p, r0, 4), from: from, to: to) }
                    h["lx"] = (q.x * 2).rounded() / 2; h["ly"] = (q.y * 2).rounded() / 2
                    return h
                },
                release: done)
        case 2: return DigitPad.hands(s, "x", want: P.n, x: 0, y: padY(P), most: 5)
        default: return nil
        }
    }

    // MARK: Show me

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Count120.Parts(s.numbers), st = at(s)
        if P.many {
            let r0 = window(s, P)
            switch st {
            case 0:
                // the ghost taps the full rows showing (the rest come after the chart turns on)
                let done = rowsDone(s, P)
                return (done..<min(P.T, r0 + 4)).map { .tap(.picture(CGPoint(x: 25, y: 5 * Double($0 - r0) + 2.5))) }
            case 1:
                let w = Int(s.run.kept["w"] ?? 0)
                let pts = ((10 * P.T + w + 1)...P.n).map { N1.mid($0, r0) }
                return pts.count == 1 ? [.tap(.picture(pts[0]))] : [.path(pts)]
            case 2: return DigitPad.demo(P.n, x: 0, y: padY(P))
            default: return []
            }
        }
        switch st {
        case 0:
            let w = Int(s.run.kept["w"] ?? 0)
            let pts = ((P.s + w + 1)...P.last).map { N1.mid($0, P.r0) }
            return pts.count == 1 ? [.tap(.picture(pts[0]))] : [.path(pts)]
        case 1, 2: return DigitPad.demo(P.boxed[st - 1], x: 0, y: padY(P))
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Count120.Parts(s.numbers), st = at(s)
        if P.many {
            switch st {
            case 0: return HandMove(hand: nil, missHand: nil, set: [("r", P.T > 1 ? -1 : -2)], check: true)
            case 1: return HandMove(hand: [:], missHand: [:], set: [("k", -1)], check: true)
            case 2:
                let slip = P.o > 0 ? 10 * P.T : P.n + 1
                return HandMove(hand: nil, missHand: nil, set: [("x", Double(slip))], keep: ["chk": Double(slip)], check: true)
            default: return nil
            }
        }
        switch st {
        case 0: return HandMove(hand: [:], missHand: [:], set: [("k", -1)], check: true)
        case 1, 2:
            let v = P.boxed[st - 1], slip = P.slips(v).first?.0 ?? v + 1
            return HandMove(hand: nil, missHand: nil, set: [("x\(st - 1)", Double(slip))], keep: ["chk\(st - 1)": Double(slip)], check: true)
        default: return nil
        }
    }
}
