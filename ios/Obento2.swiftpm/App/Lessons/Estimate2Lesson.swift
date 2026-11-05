import SwiftUI

/// Estimate length on the paper, as in the preview (design/prototype/grade2-ch4.html, dEstimate): as Inches and
/// centimeters. The benchmark lies above the thing's left end (a paper clip, about an inch, a block long; a centimeter
/// cube, 2 × 2). Tap a guess (three word blocks where the record goes): right, the benchmarks glide off the first one and
/// lay themselves end to end along the thing, counted; wrong, the guess is drawn dashed along it (red). Then the ruler
/// slides up in under the thing: hop it end to end; write `[6] in` under `about 6 in`. The fold (feet and meters): a long
/// thing drawn smaller (a foot a block, a meter 2 blocks), guessed by a foot ruler or a meter stick, then measured by hopping
/// the ruler, the stick or a yardstick (3 feet, then the rest) along a floor line under it, the landings counted.
///
/// Departure: the laid benchmarks stay under the thing while it's measured (the ruler lies 2 rows lower, so the hops arc
/// clear of them), rather than going as the ruler comes. Kept: "wp" the wrong guess last tapped; "h…" the hop.
@MainActor
struct Estimate2Lesson: PaperLesson {
    static let TY = 3.0, RY = 10.0
    private func at(_ s: PaperState) -> Int { Int((s.picture["at"] ?? 0).rounded()) }
    private func TL(_ P: Estimate2.Parts) -> Double { P.U.per * Double(P.start) }
    private func X(_ P: Estimate2.Parts, _ v: Int) -> Double { P.U.per * Double(v) }
    func recordRow(_ n: Numbers) -> Double? { Self.RY + 6 }
    private func pw(_ P: Estimate2.Parts) -> Double {
        var w = 0.0
        for v in P.guesses { w = max(w, KK.width(P.label(v), KK.words)) }
        return max(10, EG2.ceil5(w + 2))
    }
    private func picks(_ P: Estimate2.Parts) -> [CGRect] {
        let w = pw(P)
        return (0..<3).map { CGRect(x: Double($0) * (w + 5), y: Self.TY + 5, width: w, height: 4) }
    }
    private func lines(_ P: Estimate2.Parts) -> (about: [M7.Tok], boxX: Double, end: Double) {
        let about: [M7.Tok] = [.w("about"), .n(P.len), .w(P.u)]
        let a = M7.width([.w("about")]), n = M7.width([.n(P.len)]), b = M7.width([.box("x", cells: 2)])
        let boxX = max(0, a + n - b)
        return (about, boxX, max(M7.width(about), boxX + M7.width([.box("x", cells: 2), .w(P.u)])))
    }
    func blocksAt(_ s: PaperState) -> CGPoint? {
        guard at(s) >= 2 else { return nil }
        return CGPoint(x: EG2.ceil5(lines(Estimate2.Parts(s.numbers)).end + 1), y: Self.RY + 9)
    }

