import SwiftUI

/// The decimal-shift picture master: a row of digit boxes on the grid with the decimal point between them.
/// Times 10^k the point hops k places right, one hop per 0.45 s, and a 0 is written in for each place it runs
/// past the last digit. Everything comes from the problem's numbers. The boxes, hops and point are in the paper's
/// scene (PaperScene.drawShift); the digits and the label are words on top (ShiftWords).
struct ShiftPicture {
    let digits: [Character]
    /// How many digits sit left of the point, before and after the move.
    let from: Int, to: Int
    /// The zeros written in past the last digit.
    let added: Set<Int>
    let multiplier: Double

    // in paper points from the lesson's origin; boxes are two cells, one cell apart
    static let box: Double = 40, pitch: Double = 60, top: Double = 140, hop: Double = 0.45, lift: Double = 34

    init(_ n: Numbers) {
        let k = Int(n["k"] ?? 1)
        var (d, w) = PowersOfTen.digits(n["x"] ?? 0)
        var added: Set<Int> = []
        while w + k > d.count { added.insert(d.count); d += "0" }
        digits = Array(d); from = w; to = w + k; self.added = added; multiplier = pow(10, Double(k))
    }

    func boxX(_ i: Int) -> Double { Double(i) * Self.pitch }
    /// The middle of the gap just left of box `p` (p = how many digits are left of the point).
    func gapX(_ p: Int) -> Double { Double(p) * Self.pitch - (Self.pitch - Self.box) / 2 }
    var baseline: Double { Self.top + Self.box - 5 }

    /// How far the hops have got (0...k), `s` seconds after the step that moves the point began.
    func hops(_ s: Double, moving: Bool) -> Double { moving ? min(Double(to - from), max(0, (s - 0.3) / Self.hop)) : 0 }

    /// Where the point is after `h` hops: along an arc over the box it jumps.
    func point(_ h: Double) -> (x: Double, y: Double) {
        let i = min(Int(h), to - from - 1), f = h - Double(i)
        guard h < Double(to - from) else { return (gapX(to), baseline) }
        let x = gapX(from + i) + (gapX(from + i + 1) - gapX(from + i)) * f
        return (x, baseline - sin(.pi * f) * (Self.lift + Self.box - 5))
    }

    /// The hops drawn so far, as lines on the paper.
    func arcs(_ h: Double) -> [[CGPoint]] {
        (0..<Int(h.rounded(.up))).map { i in
            let end = min(1, h - Double(i))
            return (0...16).compactMap { s -> CGPoint? in
                let f = Double(s) / 16
                guard f <= end else { return nil }
                let x = gapX(from + i) + (gapX(from + i + 1) - gapX(from + i)) * f
                return CGPoint(x: x, y: Self.top - 8 - sin(.pi * f) * Self.lift)
            }
        }
    }

    /// A written-in zero shows once the point has jumped over its box.
    func shows(_ i: Int, hops h: Double) -> Bool { !added.contains(i) || h >= Double(i - from) + 0.5 }
}

/// The digits in their boxes and the line under the row.
struct ShiftWords: View {
    let model: StepsModel
    let time: Double
    let at: (Double, Double) -> CGPoint
    let k: Double

    var body: some View {
        let s = ShiftPicture(model.lesson.numbers), moving = model.lesson.picture["hop"] == 1
        let h = s.hops(model.sincePicture(time), moving: moving), shown = model.grow(at: time)
        let done = moving && h >= Double(s.to - s.from), hops = s.to - s.from
        ZStack(alignment: .topLeading) {
            ForEach(Array(s.digits.enumerated()), id: \.offset) { i, d in
                Text(String(d)).font(Typeface.font(28, .medium)).monospacedDigit().foregroundStyle(Ink.ink)
                    .opacity(s.shows(i, hops: h) ? shown : 0)
                    .pinned(at(s.boxX(i) + ShiftPicture.box / 2, ShiftPicture.top + ShiftPicture.box / 2), .center, k)
            }
            Text(done ? "× \(fmt(s.multiplier)): \(PowersOfTen.words[hops]) \(hops == 1 ? "hop" : "hops") right → \(fmt(((model.lesson["x"] * s.multiplier) * 1_000_000).rounded() / 1_000_000))"
                      : "× \(fmt(s.multiplier))")
                .font(Typeface.font(17, .medium)).foregroundStyle(done ? model.chapter.color : Ink.ink2).opacity(shown)
                .pinned(at(0, ShiftPicture.top + ShiftPicture.box + 20), .topLeading, k)
        }
    }
}
