import SwiftUI

/// Add and subtract big numbers on the paper, as in the preview (design/prototype/grade4-ch1.html): the column way, ones
/// first. The place chart (five columns, or six when the answer needs them), 2-square disks: the first number's in the
/// top band (two frames to a column), the second's (striped) in a band under it. A column at a time from the ones (the
/// thousands and up together): slide the striped disks up. Adding, they snap in after the top's; ten or more, tap the
/// full ten and it closes into one disk that slides into the next column (the carried 1). Taking away, each lands on one
/// of the top's and crosses it out; too few on top, open a ten from the next column first: it opens into a full frame.
/// The record under the chart is the column working, written as the hands go (carries and trades small); the thousands
/// and up are typed.
@MainActor
struct AddSubBigLesson: PaperLesson {
    /// The chart: names from row 0, the top band's frames from 3 (and 8), the second number's from 13, the columns'
    /// lines down to 18. Six columns take 1-square cells, a band's two frames side by side: the top band on 3, the second
    /// number's on 7, the lines down to 10 (G 3 Nov: the camera rarely goes under 75%; six columns of 2-square cells were
    /// seen at 66% to 70%, under or beside).
    static let top = 0.0
    struct Geo { let ch: PlaceChart, yT: Double, yB: Double, yEnd: Double
        /// The top band's rows (a tap there opens a ten).
        var topEnd: Double { ch.c == 2 ? yT + 7.5 : yT + 2.5 }
    }
    static func geo(_ P: AddSubBig.Parts) -> Geo {
        let n = columns(P)
        if n <= 5 { return Geo(ch: PlaceChart(n: n, c: 2, pr: 1, y0: 3), yT: 3, yB: 13, yEnd: 18) }
        return Geo(ch: PlaceChart(n: n, c: 1, pr: 2, y0: 3), yT: 3, yB: 7, yEnd: 10)
    }
    /// The record: what's carried or traded on row 2, a on 4, b on 6, the rule on line 8, the answer on 10.
    static let carryRow = 2.0, aRow = 4.0, bRow = 6.0, rule = 8.0, ansRow = 10.0

