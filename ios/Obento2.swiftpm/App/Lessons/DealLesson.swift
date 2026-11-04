import SwiftUI

/// Dividing with remainders and Dividing big numbers on the paper, as in the preview (design/prototype/grade4-ch2.html):
/// the place chart (1-square cells), the number's disks in frames on top, named at its right; under them dv rows, dashed,
/// numbered down the left (a row is a friend). From the biggest place down: a place with fewer than dv opens (tap each
/// disk: it opens into a full frame of ten of the next place); a place with enough is dealt (drag it down: one to each
/// row, round after round, the count under it running "1 each · 3 left"); what's left opens. A row's share sits in a
/// plain row, so each column's shares make an array. The record, beside the chart: Dividing with remainders writes the
/// take-aways with each share beside them; Dividing big numbers the long division as school writes it. The answer is
/// typed over the bracket, read across one row; a story's answer under it.
@MainActor
struct DealLesson: PaperLesson {
    /// Dividing big numbers (the long division record, the share's zeros).
    let big: Bool
    static let top = 0.0, y0 = 3.0, x0 = 2.0
    var liveKeys: Set<String> { ["grab"] }
    private static let count = Sketch.Words(size: Sketch.small, weight: .medium, colour: .chapter)
    private static let dim = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)
    private static let red = Sketch.Colour.hex(0xC8372D, 0xFF6B5E)
    private static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2)

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func phase(_ s: PaperState) -> Int { Int((s.picture["ph"] ?? 0).rounded()) }
    private func plan(_ n: Numbers) -> Deal.Plan { big ? DivideBig.Parts(n).plan : DivideRemainders.Parts(n).plan }

    /// Where everything goes: the chart, the frames' band (tall enough for the most disks a column holds), the rows.
    @MainActor struct Shape {
        let plan: Deal.Plan, ch: PlaceChart, bandH: Double
        init(_ plan: Deal.Plan) {
            self.plan = plan
            ch = PlaceChart(n: plan.D, c: 1, pr: 2, x0: DealLesson.x0, y0: DealLesson.y0)
            let frames = max(1, (plan.most + 9) / 10)
            bandH = Double((frames + 1) / 2 - 1) * 3 + 2
        }
        var rowsTop: Double { DealLesson.y0 + bandH + 2 }
        func rowY(_ j: Int) -> Double { rowsTop + Double(j) }
        var bottom: Double { rowsTop + Double(plan.dv) }
    }

    /// The chart after some phases (and part of the next): each place's disks on top, in frame order, and each row's
    /// dealt disks. A disk keeps its id wherever it goes, so it glides; a disk that opens is drawn with its ten (and
    /// theirs) stacked on it until it does, so they glide apart into their frame.
    struct State {
        var top: [[String]], rows: [[[String]]]
        static func kids(_ id: String) -> [String] { (0..<10).map { "\(id)>\($0)" } }

        init(_ plan: Deal.Plan, done k: Int, opened: Set<Int> = [], rounds: Int = 0) {
            top = (0..<plan.D).map { p in (0..<BigNumbers.digit(plan.n, p)).map { "d\(p).\($0)" } }
            rows = (0..<plan.D).map { _ in Array(repeating: [], count: plan.dv) }
            for (i, ph) in plan.phases.enumerated() where i <= k && i < plan.phases.count {
                let whole = i < k
                switch ph {
                case .deal(let p): deal(p, whole ? plan.shares[p] - rows[p][0].count : rounds, plan.dv)
                case .open(let p, _): open(p, whole ? Set(top[p].indices) : opened)
                }
            }
        }
        mutating func deal(_ p: Int, _ r: Int, _ dv: Int) {
            guard r > 0 else { return }
            let take = Array(top[p].suffix(r * dv).reversed())
            for (i, id) in take.enumerated() { rows[p][i % dv].append(id) }
            top[p].removeLast(r * dv)
        }
        /// The disks opened (by their place in the column) open into frames of ten at the front of the next column.
        mutating func open(_ p: Int, _ which: Set<Int>) {
            let ids = top[p].indices.filter(which.contains).map { top[p][$0] }
            top[p - 1] = ids.flatMap(State.kids) + top[p - 1]
            top[p] = top[p].indices.filter { !which.contains($0) }.map { top[p][$0] }
        }
    }

    /// Every disk that opens in the problem (the same whatever order they're tapped in), and what's stacked on one.
    private func opens(_ plan: Deal.Plan) -> Set<String> {
        var out: Set<String> = []
        for (k, ph) in plan.phases.enumerated() { if case .open(let p, _) = ph { out.formUnion(State(plan, done: k).top[p]) } }
        return out
    }
    private func stacked(_ id: String, _ opens: Set<String>) -> [String] {
        guard opens.contains(id) else { return [] }
        return State.kids(id).flatMap { [$0] + stacked($0, opens) }
    }

    private func opened(_ s: PaperState) -> Set<Int> { Set((0..<Int((s.h("n") ?? 0).rounded())).map { Int((s.h("o\($0)") ?? 0).rounded()) }) }
    private func rounds(_ s: PaperState) -> Int { Int((s.h("r") ?? 0).rounded()) + Int((s.h("dr") ?? 0).rounded()) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let plan = self.plan(s.numbers), S = Shape(plan), ch = S.ch, at = stage(s), dv = plan.dv
        let working = at == 1, k = working ? phase(s) : plan.phases.count
        let ph: Deal.Phase? = working && plan.phases.indices.contains(k) ? plan.phases[k] : nil
        let st = State(plan, done: k, opened: working ? opened(s) : [], rounds: working ? rounds(s) : 0)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let cur = ph?.place

        // the chart: frames enough for each column's disks, the columns, the places' names
        ch.draw(&pic, "ch", bands: [(Self.y0, { p in max(1, (st.top[p].count + 9) / 10) })], top: Self.top, bottom: S.bottom + 1, lit: cur)
        pic.word("name", BigNumbers.commas(plan.n), at: ch.right + 0.5, Self.y0 + 1, Record.maths, anchor: UnitPoint(x: 0, y: 0.5))
        // the rows: dashed, numbered down the left
        for j in 0...dv { pic.line("row\(j)", [(ch.x0, S.rowY(j)), (ch.right, S.rowY(j))], .ink3, dashed: true) }
        for j in 0..<dv { pic.word("rown\(j)", "\(j + 1)", at: ch.x0 - 0.5, S.rowY(j) + 0.5, Self.small, anchor: UnitPoint(x: 1, y: 0.5)) }
        // the disks: on top in their frames (with what will open out of them stacked on them), dealt in plain rows
        let op = opens(plan)
        for p in 0..<plan.D {
            for (j, id) in st.top[p].enumerated() {
                let at = ch.slot(p, j)
                for d in [id] + stacked(id, op) { ch.disk(&pic, d, at: at) }
            }
            for (j, row) in st.rows[p].enumerated() {
                for (i, id) in row.enumerated() { ch.disk(&pic, id, at: CGPoint(x: ch.colX(p) + Double(i) + 0.5, y: S.rowY(j) + 0.5)) }
            }
        }
        // what's left after the ones are dealt: outlined dashed
        if !working, at >= 2, plan.r > 0 {
            let f = ch.frame(0, 0), w = Double(min(plan.r, 5)), h = plan.r > 5 ? 2.0 : 1
            pic.sketch.box("leftover", pic.R(f.x - 0.25, f.y - 0.25, w + 0.5, h + 0.5), .chapter, width: Sketch.stroke, dashed: true)
        }
        // the counts under the chart: each dealt column's share; the column being dealt, live; the column being opened into
        for p in 0..<plan.D {
            let sh = st.rows[p][0].count
            if case .deal(let d)? = ph, d == p {
                let left = st.top[p].count, over = (s.h("over") ?? 0) != 0
                let txt = over ? (left > 0 ? "Only \(left) \(BigNumbers.place(p, left)) left: not enough for \(dv) rows." : "No \(BigNumbers.places[p]) left to deal.")
                    : "\(sh) each · \(left) left"
                // what's dealt, under the column; too many rounds asked for, what's wrong, from the chart's left edge
                if over { pic.word("dl\(p)", txt, at: ch.x0, S.bottom + 2.2, Sketch.Words(size: Sketch.small, weight: .medium, colour: Self.red), anchor: UnitPoint(x: 0, y: 0.5)) }
                else { pic.label("dl\(p)", txt, Self.count, .below, edge: S.bottom + 1, along: ch.mid(p)) }
                if s.grabbed { live.reads("\(sh) each · \(left) left") }
            } else if sh > 0 {
                pic.label("sh\(p)", "\(sh) each", Self.dim, .below, edge: S.bottom + 1, along: ch.mid(p))
            }
        }
        if case .open(let p, _)? = ph, !st.top[p - 1].isEmpty {
            let c = st.top[p - 1].count
            pic.label("oc\(p)", "\(c) \(BigNumbers.place(p - 1, c))", Self.count, .below, edge: S.bottom + 1, along: ch.mid(p - 1))
        }
        // a hint: the column to deal, or the next disk to open, ringed
        if let ph, s.on("ring") {
            switch ph {
            case .deal(let p):
                let b = ch.bottom(frames: max(1, (st.top[p].count + 9) / 10))
                pic.sketch.box("ring", pic.R(ch.colX(p) + 0.25, Self.y0 - 0.5, ch.cw - 0.5, b - Self.y0 + 1), .chapter, width: Sketch.stroke, dashed: true)
            case .open(let p, _):
                // the column to open a disk in (a first miss), then the disk (a second)
                if !st.top[p].isEmpty, s.on("spot") { let c = ch.slot(p, st.top[p].count - 1); pic.circle("ring", at: c.x, c.y, radius: ch.r + 0.5, .chapter, dashed: true) }
                else if !st.top[p].isEmpty { ch.ringColumn(&pic, "ringc", p, top: Self.y0, bottom: ch.bottom(frames: max(1, (st.top[p].count + 9) / 10))) }
            }
        }

        // the record: the divisor, its bracket, the number; the take-aways as the deals are made; the answer over it
        let xr = 3 + 2 * Double(String(plan.n).count), ya = 1.0, yd = 3.0
        rec.word("dv", "\(dv)", at: 1, yd, Record.maths)
        rec.line("brk", [(2.1, 4), (2.45, 3.3), (2.55, 2.6), (2.45, 2), (xr + 0.5, 2)], .ink)
        Record.number(&rec, "nn", plan.n, right: xr, row: yd)
        let doneK = working ? k : plan.phases.count
        var y = yd, sofar = 0
        for (i, e) in plan.log.enumerated() where plan.logAt[i] <= doneK {
            // written once its deal is done; what's left under it once the next place starts
            let ty = yd + 2 + 4 * Double(i), dy = ty + 2
            let next = plan.logAt[i] < plan.phases.count ? plan.phases[plan.logAt[i]] : nil
            var shown = doneK > plan.logAt[i] || doneK == plan.phases.count
            if case .open(let p, false)? = next, p == e.p { shown = doneK > plan.logAt[i] + 1 || doneK == plan.phases.count }
            if !big {
                let take = dv * e.s * BigNumbers.pow10(e.p), share = e.s * BigNumbers.pow10(e.p)
                sofar += take
                Record.number(&rec, "tk\(i)", take, right: xr, row: ty)
                rec.word("tkm\(i)", "−", at: xr - 2 * Double(String(take).count) - 1.5, ty, Record.maths)
                Record.number(&rec, "bs\(i)", share, right: xr + 3 + 2 * Double(String(share).count), row: ty, .chapter)
                rec.rule("tkr\(i)", from: xr - 2 * Double(String(plan.n).count) - 0.5, to: xr, row: ty + 1)
                if shown { Record.number(&rec, "df\(i)", plan.n - sofar, right: xr, row: dy) }
            } else {
                let take = dv * e.s, atx = xr - 2 * Double(e.p), left = e.part - take
                Record.number(&rec, "tk\(i)", take, right: atx, row: ty)
                rec.word("tkm\(i)", "−", at: atx - 2 * Double(String(take).count) - 1.5, ty, Record.maths)
                rec.rule("tkr\(i)", from: atx - 2 * Double(max(String(take).count, String(e.part).count)) - 0.5, to: atx, row: ty + 1)
                if shown && e.p > 0 { Record.number(&rec, "df\(i)b", left * 10 + BigNumbers.digit(plan.n, e.p - 1), right: atx + 2, row: dy) }
                else { Record.number(&rec, "df\(i)", left, right: atx, row: dy) }
            }
            y = dy
        }
        let needR = !big || plan.r > 0
        if at == 2 {
            rec.answerBox("Q", right: xr, mid: ya, per: 2, cells: String(plan.q).count, commas: true)
            if needR {
                rec.word("Rw", "R", at: xr + 1.5, ya, Record.words)
                rec.answerBox("R", right: xr + 5, mid: ya, per: 2, cells: 1)
            }
        } else if at >= 3 {
            Record.number(&rec, "Qd", plan.q, right: xr, row: ya, .chapter)
            if needR { rec.word("Rw", "R", at: xr + 1.5, ya, Record.words.colour(.chapter)); Record.number(&rec, "Rd", plan.r, right: xr + 5, row: ya, .chapter) }
        }
        // a story's answer under the working
        if !big, let story = DivideRemainders.Parts(s.numbers).story, at >= 3 {
            let row = y + 4
            if at == 3 { Record.line(&rec, "story", [.box("S", cells: String(story.answer).count), .w(story.unit)], x: 0, row: row) }
            else { Record.line(&rec, "story", [.n(story.answer), .w(story.unit)], x: 0, row: row, colours: [0: .chapter]) }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func recordBeside(_ n: Numbers) -> Double? { Self.top }
    /// Every slip fits one row across the chart and its record (a second row cost the chart its 75%).
    func messageRows(_ n: Numbers) -> Int { 1 }

    func hands(_ s: PaperState) -> Hands? {
        guard stage(s) == 1 else { return nil }
        let plan = self.plan(s.numbers), S = Shape(plan), ch = S.ch, k = phase(s)
        guard plan.phases.indices.contains(k) else { return nil }
        let ph = plan.phases[k], p = ph.place, dv = plan.dv
        let st = State(plan, done: k, opened: opened(s), rounds: rounds(s))
        let bandBottom = Self.y0 + S.bandH + 0.5
        func onColumn(_ q: CGPoint) -> Bool { ch.place(at: q.x) == p && q.y >= Self.y0 - 0.5 && q.y <= bandBottom }
        switch ph {
        case .deal:
            let had = Int((s.h("r") ?? 0).rounded()), most = State(plan, done: k, rounds: had).top[p].count / dv
            return Hands(
                grab: { q in onColumn(q) ? ["grab": 1, "r": Double(had), "dr": 0, "gy": q.y] : nil },
                drag: { q, h in
                    var h = h
                    let want = Int((max(0, q.y - (h["gy"] ?? 0)) / 1.2).rounded(.down))
                    h["dr"] = Double(min(want, most)); h["over"] = want > most ? 1 : 0
                    return h
                },
                release: { h in
                    let total = had + Int((h["dr"] ?? 0).rounded())
                    // a tap, nothing dealt: there are enough to go round
                    guard total > had else { return HandMove(hand: ["r": Double(had)], missHand: ["r": Double(had)], set: [("x", 0)], check: true) }
                    return HandMove(hand: ["r": Double(total)], missHand: ["r": Double(total)], set: [("x", Double(total))], check: true)
                })
        case .open:
            let was = opened(s)
            return Hands(
                tap: { q in
                    guard onColumn(q) else { return nil }
                    // the disk tapped (the nearest one still closed), by its place in the column when the phase began
                    let ids = State(plan, done: k).top[p]
                    @MainActor func slot(_ j: Int) -> CGPoint { st.top[p].firstIndex(of: ids[j]).map { ch.slot(p, $0) } ?? .zero }
                    guard let j = ids.indices.filter({ !was.contains($0) }).min(by: { a, b in
                        let pa = slot(a), pb = slot(b)
                        return hypot(pa.x - q.x, pa.y - q.y) < hypot(pb.x - q.x, pb.y - q.y)
                    }) else { return nil }
                    var h = s.hand
                    let n = was.count
                    h["o\(n)"] = Double(j); h["n"] = Double(n + 1)
                    let last = n + 1 == ids.count
                    return HandMove(hand: h, missHand: nil, set: last ? [("x", 1)] : [], check: last)
                },
                // dragging them down: they can't go round
                grab: { q in onColumn(q) ? ["grab": 1, "gy": q.y, "keep": 1] : nil },
                drag: { _, h in h },
                release: { _ in
                    var h = s.hand; h["grab"] = nil
                    return HandMove(hand: h, missHand: h, set: [("x", 2)], check: true)
                })
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard stage(s) == 1 else { return [] }
        let plan = self.plan(s.numbers), ch = Shape(plan).ch, k = phase(s)
        guard plan.phases.indices.contains(k) else { return [] }
        switch plan.phases[k] {
        case .deal(let p):
            let had = Int((s.h("r") ?? 0).rounded()), left = plan.shares[p] - had
            let from = CGPoint(x: ch.mid(p), y: Self.y0 + 1)
            return [.drag(from: from, to: CGPoint(x: from.x, y: from.y + 1.2 * Double(left) + 0.6))]
        case .open(let p, _):
            let st = State(plan, done: k, opened: opened(s))
            return st.top[p].indices.reversed().map { .tap(.picture(ch.slot(p, $0))) }
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard stage(s) == 1 else { return nil }
        let plan = self.plan(s.numbers), k = phase(s)
        guard plan.phases.indices.contains(k) else { return nil }
        switch plan.phases[k] {
        case .deal(let p):
            // let go a round too soon (or, with one round, a tap: there are enough)
            let r = plan.shares[p] - 1
            return HandMove(hand: ["r": Double(r)], missHand: ["r": Double(r)], set: [("x", Double(r))], check: true)
        case .open:
            return HandMove(hand: [:], missHand: [:], set: [("x", 2)], check: true)
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        guard stage(s) == 2 else { return nil }
        let plan = self.plan(s.numbers)
        if !big { let q = plan.q; return ["Q": Double(q / 10 + q % 10), "R": Double(plan.r)] }
        // a 0 left out, when the share has one
        let q = plan.q, without = Int(String(q).replacingOccurrences(of: "0", with: "")) ?? q
        return without != q ? ["Q": Double(without)] + (plan.r > 0 ? ["R": Double(plan.r)] : [:]) : nil
    }
}

private func + (a: [String: Double], b: [String: Double]) -> [String: Double] { a.merging(b) { $1 } }
