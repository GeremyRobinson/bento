import SwiftUI

/// Tens and ones on the paper, as in the preview (design/prototype/grade1-ch3.html, dTensOnes). Counters 3 × 3 arrive
/// loose in rows of ten, each in its own outlined place, rows a square apart, the last row short. Tap a full row: it
/// closes into one ten (its inner lines faint and dashed, a chapter outline, 10 at its end), the tens read out beside it
/// ("1 ten, 2 tens"). Then tap or drag along the ones: each gets its number under it. Then the record beside the picture,
/// 3 tens and 4 ones is [34], written with the digit pad in its grid under the record (so a tall picture keeps its size).
///
/// Kept: "o<k>" the rows grouped, in order; "c<k>" the ones counted, in order; "chk" what was last checked. Hand while
/// the ones are held: "grab", "lx", "ly" and the ones counted so far "h<k>".
@MainActor
struct TensOnes1Lesson: PaperLesson {
    var liveKeys: Set<String> { Set(["lx", "ly"] + (0..<10).map { "h\($0)" }) }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let rx = 35.0, line = 2.0, padY = 5.0
    /// Row r's top: the tens' rows touch (a square apart, 9 tens and 9 ones showed at 63%), the ones a square under them.
    static func rowY(_ r: Int, _ t: Int) -> Double { r < t ? 3 * Double(r) : 3 * Double(t) + 1 }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        switch at(s) {
        case 2: return DigitPad.checkAt(x: Self.rx, y: Self.padY, .grid)
        case 3: return CGPoint(x: Self.rx, y: Self.padY)
        default: return nil
        }
    }

    private func counted(_ s: PaperState, held: Bool) -> [Int] {
        if !held { return KA.list(s, "c") }
        var out: [Int] = []
        while let j = s.hand["h\(out.count)"] { out.append(Int(j.rounded())) }
        return out
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = TensOnes1.Parts(s.numbers), st = at(s), t = P.t, o = P.o, R = t + (o > 0 ? 1 : 0)
        var pic = GridPen(), live = GridPen(stableIds: true)
        let grouped = st == 0 ? KA.list(s, "o") : Array(0..<t)
        let held = st == 1 && s.grabbed
        let ones = st >= 2 ? Array(0..<o) : st == 1 ? counted(s, held: held) : []
        for r in 0..<R {
            let y = Self.rowY(r, t), len = r < t ? 10 : o, g = grouped.contains(r)
            for j in 0..<len {
                if !g { pic.sketch.box("co\(r)-\(j)", pic.R(A1.x(j), y, 3, 3), .ink2, width: Sketch.stroke) }
                A1.counter(&pic, "c\(r)-\(j)", x: A1.x(j), y: y, .solid)
            }
            if g {
                for j in 1..<10 { pic.line("gd\(r)-\(j)", [(A1.x(j), y), (A1.x(j), y + 3)], .ink3, dashed: true) }
                pic.sketch.box("g\(r)", pic.R(0, y, 30, 3), .chapter, width: Sketch.stroke)
                pic.word("gl\(r)", "10", at: 30.5, y + 1.5, KK.maths.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5))
            }
        }
        // the ones as they're counted: their numbers under them
        let kept = st == 1 ? KA.list(s, "c") : ones
        for (i, j) in ones.enumerated() {
            if kept.contains(j) || !held { pic.word("cn\(j)", "\(i + 1)", at: A1.x(j) + 1.5, Self.rowY(t, t) + 3.5 + 1, KK.lit) }
            else { live.word("cn\(j)", "\(i + 1)", at: A1.x(j) + 1.5, Self.rowY(t, t) + 3.5 + 1, KK.lit) }
        }
        if st < 2 {
            let k = grouped.count
            if k > 0 {
                let said = (1...k).map { Num1.pl($0, "ten", "tens") }
                let ro = st > 0 ? Num1.pl(t, "ten", "tens") : said.count > 4 ? "\(said[0]), \(said[1]) … \(said[k - 1])" : said.joined(separator: ", ")
                A1.note(&pic, "rt\(k)", ro, x: Self.rx, y: 1.5)
            }
            if !ones.isEmpty {
                let ro = Num1.run(Array(1...ones.count))
                if held && ones.count > kept.count { live.reads(ro); A1.note(&live, "ro", ro, x: Self.rx, y: Self.rowY(t, t) + 1.5) }
                else { A1.note(&pic, "ro\(ones.count)", ro, x: Self.rx, y: Self.rowY(t, t) + 1.5) }
            }
        }
        let toks: [M7.Tok] = [.n(t), .w(t == 1 ? "ten and" : "tens and"), .n(o), .w(o == 1 ? "one is" : "ones is")]
        switch st {
        case 0:
            let todo = (0..<t).filter { !grouped.contains($0) }
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: 0, w: 30, h: 3 * Double(t)) }
            if s.on("spot"), let r = todo.first { KK.hintBox(&pic, "spot", x: 0, y: Self.rowY(r, t), w: 30, h: 3) }
        case 1:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: Self.rowY(t, t), w: A1.x(o), h: 3) }
            if s.on("spot"), let j = (0..<o).first(where: { !ones.contains($0) }) { KK.hint(&pic, "spot", A1.x(j) + 1.5, Self.rowY(t, t) + 1.5, radius: 2.05) }
        case 2:
            let (v, wrong) = DigitPad.typed(s, "x", want: P.n)
            N1.record(&pic, "rec", toks, value: v, wrong: wrong, x: Self.rx, line: Self.line)
            DigitPad.draw(&pic, "pad", x: Self.rx, y: Self.padY, .grid)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: 0, w: 30, h: Self.rowY(R - 1, t) + 3) }
            if s.on("spot") { A1.note(&pic, "spot", "\(P.n)", x: Self.rx + 14, y: Self.padY + 2) }
        default:
            N1.record(&pic, "rec", toks, value: nil, wrong: false, done: P.n, x: Self.rx, line: Self.line)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, actions: st == 2 ? ["Check"] : [])
    }

    /// The row under the finger, when it's on one of the rows' counters.
    private func row(_ q: CGPoint, _ P: TensOnes1.Parts) -> Int? {
        let t = P.t, R = t + (P.o > 0 ? 1 : 0)
        guard let r = (0..<R).first(where: { q.y >= Self.rowY($0, t) - 0.3 && q.y <= Self.rowY($0, t) + 3.3 }), q.x >= -0.3, q.x <= A1.x(r < P.t ? 10 : P.o) + 0.3 else { return nil }
        return r
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = TensOnes1.Parts(s.numbers), t = P.t, o = P.o
        switch at(s) {
        case 0:
            let grouped = KA.list(s, "o")
            return Hands(tap: { q in
                guard let r = row(q, P) else { return nil }
                if r == t { return HandMove(hand: nil, missHand: nil, set: [("g", -1)], check: true) }
                if grouped.contains(r) { return HandMove(hand: nil) }
                let all = grouped.count + 1 == t
                return HandMove(hand: nil, missHand: nil, set: all ? [("g", Double(t))] : [], keep: ["o\(grouped.count)": Double(r)], check: all)
            })
        case 1:
            let kept = KA.list(s, "c")
            func one(_ q: CGPoint) -> Int? {
                guard q.y >= Self.rowY(t, t) - 0.3, q.y <= Self.rowY(t, t) + 3.3 else { return nil }
                let j = Int((q.x / 3).rounded(.down))
                return (0..<o).contains(j) ? j : nil
            }
            func done(_ list: [Int]) -> HandMove {
                var keep: Numbers = [:]
                for (i, j) in list.enumerated() { keep["c\(i)"] = Double(j) }
                let all = list.count == o
                return HandMove(hand: [:], missHand: [:], set: all ? [("c", Double(o))] : [], keep: keep, check: all)
            }
            func list(_ h: Numbers) -> [Int] { var out: [Int] = []; while let j = h["h\(out.count)"] { out.append(Int(j.rounded())) }; return out }
            return Hands(
                tap: { q in
                    if let r = row(q, P), r < t { return HandMove(hand: nil, missHand: nil, set: [("c", -1)], check: true) }
                    guard let j = one(q) else { return nil }
                    return kept.contains(j) ? HandMove(hand: nil) : done(kept + [j])
                },
                grab: { q in
                    guard row(q, P) == t else { return nil }
                    var h: Numbers = ["grab": 1, "lx": q.x, "ly": q.y]
                    var l = kept
                    if let j = one(q), !l.contains(j) { l.append(j) }
                    for (i, j) in l.enumerated() { h["h\(i)"] = Double(j) }
                    return h
                },
                drag: { q, held in
                    var h = held, l = list(held)
                    for p in N1.walk(CGPoint(x: held["lx"] ?? q.x, y: held["ly"] ?? q.y), q) { if let j = one(p), !l.contains(j) { l.append(j) } }
                    for (i, j) in l.enumerated() { h["h\(i)"] = Double(j) }
                    h["lx"] = (q.x * 2).rounded() / 2; h["ly"] = (q.y * 2).rounded() / 2
                    return h
                },
                release: { held in done(list(held)) })
        case 2: return DigitPad.hands(s, "x", want: P.n, x: Self.rx, y: Self.padY, .grid)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = TensOnes1.Parts(s.numbers), t = P.t
        switch at(s) {
        case 0:
            let grouped = KA.list(s, "o")
            return (0..<t).filter { !grouped.contains($0) }.map { .tap(.picture(CGPoint(x: 15, y: Self.rowY($0, t) + 1.5))) }
        case 1:
            let kept = KA.list(s, "c"), todo = (0..<P.o).filter { !kept.contains($0) }
            let pts = todo.map { CGPoint(x: A1.x($0) + 1.5, y: Self.rowY(t, t) + 1.5) }
            return pts.count == 1 ? [.tap(.picture(pts[0]))] : [.path(pts)]
        case 2: return DigitPad.demo(P.n, x: Self.rx, y: Self.padY, .grid)
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = TensOnes1.Parts(s.numbers)
        switch at(s) {
        case 0: return P.o > 0 ? HandMove(hand: nil, missHand: nil, set: [("g", -1)], check: true) : nil
        case 1: return HandMove(hand: nil, missHand: nil, set: [("c", -1)], check: true)
        case 2:
            let slip = P.o > 0 ? 10 * P.o + P.t : P.t
            return HandMove(hand: nil, missHand: nil, set: [("x", Double(slip))], keep: ["chk": Double(slip)], check: true)
        default: return nil
        }
    }
}
