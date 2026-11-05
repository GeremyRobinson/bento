import SwiftUI

/// Area of L-shapes on the paper, as in the preview (design/prototype/grade3-ch4.html, dLShape), one square of the grid a
/// square unit: the L (a W × H rectangle with a w × h corner missing), its six sides named (from problem 7 one has an empty
/// box). Two rulers: one on a stem over the top (it cuts down), one off the right side (it cuts across); dragged, each
/// snaps between squares, a dashed cut runs across and the readout names the two pieces ("4 × 3 | 5 × 6", or "a rectangle
/// | an L"). Let go from the inside corner: the cut turns solid and the second part glides a square away; each part is
/// written (`4 × 3 = [12]`) and tiles itself; they glide back and `12 + 30 = [42]`. The record then reads
/// `4 × 3 + 5 × 6`, `= 12 + 30 = 42`.
///
/// Hand: "grab", "ax" the ruler held (1 down, 2 across), "kd", "ka" where each ruler is. Kept: "ax" the cut made.
@MainActor
struct LShape3Lesson: PaperLesson {
    typealias Pt = Geo4.Pt
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    static let X0 = 5.0, Y0 = 4.0
    func messageRows(_ n: Numbers) -> Int { 2 }
    private static func down(_ s: PaperState) -> Bool { (s.run.kept["ax"] ?? 1) != 2 }
    private static func rulers(_ P: LShape3.Parts) -> (d: T3.Ruler, a: T3.Ruler) {
        (T3.Ruler(down: true, x: X0, y: Y0, c: 1, n: P.W, span: P.H), T3.Ruler(down: false, x: X0, y: Y0, c: 1, n: P.H, span: P.W))
    }
    func say(_ s: PaperState) -> String? {
        let st = at(s)
        return st >= 1 && st <= 3 ? LShape3.Parts(s.numbers).say(st, down: Self.down(s)) : nil
    }

