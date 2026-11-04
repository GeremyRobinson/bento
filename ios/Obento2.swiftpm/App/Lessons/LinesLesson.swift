import SwiftUI

/// Points, lines, rays and angles on the paper, as in the preview (design/prototype/grade4-ch8.html): a figure 30–40
/// squares long through points on grid points, turned by grid steps. A line, ray or segment: tap each end (its words
/// beside it: "a dot: it stops here", "an arrowhead: it goes on"), then tap its name. An angle: drag the page corner
/// onto its corner (it lays itself along the first arm; beside it, "It opens past the page corner."), then its name.
/// Two lines: drag an arrowhead of each away so the line runs on (they stay 4 squares apart, dashed, or cross); where
/// they cross, drag the page corner on; then their name. Made (from index 6): tap the ends to dots or arrowheads, then
/// Check; turn the free arm (live acute, right, obtuse in the bar); or draw a line from P (live parallel,
/// perpendicular).
///
/// The picture's squares: the figure from (0, 0); the page corner rests 3 squares past it; the names (and the record)
/// beside the picture or under it, whichever shows the problem bigger.
@MainActor
struct LinesLesson: PaperLesson {
    typealias Pt = Geo4.Pt
    typealias St = LinesRays.Stage
    var liveKeys: Set<String> { ["px", "py", "pull", "v", "dx", "dy"] }

    struct Line { let q: Pt, u: Pt, lo: Double, hi: Double, t0: Double, t1: Double
        func at(_ t: Double) -> Pt { Pt(q.x + u.x * t, q.y + u.y * t) }
        var a: Double { Geo4.angOf(Pt(0, 0), u) }
    }

    @MainActor struct Q {
        let p: LinesRays.Parts
        var S = Pt(0, 0), E = Pt(0, 0), A = Pt(0, 0), B = Pt(0, 0), C = Pt(0, 0), X = Pt(0, 0), P = Pt(0, 0)
        var a = 0.0, a0 = 0.0, L1 = 0.0, L2 = 0.0
        var l = 0.0, r = 0.0, t = 0.0, b = 0.0
        var lines: [Line] = []
        let rest: Pt
        let rec: (x: Double, y: Double, beside: Bool)
        let W = 40.0, H = 22.0

