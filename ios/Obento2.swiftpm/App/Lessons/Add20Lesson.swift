import SwiftUI

/// Add within 20 on the paper, as in the preview (design/prototype/grade1-ch1.html, dAdd20): the line 0 to 20 on row 12,
/// 3 squares a step; above it a counters (solid) on row 0 and b (striped) on row 4, each named at its right end. Drag the
/// bigger row down: it snaps onto the line from 0 ("Start at 9"); the smaller slides back with the miss. Hop on: a tap
/// ahead (or a drag along) makes a hop, laying one of the small row's counters on the line (its place left dashed), the
/// numbers it lands on lit ("10, 11, 12"). Write the sum on the number row; the landing gets a bracket, "3 more".
///
/// Hand: "grab", "row" (0 a, 1 b), "y" (the row held), "n" (hops while a drag hops). Kept: "ly", "lrow" where a row was let
/// go, "hops" how many made.
@MainActor
struct Add20Lesson: PaperLesson {
    var liveKeys: Set<String> { ["y"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let line = 12.0, on = 9.0, keys = 20.0
    static func home(_ row: Int) -> Double { row == 0 ? 0 : 4 }
    func recordRow(_ n: Numbers) -> Double? { 16 }

    private func hops(_ s: PaperState) -> Int {
        let P = Add20.Parts(s.numbers)
        switch at(s) { case 0: return 0; case 1: return s.grabbed ? Int(s.h("n") ?? 0) : Int(s.run.kept["hops"] ?? 0); default: return P.small }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Add20.Parts(s.numbers), st = at(s), big = P.big, small = P.small
        let bigRow = P.a >= P.b ? 0 : 1, nums = [P.a, P.b], styles: [A1.Style] = [.solid, .striped]
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let h = hops(s), held = st == 0 && s.grabbed ? Int(s.h("row") ?? 0) : nil
        let recorded = st > 0 && (P.swapped || st >= 2)
        // where a row was let go: it glides from there (home again, or onto the line)
        let ly = s.run.kept["ly"], lrow = s.run.kept["lrow"].map { Int($0) }
        for row in 0...1 {
            let n = nums[row], onLine = st > 0 && row == bigRow
            if held == row {
                let y = s.h("y") ?? Self.home(row)
                for j in 0..<n { A1.counter(&live, "c\(row)-\(j)", x: A1.x(j), y: y, styles[row]) }
                if y == Self.on { A1.note(&live, "snap", "Start at \(n)", x: A1.x(n) + 0.5, y: y + 1.5); live.reads("Start at \(n)") }
                else { live.label("cl\(row)", "\(n)", KK.maths, .right, edge: A1.x(n), along: y + 1.5) }
                continue
            }
            let y = onLine ? Self.on : Self.home(row), left = row == bigRow ? n : n - h
            let was: ((inout GridPen) -> Void)? = lrow == row ? ly.map { f in { p in for j in 0..<n { A1.counter(&p, "c\(row)-\(j)", x: A1.x(j), y: f, styles[row]) } } } : nil
            KM.seeded(&pic, was: was) { p in for j in 0..<left { A1.counter(&p, "c\(row)-\(j)", x: A1.x(j), y: y, styles[row]) } }
            for j in left..<n { A1.gone(&pic, "g\(row)-\(j)", x: A1.x(j), y: y) }
            if !onLine && !recorded { pic.label("cl\(row)", "\(n)", KK.maths, .right, edge: A1.x(n), along: y + 1.5) }
        }
        // the hops, each laying a counter of the small row on the line
        for k in 0..<h {
            A1.counter(&pic, "H\(k)", x: A1.x(big + k), y: Self.on, styles[1 - bigRow])
            A1.hop(&pic, "hop\(k)", from: A1.x(big + k), to: A1.x(big + k + 1), y: Self.on, h: 1.2)
        }
        let lit: Set<Int> = st == 0 ? [] : Set([big] + P.counted.prefix(h))
        A1.line(&pic, "nl", y: Self.line, lit: lit, ring: st == 0 ? nil : st == 3 ? P.sum : big)
        if st == 3 {
            pic.line("br", [(A1.x(big), Self.on - 2.4), (A1.x(big), Self.on - 3), (A1.x(P.sum), Self.on - 3), (A1.x(P.sum), Self.on - 2.4)], .chapter)
            A1.note(&pic, "brn", "\(small) more", x: (A1.x(big) + A1.x(P.sum)) / 2, y: Self.on - 3.85, centred: true)
        } else if st > 0 {
            A1.note(&pic, "ro\(h)", h > 0 ? P.counted.prefix(h).map(String.init).joined(separator: ", ") : "Start at \(big)", x: A1.x(big), y: Self.on - 3.5)
        }

        switch st {
        case 0:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: Self.home(bigRow), w: A1.x(big), h: 3) }
            if s.on("spot") { pic.sketch.box("spot", pic.R(0, Self.on, A1.x(big), 3), .chapter, width: Sketch.stroke, dashed: true) }
        case 1:
            if P.swapped { A1.record(&rec, "rec", [.n(P.a), .op("+"), .n(P.b), .op("="), .n(big), .op("+"), .n(small)]) }
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: 0, y: Self.home(1 - bigRow), w: A1.x(small - h), h: 3) }
            if s.on("spot"), h < small { KK.hint(&pic, "spot", A1.x(big + h + 1), Self.line + 1.85, radius: 1.6) }
        case 2:
            let (v, wrong) = KK.typed(s, "x", want: P.sum)
            A1.record(&rec, "rec", (P.swapped ? [.n(P.a), .op("+"), .n(P.b), .op("="), .n(big), .op("+"), .n(small), .op("=")] : [.n(P.a), .op("+"), .n(P.b), .op("=")]) + [.box(v, wrong: wrong)])
            A1.numberRow(&pic, "nr", y: Self.keys, wrong: wrong ? v : nil, spot: s.on("spot") ? P.sum : nil)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: A1.x(big), y: Self.on, w: A1.x(small), h: 3) }
        default:
            A1.record(&rec, "rec", (P.swapped ? [.n(P.a), .op("+"), .n(P.b), .op("="), .n(big), .op("+"), .n(small), .op("=")] : [.n(P.a), .op("+"), .n(P.b), .op("=")]) + [.n(P.sum, .chapter)])
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Add20.Parts(s.numbers), bigRow = P.a >= P.b ? 0 : 1, nums = [P.a, P.b]
        switch at(s) {
        case 0:
            return Hands(
                grab: { q in
                    guard let row = (0...1).first(where: { q.y >= Self.home($0) - 0.5 && q.y <= Self.home($0) + 3.5 && q.x >= -0.5 && q.x <= A1.x(nums[$0]) + 2.5 }) else { return nil }
                    return ["grab": 1, "row": Double(row), "gy": q.y, "y0": Self.home(row), "y": Self.home(row)]
                },
                drag: { q, held in
                    var held = held
                    var y = max(-2, min(Self.on, ((held["y0"] ?? 0) + q.y - (held["gy"] ?? q.y)).rounded()))
                    if abs(y - Self.on) < 2.5 { y = Self.on }
                    held["y"] = y
                    return held
                },
                release: { held in
                    let row = Int(held["row"] ?? 0), y = held["y"] ?? Self.home(row)
                    let keep: Numbers = ["ly": y, "lrow": Double(row)]
                    guard y == Self.on else { return HandMove(hand: [:], keep: keep) }
                    return HandMove(hand: [:], missHand: [:], set: [("r", row == bigRow ? 0 : 1)], keep: keep, check: true)
                })
        case 1:
            let done = Int(s.run.kept["hops"] ?? 0), p = P.big + done
            func move(_ n: Int, back: Bool) -> HandMove {
                if back && n == done { return HandMove(hand: [:], missHand: [:], set: [("h", -1)], check: true) }
                if n >= P.small { return HandMove(hand: [:], missHand: [:], set: [("h", Double(P.small))], keep: ["hops": Double(P.small)], check: true) }
                return HandMove(hand: [:], keep: ["hops": Double(n)])
            }
            let band = { (q: CGPoint) in q.y >= 4 && q.y <= 15 && q.x >= -1 && q.x <= 61 }
            return Hands(
                tap: { q in
                    guard band(q) else { return nil }
                    if q.x > A1.x(p) + 0.5 { return move(done + 1, back: false) }
                    if q.x < A1.x(p) - 0.5 { return move(done, back: true) }
                    return nil
                },
                grab: { q in abs(q.x - A1.x(p)) < 1.5 && band(q) ? ["grab": 1, "n": Double(done), "back": 0] : nil },
                drag: { q, held in
                    var held = held
                    let n = max(done, min(P.small, Int((q.x / 3).rounded()) - P.big))
                    held["n"] = Double(n)
                    if q.x < A1.x(p) - 2 { held["back"] = 1 }
                    return held
                },
                release: { held in move(Int(held["n"] ?? Double(done)), back: held["back"] == 1) })
        case 2: return A1.rowHands("x", y: Self.keys)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Add20.Parts(s.numbers), bigRow = P.a >= P.b ? 0 : 1
        switch at(s) {
        case 0:
            let x = A1.x(P.big) / 2
            return [.drag(from: CGPoint(x: x, y: Self.home(bigRow) + 1.5), to: CGPoint(x: x, y: Self.on + 1.5))]
        case 1:
            let done = Int(s.run.kept["hops"] ?? 0)
            return (done..<P.small).map { .tap(.picture(CGPoint(x: A1.x(P.big + $0 + 1), y: Self.on + 1.5))) }
        case 2: return [.tap(.picture(A1.keySpot(P.sum, y: Self.keys)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Add20.Parts(s.numbers), bigRow = P.a >= P.b ? 0 : 1
        switch at(s) {
        case 0: return HandMove(hand: [:], missHand: [:], set: [("r", 1)], keep: ["ly": Self.on, "lrow": Double(1 - bigRow)], check: true)
        case 1: return HandMove(hand: [:], missHand: [:], set: [("h", -1)], check: true)
        case 2: return A1.slip("x", P.sum)
        default: return nil
        }
    }
}