    func draw(_ s: PaperState) -> PaperDrawing {
        let P = Estimate2.Parts(s.numbers), st = at(s), TY = Self.TY, RY = Self.RY, per = P.U.per
        let tl = TL(P), tr = tl + per * Double(P.len), bw = LN2.toolLength[P.bench] ?? 5
        var pic = GridPen(), rec = GridPen(), live = GridPen(stableIds: true)
        // the benchmark above the thing's left end, the thing
        let benchY = P.bench == "clip" ? 0.5 : 0
        LN2.tool(&pic, "bench", P.bench, x: tl, y: benchY, name: P.fold ? "1 \(P.u)" : nil)
        LN2.thing(&pic, "t", P.name, x0: tl, x1: tr, y: TY)
        let ring = s.on("ring") && !s.on("spot"), spot = s.on("spot")
        let layY = P.bench == "clip" ? TY + 3 : TY + 2.5
        if st == 0 {
            // the guesses; a wrong one drawn dashed along the thing
            let wrong = s.run.kept["wp"].map { Int($0.rounded()) }
            let R = picks(P)
            for (i, v) in P.guesses.enumerated() { E1.block(&pic, "pk\(i)", x: R[i].minX, y: R[i].minY, w: R[i].width, P.label(v), wrong: wrong == v) }
            if let w = wrong, w > 0 {
                let far = min(Double(w), Double(P.top + 1))
                pic.line("wg\(w)", [(tl, TY + 3.3), (tl + per * far, TY + 3.3)], KK.red, dashed: true)
            }
            if ring { KK.hintBox(&pic, "hr", x: tl, y: TY, w: tr - tl, h: 2) }
            if spot, let i = P.guesses.firstIndex(of: P.len) { KK.hintBox(&pic, "sp", x: R[i].minX, y: R[i].minY, w: R[i].width, h: 4) }
        } else {
            // the benchmarks glide off the first and lay end to end along the thing, counted
            L5.seeded(&pic, was: { p in for j in 0..<P.len { LN2.tool(&p, "lay\(j)", P.bench, x: tl, y: benchY, n: j + 1) } }) { p in
                for j in 0..<P.len {
                    p.sketch.delay = st == 1 ? 0.16 * Double(j) : 0
                    LN2.tool(&p, "lay\(j)", P.bench, x: tl + bw * Double(j), y: layY, n: j + 1)
                }
                p.sketch.delay = 0
            }
        }
        let c = st == 1 ? LN2.chain(s, "h") : st > 1 ? LN2.Chain(f: P.start, t: P.end) : nil
        if st >= 1 && P.fold {
            // the tool hops along a floor line under the thing: whole tools, then (a yardstick) the rest
            let hs = c.map { Len2.hops($0.f, $0.t, big: P.step, restInOne: true) } ?? []
            let last = hs.last.map { Double($0.0) } ?? 0
            pic.line("floor", [(tl, RY + 2), (tl + per * Double(P.top), RY + 2)], .ink3)
            let name = "\(P.step) \(P.u)"
            if c == nil, st == 1 {
                L5.seeded(&pic, was: { p in LN2.tool(&p, "tool", P.tool, x: tl, y: RY + 6, name: name) }) { p in
                    p.sketch.delay = 0.16 * Double(P.len) + 0.3
                    LN2.tool(&p, "tool", P.tool, x: tl, y: RY, name: name)
                    p.sketch.delay = 0
                }
            } else {
                p_toolMoved(&pic, P, x: tl + per * last, name: name)
            }
            for (a, b) in hs {
                pic.hop("h\(a):\(b)", from: X(P, a), to: X(P, b), row: RY, height: min(1.6, per * Double(abs(b - a)) * 0.2))
                pic.line("lt\(b)", [(X(P, b), RY + 2), (X(P, b), RY + 2.6)])
                pic.word("ln\(b)", "\(b)", at: X(P, b), RY + 3.4, KK.lit)
            }
            if st == 1, !hs.isEmpty { let ro = "\(Len2.landings(hs.map { $0.1 })) \(P.u)"; EG2.readout(&pic, ro, x: tr + 1.5, y: TY + 1); if s.grabbed { live.reads(ro) } }
        } else if st >= 1 {
            let lit = c.map { $0.t != $0.f ? [$0.f, $0.t] : [$0.f] } ?? []
            if c == nil, st == 1 {
                L5.seeded(&pic, was: { p in LN2.ruler(&p, "r", x0: 0, y: RY + 6, per: per, max: P.top) }) { p in
                    p.sketch.delay = 0.16 * Double(P.len) + 0.3
                    LN2.ruler(&p, "r", x0: 0, y: RY, per: per, max: P.top)
                    p.sketch.delay = 0
                }
            } else {
                LN2.ruler(&pic, "r", x0: 0, y: RY, per: per, max: P.top, lit: lit)
            }
            pic.line("d1", [(tl, TY + 2), (tl, RY)], .ink3, dashed: true)
            pic.line("d2", [(tr, TY + 2), (tr, RY)], .ink3, dashed: true)
            if let c { LN2.hops(&pic, "h", c.f, c.t, x0: 0, per: per, row: RY, height: per > 2 ? 1.2 : 0.6) }
            if st == 1, let c, c.t != c.f { let ro = "\(abs(c.t - c.f)) \(P.u)"; EG2.readout(&pic, ro, x: tr + 1.5, y: TY + 1); if s.grabbed { live.reads(ro) } }
        }
        if st == 1 {
            if ring { KK.hintBox(&pic, "hr", x: tl, y: RY - 1.5, w: tr - tl, h: 1.5) }
            if spot { pic.circle("sp", at: tl, RY, radius: 1, .chapter, dashed: true) }
        }
        // the record: about 6 in, then [6] in under it
        if st >= 1 {
            let L = lines(P)
            M7.row(&rec, "ab", L.about, x: 0, line: 1)
            if st >= 2 {
                let e = st == 3 ? M7.row(&rec, "rec", [.n(P.len, .chapter), .w(P.u)], x: M7.width([.w("about")]), line: 4)
                    : M7.row(&rec, "rec", [.box("x", cells: 2), .w(P.u)], x: L.boxX, line: 4)
                if st == 2 && ring { KK.hintBox(&pic, "hw", x: tl, y: RY - 1.5, w: tr - tl, h: 1.5) }
                if st == 2 && spot { A1.note(&rec, "spot", "\(P.len)", x: e + 0.5, y: 4) }
            }
        }
        var right = max(tr + 1.5 + KK.width("\(P.len) \(P.u)", KK.words), per * Double(P.top) + 1)
        if P.fold { right = max(right, tr + 1.5 + KK.width(Len2.landings(P.toolHops.map { $0.1 }) + " " + P.u, KK.words)) }
        right = max(right, picks(P)[2].maxX)
        return PaperDrawing(picture: pic.sketch, live: live.sketch, record: rec.sketch, boxes: rec.boxes, extent: pic.R(-1, 0, right + 1, RY + 4))
    }
    /// The fold's tool where its last hop starts (it glides there along the floor).
    private func p_toolMoved(_ pic: inout GridPen, _ P: Estimate2.Parts, x: Double, name: String) {
        LN2.tool(&pic, "tool", P.tool, x: x, y: Self.RY, name: name)
    }

