import SwiftUI

/// Quadrilaterals on the paper, as in the preview (design/prototype/grade3-ch4.html, dQuads): one square is a unit of length,
/// the shape big, its corners on grid crossings. Tap each side (it lights and takes its number); tap the square corners (a
/// small square marks each; a corner that isn't square shows the paper corner red with its gap; Done); tap each side to
/// measure it (a strip of squares lays along it, the length outside, matching sides the same ticks); Yes or No: all 4 sides
/// the same?; tap two sides that never meet (they run on, dashed: parallel ones get matching arrowheads, others are
/// measured closing in, with drops; No more); tap its most special name (six blocks); also a rectangle? Make one: drag any
/// corner to another crossing (its marks redraw as it moves; a shape that breaks snaps back), Done. The record beside it
/// gets one short line a step; the picks sit under it, in the picture's squares.
///
/// Hand: sides "L<i>" the order lit; corners "f<i>", "wc" the corner that didn't fit; measure "m<i>" the order, "last";
/// pairs "sel", "pA", "pB" (0 or 1), "close"; picks "bad"; make "grab", "gi", "v<i>x", "v<i>y". Kept on make: "made", "mR",
/// "mE", "mP", "v<i>x", "v<i>y".
@MainActor
struct Quads3Lesson: PaperLesson {
    typealias Pt = Geo4.Pt
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let O = Pt(5, 3)
    func recordRow(_ n: Numbers) -> Double? { 0 }
    func messageRows(_ n: Numbers) -> Int { 2 }

    @MainActor struct Q {
        let P: Quads3.Parts, v: [(Int, Int)], pts: [Pt], c: Quads3.Cls, rx: Double, ry: Double
        init(_ s: PaperState) {
            P = Quads3.Parts(s.numbers)
            let st = Int((s.picture["at"] ?? 0).rounded())
            let pv = P.v
            var v = pv
            // making one: the corners where the hand (or, once made, the run) has them
            let src: Numbers? = st == 8 ? s.hand : P.make ? s.run.kept : nil
            if let src { v = (0..<4).map { i in src["v\(i)x"].map { (Int($0), Int(src["v\(i)y"] ?? 0)) } ?? pv[i] } }
            self.v = v
            pts = v.map { Pt(Quads3Lesson.O.x + Double($0.0), Quads3Lesson.O.y + Double($0.1)) }
            c = Quads3.classify(v)
            let W = Double(P.w) + (P.make ? 8 : 0)
            rx = ((Quads3Lesson.O.x + W + 2) / 5).rounded(.up) * 5; ry = Quads3Lesson.O.y
        }
        var ctr: Pt { Pt(pts.map(\.x).reduce(0, +) / 4, pts.map(\.y).reduce(0, +) / 4) }
        func dir(_ i: Int) -> Pt { let a = pts[i], b = pts[(i + 1) % 4], L = Geo4.dist(a, b); return Pt((b.x - a.x) / L, (b.y - a.y) / L) }
        func mid(_ i: Int) -> Pt { let a = pts[i], b = pts[(i + 1) % 4]; return Pt((a.x + b.x) / 2, (a.y + b.y) / 2) }
        /// Side i's normal pointing out of the shape.
        func out(_ i: Int) -> Pt {
            let d = dir(i), m = mid(i), C = ctr
            var n = Pt(d.y, -d.x)
            if n.x * (m.x - C.x) + n.y * (m.y - C.y) < 0 { n = Pt(-n.x, -n.y) }
            return n
        }
        func side(at q: Pt) -> Int? {
            (0..<4).filter { Geo4.segDist(q, pts[$0], pts[($0 + 1) % 4]) <= 1.4 }.min { Geo4.segDist(q, pts[$0], pts[($0 + 1) % 4]) < Geo4.segDist(q, pts[$1], pts[($1 + 1) % 4]) }
        }
        func inside(_ q: Pt) -> Bool {
            var c = false, j = 3
            for i in 0..<4 {
                let a = pts[i], b = pts[j]
                if (a.y > q.y) != (b.y > q.y) && q.x < (b.x - a.x) * (q.y - a.y) / (b.y - a.y) + a.x { c.toggle() }
                j = i
            }
            return c
        }
        /// The record's lines so far and where the blocks under them start.
        func lines(_ s: PaperState, _ st: Int) -> [(Int?, String, Bool)] {
            var rec: [(Int?, String, Bool)] = []
            let done = { (code: Int) in P.stages.firstIndex(of: code).map { k in (P.stages.firstIndex(of: st) ?? 0) >= k } ?? false }
            if P.warm && (st != 0 || !lit(s).isEmpty) { let n = st == 0 ? lit(s).count : 4; rec.append((n, n == 1 ? "side" : "sides", false)) }
            if !P.make && done(1) { let n = st == 1 ? found(s).count : c.nRight; rec.append((n, n == 1 ? "square corner" : "square corners", false)) }
            if !P.make && done(4) { let n = st == 4 ? pairs(s).count : c.nPar; rec.append((n, n == 1 ? "pair of parallel sides" : "pairs of parallel sides", false)) }
            if done(5) && st != 5 { rec.append((nil, Quads3.names[P.make ? Int(s.run.kept["made"] ?? 3) : P.shape], true)) }
            if P.also && st == 7 { rec.append((nil, P.shape == 0 ? "also a rectangle" : "not a square", false)) }
            return rec
        }
        func lit(_ s: PaperState) -> [Int] { (0..<4).filter { s.h("L\($0)") != nil }.sorted { (s.h("L\($0)") ?? 0) < (s.h("L\($1)") ?? 0) } }
        func found(_ s: PaperState) -> [Int] { (0..<4).filter { (s.h("f\($0)") ?? 0) > 0 } }
        func measured(_ s: PaperState) -> [Int] { (0..<4).filter { s.h("m\($0)") != nil } }
        func pairs(_ s: PaperState) -> [Int] { ["pA", "pB"].compactMap { s.h($0).map { Int($0) } } }
        /// Where the blocks go: under the record's lines.
        func by(_ s: PaperState, _ st: Int) -> Double { ry + 3 * Double(lines(s, st).count) }
        func yesNo(_ s: PaperState, _ st: Int) -> [CGRect] { let y = by(s, st); return [CGRect(x: rx, y: y, width: 4, height: 2), CGRect(x: rx + 5, y: y, width: 4, height: 2)] }
        func nameRects(_ s: PaperState, _ st: Int) -> [CGRect] {
            let y = by(s, st)
            return (0..<6).map { j in CGRect(x: rx + Double(j % 2) * 10, y: y + 3 * Double(j / 2), width: 9, height: 2) }
        }
    }

