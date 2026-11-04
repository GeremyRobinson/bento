import SwiftUI

/// Tens, hundreds, thousands on the paper, as in the preview (design/prototype/grade4-ch1.html): the place chart with the
/// columns the problem needs. A (how many tens make 340?): each hundred is a disk; tap it and it opens where it stands
/// into a full frame of ten tens, the count under the tens running on ("14 tens", "24 tens", "34 tens"); then write the
/// count. B (what number is 52 hundreds?): tap each full frame of ten; it closes into one disk that slides into the
/// thousands; then write the number. The record: 340 = 34 tens = 34 × 10, or 52 hundreds = 5 thousands and 2 hundreds
/// = 5,200; the last words say why.
@MainActor
struct TensHundredsLesson: PaperLesson {
    /// The chart's names on rows 0–3, its frames from row 3.
    static let top = 0.0, y0 = 3.0
    private static let count = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .chapter)

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    @MainActor
    struct Shape {
        let p: TensHundreds.Parts, chart: PlaceChart, frames: Int, bottom: Double
        var tall: Bool { bottom > 26 }
        init(_ n: Numbers) {
            p = TensHundreds.Parts(n)
            frames = (p.c + 9) / 10
            // past 3 frames down one column, 1-square cells two frames across (G 3 Nov: the camera rarely goes under
            // 75%; 50 thousands in 2-square cells was seen at 67%)
            let big = PlaceChart.sized(n: p.columns, frames: frames, y0: TensHundredsLesson.y0)
            chart = big.c == 2 && big.pr == 1 && frames > 3 ? PlaceChart(n: p.columns, c: 1, pr: 2, y0: TensHundredsLesson.y0) : big
            bottom = chart.bottom(frames: frames) + 1
        }
        /// Frames drawn in each column: the place's as many rows as its disks need, the others one row.
        func framesIn(_ pw: Int) -> Int { pw == p.q ? ((frames + chart.pr - 1) / chart.pr) * chart.pr : chart.pr }
    }

    /// The order the disks were opened (A) or frames closed (B): from the hand on the move, kept after it.
    private func order(_ s: PaperState, _ P: TensHundreds.Parts) -> [Int] {
        let at = stage(s)
        if at <= 1 { return (0..<Int((s.h("n") ?? 0).rounded())).map { Int((s.h("o\($0)") ?? 0).rounded()) } }
        let kept = (0..<P.h).compactMap { s.run.kept["o\($0)"].map { Int($0.rounded()) } }
        return kept.count == P.h ? kept : Array(0..<P.h)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let S = Shape(s.numbers), P = S.p, ch = S.chart, q = P.q, at = stage(s), done = order(s, P)
        var pic = GridPen(), rec = GridPen()
        ch.draw(&pic, "ch", bands: [(Self.y0, S.framesIn)], top: Self.top, bottom: S.bottom)
        if P.a {
            // the place up: a disk each, ten disks stacked in it until it opens into its frame of ten
            for j in 0..<P.h {
                let m = done.firstIndex(of: j)
                for i in 0..<10 {
                    let at = m.map { ch.slot(q, $0 * 10 + i) } ?? ch.slot(q + 1, j)
                    ch.disk(&pic, "u\(j).\(i)", at: at)
                }
            }
            // the place's own disks, after the frames opened
            for i in 0..<P.r { ch.disk(&pic, "l\(i)", at: ch.slot(q, done.count * 10 + i)) }
            if at < 3 {
                let k = 10 * done.count + P.r
                pic.label("cnt\(k)", "\(k) \(BigNumbers.place(q, k))", Self.count, .below, edge: S.bottom, along: ch.mid(q))
            }
            // a hint: the column to open a disk in (a first miss), then the next disk itself (a second)
            if at == 1, s.on("spot"), let j = (0..<P.h).first(where: { !done.contains($0) }) {
                let c = ch.slot(q + 1, j)
                pic.circle("ring", at: c.x, c.y, radius: ch.r + 0.6, .chapter, dashed: true)
            } else if at == 1, s.on("ring") { ch.ringColumn(&pic, "ringc", q + 1, top: Self.y0, bottom: S.bottom) }
        } else {
            // the place's disks; each full frame closed glides into the place up as one disk
            let left = (0..<P.c).filter { !done.contains($0 / 10) }
            for i in 0..<P.c {
                if let m = done.firstIndex(of: i / 10) { ch.disk(&pic, "d\(i)", at: ch.slot(q + 1, m)) }
                else { ch.disk(&pic, "d\(i)", at: ch.slot(q, left.firstIndex(of: i) ?? 0)) }
            }
            if at < 3, !done.isEmpty {
                pic.label("cnt\(done.count)", "\(done.count) \(BigNumbers.place(q + 1, done.count))", Self.count, .below, edge: S.bottom, along: ch.mid(q + 1))
            }
            if at == 1, s.on("ring"), left.count >= 10 {
                let f = ch.frame(q, 0)
                pic.sketch.box("ring", pic.R(f.x - 0.5, f.y - 0.5, 5 * ch.c + 1, 2 * ch.c + 1), .chapter, width: Sketch.stroke, dashed: true)
            }
        }

        // the record: written once the hands have found it
        var boxes: [WorkBox] = []
        if at >= 2 {
            let c: Sketch.Colour = .chapter, name = P.name
            var lines: [[Record.Token]] = [], colours: [[Int: Sketch.Colour]] = []
            if at == 2 {
                lines = [P.a ? [.n(P.N), .op("="), .box("x", cells: String(P.c).count), .w(name)] : [.n(P.c), .w(name), .op("="), .box("x", cells: String(P.N).count)]]
                colours = [[:]]
            } else if P.a {
                let a1: [Record.Token] = [.n(P.N)], a2: [Record.Token] = [.op("="), .n(P.c), .w(name)], a3: [Record.Token] = [.op("="), .n(P.c), .op("×"), .n(P.p)]
                if S.tall { lines = [a1, a2, a3]; colours = [[:], [1: c], [:]] } else { lines = [a1 + a2 + a3]; colours = [[2: c]] }
            } else {
                let up = BigNumbers.place(q + 1, P.h)
                let b1: [Record.Token] = [.n(P.c), .w(name)], b2: [Record.Token] = [.op("="), .n(P.h), .w(up)]
                let b3: [Record.Token] = P.r > 0 ? [.w("and"), .n(P.r), .w(BigNumbers.place(q, P.r))] : [], b4: [Record.Token] = [.op("="), .n(P.N)]
                if S.tall {
                    lines = [b1, b2] + (P.r > 0 ? [[.gap(3)] + b3] : []) + [b4]
                    colours = lines.indices.map { $0 == lines.count - 1 ? [1: c] : [:] }
                } else { lines = [b1 + b2 + b3 + b4]; colours = [[b1.count + b2.count + b3.count + 1: c]] }
            }
            for (i, l) in lines.enumerated() { Record.line(&rec, "rec\(at)\(i)", l, x: 0, row: 1 + 3 * Double(i), colours: colours[i]) }
            boxes = rec.boxes
        }
        return PaperDrawing(picture: pic.sketch, record: rec.sketch, boxes: boxes)
    }

    /// A tall chart (more than a screen's rows of frames) keeps its record beside it, level with its frames.
    func recordBeside(_ n: Numbers) -> Double? { Shape(n).tall ? Self.y0 : nil }

    func hands(_ s: PaperState) -> Hands? {
        guard stage(s) == 1 else { return nil }
        let S = Shape(s.numbers), P = S.p, ch = S.chart, q = P.q, done = order(s, P)
        return Hands(tap: { pt in
            guard pt.y > Self.y0 - 0.5, pt.y < S.bottom, let pw = ch.place(at: pt.x) else { return nil }
            var h = s.hand
            if P.a {
                if pw == q { return HandMove(hand: nil, missHand: nil, set: [("x", -1)], check: true) }
                guard pw == q + 1 else { return nil }
                // the disk nearest the finger that hasn't opened
                guard let j = (0..<P.h).filter({ !done.contains($0) }).min(by: { a, b in
                    let pa = ch.slot(q + 1, a), pb = ch.slot(q + 1, b)
                    return hypot(pa.x - pt.x, pa.y - pt.y) < hypot(pb.x - pt.x, pb.y - pt.y)
                }) else { return nil }
                h["o\(done.count)"] = Double(j); h["n"] = Double(done.count + 1)
                let last = done.count + 1 == P.h
                return HandMove(hand: h, missHand: nil, set: last ? [("x", Double(P.h))] : [], keep: last ? h.filter { $0.key.hasPrefix("o") } : [:], check: last)
            }
            guard pw == q else { return nil }
            // the frame tapped among those standing now: a full one closes, a part one is a miss
            let left = (0..<P.c).filter { !done.contains($0 / 10) }
            guard let k = ch.frame(at: pt, q, count: (left.count + 9) / 10) else { return nil }
            let inFrame = min(10, left.count - k * 10)
            guard inFrame == 10 else { return HandMove(hand: nil, missHand: nil, set: [("x", -Double(inFrame))], check: true) }
            h["o\(done.count)"] = Double(left[k * 10] / 10); h["n"] = Double(done.count + 1)
            let last = done.count + 1 == P.h
            return HandMove(hand: h, missHand: nil, set: last ? [("x", Double(P.h))] : [], keep: last ? h.filter { $0.key.hasPrefix("o") } : [:], check: last)
        })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard stage(s) == 1 else { return [] }
        let S = Shape(s.numbers), P = S.p, ch = S.chart, done = order(s, P)
        if P.a { return (0..<P.h).filter { !done.contains($0) }.map { .tap(.picture(ch.slot(P.q + 1, $0))) } }
        return (done.count..<P.h).map { _ in .tap(.picture(ch.centre(P.q, 0))) }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard stage(s) == 1 else { return nil }
        let P = TensHundreds.Parts(s.numbers)
        if P.a { return HandMove(hand: nil, missHand: nil, set: [("x", -1)], check: true) }
        return P.r > 0 ? HandMove(hand: nil, missHand: nil, set: [("x", -Double(P.r))], check: true) : nil
    }
}
