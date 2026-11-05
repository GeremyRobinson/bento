import SwiftUI

/// Add and subtract within 1000 on the paper, as in the preview (design/prototype/grade3-ch3.html, dAddSub): the place
/// chart, hundreds | tens | ones, each column 15 squares (3 blocks) wide a block apart; a disk is a 3-square cell and says
/// what it's worth; a column holds ten-frames (2 rows of 5), two deep. a's disks fill the top, its digits over the columns
/// (the chart's number); b's wait under their columns, `+ 275` beside them (striped to take away). A place at a time,
/// biggest first: slide its disks up (they snap in after the column's, or land on a's and cross them out); too few, tap a
/// disk of the place up and it opens into ten; ten or more, tap the full ten and it closes into one disk of the next place.
/// Then write the jump, `458 + 200 = [658]`, one line per place.
///
/// Hand: "grab", "dx", "dy" (the held disks' offset, in squares), "c" the column held, "wrong" (another column held), "o"
/// the opens done on this slide, "need" (slid with too few: open one first), "picked"/"wrong" a story's pick.
@MainActor
struct AddSub3Lesson: PaperLesson {
    static let TY = 3.0, BY = 17.0, rec = 25.0
    static let places = [100, 10, 1]
    /// A disk's radius: its worth ("100") clear of its ring.
    static let r = 1.35
    var liveKeys: Set<String> { ["dx", "dy"] }
    func recordRow(_ n: Numbers) -> Double? { Self.rec }
    private static let small = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink)

    private func phase(_ s: PaperState) -> (Int, AddSub3.Phase) {
        let P = AddSub3.Parts(s.numbers), phs = P.phases, i = max(0, min(phs.count - 1, Int((s.picture["ph"] ?? 0).rounded())))
        return (i, phs[i])
    }
    private func opened(_ s: PaperState) -> Int { Int((s.h("o") ?? 0).rounded()) }

    static func colX(_ c: Int) -> Double { Double(c) * 20 }
    static func slot(_ c: Int, _ j: Int) -> CGPoint {
        let f = j / 10, i = j % 10
        return CGPoint(x: colX(c) + Double(i % 5) * 3 + 1.5, y: TY + Double(f) * 7 + Double(i / 5) * 3 + 1.5)
    }
    static func low(_ c: Int, _ j: Int) -> CGPoint { CGPoint(x: colX(c) + Double(j % 5) * 3 + 1.5, y: BY + Double(j / 5) * 3 + 1.5) }

    /// The chart after some moves: each column's disks (a disk is one id, or ten stacked: a ten closed into one), which
    /// striped disk crossed out which, b's disks still waiting, the columns b has slid.
    struct Board {
        struct Item { var ids: [String]; var value: Int; var hidden: [String] = [] }
        let P: AddSub3.Parts
        var top: [[Item]] = [[], [], []], bottom: [[String]] = [[], [], []]
        var cover: [String: String] = [:], used: Set<Int> = [], opened: [String: String] = [:]
        let toOpen: [String: String]
        init(_ P: AddSub3.Parts, toOpen: [String: String]) {
            self.P = P; self.toOpen = toOpen
            for c in 0..<3 {
                let place = AddSub3Lesson.places[c]
                for k in 0..<(P.a / place % 10) { top[c].append(item("a\(c).\(k)", place)) }
                for k in 0..<(P.b / place % 10) { bottom[c].append("b\(c).\(k)") }
            }
        }
        /// A disk; one that will open later holds its ten under it, so they glide out of it.
        func item(_ id: String, _ value: Int) -> Item {
            Item(ids: [id], value: value, hidden: toOpen[id].map { key in (0..<10).map { "\(key).\($0)" } } ?? [])
        }
        mutating func open(_ k: Int, _ n: Int, _ o: Int) {
            guard let it = top[o].popLast() else { return }
            let key = "o\(k).\(n)"
            opened[it.ids[0]] = key
            let ids = it.hidden.isEmpty ? (0..<10).map { "\(key).\($0)" } : it.hidden
            for id in ids { top[o + 1].append(item(id, AddSub3Lesson.places[o + 1])) }
        }
        mutating func land(_ k: Int) {
            let j = P.jumps[k], c = j.c
            if P.sub {
                let n = top[c].count
                for (m, sid) in bottom[c].enumerated() where n - j.d + m >= 0 { cover[top[c][n - j.d + m].ids[0]] = sid }
            } else {
                for id in bottom[c] { top[c].append(Item(ids: [id], value: j.place)) }
            }
            bottom[c] = []; used.insert(c)
        }
        mutating func close(_ c: Int) {
            let ten = top[c].prefix(10)
            let ids = ten.flatMap(\.ids)
            top[c].removeFirst(min(10, top[c].count))
            top[c - 1].append(Item(ids: ids, value: AddSub3Lesson.places[c - 1]))
        }
        mutating func clear(_ c: Int) { top[c].removeAll { cover[$0.ids[0]] != nil }; cover = [:] }
        func count(_ c: Int) -> Int { top[c].filter { cover[$0.ids[0]] == nil }.count }
        var number: Int { (0..<3).reduce(0) { $0 + count($1) * AddSub3Lesson.places[$1] } }

        /// Every move before phase i done, and `o` opens of a slide at i.
        mutating func run(to i: Int, opened o: Int) {
            let phs = P.phases, plan = P.plan
            for (x, ph) in phs.enumerated() {
                if x > i { break }
                switch ph {
                case .slide(let k):
                    let n = x < i ? plan[k].opens.count : min(o, plan[k].opens.count)
                    for m in 0..<n { open(k, m, plan[k].opens[m]) }
                    if x < i { land(k) }
                case .close(_, let c): if x < i { close(c) }
                case .write(let k): if x < i && P.sub { clear(P.jumps[k].c) }
                default: break
                }
            }
        }
        static func at(_ P: AddSub3.Parts, _ i: Int, opened o: Int) -> Board {
            var all = Board(P, toOpen: [:])
            all.run(to: P.phases.count, opened: 0)
            var b = Board(P, toOpen: all.opened)
            b.run(to: i, opened: o)
            return b
        }
    }

    /// A disk: tinted (plain while a story is read, striped when it takes away), its worth written in it.
    static func disk(_ pen: inout GridPen, _ id: String, at p: CGPoint, value: Int, striped: Bool = false, plain: Bool = false, quiet: Bool = false) {
        let c = pen.P(p.x, p.y), r = Self.r * Paper.cell
        let pts = (0..<24).map { i in let a = Double(i) / 24 * 2 * .pi; return CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a)) }
        if striped { PlaceChart.disk(&pen, id, at: p, r: Self.r, striped: true) }
        else {
            pen.sketch.plate("dk" + id, pts, plain ? .paper : .tint(0.2))
            pen.sketch.overLine("dko" + id, pts + [pts[0]], .ink, width: Sketch.stroke)
        }
        if !quiet { pen.word("dt\(id).\(value)", "\(value)", at: p.x, p.y, small) }
    }
    private static func frame10(_ pen: inout GridPen, _ id: String, x: Double, y: Double) {
        pen.sketch.box(id, pen.R(x, y, 15, 6), .ink3, width: Sketch.stroke)
        var segs: [(CGPoint, CGPoint)] = [(pen.P(x, y + 3), pen.P(x + 15, y + 3))]
        for i in 1..<5 { segs.append((pen.P(x + 3 * Double(i), y), pen.P(x + 3 * Double(i), y + 6))) }
        pen.sketch.segments(id + "i", segs, .ink3, width: 1)
    }

    /// Where held disks of column c would land: a column, −1 off the chart, nil not slid up onto it.
    static func over(_ c: Int, dx: Double, dy: Double) -> Int? {
        guard BY + dy + 3 <= TY + 14 else { return nil }
        let tc = Int(((colX(c) + dx) / 20).rounded())
        return (0...2).contains(tc) ? tc : -1
    }

    func say(_ s: PaperState) -> String? {
        let P = AddSub3.Parts(s.numbers)
        guard case .slide(let k) = phase(s).1, (s.h("need") ?? 0) != 0 else { return nil }
        return P.slideSay(k, need: true, opened: opened(s))
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = AddSub3.Parts(s.numbers), (i, ph) = phase(s), o = opened(s), TY = Self.TY, BY = Self.BY
        let B = Board.at(P, i, opened: o)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let picking = ph == .pick, held = s.grabbed && (s.h("wrong") ?? 0) == 0
        let hc = Int((s.h("c") ?? -1).rounded()), dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0
        var cur: P3.Jump? = nil
        switch ph { case .slide(let k), .write(let k), .close(let k, _): cur = P.jumps[k]; default: break }

        // the frames: two deep in each column, one under it where b's disks wait
        for c in 0..<3 {
            Self.frame10(&pic, "ft\(c).0", x: Self.colX(c), y: TY); Self.frame10(&pic, "ft\(c).1", x: Self.colX(c), y: TY + 7)
            if P.b / Self.places[c] % 10 > 0 { Self.frame10(&pic, "fb\(c)", x: Self.colX(c), y: BY) }
        }
        if case .close(_, let c) = ph {
            pic.fill("glow\(c)", col: Self.colX(c), row: TY, w: 15, h: 6, .tint(0.42))
            pic.sketch.box("full\(c)", pic.R(Self.colX(c), TY, 15, 6), .chapter, width: Sketch.stroke)
        }
        // over each column its digit of the chart's number (10 or more, in colour); held over its column, what it'll be
        let overCol = held ? Self.over(hc, dx: dx, dy: dy) : nil
        let short = cur.map { P.sub && B.count($0.c) < $0.d } ?? false
        var lead = true
        for c in 0..<3 {
            let n = B.count(c), preview = held && overCol == hc && hc == c && !short
            let v = n + (preview ? P.s * B.bottom[c].count : 0)
            if lead && v == 0 && n == 0 && c < 2 { continue }
            lead = false
            let hot = preview || v >= 10
            if held && hc == c { live.label("hd\(c)", "\(v)", Record.maths.colour(hot ? .chapter : .ink), .above, edge: TY, along: Self.colX(c) + 7.5) }
            else { pic.label("hd\(c).\(v)\(hot)", "\(v)", Record.maths.colour(hot ? .chapter : .ink), .above, edge: TY, along: Self.colX(c) + 7.5) }
        }
        // the disks: the chart's (the crossed-out ones with the striped disk on them), b's waiting or held
        var land: [String: String] = [:]
        for (t, sid) in B.cover { land[t] = sid }
        for c in 0..<3 {
            for (j, it) in B.top[c].enumerated() {
                let p = Self.slot(c, j)
                // what's stacked under a disk (the ten it opens into, or the ten closed into it) lies under it, unseen
                for h in it.hidden { Self.disk(&pic, h, at: p, value: it.value, quiet: true) }
                for id in it.ids.dropFirst().reversed() { Self.disk(&pic, id, at: p, value: it.value, quiet: true) }
                Self.disk(&pic, it.ids[0], at: p, value: it.value, quiet: land[it.ids[0]] != nil)
                if let sid = land[it.ids[0]] {
                    Self.disk(&pic, sid, at: p, value: it.value, striped: true)
                    // crossed out, over the disk (a plate sits over plain lines)
                    pic.sketch.overLine("x\(sid)", [pic.P(p.x - 1.25, p.y + 1.25), pic.P(p.x + 1.25, p.y - 1.25)], .ink, width: Sketch.stroke)
                }
            }
            for (j, id) in B.bottom[c].enumerated() {
                let p = Self.low(c, j)
                if held && hc == c { Self.disk(&live, id, at: CGPoint(x: p.x + dx, y: p.y + dy), value: Self.places[c], striped: P.sub) }
                else { Self.disk(&pic, id, at: p, value: Self.places[c], striped: P.sub && !picking, plain: picking) }
            }
        }
        if held, let j = cur {
            live.reads(overCol == j.c && !short ? "\(B.number) \(P.sign) \(j.v) = \(B.number + P.s * j.v)" : "\(j.v)")
        }
        // b beside its disks, its digits ending on a block line, grey once their disks have gone in
        // (written tight, call of 3 Nov: each digit where it stands in the tight number, so one can grey alone)
        let bs = Array(String(P.b)), dw = PaperText.width("0", PaperText.font(Sketch.maths, .medium, digits: true)) / Paper.cell
        let bx = 65.6 - dw * Double(bs.count)
        if !picking { pic.word("bsign", P.sign, at: bx - 1.4, BY + 3, Record.maths) }
        for (k, ch) in bs.enumerated() {
            let c = 3 - bs.count + k, gone = B.used.contains(c)
            pic.word("bd\(k)\(gone)", String(ch), at: bx + dw * (Double(k) + 0.5), BY + 3, Record.maths.colour(gone ? .ink3 : .ink))
        }

        // hints: a first miss rings the general area, a second the exact spot
        let ring = s.on("ring"), spot = s.on("spot")
        if case .slide(let k) = ph, let j = cur, ring || spot {
            if short, let w = P.opener(k, o), let oc = Self.places.firstIndex(of: w) {
                if spot, let last = B.top[oc].indices.last { pic.circle("hs", at: Self.slot(oc, last).x, Self.slot(oc, last).y, radius: 1.8, .chapter, dashed: true) }
                else { KK.hintBox(&pic, "hr", x: Self.colX(oc), y: TY, w: 15, h: B.top[oc].count > 10 ? 13 : 6) }
            } else if spot { KK.hintBox(&pic, "hs", x: Self.colX(j.c), y: TY, w: 15, h: 13) }
            else { KK.hintBox(&pic, "hr", x: Self.colX(j.c), y: BY, w: 15, h: 6) }
        }
        if case .write = ph, ring, let j = cur { KK.hintBox(&pic, "hw", x: Self.colX(j.c) + 5, y: TY - 2.6, w: 5, h: 2) }

        // a story's pick: + Add and − Take away under the chart (red or green for its moment)
        if picking {
            let w = s.h("wrong"), r = s.h("picked")
            T3.block(&pic, "add", x: 0, y: Self.rec, w: 7, "+ Add", wrong: w == 0, right: r == 0)
            T3.block(&pic, "take", x: 10, y: Self.rec, w: 12, "− Take away", wrong: w == 1, right: r == 1)
        }

        // the record: one line per place, written after the hands have done it
        var lines = 0
        switch ph {
        case .slide(let k), .close(let k, _): lines = k
        case .write(let k): lines = k + 1
        case .done: lines = P.jumps.count
        default: lines = 0
        }
        for k in 0..<lines {
            let j = P.jumps[k], right: Bool = { if case .write(let w) = ph { return w != k } else { return true } }()
            M7.row(&rec, "r\(k)", [.n(j.from), .op(P.sign), .n(j.v), .op("="), M3.box("w\(k)", j.to, cells: 3, right: right)], x: 0, line: 1 + 3 * Double(k))
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    /// Check (or Next problem) beside the line being written, on a block line.
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = AddSub3.Parts(s.numbers)
        let k: Int
        switch phase(s).1 { case .write(let w): k = w; case .done: k = P.jumps.count - 1; default: return nil }
        let j = P.jumps[k], w = M7.width([.n(j.from), .op(P.sign), .n(j.v), .op("="), .box("w", cells: 3)])
        return CGPoint(x: ((w + 2) / 5).rounded(.up) * 5, y: Self.rec + 3 * Double(k))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = AddSub3.Parts(s.numbers), (i, ph) = phase(s), o = opened(s), BY = Self.BY, TY = Self.TY
        let B = Board.at(P, i, opened: o), keep: Numbers = ["o": Double(o), "need": s.h("need") ?? 0]
        func lowCol(_ q: CGPoint) -> Int? {
            guard q.y >= BY - 0.5, q.y <= BY + 6.5 else { return nil }
            return (0..<3).first { !B.bottom[$0].isEmpty && q.x >= Self.colX($0) - 0.5 && q.x <= Self.colX($0) + 15.5 }
        }
        switch ph {
        case .pick:
            return Hands(tap: { q in
                guard q.y >= Self.rec - 0.3, q.y <= Self.rec + 2.3 else { return nil }
                let v: Double? = q.x >= -0.3 && q.x <= 7.3 ? 0 : q.x >= 9.7 && q.x <= 22.3 ? 1 : nil
                return v.map { HandMove(hand: ["picked": $0], missHand: ["wrong": $0], set: [("c", $0)], check: true) }
            })
        case .close(_, let c):
            return Hands(
                tap: { q in
                    q.x >= Self.colX(c) - 0.3 && q.x <= Self.colX(c) + 15.3 && q.y >= TY - 0.3 && q.y <= TY + 6.3
                        ? HandMove(hand: [:], missHand: [:], set: [("x", 1)], check: true) : nil
                },
                grab: { q in lowCol(q) != nil ? ["grab": 1, "wrong": 1] : nil },
                drag: { _, h in h },
                release: { _ in HandMove(hand: [:], missHand: [:], set: [("x", 5)], check: true) })
        case .slide(let k):
            let j = P.jumps[k], short = P.sub && B.count(j.c) < j.d
            return Hands(
                // taking away: a disk of the place up tapped opens into ten
                tap: { q in
                    guard P.sub, q.y >= TY - 0.5, q.y <= TY + 13.5 else { return nil }
                    for c in 0..<3 { for (m, _) in B.top[c].enumerated() {
                        let p = Self.slot(c, m)
                        guard abs(q.x - p.x) <= 1.5, abs(q.y - p.y) <= 1.5 else { continue }
                        if !short { return HandMove(hand: keep, missHand: keep, set: [("x", 5)], check: true) }
                        guard let w = P.opener(k, o), Self.places.firstIndex(of: w) == c else {
                            return HandMove(hand: keep, missHand: keep, set: [("x", Double(6 + 10 * o))], check: true)
                        }
                        return HandMove(hand: ["o": Double(o + 1)], missHand: nil, set: [], check: false)
                    } }
                    return nil
                },
                grab: { q in
                    guard let c = lowCol(q) else { return nil }
                    var h = keep
                    h["grab"] = 1; h["c"] = Double(c); h["fx"] = q.x; h["fy"] = q.y; h["dx"] = 0; h["dy"] = 0
                    if c != j.c { h["wrong"] = 1 }
                    return h
                },
                drag: { q, h in
                    var h = h
                    h["dx"] = (q.x - (h["fx"] ?? 0)).rounded()
                    h["dy"] = max(TY - BY, min(1, (q.y - (h["fy"] ?? 0)).rounded()))
                    return h
                },
                release: { h in
                    if (h["wrong"] ?? 0) != 0 { return HandMove(hand: keep, missHand: keep, set: [("x", 3)], check: true) }
                    guard let tc = Self.over(j.c, dx: h["dx"] ?? 0, dy: h["dy"] ?? 0) else { return HandMove(hand: keep, missHand: keep, set: [], check: false) }
                    if tc != j.c { return HandMove(hand: keep, missHand: keep, set: [("x", 2)], check: true) }
                    if short {
                        let need: Numbers = ["o": Double(o), "need": 1]
                        return HandMove(hand: need, missHand: need, set: [("x", Double(4 + 10 * o))], check: true)
                    }
                    return HandMove(hand: [:], missHand: keep, set: [("x", 1)], check: true)
                })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = AddSub3.Parts(s.numbers), (i, ph) = phase(s), o = opened(s)
        switch ph {
        case .pick: return [.tap(.picture(CGPoint(x: P.sub ? 16 : 3.5, y: Self.rec + 1)))]
        case .close(_, let c): return [.tap(.picture(CGPoint(x: Self.colX(c) + 7.5, y: Self.TY + 3)))]
        case .slide(let k):
            var moves: [GhostMove] = []
            let opens = P.plan[k].opens
            if o < opens.count {
                for n in o..<opens.count {
                    let B = Board.at(P, i, opened: n), oc = opens[n]
                    if let last = B.top[oc].indices.last { moves.append(.tap(.picture(Self.slot(oc, last)))) }
                }
            }
            let c = P.jumps[k].c, from = CGPoint(x: Self.colX(c) + 7.5, y: Self.BY + 3)
            moves.append(.drag(from: from, to: CGPoint(x: from.x, y: Self.TY + 3)))
            return moves
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = AddSub3.Parts(s.numbers), (i, ph) = phase(s), o = opened(s)
        switch ph {
        case .pick: let v: Double = P.sub ? 0 : 1; return HandMove(hand: ["picked": v], missHand: ["wrong": v], set: [("c", v)], check: true)
        case .slide(let k):
            let j = P.jumps[k], B = Board.at(P, i, opened: o)
            if P.sub && B.count(j.c) < j.d { let need: Numbers = ["o": Double(o), "need": 1]; return HandMove(hand: need, missHand: need, set: [("x", Double(4 + 10 * o))], check: true) }
            return HandMove(hand: [:], missHand: [:], set: [("x", 2)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = AddSub3.Parts(s.numbers)
        guard case .write(let k) = phase(s).1, let w = P.writeSlips(k).first(where: { $0.0 != P.jumps[k].to && $0.0 >= 0 }) else { return nil }
        return ["w\(k)": Double(w.0)]
    }
}
