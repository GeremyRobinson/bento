import SwiftUI

/// Add up to four numbers on the paper, as in the preview (design/prototype/grade2-ch1.html, dAddFour): the first number at
/// the left, where the total builds; the others in a column at the right, each its ten rows and its ones row, a square
/// apart; the column form beside. Slide every number's ones over in any order (they count on, a full row starts the next;
/// holding a ones row lights another whose ones make 10 with it, "4 and 6 make 10"); tap each full row (it closes into a ten
/// under the tens, a small 1 or 2 over the tens in the column); slide the others' tens over; write the sum.
///
/// Hand: "grab", "gx", "gy", "dx", "dy", "k" the number carried, "w" (1 ones, 2 tens, 0 a dead grab). Kept: "s1"… the order
/// each ones row went over in, "u1"… the tens', "G" the new tens made, "lx", "ly", "lw", "lk" the last carry let go.
@MainActor
struct AddFour2Lesson: PaperLesson {
    static let RX = 25.0
    var liveKeys: Set<String> { ["dx", "dy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func Y(_ r: Int) -> Double { A2.row * Double(r) }

    private struct Lay {
        let P: AddFour2.Parts, sOrder: [Int], uOrder: [Int], G: Int
        var startRow: [Int] {
            var out = [0, 0]
            for k in 1..<max(1, P.n - 1) { out.append(out[k] + P.t[k] + (P.o[k] > 0 ? 1 : 0)) }
            return Array(out.prefix(P.n))
        }
        var tens: [(String, A2.Style)] {
            (0..<P.t[0]).map { ("A.t\($0)", A2.Style.solid) } + (0..<G).map { ("G.t\($0)", .solid) }
                + uOrder.flatMap { k in (0..<P.t[k]).map { ("N\(k).t\($0)", A2.Style.striped) } }
        }
        /// The ones on the left, in rows of ten after the new tens took theirs: id, style, its count while counting.
        var ones: [(String, A2.Style, Int)] {
            let all = (0..<P.o[0]).map { ("A.o\($0)", A2.Style.solid) } + sOrder.flatMap { k in (0..<P.o[k]).map { ("N\(k).o\($0)", A2.Style.striped) } }
            return all.enumerated().map { ($1.0, $1.1, $0 + 1) }.dropFirst(10 * G).map { $0 }
        }
    }
    private func lay(_ s: PaperState) -> Lay {
        let P = AddFour2.Parts(s.numbers), st = at(s), k = s.run.kept
        func order(_ key: String, all: Bool) -> [Int] {
            all ? (1..<P.n).filter { key == "s" ? P.o[$0] > 0 : true }.sorted { (k["\(key)\($0)"] ?? Double($0)) < (k["\(key)\($1)"] ?? Double($1)) }
                : (1..<P.n).filter { k["\(key)\($0)"] != nil }.sorted { k["\(key)\($0)"]! < k["\(key)\($1)"]! }
        }
        return Lay(P: P, sOrder: order("s", all: st >= 1), uOrder: order("u", all: st >= 3), G: st >= 2 ? P.G : Int(k["G"] ?? 0))
    }

    func recordBeside(_ n: Numbers) -> Double? { 0 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let L = lay(s), P = L.P, st = at(s), RX = Self.RX, kept = s.run.kept, SR = L.startRow
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let held = s.grabbed && (s.h("w") ?? 0) != 0, w = Int(s.h("w") ?? 0), hk = Int(s.h("k") ?? -1)
        let dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0
        if !held, let lw = kept["lw"], let lk = kept["lk"].map({ Int($0) }), lk < P.n {
            let lx = kept["lx"] ?? 0, ly = kept["ly"] ?? 0
            pic.sketch.from = A2.kinds { q in
                if lw == 1 { for j in 0..<P.o[lk] { A2.counter(&q, "N\(lk).o\(j)", x: RX + 2 * Double(j) + lx, y: Y(SR[lk] + P.t[lk]) + ly, .striped) } }
                else { for r in 0..<P.t[lk] { A2.ten(&q, "N\(lk).t\(r)", x: RX + lx, y: Y(SR[lk] + r) + ly, .striped) } }
            }
        }
        let tens = L.tens, ones = L.ones
        for (r, t) in tens.enumerated() { A2.ten(&pic, t.0, x: 0, y: Y(r), t.1) }
        for (j, o) in ones.enumerated() { A2.counter(&pic, o.0, x: 2 * Double(j % 10), y: Y(tens.count + j / 10), o.1, n: st <= 1 && o.1 == .striped ? o.2 : nil) }
        if st == 1 { for c in 0..<(ones.count / 10) { pic.sketch.box("full\(c)", pic.R(0, Y(tens.count + c), 20, 2), .chapter, width: Sketch.stroke) } }
        pic.sketch.from = [:]
        // the others in a column at the right, each at home unless carried or gone over
        for k in 1..<P.n {
            if !L.uOrder.contains(k) {
                for r in 0..<P.t[k] {
                    if held && w == 2 && hk == k { A2.ten(&live, "N\(k).t\(r)", x: RX + dx, y: Y(SR[k] + r) + dy, .striped) }
                    else { A2.ten(&pic, "N\(k).t\(r)", x: RX, y: Y(SR[k] + r), .striped) }
                }
            }
            if !L.sOrder.contains(k) {
                for j in 0..<P.o[k] {
                    if held && w == 1 && hk == k { A2.counter(&live, "N\(k).o\(j)", x: RX + 2 * Double(j) + dx, y: Y(SR[k] + P.t[k]) + dy, .striped) }
                    else { A2.counter(&pic, "N\(k).o\(j)", x: RX + 2 * Double(j), y: Y(SR[k] + P.t[k]), .striped) }
                }
            }
        }
        if held && w > 0 {
            let o = over(L, w, hk, dx, dy), pt = w == 1 ? partner(L, hk) : nil
            if let pt { live.sketch.box("lit", pt == 0 ? live.R(0, Y(tens.count), 2 * Double(P.o[0]), 2) : live.R(RX, Y(SR[pt] + P.t[pt]), 2 * Double(P.o[pt]), 2), .chapter, width: Sketch.stroke) }
            if w == 1 {
                let sums = [P.o[0]] + L.sOrder.map { P.o[$0] }
                live.reads(pt.map { "\(P.o[hk]) and \(P.o[$0]) make 10" } ?? (o == 1 ? "\((sums + [P.o[hk]]).map(String.init).joined(separator: " + ")) = \(sums.reduce(0, +) + P.o[hk])" : G2.count(P.o[hk], "one")))
            } else {
                let parts = [P.t[0]] + L.uOrder.map { P.t[$0] } + Array(repeating: 1, count: L.G)
                live.reads(o != 0 ? "\((parts + [P.t[hk]]).map(String.init).joined(separator: " + ")) = \(parts.reduce(0, +) + P.t[hk]) tens" : G2.count(P.t[hk], "ten"))
            }
        }

        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        switch st {
        case 0:
            if ring { KK.hintBox(&pic, "hr", x: 0, y: Y(tens.count), w: 20, h: 2) }
            if spot { pic.sketch.box("spot", pic.R(2 * Double(ones.count % 10), Y(tens.count + ones.count / 10), 2 * Double(10 - ones.count % 10), 2), .chapter, width: Sketch.stroke, dashed: true) }
        case 1:
            if ring { KK.hintBox(&pic, "hr", x: 0, y: Y(tens.count), w: 20, h: A2.row * Double((ones.count + 9) / 10) - 1) }
            if spot { KK.hintBox(&pic, "spot", x: -0.5, y: Y(tens.count) - 0.5, w: 21, h: 3) }
        case 2:
            if ring { KK.hintBox(&pic, "hr", x: 0, y: Y(0), w: 20, h: A2.row * Double(tens.count) - 1) }
            if spot { pic.sketch.box("spot", pic.R(0, Y(tens.count), 20, 2), .chapter, width: Sketch.stroke, dashed: true) }
        case 3: if ring { KK.hintBox(&pic, "hr", x: 0, y: Y(0), w: 20, h: A2.row * Double(tens.count + 1) - 1) }
        default: break
        }

        // the record: the column form, a small 1 (or 2) over the tens for each new ten
        let mid = A2.column(&rec, "col", x: 0, y: 1, P.nums, sign: "+")
        if L.G > 0 { rec.word("carry\(L.G)", "\(L.G)", at: 3, 0.4, A2.carry) }
        if st == 3 { A2.answer(&rec, "ans", x: 0, mid: mid, done: nil); if spot { A1.note(&rec, "spot", "\(P.sum)", x: 7, y: mid) } }
        else if st == 4 { A2.answer(&rec, "ans", x: 0, mid: mid, done: P.sum) }
        else { rec.sketch.box("answ", rec.R(2, mid - 1, 4, 2), .ink3, width: Sketch.stroke) }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    /// Where a carried row would land: 1 the left's ones, 2 its tens, 0 nowhere.
    private func over(_ L: Lay, _ w: Int, _ k: Int, _ dx: Double, _ dy: Double) -> Int {
        let P = L.P, SR = L.startRow
        let cx = Self.RX + dx + (w == 1 ? Double(P.o[k]) : 10)
        let cy = (w == 1 ? Y(SR[k] + P.t[k]) + 1 : Y(SR[k]) + (A2.row * Double(P.t[k]) - 1) / 2) + dy
        guard cx > -3, cx < 23 else { return 0 }
        return cy >= Y(L.tens.count) - 1.5 ? 1 : 2
    }
    /// Holding a ones row: another whose ones make 10 with it (0 the left's own, before any are over).
    private func partner(_ L: Lay, _ k: Int) -> Int? {
        let P = L.P
        if L.sOrder.isEmpty && P.o[0] + P.o[k] == 10 { return 0 }
        return (1..<P.n).first { $0 != k && !L.sOrder.contains($0) && P.o[$0] > 0 && P.o[$0] + P.o[k] == 10 }
    }

    func hands(_ s: PaperState) -> Hands? {
        let L = lay(s), P = L.P, RX = Self.RX, st = at(s), SR = L.startRow, kept = s.run.kept
        func inBox(_ q: CGPoint, _ x: Double, _ y: Double, _ w: Double, _ h: Double) -> Bool { q.x >= x - 0.5 && q.x <= x + w + 0.5 && q.y >= y - 0.5 && q.y <= y + h + 0.5 }
        func carry(_ what: Int) -> Hands {
            Hands(
                grab: { q in
                    for k in 1..<P.n {
                        if what == 1, P.o[k] > 0, !L.sOrder.contains(k), inBox(q, RX, Y(SR[k] + P.t[k]), 2 * Double(P.o[k]), 2) {
                            return ["grab": 1, "w": 1, "k": Double(k), "gx": q.x, "gy": q.y, "dx": 0, "dy": 0]
                        }
                        if !L.uOrder.contains(k), inBox(q, RX, Y(SR[k]), 20, A2.row * Double(P.t[k]) - 1) {
                            return what == 2 ? ["grab": 1, "w": 2, "k": Double(k), "gx": q.x, "gy": q.y, "dx": 0, "dy": 0] : ["grab": 1, "w": 0]
                        }
                    }
                    return nil
                },
                drag: { q, held in
                    var h = held; guard (held["w"] ?? 0) != 0 else { return h }
                    h["dx"] = q.x - (held["gx"] ?? q.x); h["dy"] = q.y - (held["gy"] ?? q.y); return h
                },
                release: { held in
                    let w = Int(held["w"] ?? 0), k = Int(held["k"] ?? 1)
                    if w == 0 { return HandMove(hand: [:], missHand: [:], set: [("o", -2)], check: true) }
                    let dx = held["dx"] ?? 0, dy = held["dy"] ?? 0, o = over(L, w, k, dx, dy), moved = hypot(dx, dy) > 2
                    var keep: Numbers = ["lx": dx, "ly": dy, "lw": Double(w), "lk": Double(k)]
                    let box = w == 1 ? "o" : "t"
                    if (w == 1 && o == 1) || (w == 2 && o != 0) {
                        let done = w == 1 ? L.sOrder.count + 1 : L.uOrder.count + 1
                        keep["\(w == 1 ? "s" : "u")\(k)"] = Double(done)
                        let all = w == 1 ? P.withOnes.count : P.n - 1
                        if done == all { return HandMove(hand: [:], missHand: [:], set: [(box, Double(w == 1 ? P.O : P.n - 1))], keep: keep, check: true) }
                        return HandMove(hand: [:], keep: keep)
                    }
                    if moved { return HandMove(hand: [:], missHand: [:], set: [(box, -1)], keep: keep, check: true) }
                    return HandMove(hand: [:])
                })
        }
        switch st {
        case 0: return carry(1)
        case 1:
            return Hands(tap: { q in
                guard q.x >= -0.5, q.x <= 20.5 else { return nil }
                let c = Int((q.y + 0.5) / A2.row) - L.tens.count, ones = L.ones.count
                guard c >= 0, c * 10 < ones else { return nil }
                let n = min(10, ones - 10 * c)
                if n < 10 { return HandMove(hand: nil, missHand: nil, set: [("g", -Double(n) - 1)], check: true) }
                let G = Int(kept["G"] ?? 0) + 1
                if G == P.G { return HandMove(hand: nil, missHand: nil, set: [("g", Double(G))], keep: ["G": Double(G)], check: true) }
                return HandMove(hand: nil, keep: ["G": Double(G)])
            })
        case 2: return carry(2)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let L = lay(s), P = L.P, RX = Self.RX, SR = L.startRow
        switch at(s) {
        case 0: return P.withOnes.filter { !L.sOrder.contains($0) }.map { k in .drag(from: CGPoint(x: RX + 1, y: Y(SR[k] + P.t[k]) + 1), to: CGPoint(x: 1, y: Y(L.tens.count) + 1)) }
        case 1: return (L.G..<P.G).map { i in .tap(.picture(CGPoint(x: 10, y: Y(P.t[0] + i) + 1))) }
        case 2: return (1..<P.n).filter { !L.uOrder.contains($0) }.map { k in .drag(from: CGPoint(x: RX + 10, y: Y(SR[k]) + 1), to: CGPoint(x: 10, y: Y(L.tens.count) + 1)) }
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let L = lay(s)
        switch at(s) {
        case 0: return HandMove(hand: [:], missHand: [:], set: [("o", -2)], check: true)
        case 1: return HandMove(hand: nil, missHand: nil, set: [("g", -Double(L.P.O % 10) - 1)], check: true)
        case 2: return HandMove(hand: [:], missHand: [:], set: [("t", -1)], check: true)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        at(s) == 3 ? ["x": Double(AddFour2.Parts(s.numbers).slips[0].0)] : nil
    }
}
