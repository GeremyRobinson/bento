import SwiftUI

/// Sorting by sides and angles on the paper, as in the preview (design/prototype/grade4-ch8.html), with 5th grade's
/// Sorting shapes' marks: the shape on the left, corners on grid points; a block to its right two overlapping loops in
/// a frame, named "parallel sides" and "a square corner" (for triangles "a square corner" and "an obtuse angle").
/// 1. Tap each square corner: the page corner lays itself on it, and when it fits the little square mark is drawn (for
///    triangles an obtuse corner gets its arc); No more. 2. Tap two sides that are parallel: matching arrowheads (one on
///    the first pair, two on the second); No more. 3. Drag the shape (a small copy follows the finger) into one loop,
///    the other, both, or outside both. The record names what it has and where it went.
///
/// The picture's squares: the shape from column 0, centred on the loops' 20 rows; the loops' frame 35 × 20 from the
/// first block line 5 squares past it; the blocks and the record under them.
@MainActor
struct ClassifyLesson: PaperLesson {
    typealias Pt = Geo4.Pt
    static let LH = 20.0, LW = 35.0, LR = Pt(10.5, 8.5)
    var liveKeys: Set<String> { ["qx", "qy"] }

    @MainActor struct Q {
        let p: Classify4.Parts
        let pts: [Pt], lx: Double, ly: Double, mid: Pt, recY: Double
        var loops: [Pt] { [Pt(lx + 12, ly + 10.5), Pt(lx + 23, ly + 10.5)] }
        init(_ n: Numbers) {
            p = Classify4.Parts(n)
            let oy = ((ClassifyLesson.LH - Double(p.h)) / 2).rounded()
            ly = max(0, -oy)
            let top = max(0, oy)
            pts = p.pts.map { Pt(Double($0.0), Double($0.1) + top) }
            lx = ((Double(p.w) + 5) / 5).rounded(.up) * 5
            mid = Pt(pts.map(\.x).reduce(0, +) / Double(pts.count), pts.map(\.y).reduce(0, +) / Double(pts.count))
            recY = max(ly + ClassifyLesson.LH, top + Double(p.h)) + 2
        }
        func inLoop(_ q: Pt, _ c: Pt) -> Bool { pow((q.x - c.x) / ClassifyLesson.LR.x, 2) + pow((q.y - c.y) / ClassifyLesson.LR.y, 2) <= 1 }
        func inFrame(_ q: Pt) -> Bool { q.x >= lx && q.x <= lx + ClassifyLesson.LW && q.y >= ly && q.y <= ly + ClassifyLesson.LH }
        /// How the page corner lies on corner i: along its sides.
        func pcAngle(_ i: Int) -> (a: Double, sweep: Double, lo: Double) {
            let n = pts.count, u = p.sides[i], w = (-p.sides[(i + n - 1) % n].0, -p.sides[(i + n - 1) % n].1)
            let a = Geo4.angOf(Pt(0, 0), Pt(Double(u.0), Double(u.1))), wa = Geo4.angOf(Pt(0, 0), Pt(Double(w.0), Double(w.1)))
            let d = Geo4.adiff(wa, a)
            return (d > 0 ? a : a - 90, abs(d), d > 0 ? a : wa)
        }
        func inside(_ q: Pt) -> Bool {
            var c = false, j = pts.count - 1
            for i in pts.indices {
                let a = pts[i], b = pts[j]
                if (a.y > q.y) != (b.y > q.y) && q.x < (b.x - a.x) * (q.y - a.y) / (b.y - a.y) + a.x { c.toggle() }
                j = i
            }
            return c
        }
        func side(at q: Pt) -> Int? {
            p.sides.indices.first { k in Geo4.segDist(q, pts[k], pts[(k + 1) % pts.count]) <= 1.3 && pts.allSatisfy { Geo4.dist(q, $0) > 1.6 } }
        }
    }