    func say(_ s: PaperState) -> String? {
        let P = Quads3.Parts(s.numbers)
        return at(s) == 7 && P.make ? P.doneSay(Int(s.run.kept["made"] ?? 3)) : nil
    }

    private static func lab(_ pen: inout GridPen, _ id: String, _ text: String, _ q: Q, _ i: Int, _ w: Sketch.Words, extra: Double = 0) {
        let n = q.out(i), m = q.mid(i), tw = PaperText.width(text, PaperText.font(w.size, w.weight)) / Paper.cell
        let off = 0.5 + extra + abs(n.x) * tw / 2 + abs(n.y) * 0.4
        pen.word(id, text, at: m.x + n.x * off, m.y + n.y * off, w)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = Q(s), P = q.P, c = q.c, st = at(s), pts = q.pts, ch = Sketch.Colour.chapter
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let ring = s.on("ring") || s.on("spot"), spot = s.on("spot"), making = st == 8
        func seg(_ pen: inout GridPen, _ id: String, _ i: Int, _ col: Sketch.Colour, dashed: Bool = false) { G8.seg(&pen, id, pts[i], pts[(i + 1) % 4], col, dashed: dashed) }
        // a side run on past both ends, dashed (kept on the paper's rows)
        func runOn(_ id: String, _ i: Int) {
            let d = q.dir(i), a = pts[i], b = pts[(i + 1) % 4]
            func far(_ p: Pt, _ sg: Double) -> Pt { var t = 4.0; let dy = d.y * sg; if dy < 0 { t = min(t, p.y / -dy) }; return Pt(p.x + d.x * sg * t, p.y + d.y * sg * t) }
            G8.seg(&pic, id, far(a, -1), far(b, 1), .ink2, dashed: true)
        }
        if making { G8.path(&live, "shape", pts, .ink, closed: true) } else { G8.path(&pic, "shape", pts, .ink, closed: true) }

        // sides, lit and numbered as they're tapped
        if st == 0 { for (n, i) in q.lit(s).enumerated() { seg(&pic, "lit\(i)", i, ch); Self.lab(&pic, "litn\(i)", "\(n + 1)", q, i, S3P.lit) } }
        // square corners: a small square in each
        let rc = P.make || st > 1 ? (0..<4).filter { c.right[$0] } : st == 1 ? q.found(s) : []
        for i in rc {
            let p = pts[i], u = q.dir(i), d0 = pts[(i + 3) % 4], L = Geo4.dist(p, d0), d = Pt((d0.x - p.x) / L, (d0.y - p.y) / L)
            let q1 = Pt(p.x + u.x * 1.5, p.y + u.y * 1.5), q3 = Pt(p.x + d.x * 1.5, p.y + d.y * 1.5)
            if making { G8.path(&live, "rc\(i)", [q1, Pt(q1.x + d.x * 1.5, q1.y + d.y * 1.5), q3], .ink) }
            else { G8.path(&pic, "rc\(i)", [q1, Pt(q1.x + d.x * 1.5, q1.y + d.y * 1.5), q3], .ink) }
        }
        // a corner that doesn't fit: the paper corner laid in it, red, its gap showing
        if st == 1, let wi = s.h("wc").map({ Int($0) }) {
            let p = pts[wi], u = q.dir(wi), d0 = pts[(wi + 3) % 4]
            var w = Pt(-u.y, u.x)
            if w.x * (d0.x - p.x) + w.y * (d0.y - p.y) < 0 { w = Pt(-w.x, -w.y) }
            let sq = [p, Pt(p.x + u.x * 4, p.y + u.y * 4), Pt(p.x + u.x * 4 + w.x * 4, p.y + u.y * 4 + w.y * 4), Pt(p.x + w.x * 4, p.y + w.y * 4)]
            G8.fill(&pic, "pc\(wi)", sq, .tint(0.2)); G8.path(&pic, "pco\(wi)", sq, KK.red, closed: true)
        }
        // lengths: a strip of squares along the side just measured; every measured side's length outside it; matching
        // sides the same tick marks
        let meas: [Int] = P.make ? [] : st == 2 ? q.measured(s) : st > 2 ? [0, 1, 2, 3] : []
        if st == 2, let li = s.h("last").map({ Int($0) }) {
            let a = pts[li], b = pts[(li + 1) % 4], u = q.dir(li), o = q.out(li), n = Pt(-o.x * 0.8, -o.y * 0.8), len = c.len[li]
            G8.fill(&pic, "strip\(li)", [a, b, Pt(b.x + n.x, b.y + n.y), Pt(a.x + n.x, a.y + n.y)], .tint(0.2))
            var segs: [(CGPoint, CGPoint)] = []
            for k in 1..<max(1, len) { let m = Pt(a.x + u.x * Double(k), a.y + u.y * Double(k)); segs.append((G8.cg(pic, m), G8.cg(pic, Pt(m.x + n.x, m.y + n.y)))) }
            if !segs.isEmpty { pic.sketch.segments("stript\(li)", segs, ch, width: Sketch.stroke) }
        }
        for i in meas { Self.lab(&pic, "len\(i)", "\(c.len[i])", q, i, S3P.small, extra: 0.8) }
        var groups: [Int] = []
        let tickSides = P.make ? [0, 1, 2, 3] : meas
        for i in tickSides {
            guard tickSides.filter({ c.l2[$0] == c.l2[i] }).count >= 2 else { continue }
            if !groups.contains(c.l2[i]) { groups.append(c.l2[i]) }
            let g = groups.firstIndex(of: c.l2[i]) ?? 0, m = q.mid(i), u = q.dir(i), n = q.out(i)
            for k in 0...g {
                let t = (Double(k) - Double(g) / 2) * 0.5, cx = m.x + u.x * t, cy = m.y + u.y * t
                let a = Pt(cx - n.x * 0.6, cy - n.y * 0.6), b = Pt(cx + n.x * 0.6, cy + n.y * 0.6)
                if making { G8.seg(&live, "eq\(i)_\(k)", a, b) } else { G8.seg(&pic, "eq\(i)_\(k)", a, b) }
            }
        }
        // parallel sides: matching arrowheads (one for the first pair, two for the second), pointing the same way
        let prs: [Int] = making || P.make ? [0, 1].filter { c.par[$0] } : st == 4 ? q.pairs(s) : st > 4 ? [0, 1].filter { c.par[$0] } : []
        for (g, k) in prs.enumerated() {
            let u = q.dir(k), wv = Pt(-u.y, u.x)
            for i in [k, k + 2] {
                let m = q.mid(i), base = Pt(m.x + u.x * 1.6, m.y + u.y * 1.6)
                for j in 0...g {
                    let tip = Pt(base.x + u.x * Double(j) * 0.6, base.y + u.y * Double(j) * 0.6), bk = Pt(tip.x - u.x * 0.6, tip.y - u.y * 0.6)
                    let arrow = [Pt(bk.x + wv.x * 0.55, bk.y + wv.y * 0.55), tip, Pt(bk.x - wv.x * 0.55, bk.y - wv.y * 0.55)]
                    if making { G8.path(&live, "par\(i)_\(j)", arrow, .ink) } else { G8.path(&pic, "par\(i)_\(j)", arrow, .ink) }
                }
            }
            if st == 4 { runOn("ro\(k)", k); runOn("ro\(k + 2)", k + 2) }
        }
        if st == 4, let sel = s.h("sel").map({ Int($0) }) { seg(&pic, "sel\(sel)", sel, ch) }
        if st == 4, let k = s.h("close").map({ Int($0) }) {
            let ci = Quads3.closeIn(q.v, k)
            runOn("cr\(k)", k); runOn("cr\(k + 2)", k + 2)
            // the side the ends drop onto runs on, dashed, as far as where they land
            let f0 = Pt(Self.O.x + ci.feet[0].0, Self.O.y + ci.feet[0].1), f1 = Pt(Self.O.x + ci.feet[1].0, Self.O.y + ci.feet[1].1)
            if let t = [k, k + 2].min(by: { abs((f0.x - pts[$0].x) * q.dir($0).y - (f0.y - pts[$0].y) * q.dir($0).x) < abs((f0.x - pts[$1].x) * q.dir($1).y - (f0.y - pts[$1].y) * q.dir($1).x) }) {
                let all = [f0, f1, pts[t], pts[(t + 1) % 4]]
                var best = (all[0], all[1]), bd = 0.0
                for a in all { for b in all where Geo4.dist(a, b) > bd { bd = Geo4.dist(a, b); best = (a, b) } }
                G8.seg(&pic, "crl\(k)", best.0, best.1, .ink2, dashed: true)
            }
            for j in 0..<2 {
                let f = Pt(Self.O.x + ci.from[j].0, Self.O.y + ci.from[j].1), ft = Pt(Self.O.x + ci.feet[j].0, Self.O.y + ci.feet[j].1)
                G8.seg(&pic, "drop\(k)_\(j)", f, ft, ch, dashed: true)
                let L = max(0.001, Geo4.dist(f, ft)), dd = Pt((ft.x - f.x) / L, (ft.y - f.y) / L), m = Pt((f.x + ft.x) / 2, (f.y + ft.y) / 2), C = q.ctr
                var n = Pt(dd.y, -dd.x)
                if n.x * (C.x - m.x) + n.y * (C.y - m.y) < 0 { n = Pt(-n.x, -n.y) }
                let off = 0.6 + abs(n.x) * Double(String(ci.d[j]).count) * 0.26 + abs(n.y) * 0.35
                pic.word("dropn\(k)_\(j)", "\(ci.d[j])", at: m.x + n.x * off, m.y + n.y * off, S3P.lit)
            }
        }
        for (i, p) in pts.enumerated() {
            if making { live.dot("mk\(i)", at: p.x, p.y, radius: (s.h("gi").map { Int($0) } == i && s.grabbed) ? 0.7 : 0.55) }
        }
        if making && s.grabbed { live.reads("\(S3.count(c.nRight, "square corner", "square corners")) · \(S3.count(c.nPar, "pair", "pairs")) of parallel sides") }

        // hints: a first miss rings the shape (or the picks); a second the corner, the pair or the right pick
        let xs = pts.map(\.x), ys = pts.map(\.y)
        if ring && [0, 1, 2, 4, 8].contains(st) { KK.hintBox(&pic, "hs", x: xs.min()!, y: ys.min()!, w: xs.max()! - xs.min()!, h: ys.max()! - ys.min()!) }
        if spot {
            switch st {
            case 0: if let i = (0..<4).first(where: { s.h("L\($0)") == nil }) { let m = q.mid(i); pic.circle("sp", at: m.x, m.y, radius: 1.5, .chapter, dashed: true) }
            case 1: if let i = (0..<4).first(where: { c.right[$0] && (s.h("f\($0)") ?? 0) == 0 }) { pic.circle("sp", at: pts[i].x, pts[i].y, radius: 1.5, .chapter, dashed: true) }
            case 2: if let i = (0..<4).first(where: { s.h("m\($0)") == nil }) { let m = q.mid(i); pic.circle("sp", at: m.x, m.y, radius: 1.5, .chapter, dashed: true) }
            case 4:
                if let k = [0, 1].first(where: { c.par[$0] && !q.pairs(s).contains($0) }) {
                    for i in [k, k + 2] { let m = q.mid(i); pic.circle("sp\(i)", at: m.x, m.y, radius: 1.5, .chapter, dashed: true) }
                }
            case 8: pic.circle("sp", at: pts[2].x, pts[2].y, radius: 1.5, .chapter, dashed: true)
            default: break
            }
        }

        // the record beside it: one short line a step
        let lines = q.lines(s, st)
        for (k, l) in lines.enumerated() {
            S3P.wordLine(&rec, "rec\(k)\(l.1)", l.0, l.1, colour: l.2 ? ch : .ink, x: q.rx, line: q.ry + 1 + 3 * Double(k))
        }
        // the picks, in the picture's squares under the record
        let bad = s.h("bad").map { Int($0) }
        if st == 3 || st == 6 {
            let r = q.yesNo(s, st)
            T3.block(&pic, "yes", x: r[0].minX, y: r[0].minY, w: 4, "Yes", wrong: bad == 1)
            T3.block(&pic, "no", x: r[1].minX, y: r[1].minY, w: 4, "No", wrong: bad == 0)
            if ring { KK.hintBox(&pic, "hb", x: q.rx, y: r[0].minY, w: 9, h: 2) }
            if spot { let i = st == 3 ? (c.allEqual ? 0 : 1) : (P.shape == 0 ? 0 : 1); KK.hintBox(&pic, "spb", x: r[i].minX, y: r[i].minY, w: 4, h: 2) }
        }
        if st == 5 {
            let r = q.nameRects(s, st)
            for (j, nm) in Quads3.names.enumerated() { T3.block(&pic, "nm\(j)", x: r[j].minX, y: r[j].minY, w: 9, P3.cap(nm), wrong: bad == j) }
            if ring { KK.hintBox(&pic, "hb", x: q.rx, y: r[0].minY, w: 19, h: 8) }
            if spot { let made = P.make ? Int(s.run.kept["made"] ?? 3) : P.shape; KK.hintBox(&pic, "spb", x: r[made].minX, y: r[made].minY, w: 9, h: 2) }
        }
        let ext = pic.R(0, 0, q.rx + 20, max(ys.max()! + (making ? 6 : 2), q.by(s, st) + (st == 5 ? 8 : 2)))
        let acts = st == 1 || st == 8 ? ["Done"] : st == 4 ? ["No more"] : []
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, actions: acts, extent: ext)
    }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let q = Q(s), st = at(s)
        return CGPoint(x: q.rx, y: q.by(s, st) + (st == 3 || st == 6 ? 3 : st == 5 ? 9 : 0))
    }

    func hands(_ s: PaperState) -> Hands? {
        let q = Q(s), P = q.P, c = q.c, st = at(s), base = s.hand
        func tapBlock(_ rects: [CGRect], _ box: String, want: Int, _ value: @escaping (Int) -> Int) -> Hands {
            Hands(tap: { cp in
                guard let i = G8.choice(at: cp, rects) else { return nil }
                var h = base; if value(i) != want { h["bad"] = Double(value(i)) }
                return HandMove(hand: h, missHand: h, set: [(box, Double(value(i)))], check: true)
            })
        }
        switch st {
        case 0:
            return Hands(tap: { cp in
                let p = G8.pt(cp)
                guard let i = q.side(at: p) else {
                    return q.inside(p) ? HandMove(hand: base, missHand: base, set: [("s", -1)], check: true) : nil
                }
                if base["L\(i)"] != nil { return HandMove(hand: base, missHand: base, set: [("s", -2)], check: true) }
                var h = base; h["L\(i)"] = Double(q.lit(s).count + 1)
                let n = (0..<4).filter { h["L\($0)"] != nil }.count
                return n == 4 ? HandMove(hand: h, missHand: h, set: [("s", 4)], check: true) : HandMove(hand: h)
            })
        case 1:
            let n = Double(q.found(s).count)
            return Hands(tap: { cp in
                let p = G8.pt(cp)
                guard let i = (0..<4).first(where: { Geo4.dist(p, q.pts[$0]) <= 2.6 }) else { return nil }
                var h = base; h["wc"] = nil
                if c.right[i] {
                    h["f\(i)"] = 1
                    let k = (0..<4).filter { (h["f\($0)"] ?? 0) > 0 }.count
                    return k == 4 ? HandMove(hand: h, missHand: h, set: [("c", 4)], check: true) : HandMove(hand: h)
                }
                h["wc"] = Double(i)
                return HandMove(hand: h, missHand: h, set: [("c", Double(100 + i))], check: true)
            }, actions: ["Done": { var h = base; h["wc"] = nil; return HandMove(hand: h, missHand: h, set: [("c", n)], check: true) }])
        case 2:
            return Hands(tap: { cp in
                guard let i = q.side(at: G8.pt(cp)) else { return nil }
                if base["m\(i)"] != nil { return HandMove(hand: base, missHand: base, set: [("l", -2)], check: true) }
                var h = base; h["m\(i)"] = Double(q.measured(s).count + 1); h["last"] = Double(i)
                let k = (0..<4).filter { h["m\($0)"] != nil }.count
                return k == 4 ? HandMove(hand: h, missHand: h, set: [("l", 4)], check: true) : HandMove(hand: h)
            })
        case 3: return tapBlock(q.yesNo(s, st), "e", want: c.allEqual ? 1 : 0) { $0 == 0 ? 1 : 0 }
        case 6: return tapBlock(q.yesNo(s, st), "a", want: P.shape == 0 ? 1 : 0) { $0 == 0 ? 1 : 0 }
        case 5:
            return Hands(tap: { cp in
                guard let i = G8.choice(at: cp, q.nameRects(s, st)) else { return nil }
                var h = base; let made = P.make ? Int(s.run.kept["made"] ?? 3) : P.shape
                if i != made { h["bad"] = Double(i) }
                return HandMove(hand: h, missHand: h, set: [("n", Double(i))], check: true)
            })
        case 4:
            let found = q.pairs(s)
            return Hands(tap: { cp in
                guard let i = q.side(at: G8.pt(cp)) else { return nil }
                var h = base; h["close"] = nil
                guard let a = h["sel"].map({ Int($0) }), a != i else { h["sel"] = h["sel"] == nil ? Double(i) : nil; return HandMove(hand: h) }
                h["sel"] = nil
                if (a - i + 4) % 2 == 1 { return HandMove(hand: h, missHand: h, set: [("p", 50)], check: true) }
                let k = min(a, i)
                if c.par[k] {
                    if !found.contains(k) { h[found.isEmpty ? "pA" : "pB"] = Double(k) }
                    let n = ["pA", "pB"].filter { h[$0] != nil }.count
                    return n == 2 ? HandMove(hand: h, missHand: h, set: [("p", 2)], check: true) : HandMove(hand: h)
                }
                h["close"] = Double(k)
                return HandMove(hand: h, missHand: h, set: [("p", Double(100 + k))], check: true)
            }, actions: ["No more": { var h = base; h["sel"] = nil; h["close"] = nil; return HandMove(hand: h, missHand: h, set: [("p", Double(found.count))], check: true) }])
        case 8:
            var cur: Numbers = [:]
            for i in 0..<4 { cur["v\(i)x"] = Double(q.v[i].0); cur["v\(i)y"] = Double(q.v[i].1) }
            let W = Double(P.w), H = Double(P.h)
            return Hands(
                grab: { cp in
                    let p = G8.pt(cp)
                    guard let i = (0..<4).first(where: { Geo4.dist(p, q.pts[$0]) < 2.5 }) else { return nil }
                    var h = cur; h["grab"] = 1; h["gi"] = Double(i); return h
                },
                drag: { cp, h in
                    var h = h; let i = Int(h["gi"] ?? 0)
                    h["v\(i)x"] = max(-Self.O.x, min(W + 8, (cp.x - Self.O.x).rounded())); h["v\(i)y"] = max(-2, min(H + 5, (cp.y - Self.O.y).rounded()))
                    return h
                },
                release: { h in
                    var v2 = cur
                    for i in 0..<4 { v2["v\(i)x"] = h["v\(i)x"]; v2["v\(i)y"] = h["v\(i)y"] }
                    let vs = (0..<4).map { (Int(v2["v\($0)x"] ?? 0), Int(v2["v\($0)y"] ?? 0)) }, code = Quads3.madeCode(vs)
                    return code < 0 ? HandMove(hand: cur, missHand: cur, set: [("m", Double(code))], check: true) : HandMove(hand: v2)
                },
                actions: ["Done": {
                    let code = Quads3.madeCode(q.v)
                    var keep = cur
                    keep["made"] = Double(code); keep["mR"] = Double(c.nRight); keep["mE"] = c.allEqual ? 1 : 0; keep["mP"] = Double(c.nPar)
                    return HandMove(hand: cur, missHand: cur, set: [("m", Double(code))], keep: keep, check: true)
                }])
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = Q(s), P = q.P, c = q.c, st = at(s)
        func tap(_ p: Pt) -> GhostMove { .tap(.picture(CGPoint(x: p.x, y: p.y))) }
        func centre(_ r: CGRect) -> GhostMove { .tap(.picture(CGPoint(x: r.midX, y: r.midY))) }
        switch st {
        case 0: return (0..<4).filter { s.h("L\($0)") == nil }.map { tap(q.mid($0)) }
        case 1:
            let left = (0..<4).filter { c.right[$0] && (s.h("f\($0)") ?? 0) == 0 }.map { tap(q.pts[$0]) }
            return c.nRight == 4 ? left : left + [.tap(.action("Done"))]
        case 2: return (0..<4).filter { s.h("m\($0)") == nil }.map { tap(q.mid($0)) }
        case 3: return [centre(q.yesNo(s, st)[c.allEqual ? 0 : 1])]
        case 6: return [centre(q.yesNo(s, st)[P.shape == 0 ? 0 : 1])]
        case 5: return [centre(q.nameRects(s, st)[P.make ? Int(s.run.kept["made"] ?? 3) : P.shape])]
        case 4:
            var out: [GhostMove] = []
            for k in [0, 1] where c.par[k] && !q.pairs(s).contains(k) { out.append(tap(q.mid(k))); out.append(tap(q.mid(k + 2))) }
            return c.nPar == 2 ? out : out + [.tap(.action("No more"))]
        case 8:
            let p = q.pts[2]
            return [.drag(from: CGPoint(x: p.x, y: p.y), to: CGPoint(x: p.x + 5, y: p.y)), .tap(.action("Done"))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let q = Q(s), c = q.c, P = q.P
        switch at(s) {
        case 0: return HandMove(hand: [:], missHand: [:], set: [("s", -1)], check: true)
        case 1:
            if let i = (0..<4).first(where: { !c.right[$0] }) { return HandMove(hand: ["wc": Double(i)], missHand: ["wc": Double(i)], set: [("c", Double(100 + i))], check: true) }
            return HandMove(hand: [:], missHand: [:], set: [("c", 3)], check: true)
        case 3: let b = c.allEqual ? 0.0 : 1; return HandMove(hand: ["bad": b], missHand: ["bad": b], set: [("e", b)], check: true)
        case 6: let b = P.shape == 0 ? 0.0 : 1; return HandMove(hand: ["bad": b], missHand: ["bad": b], set: [("a", b)], check: true)
        case 4:
            if let k = [0, 1].first(where: { !c.par[$0] }) { return HandMove(hand: ["close": Double(k)], missHand: ["close": Double(k)], set: [("p", Double(100 + k))], check: true) }
            return HandMove(hand: [:], missHand: [:], set: [("p", 50)], check: true)
        case 5: let b = Double(P.shape == 5 ? 4 : 5); return HandMove(hand: ["bad": b], missHand: ["bad": b], set: [("n", b)], check: true)
        case 8: return HandMove(hand: [:], missHand: [:], set: [("m", 0)], check: true)
        default: return nil
        }
    }
}
