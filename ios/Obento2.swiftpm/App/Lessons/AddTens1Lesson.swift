import SwiftUI

/// Add tens to a number and Add within 100 on the paper, as in the preview (design/prototype/grade1-ch4.html, dAdd). a as
/// tens and ones (T1's stack); b beside it, striped, b written over it, so the problem is the picture's names. Slide b's
/// tens (all together) onto a's tens: they snap in under them and the ones row moves down below; the readout says
/// "2 tens and 3 tens: 5 tens". Slide b's ones (the one grabbed and every one left of it go together) onto a's ones row:
/// they go in after its ones, counting on ("37, 38, 39, 40"); a full row is ringed a beat, closes into a new ten and joins
/// the tens, and the rest start a new ones row. Then the record goes on along the names line, 36 + 7 = 40 + 3 = [43],
/// written with the digit pad in its grid where b stood.
///
/// Hand: "grab", "dx", "dy" how far it's carried, "g" the one grabbed (−1: the tens), "dead" b's ones grabbed before its
/// tens. Kept: "m" b's ones moved; the last carry let go: "lg", "lm" (its first), "lx", "ly"; "chk" what was last checked.
@MainActor
struct AddTens1Lesson: PaperLesson {
    let tensOnly: Bool
    var liveKeys: Set<String> { ["dx", "dy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func parts(_ s: PaperState) -> AddTens1.Parts { AddTens1.Parts(s.numbers, tensOnly: tensOnly) }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        switch at(s) {
        case 2: return DigitPad.checkAt(x: T1.bx, y: T1.padY, .grid)
        case 3: return CGPoint(x: T1.bx, y: T1.padY)
        default: return nil
        }
    }

