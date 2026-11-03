import SwiftUI

/// Reading and writing big numbers on the paper, as in the preview (design/prototype/grade4-ch1.html): the whole place
/// chart, six columns, 2-square disks, one frame to a column. A (name to number): the name is written over the chart; tap
/// a column to put a disk in (or drag along it: the frame fills up to the finger), tap a disk to take it out; the number
/// built is named under the chart as it grows; Check. Done, "= 40,605" goes on from the name. B (number to its parts):
/// the digits under their disks; pull each digit down out of the chart: zeros follow it from every place to its right,
/// and it lands in the record as its value: 305,280 = 300,000 + 5,000 + 200 + 80.
@MainActor
struct ReadWriteLesson: PaperLesson {
    static let chart = PlaceChart(n: 6, c: 2, pr: 1, y0: 0)
    /// A: the name on row 1, the chart from row 3 (frames from 6, its bottom 11), the number built named on row 13.
    /// B: the chart from row 0 (frames from 3, bottom 8), the digits on row 10, the parts from row 14.
    static func rows(_ a: Bool) -> (top: Double, y0: Double, bottom: Double) { a ? (3, 6, 11) : (0, 3, 8) }
    static let title = 1.0, built = 13.0, digits = 10.0, parts = 14.0

    var liveKeys: Set<String> { ["dx", "dy"] }
    private static let say = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)

    private func stage(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func chart(_ a: Bool) -> PlaceChart { PlaceChart(n: 6, c: 2, pr: 1, y0: Self.rows(a).y0) }

    /// A: the disks in each column now (all of the number's once it's built).
    private func counts(_ s: PaperState, _ P: ReadWriteBig.Parts) -> [Int] {
        stage(s) >= 2 ? (0..<6).map { P.digit($0) } : (0..<6).map { Int((s.h("c\($0)") ?? 0).rounded()) }
    }
    private static func value(_ c: [Int]) -> Int { c.enumerated().reduce(0) { $0 + $1.element * BigNumbers.pow10($1.offset) } }
    /// B: the places pulled so far (all of them once done).
    private func pulled(_ s: PaperState, _ P: ReadWriteBig.Parts) -> Set<Int> {
        if stage(s) >= 2 { return Set(P.parts) }
        let m = Int((s.h("m") ?? 0).rounded())
        return Set((0..<6).filter { m & (1 << $0) != 0 })
    }
    /// B's parts in the record: each in its own place, in place order, a "+" before all but the first, wrapping at 62.
    private static func slots(_ P: ReadWriteBig.Parts) -> [Int: (x: Double, y: Double, plus: Bool)] {
        var out: [Int: (x: Double, y: Double, plus: Bool)] = [:], x = 3.0, y = parts
        for (i, pw) in P.parts.enumerated() {
            let w = 2 * Double(String(P.value(pw)).count) + (i > 0 ? 3 : 0)
            if x + w > 62 { x = 0; y += 3 }
            out[pw] = (x, y, i > 0); x += w
        }
        return out
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = ReadWriteBig.Parts(s.numbers), at = stage(s), R = Self.rows(P.a), ch = chart(P.a)
        var pic = GridPen(), live = GridPen(stableIds: true)
        ch.draw(&pic, "ch", bands: [(R.y0, { _ in 1 })], top: R.top, bottom: R.bottom)
        if P.a {
            // the name, written once as the title; done, "= 40,605" goes on from it
            pic.word("title", P.name, at: 0, Self.title, Self.say, anchor: UnitPoint(x: 0, y: 0.5))
            let c = counts(s, P), b = Self.value(c)
            for pw in 0..<6 { for j in 0..<c[pw] { ch.disk(&pic, "a\(pw).\(j)", at: ch.slot(pw, j)) } }
            if at >= 2 {
                let x = (PaperText.width(P.name, PaperText.font(Sketch.wordSize, .medium)) / Paper.cell + 1).rounded(.up)
                Record.line(&pic, "eq", [.op("="), .n(P.N)], x: x, row: Self.title, colours: [1: .chapter])
            } else if b > 0 {
                // the number built, named under the chart as it grows
                pic.word("built", BigNumbers.name(b), at: 0, Self.built, Self.say.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5))
                if s.grabbed { live.reads(BigNumbers.commas(b)) }
            }
            // a hint: the first place that's off, outlined
            if at == 1, s.on("ring"), let k = (0..<6).reversed().first(where: { c[$0] != P.digit($0) }) {
                pic.sketch.box("ring\(k)", pic.R(ch.colX(k) + 0.5, R.y0 + 0.5, ch.cw - 1, 2 * ch.c - 1), .chapter, width: Sketch.stroke, dashed: true)
            }
            return PaperDrawing(picture: pic.sketch, live: live.sketch, actions: at == 1 ? ["Check"] : [],
                                extent: CGRect(x: 0, y: 0, width: ch.right * Paper.cell, height: (Self.built + 1) * Paper.cell))
        }
        // B: the disks, the digits under them, the comma under the line between the thousands and the hundreds
        for pw in 0..<6 { for j in 0..<P.digit(pw) { ch.disk(&pic, "b\(pw).\(j)", at: ch.slot(pw, j)) } }
        let done = pulled(s, P), held = s.grabbed ? Int((s.h("p") ?? -1).rounded()) : -1
        for pw in 0..<P.length {
            let colour: Sketch.Colour = pw == held ? .ink3 : done.contains(pw) ? .chapter : .ink
            pic.word("dg\(pw)", "\(P.digit(pw))", at: ch.mid(pw), Self.digits, Record.maths.colour(colour))
        }
        if P.length > 3 { pic.word("dgc", ",", at: ch.colX(2), Self.digits, Record.maths) }
        // the digit being pulled, its zeros following from every place to its right
        if held >= 0 {
            let dx = s.h("dx") ?? 0, dy = max(0, s.h("dy") ?? 0)
            for z in stride(from: held, through: 0, by: -1) {
                live.word("pz\(z)", z == held ? "\(P.digit(held))" : "0", at: ch.mid(z) + dx, Self.digits + dy, Record.maths.colour(.chapter))
            }
            live.reads("\(P.digit(held)) \(BigNumbers.place(held, P.digit(held)))")
        }
        // the record: =, and each part in its place as it lands
        let slots = Self.slots(P)
        if !done.isEmpty {
            Record.line(&pic, "recEq", [.op("=")], x: 0, row: Self.parts)
            for pw in P.parts where done.contains(pw) {
                let sl = slots[pw]!
                Record.line(&pic, "part\(pw)", (sl.plus ? [.op("+")] : []) + [.n(P.value(pw))], x: sl.x, row: sl.y, colours: [sl.plus ? 1 : 0: .chapter])
            }
        }
        // a hint: the next digit to pull, ringed
        if at == 1, s.on("ring"), let k = P.parts.first(where: { !done.contains($0) }) {
            pic.circle("ring\(k)", at: ch.mid(k), Self.digits, radius: 1.6, .chapter, dashed: true)
        }
        let lastRow = slots.values.map(\.y).max() ?? Self.parts
        return PaperDrawing(picture: pic.sketch, live: live.sketch,
                            extent: CGRect(x: 0, y: 0, width: ch.right * Paper.cell, height: (lastRow + 1) * Paper.cell))
    }

    /// Everything is on the picture: the record is the name's "= 40,605" (A) or the parts (B), both written there.
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func messageRows(_ n: Numbers) -> Int { 2 }

    func hands(_ s: PaperState) -> Hands? {
        guard stage(s) == 1 else { return nil }
        let P = ReadWriteBig.Parts(s.numbers), R = Self.rows(P.a), ch = chart(P.a)
        if P.a {
            /// The cell of a column's frame under a finger (0 to 9), or nil.
            func cell(_ q: CGPoint) -> (pw: Int, i: Int)? {
                guard let pw = ch.place(at: q.x), q.y >= R.y0 - 0.5, q.y <= R.y0 + 2 * ch.c + 0.5 else { return nil }
                let col = min(4, max(0, Int(((q.x - ch.colX(pw)) / ch.c).rounded(.down)))), row = min(1, max(0, Int(((q.y - R.y0) / ch.c).rounded(.down))))
                return (pw, row * 5 + col)
            }
            func move(_ c: [Int], extra: Numbers = [:], keepHold: Bool = false) -> HandMove {
                var h: Numbers = extra
                for (k, v) in c.enumerated() where v > 0 { h["c\(k)"] = Double(v) }
                let b = Self.value(c)
                return HandMove(hand: h, missHand: nil, set: [("x", b > 0 ? Double(b) : nil)])
            }
            let now = counts(s, P)
            return Hands(
                // tap a disk: it comes out; tap the empty part of a column: one more goes in
                tap: { q in
                    guard let (pw, i) = cell(q) else { return nil }
                    var c = now
                    if i < c[pw] { c[pw] -= 1 } else if c[pw] < 9 { c[pw] += 1 } else { return nil }
                    return move(c)
                },
                // drag along a column: its frame fills up to the finger (at most 9: a place holds 9 at most)
                grab: { q in
                    guard let (pw, i) = cell(q) else { return nil }
                    var h = s.hand; h["grab"] = 1; h["col"] = Double(pw); h["c\(pw)"] = Double(min(9, i + 1))
                    return h
                },
                drag: { q, h in
                    var h = h
                    if let (pw, i) = cell(q), pw == Int((h["col"] ?? -1).rounded()) { h["c\(pw)"] = Double(min(9, i + 1)) }
                    return h
                },
                release: { h in
                    let c = (0..<6).map { Int((h["c\($0)"] ?? 0).rounded()) }
                    return move(c)
                },
                actions: ["Check": { HandMove(hand: nil, missHand: nil, set: [], check: true) }])
        }
        // B: a digit pulled down out of the chart; a 0 tapped (or pulled) won't come
        let done = pulled(s, P)
        func digitAt(_ q: CGPoint) -> Int? {
            guard abs(q.y - Self.digits) <= 1.6, let pw = ch.place(at: q.x), pw < P.length else { return nil }
            return pw
        }
        return Hands(
            tap: { q in
                guard let pw = digitAt(q), P.digit(pw) == 0 else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("x", -Double(pw + 1))], check: true)
            },
            grab: { q in
                guard let pw = digitAt(q), !done.contains(pw), P.digit(pw) != 0 else { return nil }
                return ["grab": 1, "p": Double(pw), "fx": q.x, "fy": q.y, "dx": 0, "dy": 0, "m": s.h("m") ?? 0]
            },
            drag: { q, h in
                var h = h
                h["dx"] = (q.x - (h["fx"] ?? 0)).rounded(); h["dy"] = (q.y - (h["fy"] ?? 0)).rounded()
                return h
            },
            release: { h in
                let pw = Int((h["p"] ?? 0).rounded()), m = Int((h["m"] ?? 0).rounded())
                guard (h["dy"] ?? 0) >= 2.5 else { return HandMove(hand: ["m": Double(m)], missHand: nil, set: [("x", -100)], check: true) }
                let now = m | (1 << pw), count = (0..<6).filter { now & (1 << $0) != 0 }.count
                let all = count == P.parts.count
                return HandMove(hand: ["m": Double(now)], missHand: nil, set: [("x", Double(count))], check: all)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard stage(s) == 1 else { return [] }
        let P = ReadWriteBig.Parts(s.numbers), ch = chart(P.a)
        if P.a {
            let now = counts(s, P)
            var moves: [GhostMove] = []
            for pw in (0..<6).reversed() where now[pw] != P.digit(pw) {
                let d = P.digit(pw)
                if d == 0 { for _ in 0..<now[pw] { moves.append(.tap(.picture(ch.slot(pw, 0)))) }; continue }
                moves.append(d == 1 && now[pw] == 0 ? .tap(.picture(ch.slot(pw, 0))) : .drag(from: ch.slot(pw, 0), to: ch.slot(pw, d - 1)))
            }
            return moves + [.tap(.action("Check"))]
        }
        let done = pulled(s, P)
        return P.parts.filter { !done.contains($0) }.map { .drag(from: CGPoint(x: ch.mid($0), y: Self.digits), to: CGPoint(x: ch.mid($0), y: Self.digits + 4)) }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard stage(s) == 1 else { return nil }
        let P = ReadWriteBig.Parts(s.numbers)
        if P.a {
            // the trap: the number built without its empty places (40,605 as 4,605), else one off in the ones
            var digits = Array(String(P.N))
            if let z = digits.indices.dropFirst().first(where: { digits[$0] == "0" }) { digits.remove(at: z) }
            let squeezed = Int(String(digits)) ?? P.N
            let b = squeezed != P.N ? squeezed : P.N + 1
            var h: Numbers = [:]
            for k in 0..<6 where BigNumbers.digit(b, k) > 0 { h["c\(k)"] = Double(BigNumbers.digit(b, k)) }
            return HandMove(hand: h, missHand: nil, set: [("x", Double(b))], check: true)
        }
        // a digit let go too soon
        return HandMove(hand: nil, missHand: nil, set: [("x", -100)], check: true)
    }
}