        init(_ n: Numbers) {
            p = LinesRays.Parts(n)
            var pts: [Pt]
            switch p.kind {
            case 0:
                let d = LinesRays.dirs[p.turn], dx = Double(d.0), dy = Double(d.1)
                // steep figures are 26 squares (the design says 30), so they show at 75% on an 11-inch iPad
                let k = ((abs(dy) > abs(dx) ? 26 : abs(dy) == abs(dx) ? 34 : 40) / hypot(dx, dy)).rounded()
                func at(_ t: Double) -> Pt { Pt(t * dx, t * dy) }
                S = at(0); E = at(k); a = Geo4.angOf(Pt(0, 0), Pt(dx, dy))
                A = p.item == 0 ? at((0.3 * k).rounded()) : S
                B = p.item == 2 ? E : at(((p.item == 1 ? 0.55 : 0.7) * k).rounded())
                pts = [S, E]
                // the ends' words: past a flat figure's ends, beside a steep one's
                let f = PaperText.font(G8.small.size, G8.small.weight)
                let lw = max(PaperText.width("a dot: it stops here", f), PaperText.width("an arrowhead: it goes on", f)) / Paper.cell
                for (e, ang) in [(S, a + 180), (E, a)] {
                    let c = cos(ang * .pi / 180), o = Geo4.pol(e, 2.4, ang)
                    pts.append(dy == 0 ? Pt(e.x, e.y + 2.5) : abs(c) < 0.5 ? Pt(e.x + 1.6 + lw, e.y) : Pt(c > 0 ? o.x + lw : o.x - lw, o.y))
                }
            case 1:
                a0 = p.make ? 0 : p.deg > 90 ? 180 * Double(p.turn % 2) : 90 * Double(p.turn % 4)
                if p.make { L1 = 26; L2 = 22; pts = [C, Geo4.pol(C, 26, a0), Geo4.pol(C, 22, a0 + 90), Geo4.pol(C, 22, a0 + 180)] }
                else {
                    L1 = p.deg < 90 ? 28 : p.deg == 180 ? 20 : 22; L2 = L1
                    pts = [C, Geo4.pol(C, L1, a0), Geo4.pol(C, L2, a0 + Double(p.deg))] + G8.pcPts(C, a0)
                }
            default:
                X = Pt(20, 11); pts = [Pt(0, 0), Pt(W, H)]
            }
            // room round it: for an arrowhead and an end's words (beside a steep figure's ends, past a flat one's)
            let pad = p.kind == 2 ? 0 : p.kind == 1 ? 1 : 2.5, padY = p.kind == 0 ? 1.5 : pad
            let l0 = pts.map(\.x).min()! - pad, r0 = pts.map(\.x).max()! + pad, t0 = pts.map(\.y).min()! - padY, b0 = pts.map(\.y).max()! + padY
            let sh = Pt((-l0).rounded(), (-t0).rounded() + (p.kind == 2 ? 0 : max(0, ((20 - (b0 - t0)) / 2).rounded(.down))))
            S = S + sh; E = E + sh; A = A + sh; B = B + sh; C = C + sh; X = X + sh
            l = l0 + sh.x; r = r0 + sh.x; t = t0 + sh.y; b = b0 + sh.y
            if p.kind == 2 {
                let d1 = p.d1, d2 = p.d2, off = d1.0 == 0 ? Pt(2, 0) : Pt(0, 2)
                func un(_ d: (Int, Int)) -> Pt { let k = hypot(Double(d.0), Double(d.1)); return Pt(Double(d.0) / k, Double(d.1) / k) }
                var out: [Line] = []
                let (W, H, l, t) = (self.W, self.H, self.l, self.t)
                func add(_ q: Pt, _ d: (Int, Int), _ a: Double, _ b: Double) {
                    let u = un(d), (lo, hi) = Self.clip(Pt(q.x - l, q.y - t), u, W, H)
                    out.append(Line(q: q, u: u, lo: lo, hi: hi, t0: max(a, lo + 3), t1: min(b, hi - 3)))
                }
                if p.make { add(X, d1, -1e9, 1e9); P = Pt(X.x + 2 * off.x, X.y + 2 * off.y) }
                else if p.item == 0 { add(Pt(X.x - off.x, X.y - off.y), d1, -15, 3); add(Pt(X.x + off.x, X.y + off.y), d2, -3, 15) }
                else { add(X, d1, 5, 19); add(X, d2, -19, -5) }
                lines = out
            }
            rest = Pt(r.rounded(.up) + 3, 7)
            let placed = G8.placeRecord(r: r + (p.kind == 1 && !p.make ? 10 : 0), b: b, w: Self.recW(p), h: 5,
                                 wBeside: p.make ? nil : max(G8.columnWidth(p.names), Record.width(p.named) + 1), hBeside: p.make ? nil : 3 * Double(p.names.count) + 2)
            // beside, the names start two rows lower: what a tool showed is written over them
            rec = placed.beside && !p.make ? (placed.x, placed.y + 2, true) : placed
        }
        /// The record's width: the names to pick from, or the name and its blocks (Check, Next problem).
        static func recW(_ p: LinesRays.Parts) -> Double { p.make ? max(Record.width(p.named) + 1, 10) : G8.choicesWidth(p.names) }
        /// The record's width where it is.
        var recWidth: Double { rec.beside && !p.make ? max(G8.columnWidth(p.names), Record.width(p.named) + 1) : Q.recW(p) }
        /// Where a line through q along u leaves the box W × H.
        static func clip(_ q: Pt, _ u: Pt, _ W: Double, _ H: Double) -> (Double, Double) {
            var lo = -1e9, hi = 1e9
            for (a, v, m) in [(q.x, u.x, W), (q.y, u.y, H)] {
                guard abs(v) > 1e-9 else { continue }
                var s = -a / v, e = (m - a) / v
                if s > e { swap(&s, &e) }
                lo = max(lo, s); hi = min(hi, e)
            }
            return (lo, hi)
        }
        /// Where the page corner goes: the angle's corner along its first arm, or where the lines cross along the first.
        var target: (at: Pt, a: Double) { p.kind == 1 ? (C, a0) : (X, Geo4.angOf(Pt(0, 0), Pt(Double(p.d1.0), Double(p.d1.1)))) }
        func endType(_ i: Int, _ s: PaperState) -> Int {
            if p.make { return Int(s.h("e\(i)") ?? 0) }
            return i == 0 ? (p.item == 0 ? 2 : 1) : (p.item == 2 ? 1 : 2)
        }
        /// The made line's grid steps: what's drawn, or the right one once it's done.
        var goal: (Int, Int) { p.item == 0 ? p.d1 : (-p.d1.1, p.d1.0) }
        /// The choices' places.
        var choiceRects: [CGRect] {
            G8.choiceRects(x: rec.x, y: rec.y - 1, p.names, column: rec.beside)
        }
    }