    /// Where everything is for a state: b's tens joined, b's ones moved, whether the full row has closed.
    private struct Lay {
        let P: AddTens1.Parts, joined: Bool, m: Int
        var closed: Bool { P.newTen && m >= P.need }
        var rows: Int { P.ta + (joined ? P.tb : 0) + (closed ? 1 : 0) }
        var holdY: Double { T1.top + 3 * Double(rows) + 1 }
        var bOy: Double { T1.top + (P.tb > 0 ? 3 * Double(P.tb) + 1 : 0) }
        /// The ones on the hold row now.
        var held: Int { closed ? m - P.need : P.ao + m }
        func tenY(_ r: Int) -> Double { T1.top + 3 * Double(r) }
        /// b's one j on the hold row (nil: it's in the new ten, or home).
        func slot(_ j: Int) -> Int? { j >= m ? nil : closed ? (j < P.need ? nil : j - P.need) : P.ao + j }
    }
    private func lay(_ s: PaperState) -> Lay {
        let P = parts(s), st = at(s)
        let m = st >= 2 ? P.bo : st == 1 ? Int(s.run.kept["m"] ?? 0) : 0
        return Lay(P: P, joined: P.tb > 0 && st >= 1, m: m)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let L = lay(s), P = L.P, st = at(s)
        var pic = GridPen(), live = GridPen(stableIds: true)
        let held = s.grabbed && (s.h("dead") ?? 0) == 0
        let carryTens = held && st == 0, g = Int(s.h("g") ?? -1)
        let carry: [Int] = held && st == 1 && g >= L.m ? Array(L.m...g) : []
        let dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0
        let k = s.run.kept, lg = k["lg"].map { Int($0) }, lm = Int(k["lm"] ?? 0), lx = k["lx"] ?? 0, ly = k["ly"] ?? 0

        // where the last carry was let go: its parts start there (a glide from the finger, or home again)
        var from: [String: Sketch.Kind] = [:]
        if let lg, !held {
            from = T1.kinds { p in
                if lg < 0 { for r in 0..<P.tb { T1.ten(&p, "B\(r)", x: T1.bx + lx, y: L.tenY(r) + ly, [.striped]) } }
                else { for j in lm...lg { A1.counter(&p, "b\(j)", x: T1.bx + A1.x(j) + lx, y: L.bOy + ly, .striped) } }
            }
        }
        // the full row closing just now: it rests on the ones row (ringed) a beat, then joins the tens
        let justClosed = (st == 1 || st == 2) && L.closed && lg != nil && lm < P.need && !held
        let beat = SketchDrawer.morphTime + SketchDrawer.viaRest
        pic.sketch.from = from

        // a's tens, then b's (once joined), then the new ten
        for r in 0..<P.ta { T1.ten(&pic, "A\(r)", x: 0, y: L.tenY(r), [.solid]) }
        if L.joined {
            for r in 0..<P.tb {
                pic.sketch.delay = (lg ?? 0) < 0 ? 0.12 + 0.06 * Double(r) : 0
                T1.ten(&pic, "B\(r)", x: 0, y: L.tenY(P.ta + r), [.striped])
            }
            pic.sketch.delay = 0
        }
        if L.closed {
            let y = L.tenY(L.rows - 1), hold0 = y + 1
            let ids = (0..<P.ao).map { "a\($0)" } + (0..<P.need).map { "b\($0)" }
            let styles: [A1.Style] = (0..<10).map { $0 < P.ao ? .solid : .striped }
            if justClosed {
                // b's ones land on the ones row first (via), a's wait there, the ring shows round the row
                let via = T1.kinds { p in for j in 0..<P.need { A1.counter(&p, "b\(j)", x: A1.x(P.ao + j), y: hold0, .striped) } }
                for (id, kd) in via where pic.sketch.from[id] != nil { pic.sketch.via[id] = kd }
                pic.sketch.from["Ng"] = T1.kinds { p in p.sketch.box("Ng", p.R(0, hold0, 30, 3), .chapter, width: Sketch.stroke) }["Ng"]
            }
            // what was already on the ones row waits the beat; what's carried lands first, then goes on with it
            for j in 0..<10 {
                pic.sketch.delay = justClosed && pic.sketch.from[ids[j] + "f"] == nil ? beat : 0
                A1.counter(&pic, ids[j], x: A1.x(j), y: y, styles[j])
            }
            pic.sketch.delay = justClosed ? beat : 0
            pic.sketch.box("Ng", pic.R(0, y, 30, 3), .chapter, width: Sketch.stroke)
            pic.sketch.delay = 0; pic.sketch.via = [:]
            if justClosed { pic.sketch.startAt = beat + SketchDrawer.morphTime }
            for j in 1..<10 { pic.line("Nd\(j)", [(A1.x(j), y), (A1.x(j), y + 3)], .ink3, dashed: true) }
            pic.sketch.startAt = nil
        }
        // the ones row: its empty places dashed while ones are slid onto it, then a's ones and b's moved ones
        if st == 1 {
            for i in L.held..<10 { pic.sketch.box("hs\(i)", pic.R(A1.x(i), L.holdY, 3, 3), .ink3, width: Sketch.stroke, dashed: true) }
        }
        if !L.closed { for j in 0..<P.ao { T1.one(&pic, "a\(j)", x: A1.x(j), y: L.holdY, .solid) } }
        for j in 0..<P.bo {
            if let sl = L.slot(j) { T1.one(&pic, "b\(j)", x: A1.x(sl), y: L.holdY, .striped) }
        }
        pic.sketch.from = [:]
        // b, home: its tens (unless carried), its ones (unless moved or carried)
        if !L.joined && !carryTens { for r in 0..<P.tb { T1.ten(&pic, "B\(r)", x: T1.bx, y: L.tenY(r), [.striped]) } }
        pic.sketch.from = from
        for j in L.m..<P.bo where !carry.contains(j) { T1.one(&pic, "b\(j)", x: T1.bx + A1.x(j), y: L.bOy, .striped) }
        pic.sketch.from = [:]
        if carryTens {
            for r in 0..<P.tb { T1.ten(&live, "B\(r)", x: T1.bx + dx, y: L.tenY(r) + dy, [.striped]) }
            live.reads(P.tensWords)
        }
        if !carry.isEmpty {
            for j in carry { T1.one(&live, "b\(j)", x: T1.bx + A1.x(j) + dx, y: L.bOy + dy, .striped) }
            let start = P.base + L.m
            live.reads(Num1.run(Array((start + 1)...(start + carry.count))))
        }

        // the names, and the record going on along them
        let rx = T1.names(&pic, P.a, "+", P.b)
        // readouts: the count on, at its row's end; the tens (and the sum's parts) top right
        if st == 1 && L.m > 0 && carry.isEmpty {
            let fromN = L.closed && L.m > P.need ? P.base + P.need + 1 : P.base + 1
            let y = L.closed && L.m == P.need ? L.tenY(L.rows - 1) : L.holdY
            if justClosed { pic.sketch.startAt = beat + SketchDrawer.morphTime }
            A1.note(&pic, "run\(fromN)-\(L.m)", Num1.run(Array(fromN...(P.base + L.m))), x: 31.5, y: y + 1.5)
            pic.sketch.startAt = nil
        }
        if L.joined && st == 1 { A1.note(&pic, "rt", P.tensWords, x: T1.bx, y: T1.noteY) }
        if st >= 2 { A1.note(&pic, "sum", P.summary, x: T1.bx, y: T1.noteY) }

        let toks: [M7.Tok] = P.split ? [.op("="), .n(10 * P.T), .op("+"), .n(P.O), .op("=")] : [.op("=")]
        let stackH = L.holdY + (L.held > 0 || st == 1 ? 3 : -1) - T1.top
        switch st {
        case 0:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: T1.top, w: 30, h: 3 * Double(P.ta)) }
            if s.on("spot") { pic.sketch.box("spot", pic.R(0, L.tenY(P.ta), 30, 3 * Double(P.tb)), .chapter, width: Sketch.stroke, dashed: true) }
        case 1:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: L.holdY, w: 30, h: 3) }
            if s.on("spot") { KK.hintBox(&pic, "spot", x: T1.bx + A1.x(L.m), y: L.bOy, w: A1.x(P.bo - L.m), h: 3) }
        case 2:
            let (v, wrong) = DigitPad.typed(s, "x", want: P.sum)
            N1.record(&pic, "rec", toks, value: v, wrong: wrong, x: rx, line: T1.line)
            DigitPad.draw(&pic, "pad", x: T1.bx, y: T1.padY, .grid)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: T1.top, w: 30, h: stackH) }
            if s.on("spot") { A1.note(&pic, "spot", "\(P.sum)", x: T1.bx + 14, y: T1.padY + 2) }
        default:
            N1.record(&pic, "rec", toks, value: nil, wrong: false, done: P.sum, x: rx, line: T1.line)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, actions: st == 2 ? ["Check"] : [])
    }

    func hands(_ s: PaperState) -> Hands? {
        let L = lay(s), P = L.P
        func dragged(_ q: CGPoint, _ held: Numbers) -> Numbers {
            var h = held
            h["dx"] = (q.x - (held["gx"] ?? q.x)).rounded()
            h["dy"] = (q.y - (held["gy"] ?? q.y)).rounded()
            return h
        }
        func onHome(_ q: CGPoint) -> Int? {
            guard q.y >= L.bOy - 0.5, q.y <= L.bOy + 3.5, q.x >= T1.bx - 0.25 else { return nil }
            let j = Int(((q.x - T1.bx) / 3).rounded(.down))
            return j >= L.m && j < P.bo ? j : nil
        }
        switch at(s) {
        case 0:
            return Hands(
                grab: { q in
                    if q.x >= T1.bx - 0.3, q.x <= T1.bx + 30.3, q.y >= T1.top - 0.3, q.y <= L.tenY(P.tb) + 0.3 {
                        return ["grab": 1, "g": -1, "gx": q.x, "gy": q.y, "dx": 0, "dy": 0]
                    }
                    if onHome(q) != nil { return ["grab": 1, "dead": 1] }
                    return nil
                },
                drag: { q, held in (held["dead"] ?? 0) != 0 ? held : dragged(q, held) },
                release: { held in
                    if (held["dead"] ?? 0) != 0 { return HandMove(hand: [:], missHand: [:], set: [("t", -2)], check: true) }
                    let dx = held["dx"] ?? 0, dy = held["dy"] ?? 0
                    let keep: Numbers = ["lg": -1, "lm": 0, "lx": dx, "ly": dy]
                    let cx = T1.bx + dx + 15, cy = T1.top + dy + 1.5, over = cx > -4 && cx < 34, hy = L.holdY
                    if over && cy > T1.top - 3 && cy < hy + 1 { return HandMove(hand: [:], missHand: [:], set: [("t", Double(P.tb))], keep: keep, check: true) }
                    if over && cy >= hy + 1 && cy < hy + 5 { return HandMove(hand: [:], missHand: [:], set: [("t", -1)], keep: keep, check: true) }
                    return HandMove(hand: [:], keep: keep)
                })
        case 1:
            return Hands(
                grab: { q in onHome(q).map { ["grab": 1, "g": Double($0), "gx": q.x, "gy": q.y, "dx": 0, "dy": 0] } },
                drag: { q, held in dragged(q, held) },
                release: { held in
                    let g = Int(held["g"] ?? 0), dx = held["dx"] ?? 0, dy = held["dy"] ?? 0
                    var keep: Numbers = ["lg": Double(g), "lm": Double(L.m), "lx": dx, "ly": dy]
                    let cx = T1.bx + A1.x(L.m) + 1.5 + dx, cy = L.bOy + 1.5 + dy, over = cx > -2 && cx < 32, hy = L.holdY
                    if over && cy > hy - 2 && cy < hy + 5 {
                        keep["m"] = Double(g + 1)
                        if g + 1 == P.bo { return HandMove(hand: [:], missHand: [:], set: [("o", Double(P.bo))], keep: keep, check: true) }
                        return HandMove(hand: [:], keep: keep)
                    }
                    if over && cy > T1.top - 2 && cy <= hy - 2 { return HandMove(hand: [:], missHand: [:], set: [("o", -1)], keep: keep, check: true) }
                    return HandMove(hand: [:], keep: keep)
                })
        case 2: return DigitPad.hands(s, "x", want: P.sum, x: T1.bx, y: T1.padY, .grid)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let L = lay(s), P = L.P
        switch at(s) {
        case 0: return [.drag(from: CGPoint(x: T1.bx + 15, y: T1.top + 1.5), to: CGPoint(x: 15, y: L.tenY(P.ta) + 1.5))]
        case 1:
            let g = P.bo - 1, fx = T1.bx + A1.x(g) + 1.5
            let tx = A1.x(L.held) + 1.5 + A1.x(g - L.m)
            return [.drag(from: CGPoint(x: fx, y: L.bOy + 1.5), to: CGPoint(x: tx, y: L.holdY + 1.5))]
        case 2: return DigitPad.demo(P.sum, x: T1.bx, y: T1.padY, .grid)
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = parts(s)
        switch at(s) {
        case 0: return HandMove(hand: [:], missHand: [:], set: [("t", -1)], check: true)
        case 1: return HandMove(hand: [:], missHand: [:], set: [("o", -1)], check: true)
        case 2:
            let slip = P.slips.first { $0.0 != P.sum && $0.0 >= 0 }?.0 ?? P.sum + 1
            return HandMove(hand: nil, missHand: nil, set: [("x", Double(slip))], keep: ["chk": Double(slip)], check: true)
        default: return nil
        }
    }
}
