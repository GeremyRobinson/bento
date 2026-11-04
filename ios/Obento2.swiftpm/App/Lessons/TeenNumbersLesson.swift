import SwiftUI

/// Teen numbers on the paper, as in the preview (design/prototype/gradeK-ch5.html, lTeens). One block is one cell: two ten
/// frames side by side, a block apart (55 × 10 squares). Count these: the first frame full, named 10 under it; tap each dot
/// in the second frame (the full frame tapped: "That’s the full frame…"); its count is written under it. Then "Watch the 0.":
/// the count slides onto the 0 of 10 and covers it, and 10 + 6 = [16] is written on the number row grown to 20. Make a teen
/// (from index 3, every other problem): drag across the two empty frames, the first filling first, a dot a cell, the readout
/// counting; let go on the teen; write 16 = 10 + [6].
///
/// Kept: "o<k>" the second frame's dots counted in order, "again" a dot tapped that's wrong (frame·10 + cell). Hand (make):
/// "grab", "m" the dots made.
@MainActor
struct TeenNumbersLesson: PaperLesson {
    var liveKeys: Set<String> { ["m", "grab"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let f2 = 30.0, names = 12.0, keys = 20.0
    func recordRow(_ n: Numbers) -> Double? { 15 }
    /// The cell the finger is over, counted from the first frame's first: the first frame fills first, a row at a time.
    static func cellOf(_ q: CGPoint) -> Int {
        let f = q.x < 27.5 ? 0 : 1, c = max(0, min(4, Int(floor((q.x - (f == 1 ? f2 : 0)) / 5)))), r = q.y < 5 ? 0 : 1
        return 10 * f + 5 * r + c + 1
    }
    /// The i-th dot's cell (0-based), the first frame first.
    static func spot(_ i: Int) -> CGPoint { KT.cell(i < 10 ? 0 : f2, 0, i % 10) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = TeenNumbersK.Parts(s.numbers), st = at(s), ones = P.ones, n = P.n
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        KT.frame(&pic, "fa", x: 0, y: 0)
        KT.frame(&pic, "fb", x: Self.f2, y: 0)
        if P.make {
            if st == 3 {
                let m = Int((s.h("m") ?? 0).rounded())
                // what the finger has made follows it; let go, it stays; past the teen, the extra ones in red
                var pen = s.grabbed ? live : pic
                for i in 0..<m { let p = Self.spot(i); KK.counter(&pen, "m\(i)", p.x, p.y, num: nil) }
                if !s.grabbed && m > n { for i in n..<m { let p = Self.spot(i); pen.circle("mx\(i)", at: p.x, p.y, radius: 2.05, KK.red) } }
                if s.grabbed { live = pen; live.reads("\(m)") } else { pic = pen }
                if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: Self.f2, y: 0, w: 25, h: 10) }
                if s.on("spot") { let p = Self.spot(n - 1); pic.circle("spot", at: p.x, p.y, radius: 2.6, .chapter) }
            } else {
                // the dots made stay where they went, drawn at once
                pic.sketch.pace = 0
                for i in 0..<n { let p = Self.spot(i); KK.counter(&pic, "m\(i)", p.x, p.y, num: nil) }
                pic.sketch.pace = 1
                if st == 4 {
                    let (v, wrong) = KK.typed(s, "x", want: ones)
                    KA.line(&rec, "rec", [.n(n), .op("="), .n(10), .op("+")], value: v, wrong: wrong)
                    KK.numberRow(&pic, "nr", y: Self.keys, wrong: wrong ? v : nil, spot: s.on("spot") ? ones : nil)
                    if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: Self.f2, y: 0, w: 25, h: 10) }
                } else {
                    M7.row(&rec, "rec", [.n(n), .op("="), .n(10), .op("+"), .n(ones, .chapter)], x: 0, line: 1)
                }
            }
            return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, 55, 10))
        }
        for j in 0..<10 { let p = KT.cell(0, 0, j); KK.counter(&pic, "a\(j)", p.x, p.y, num: nil) }
        let list = KA.list(s, "o"), counted = st == 0 ? list : (list.count == ones ? list : Array(0..<ones))
        for j in 0..<ones {
            let p = KT.cell(Self.f2, 0, j), k = counted.firstIndex(of: j)
            KK.counter(&pic, "b\(j)", p.x, p.y, num: k.map { $0 + 1 }, ring: counted.count == ones && k == ones - 1)
        }
        // the names under the frames: 10, and the count once it's made; then the count slides onto the 0 and covers it
        pic.word("t1", "1", at: 12, Self.names, KK.maths)
        if st == 0 {
            pic.word("t0", "0", at: 13, Self.names, KK.maths)
            if counted.count == ones { pic.word("on", "\(ones)", at: 42.5, Self.names, KK.maths.colour(.chapter)) }
            if let a = KA.kept(s, "again") { KT.again(&pic, "again\(a)", a >= 10 ? KT.cell(0, 0, a - 10) : KT.cell(Self.f2, 0, a)) }
            let todo = (0..<ones).filter { !counted.contains($0) }
            if s.on("ring") && !s.on("spot") { for j in todo { let p = KT.cell(Self.f2, 0, j); KK.hint(&pic, "hr\(j)", p.x, p.y) } }
            if s.on("spot"), let j = todo.first { let p = KT.cell(Self.f2, 0, j); pic.circle("spot", at: p.x, p.y, radius: 2.6, .chapter) }
        } else {
            pic.sketch.delay = 0.3
            KM.seeded(&pic, was: { p in p.word("on", "\(ones)", at: 42.5, Self.names, KK.maths.colour(.chapter)) }) { p in
                p.word("on", "\(ones)", at: 13, Self.names, KK.maths.colour(.chapter))
            }
            pic.sketch.delay = 0
        }
        if st == 1 {
            let (v, wrong) = KK.typed(s, "x", want: n)
            KA.line(&rec, "rec", [.n(10), .op("+"), .n(ones), .op("=")], value: v, wrong: wrong)
            KT.twenty(&pic, "nr", y: Self.keys, lo: 0, wrong: wrong ? v : nil, spot: s.on("spot") ? n : nil)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: 0, w: 25, h: 10) }
        } else if st == 2 {
            M7.row(&rec, "rec", [.n(10), .op("+"), .n(ones), .op("="), .n(n, .chapter)], x: 0, line: 1)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = TeenNumbersK.Parts(s.numbers), ones = P.ones
        switch at(s) {
        case 0:
            let counted = KA.list(s, "o"), spots = (0..<ones).map { KT.cell(Self.f2, 0, $0) }, full = (0..<10).map { KT.cell(0, 0, $0) }
            return Hands(tap: { q in
                if let j = KT.hit(q, full) { return HandMove(hand: nil, missHand: nil, set: [("c", -1)], keep: ["again": Double(10 + j)], check: true) }
                guard let j = KT.hit(q, spots) else { return nil }
                if counted.contains(j) { return HandMove(hand: nil, missHand: nil, set: [("c", -2)], keep: ["again": Double(j)], check: true) }
                let done = counted.count + 1 == ones
                return HandMove(hand: nil, missHand: nil, set: done ? [("c", Double(ones))] : [], keep: ["o\(counted.count)": Double(j), "again": -1], check: done)
            })
        case 1:
            return Hands(tap: { q in KT.tappedTwenty(q, y: Self.keys, lo: 0).map { HandMove(hand: nil, missHand: nil, set: [("x", Double($0))], check: true) } })
        case 3:
            let inFrames = { (q: CGPoint) in q.y >= -1 && q.y <= 11 && q.x >= -1 && q.x <= 56 }
            func held(_ m: Int) -> Numbers { ["grab": 1, "m": Double(m)] }
            func letGo(_ m: Int) -> HandMove { HandMove(hand: ["m": Double(m)], missHand: nil, set: [("m", Double(m))], check: true) }
            return Hands(
                tap: { q in inFrames(q) ? letGo(Self.cellOf(q)) : nil },
                grab: { q in inFrames(q) ? held(Self.cellOf(q)) : nil },
                drag: { q, _ in held(Self.cellOf(q)) },
                release: { h in letGo(Int((h["m"] ?? 0).rounded())) })
        case 4:
            return Hands(tap: { q in KK.tapped(q, y: Self.keys).map { HandMove(hand: nil, missHand: nil, set: [("x", Double($0))], check: true) } })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = TeenNumbersK.Parts(s.numbers)
        switch at(s) {
        case 0: let counted = KA.list(s, "o"); return (0..<P.ones).filter { !counted.contains($0) }.map { .tap(.picture(KT.cell(Self.f2, 0, $0))) }
        case 1: return [.tap(.picture(KT.twentySpot(P.n, y: Self.keys)))]
        case 3:
            // along the first frame's rows, then on into the second
            let last = Self.spot(P.n - 1)
            return [.path([CGPoint(x: 2.5, y: 2.5), CGPoint(x: 22.5, y: 2.5), CGPoint(x: 2.5, y: 7.5), CGPoint(x: 22.5, y: 7.5)]
                          + (P.ones > 5 ? [CGPoint(x: 32.5, y: 2.5), CGPoint(x: 52.5, y: 2.5), last] : [CGPoint(x: 32.5, y: 2.5), last]))]
        case 4: return [.tap(.picture(KK.keySpot(P.ones, y: Self.keys)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = TeenNumbersK.Parts(s.numbers)
        switch at(s) {
        case 0: return HandMove(hand: nil, missHand: nil, set: [("c", -1)], keep: ["again": 12], check: true)
        case 1: return HandMove(hand: nil, missHand: nil, set: [("x", Double(P.ones))], check: true)
        case 3: let m = P.n == 20 ? 19 : P.n + 1; return HandMove(hand: ["m": Double(m)], missHand: nil, set: [("m", Double(m))], check: true)
        case 4: return HandMove(hand: nil, missHand: nil, set: [("x", 10)], check: true)
        default: return nil
        }
    }
}