    var liveKeys: Set<String> { ["dy"] }
    private static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .chapter)

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func phase(_ s: PaperState) -> Int { Int((s.picture["ph"] ?? 0).rounded()) }
    nonisolated static func columns(_ P: AddSubBig.Parts) -> Int { max(5, BigNumbers.length(P.R), P.length) }
    static func chart(_ P: AddSubBig.Parts) -> PlaceChart { geo(P).ch }

    /// One disk on the chart, or several stacked as one (ten closed, or a disk about to open into ten).
    /// Each disk keeps its own look as it moves, so it glides; a closed ten is its ten disks stacked, all solid.
    struct Item { var ids: [String]; var striped: [Bool] }
    /// The chart after some moves: each column's disks in the top band (the crossed-out ones with the striped disk that
    /// took them away), the second number's still in its band, and what the record shows was carried or traded.
    struct Chart {
        var top: [[Item]], crossed: [[String?]], bottom: [[String]]
        var carried: Set<Int> = [], traded: Set<Int> = []

        init(_ P: AddSubBig.Parts, moves k: Int, opened: Bool) {
            let n = AddSubBigLesson.columns(P)
            top = (0..<n).map { pw in (0..<BigNumbers.digit(P.a, pw)).map { Item(ids: ["t\(pw).\($0)"], striped: [false]) } }
            bottom = (0..<n).map { pw in (0..<BigNumbers.digit(P.b, pw)).map { "s\(pw).\($0)" } }
            crossed = top.map { $0.map { _ in nil } }
            // taking away: the disk that opens into ten is ten stacked under it until it does
            if P.sub, top.indices.contains(P.at + 1), let last = top[P.at + 1].indices.last {
                top[P.at + 1][last].ids += (0..<10).map { "o\($0)" }
                top[P.at + 1][last].striped += Array(repeating: false, count: 10)
            }
            let phases = P.phases
            for (i, ph) in phases.prefix(k + 1).enumerated() {
                let finished = i < k
                switch ph {
                case .slide(let cols):
                    // the ten opened (on the move, or done before it)
                    if P.sub, cols.contains(P.at), (finished || opened) { open(P.at + 1) }
                    guard finished else { continue }
                    for pw in cols {
                        if P.sub {
                            // each striped disk lands on one of the top's, from the right, and crosses it out
                            let live = top[pw].indices.filter { crossed[pw][$0] == nil }
                            for (j, sid) in bottom[pw].enumerated() { crossed[pw][live[live.count - bottom[pw].count + j]] = sid }
                        } else {
                            top[pw] += bottom[pw].map { Item(ids: [$0], striped: [true]) }
                            crossed[pw] += bottom[pw].map { _ in nil }
                        }
                        bottom[pw] = []
                    }
                case .close(let pw):
                    guard finished else { continue }
                    // one disk of the next place: all ten solid (the first number's glide there; the second's, striped, come
                    // in solid with them), so the carried 1 never looks like part of the second number
                    let ten = top[pw].prefix(10).flatMap(\.ids)
                    top[pw + 1].append(Item(ids: ten, striped: ten.map { _ in false }))
                    crossed[pw + 1].append(nil)
                    top[pw].removeFirst(10); crossed[pw].removeFirst(10)
                    carried.insert(pw + 1)
                }
            }
        }
        /// The disk on top of the next column opens into a full frame of ten in this one (in front of its own).
        private mutating func open(_ from: Int) {
            guard let last = top[from].indices.last, top[from][last].ids.count > 1 else { return }
            let stack = top[from].removeLast(); crossed[from].removeLast()
            top[from - 1].insert(contentsOf: stack.ids.dropFirst().map { Item(ids: [$0], striped: [false]) }, at: 0)
            crossed[from - 1].insert(contentsOf: Array(repeating: nil, count: 10), at: 0)
            traded.insert(from - 1)
        }
        /// The disks left in a column (not crossed out).
        func left(_ pw: Int) -> Int { crossed[pw].filter { $0 == nil }.count }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = AddSubBig.Parts(s.numbers), ch = Self.chart(P), at = stage(s), k = phase(s), g = Self.geo(P)
        let opened = (s.h("opened") ?? 0) != 0
        let model = Chart(P, moves: at >= 3 ? P.phases.count : k, opened: opened)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        ch.draw(&pic, "ch", bands: [(g.yT, { _ in 2 }), (g.yB, { _ in 1 })], top: Self.top, bottom: g.yEnd)
        let phases = P.phases
        let moving: [Int] = at == 1 ? { if case .slide(let c) = phases[k] { c } else { [] } }() : []
        let held = s.grabbed && (s.h("wrong") ?? 0) == 0, dy = s.h("dy") ?? 0
        for pw in 0..<ch.n {
            for (j, item) in model.top[pw].enumerated() {
                let p = ch.slot(pw, j, band: g.yT), gone = model.crossed[pw][j]
                // taken away: faint, crossed out as school crosses it out (the striped disk that took it is used up)
                for (id, striped) in zip(item.ids, item.striped) { ch.disk(&pic, id + (gone != nil ? "x" : ""), at: p, striped: striped, faint: gone != nil) }
                if let sid = gone {
                    let r = ch.r + 0.2
                    pic.line("x\(sid)", [(p.x - r, p.y + r), (p.x + r, p.y - r)], .ink2)
                }
            }
            for (j, sid) in model.bottom[pw].enumerated() {
                let p = ch.slot(pw, j, band: g.yB)
                if held && moving.contains(pw) { ch.disk(&live, sid, at: CGPoint(x: p.x, y: p.y + dy), striped: true) }
                else { ch.disk(&pic, sid, at: p, striped: true) }
            }
        }
        // the count, under the column being worked
        let cp: Int? = at == 1 && (moving.first ?? 3) < 3 ? moving.first : at == 2 ? { if case .close(let c) = phases[k] { c } else { nil } }() : nil
        if let cp {
            let n = model.left(cp)
            pic.label("cnt\(cp).\(n)", "\(n) \(BigNumbers.place(cp, n))", Self.small, .below, edge: g.yEnd, along: ch.mid(cp))
        }
        if held, let c = moving.first, c < 3 { let n = model.left(c); live.reads("\(n) \(BigNumbers.place(c, n))") }
        // a hint: what to do now, outlined
        if s.on("ring") {
            if at == 2, let cp {
                let f = ch.frame(cp, 0)
                pic.sketch.box("ring", pic.R(f.x - 0.5, f.y - 0.5, 5 * ch.c + 1, 2 * ch.c + 1), .chapter, width: Sketch.stroke, dashed: true)
            } else if at == 1, P.sub, moving.contains(P.at), !opened, let j = model.top[P.at + 1].indices.last {
                let p = ch.slot(P.at + 1, j, band: g.yT)
                pic.circle("ring", at: p.x, p.y, radius: ch.r + 0.6, .chapter, dashed: true)
            } else if at == 1, let c = moving.first {
                pic.sketch.box("ring", pic.R(ch.colX(c) + 0.5, g.yB - 0.5, ch.cw * Double(moving.count) - 1, 2 * ch.c + 1), .chapter, width: Sketch.stroke, dashed: true)
            }
        }

        // the record: the column working as school writes it, the carries and trades small, filled in column by column
        let n = ch.n, xr = 2 * Double(n) + 4
        func cx(_ pw: Int) -> Double { xr - 2 * Double(pw) - 1 }
        for pw in 0..<BigNumbers.length(P.a) {
            let d = BigNumbers.digit(P.a, pw)
            rec.word("ra\(pw)", "\(d)", at: cx(pw), Self.aRow, Record.maths)
            if P.sub && model.traded.contains(pw - 1) {
                // the place that traded a ten away: crossed out, one less written over it
                rec.line("rax\(pw)", [(cx(pw) - 0.5, Self.aRow + 0.6), (cx(pw) + 0.5, Self.aRow - 0.6)], .chapter)
                rec.word("rat\(pw)", "\(d - 1)", at: cx(pw), Self.carryRow, Self.small)
            }
            if P.sub && model.traded.contains(pw) { rec.word("ron\(pw)", "1", at: cx(pw) - 0.75, Self.aRow - 0.9, Self.small) }
        }
        if BigNumbers.length(P.a) > 3 { rec.word("rac", ",", at: xr - 6, Self.aRow, Record.maths) }
        for pw in 0..<BigNumbers.length(P.b) { rec.word("rb\(pw)", "\(BigNumbers.digit(P.b, pw))", at: cx(pw), Self.bRow, Record.maths) }
        if BigNumbers.length(P.b) > 3 { rec.word("rbc", ",", at: xr - 6, Self.bRow, Record.maths) }
        // a story's sign stays hidden until it's picked
        if !s.picking { rec.word("rsg", P.sign, at: 1, Self.bRow, Record.maths) }
        for pw in model.carried { rec.word("rcar\(pw)", "1", at: cx(pw), Self.carryRow, Self.small) }
        rec.rule("rule", from: 0, to: xr, row: Self.rule)
        var boxes: [WorkBox] = []
        if at >= 4 {
            Record.number(&rec, "ans", P.R, right: xr, row: Self.ansRow, .chapter)
        } else {
            for (pw, d) in P.written(after: at >= 3 ? phases.count : k) { rec.word("rw\(pw)\(d)", "\(d)", at: cx(pw), Self.ansRow, Record.maths.colour(.chapter)) }
            if at == 3 {
                let cells = BigNumbers.length(P.R) - 3
                // the box ends where the hands' digits begin (its comma comes with the answer)
                rec.answerBox("x", right: xr - 6, mid: Self.ansRow, per: 2, cells: cells, commas: true, tight: true)
                boxes = rec.boxes
            }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: boxes)
    }

    /// Every slip fits one row over the chart (its narrowest, beside a five-column chart, is 69 squares); a second row
    /// cost a story its 75%.
    func messageRows(_ n: Numbers) -> Int { 1 }
    /// The record may go beside the chart, level with its names, when that shows it bigger (five columns: the chart is
    /// 18 rows tall, and under it the column working was seen at 56% in a story).
    func recordBeside(_ n: Numbers) -> Double? { Self.top }
    /// Under the chart, the record's own first rows are empty (the carries sit on its row 2): it starts a square under
    /// the columns' lines, so its first number is 3 rows under the count.
    func recordRow(_ n: Numbers) -> Double? { Self.geo(AddSubBig.Parts(n)).yEnd + 1 }

    func hands(_ s: PaperState) -> Hands? {
        let P = AddSubBig.Parts(s.numbers), ch = Self.chart(P), at = stage(s), k = phase(s), phases = P.phases, g = Self.geo(P)
        guard at == 1 || at == 2, phases.indices.contains(k) else { return nil }
        let opened = (s.h("opened") ?? 0) != 0
        let model = Chart(P, moves: k, opened: opened)
        func inBottom(_ q: CGPoint) -> Int? {
            guard q.y >= g.yB - 0.5, q.y <= g.yB + 2 * ch.c + 0.5, let pw = ch.place(at: q.x), !model.bottom[pw].isEmpty else { return nil }
            return pw
        }
        if case .close(let c) = phases[k] {
            return Hands(
                tap: { q in
                    guard q.y >= g.yT - 0.5, q.y <= g.yEnd, ch.place(at: q.x) != nil else { return nil }
                    if ch.place(at: q.x) == c, ch.frame(at: q, c, count: 2) == 0 { return HandMove(hand: nil, missHand: nil, set: [("x", 1)], check: true) }
                    return HandMove(hand: nil, missHand: nil, set: [("x", 6)], check: true)
                },
                // the next column slid first: the full ten comes first
                grab: { q in inBottom(q) != nil ? ["grab": 1, "wrong": 1] : nil },
                drag: { _, h in h },
                release: { _ in HandMove(hand: [:], missHand: [:], set: [("x", 5)], check: true) })
        }
        guard case .slide(let cols) = phases[k] else { return nil }
        let trade = P.sub && cols.contains(P.at)
        return Hands(
            // taking away: a disk of the next column tapped opens into ten
            tap: { q in
                guard P.sub, q.y >= g.yT - 0.5, q.y <= g.topEnd, let pw = ch.place(at: q.x), !model.top[pw].isEmpty else { return nil }
                if opened { return nil }
                if !trade { return HandMove(hand: nil, missHand: nil, set: [("x", 3)], check: true) }
                if pw != P.at + 1 { return HandMove(hand: nil, missHand: nil, set: [("x", 4)], check: true) }
                return HandMove(hand: ["opened": 1], missHand: nil, set: [], check: false)
            },
            grab: { q in
                guard let pw = inBottom(q) else { return nil }
                var h: Numbers = ["grab": 1, "fy": q.y, "dy": 0]
                if opened { h["opened"] = 1 }
                if !cols.contains(pw) { h["wrong"] = 1 }
                return h
            },
            drag: { q, h in
                var h = h
                h["dy"] = max(g.yT - g.yB, min(0.5, (q.y - (h["fy"] ?? 0)).rounded()))
                return h
            },
            release: { h in
                let keep: Numbers = opened ? ["opened": 1] : [:]
                if (h["wrong"] ?? 0) != 0 { return HandMove(hand: keep, missHand: keep, set: [("x", 5)], check: true) }
                // not lifted far: it drops back
                guard (h["dy"] ?? 0) <= -min(3, g.yB - g.yT - 1) else { return HandMove(hand: keep, missHand: keep, set: [], check: false) }
                return HandMove(hand: keep, missHand: keep, set: [("x", trade && !opened ? 2 : 1)], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = AddSubBig.Parts(s.numbers), ch = Self.chart(P), at = stage(s), k = phase(s), phases = P.phases, g = Self.geo(P)
        guard phases.indices.contains(k) else { return [] }
        if at == 2, case .close(let c) = phases[k] { return [.tap(.picture(ch.centre(c, 0)))] }
        guard at == 1, case .slide(let cols) = phases[k], let c = cols.first else { return [] }
        var moves: [GhostMove] = []
        let opened = (s.h("opened") ?? 0) != 0
        if P.sub, cols.contains(P.at), !opened {
            let model = Chart(P, moves: k, opened: false)
            if let j = model.top[P.at + 1].indices.last { moves.append(.tap(.picture(ch.slot(P.at + 1, j)))) }
        }
        let from = CGPoint(x: ch.mid(c), y: g.yB + ch.c)
        moves.append(.drag(from: from, to: CGPoint(x: from.x, y: from.y - (g.yB - g.yT))))
        return moves
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = AddSubBig.Parts(s.numbers), at = stage(s), k = phase(s), phases = P.phases
        guard at == 1, phases.indices.contains(k), case .slide(let cols) = phases[k] else { return nil }
        // taking away without the ten opened first
        if P.sub && cols.contains(P.at) { return HandMove(hand: [:], missHand: [:], set: [("x", 2)], check: true) }
        return nil
    }
}
