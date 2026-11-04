import SwiftUI

/// 10 more, 10 less on the paper, as in the preview (design/prototype/grade1-ch3.html, dTenMore). Three rows of the 120
/// chart: n's row, the row above and the row below; n written big and ringed. Drag the ring down (10 more) or up (10 less):
/// it snaps a place at a time and the readout under the chart says how far ("+10"); a tap on a place moves it there too.
/// Then both numbers are big, their tens digits lit and their ones underlined: the ones stay. The record under the chart,
/// 34 + 10, gets "= [44]", written with the digit pad.
///
/// Hand while the ring is held: "grab", "v" the place it's on. Kept: "chk" what was last checked.
@MainActor
struct TenMore1Lesson: PaperLesson {
    var liveKeys: Set<String> { ["v"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let line = 19.0, padY = 21.0

    func blocksAt(_ s: PaperState) -> CGPoint? {
        switch at(s) {
        case 1: return DigitPad.checkAt(x: 0, y: Self.padY)
        case 2: return CGPoint(x: 0, y: Self.padY)
        default: return nil
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = TenMore1.Parts(s.numbers), st = at(s), r0 = Num1.row(P.n) - 1, found = st > 0
        var pic = GridPen(), live = GridPen(stableIds: true)
        for v in (10 * r0 + 1)...(10 * (r0 + 3)) {
            if v == P.n || (found && v == P.res) { N1.big(&pic, "big", v, r0, lit: found) } else { N1.num(&pic, "cn", v, r0) }
        }
        N1.lines(&pic, "ch", r0, 3)
        let held = st == 0 && s.grabbed, ring = held ? Int(s.h("v") ?? Double(P.n)) : found ? P.res : P.n
        let c = N1.mid(ring, r0)
        if held {
            live.circle("ring", at: c.x, c.y, radius: 2.1, .chapter)
            if ring != P.n {
                let d = ring - P.n, ro = "\(d > 0 ? "+" : "−")\(abs(d))"
                live.word("ro", ro, at: c.x, 16, KK.lit); live.reads(ro)
            }
        } else {
            pic.circle("rg\(ring)", at: c.x, c.y, radius: 2.1, .chapter)
        }
        let toks: [M7.Tok] = [.n(P.n), .op(P.op), .n(10)]
        switch st {
        case 0:
            M7.row(&pic, "rec", toks, x: 0, line: Self.line)
            let col = N1.block(P.n, r0).x
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: col, y: 0, w: 5, h: 15) }
            if s.on("spot") { let m = N1.mid(P.res, r0); KK.hint(&pic, "spot", m.x, m.y) }
        case 1:
            let (v, wrong) = DigitPad.typed(s, "x", want: P.res)
            N1.record(&pic, "rec", toks + [.op("=")], value: v, wrong: wrong, line: Self.line)
            DigitPad.draw(&pic, "pad", x: 0, y: Self.padY)
            if s.on("ring") && !s.on("spot") { let b = N1.block(P.res, r0); KK.hintBox(&pic, "hr", x: b.x, y: b.y, w: 5, h: 5) }
            if s.on("spot") { A1.note(&pic, "spot", "\(P.res)", x: 50.5, y: 5 * Double(Num1.row(P.res) - r0) + 2.5) }
        default:
            N1.record(&pic, "rec", toks + [.op("=")], value: nil, wrong: false, done: P.res, line: Self.line)
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, actions: st == 1 ? ["Check"] : [])
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = TenMore1.Parts(s.numbers), r0 = Num1.row(P.n) - 1
        switch at(s) {
        case 0:
            func land(_ v: Int) -> HandMove {
                v == P.n ? HandMove(hand: [:]) : HandMove(hand: [:], missHand: [:], set: [("d", Double(v - P.n))], check: true)
            }
            return Hands(
                tap: { q in N1.at(q, r0, 3).flatMap { $0 == P.n ? nil : land($0) } },
                grab: { q in
                    let b = N1.block(P.n, r0)
                    guard q.x >= b.x - 0.5, q.x <= b.x + 5.5, q.y >= b.y - 0.5, q.y <= b.y + 5.5 else { return nil }
                    return ["grab": 1, "v": Double(P.n)]
                },
                drag: { q, held in var h = held; h["v"] = Double(N1.at(q, r0, 3, clamped: true) ?? P.n); return h },
                release: { held in land(Int(held["v"] ?? Double(P.n))) })
        case 1: return DigitPad.hands(s, "x", want: P.res, x: 0, y: Self.padY)
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = TenMore1.Parts(s.numbers), r0 = Num1.row(P.n) - 1
        switch at(s) {
        case 0: return [.drag(from: N1.mid(P.n, r0), to: N1.mid(P.res, r0))]
        case 1: return DigitPad.demo(P.res, x: 0, y: Self.padY)
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = TenMore1.Parts(s.numbers)
        switch at(s) {
        case 0: return HandMove(hand: [:], missHand: [:], set: [("d", Double(P.n - P.res))], check: true)
        case 1:
            let slip = P.n + (P.more ? 1 : -1)
            return HandMove(hand: nil, missHand: nil, set: [("x", Double(slip))], keep: ["chk": Double(slip)], check: true)
        default: return nil
        }
    }
}
