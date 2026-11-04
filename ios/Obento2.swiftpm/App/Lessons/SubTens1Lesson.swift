import SwiftUI

/// Take away tens on the paper, as in the preview (design/prototype/grade1-ch4.html, dSubTens). a as tens rows (T1's
/// stack), − b written over the place they go. Slide tens away to the right, one row at a time: each lands in the pile (a
/// dashed place shows where) and is crossed out; the rows left close up; the readout under the pile says "take 1 ten,
/// 2 tens". Then tap the rows left to count them (each gets its count at its end, not a tint: a tint under the counters flickers; sliding one more away slides back).
/// Then the record goes on along the names line, 70 − 30 = [40], written with the digit pad under it all (or in its grid
/// under the rows left, when that's shorter).
///
/// Hand: "grab", "r" the row grabbed, "dx", "dy". Kept: "t<k>" the rows taken, in order; "c<k>" the rows counted; the last
/// row let go "lr", "lx", "ly" (its top-left then); "chk" what was last checked.
@MainActor
struct SubTens1Lesson: PaperLesson {
    var liveKeys: Set<String> { ["dx", "dy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    private func taken(_ s: PaperState, _ P: SubTens1.Parts) -> [Int] {
        let t = KA.list(s, "t")
        if at(s) == 0 { return t }
        // every step after the take: the first B rows taken (as the child took them, while they're kept)
        return t.count == P.B ? t : Array((P.L)..<P.A)
    }
    private func left(_ s: PaperState, _ P: SubTens1.Parts) -> [Int] { let t = taken(s, P); return (0..<P.A).filter { !t.contains($0) } }
    private func rowY(_ i: Int) -> Double { T1.top + 3 * Double(i) }

    /// The pad: in the left column under the rows left when it fits beside the pile, else a row under everything.
    private func pad(_ P: SubTens1.Parts) -> (x: Double, y: Double, layout: DigitPad.Layout) {
        let M = max(P.L, P.B), padA = rowY(P.L) + 4, padB = rowY(P.B) + 4
        if padA + 19 <= rowY(M) + 8 { return (0, padA, .grid) }
        // many tens left and few taken: the grid under the pile keeps the problem 75% or more (a row under 8 tens was 73%)
        if padB + 19 < rowY(M) + 8 { return (T1.bx, padB, .grid) }
        return (0, rowY(M) + 4, .row)
    }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let p = pad(SubTens1.Parts(s.numbers))
        switch at(s) {
        case 2: return DigitPad.checkAt(x: p.x, y: p.y, p.layout)
        case 3: return CGPoint(x: p.x, y: p.y)
        default: return nil
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = SubTens1.Parts(s.numbers), st = at(s)
        var pic = GridPen(), live = GridPen(stableIds: true)
        let tk = taken(s, P), lf = left(s, P), counted = st == 1 ? KA.list(s, "c") : st >= 2 ? lf : []
        let held = s.grabbed ? Int(s.h("r") ?? -1) : nil
        let dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0
        let k = s.run.kept
        // the row let go last starts where it was let go
        if let lr = k["lr"].map({ Int($0) }), held == nil {
            pic.sketch.from = T1.kinds { p in T1.ten(&p, "R\(lr)", x: k["lx"] ?? 0, y: k["ly"] ?? 0, [.solid]) }
        }
        if st == 0 { pic.sketch.box("land\(tk.count)", pic.R(T1.bx, rowY(tk.count), 30, 3), .ink3, width: Sketch.stroke, dashed: true) }
        for (i, r) in tk.enumerated() { T1.ten(&pic, "R\(r)", x: T1.bx, y: rowY(i), [.solid], cross: true) }
        for (i, r) in lf.enumerated() where r != held {
            let c = counted.firstIndex(of: r)
            T1.ten(&pic, "R\(r)", x: 0, y: rowY(i), [.solid])
            if let c, st == 1 { pic.word("cn\(r)", "\(c + 1)", at: 32.5, rowY(i) + 1.5, KK.lit) }
        }
        pic.sketch.from = [:]
        if let held, let i = lf.firstIndex(of: held) {
            T1.ten(&live, "R\(held)", x: dx, y: rowY(i) + dy, [.solid])
            if st == 0 { live.reads("take " + T1.tensRun(tk.count + 1)) }
        }
        let rx = T1.names(&pic, P.a, "−", P.b)
        // readouts: what's taken, under the pile; what's left, under the rows left
        if !tk.isEmpty {
            let ro = st == 0 ? "take " + T1.tensRun(tk.count) : "take " + Num1.pl(P.B, "ten", "tens")
            A1.note(&pic, "rp:\(ro)", ro, x: T1.bx, y: rowY(tk.count + (st == 0 ? 1 : 0)) + 1.5)
        }
        if st >= 1 && (!counted.isEmpty || P.L == 0) {
            let ro = P.L == 0 ? "0 tens" : st == 1 ? T1.tensRun(counted.count) : Num1.pl(P.L, "ten", "tens")
            A1.note(&pic, "rl:\(ro)", ro, x: 0, y: rowY(P.L) + 1.5)
        }
        let p = pad(P)
        switch st {
        case 1:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: T1.top, w: 30, h: 3 * Double(P.L)) }
            if s.on("spot"), let i = lf.firstIndex(where: { !counted.contains($0) }) { KK.hintBox(&pic, "spot", x: 0, y: rowY(i), w: 30, h: 3) }
        case 2:
            let (v, wrong) = DigitPad.typed(s, "x", want: P.res)
            N1.record(&pic, "rec", [.op("=")], value: v, wrong: wrong, x: rx, line: T1.line)
            DigitPad.draw(&pic, "pad", x: p.x, y: p.y, p.layout)
            if s.on("ring") && !s.on("spot") && P.L > 0 { KK.hintBox(&pic, "hr", x: 0, y: T1.top, w: 30, h: 3 * Double(P.L)) }
            if s.on("spot") {
                if p.layout == .grid { A1.note(&pic, "spot", "\(P.res)", x: p.x + 14, y: p.y + 2) }
                else { A1.note(&pic, "spot", "\(P.res)", x: DigitPad.width + 13.5, y: p.y + 2) }
            }
        case 3:
            N1.record(&pic, "rec", [.op("=")], value: nil, wrong: false, done: P.res, x: rx, line: T1.line)
        default: break
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, actions: st == 2 ? ["Check"] : [])
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = SubTens1.Parts(s.numbers), st = at(s)
        let tk = taken(s, P), lf = left(s, P)
        func row(_ q: CGPoint) -> Int? {
            guard q.x >= -0.3, q.x <= 30.3 else { return nil }
            return lf.indices.first { q.y >= rowY($0) - 0.3 && q.y <= rowY($0) + 3.3 }.map { lf[$0] }
        }
        switch st {
        case 0, 1:
            let counted = KA.list(s, "c")
            return Hands(
                tap: { q in
                    guard st == 1, let r = row(q), !counted.contains(r) else { return nil }
                    let all = counted.count + 1 == P.L
                    return HandMove(hand: nil, missHand: nil, set: all ? [("c", Double(P.L))] : [], keep: ["c\(counted.count)": Double(r)], check: all)
                },
                grab: { q in row(q).map { ["grab": 1, "r": Double($0), "gx": q.x, "gy": q.y, "dx": 0, "dy": 0] } },
                drag: { q, held in
                    var h = held
                    h["dx"] = (q.x - (held["gx"] ?? q.x)).rounded(); h["dy"] = (q.y - (held["gy"] ?? q.y)).rounded()
                    return h
                },
                release: { held in
                    let r = Int(held["r"] ?? 0), dx = held["dx"] ?? 0, dy = held["dy"] ?? 0
                    let i = lf.firstIndex(of: r) ?? 0
                    let keep: Numbers = ["lr": Double(r), "lx": dx, "ly": rowY(i) + dy]
                    // not slid away far enough: back it goes
                    guard dx >= 8 else { return HandMove(hand: [:], keep: keep) }
                    if st == 1 { return HandMove(hand: [:], missHand: [:], set: [("c", -1)], keep: keep, check: true) }
                    var kp = keep; kp["t\(tk.count)"] = Double(r)
                    let all = tk.count + 1 == P.B
                    return HandMove(hand: [:], missHand: [:], set: all ? [("k", Double(P.B))] : [], keep: kp, check: all)
                })
        case 2:
            let p = pad(P)
            return DigitPad.hands(s, "x", want: P.res, x: p.x, y: p.y, p.layout)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = SubTens1.Parts(s.numbers)
        switch at(s) {
        case 0:
            let n = taken(s, P).count
            return (n..<P.B).map { k in .drag(from: CGPoint(x: 15, y: T1.top + 1.5), to: CGPoint(x: T1.bx + 15, y: rowY(k) + 1.5)) }
        case 1:
            let counted = KA.list(s, "c"), lf = left(s, P)
            return lf.indices.filter { !counted.contains(lf[$0]) }.map { .tap(.picture(CGPoint(x: 15, y: rowY($0) + 1.5))) }
        case 2: let p = pad(P); return DigitPad.demo(P.res, x: p.x, y: p.y, p.layout)
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = SubTens1.Parts(s.numbers)
        switch at(s) {
        case 1: return HandMove(hand: [:], missHand: [:], set: [("c", -1)], check: true)
        case 2:
            let slip = P.L > 0 ? P.L : P.a + P.b
            return HandMove(hand: nil, missHand: nil, set: [("x", Double(slip))], keep: ["chk": Double(slip)], check: true)
        default: return nil
        }
    }
}
