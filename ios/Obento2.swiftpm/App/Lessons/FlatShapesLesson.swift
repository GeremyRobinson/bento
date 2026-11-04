import SwiftUI

/// Flat shapes on the paper, as in the preview (design/prototype/gradeK-ch2.html, lShapes): the shape big, its corners on
/// the paper's crossings, a block under the words. Tap each side: it lights and its number is written just outside it
/// (tapped again it goes red: "You counted that side."). Tap each corner: a dot and its number. Tap its name in the column
/// of words on its right. Then the See: a turned shape turns upright where it is and back (the same shape); a square's
/// or rectangle's first side lifts off as a stick and lays itself on each side in turn. The record beside it.
///
/// Kept: "s<k>" the side counted k-th, "c<k>" the corner, "againS"/"againC" one tapped twice, "wrong" a name tapped wrong.
@MainActor
struct FlatShapesLesson: PaperLesson {
    typealias Pt = KS.Pt
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let top = 3.0, names = CGPoint(x: 40, y: 5)
    /// The shape's corners where it's drawn (squares), and a circle's middle and radius.
    private func base(_ P: FlatShapes.Parts) -> (pts: [Pt], c: Pt, r: Double) {
        let x0 = Double(ShapesK.jsRound(18 - Double(P.width) / 2))
        let pts = P.corners.map { (Double($0.0) + x0, Double($0.1) + Self.top) }
        return (pts, P.round ? (x0 + Double(P.r), Self.top + Double(P.r)) : KS.centroid(pts), Double(P.r))
    }
    private func order(_ s: PaperState, _ k: String) -> [Int] {
        var out: [Int] = []
        while let j = s.run.kept["\(k)\(out.count)"] { out.append(Int(j.rounded())) }
        return out
    }
    private func names(_ P: FlatShapes.Parts) -> [CGRect] { KS.rects(P.choices.count, x: Self.names.x, y: Self.names.y, w: 15, .column) }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = FlatShapes.Parts(s.numbers), st = at(s), B = base(P), p = B.pts, n = P.n
        var pic = GridPen()
        let sides = st == 0 ? order(s, "s") : Array(0..<n), corners = st <= 1 ? (st == 1 ? order(s, "c") : []) : Array(0..<n)
        if P.round {
            KS.poly(&pic, "circ", KS.circlePts(B.c, B.r), KS.fill)
            KS.outline(&pic, "circo", KS.circlePts(B.c, B.r), st >= 1 ? .chapter : .ink)
            if st == 0 && s.on("ring") { KS.outline(&pic, "circh", KS.circlePts(B.c, B.r + 1.2), .chapter, dashed: true) }
            if st == 1 && s.on("ring") { KS.outline(&pic, "circh", KS.circlePts(B.c, B.r + 1.2), .chapter, dashed: true) }
        } else if st < 3 {
            KS.poly(&pic, "shape", p, KS.fill)
            KS.outline(&pic, "shapeo", p)
            let again = st == 0 ? s.run.kept["againS"].map { Int($0) } : nil
            for (k, i) in sides.enumerated() {
                KS.poly(&pic, "sd\(i)\(again == i)", KS.edge(p, i), again == i ? .hex(0xE9B7B2, 0x6B2E2A) : KS.lit)
                if st == 0 { let m = KS.sideLabel(p, i); pic.word("sn\(i)", "\(k + 1)", at: m.0, m.1, KK.count) }
            }
            for (k, i) in corners.enumerated() {
                pic.dot("cd\(i)", at: p[i].0, p[i].1, radius: 0.6, .chapter, over: true)
                if st >= 1 { let m = KS.cornerLabel(p, i); pic.word("cn\(i)", "\(st == 1 ? k + 1 : i + 1)", at: m.0, m.1, KK.count) }
            }
            if st == 1, let a = s.run.kept["againC"], a >= 0 { let i = Int(a); pic.circle("cx\(i)", at: p[i].0, p[i].1, radius: 1.4, KK.red) }
            // a hint: the sides (corners) still to count, ringed; a second miss, the next one
            let todo = (0..<n).filter { !(st == 0 ? sides : corners).contains($0) }
            if st <= 1 && s.on("ring") {
                for i in todo { let m = st == 0 ? KS.sideLabel(p, i, out: 0) : p[i]; KK.hint(&pic, "hr\(i)", m.0, m.1, radius: 1.8) }
            }
            if st <= 1 && s.on("spot"), let i = todo.first { let m = st == 0 ? KS.sideLabel(p, i, out: 0) : p[i]; pic.circle("spot", at: m.0, m.1, radius: 1.8, .chapter) }
        } else {
            // the See: the shape (its lit sides, its corners) turns upright where it is and back; or the stick
            let up = KS.turned(p, by: -P.angle, about: B.c)
            func seeded(_ id: String, _ q: [Pt], _ qUp: [Pt], _ colour: Sketch.Colour, over: Bool = false) {
                if P.turned { pic.sketch.from[id] = KS.kind(q, pic, over: over); pic.sketch.via[id] = KS.kind(qUp, pic, over: over) }
                if over { pic.sketch.plate(id, q.map { pic.P($0.0, $0.1) }, colour) } else { KS.poly(&pic, id, q, colour) }
                pic.sketch.from = [:]; pic.sketch.via = [:]
            }
            seeded("shape3", p, up, KS.fill)
            for i in 0..<n {
                let b = KS.edge(p, i), bu = KS.edge(up, i)
                if !(P.kind == "square" || P.kind == "rectangle") { seeded("sd3\(i)", b, bu, KS.lit) }
                let d = KS.circlePts(p[i], 0.6, 16), du = KS.circlePts(up[i], 0.6, 16)
                seeded("cd3\(i)", d, du, .chapter, over: true)
            }
            if !P.turned { KS.outline(&pic, "shapeo", p) }
            var seeTime = P.turned ? SketchDrawer.morphTime * 2 + SketchDrawer.viaRest : 0
            if P.kind == "square" || P.kind == "rectangle" {
                KS.outline(&pic, "shapeo", p)
                seeTime = KS.stick(&pic, "stk", p, start: PaperClock.now + 0.3) + 0.6
            }
            // the record beside it, once it's been seen
            pic.sketch.startAt = PaperClock.now + seeTime
            let x = Double(Self.names.x)
            var y = Double(Self.names.y) + 1
            KS.line(&pic, "rec0", KS.sidesCorners(n), x: x, line: y); y += 3
            if P.kind == "square" { KS.line(&pic, "rec1", [.n(4, .chapter), .w("sides the same")], x: x, line: y); y += 3 }
            KS.line(&pic, "rec2", [.w("It’s \(ShapesK.an(P.kind)).")], x: x, line: y)
            pic.sketch.startAt = nil
        }
        if P.round && st == 3 {
            pic.sketch.startAt = PaperClock.now + 0.3
            KS.line(&pic, "rec0", KS.sidesCorners(0), x: Double(Self.names.x), line: Double(Self.names.y) + 1)
            KS.line(&pic, "rec2", [.w("It’s a circle.")], x: Double(Self.names.x), line: Double(Self.names.y) + 4)
            pic.sketch.startAt = nil
        }
        if st == 2 {
            let wrong = s.run.kept["wrong"].map { Int($0.rounded()) }.flatMap { $0 >= 0 ? $0 : nil }
            KS.blocks(&pic, "nm", P.choices.map(ShapesK.cap), names(P), wrong: wrong, spot: s.on("spot") ? P.right : nil, ring: s.on("ring") && !s.on("spot"))
        }
        // room for the names (and the record) beside it on every step, so the camera holds still
        let room = st >= 2 ? pic.R(-1, 0, Self.names.x + 16, max(Self.top + Double(P.height) + 3, Self.names.y + 20)) : pic.R(-1, 0, 38, Self.top + Double(P.height) + 3)
        return PaperDrawing(picture: pic.sketch, extent: room)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = FlatShapes.Parts(s.numbers), B = base(P), p = B.pts, n = P.n
        switch at(s) {
        case 0, 1:
            let st = at(s), key = st == 0 ? "s" : "c", box = st == 0 ? "s" : "c", done = order(s, key)
            return Hands(tap: { q in
                let f = (Double(q.x), Double(q.y))
                if P.round {
                    guard abs(hypot(f.0 - B.c.0, f.1 - B.c.1) - B.r) < 4 else { return nil }
                    return HandMove(hand: nil, missHand: nil, set: [(box, 0)], check: true)
                }
                let d = (0..<n).map { i in st == 0 ? KS.segDist(f, p[i], p[(i + 1) % n]) : hypot(f.0 - p[i].0, f.1 - p[i].1) }
                guard let i = d.indices.min(by: { d[$0] < d[$1] }), d[i] < (st == 0 ? 2.2 : 3) else { return nil }
                if done.contains(i) { return HandMove(hand: nil, missHand: nil, set: [(box, -1)], keep: [st == 0 ? "againS" : "againC": Double(i)], check: true) }
                let k = done.count
                return HandMove(hand: nil, missHand: nil, set: k + 1 == n ? [(box, Double(n))] : [], keep: ["\(key)\(k)": Double(i), st == 0 ? "againS" : "againC": -1], check: k + 1 == n)
            })
        case 2:
            let r = names(P)
            return Hands(tap: { q in
                guard let j = KS.hit(q, r) else { return nil }
                return HandMove(hand: nil, missHand: nil, set: [("p", Double(j))], keep: ["wrong": j == P.right ? -1 : Double(j)], check: true)
            })
        default: return nil
        }
    }

    /// Done: Next problem under the record, in the names' column.
    func blocksAt(_ s: PaperState) -> CGPoint? {
        guard at(s) == 3 else { return nil }
        let P = FlatShapes.Parts(s.numbers)
        return CGPoint(x: Self.names.x, y: Self.names.y + (P.kind == "square" ? 9 : 6) + 1)
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = FlatShapes.Parts(s.numbers), B = base(P), p = B.pts, n = P.n
        switch at(s) {
        case 0, 1:
            if P.round { return [.tap(.picture(CGPoint(x: B.c.0 + B.r, y: B.c.1)))] }
            let st = at(s), done = order(s, st == 0 ? "s" : "c")
            return (0..<n).filter { !done.contains($0) }.map { i in
                let m = st == 0 ? KS.sideLabel(p, i, out: 0) : p[i]
                return .tap(.picture(CGPoint(x: m.0, y: m.1)))
            }
        case 2: let r = names(P)[P.right]; return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = FlatShapes.Parts(s.numbers), st = at(s)
        switch st {
        case 0, 1:
            if P.round { return nil }
            let key = st == 0 ? "s" : "c", done = order(s, key), i = done.first ?? 0
            var keep: Numbers = [st == 0 ? "againS" : "againC": Double(i)]
            if done.isEmpty { keep["\(key)0"] = 0 }
            return HandMove(hand: nil, missHand: nil, set: [(key, -1)], keep: keep, check: true)
        case 2:
            let j = (P.right + 1) % P.choices.count
            return HandMove(hand: nil, missHand: nil, set: [("p", Double(j))], keep: ["wrong": Double(j)], check: true)
        default: return nil
        }
    }
}
