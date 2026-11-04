import SwiftUI

/// More, less or the same on the paper, as in the preview (design/prototype/gradeK-ch1.html, lCompare): two ten tracks
/// a block apart, the top row on its track from the start line, the bottom row out of line (spread out or shifted).
/// Count each row (tap to count; each row's count goes at its right end), slide the bottom row under the top one's start
/// (it snaps, dot under dot; partner lines draw between the pairs and the dots with no partner are ringed, "2 without a
/// partner"), then tap the row with more, or the "same" block at the rows' right end. The tap writes the record.
@MainActor
struct CompareGroupsLesson: PaperLesson {
    var liveKeys: Set<String> { ["off", "gx", "goff"] }
    static let top = 0.0, bottom = 10.0
    /// The "same" block, at the rows' right end, between them.
    static let same = CGRect(x: 55, y: 5, width: 10, height: 5)
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func order(_ s: PaperState, _ row: String) -> [Int] {
        var out: [Int] = []
        while let j = s.run.kept["\(row)\(out.count)"] { out.append(Int(j.rounded())) }
        return out
    }
    /// The bottom row's dot j, with the row `off` blocks along (before it's lined up, its own shift).
    private func bx(_ P: CompareGroups.Parts, _ j: Int, off: Double? = nil, lined: Bool) -> Double {
        lined ? Double(j) * 5 + 2.5 : (Double(P.slots[j]) + (off ?? Double(P.shift))) * 5 + 2.5
    }
    func recordRow(_ n: Numbers) -> Double? { 18 }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = CompareGroups.Parts(s.numbers), st = at(s), lined = st >= 2
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        KK.track(&pic, "tt", x: 0, y: Self.top)
        KK.track(&pic, "bt", x: 0, y: Self.bottom)
        let cT = st == 0 ? order(s, "t") : Array(0..<P.top), cB = st == 0 ? order(s, "b") : Array(0..<P.bottom)
        let lo = min(P.top, P.bottom), hi = max(P.top, P.bottom)
        // partner lines between the pairs, drawn one after another, before the dots so the dots sit over them
        if lined { for j in 0..<lo { pic.line("pl\(j)", [(Double(j) * 5 + 2.5, Self.top + 4), (Double(j) * 5 + 2.5, Self.bottom + 1)], .chapter) } }
        // a wrong row tapped: its track outlined red
        let wrong = st == 2 ? s.run.kept["wrong"].map { Int($0.rounded()) } : nil
        if wrong == 0 { pic.sketch.box("wr0", pic.R(0, Self.top, 50, 5), KK.red, width: Sketch.stroke) }
        if wrong == 1 { pic.sketch.box("wr1", pic.R(0, Self.bottom, 50, 5), KK.red, width: Sketch.stroke) }
        for j in 0..<P.top {
            let k = cT.firstIndex(of: j)
            KK.counter(&pic, "td\(j)", Double(j) * 5 + 2.5, Self.top + 2.5, num: k.map { $0 + 1 }, ring: cT.count == P.top && k == P.top - 1 && st < 3)
        }
        // the bottom row: held, it follows the finger (live); let go, it's still
        let held = st == 1 && s.grabbed
        let off = s.h("off")
        for j in 0..<P.bottom {
            let k = cB.firstIndex(of: j), x = bx(P, j, off: held ? off : nil, lined: lined)
            if held { KK.counter(&live, "bd\(j)", x, Self.bottom + 2.5, num: k.map { $0 + 1 }, ring: k == P.bottom - 1) }
            else { KK.counter(&pic, "bd\(j)", x, Self.bottom + 2.5, num: k.map { $0 + 1 }, ring: cB.count == P.bottom && k == P.bottom - 1 && st < 3) }
        }
        // a dot tapped again: ringed red
        if st == 0, let a = s.run.kept["again"], a >= 0 {
            let r = Int(a) / 100, j = Int(a) % 100
            pic.circle("again\(Int(a))", at: r == 0 ? Double(j) * 5 + 2.5 : bx(P, j, lined: false), (r == 0 ? Self.top : Self.bottom) + 2.5, radius: 2.05, KK.red)
        }
        // each row's count at its right end once it's counted (right of the track); once the record is written, it carries
        // the numbers, so these go
        let nameT = 50.5, nameB = max(50, bx(P, P.bottom - 1, lined: lined) + 2.5) + 0.5
        if cT.count == P.top && st < 3 { pic.label("tname", "\(P.top)", KK.maths, .right, edge: nameT - 0.5, along: Self.top + 2.5) }
        if cB.count == P.bottom && st < 3 {
            if held { live.label("bname", "\(P.bottom)", KK.maths, .right, edge: max(50, bx(P, P.bottom - 1, off: off, lined: false) + 2.5), along: Self.bottom + 2.5) }
            else { pic.label("bname", "\(P.bottom)", KK.maths, .right, edge: nameB - 0.5, along: Self.bottom + 2.5) }
        }
        // the dots with no partner, ringed: "2 without a partner"
        let d = P.extra
        if lined, d > 0 {
            let y = (P.top > P.bottom ? Self.top : Self.bottom) + 0.5
            KK.stadium(&pic, "np", x: Double(lo) * 5 + 0.5, y: y, w: Double(d) * 5 - 1, h: 4)
            pic.label("npw", "\(d) without a partner", KK.lit, .right, edge: 51 + KK.width("\(hi)", KK.maths), along: y + 2)
        }
        switch st {
        case 0:
            if s.on("ring") {
                for j in 0..<P.top where !cT.contains(j) { KK.hint(&pic, "hrt\(j)", Double(j) * 5 + 2.5, Self.top + 2.5) }
                for j in 0..<P.bottom where !cB.contains(j) { KK.hint(&pic, "hrb\(j)", bx(P, j, lined: false), Self.bottom + 2.5) }
            }
        case 1:
            // a hint: where the row starts; a second miss, the top row's first block, under which it goes
            if s.on("ring") { KK.hint(&pic, "hr", bx(P, 0, lined: false), Self.bottom + 2.5) }
            if s.on("spot") { KK.hintBox(&pic, "spot", x: 0, y: Self.bottom, w: 5, h: 5) }
        case 2:
            let bad = wrong == 2, r = Self.same
            pic.sketch.box("same\(bad)", pic.R(r.minX, r.minY, r.width, r.height), bad ? KK.red : .ink, width: Sketch.stroke)
            pic.word("samew\(bad)", "same", at: r.midX, r.midY, bad ? KK.words.colour(KK.red) : KK.words)
            if s.on("ring"), d > 0 { KK.hintBox(&pic, "hr", x: Double(lo) * 5, y: (P.top > P.bottom ? Self.top : Self.bottom), w: Double(d) * 5, h: 5) }
            if s.on("spot") {
                switch P.right {
                case 0: KK.hintBox(&pic, "spot", x: 0, y: Self.top, w: 50, h: 5)
                case 1: KK.hintBox(&pic, "spot", x: 0, y: Self.bottom, w: 50, h: 5)
                default: KK.hintBox(&pic, "spot", x: r.minX, y: r.minY, w: r.width, h: r.height)
                }
            }
        default:
            M7.row(&rec, "rec", [.n(P.top, .chapter), .w("is \(CompareGroups.choices[P.right])"), .n(P.bottom, .chapter)], x: 0, line: 1)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = CompareGroups.Parts(s.numbers)
        switch at(s) {
        case 0:
            let cT = order(s, "t"), cB = order(s, "b")
            return Hands(tap: { q in
                for (r, name, count, counted, y) in [(0, "t", P.top, cT, Self.top), (1, "b", P.bottom, cB, Self.bottom)] {
                    guard q.y >= y, q.y <= y + 5 else { continue }
                    guard let j = (0..<count).first(where: { abs(q.x - (r == 0 ? Double($0) * 5 + 2.5 : bx(P, $0, lined: false))) <= 2.5 }) else { return nil }
                    if counted.contains(j) { return HandMove(hand: nil, missHand: nil, set: [("top", -1), ("bottom", -1)], keep: ["again": Double(100 * r + j)], check: true) }
                    let done = cT.count + cB.count + 1 == P.top + P.bottom
                    return HandMove(hand: nil, missHand: nil, set: done ? [("top", Double(P.top)), ("bottom", Double(P.bottom))] : [], keep: ["\(name)\(counted.count)": Double(j), "again": -1], check: done)
                }
                return nil
            })
        case 1:
            let lo = bx(P, 0, lined: false) - 2.5, hi = bx(P, P.bottom - 1, lined: false) + 2.5
            return Hands(
                grab: { q in
                    guard q.y >= Self.bottom - 1, q.y <= Self.bottom + 6, q.x >= lo - 1, q.x <= hi + 1 else { return nil }
                    return ["grab": 1, "gx": q.x, "off": Double(P.shift), "goff": Double(P.shift)]
                },
                drag: { q, h in var h = h; h["off"] = (h["goff"] ?? 0) + (q.x - (h["gx"] ?? q.x)) / 5; return h },
                release: { h in
                    // under the top one's start: it snaps, dot under dot; anywhere else it slides back
                    let start = Double(P.slots[0]) + (h["off"] ?? Double(P.shift))
                    return HandMove(hand: [:], missHand: [:], set: [("l", abs(start) < 0.6 ? 1 : 0)], check: true)
                })
        case 2:
            return Hands(tap: { q in
                let c: Int? = Self.same.contains(q) ? 2
                    : q.y >= Self.top && q.y <= Self.top + 5 && q.x >= 0 && q.x <= Double(P.top) * 5 + 4 ? 0
                    : q.y >= Self.bottom && q.y <= Self.bottom + 5 && q.x >= 0 && q.x <= Double(P.bottom) * 5 + 4 ? 1 : nil
                guard let c else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("c", Double(c))], keep: ["wrong": c == P.right ? -1 : Double(c)], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = CompareGroups.Parts(s.numbers)
        switch at(s) {
        case 0:
            let cT = order(s, "t"), cB = order(s, "b")
            return (0..<P.top).filter { !cT.contains($0) }.map { .tap(.picture(CGPoint(x: Double($0) * 5 + 2.5, y: Self.top + 2.5))) }
                + (0..<P.bottom).filter { !cB.contains($0) }.map { .tap(.picture(CGPoint(x: bx(P, $0, lined: false), y: Self.bottom + 2.5))) }
        case 1:
            let x = bx(P, 0, lined: false)
            return [.drag(from: CGPoint(x: x, y: Self.bottom + 2.5), to: CGPoint(x: x - Double(P.slots[0] + P.shift) * 5, y: Self.bottom + 2.5))]
        case 2:
            let r = Self.same
            switch P.right {
            case 0: return [.tap(.picture(CGPoint(x: 2.5, y: Self.top + 2.5)))]
            case 1: return [.tap(.picture(CGPoint(x: 2.5, y: Self.bottom + 2.5)))]
            default: return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
            }
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = CompareGroups.Parts(s.numbers)
        switch at(s) {
        case 0: return HandMove(hand: nil, missHand: nil, set: [("top", -1), ("bottom", -1)], keep: ["t0": 0, "again": 0], check: true)
        case 1: return HandMove(hand: [:], missHand: [:], set: [("l", 0)], check: true)
        case 2: let c = P.right == 2 ? 0 : 2; return HandMove(hand: nil, missHand: nil, set: [("c", Double(c))], keep: ["wrong": Double(c)], check: true)
        default: return nil
        }
    }
}
