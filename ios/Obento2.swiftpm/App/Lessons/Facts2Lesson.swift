import SwiftUI

/// Facts to 20 on the paper, as in the preview (design/prototype/grade2-ch1.html, dFacts): 1st grade's two rows of ten
/// places (3 × 3 a counter), the fact's counters in them; the record `8 + 5 = [ ]` three rows under, its box live from the
/// start. The line names the way: make a ten (slide counters up from the bottom row: each snaps into the next place, the
/// full row's outline goes bold with 10 at its end; one more than fits goes back, "The top row is full. That's 10."), pair
/// them up (the bottom row starts a block to the right; slide it under: a line joins each pair, the extra one rings), or back
/// to 10 (slide along the top: the bottom row's counters are crossed first, then the top's). Once the hands have found it
/// the record writes the way (8 + 5 = 10 + 3 = [ ]); a right answer written straight away plays the way (See).
///
/// Hand: "grab", "gx", "gy", "dx", "dy"; "g" the bottom counter grabbed (make a ten), "d0"/"k0" where it started. Kept: "up" a
/// bitmask of the bottom counters moved up, "dx" the bottom row's offset (pairs), "k" how many crossed (back), "w" the way
/// found, "full" one too many slid up.
@MainActor
struct Facts2Lesson: PaperLesson {
    static let PL = 3.0, TY = 0.0, BY = 4.0
    var liveKeys: Set<String> { ["dx", "dy", "k"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }

    private struct Lay {
        let P: Facts2.Parts, up: [Int], bottom: [Int], dx: Double, k: Int, way: Bool
        var room: Int { 10 - P.big - up.count }
    }
    private func lay(_ s: PaperState) -> Lay {
        let P = Facts2.Parts(s.numbers), kept = s.run.kept, done = at(s) >= 1
        let mask = Int(kept["up"] ?? 0)
        var up = (0..<P.small).filter { mask & (1 << $0) != 0 }
        var dx = kept["dx"] ?? 5, k = Int(kept["k"] ?? 0)
        let way = done || (kept["w"] ?? 0) != 0
        if done {
            // the way played on the picture (See), if the hands hadn't found it
            switch P.kind {
            case .ten: let need = 10 - P.big; if up.count < need { up += (0..<P.small).filter { !up.contains($0) }.suffix(need - up.count) }; up.sort()
            case .pairs: dx = 0
            case .back: k = P.b
            }
        }
        return Lay(P: P, up: up, bottom: (0..<P.small).filter { !up.contains($0) }, dx: P.kind == .pairs ? dx : 0, k: k, way: way)
    }

    func say(_ s: PaperState) -> String? {
        guard at(s) == 0 else { return nil }
        let kept = s.run.kept, P = Facts2.Parts(s.numbers)
        if (kept["w"] ?? 0) != 0 { return ((kept["full"] ?? 0) != 0 ? "The top row is full. That's 10. " : "") + G2.write }
        if let o = kept["over"], o > 0 { return "That's \(Int(o)). Take \(P.b) away." }
        return nil
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let L = lay(s), P = L.P, st = at(s), PL = Self.PL, TY = Self.TY, BY = Self.BY
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let held = s.grabbed && st == 0
        let dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0, g = Int(s.h("g") ?? -1)
        // the places: two rows of ten, dashed; the top row bold with 10 at its end once full
        let topFull = P.kind == .back || (P.kind == .ten && L.up.count == 10 - P.big)
        A1.places(&pic, "pt", x: 0, y: TY, full: topFull && P.kind == .ten)
        let bx = P.kind == .pairs ? (held ? max(-3, min(10, (s.h("d0") ?? L.dx) + dx)) : L.dx) : 0
        if P.kind == .pairs && held { A1.places(&live, "pb", x: bx, y: BY) } else { A1.places(&pic, "pb", x: bx, y: BY) }
        if topFull && P.kind == .ten { pic.word("full10", "10", at: 30.5, TY + 1.5, KK.maths.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5)) }
        var ro: String?
        switch P.kind {
        case .ten:
            for i in 0..<P.big { A2.counter(&pic, "T\(i)", x: Double(i) * PL, y: TY, .solid, size: 3) }
            for (j, id) in L.up.enumerated() { A2.counter(&pic, "B\(id)", x: Double(P.big + j) * PL, y: TY, .striped, size: 3) }
            let carried = held && g >= 0 ? Array(L.bottom.drop { $0 != g }) : []
            for (j, id) in L.bottom.enumerated() {
                if carried.contains(id) { A2.counter(&live, "B\(id)", x: Double(j) * PL + dx, y: BY + dy, .striped, size: 3) }
                else { A2.counter(&pic, "B\(id)", x: Double(j) * PL, y: BY, .striped, size: 3) }
            }
            if held, dy < -2, !carried.isEmpty { let f = min(carried.count, L.room); ro = "\(P.big + L.up.count + f) + \(L.bottom.count - f)" }
        case .pairs:
            for i in 0..<P.a { A2.counter(&pic, "T\(i)", x: Double(i) * PL, y: TY, .solid, size: 3) }
            for j in 0..<P.b {
                if held { A2.counter(&live, "B\(j)", x: bx + Double(j) * PL, y: BY, .striped, size: 3) }
                else { A2.counter(&pic, "B\(j)", x: bx + Double(j) * PL, y: BY, .striped, size: 3) }
            }
            if L.way || (held && abs(bx) <= 1.5) {
                var pen = held ? live : pic
                for j in 0..<P.small { pen.line("pair\(j)", [(Double(j) * PL + 1.5, TY + 2.7), (Double(j) * PL + 1.5, BY + 0.3)], .chapter) }
                if P.a != P.b { pen.circle("extra", at: Double(P.small) * PL + 1.5, (P.a > P.b ? TY : BY) + 1.5, radius: 1.45, .chapter) }
                if held { live = pen } else { pic = pen }
                if held { ro = P.found }
            }
        case .back:
            let k = held ? max(0, min(P.a, Int(s.h("k0") ?? 0) + Int((dx / PL).rounded()))) : L.k
            let order = (0..<P.ro).reversed().map { "B\($0)" } + (0..<10).reversed().map { "T\($0)" }
            let out = Set(order.prefix(k))
            var pen = held ? live : pic
            for i in 0..<10 { A2.counter(&pen, "T\(i)", x: Double(i) * PL, y: TY, .solid, cross: out.contains("T\(i)"), size: 3) }
            for j in 0..<P.ro { A2.counter(&pen, "B\(j)", x: Double(j) * PL, y: BY, .solid, cross: out.contains("B\(j)"), size: 3) }
            if held { live = pen } else { pic = pen }
            if held, k > 0 { ro = k < P.ro ? "\(k)" : k == P.ro ? "\(P.ro) … back to 10" : "\(P.ro) … back to 10 … \(k - P.ro) more: \(P.a - k) left" }
        }
        if let ro { live.reads(ro) }
        // a hint: the rows (a first miss), the answer by its box (a second)
        if st == 0 && s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: TY, w: 30, h: 7) }

        // the record: the way the hands went, then the box (live from the start)
        var toks: [M7.Tok] = [.n(P.a), .op(P.sign), .n(P.b), .op("=")]
        if L.way && !P.way.isEmpty { toks += P.way.map { Int($0).map { M7.Tok.n($0) } ?? .op($0) } + [.op("=")] }
        if st >= 1 { M7.row(&rec, "rec", toks + [.n(P.ans, .chapter)], x: 0, line: 1) }
        else {
            let end = M7.row(&rec, "rec", toks + [.box("x", cells: 2)], x: 0, line: 1)
            if s.on("spot") { A1.note(&rec, "spot", "\(P.ans)", x: end + 1, y: 1) }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        guard at(s) == 0 else { return nil }
        let L = lay(s), P = L.P, PL = Self.PL
        if (s.run.kept["w"] ?? 0) != 0 { return nil }
        func dragged(_ q: CGPoint, _ held: Numbers) -> Numbers {
            var h = held; h["dx"] = q.x - (held["gx"] ?? q.x); h["dy"] = q.y - (held["gy"] ?? q.y); return h
        }
        switch P.kind {
        case .ten:
            return Hands(
                grab: { q in
                    guard !L.bottom.isEmpty, q.y >= Self.BY - 0.3, q.y <= Self.BY + 3.3, q.x >= -0.3, q.x <= Double(L.bottom.count) * PL + 0.3 else { return nil }
                    let j = max(0, min(L.bottom.count - 1, Int(q.x / PL)))
                    return ["grab": 1, "g": Double(L.bottom[j]), "gx": q.x, "gy": q.y, "dx": 0, "dy": 0]
                },
                drag: { q, held in dragged(q, held) },
                release: { held in
                    guard (held["dy"] ?? 0) < -2, let g = held["g"].map({ Int($0) }) else { return HandMove(hand: [:]) }
                    let carried = Array(L.bottom.drop { $0 != g }), go = Array(carried.prefix(L.room))
                    var mask = Int(s.run.kept["up"] ?? 0)
                    for id in go { mask |= 1 << id }
                    var keep: Numbers = ["up": Double(mask)]
                    if carried.count > L.room { keep["full"] = 1 }
                    if L.up.count + go.count == 10 - P.big { keep["w"] = 1 }
                    return HandMove(hand: [:], keep: keep)
                })
        case .pairs:
            return Hands(
                grab: { q in
                    guard q.y >= Self.BY - 0.3, q.y <= Self.BY + 3.3, q.x >= L.dx - 0.3, q.x <= L.dx + Double(P.b) * PL + 0.3 else { return nil }
                    return ["grab": 1, "gx": q.x, "gy": q.y, "dx": 0, "dy": 0, "d0": L.dx]
                },
                drag: { q, held in dragged(q, held) },
                release: { held in
                    let x = max(-3, min(10, (held["d0"] ?? 5) + (held["dx"] ?? 0)))
                    return abs(x) <= 1.5 ? HandMove(hand: [:], keep: ["dx": 0, "w": 1]) : HandMove(hand: [:], keep: ["dx": 5])
                })
        case .back:
            return Hands(
                grab: { q in
                    guard q.y >= Self.TY - 0.3, q.y <= Self.BY + 3.3, q.x >= -0.3, q.x <= 30.3 else { return nil }
                    return ["grab": 1, "gx": q.x, "gy": q.y, "dx": 0, "dy": 0, "k0": Double(L.k)]
                },
                drag: { q, held in dragged(q, held) },
                release: { held in
                    let k0 = Int(held["k0"] ?? 0), k = max(0, min(P.a, k0 + Int(((held["dx"] ?? 0) / PL).rounded())))
                    if k == P.b { return HandMove(hand: [:], keep: ["k": Double(k), "w": 1, "over": 0]) }
                    if k > P.b { return HandMove(hand: [:], keep: ["k": Double(k0), "over": Double(k)]) }
                    return HandMove(hand: [:], keep: ["k": Double(k), "over": 0])
                })
        }
    }

    /// Show me: the way played first, then the answer written.
    func typedDemo(_ s: PaperState) -> [GhostMove] {
        guard at(s) == 0, (s.run.kept["w"] ?? 0) == 0 else { return [] }
        let L = lay(s), P = L.P, PL = Self.PL
        switch P.kind {
        case .ten:
            let need = L.room, j = max(0, L.bottom.count - need)
            return [.drag(from: CGPoint(x: Double(j) * PL + 1.5, y: Self.BY + 1.5), to: CGPoint(x: Double(P.big + L.up.count) * PL + 1.5, y: Self.TY + 1.5))]
        case .pairs: return [.drag(from: CGPoint(x: L.dx + 1.5, y: Self.BY + 1.5), to: CGPoint(x: 1.5, y: Self.BY + 1.5))]
        case .back: return [.drag(from: CGPoint(x: 1.5, y: Self.TY + 1.5), to: CGPoint(x: 1.5 + Double(P.b - L.k) * PL, y: Self.TY + 1.5))]
        }
    }

    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Facts2.Parts(s.numbers)
        return at(s) == 0 ? ["x": Double(P.slips.first { $0.0 != P.ans && $0.0 >= 0 }?.0 ?? P.ans + 1)] : nil
    }
}