    private func st(_ s: PaperState) -> St { St(rawValue: G8.stage(s)) ?? .ask }

    func draw(_ s: PaperState) -> PaperDrawing {
        let q = Q(s.numbers), p = q.p, stage = st(s), done = stage == .done
        var pic = GridPen(), live = GridPen(stableIds: true)
        let held = s.grabbed, hint = s.on("ring") || s.on("spot"), spot = s.on("spot")

        switch p.kind {
        case 0:
            G8.seg(&pic, "fig", q.S, q.E)
            for (i, e) in [q.S, q.E].enumerated() {
                let a = i == 0 ? q.a + 180 : q.a, t = q.endType(i, s)
                let lit = !p.make && ((s.h("s\(i)") ?? 0) > 0 || stage == .name || done)
                let c: Sketch.Colour = lit ? .chapter : .ink
                if t == 1 { pic.dot("end\(i)d\(lit)", at: e.x, e.y, radius: 0.45, c, over: true) }
                else if t == 2 { G8.arrow(&pic, "end\(i)a\(lit)", e, a, c) }
                else { pic.circle("end\(i)o", at: e.x, e.y, radius: 0.6, .ink3) }
                if lit {
                    let o = Geo4.pol(e, 2.4, a), cx = cos(a * .pi / 180), steep = abs(cx) < 0.5
                    let words = t == 1 ? "a dot: it stops here" : "an arrowhead: it goes on"
                    // under a flat figure's ends, running in (so it fits at 75%); beside a steep one's
                    if abs(sin(a * .pi / 180)) < 0.01 { pic.word("endw\(i)", words, at: e.x, e.y + 1.8, G8.small, anchor: UnitPoint(x: cx > 0 ? 1 : 0, y: 0.5)) }
                    else if steep { pic.word("endw\(i)", words, at: e.x + 1.6, e.y, G8.small, anchor: UnitPoint(x: 0, y: 0.5)) }
                    else { pic.word("endw\(i)", words, at: o.x, o.y, G8.small, anchor: UnitPoint(x: cx > 0 ? 0 : 1, y: 0.5)) }
                }
                // a hint after a second miss: the end that's wrong
                if p.make && stage == .make && spot {
                    let want = i == 0 ? (p.item == 0 ? 2 : 1) : (p.item == 2 ? 1 : 2)
                    if t != want { pic.circle("ring\(i)", at: e.x, e.y, radius: 1.6, .chapter, dashed: true) }
                }
            }
            for (nm, pt) in [("A", q.A), ("B", q.B)] {
                if !(nm == "A" ? p.item != 0 : p.item == 2) || p.make && (nm == "A" ? pt != q.S : pt != q.E) { pic.dot("pt\(nm)", at: pt.x, pt.y, radius: 0.35, .ink, over: true) }
                let o = Geo4.pol(pt, 1.8, q.a + 90)
                pic.word("pn\(nm)", nm, at: o.x, o.y, G8.say)
            }
        case 1:
            if stage == .name || done || p.make { G8.pageCorner(&pic, "pc", at: q.C, q.a0) }
            G8.seg(&pic, "arm1", q.C, Geo4.pol(q.C, q.L1, q.a0))
            if p.make {
                let v = s.h("v") ?? (done ? Double([45, 90, 135][p.item]) : 0), a2 = q.a0 + v
                var pen = held ? live : pic
                G8.wedge(&pen, "wd\(Int(v))", q.C, 5, q.a0, a2)
                if Int(v) == 90 { G8.cornerMark(&pen, "cm", q.C, q.a0) }
                G8.seg(&pen, "arm2\(Int(v))", q.C, Geo4.pol(q.C, q.L2, a2), done ? .chapter : .ink)
                if held { live = pen } else { pic = pen }
                if stage == .turn {
                    let h = Geo4.pol(q.C, q.L2, a2)
                    live.dot("hd", at: h.x, h.y, radius: held ? 0.75 : 0.55, .ink, over: true)
                    if held && v > 0 { live.reads(Geo4.kinds[Geo4.kind(Int(v))].lowercased()) }
                    // a hint: after a miss, the part of the turn the arm goes in; after a second, where it stops
                    if spot { let g = Geo4.pol(q.C, q.L2, q.a0 + Double([45, 90, 135][p.item])); pic.circle("spot", at: g.x, g.y, radius: 1.4, .chapter, dashed: true) }
                    else if s.on("ring") && p.item != 1 { G8.arc(&pic, "ring", q.C, q.L2 + 2, q.a0 + (p.item == 0 ? 3 : 93), q.a0 + (p.item == 0 ? 87 : 177), .chapter, dashed: true) }
                }
            } else {
                G8.seg(&pic, "arm2", q.C, Geo4.pol(q.C, q.L2, q.a0 + Double(p.deg)))
            }
            pic.dot("corner", at: q.C.x, q.C.y, radius: 0.35, .ink, over: true)
            // what the page corner showed: over the names when they're beside the angle, else where the page corner rested
            if !p.make && (stage == .name || done) {
                if q.rec.beside { G8.aside(&pic, "fd", p.finding, x: q.rec.x, y: 0, w: max(16, q.recWidth)) } else { G8.aside(&pic, "fd", p.finding, x: q.rest.x, y: 2, w: 14) }
            }
            if stage == .corner {
                let at = Pt(s.h("px") ?? q.rest.x, s.h("py") ?? q.rest.y)
                if held { G8.pageCorner(&live, "pcr", at: at, 0) } else { G8.pageCorner(&pic, "pcr", at: at, 0) }
                if spot { pic.circle("spot", at: q.C.x, q.C.y, radius: 1.4, .chapter, dashed: true) }
            }
        default:
            let tg = q.target
            if (stage == .name || done) && p.item > 0 && !p.make { G8.pageCorner(&pic, "pcl", at: q.X, tg.a) }
            if p.make && done && p.item == 1 { G8.pageCorner(&pic, "pcl", at: q.X, tg.a) }
            let allRun = stage != .run && stage != .ask
            for (i, ln) in q.lines.enumerated() {
                let run = p.make || allRun || (s.h("r\(i)") ?? 0) > 0
                var t0 = run ? ln.lo : ln.t0, t1 = run ? ln.hi : ln.t1
                let holding = held && Int(s.h("ln") ?? -1) == i
                if holding, let pull = s.h("pull") { if (s.h("end") ?? 1) == 1 { t1 = max(t1, pull) } else { t0 = min(t0, pull) } }
                var pen = holding ? live : pic
                pen.sketch.morphs = !holding
                G8.seg(&pen, "ln\(i)", ln.at(t0), ln.at(t1))
                G8.arrow(&pen, "ln\(i)h0", ln.at(t0), ln.a + 180); G8.arrow(&pen, "ln\(i)h1", ln.at(t1), ln.a)
                pen.sketch.morphs = false
                if holding { live = pen } else { pic = pen }
                // a hint after a second miss: the arrowhead to pull
                if stage == .run && spot && !run { let e = ln.at(ln.t1); pic.circle("spot\(i)", at: e.x, e.y, radius: 1.6, .chapter, dashed: true) }
            }
            if p.make {
                pic.dot("P", at: q.P.x, q.P.y, radius: 0.4, .ink, over: true)
                pic.word("Pn", "P", at: q.P.x - 1.4, q.P.y + 1.2, G8.say)
                let drawn: (Int, Int)? = done ? q.goal : s.h("dx").map { (Int($0), Int(s.h("dy") ?? 0)) }
                if let v = drawn, v != (0, 0) {
                    let k = hypot(Double(v.0), Double(v.1)), u = Pt(Double(v.0) / k, Double(v.1) / k)
                    let (lo, hi) = Q.clip(Pt(q.P.x - q.l, q.P.y - q.t), u, q.W, q.H), ln = Line(q: q.P, u: u, lo: lo, hi: hi, t0: lo, t1: hi)
                    var pen = done ? pic : live
                    let c: Sketch.Colour = done ? .chapter : .ink
                    G8.seg(&pen, "dr\(v.0)_\(v.1)", ln.at(lo), ln.at(hi), c)
                    G8.arrow(&pen, "dra\(v.0)_\(v.1)", ln.at(lo), ln.a + 180, c); G8.arrow(&pen, "drb\(v.0)_\(v.1)", ln.at(hi), ln.a, c)
                    if done { pic = pen } else { live = pen }
                    if held && !done { live.reads(["parallel", "perpendicular", "crosses"][p.relation(v)]) }
                }
                if stage == .draw {
                    live.dot("hP", at: q.P.x, q.P.y, radius: held ? 0.75 : 0.55, .ink, over: true)
                    if spot {
                        let g = q.goal, k = hypot(Double(g.0), Double(g.1)), u = Pt(Double(g.0) / k, Double(g.1) / k)
                        let (lo, hi) = Q.clip(Pt(q.P.x - q.l, q.P.y - q.t), u, q.W, q.H)
                        G8.seg(&pic, "spot", Pt(q.P.x + u.x * lo, q.P.y + u.y * lo), Pt(q.P.x + u.x * hi, q.P.y + u.y * hi), .chapter, dashed: true)
                    }
                }
            }
            let ran = p.make ? done : allRun
            if ran && p.item == 0 && q.lines.count > 0 {
                let p0 = p.make ? q.X : q.lines[0].q, u = q.lines[0].u, off = p.d1.0 == 0 ? Pt(4, 0) : Pt(0, 4)
                for t in [-14.0, 0, 14] {
                    let c = Pt(p0.x + u.x * t, p0.y + u.y * t)
                    guard c.x >= q.l + 1, c.x <= q.r - 1, c.y >= q.t + 1, c.y <= q.b - 1 else { continue }
                    G8.seg(&pic, "gap\(Int(t))", c, c + off, .ink2, dashed: true)
                }
            }
            if ran && p.item > 0 { pic.dot("X", at: q.X.x, q.X.y, radius: 0.4, .chapter, over: true) }
            if !p.make && allRun {
                let f = stage == .corner || p.item == 0 ? p.ran : p.finding
                if q.rec.beside { G8.aside(&pic, "fd", f, x: q.rec.x, y: 0, w: max(16, q.recWidth)) } else { G8.aside(&pic, "fd", f, x: q.rest.x, y: 2, w: 14) }
            }
            if stage == .corner {
                let at = Pt(s.h("px") ?? q.rest.x, s.h("py") ?? q.rest.y)
                if held { G8.pageCorner(&live, "pcr", at: at, 0) } else { G8.pageCorner(&pic, "pcr", at: at, 0) }
                if spot { pic.circle("spot", at: q.X.x, q.X.y, radius: 1.4, .chapter, dashed: true) }
            }
        }

        // the names to tap, where the name will be written; then the name, in the chapter's colour
        if stage == .name {
            G8.choices(&pic, "c", x: q.rec.x, y: q.rec.y - 1, p.names, bad: s.h("bad").map { Int($0) }, ring: spot ? p.right : nil, column: q.rec.beside)
        }
        if done { M7.row(&pic, "rec", [.w(p.named, .chapter)], x: q.rec.x - 0.5, line: q.rec.y) }
        _ = hint
        // room for everything any step draws (the names under or beside it, the resting page corner)
        let ext = pic.R(0, 0, max(q.r, q.rec.x + q.recWidth), max(q.b, q.rec.y + 1))
        return PaperDrawing(picture: pic.sketch, live: live.sketch, actions: stage == .make ? ["Check"] : [], extent: ext)
    }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let q = Q(s.numbers)
        switch st(s) {
        case .make: return CGPoint(x: q.rec.x, y: q.rec.y - 1)
        case .done: return CGPoint(x: q.rec.x, y: q.rec.y + 2)
        default: return nil
        }
    }
    func messageRows(_ n: Numbers) -> Int { 2 }

    func hands(_ s: PaperState) -> Hands? {
        let q = Q(s.numbers), p = q.p
        func near(_ c: CGPoint, _ a: Pt, _ r: Double) -> Bool { hypot(c.x - a.x, c.y - a.y) <= r }
        switch st(s) {
        case .ends:
            let base = s.hand
            return Hands(tap: { c in
                if let i = [q.S, q.E].firstIndex(where: { near(c, $0, 2.2) }) {
                    var h = base; h["s\(i)"] = 1
                    if (h["s0"] ?? 0) > 0 && (h["s1"] ?? 0) > 0 { return HandMove(hand: h, missHand: h, set: [("e", 1)], check: true) }
                    return HandMove(hand: h)
                }
                if near(c, q.A, 1.8) && q.A != q.S { return HandMove(hand: base, missHand: base, set: [("e", -1)], check: true) }
                if near(c, q.B, 1.8) && q.B != q.E { return HandMove(hand: base, missHand: base, set: [("e", -2)], check: true) }
                if Geo4.segDist(G8.pt(c), q.S, q.E) <= 1 { return HandMove(hand: base, missHand: base, set: [("e", -3)], check: true) }
                return nil
            })
        case .make:
            let base = s.hand
            return Hands(tap: { c in
                guard let i = [q.S, q.E].firstIndex(where: { near(c, $0, 2.2) }) else { return nil }
                var h = base; h["e\(i)"] = (h["e\(i)"] ?? 0) == 1 ? 2 : 1
                return HandMove(hand: h)
            }, actions: ["Check": {
                HandMove(hand: base, missHand: base, set: [("m", 10 * (base["e0"] ?? 0) + (base["e1"] ?? 0))], check: true)
            }])
        case .corner:
            let at = Pt(s.h("px") ?? q.rest.x, s.h("py") ?? q.rest.y), tg = q.target
            return Hands(grab: { c in
                G8.inPC(G8.pt(c), at: at, 0) ? ["grab": 1, "ox": c.x - at.x, "oy": c.y - at.y, "px": at.x, "py": at.y, "fx": at.x, "fy": at.y] : nil
            }, drag: { c, h in
                var h = h; h["px"] = c.x - (h["ox"] ?? 0); h["py"] = c.y - (h["oy"] ?? 0); return h
            }, release: { h in
                let to = Pt(h["px"] ?? at.x, h["py"] ?? at.y)
                if Geo4.dist(to, Pt(h["fx"] ?? at.x, h["fy"] ?? at.y)) < 0.5 { return HandMove(hand: [:]) }
                return HandMove(hand: [:], missHand: [:], set: [("k", Geo4.dist(to, tg.at) <= 2.5 ? 1 : 0)], check: true)
            })
        case .run:
            let base = s.hand
            return Hands(grab: { c in
                for (i, ln) in q.lines.enumerated() where (base["r\(i)"] ?? 0) == 0 {
                    for j in 0...1 where near(c, ln.at(j == 0 ? ln.t0 : ln.t1), 2.2) {
                        var h = base; h["grab"] = 1; h["ln"] = Double(i); h["end"] = Double(j); h["pull"] = j == 0 ? ln.t0 : ln.t1
                        return h
                    }
                }
                return nil
            }, drag: { c, h in
                var h = h
                let ln = q.lines[Int(h["ln"] ?? 0)]
                h["pull"] = min(ln.hi, max(ln.lo, (c.x - ln.q.x) * ln.u.x + (c.y - ln.q.y) * ln.u.y))
                return h
            }, release: { h in
                let i = Int(h["ln"] ?? 0), ln = q.lines[i], pull = h["pull"] ?? 0
                let out = (h["end"] ?? 1) == 1 ? pull >= ln.t1 + 1 : pull <= ln.t0 - 1
                var b = base; b["grab"] = nil
                guard out else { return HandMove(hand: b, missHand: b, set: [("r", 0)], check: true) }
                b["r\(i)"] = 1
                if q.lines.indices.allSatisfy({ (b["r\($0)"] ?? 0) > 0 }) { return HandMove(hand: b, missHand: b, set: [("r", 1)], check: true) }
                return HandMove(hand: b)
            })
        case .name:
            let rects = q.choiceRects
            return Hands(tap: { c in
                guard let i = G8.choice(at: c, rects) else { return nil }
                return HandMove(hand: [:], missHand: ["bad": Double(i)], set: [("c", Double(i))], check: true)
            })
        case .turn:
            let v = s.h("v") ?? 0
            return Hands(grab: { c in
                near(c, Geo4.pol(q.C, q.L2, q.a0 + v), 2.2) ? ["grab": 1, "v": v, "v0": v] : nil
            }, drag: { c, h in
                var r = Geo4.adiff(Geo4.angOf(q.C, G8.pt(c)), q.a0)
                if r < 0 { r = r < -90 ? 180 : 0 }
                var h = h; h["v"] = min(180, max(0, (r / 5).rounded() * 5)); return h
            }, release: { h in
                let v2 = h["v"] ?? 0
                if v2 == 0 || v2 == h["v0"] { return HandMove(hand: ["v": v2]) }
                return HandMove(hand: ["v": v2], missHand: ["v": v2], set: [("a", v2)], check: true)
            })
        case .draw:
            return Hands(grab: { c in near(c, q.P, 2.5) ? ["grab": 1] : nil },
                         drag: { c, h in
                             let g = (Int(c.x.rounded()) - Int(q.P.x), Int(c.y.rounded()) - Int(q.P.y))
                             if g == (0, 0) { return ["grab": 1] }
                             let v = Geo4.redv(g.0, g.1)
                             return ["grab": 1, "dx": Double(v.0), "dy": Double(v.1)]
                         },
                         release: { h in
                             guard let dx = h["dx"], let dy = h["dy"] else { return HandMove(hand: [:]) }
                             return HandMove(hand: ["dx": dx, "dy": dy], missHand: [:], set: [("d", Double(p.relation((Int(dx), Int(dy)))))], check: true)
                         })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let q = Q(s.numbers), p = q.p
        func c(_ a: Pt) -> CGPoint { CGPoint(x: a.x, y: a.y) }
        switch st(s) {
        case .ends: return [.tap(.picture(c(q.S))), .tap(.picture(c(q.E)))]
        case .make:
            let want = [p.item == 0 ? 2 : 1, p.item == 2 ? 1 : 2]
            var moves: [GhostMove] = []
            for (i, e) in [q.S, q.E].enumerated() {
                var now = Int(s.h("e\(i)") ?? 0)
                while now != want[i] { moves.append(.tap(.picture(c(e)))); now = now == 1 ? 2 : 1 }
            }
            return moves + [.tap(.action("Check"))]
        case .corner:
            let at = Pt(s.h("px") ?? q.rest.x, s.h("py") ?? q.rest.y), tg = q.target.at
            // held by its middle (it lies up and right of its corner)
            return [.drag(from: CGPoint(x: at.x + 3, y: at.y - 3), to: CGPoint(x: tg.x + 3, y: tg.y - 3))]
        case .run:
            return q.lines.enumerated().filter { (s.h("r\($0.offset)") ?? 0) == 0 }.map { (_, ln) in
                .drag(from: c(ln.at(ln.t1)), to: c(ln.at(min(ln.hi, ln.t1 + 6))))
            }
        case .name:
            let r = q.choiceRects[p.right]
            return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
        case .turn:
            let v = s.h("v") ?? 0, to = Double([45, 90, 135][p.item])
            return [.drag(from: c(Geo4.pol(q.C, q.L2, q.a0 + v)), to: c(Geo4.pol(q.C, q.L2, q.a0 + to)))]
        case .draw:
            let g = q.goal, k = 8 / hypot(Double(g.0), Double(g.1)), m = max(1, k.rounded())
            return [.drag(from: c(q.P), to: CGPoint(x: q.P.x + Double(g.0) * m, y: q.P.y + Double(g.1) * m))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let q = Q(s.numbers), p = q.p
        switch st(s) {
        case .corner: return HandMove(hand: [:], missHand: [:], set: [("k", 0)], check: true)
        case .name: let i = (p.right + 1) % p.names.count; return HandMove(hand: [:], missHand: ["bad": Double(i)], set: [("c", Double(i))], check: true)
        case .make:
            let h: Numbers = p.item == 0 ? ["e0": 1, "e1": 1] : ["e0": 2, "e1": 2]
            return HandMove(hand: h, missHand: h, set: [("m", 10 * h["e0"]! + h["e1"]!)], check: true)
        case .turn: let v = p.item == 0 ? 120.0 : 45; return HandMove(hand: ["v": v], missHand: ["v": v], set: [("a", v)], check: true)
        case .draw: return HandMove(hand: [:], missHand: [:], set: [("d", 2)], check: true)
        case .ends: return HandMove(hand: [:], missHand: [:], set: [("e", -1)], check: true)
        case .run: return HandMove(hand: [:], missHand: [:], set: [("r", 0)], check: true)
        default: return nil
        }
    }
}
