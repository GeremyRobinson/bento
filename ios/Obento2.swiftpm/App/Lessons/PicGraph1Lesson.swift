import SwiftUI

/// Picture graphs on the paper, as in the preview (design/prototype/grade1-ch5.html, dPicGraph): one picture is one block
/// (its drawing 3 squares across in the middle), three rows of up to 9 from one start line, a square apart, each row's name
/// in front, the title over it; the strong lines are its columns, so a longer row is plainly longer. The first three start
/// with the pictures in a pile under the graph: tap one and it goes to the next place in its row, the row's count at its
/// end. Then the web's ask: read a row (tap or drag along to count, write, then Longer or Shorter), the row with the most
/// or fewest (tap it), how many more (tap the pictures past the shorter row's end, write), together (slide one row onto the
/// end of the other, the count running on, write). Together past 11: a picture is 3 squares, said on its own row.
///
/// Kept: "s<i>" the pile's places tapped, in order; "k<i>" the pictures counted; "e<i>" those past the end; "wr" a row tapped
/// and wrong; "jm" the row slid, "jdx", "jdy" where it was let go; "lw" Longer or Shorter tapped and wrong; "chk".
/// Hand: "grab", "r", "gx", "gy", "dx", "dy", "bad"; counting along: "lx", "ly", "h<i>".
@MainActor
struct PicGraph1Lesson: PaperLesson {
    var liveKeys: Set<String> { ["dx", "dy", "lx", "ly", "gx", "gy"] }
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let gx = 10.0
    static let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink)

    struct G {
        let P: PicGraph1.Parts
        var C: Double { P.small ? 3 : 5 }
        var y0: Double { P.small ? 4 : 2 }
        func rowY(_ r: Int) -> Double { y0 + (C + 1) * Double(r) }
        var bot: Double { rowY(2) + C }
        var rec: Double { bot + 4 }
        var padY: Double { rec + 3 }
        func cell(_ r: Int, _ j: Int) -> CGPoint { CGPoint(x: PicGraph1Lesson.gx + C * Double(j) + C / 2, y: rowY(r) + C / 2) }
        var sc: Double { P.small ? 0.85 : 1 }
        /// Picture g's row (the pictures numbered row by row).
        func row(_ g: Int) -> Int { g < P.c[0] ? 0 : g < P.c[0] + P.c[1] ? 1 : 2 }
        var perm: [Int] { Len1.pile(P.total, seed: P.seed) }
        func pileAt(_ k: Int) -> CGPoint { CGPoint(x: 3.5 + 4 * Double(k % 12), y: bot + 4 + 4 * Double(k / 12)) }
        var pileBot: Double { bot + 2 + 4 * Double((P.total + 11) / 12) }
        /// The row a point is on (from the names, or from the start line).
        func rowAt(_ q: CGPoint, from x: Double = PicGraph1Lesson.gx - 10) -> Int? {
            (0..<3).first { q.y >= rowY($0) - 0.5 && q.y <= rowY($0) + C + 0.5 && q.x >= x && q.x <= PicGraph1Lesson.gx + C * 18 + 3 }
        }
        func slot(_ q: CGPoint) -> Int { Int(((q.x - PicGraph1Lesson.gx) / C).rounded(.down)) }
    }

    /// Where each picture is: its row and place, or its pile place.
    private func places(_ s: PaperState, _ g: G) -> [(row: Int, j: Int?, pile: Int)] {
        let P = g.P, perm = g.perm, sorted = at(s) == 0 ? KA.list(s, "s") : Array(0..<P.total)
        var count = [0, 0, 0], out = [(row: Int, j: Int?, pile: Int)](repeating: (0, nil, 0), count: P.total)
        for k in 0..<P.total { let id = perm[k]; out[id] = (g.row(id), nil, k) }
        if !P.sort || at(s) > 0 {
            var start = 0
            for r in 0..<3 { for j in 0..<P.c[r] { out[start + j].j = j }; start += P.c[r] }
            return out
        }
        for k in sorted { let id = perm[k], r = g.row(id); out[id].j = count[r]; count[r] += 1 }
        return out
    }

    func blocksAt(_ s: PaperState) -> CGPoint? {
        let P = PicGraph1.Parts(s.numbers), g = G(P: P)
        switch at(s) {
        case 2: return DigitPad.checkAt(x: 0, y: g.padY)
        case 3: return CGPoint(x: 0, y: g.padY + 5)
        case 4: return CGPoint(x: 0, y: P.ask == 0 ? g.rec + 5 : P.ask == 1 ? g.rec + 2 : g.rec + 3)
        default: return nil
        }
    }

    private func recToks(_ s: PaperState, _ P: PicGraph1.Parts, _ v: Int?, _ wrong: Bool, done: Bool) -> [A1.Tok] {
        let last: A1.Tok = done ? .n(P.answer, .chapter) : .box(v, wrong: wrong)
        switch P.ask {
        case 2: return [.n(P.c[P.x]), .op("−"), .n(P.c[P.y]), .op("="), last]
        default:
            let m = Int(s.run.kept["jm"] ?? Double(P.y)), j = m == P.x ? P.y : P.x
            return [.n(P.c[j]), .op("+"), .n(P.c[m]), .op("="), last]
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = PicGraph1.Parts(s.numbers), g = G(P: P), st = at(s), th = P.th, C = g.C, gx = Self.gx
        var pic = GridPen(), live = GridPen(stableIds: true)
        let k = s.run.kept, pl = places(s, g)
        // the title over the graph, and (Together, small) what a picture is here
        let scale = "Here one picture is 3 squares."
        let tw = max(C * Double(P.c.max() ?? 1), L5.smallWidth(th.title) + 2, P.small ? L5.smallWidth(scale) + 2 : 0)
        pic.word("title", th.title, at: gx + tw / 2, 0.5, Self.small)
        if P.small { pic.word("scale", scale, at: gx + tw / 2, 2.5, Self.small) }
        pic.line("axis", [(gx, g.rowY(0) - 0.5), (gx, g.bot + 0.5)])
        let wrongRow = st == 1 && P.ask == 1 ? k["wr"].map { Int($0) } : nil
        let picked = st >= 4 && P.ask == 1 ? P.rightRow : nil
        for r in 0..<3 {
            let c: Sketch.Colour = wrongRow == r ? KK.red : picked == r ? .chapter : .ink
            pic.word("nm\(r)\(c == .ink ? "" : "c")", th.names[r], at: gx - 1, g.rowY(r) + C / 2, Self.small.colour(c), anchor: UnitPoint(x: 1, y: 0.5))
        }
        let held = st == 1 && s.grabbed
        // counting along (held): the pictures counted so far
        func heldList(_ h: Numbers) -> [Int] { var out: [Int] = []; while let j = h["h\(out.count)"] { out.append(Int(j)) }; return out }
        let counted = P.ask == 0 ? (st == 1 ? (held && s.h("lx") != nil ? heldList(s.hand) : KA.list(s, "k")) : st >= 2 ? Array(0..<P.c[P.x]) : []) : []
        let extra = P.ask == 2 ? (st == 1 ? KA.list(s, "e") : st >= 2 ? Array(P.c[P.y]..<P.c[P.x]) : []) : []
        let joined = P.ask == 3 && st >= 2, jm = Int(k["jm"] ?? Double(P.y)), js = jm == P.x ? P.y : P.x
        let slid = P.ask == 3 && held && s.h("bad") != 1 ? Int(s.h("r") ?? -1) : -1
        let dx = s.h("dx") ?? 0, dy = s.h("dy") ?? 0
        let lastSorted = st == 0 ? KA.list(s, "s").last : nil
        var start = 0
        for r in 0..<3 {
            for j0 in 0..<P.c[r] {
                let id = start + j0, p = pl[id], ic = th.icons[r]
                guard let j = p.j else {
                    let q = g.pileAt(p.pile); L5.icon(&pic, "p\(id)", ic, q.x, q.y); continue
                }
                if r == slid { let c = g.cell(r, j); L5.icon(&live, "p\(id)", ic, c.x + dx, c.y + dy, sc: g.sc); continue }
                let lit = (r == P.x && counted.contains(j)) || (r == P.x && extra.contains(j)) || picked == r
                var c = g.cell(r, j), was: CGPoint? = nil
                if joined && r == jm { c = g.cell(js, P.c[js] + j); was = CGPoint(x: g.cell(r, j).x + (k["jdx"] ?? 0), y: g.cell(r, j).y + (k["jdy"] ?? 0)) }
                else if st == 1 && P.ask == 3 && k["jdx"] != nil && Int(k["jr"] ?? -1) == r { was = CGPoint(x: c.x + (k["jdx"] ?? 0), y: c.y + (k["jdy"] ?? 0)) }
                if lastSorted == p.pile { was = g.pileAt(p.pile) }
                let w = was, cc = c, sc = g.sc
                L5.seeded(&pic, was: w.map { wp in { pen in L5.icon(&pen, "p\(id)", ic, wp.x, wp.y, sc: sc, lit: lit) } }) { pen in L5.icon(&pen, "p\(id)", ic, cc.x, cc.y, sc: sc, lit: lit) }
            }
            start += P.c[r]
        }
        // readouts at the rows' ends: the sort's counts; the count; how many more; the count running on
        if st == 0 {
            for r in 0..<3 { let n = pl.filter { $0.row == r && $0.j != nil }.count; if n > 0 { A1.note(&pic, "fc\(r)", "\(n)", x: gx + C * Double(n) + 1, y: g.rowY(r) + C / 2) } }
        }
        if !counted.isEmpty {
            let ro = Len1.run(Array(1...counted.count))
            A1.note(&pic, "run", ro, x: gx + C * Double(P.c[P.x]) + 1, y: g.rowY(P.x) + C / 2)
            if held { live.reads(ro) }
        }
        if !extra.isEmpty { A1.note(&pic, "ex", "\(extra.count) more", x: gx + C * Double(P.c[P.x]) + 1, y: g.rowY(P.x) + C / 2) }
        if joined { A1.note(&pic, "jn", Len1.run(Array((P.c[js] + 1)...(P.c[js] + P.c[jm]))), x: gx + C * Double(P.c[P.x] + P.c[P.y]) + 1, y: g.rowY(js) + C / 2) }
        if slid >= 0 { live.reads(Len1.pl(P.c[slid], "picture", "pictures")) }
        if st == 1 && P.ask == 2 {
            pic.line("guide", [(gx + C * Double(P.c[P.y]), min(g.rowY(P.x), g.rowY(P.y)) - 0.5), (gx + C * Double(P.c[P.y]), max(g.rowY(P.x), g.rowY(P.y)) + C + 0.5)], .ink3, dashed: true)
        }
        let lo = Double(P.c.min() ?? 1), hi = Double(P.c.max() ?? 1)
        switch st {
        case 1:
            switch P.ask {
            case 0:
                if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: gx, y: g.rowY(P.x), w: C * Double(P.c[P.x]), h: C) }
                if s.on("spot"), let j = (0..<P.c[P.x]).first(where: { !counted.contains($0) }) { let c = g.cell(P.x, j); KK.hint(&pic, "spot", c.x, c.y, radius: C / 2 + 0.3) }
            case 1:
                if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: gx + C * lo - 1, y: g.rowY(0), w: C * (hi - lo) + 2, h: g.bot - g.rowY(0)) }
                if s.on("spot") { KK.hintBox(&pic, "spot", x: gx - 1, y: g.rowY(P.rightRow), w: C * Double(P.c[P.rightRow]) + 1, h: C) }
            case 2:
                if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: gx + C * Double(P.c[P.y]), y: g.rowY(P.x), w: C * Double(P.c[P.x] - P.c[P.y]), h: C) }
                if s.on("spot"), let j = (P.c[P.y]..<P.c[P.x]).first(where: { !extra.contains($0) }) { let c = g.cell(P.x, j); KK.hint(&pic, "spot", c.x, c.y, radius: C / 2 + 0.3) }
            default:
                if s.on("ring") && !s.on("spot") { for r in [P.x, P.y] { KK.hintBox(&pic, "hr\(r)", x: gx, y: g.rowY(r), w: C * Double(P.c[r]), h: C) } }
                if s.on("spot") { pic.sketch.box("spot", pic.R(gx + C * Double(P.c[P.x]), g.rowY(P.x), C * Double(P.c[P.y]), C), .chapter, width: Sketch.stroke, dashed: true) }
            }
        case 2:
            let (v, wrong) = DigitPad.typed(s, "x", want: P.answer)
            if P.ask == 0 { KK.line(&pic, "rec", [.w("\(P.X):")], value: v, wrong: wrong, x: 0, line: g.rec) }
            else { A1.record(&pic, "rec", recToks(s, P, v, wrong, done: false), x: 0, line: g.rec) }
            DigitPad.draw(&pic, "pad", x: 0, y: g.padY)
            if s.on("ring") && !s.on("spot") { KK.hintBox(&pic, "hr", x: gx, y: g.rowY(P.x), w: C * Double(P.ask == 3 ? P.c[P.x] + P.c[P.y] : P.c[P.x]), h: C) }
            if s.on("spot") { A1.note(&pic, "spot", "\(P.answer)", x: DigitPad.width + 13.5, y: g.padY + 2) }
        default:
            if st >= 3 {
                if P.ask == 0 { M7.row(&pic, "rec", [.w("\(P.X):"), .n(P.c[P.x], .chapter)], x: 0, line: g.rec) }
                else if P.ask != 1 { A1.record(&pic, "rec", recToks(s, P, nil, false, done: true), x: 0, line: g.rec) }
            }
            if st == 3 {
                let rs = [CGRect(x: 0, y: g.padY, width: 10, height: 4), CGRect(x: 11, y: g.padY, width: 10, height: 4)]
                KS.blocks(&pic, "lr", ["Longer", "Shorter"], rs, wrong: k["lw"].map { Int($0) }.flatMap { $0 >= 0 ? $0 : nil }, spot: s.on("spot") ? (P.longer ? 0 : 1) : nil)
                if s.on("ring") && !s.on("spot") {
                    let a = Double(min(P.c[P.x], P.c[P.y])), b = Double(max(P.c[P.x], P.c[P.y]))
                    KK.hintBox(&pic, "hr", x: gx + C * a - 1, y: min(g.rowY(P.x), g.rowY(P.y)), w: C * (b - a) + 2, h: abs(g.rowY(P.x) - g.rowY(P.y)) + C)
                }
            }
            if st == 4, let r2 = P.rec2 { pic.word("r2", r2, at: 0, P.ask == 0 ? g.rec + 3 : g.rec, KK.words, anchor: UnitPoint(x: 0, y: 0.5)) }
        }
        var right = gx + C * 9 + 1 + L5.smallWidth("1, 2 … 9")
        if P.ask == 3 {
            let a = min(P.c[P.x], P.c[P.y]), n = P.c[P.x] + P.c[P.y]
            right = max(right, gx + C * Double(n) + 1 + L5.smallWidth(Len1.run(Array((a + 1)...n))))
        }
        if st == 0 { right = max(right, 3.5 + 4 * 11 + 2) }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, actions: st == 2 ? ["Check"] : [], extent: pic.R(0, -0.5, right, (st == 0 ? g.pileBot : g.bot) + 0.5))
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = PicGraph1.Parts(s.numbers), g = G(P: P), st = at(s), C = g.C
        switch st {
        case 0:
            let pl = places(s, g), sorted = KA.list(s, "s")
            return Hands(tap: { q in
                guard let k = (0..<P.total).first(where: { k in let c = g.pileAt(k); return !sorted.contains(k) && abs(q.x - c.x) <= 2 && abs(q.y - c.y) <= 2 }) else { return nil }
                _ = pl
                let all = sorted.count + 1 == P.total
                return HandMove(hand: nil, missHand: nil, set: all ? [("p", Double(P.total))] : [], keep: ["s\(sorted.count)": Double(k)], check: all)
            })
        case 1:
            switch P.ask {
            case 0:
                let kept = KA.list(s, "k"), n = P.c[P.x]
                func one(_ q: CGPoint) -> Int? { guard g.rowAt(q, from: Self.gx) == P.x else { return nil }; let j = g.slot(q); return (0..<n).contains(j) ? j : nil }
                func done(_ l: [Int]) -> HandMove {
                    var keep: Numbers = [:]
                    for (i, j) in l.enumerated() { keep["k\(i)"] = Double(j) }
                    return HandMove(hand: [:], missHand: [:], set: l.count == n ? [("k", Double(n))] : [], keep: keep, check: l.count == n)
                }
                func list(_ h: Numbers) -> [Int] { var out: [Int] = []; while let j = h["h\(out.count)"] { out.append(Int(j)) }; return out }
                return Hands(
                    tap: { q in
                        guard let r = g.rowAt(q) else { return nil }
                        if r != P.x { return HandMove(hand: nil, missHand: nil, set: [("k", Double(10 + r))], check: true) }
                        guard let j = one(q) else { return nil }
                        return kept.contains(j) ? HandMove(hand: nil) : done(kept + [j])
                    },
                    grab: { q in
                        guard g.rowAt(q, from: Self.gx) == P.x else { return nil }
                        var h: Numbers = ["grab": 1, "lx": q.x, "ly": q.y], l = kept
                        if let j = one(q), !l.contains(j) { l.append(j) }
                        for (i, j) in l.enumerated() { h["h\(i)"] = Double(j) }
                        return h
                    },
                    drag: { q, held in
                        var h = held, l = list(held)
                        for p in N1.walk(CGPoint(x: held["lx"] ?? q.x, y: held["ly"] ?? q.y), q) { if let j = one(p), !l.contains(j) { l.append(j) } }
                        for (i, j) in l.enumerated() { h["h\(i)"] = Double(j) }
                        h["lx"] = (q.x * 2).rounded() / 2; h["ly"] = (q.y * 2).rounded() / 2
                        return h
                    },
                    release: { h in done(list(h)) })
            case 1:
                return Hands(tap: { q in
                    guard let r = g.rowAt(q) else { return nil }
                    return HandMove(hand: nil, missHand: nil, set: [("c", Double(r))], keep: ["wr": r == P.rightRow ? -1 : Double(r)], check: true)
                })
            case 2:
                let extra = KA.list(s, "e"), d = P.c[P.x] - P.c[P.y]
                return Hands(tap: { q in
                    guard let r = g.rowAt(q) else { return nil }
                    if r != P.x { return HandMove(hand: nil, missHand: nil, set: [("m", Double(10 + r))], check: true) }
                    let j = g.slot(q)
                    if j < P.c[P.y] { return HandMove(hand: nil, missHand: nil, set: [("m", -1)], check: true) }
                    guard j < P.c[P.x], !extra.contains(j) else { return HandMove(hand: nil) }
                    let all = extra.count + 1 == d
                    return HandMove(hand: nil, missHand: nil, set: all ? [("m", Double(d))] : [], keep: ["e\(extra.count)": Double(j)], check: all)
                })
            default:
                return Hands(
                    grab: { q in
                        guard let r = g.rowAt(q, from: Self.gx), q.x <= Self.gx + C * Double(P.c[r]) + 0.5 else { return nil }
                        return ["grab": 1, "r": Double(r), "bad": r == P.x || r == P.y ? 0 : 1, "gx": q.x, "gy": q.y, "dx": 0, "dy": 0]
                    },
                    drag: { q, h in
                        var h = h
                        h["dx"] = (q.x - (h["gx"] ?? q.x)).rounded(); h["dy"] = (q.y - (h["gy"] ?? q.y)).rounded()
                        return h
                    },
                    release: { h in
                        if h["bad"] == 1 { return HandMove(hand: [:], missHand: [:], set: [("j", -1)], check: true) }
                        let m = Int(h["r"] ?? 0), sr = m == P.x ? P.y : P.x, dx = h["dx"] ?? 0, dy = h["dy"] ?? 0
                        let f = g.cell(m, 0), fx = f.x + dx, fy = f.y + dy, t = g.cell(sr, P.c[sr])
                        let keep: Numbers = ["jdx": dx, "jdy": dy, "jr": Double(m)]
                        if abs(fy - t.y) <= C / 2 + 1.5 && fx >= t.x - C * 1.5 && fx <= t.x + C * 3 {
                            var kp = keep; kp["jm"] = Double(m)
                            return HandMove(hand: [:], missHand: [:], set: [("j", 1)], keep: kp, check: true)
                        }
                        guard hypot(dx, dy) > 0.5 else { return HandMove(hand: [:]) }
                        return HandMove(hand: [:], missHand: [:], set: [("j", -2)], keep: keep, check: true)
                    })
            }
        case 2: return DigitPad.hands(s, "x", want: P.answer, x: 0, y: g.padY)
        case 3:
            let rs = [CGRect(x: 0, y: g.padY, width: 10, height: 4), CGRect(x: 11, y: g.padY, width: 10, height: 4)]
            return Hands(tap: { q in
                guard let i = rs.firstIndex(where: { $0.contains(q) }) else { return nil }
                let right = i == (P.longer ? 0 : 1)
                return HandMove(hand: nil, missHand: nil, set: [("c", Double(i))], keep: ["lw": right ? -1 : Double(i)], check: true)
            })
        default: return nil
        }
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = PicGraph1.Parts(s.numbers), g = G(P: P)
        switch at(s) {
        case 0:
            let sorted = KA.list(s, "s")
            return (0..<P.total).filter { !sorted.contains($0) }.map { .tap(.picture(g.pileAt($0))) }
        case 1:
            switch P.ask {
            case 0:
                let kept = KA.list(s, "k"), pts = (0..<P.c[P.x]).filter { !kept.contains($0) }.map { g.cell(P.x, $0) }
                return pts.count == 1 ? [.tap(.picture(pts[0]))] : [.path(pts)]
            case 1: return [.tap(.picture(g.cell(P.rightRow, 0)))]
            case 2:
                let extra = KA.list(s, "e")
                return (P.c[P.y]..<P.c[P.x]).filter { !extra.contains($0) }.map { .tap(.picture(g.cell(P.x, $0))) }
            default: return [.drag(from: g.cell(P.y, 0), to: g.cell(P.x, P.c[P.x]))]
            }
        case 2: return DigitPad.demo(P.answer, x: 0, y: g.padY)
        case 3: return [.tap(.picture(CGPoint(x: P.longer ? 5 : 16, y: g.padY + 2)))]
        default: return []
        }
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = PicGraph1.Parts(s.numbers)
        switch at(s) {
        case 1:
            switch P.ask {
            case 0: return HandMove(hand: nil, missHand: nil, set: [("k", Double(10 + P.y))], check: true)
            case 1: return HandMove(hand: nil, missHand: nil, set: [("c", Double(P.otherEnd))], keep: ["wr": Double(P.otherEnd)], check: true)
            case 2: return HandMove(hand: nil, missHand: nil, set: [("m", -1)], check: true)
            default: return HandMove(hand: [:], missHand: [:], set: [("j", -2)], check: true)
            }
        case 2:
            let slip = P.slips.first?.0 ?? P.answer + 1
            return HandMove(hand: nil, missHand: nil, set: [("x", Double(slip))], keep: ["chk": Double(slip)], check: true)
        case 3:
            let i = P.longer ? 1 : 0
            return HandMove(hand: nil, missHand: nil, set: [("c", Double(i))], keep: ["lw": Double(i)], check: true)
        default: return nil
        }
    }
}
