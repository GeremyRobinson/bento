import SwiftUI

/// Add three numbers on the paper, as in the preview (design/prototype/grade1-ch1.html, dThree): three groups of counters
/// (solid, striped, dotted) on rows 0, 4 and 8, each named at its right end; the twenty a block under them (two rows of ten
/// places, rows 13 and 17). Tap two that make 10 or a double (the pick step, when there is one: a tapped group is ringed,
/// a wrong pair outlined red; the preview tints them, but a tint under the counters flickers on the iPad); slide the two into the top row, one group then the other (they fill it from the left, "7 and 3 make 10", the
/// row solid and named 10 once full); slide the last group in (its counters land one after another, the count running
/// on). A group slid into the twenty leaves its places dashed. The record goes beside the twenty and the number row under
/// it, so the whole problem shows at 75% with a story's two rows of words (the preview wrote it under the twenty).
///
/// Hand: "grab", "g", "gx", "gy", "dx", "dy". Kept: "sel" the groups tapped (bits), "bad" a wrong pair's code, "u0" the
/// group slid in first, "u" the pair's code, "lg", "lx", "ly" a group let go (it glides from there).
@MainActor
struct Three1Lesson: PaperLesson {
    var liveKeys: Set<String> { ["dx", "dy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let twenty = 13.0, keys = 22.0, recX = 35.0
    static func gy(_ g: Int) -> Double { 4 * Double(g) }
    static func place(_ p: Int) -> CGPoint { CGPoint(x: A1.x(p % 10), y: twenty + (p >= 10 ? 4 : 0)) }
    static let styles: [A1.Style] = [.solid, .striped, .dotted]
    func recordRow(_ n: Numbers) -> Double? { 0 }

    /// The groups slid in so far, in order.
    private func used(_ s: PaperState) -> [Int] {
        let P = Three1.Parts(s.numbers), st = at(s)
        let code = Int(s.run.kept["u"] ?? Double(P.pairCode)), pair = Three1.pair(code) ?? P.first.pair
        let u0 = s.run.kept["u0"].map { Int($0) } ?? pair.0
        let second = pair.0 == u0 ? pair.1 : pair.0
        switch st {
        case 0: return []
        case 1: return s.run.kept["u0"].map { [Int($0)] } ?? []
        case 2: return [u0, second]
        default: return [u0, second, 3 - pair.0 - pair.1]
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Three1.Parts(s.numbers), st = at(s), v = P.v, writing = st >= 3
        var pic = GridPen(), live = GridPen(stableIds: true)
        let u = used(s), held = s.grabbed ? Int(s.h("g") ?? 0) : nil
        // where each used group's counters landed in the twenty
        var start: [Int: Int] = [:], fill = 0
        for g in u { start[g] = fill; fill += v[g] }
        let full = fill >= 10
        A1.places(&pic, "tt", x: 0, y: Self.twenty, full: full)
        A1.places(&pic, "tb", x: 0, y: Self.twenty + 4)
        let code = Int(s.run.kept["u"] ?? Double(P.pairCode)), pair = Three1.pair(code) ?? P.first.pair
        // the two to slide first, lit (once picked, or offered when there's no pick)
        if st == 1 { for g in [P.first.pair.0, P.first.pair.1] where !u.contains(g) && held != g { KK.stadium(&pic, "lit\(g)", x: -0.25, y: Self.gy(g) - 0.25, w: A1.x(v[g]) + 0.25, h: 3.5) } }
        let sel = Int(s.run.kept["sel"] ?? 0)
        if st == 0 { for g in 0..<3 where sel & (1 << g) != 0 { KK.stadium(&pic, "lit\(g)", x: -0.25, y: Self.gy(g) - 0.25, w: A1.x(v[g]) + 0.25, h: 3.5) } }
        if st == 0, let bad = KA.kept(s, "bad"), let (a, b) = Three1.pair(bad) {
            for g in [a, b] { pic.sketch.box("bad\(g)", pic.R(-0.5, Self.gy(g) - 0.5, A1.x(v[g]) + 1, 4), KK.red, width: Sketch.stroke) }
        }
        let lg = s.run.kept["lg"].map { Int($0) }, lx = s.run.kept["lx"] ?? 0, ly = s.run.kept["ly"] ?? 0
        for g in 0..<3 {
            if held == g {
                let dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0
                for j in 0..<v[g] { A1.counter(&live, "c\(g)-\(j)", x: A1.x(j) + dx, y: Self.gy(g) + dy, Self.styles[g]) }
                continue
            }
            let was: ((inout GridPen) -> Void)? = lg == g ? { p in for j in 0..<v[g] { A1.counter(&p, "c\(g)-\(j)", x: A1.x(j) + lx, y: Self.gy(g) + ly, Self.styles[g]) } } : nil
            let last = st >= 3 && g == u.last
            KM.seeded(&pic, was: was) { p in
                for j in 0..<v[g] {
                    if let s0 = start[g] {
                        // the last group lands one after another, the count running on
                        if last { p.sketch.delay = 0.22 * Double(j) }
                        let q = Self.place(s0 + j)
                        A1.counter(&p, "c\(g)-\(j)", x: q.x, y: q.y, Self.styles[g])
                        p.sketch.delay = 0
                    } else {
                        A1.counter(&p, "c\(g)-\(j)", x: A1.x(j), y: Self.gy(g), Self.styles[g])
                    }
                }
            }
            if start[g] != nil { for j in 0..<v[g] { A1.gone(&pic, "g\(g)-\(j)", x: A1.x(j), y: Self.gy(g)) } }
            if !writing { pic.label("lg\(g)\(start[g] != nil)", "\(v[g])", KK.maths.colour(start[g] != nil ? .ink3 : .ink), .right, edge: A1.x(v[g]), along: Self.gy(g) + 1.5) }
        }
        if full && !writing { pic.label("t10", "10", KK.maths.colour(.chapter), .right, edge: 30, along: Self.twenty + 1.5) }
        if st == 2 { let f = P.after(code); A1.note(&pic, "ro2", "\(v[pair.0]) and \(v[pair.1]) make \(f.first)", x: 0, y: Self.twenty + 9) }
        if held != nil, st >= 1 {
            let g = held!, have = fill
            let text = u.isEmpty ? "\(v[g])" : "\(have) and \(v[g]) make \(have + v[g])"
            live.reads(text)
        }

        let f = P.after(code)
        switch st {
        case 0:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: 0, w: A1.x(v.max() ?? 9), h: 11) }
            if s.on("spot") { for g in [P.first.pair.0, P.first.pair.1] { pic.sketch.box("spot\(g)", pic.R(-0.5, Self.gy(g) - 0.5, A1.x(v[g]) + 1, 4), .chapter, width: Sketch.stroke, dashed: true) } }
        case 1, 2:
            let todo = st == 1 ? [P.first.pair.0, P.first.pair.1].filter { !u.contains($0) } : [3 - pair.0 - pair.1]
            if s.on("ring") && !s.on("spot") { for g in todo { KK.hintBox(&pic, "hr\(g)", x: 0, y: Self.gy(g), w: A1.x(v[g]), h: 3) } }
            if s.on("spot"), let g = todo.first {
                let p0 = Self.place(fill)
                pic.sketch.box("spot", pic.R(p0.x, p0.y, A1.x(min(v[g], 10 - fill % 10)), 3), .chapter, width: Sketch.stroke, dashed: true)
            }
        case 3:
            let (x, wrong) = KK.typed(s, "x", want: P.sum)
            A1.record(&pic, "rec", [.n(v[0]), .op("+"), .n(v[1]), .op("+"), .n(v[2]), .op("="), .n(f.first), .op("+"), .n(f.z), .op("="), .box(x, wrong: wrong)], x: Self.recX, line: Self.twenty + 1.5)
            A1.numberRow(&pic, "nr", y: Self.keys, wrong: wrong ? x : nil, spot: s.on("spot") ? P.sum : nil)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: Self.twenty, w: 30, h: 7) }
        default:
            A1.record(&pic, "rec", [.n(v[0]), .op("+"), .n(v[1]), .op("+"), .n(v[2]), .op("="), .n(f.first), .op("+"), .n(f.z), .op("="), .n(P.sum, .chapter)], x: Self.recX, line: Self.twenty + 1.5)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch)
    }

    private func group(_ q: CGPoint, _ v: [Int]) -> Int? {
        (0..<3).first { q.y >= Self.gy($0) - 0.5 && q.y <= Self.gy($0) + 3.5 && q.x >= -0.5 && q.x <= A1.x(v[$0]) + 2.5 }
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Three1.Parts(s.numbers), v = P.v, st = at(s)
        switch st {
        case 0:
            let sel = Int(s.run.kept["sel"] ?? 0)
            return Hands(tap: { q in
                guard let g = group(q, v) else { return nil }
                let now = sel ^ (1 << g)
                let picked = (0..<3).filter { now & (1 << $0) != 0 }
                guard picked.count == 2 else { return HandMove(hand: nil, keep: ["sel": Double(now), "bad": -1]) }
                let code = Three1.code(picked[0], picked[1])
                return HandMove(hand: nil, missHand: nil, set: [("p", Double(code))], keep: ["sel": 0, "bad": Double(code == P.pairCode ? -1 : code)], check: true)
            })
        case 1, 2:
            let u = used(s)
            return Hands(
                grab: { q in
                    guard let g = group(q, v), !u.contains(g) else { return nil }
                    return ["grab": 1, "g": Double(g), "gx": q.x, "gy": q.y, "dx": 0, "dy": 0]
                },
                drag: { q, held in
                    var held = held
                    held["dx"] = (q.x - (held["gx"] ?? q.x)).rounded()
                    held["dy"] = (q.y - (held["gy"] ?? q.y)).rounded()
                    return held
                },
                release: { held in
                    let g = Int(held["g"] ?? 0), dx = held["dx"] ?? 0, dy = held["dy"] ?? 0
                    let back: Numbers = ["lg": Double(g), "lx": dx, "ly": dy]
                    // not down at the twenty: home it goes
                    guard Self.gy(g) + dy >= Self.twenty - 3 else { return HandMove(hand: [:], keep: back) }
                    if st == 2 { return HandMove(hand: [:], missHand: [:], set: [("z", 1)], keep: back, check: true) }
                    if u.isEmpty {
                        guard P.allowed.contains(where: { c in Three1.pair(c).map { $0.0 == g || $0.1 == g } ?? false }) else {
                            return HandMove(hand: [:], missHand: [:], set: [("s", -1)], keep: back, check: true)
                        }
                        return HandMove(hand: [:], keep: back.merging(["u0": Double(g)]) { $1 })
                    }
                    let code = Three1.code(u[0], g)
                    var keep = back
                    if P.allowed.contains(code) { keep["u"] = Double(code) }
                    return HandMove(hand: [:], missHand: [:], set: [("s", P.allowed.contains(code) ? Double(code) : -1)], keep: keep, check: true)
                })
        case 3: return A1.rowHands("x", y: Self.keys)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Three1.Parts(s.numbers), v = P.v, u = used(s), pair = P.first.pair
        func slide(_ g: Int) -> GhostMove { .drag(from: CGPoint(x: 1.5, y: Self.gy(g) + 1.5), to: CGPoint(x: 1.5, y: Self.twenty + 1.5)) }
        switch at(s) {
        case 0: return [pair.0, pair.1].map { .tap(.picture(CGPoint(x: A1.x(v[$0]) / 2, y: Self.gy($0) + 1.5))) }
        case 1: return [pair.0, pair.1].filter { !u.contains($0) }.map(slide)
        case 2: return [slide(3 - pair.0 - pair.1)]
        case 3: return [.tap(.picture(A1.keySpot(P.sum, y: Self.keys)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Three1.Parts(s.numbers)
        switch at(s) {
        case 0:
            let bad = [Three1.code(0, 1), Three1.code(0, 2), Three1.code(1, 2)].first { $0 != P.pairCode }!
            return HandMove(hand: nil, missHand: nil, set: [("p", Double(bad))], keep: ["sel": 0, "bad": Double(bad)], check: true)
        case 1:
            let g = (0..<3).first { g in !P.allowed.contains { c in Three1.pair(c).map { $0.0 == g || $0.1 == g } ?? false } }
            return HandMove(hand: [:], missHand: [:], set: [("s", -1)], keep: g.map { ["lg": Double($0), "lx": 0, "ly": Self.twenty - Self.gy($0)] } ?? [:], check: true)
        case 3: return A1.slip("x", P.sum)
        default: return nil
        }
    }
}
