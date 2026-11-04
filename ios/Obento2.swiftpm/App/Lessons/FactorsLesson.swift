import SwiftUI

/// Factors and multiples on the paper, as in the preview (design/prototype/grade4-ch3.html): one square is one. n squares
/// in one long row, named `1 × 20` at its end, and under it the same squares to arrange, a handle on their bottom edge.
/// Drag it down: the squares flow into that many rows (leftovers dashed), live "3 rows of 6, 2 over"; let go on the
/// rectangle with the fewest rows and it glides down out of the way, named `2 × 10`, and the squares come back as one
/// row; then the next. Then the rectangles glide up beside each other, and hops by t run along the long row, counting;
/// each numbered under where it lands; tap Yes or No; then write how many factors, the factors listed under the pairs.
@MainActor
struct FactorsLesson: PaperLesson {
    /// The long row, the squares to arrange, the rectangles once they're both found.
    static let yRow = 0.0, yW = 4.0, yF1 = 5.0
    var liveKeys: Set<String> { ["grab"] }
    static let yesNo = ["Yes", "No"]

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    /// Where the rectangles wait while the next is looked for: under the most rows the squares can take.
    private func yF0(_ P: Factors.Parts) -> Double { Self.yW + Double(P.maxR) + 2 }
    /// The rows the squares are in now (1 until the hand moves them).
    private func rows(_ s: PaperState) -> Int { Int((s.h("R") ?? 1).rounded()) }
    private func hops(_ s: PaperState, _ P: Factors.Parts) -> Int { stage(s) >= 4 ? P.hopsTo : Int((s.h("h") ?? 0).rounded()) }
    /// The record's first row (its top), in the picture's rows: under the rectangles once they've glided up.
    func recordRow(_ n: Numbers) -> Double? { Self.yF1 + Double(Factors.Parts(n).a2) + 2 }
    /// Yes and No, in the record, under its first line.
    private func choicesTop(_ n: Numbers) -> Double { (recordRow(n) ?? 0) + 3 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Factors.Parts(s.numbers), at = stage(s), n = P.n, t = P.t
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let yRow = Self.yRow, yW = Self.yW

        // the long row, named 1 × n
        for j in 0..<n { Squares.cell(&pic, "lr\(j)", Double(j), yRow) }
        pic.label("lrn", "1 × \(n)", Squares.named, .right, edge: Double(n), along: yRow + 0.5)

        // the squares to arrange (until both pairs are found): the rows the hand has made, a handle on their bottom edge
        let pairs = at <= 2 ? max(0, at - 1) : 2
        if at <= 2 {
            let R = at == 0 ? 1 : rows(s), g = Factors.arrange(n, R)
            for j in 0..<n {
                let over = j >= R * g.q, x = over ? j - R * g.q : j % g.q, y = over ? R : j / g.q
                Squares.cell(&pic, "w\(pairs)_\(j)", Double(x), yW + Double(y), over: over)
            }
            if at >= 1 {
                Squares.handle(&live, s, at: Double(g.q) / 2, yW + Double(R))
                if s.grabbed { live.reads(Factors.rows(n, R)) }
                // a hint after a second miss: where the rectangle's bottom edge goes, dashed
                if s.on("spot") {
                    let a = at == 1 ? P.a1 : P.a2
                    pic.line("ring", [(-1, yW + Double(a)), (Double(n / a) + 1, yW + Double(a))], .chapter, dashed: true)
                }
            }
        }
        // the rectangles found, each named rows × in a row: below while the next is looked for, then up side by side
        let fy = at <= 2 ? yF0(P) : Self.yF1
        var fx = 0.0
        for (k, a) in [P.a1, P.a2].prefix(pairs).enumerated() {
            let w = n / a
            for j in 0..<n { Squares.cell(&pic, "w\(k)_\(j)", fx + Double(j % w), fy + Double(j / w)) }
            pic.label("fdn\(k)", "\(a) × \(w)", Squares.named, .right, edge: fx + Double(w), along: fy + Double(a) / 2)
            fx = ((fx + Double(w) + 7) / 5).rounded(.up) * 5
        }

        // hops by t under the long row, each numbered where it lands
        if at >= 3 {
            let h = hops(s, P)
            for j in 0..<h {
                let a = Double(j * t), b = a + Double(t)
                let pts = (0...16).map { i -> (Double, Double) in let u = Double(i) / 16; return (a + Double(t) * u, yRow + 1 + sin(.pi * u) * 1.5) }
                pic.line("hop\(j)", pts, .chapter)
                pic.word("hopn\(j)", "\((j + 1) * t)", at: b, yRow + 3.3, Squares.count)
            }
            if at == 3 {
                Squares.handle(&live, s, at: Double(h * t), yRow + 1)
                if s.grabbed { live.reads("\(h) \(h == 1 ? "hop" : "hops"): \(h * t)") }
                if s.on("spot") { pic.line("ring", [(Double(n), yRow - 1), (Double(n), yRow + 3)], .chapter, dashed: true) }
            }
        }

        // the record: every pair; Yes or No; how n goes into t's; the factors; how many
        var boxes: [WorkBox] = []
        if at >= 3 {
            let pairsLine: [Record.Token] = [.n(n), .op("="), .n(1), .op("×"), .n(n), .op("="), .n(P.a1), .op("×"), .n(P.b1), .op("="), .n(P.a2), .op("×"), .n(P.b2)]
            Record.line(&rec, "r1", pairsLine, x: 0, row: 1)
            if at == 4 {
                let bad = s.h("bad").map { Int($0.rounded()) }
                Squares.choices(&rec, "yn", Self.yesNo, x: 0, y: 3, bad: bad)
            }
            if at >= 5 {
                Record.line(&rec, "r2", [.n(n), .op("="), .n(t), .op("×"), .n(P.q)] + (P.r > 0 ? [.op("+"), .n(P.r)] : []), x: 0, row: 4)
                Squares.list(&rec, "r3", P.factors, x: 0, y: 7)
                let want = P.factors.count
                Record.line(&rec, "r4", [.w("factors of"), .n(n), .op("="), at == 5 ? .box("x", cells: String(want).count) : .n(want)], x: 0, row: 10,
                            colours: at >= 6 ? [3: .chapter] : [:])
            }
            boxes = rec.boxes
        }
        let reach = max(Double(n) + 6, Double(P.hopsTo * t) + 1)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes,
                            extent: at <= 2 ? pic.R(0, 0, reach, yW + Double(P.maxR) + 1.5) : at == 3 ? pic.R(0, 0, reach, yRow + 3.5) : nil)
    }

    func messageRows(_ n: Numbers) -> Int { 1 }

    func hands(_ s: PaperState) -> Hands? {
        let P = Factors.Parts(s.numbers), at = stage(s), n = P.n, t = P.t
        switch at {
        case 1, 2:
            let R = rows(s), g = Factors.arrange(n, R), hy = Self.yW + Double(R)
            return Hands(
                grab: { q in
                    guard abs(q.y - hy) <= 1.5, q.x >= -1, q.x <= Double(max(g.q, g.L)) + 1 else { return nil }
                    return ["grab": 1, "R": Double(R), "R0": Double(R), "gy": q.y]
                },
                drag: { q, h in
                    var h = h
                    h["R"] = Double(max(1, min(P.maxR, Int(h["R0"] ?? 1) + Int((q.y - (h["gy"] ?? 0)).rounded()))))
                    return h
                },
                release: { h in
                    let r = Int((h["R"] ?? 1).rounded())
                    guard r > 1 else { return HandMove(hand: ["R": 1], missHand: nil) }
                    // a miss keeps the rows it was let go at, so the leftovers show why
                    return HandMove(hand: ["R": Double(r)], missHand: nil, set: [("x", Double(r))], check: true)
                })
        case 3:
            let h = hops(s, P)
            return Hands(
                grab: { q in abs(q.x - Double(h * t)) <= 2 && abs(q.y - (Self.yRow + 1)) <= 2.5 ? ["grab": 1, "h": Double(h)] : nil },
                drag: { q, _ in ["grab": 1, "h": Double(max(0, min(P.hopsTo, Int((q.x / Double(t)).rounded()))))] },
                release: { hd in
                    let k = Int((hd["h"] ?? 0).rounded())
                    guard k > 0 else { return HandMove(hand: ["h": 0], missHand: nil) }
                    return HandMove(hand: ["h": Double(k)], missHand: nil, set: [("x", Double(k))], check: true)
                })
        case 4:
            let top = choicesTop(s.numbers)
            return Hands(tap: { q in
                guard let i = Squares.choice(at: CGPoint(x: q.x, y: q.y - top + 3), Self.yesNo, x: 0, y: 3) else { return nil }
                return HandMove(hand: [:], missHand: ["bad": Double(i)], set: [("c", Double(i))], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Factors.Parts(s.numbers), at = stage(s), n = P.n
        switch at {
        case 1, 2:
            let R = rows(s), a = at == 1 ? P.a1 : P.a2, g = Factors.arrange(n, R)
            return [.drag(from: CGPoint(x: Double(g.q) / 2, y: Self.yW + Double(R)), to: CGPoint(x: Double(g.q) / 2, y: Self.yW + Double(a)))]
        case 3:
            let h = hops(s, P)
            return [.drag(from: CGPoint(x: Double(h * P.t), y: Self.yRow + 1), to: CGPoint(x: Double(P.hopsTo * P.t), y: Self.yRow + 1))]
        case 4:
            let r = Squares.choiceRects(Self.yesNo, x: 0, y: choicesTop(s.numbers))[P.isMultiple ? 0 : 1]
            return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Factors.Parts(s.numbers), at = stage(s)
        switch at {
        case 1, 2:
            // rows that leave some over
            let r = (2...P.maxR).first { Factors.arrange(P.n, $0).L > 0 } ?? 2
            return HandMove(hand: ["R": Double(r)], missHand: nil, set: [("x", Double(r))], check: true)
        case 3:
            let h = max(1, P.hopsTo - 1)
            return HandMove(hand: ["h": Double(h)], missHand: nil, set: [("x", Double(h))], check: true)
        case 4:
            let i = P.isMultiple ? 1 : 0
            return HandMove(hand: [:], missHand: ["bad": Double(i)], set: [("c", Double(i))], check: true)
        default: return nil
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? { stage(s) == 5 ? ["x": 3] : nil }
}
