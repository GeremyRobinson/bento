import SwiftUI

/// Lines of symmetry on the paper, as in the preview (design/prototype/grade4-ch8.html): the shape centred on a grid
/// point, about 28 squares across. Is the dashed line a line of symmetry: drag one half over the line; it turns over it
/// as the finger goes (seen in perspective, rising toward you as it turns), and let go past the line it lands: every
/// corner on a corner (a green dot on each), or corners sticking out (ringed); beside it "2 corners stick out."; then Yes
/// or No, and it unfolds. How many lines: draw a fold line across it (it snaps to lines through the middle) and let go:
/// it folds; a match stays drawn and counted, a miss shows what sticks out; No more; type the count.
///
/// The fold is drawn on the flat paper with the preview's perspective (the paper's own tilt is kept for lessons that
/// rise off it as solids); landing and unfolding glide on the paper's spring.
///
/// The picture's squares: the shape's middle at (16, 16); the names, the count and the record from column 35.
@MainActor
struct SymmetryLesson: PaperLesson {
    typealias Pt = Geo4.Pt
    static let ry = 6.0
    var liveKeys: Set<String> { ["th", "da"] }

    /// Where the shape's middle goes (a grid point, with room round it for every line that can be drawn through it,
    /// each reaching 2 squares past the shape), and the column the names and the record start on.
    struct G {
        let O: Pt, rx: Double, local: [Pt], bottom: Double
        init(_ p: Symmetry4.Parts) {
            local = p.local
            let angles = p.kind == 0 ? [p.la] : Symmetry4.snaps(p.S, turn: p.turn)
            // the shape, and wherever a fold can land it: over the dashed line, or (drawing fold lines) anywhere round
            // its middle, as far out as its farthest corner; and every fold line's ends
            var pts = p.kind == 0 ? local + local.map { Symmetry4.refl($0, p.la) } : local
            if p.kind == 1 { let r = local.map { hypot($0.x, $0.y) }.max() ?? 14; pts += [Pt(r, 0), Pt(-r, 0), Pt(0, r), Pt(0, -r)] }
            for a in angles { let (f, b) = G.reach(local, a); pts += [Geo4.pol(Pt(0, 0), f, a), Geo4.pol(Pt(0, 0), b, a + 180)] }
            let left = -(pts.map(\.x).min() ?? -14), right = pts.map(\.x).max() ?? 14
            let top = -(pts.map(\.y).min() ?? -14), low = pts.map(\.y).max() ?? 14
            O = Pt(left.rounded(.up), top.rounded(.up))
            bottom = O.y + low.rounded(.up)
            rx = ((O.x + right + 3) / 5).rounded(.up) * 5
        }
        /// How far a fold line at angle a runs from the middle each way: to where it leaves the shape, and a square on.
        static func reach(_ pts: [Pt], _ a: Double) -> (Double, Double) {
            let u = Pt(cos(a * .pi / 180), -sin(a * .pi / 180))
            var f = 0.0, b = 0.0
            for (i, p) in pts.enumerated() {
                let q = pts[(i + 1) % pts.count], e = Pt(q.x - p.x, q.y - p.y)
                let den = u.x * e.y - u.y * e.x
                guard abs(den) > 1e-9 else { continue }
                let t = (p.x * e.y - p.y * e.x) / den, sg = (p.x * u.y - p.y * u.x) / den
                guard sg >= -1e-9 && sg <= 1 + 1e-9 else { continue }
                if t > 0 { f = max(f, t) } else { b = max(b, -t) }
            }
            return (f + 1, b + 1)
        }
        func at(_ q: Pt) -> Pt { Pt(q.x + O.x, q.y + O.y) }
        func ends(_ a: Double) -> (Pt, Pt) { let (f, b) = G.reach(local, a); return (Geo4.pol(O, f, a), Geo4.pol(O, b, a + 180)) }
    }
    private func found(_ h: Numbers) -> [Double] { (0..<8).compactMap { h["f\($0)"] } }