    private func pairs(_ h: Numbers) -> [(Int, Int)] {
        ["pA", "pB"].compactMap { h[$0].map { (Int($0) / 10, Int($0) % 10) } }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = Q(s.numbers), p = q.p, at = G8.stage(s), done = at >= 4, n = q.pts.count
        var pic = GridPen(), live = GridPen(stableIds: true)
        let held = s.grabbed
        // the corners marked and the pairs found: this step's hand, or every one once its step is done
        let marked: [Int] = at == 1 ? (0..<n).filter { (s.h("m\($0)") ?? 0) > 0 } : at >= 2 ? p.marks : []
        let found: [(Int, Int)] = at == 2 ? pairs(s.hand) : at >= 3 ? p.pairs : []
        G8.fill(&pic, "shape", q.pts, .tint(0.2))
        // the page corner laid on the corner tapped: over the shape's fill, under its sides
        if at == 1, let c = s.h("pc").map({ Int($0) }), c < n { G8.pageCorner(&pic, "pco\(c)", at: q.pts[c], q.pcAngle(c).a, laid: true) }
        G8.path(&pic, "shapeo", q.pts, .ink, closed: true)
        // the side picked first, lit
        if at == 2, let i = s.h("sel").map({ Int($0) }), i < n {
            pic.sketch.line("sel\(i)", [G8.cg(pic, q.pts[i]), G8.cg(pic, q.pts[(i + 1) % n])], .tint(0.45), width: 12)
        }
        for (k, pr) in found.enumerated() {
            let u = p.sides[pr.0], ad = Geo4.angOf(Pt(0, 0), Pt(Double(u.0), Double(u.1)))
            for i in [pr.0, pr.1] {
                let a = q.pts[i], b = q.pts[(i + 1) % n], m = Pt((a.x + b.x) / 2, (a.y + b.y) / 2)
                for j in 0...k { G8.arrow(&pic, "par\(k)_\(i)_\(j)", Geo4.pol(m, Double(j) * 0.9 - Double(k) * 0.45, ad), ad, .chapter) }
            }
        }
        for i in marked {
            let g = q.pcAngle(i)
            if p.corners[i] == .square { G8.cornerMark(&pic, "cm\(i)", q.pts[i], g.a) } else { G8.arc(&pic, "ob\(i)", q.pts[i], 2, g.lo, g.lo + g.sweep) }
        }
        for (i, c) in q.pts.enumerated() { pic.dot("v\(i)", at: c.x, c.y, radius: 0.3, .ink, over: true) }

        // the loops in their frame (the frame is "neither")
        pic.sketch.box("lframe", pic.R(q.lx, q.ly, Self.LW, Self.LH), .ink3, width: Sketch.stroke)
        for (k, c) in q.loops.enumerated() {
            pic.ring("loop\(k)", col: c.x - Self.LR.x, row: c.y - Self.LR.y, w: 2 * Self.LR.x, h: 2 * Self.LR.y, .ink2)
            pic.word("lname\(k)", p.names[k], at: c.x + (k == 1 ? 4 : -4), q.ly + 1.3, G8.pencil)
        }
        // the small copy the hand drags; where it was let go once it's right
        let drop: Pt? = held ? s.h("qx").map { Pt($0, s.h("qy") ?? 0) } : done ? s.run.kept["qx"].map { Pt($0, s.run.kept["qy"] ?? 0) } : nil
        if let d = drop {
            let mini = q.pts.map { Pt(d.x + ($0.x - q.mid.x) * 0.3, d.y + ($0.y - q.mid.y) * 0.3) }
            var pen = held ? live : pic
            G8.fill(&pen, "minif\(done)", mini, .tint(0.45))
            G8.path(&pen, "minio\(done)", mini, done ? .chapter : .ink, closed: true)
            if held { live = pen } else { pic = pen }
        }

        // what the page corner showed, or the pairs found, under the loops
        let flash: String? = {
            if at == 1, let c = s.h("pc").map({ Int($0) }), c < n, (s.h("m\(c)") ?? 0) > 0 {
                return p.corners[c] == .square ? "The page corner fits: a square corner." : "It opens past the page corner: obtuse."
            }
            if at == 2, !found.isEmpty { return "\(found.count) \(found.count == 1 ? "pair" : "pairs") of parallel sides" }
            return nil
        }()
        if let f = flash { G8.aside(&pic, "flash", f, x: q.lx, y: q.ly + Self.LH + 1.5, w: Self.LW) }

        // hints: after a miss the shape (or the loops) ringed; after a second, the corner, the side or the loop
        if s.on("spot") {
            switch at {
            case 1: if let i = p.marks.first(where: { !marked.contains($0) }) { pic.circle("spot", at: q.pts[i].x, q.pts[i].y, radius: 1.5, .chapter, dashed: true) }
            case 2:
                if let pr = p.pairs.first(where: { pr in !found.contains { $0 == pr } }) {
                    for i in [pr.0, pr.1] { let a = q.pts[i], b = q.pts[(i + 1) % n]; pic.circle("spot\(i)", at: (a.x + b.x) / 2, (a.y + b.y) / 2, radius: 1.5, .chapter, dashed: true) }
                }
            case 3:
                let w = p.want, c: Pt = w[0] && w[1] ? Pt(q.lx + 17.5, q.ly + 10.5) : w[0] ? Pt(q.lx + 7, q.ly + 10.5) : w[1] ? Pt(q.lx + 28, q.ly + 10.5) : Pt(q.lx + 2.5, q.ly + 2.5)
                pic.circle("spot", at: c.x, c.y, radius: 2, .chapter, dashed: true)
            default: break
            }
        }

        if done { pic.word("rec", p.record, at: 0, q.recY + 1, Record.words.colour(.chapter), anchor: UnitPoint(x: 0, y: 0.5)) }
        let ext = pic.R(0, 0, q.lx + Self.LW, q.recY + (done ? 2 : 0))
        return PaperDrawing(picture: pic.sketch, live: live.sketch, actions: at == 1 || at == 2 ? ["No more"] : [], extent: ext)
    }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let q = Q(s.numbers), at = G8.stage(s)
        return at >= 4 ? CGPoint(x: 0, y: q.recY + 3) : CGPoint(x: 0, y: q.recY)
    }
    func messageRows(_ n: Numbers) -> Int { 2 }

    func hands(_ s: PaperState) -> Hands? {
        let q = Q(s.numbers), p = q.p, n = q.pts.count
        switch G8.stage(s) {
        case 1:
            let base = s.hand
            let count = Double((0..<n).filter { (base["m\($0)"] ?? 0) > 0 }.count)
            return Hands(tap: { c in
                guard let i = q.pts.indices.first(where: { Geo4.dist(G8.pt(c), q.pts[$0]) <= 2.2 }) else { return nil }
                var h = base; h["pc"] = Double(i)
                if p.marks.contains(i) { h["m\(i)"] = 1; return HandMove(hand: h) }
                return HandMove(hand: h, missHand: h, set: [("x", Double(100 + i))], check: true)
            }, actions: ["No more": { HandMove(hand: base, missHand: base, set: [("x", count)], check: true) }])
        case 2:
            let base = s.hand, found = pairs(base)
            return Hands(tap: { c in
                guard let i = q.side(at: G8.pt(c)) else { return nil }
                var h = base
                if found.contains(where: { $0.0 == i || $0.1 == i }) { return HandMove(hand: h) }
                guard let j = h["sel"].map({ Int($0) }), j != i else { h["sel"] = h["sel"] == nil ? Double(i) : nil; return HandMove(hand: h) }
                h["sel"] = nil
                if Geo4.same(p.sides[i], p.sides[j]) { h[found.isEmpty ? "pA" : "pB"] = Double(10 * min(i, j) + max(i, j)); return HandMove(hand: h) }
                return HandMove(hand: h, missHand: h, set: [("y", Double(100 + 10 * j + i))], check: true)
            }, actions: ["No more": { var h = base; h["sel"] = nil; return HandMove(hand: h, missHand: h, set: [("y", Double(found.count))], check: true) }])
        case 3:
            return Hands(grab: { c in
                q.inside(G8.pt(c)) ? ["grab": 1, "ox": c.x - q.mid.x, "oy": c.y - q.mid.y, "qx": q.mid.x, "qy": q.mid.y] : nil
            }, drag: { c, h in
                var h = h; h["qx"] = c.x - (h["ox"] ?? 0); h["qy"] = c.y - (h["oy"] ?? 0); return h
            }, release: { h in
                let d = Pt(h["qx"] ?? 0, h["qy"] ?? 0)
                guard q.inFrame(d) else { return HandMove(hand: [:]) }
                let z = (q.inLoop(d, q.loops[0]) ? 2 : 0) + (q.inLoop(d, q.loops[1]) ? 1 : 0)
                let right = z == (p.want[0] ? 2 : 0) + (p.want[1] ? 1 : 0)
                return HandMove(hand: [:], missHand: [:], set: [("z", Double(z))], keep: right ? ["qx": d.x, "qy": d.y] : [:], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = Q(s.numbers), p = q.p, n = q.pts.count
        func c(_ a: Pt) -> CGPoint { CGPoint(x: a.x, y: a.y) }
        switch G8.stage(s) {
        case 1: return p.marks.filter { (s.h("m\($0)") ?? 0) == 0 }.map { .tap(.picture(c(q.pts[$0]))) } + [.tap(.action("No more"))]
        case 2:
            var moves: [GhostMove] = []
            if let j = s.h("sel").map({ Int($0) }) { let a = q.pts[j], b = q.pts[(j + 1) % n]; moves.append(.tap(.picture(CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)))) }
            let found = pairs(s.hand)
            for pr in p.pairs where !found.contains(where: { $0 == pr }) {
                for i in [pr.0, pr.1] { let a = q.pts[i], b = q.pts[(i + 1) % n]; moves.append(.tap(.picture(CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)))) }
            }
            return moves + [.tap(.action("No more"))]
        case 3:
            let w = p.want
            let to: Pt = w[0] && w[1] ? Pt(q.lx + 17.5, q.ly + 10.5) : w[0] ? Pt(q.lx + 6, q.ly + 10.5) : w[1] ? Pt(q.lx + 29, q.ly + 10.5) : Pt(q.lx + 2.5, q.ly + 17)
            return [.drag(from: c(q.mid), to: c(to))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let q = Q(s.numbers), p = q.p
        switch G8.stage(s) {
        case 1:
            if let i = p.corners.indices.first(where: { !p.marks.contains($0) }) { return HandMove(hand: ["pc": Double(i)], missHand: ["pc": Double(i)], set: [("x", Double(100 + i))], check: true) }
            return HandMove(hand: [:], missHand: [:], set: [("x", 0)], check: true)
        case 2:
            let n = q.pts.count
            if let i = (0..<n).first(where: { !Geo4.same(p.sides[$0], p.sides[($0 + 1) % n]) }) { return HandMove(hand: [:], missHand: [:], set: [("y", Double(100 + 10 * i + (i + 1) % n))], check: true) }
            return HandMove(hand: [:], missHand: [:], set: [("y", 0)], check: true)
        case 3:
            let z = ((p.want[0] ? 2 : 0) + (p.want[1] ? 1 : 0) + 1) % 4
            return HandMove(hand: [:], missHand: [:], set: [("z", Double(z))], check: true)
        default: return nil
        }
    }
}