    func hands(_ s: PaperState) -> Hands? {
        let P = Estimate2.Parts(s.numbers), st = at(s), per = P.U.per, top = P.top
        if st == 0 {
            let R = picks(P)
            return Hands(tap: { q in
                guard let i = R.firstIndex(where: { $0.insetBy(dx: -0.3, dy: -0.3).contains(q) }) else { return nil }
                let v = P.guesses[i]
                return HandMove(hand: nil, missHand: nil, set: [("g", Double(v))], keep: ["wp": v == P.len ? -1 : Double(v)], check: true)
            })
        }
        guard st == 1 else { return nil }
        return LN2.hopHands(s, "h", box: "h", band: (Self.TY - 0.5)...(Self.RY + 3.5), xr: 0...(per * Double(top)),
                            at: { x in max(0, min(top, Int((x / per).rounded()))) }, clears: { f, _ in f != P.start })
    }

    func demo(_ s: PaperState) -> [GhostMove] {
        let P = Estimate2.Parts(s.numbers)
        switch at(s) {
        case 0:
            guard let i = P.guesses.firstIndex(of: P.len) else { return [] }
            let r = picks(P)[i]
            return [.tap(.picture(CGPoint(x: r.midX, y: r.midY)))]
        case 1: return [.drag(from: CGPoint(x: TL(P), y: Self.RY - 0.5), to: CGPoint(x: X(P, P.end), y: Self.RY - 0.5))]
        default: return []
        }
    }
    func wrongMove(_ s: PaperState) -> HandMove? {
        let P = Estimate2.Parts(s.numbers)
        switch at(s) {
        case 0: return HandMove(hand: nil, missHand: nil, set: [("g", Double(P.smallGuess))], keep: ["wp": Double(P.smallGuess)], check: true)
        case 1: return LN2.hopMove("h", box: "h", from: P.start, to: P.end - 1)
        default: return nil
        }
    }
    func wrongTyping(_ s: PaperState) -> [String: Double]? {
        let P = Estimate2.Parts(s.numbers)
        guard at(s) == 2 else { return nil }
        return ["x": Double(P.slips.first?.0 ?? P.len + 1)]
    }
}