    /// A polygon as a fill and an outline, from where it starts (`from`, when it moves in) to where it is.
    /// `over`: a half folded over the rest (it lies on top of the paper under it, its outline too).
    private func shape(_ pen: inout GridPen, _ g: G, _ id: String, _ pts: [Pt], fill: Sketch.Colour, from: [Pt]? = nil, over: Bool = false) {
        let o = pts.map(g.at).map { G8.cg(pen, $0) }, ring = o + (o.first.map { [$0] } ?? [])
        if let f = from?.map(g.at).map({ G8.cg(pen, $0) }) {
            pen.sketch.from[id + "f"] = over ? .plate(f) : .fill(f)
            pen.sketch.from[id + "o"] = over ? .overLine(f + [f[0]], width: Sketch.stroke) : .line(f + [f[0]], width: Sketch.stroke, dashed: false)
        }
        if over { pen.sketch.plate(id + "f", o, fill); pen.sketch.overLine(id + "o", ring, .ink, width: Sketch.stroke) }
        else { pen.sketch.polygon(id + "f", o, fill); pen.sketch.line(id + "o", ring, .ink, width: Sketch.stroke) }
        pen.sketch.from = [:]
    }
    /// Green dots on the corners that land on a corner; rings round the ones that stick out.
    private func landing(_ pen: inout GridPen, _ g: G, _ p: Symmetry4.Parts, _ a: Double, _ side: Double) {
        guard !p.heart else { return }
        let local = p.local
        let land = Symmetry4.half(local, a, side).filter { abs(Symmetry4.side($0, a)) > 1e-6 }.map { Symmetry4.refl($0, a) }
        for (i, q) in land.enumerated() {
            let c = g.at(q)
            if local.contains(where: { Geo4.dist($0, q) < 0.05 }) { pen.dot("ok\(i)", at: c.x, c.y, radius: 0.45, Bars.green, over: true) }
            else {
                let r = 0.9, pts = (0...32).map { k -> CGPoint in let t = Double(k) / 32 * 2 * .pi; return pen.P(c.x + r * cos(t), c.y + r * sin(t)) }
                pen.sketch.overLine("out\(i)", pts, .ink, width: Sketch.stroke)
            }
        }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let p = Symmetry4.Parts(s.numbers), st = G8.stage(s), done = st >= 3, local = p.local, held = s.grabbed
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let g = G(p), rx = g.rx, ry = Self.ry

        if p.kind == 0 {
            let la = p.la, kept = s.run.kept
            if st == 1 && held, let th = s.h("th"), let sd = s.h("sd") {
                shape(&pic, g, "stay\(sd)", Symmetry4.half(local, la, -sd), fill: .tint(0.2))
                shape(&live, g, "move", Symmetry4.half(local, la, sd).map { Symmetry4.folded($0, la, th) }, fill: .tint(0.45), over: true)
            } else if st == 1, let back = s.h("back"), let sd = s.h("sd") {
                // let go short of the line: the half falls back flat
                let h = Symmetry4.half(local, la, sd)
                shape(&pic, g, "stay\(sd)", Symmetry4.half(local, la, -sd), fill: .tint(0.2))
                shape(&pic, g, "back\(Int(back * 100))", h, fill: .tint(0.2), from: h.map { Symmetry4.folded($0, la, back) }, over: true)
            } else if st == 2 {
                let sd = kept["sd"] ?? 1, th = kept["th"] ?? .pi, h = Symmetry4.half(local, la, sd)
                shape(&pic, g, "stay\(sd)", Symmetry4.half(local, la, -sd), fill: .tint(0.2))
                shape(&pic, g, "landed", h.map { Symmetry4.refl($0, la) }, fill: .tint(0.45), from: h.map { Symmetry4.folded($0, la, th) }, over: true)
                landing(&pic, g, p, la, sd)
                G8.aside(&pic, "fd", p.landed(sd), x: rx, y: 2, w: 20)
            } else if done {
                let sd = kept["sd"] ?? 1, h = Symmetry4.half(local, la, sd)
                shape(&pic, g, "whole", local, fill: .tint(0.2))
                shape(&pic, g, "unfold", h, fill: .tint(0.2), from: h.map { Symmetry4.refl($0, la) }, over: true)
            } else {
                shape(&pic, g, "whole", local, fill: .tint(0.2))
            }
            let (a, b) = g.ends(la), solid = done && p.ok
            G8.seg(&pic, "dl\(solid)", a, b, solid ? .chapter : .ink2, dashed: !solid)
            if st == 2 {
                G8.choices(&pic, "yn", x: rx, y: ry - 1, ["Yes", "No"], bad: s.h("bad").map { Int($0) }, ring: s.on("spot") ? (p.ok ? 0 : 1) : nil)
            }
            if done { G8.aside(&pic, "rec", "The dashed line \(p.ok ? "is" : "is not") a line of symmetry.", x: rx, y: ry, w: 24, Record.words.colour(.chapter)) }
        } else {
            let lines = st == 1 ? found(s.hand) : found(s.run.kept)
            if st == 1, let la = s.h("la"), !held {
                // the last fold, landed: its half glides over the line
                let n = Int(s.h("fc") ?? 0), h = Symmetry4.half(local, la, 1)
                shape(&pic, g, "stay\(n)", Symmetry4.half(local, la, -1), fill: .tint(0.2))
                shape(&pic, g, "fold\(n)", h.map { Symmetry4.refl($0, la) }, fill: .tint(0.45), from: h, over: true)
                landing(&pic, g, p, la, 1)
            } else {
                shape(&pic, g, "whole", local, fill: .tint(0.2))
            }
            for a in lines { let (u, v) = g.ends(a); G8.seg(&pic, "fl\(Int((a * 10).rounded()))", u, v, .chapter) }
            if st == 1, held, let da = s.h("da") { let (u, v) = g.ends(da); G8.seg(&live, "dw\(Int((da * 10).rounded()))", u, v, .ink2, dashed: true) }
            if st == 1 && !lines.isEmpty { G8.aside(&pic, "cnt", "\(lines.count) \(lines.count == 1 ? "line" : "lines")", x: rx, y: 2, w: 10) }
            // a hint after a second miss: a fold line not found yet, dashed
            if st == 1 && s.on("spot"), let a = p.trueLines.first(where: { t in !lines.contains { abs(Geo4.adiff(2 * $0, 2 * t)) < 0.01 } }) {
                let (u, v) = g.ends(a); G8.seg(&pic, "spot", u, v, .chapter, dashed: true)
            }
            if st == 2 { M7.row(&rec, "rec", [.box("R", cells: 1), .w("lines of symmetry")], x: 0, line: 2) }
            if done { M7.row(&rec, "rec", [.n(p.n, .chapter), .w(p.n == 1 ? "line of symmetry" : "lines of symmetry", .chapter)], x: 0, line: 2) }
        }
        pic.dot("O", at: g.O.x, g.O.y, radius: 0.3, .ink, over: true)
        let ext = pic.R(0, 0, p.kind == 0 ? rx + 24 : 2 * g.O.x, g.bottom)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes,
                            actions: p.kind == 1 && st == 1 ? ["No more"] : [], extent: ext)
    }

    func recordBeside(_ n: Numbers) -> Double? { Self.ry - 2 }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        let p = Symmetry4.Parts(s.numbers)
        guard p.kind == 0 else { return nil }
        return G8.stage(s) >= 3 ? CGPoint(x: G(p).rx, y: Self.ry + 4) : nil
    }
    func messageRows(_ n: Numbers) -> Int { 1 }

    func hands(_ s: PaperState) -> Hands? {
        let p = Symmetry4.Parts(s.numbers), O = G(p).O, st = G8.stage(s)
        func rel(_ c: CGPoint) -> Pt { Pt(c.x - O.x, c.y - O.y) }
        if p.kind == 0 && st == 1 {
            let la = p.la
            return Hands(grab: { c in
                let q = rel(c), d = Symmetry4.side(q, la)
                guard hypot(q.x, q.y) <= 18, abs(d) >= 1 else { return nil }
                return ["grab": 1, "sd": d > 0 ? 1 : -1, "d0": abs(d), "th": 0]
            }, drag: { c, h in
                var h = h
                let d = (h["sd"] ?? 1) * Symmetry4.side(rel(c), la)
                h["th"] = acos(min(1, max(-1, d / (h["d0"] ?? 1)))); return h
            }, release: { h in
                let th = h["th"] ?? 0, sd = h["sd"] ?? 1
                if th > 0.6 * .pi { return HandMove(hand: [:], missHand: [:], set: [("f", 1)], keep: ["th": th, "sd": sd], check: true) }
                if th < 0.05 { return HandMove(hand: [:]) }
                return HandMove(hand: ["back": th, "sd": sd], missHand: ["back": th, "sd": sd], set: [("f", 0)], check: true)
            })
        }
        if p.kind == 0 && st == 2 {
            return Hands(tap: { c in
                var cx = G(p).rx
                for (i, l) in ["Yes", "No"].enumerated() {
                    let w = Record.width(l) + 2
                    if c.x >= cx - 0.3 && c.x <= cx + w + 0.3 && c.y >= Self.ry - 1.3 && c.y <= Self.ry + 1.3 {
                        return HandMove(hand: [:], missHand: ["bad": Double(i)], set: [("c", Double(i))], check: true)
                    }
                    cx += w + 2
                }
                return nil
            })
        }
        if p.kind == 1 && st == 1 {
            var base = s.hand
            base["grab"] = nil; base["da"] = nil; base["fx"] = nil; base["fy"] = nil
            let lines = found(base), snaps = Symmetry4.snaps(p.S, turn: p.turn), local = p.local
            return Hands(grab: { c in
                guard hypot(c.x - O.x, c.y - O.y) <= 20 else { return nil }
                var h = base; h["grab"] = 1; h["fx"] = c.x; h["fy"] = c.y; h["la"] = nil
                return h
            }, drag: { c, h in
                var h = h
                let f = Pt(h["fx"] ?? c.x, h["fy"] ?? c.y)
                guard Geo4.dist(f, G8.pt(c)) > 2 else { return h }
                let a = Geo4.angOf(f, G8.pt(c)).truncatingRemainder(dividingBy: 180)
                h["da"] = snaps.min { abs(Geo4.adiff(2 * $0, 2 * a)) < abs(Geo4.adiff(2 * $1, 2 * a)) }
                return h
            }, release: { h in
                var b = base
                guard let a = h["da"] else { return HandMove(hand: b) }
                if lines.contains(where: { abs(Geo4.adiff(2 * a, 2 * $0)) < 0.01 }) { return HandMove(hand: b, missHand: b, set: [("n", -2)], check: true) }
                b["la"] = a; b["fc"] = (b["fc"] ?? 0) + 1
                if Symmetry4.isSym(local, a) { b["f\(lines.count)"] = a; return HandMove(hand: b) }
                return HandMove(hand: b, missHand: b, set: [("n", -1)], check: true)
            }, actions: ["No more": {
                var keep: Numbers = [:]
                for (i, a) in lines.enumerated() { keep["f\(i)"] = a }
                return HandMove(hand: base, missHand: base, set: [("n", Double(lines.count))], keep: keep, check: true)
            }])
        }
        return nil
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let p = Symmetry4.Parts(s.numbers), O = G(p).O, st = G8.stage(s)
        if p.kind == 0 && st == 1 {
            let n = Pt(sin(p.la * .pi / 180), cos(p.la * .pi / 180))
            return [.drag(from: CGPoint(x: O.x + 8 * n.x, y: O.y + 8 * n.y), to: CGPoint(x: O.x - 8 * n.x, y: O.y - 8 * n.y))]
        }
        if p.kind == 0 && st == 2 {
            let i = p.ok ? 0 : 1, w0 = Record.width("Yes") + 2, w = Record.width(["Yes", "No"][i]) + 2
            return [.tap(.picture(CGPoint(x: G(p).rx + (i == 0 ? 0 : w0 + 2) + w / 2, y: Self.ry)))]
        }
        if p.kind == 1 && st == 1 {
            let have = found(s.hand)
            let todo = p.trueLines.filter { t in !have.contains { abs(Geo4.adiff(2 * $0, 2 * t)) < 0.01 } }
            return todo.map { a in
                let u = Pt(cos(a * .pi / 180), -sin(a * .pi / 180))
                return .drag(from: CGPoint(x: O.x - 12 * u.x, y: O.y - 12 * u.y), to: CGPoint(x: O.x + 12 * u.x, y: O.y + 12 * u.y))
            } + [.tap(.action("No more"))]
        }
        return []
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        let p = Symmetry4.Parts(s.numbers), st = G8.stage(s)
        if p.kind == 0 && st == 1 { return HandMove(hand: ["back": 1.2, "sd": 1], missHand: ["back": 1.2, "sd": 1], set: [("f", 0)], check: true) }
        if p.kind == 0 && st == 2 { let i = p.ok ? 1 : 0; return HandMove(hand: [:], missHand: ["bad": Double(i)], set: [("c", Double(i))], check: true) }
        if p.kind == 1 && st == 1 {
            let snaps = Symmetry4.snaps(p.S, turn: p.turn)
            guard let a = snaps.first(where: { !Symmetry4.isSym(p.local, $0) }) else { return nil }
            let h: Numbers = ["la": a, "fc": 1]
            return HandMove(hand: h, missHand: h, set: [("n", -1)], check: true)
        }
        return nil
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let p = Symmetry4.Parts(s.numbers)
        return G8.stage(s) == 2 && p.kind == 1 ? ["R": Double(p.shape == 0 ? 2 : p.shape == 1 ? 4 : p.n + 1)] : nil
    }
}