    /// A ruler drawn under its own ids: its stem, its handle and, away from its rest, the dashed cut.
    private static func ruler(_ pen: inout GridPen, _ id: String, _ R: T3.Ruler, _ k: Int, held: Bool, rest: Int) {
        let h = R.at(k), L = Double(R.span)
        if R.down { pen.line(id + "s", [(h.x, R.y), (h.x, h.y)], .chapter) } else { pen.line(id + "s", [(R.x + L, h.y), (h.x, h.y)], .chapter) }
        pen.dot(id + "h", at: h.x, h.y, radius: held ? 0.7 : 0.55)
        guard k != rest, k > 0, k < R.n else { return }
        if R.down { pen.line(id + "c", [(h.x, R.y - 0.6), (h.x, R.y + L + 0.6)], .ink2, dashed: true) }
        else { pen.line(id + "c", [(R.x - 0.6, h.y), (R.x + L + 0.6, h.y)], .ink2, dashed: true) }
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = LShape3.Parts(s.numbers), st = at(s), X0 = Self.X0, Y0 = Self.Y0, W = Double(P.W), H = Double(P.H)
        var pic = GridPen(), live = GridPen(stableIds: true), rec = GridPen()
        let ring = s.on("ring") || s.on("spot"), spot = s.on("spot"), ch = Sketch.Colour.chapter
        let ext = pic.R(0, Y0 - 4, X0 + W + 5, H + 6)
        if st == 0 {
            let pts = P.outline.map { Pt(X0 + Double($0.0), Y0 + Double($0.1)) }
            G8.path(&pic, "L", pts, .ink, closed: true)
            // each side named, outside the L (the one without a name: an empty box)
            func inL(_ x: Double, _ y: Double) -> Bool {
                x > 0 && x < W && y > 0 && y < H && !(x > Double(P.nx.0) && x < Double(P.nx.1) && y > Double(P.ny.0) && y < Double(P.ny.1))
            }
            for i in 0..<6 {
                let a = pts[i], b = pts[(i + 1) % 6], mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2, horiz = a.y == b.y
                let bx = mx - X0, by = my - Y0
                let side: GridPen.Side = horiz ? (inL(bx, by + 0.1) ? .above : .below) : (inL(bx + 0.1, by) ? .left : .right)
                if (P.hide == 1 && i == 0) || (P.hide == 2 && i == 3) {
                    let cx = horiz ? mx : side == .left ? mx - 2.5 : mx + 2.5, cy = horiz ? (side == .above ? my - 1.5 : my + 1.5) : my
                    M3.nameBox(&pic, "nb\(i)", cx: cx, cy: cy); continue
                }
                // the notch's two sides: each label slid away from the inside corner, so a small notch's two don't meet
                var along = horiz ? mx : my
                if i == 1 { along += (pts[1].y - pts[2].y) * 0.2 }
                if i == 2 { along += (pts[3].x - pts[2].x) * 0.25 }
                pic.label("s\(i)", "\(P.lens[i])", S3P.small, side, edge: horiz ? my : mx, along: along)
            }
            let (Rd, Ra) = Self.rulers(P), kd = Int((s.h("kd") ?? Double(P.restDown)).rounded()), ka = Int((s.h("ka") ?? Double(P.restAcross)).rounded())
            let ax = Int((s.h("ax") ?? 0).rounded())
            Self.ruler(&live, "rd", Rd, kd, held: s.grabbed && ax == 1, rest: P.restDown)
            Self.ruler(&live, "ra", Ra, ka, held: s.grabbed && ax == 2, rest: P.restAcross)
            if s.grabbed && ax != 0 {
                let dn = ax == 1, k = dn ? kd : ka, rest = dn ? P.restDown : P.restAcross, want = dn ? P.X : P.Y
                if k != rest {
                    if k == want { live.reads(P.parts(down: dn).map { "\($0.rows) × \($0.cols)" }.joined(separator: " | ")) }
                    else { live.reads([k <= want, k >= want].map { $0 ? "a rectangle" : "an L" }.joined(separator: " | ")) }
                }
            }
            // a miss rings the inside corner; a second dashes the cut from it
            if ring { KK.hintBox(&pic, "hr", x: X0 + Double(P.X) - 1, y: Y0 + Double(P.Y) - 1, w: 2, h: 2) }
            if spot { pic.line("sp", [(X0 + Double(P.X), Y0 - 0.5), (X0 + Double(P.X), Y0 + H + 0.5)], ch, dashed: true) }
            return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
        }
        // the two parts, a square apart while they're written, then back together
        let dn = Self.down(s), parts = P.parts(down: dn), apart = st == 1 || st == 2
        let compX = P.fx ? (P.w, P.W) : (0, P.W - P.w), compY = P.fy ? (0, P.H - P.h) : (P.h, P.H)
        var boxes: [CGRect] = []
        for (n, p) in parts.enumerated() {
            let ox = n == 1 && apart && dn ? 1.0 : 0, oy = n == 1 && apart && !dn ? 1.0 : 0
            let px = X0 + Double(p.x0) + ox, py = Y0 + Double(p.y0) + oy, pw = Double(p.cols), ph = Double(p.rows)
            boxes.append(CGRect(x: px, y: py, width: pw, height: ph))
            if st > n + 1 { pic.fill("pt\(n)", col: px, row: py, w: pw, h: ph, S3P.tint) }
            S3P.tiles(&pic, "p\(n)", x: px, y: py, rows: p.rows, cols: p.cols)
            let wFound = P.hide == 1 && p.x0 == compX.0 && p.x1 == compX.1, hFound = P.hide == 2 && p.y0 == compY.0 && p.y1 == compY.1
            let below = !dn && n == 1, right = dn && n == 1
            let wl = wFound ? P.found ?? "" : "\(p.cols)", hl = hFound ? P.found ?? "" : "\(p.rows)"
            pic.label("pw\(n)", wl, wFound ? S3P.lit : S3P.small, below ? .below : .above, edge: below ? py + ph : py, along: px + pw / 2)
            pic.label("ph\(n)", hl, hFound ? S3P.lit : S3P.small, right ? .right : .left, edge: right ? px + pw : px, along: py + ph / 2)
        }
        if (st == 1 || st == 2) && ring { let b = boxes[st - 1]; KK.hintBox(&pic, "hp", x: b.minX, y: b.minY, w: b.width, h: b.height) }
        if (st == 1 || st == 2) && spot { let b = boxes[st - 1]; S3P.count(&pic, "sp", "\(parts[st - 1].area)", x: b.maxX, y: b.maxY - 0.5) }
        if st == 3 && ring { KK.hintBox(&pic, "hs", x: X0, y: Y0, w: W, h: H) }

        // the record
        let a = parts[0], b = parts[1]
        if st == 4 {
            M7.row(&rec, "f0", [.n(a.rows), .op("×"), .n(a.cols), .op("+"), .n(b.rows), .op("×"), .n(b.cols)], x: 0, line: 1)
            M7.row(&rec, "f1", [.op("="), .n(a.area), .op("+"), .n(b.area), .op("="), .n(P.tot, ch)], x: 0, line: 4)
        } else {
            M7.row(&rec, "l0", [.n(a.rows), .op("×"), .n(a.cols), .op("="), M3.box("a", a.area, cells: 2, right: st >= 2)], x: 0, line: 1)
            if st >= 2 { M7.row(&rec, "l1", [.n(b.rows), .op("×"), .n(b.cols), .op("="), M3.box("b", b.area, cells: 2, right: st >= 3)], x: 0, line: 4) }
            if st == 3 { M7.row(&rec, "l2", [.n(a.area), .op("+"), .n(b.area), .op("="), M3.box("s", P.tot, cells: 2, right: false)], x: 0, line: 7) }
        }
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: ext)
    }

    func hands(_ s: PaperState) -> Hands? {
        guard at(s) == 0 else { return nil }
        let P = LShape3.Parts(s.numbers), (Rd, Ra) = Self.rulers(P)
        let kd = Int((s.h("kd") ?? Double(P.restDown)).rounded()), ka = Int((s.h("ka") ?? Double(P.restAcross)).rounded())
        let rest: Numbers = ["kd": Double(P.restDown), "ka": Double(P.restAcross)]
        return Hands(
            grab: { q in
                if Rd.holds(q, kd) { return ["grab": 1, "ax": 1, "kd": Double(kd), "ka": Double(ka)] }
                if Ra.holds(q, ka) { return ["grab": 1, "ax": 2, "kd": Double(kd), "ka": Double(ka)] }
                return nil
            },
            drag: { q, h in
                var h = h
                if (h["ax"] ?? 1) == 1 { h["kd"] = Double(Rd.snap(q)) } else { h["ka"] = Double(Ra.snap(q)) }
                return h
            },
            release: { h in
                let dn = (h["ax"] ?? 1) == 1, k = Int((h[dn ? "kd" : "ka"] ?? 0).rounded())
                guard k != (dn ? P.restDown : P.restAcross) else { return HandMove(hand: rest) }
                return HandMove(hand: rest, missHand: rest, set: [("k", Double((dn ? 100 : 200) + k))], keep: ["ax": dn ? 1 : 2], check: true)
            })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        guard at(s) == 0 else { return [] }
        let P = LShape3.Parts(s.numbers), (Rd, _) = Self.rulers(P)
        return [.drag(from: Rd.at(P.restDown), to: Rd.at(P.X))]
    }

    func wrongMove(_ s: PaperState) -> HandMove? {
        guard at(s) == 0 else { return nil }
        let P = LShape3.Parts(s.numbers), k = P.X == 1 ? 2 : P.X - 1
        let rest: Numbers = ["kd": Double(P.restDown), "ka": Double(P.restAcross)]
        return HandMove(hand: rest, missHand: rest, set: [("k", Double(100 + k))], keep: ["ax": 1], check: true)
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = LShape3.Parts(s.numbers), p = P.parts(down: Self.down(s))
        switch at(s) { case 1: return ["a": Double(p[0].rows + p[0].cols)]; case 2: return ["b": Double(p[1].rows * p[1].cols - 1)]; case 3: return ["s": Double(P.W * P.H)]; default: return nil }
    }
}
