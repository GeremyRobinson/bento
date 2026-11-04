import SwiftUI

/// Number bonds on the paper, as in the preview (design/prototype/gradeK-ch4.html, lBonds): the bond on top (the whole's
/// circle one block across over the middle, the parts' circles 2 blocks lower and 3 blocks to each side, lines between;
/// the whole's number, the first part's, the other's circle dashed with "?"), and under it the train of the whole. Drag
/// across the train to cut it (the cut snaps between cubes; the readout is the count before it); let go after the first
/// part and the pieces part a square, the other striped. Write the other part on the number row (it fills the dashed
/// circle as it's written; tapping the striped cubes numbers them, a help). Then the pieces join: cut in another place
/// (the bond's parts change as it moves, "4 and 1") and a second line writes itself.
///
/// Departure, so the write step shows at 75% or more (it was 69%): the parts' circles a block and a half under the
/// whole's, not 2 blocks, and the train a block higher.
///
/// Hand: "grab", "cut". Kept: "o<i>" the striped cubes counted, "cut2" the second cut.
@MainActor
struct BondsLesson: PaperLesson {
    var liveKeys: Set<String> { ["cut"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let whole = CGPoint(x: 25, y: 2.5), parts = [CGPoint(x: 10, y: 10), CGPoint(x: 40, y: 10)], r = 2.5, train = 15.0, keys = 28.0
    func recordRow(_ n: Numbers) -> Double? { 23 }
    /// The train starts on the block line that centres it best under the bond.
    private func x0(_ w: Int) -> Double { 5 * Double((10 - w) / 2) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = BondsK.Parts(s.numbers), st = at(s), w = P.whole, X0 = x0(w)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let held = s.grabbed, cut = s.h("cut").map { Int($0.rounded()) }, cut2 = KA.kept(s, "cut2") ?? P.other
        // the bond: the lines between the circles, the circles, the numbers they hold now
        let W = Self.whole
        for (j, pc) in Self.parts.enumerated() {
            let dx = pc.x - W.x, dy = pc.y - W.y, d = hypot(dx, dy), k = Self.r / d
            pic.line("bl\(j)", [(W.x + dx * k, W.y + dy * k), (pc.x - dx * k, pc.y - dy * k)])
        }
        pic.circle("bw", at: W.x, W.y, radius: Self.r, .ink)
        pic.word("bwn", "\(w)", at: W.x, W.y, KK.maths)
        pic.circle("b0", at: Self.parts[0].x, Self.parts[0].y, radius: Self.r, .ink)
        let typed = KK.typed(s, "x", want: P.rest), open = st <= 1, bad = st == 1 && typed.wrong
        if open {
            let c = Self.parts[1]
            pic.circle("b1d\(bad)", at: c.x, c.y, radius: Self.r, bad ? KK.red : .ink, dashed: true)
        } else { pic.circle("b1", at: Self.parts[1].x, Self.parts[1].y, radius: Self.r, .ink) }
        // what the parts' circles say: the first part and "?" (or what's written); while another cut is held, it live
        let names: (Int, String, Sketch.Words) = {
            switch st {
            case 0: return (P.part, "?", KK.maths)
            case 1: return (P.part, typed.value.map(String.init) ?? "?", bad ? KK.maths.colour(KK.red) : KK.maths)
            case 2: return (P.part, "\(P.rest)", KK.maths)
            default: return (cut2, "\(w - cut2)", KK.maths.colour(.chapter))
            }
        }()
        if st == 2 && held, let c = cut {
            live.word("b0n", "\(c)", at: Self.parts[0].x, Self.parts[0].y, KK.maths)
            live.word("b1n", "\(w - c)", at: Self.parts[1].x, Self.parts[1].y, KK.maths)
        } else {
            pic.word("b0n", "\(names.0)", at: Self.parts[0].x, Self.parts[0].y, st == 3 ? KK.maths.colour(.chapter) : KK.maths)
            pic.word("b1n", names.1, at: Self.parts[1].x, Self.parts[1].y, names.2)
        }

        // the train: whole while cutting; parted a square after the cut, the other piece striped
        let split: Int? = st == 1 ? P.part : st == 3 ? cut2 : nil
        let counted = st == 1 ? KA.list(s, "o") : []
        for j in 0..<w {
            let after = split.map { j >= $0 } ?? false
            let k = counted.firstIndex(of: j)
            KA.cube(&pic, "c\(j)", x: X0 + Double(j) * 5 + (after ? 1 : 0), y: Self.train, striped: after, num: k.map { $0 + 1 })
        }
        // the cut: a line across the train where the finger is (or was let go)
        if let c = cut, st == 0 || st == 2 {
            live.line("cut", [(X0 + 5 * Double(c), Self.train - 1.5), (X0 + 5 * Double(c), Self.train + 6.5)], held ? .ink2 : .ink)
            if held { live.reads(st == 0 ? "\(c)" : "\(c) and \(w - c)") }
        }

        let first: [M7.Tok] = [.n(w), .op("="), .n(P.part), .op("+")]
        switch st {
        case 0, 2:
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: X0, y: Self.train, w: 5 * Double(w), h: 5) }
            if s.on("spot") { let x = X0 + 5 * Double(st == 0 ? P.part : P.other); pic.line("spot", [(x, Self.train - 2), (x, Self.train + 7)], .chapter, dashed: true) }
            if st == 2 { M7.row(&rec, "r1", first + [.n(P.rest, .chapter)], x: 0, line: 1) }
        case 1:
            KA.line(&rec, "r1", first, value: typed.value, wrong: typed.wrong)
            KK.numberRow(&pic, "nr", y: Self.keys, wrong: typed.wrong ? typed.value : nil, spot: s.on("spot") ? P.rest : nil)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: X0 + 5 * Double(P.part) + 1, y: Self.train, w: 5 * Double(P.rest), h: 5) }
        default:
            M7.row(&rec, "r1", first + [.n(P.rest, .chapter)], x: 0, line: 1)
            M7.row(&rec, "r2", [.n(w), .op("="), .n(cut2), .op("+"), .n(w - cut2)], x: 25, line: 1)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(0, 0, 50, Self.train + 7))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = BondsK.Parts(s.numbers), st = at(s), w = P.whole, X0 = x0(w)
        func place(_ q: CGPoint) -> Int { max(0, min(w, Int(((q.x - X0) / 5).rounded()))) }
        let onTrain = { (q: CGPoint) in q.y >= Self.train - 2.5 && q.y <= Self.train + 7.5 && q.x >= X0 - 2.5 && q.x <= X0 + 5 * Double(w) + 2.5 }
        switch st {
        case 0, 2:
            let box = st == 0 ? "k" : "k2"
            func letGo(_ c: Int) -> HandMove {
                HandMove(hand: ["cut": Double(c)], missHand: nil, set: [(box, Double(c))], keep: st == 2 ? ["cut2": Double(c)] : [:], check: true)
            }
            return Hands(
                tap: { q in onTrain(q) ? letGo(place(q)) : nil },
                grab: { q in onTrain(q) ? ["grab": 1, "cut": Double(place(q))] : nil },
                drag: { q, _ in ["grab": 1, "cut": Double(place(q))] },
                release: { h in letGo(Int((h["cut"] ?? 0).rounded())) })
        case 1:
            let counted = KA.list(s, "o")
            return Hands(tap: { q in
                if let v = KK.tapped(q, y: Self.keys) { return HandMove(hand: nil, missHand: nil, set: [("x", Double(v))], check: true) }
                // a striped cube tapped: it's numbered (a help to count, never checked)
                guard q.y >= Self.train, q.y <= Self.train + 5 else { return nil }
                let j = Int(floor((q.x - X0 - 1) / 5))
                guard j >= P.part, j < w, !counted.contains(j) else { return nil }
                return HandMove(hand: nil, missHand: nil, keep: ["o\(counted.count)": Double(j)])
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = BondsK.Parts(s.numbers), X0 = x0(P.whole), y = Self.train + 2.5
        switch at(s) {
        case 0: return [.drag(from: CGPoint(x: X0 + 2, y: y), to: CGPoint(x: X0 + 5 * Double(P.part), y: y))]
        case 1: return [.tap(.picture(KK.keySpot(P.rest, y: Self.keys)))]
        case 2: return [.drag(from: CGPoint(x: X0 + 5 * Double(P.part), y: y), to: CGPoint(x: X0 + 5 * Double(P.other), y: y))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = BondsK.Parts(s.numbers)
        switch at(s) {
        case 0: let c = P.part + 1; return HandMove(hand: ["cut": Double(c)], missHand: nil, set: [("k", Double(c))], check: true)
        case 1: return HandMove(hand: nil, missHand: nil, set: [("x", Double(P.part == P.rest ? P.whole : P.part))], check: true)
        case 2: return HandMove(hand: ["cut": Double(P.part)], missHand: nil, set: [("k2", Double(P.part))], keep: ["cut2": Double(P.part)], check: true)
        default: return nil
        }
    }
}
