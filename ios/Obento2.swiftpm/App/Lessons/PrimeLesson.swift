import SwiftUI

/// Prime or composite on the paper, as in the preview (design/prototype/grade4-ch3.html): one square is one. n squares in
/// rows of ten, named n at the right. Drag the bottom edge down to try 2 rows, 3 rows, …: the squares flow into that
/// many rows as the finger goes, leftovers dashed, live "4 rows of 12, 3 over". Let go on a full rectangle: it turns
/// green and its pair is written in the record; the squares wait for the next try (only the try is drawn, so 96's five
/// pairs never crowd the screen). The tries stop once the rows would outnumber a row's squares. Then tap Prime or
/// Composite.
@MainActor
struct PrimeLesson: PaperLesson {
    static let top = 0.0
    var liveKeys: Set<String> { ["grab"] }
    static let labels = ["Prime", "Composite"]

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// The rows tried now: 0 the rows of ten it starts in; after the tries, where they stopped.
    private func rows(_ s: PaperState, _ P: PrimeComposite.Parts) -> Int { stage(s) >= 2 ? P.stop : Int((s.h("R") ?? 0).rounded()) }
    /// The rectangles found so far (by their rows).
    private func found(_ s: PaperState, _ P: PrimeComposite.Parts) -> [Int] {
        if stage(s) >= 2 { return P.rects }
        let m = Int((s.h("f") ?? 0).rounded())
        return P.rects.filter { m & (1 << $0) != 0 }
    }
    /// The squares' rows of ten, or the try: where square j sits, and whether it's left over.
    private func place(_ P: PrimeComposite.Parts, _ R: Int, _ j: Int) -> (x: Int, y: Int, over: Bool) {
        if R == 0 { return (j % 10, j / 10, false) }
        let g = Factors.arrange(P.n, R)
        return j < R * g.q ? (j % g.q, j / g.q, false) : (j - R * g.q, R, true)
    }
    private func handle(_ P: PrimeComposite.Parts, _ R: Int) -> CGPoint {
        R == 0 ? CGPoint(x: Double(min(P.n, 10)) / 2, y: Self.top + Double((P.n + 9) / 10)) : CGPoint(x: Double(Factors.arrange(P.n, R).q) / 2, y: Self.top + Double(R))
    }
    /// The picture's rows at their most: the rows of ten, or the last try and its leftovers.
    private func bottom(_ P: PrimeComposite.Parts) -> Double { Self.top + Double(max((P.n + 9) / 10, P.stop + 1)) }
    func recordRow(_ n: Numbers) -> Double? { bottom(PrimeComposite.Parts(n)) + 2 }
    /// The record's lines of pairs, three to a line.
    private func lines(_ count: Int) -> Int { (count + 2) / 3 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = PrimeComposite.Parts(s.numbers), at = stage(s), n = P.n, R = rows(s, P), f = found(s, P)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let lit = Int((s.h("lit") ?? 0).rounded()), green = at == 1 && lit > 0 && lit == R
        for j in 0..<n {
            let p = place(P, R, j)
            Squares.cell(&pic, "p\(j)", Double(p.x), Self.top + Double(p.y), over: p.over, green: green && !p.over)
        }
        let w = R == 0 ? min(n, 10) : max(Factors.arrange(n, R).q, Factors.arrange(n, R).L)
        pic.label("pn", "\(n)", Record.maths, .right, edge: Double(w), along: Self.top + 0.5)
        if at == 1 {
            let hd = handle(P, R)
            Squares.handle(&live, s, at: hd.x, hd.y)
            if s.grabbed { live.reads(Factors.rows(n, R)) }
            // a hint: where the next rectangle's bottom edge goes (or where the tries stop), dashed
            if s.on("ring") {
                let a = P.rects.first { !f.contains($0) } ?? P.stop
                pic.line("ring", [(-1, Self.top + Double(a)), (Double(n / a) + 1, Self.top + Double(a))], .chapter, dashed: true)
            }
        }

        // the record: every pair found, three to a line; Prime or Composite; then which it is
        let prs = [(1, n)] + f.map { ($0, n / $0) }
        let digits = Double(String(n).count)
        for i in stride(from: 0, to: prs.count, by: 3) {
            var toks: [Record.Token] = [i == 0 ? .n(n) : .gap(2 * digits)]
            for (u, v) in prs[i..<min(prs.count, i + 3)] { toks += [.op("="), .n(u), .op("×"), .n(v)] }
            Record.line(&rec, "pr\(i)", toks, x: 0, row: 1 + Double(i))
        }
        let after = 3 * Double(lines(prs.count))
        if at == 2 { Squares.choices(&rec, "pc", Self.labels, x: 0, y: after, bad: s.h("bad").map { Int($0.rounded()) }) }
        if at >= 3 { rec.word("pw", P.prime ? "prime" : "composite", at: 0.5, after + 1, Record.words.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5)) }
        let reach = Double(max(10, (n + 1) / 2)) + 1 + 2 * digits
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch,
                            extent: at <= 2 ? pic.R(0, 0, reach, bottom(P)) : nil)
    }

    func messageRows(_ n: Numbers) -> Int { 1 }

    func hands(_ s: PaperState) -> Hands? {
        let P = PrimeComposite.Parts(s.numbers)
        switch stage(s) {
        case 1:
            let R = rows(s, P), hd = handle(P, R), base = s.hand
            return Hands(
                grab: { q in
                    guard abs(q.y - hd.y) <= 1.5, q.x >= -1, q.x <= 2 * hd.x + 1 else { return nil }
                    var h = base; h["grab"] = 1; h["lit"] = 0
                    let r = max(2, R); h["R"] = Double(r); h["R0"] = Double(r); h["gy"] = q.y
                    return h
                },
                drag: { q, h in
                    var h = h
                    h["R"] = Double(max(2, min(P.stop, Int(h["R0"] ?? 2) + Int((q.y - (h["gy"] ?? 0)).rounded()))))
                    return h
                },
                release: { h in
                    var out = h; out["grab"] = nil; out["R0"] = nil; out["gy"] = nil
                    let r = Int((h["R"] ?? 2).rounded())
                    var m = Int((h["f"] ?? 0).rounded())
                    if r < P.stop && Factors.arrange(P.n, r).L == 0 { m |= 1 << r; out["lit"] = Double(r) }
                    out["f"] = Double(m)
                    // every let-go is checked: a try says what it made (grey), at the stop the tries are done or one was passed
                    return HandMove(hand: out, missHand: nil, set: [("x", Double(r)), ("f", Double(m))], check: true)
                })
        case 2:
            let top = (recordRow(s.numbers) ?? 0) + 3 * Double(lines(P.pairs.count))
            return Hands(tap: { q in
                guard let i = Squares.choice(at: q, Self.labels, x: 0, y: top) else { return nil }
                return HandMove(hand: [:], missHand: ["bad": Double(i)], set: [("c", Double(i))], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = PrimeComposite.Parts(s.numbers)
        switch stage(s) {
        case 1:
            // let go on each rectangle not found yet, then where the tries stop
            var R = rows(s, P), out: [GhostMove] = []
            let f = found(s, P)
            for a in P.rects.filter({ !f.contains($0) }) + [P.stop] {
                let from = handle(P, R), r0 = max(2, R)
                out.append(.drag(from: from, to: CGPoint(x: from.x, y: from.y + Double(a - r0))))
                R = a
            }
            return out
        case 2:
            let top = (recordRow(s.numbers) ?? 0) + 3 * Double(lines(P.pairs.count))
            let r = Squares.choiceRects(Self.labels, x: 0, y: top)[P.prime ? 0 : 1]
            return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = PrimeComposite.Parts(s.numbers)
        switch stage(s) {
        case 1:
            // straight to where the tries stop, a rectangle passed (a prime has none to pass: a try that leaves some over)
            if P.prime { let r = 2; return HandMove(hand: ["R": Double(r)], missHand: nil, set: [("x", Double(r)), ("f", 0)], check: true) }
            return HandMove(hand: ["R": Double(P.stop)], missHand: nil, set: [("x", Double(P.stop)), ("f", 0)], check: true)
        case 2:
            let i = P.prime ? 1 : 0
            return HandMove(hand: [:], missHand: ["bad": Double(i)], set: [("c", Double(i))], check: true)
        default: return nil
        }
    }
}
