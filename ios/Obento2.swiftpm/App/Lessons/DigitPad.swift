import SwiftUI

/// The digit pad (the preview design/prototype/gradeK-ch5.html, grade1-ch3.html's): Kindergarten's one written number past
/// 20, and 1st grade's numbers to 120, written by tapping drawn keys on the paper, never the iPad's keyboard. Ten keys,
/// 0–9, and a rub-out, each 4 × 4 squares in one row (44 squares; small fingers, call of 4 Nov: 80 pt at 100%, never under
/// 60 pt at the 75% a lesson keeps), drawn faint; the lesson's own Check block goes two
/// squares right of it (`checkAt`). A key tapped writes its digit into the record's box (a hand move that sets the box,
/// not checked); Check checks it. After a miss the box is red until the next key starts it again.
@MainActor
enum DigitPad {
    static let key = 4.0, width = 44.0
    /// Rub-out's place on the row.
    static let rubOut = 10
    static let digit = Sketch.Words(size: Sketch.maths, weight: .medium, colour: .ink)

    /// The pad from (x, y): its keys, and a hint's ring round key `spot`.
    static func draw(_ pen: inout GridPen, _ id: String, x: Double, y: Double, spot: Int? = nil) {
        for i in 0...rubOut {
            let kx = x + key * Double(i)
            pen.sketch.box("\(id)k\(i)", pen.R(kx, y, key, key), .ink3, width: Sketch.stroke)
            if i < rubOut {
                pen.word("\(id)n\(i)", "\(i)", at: kx + key / 2, y + key / 2, digit)
            } else {
                // a rub-out: a key-shaped outline pointing left
                let m = key / 2
                pen.line("\(id)x", [(kx + m - 1.3, y + m), (kx + m - 0.5, y + m - 0.8), (kx + m + 1.3, y + m - 0.8), (kx + m + 1.3, y + m + 0.8), (kx + m - 0.5, y + m + 0.8), (kx + m - 1.3, y + m)], .ink2)
            }
        }
        if let spot { KK.hintBox(&pen, "\(id)spot", x: x + key * Double(spot), y: y, w: key, h: key) }
    }
    /// The key tapped (0–9, or `rubOut`), or nil.
    static func tapped(_ q: CGPoint, x: Double, y: Double) -> Int? {
        guard q.y >= y, q.y <= y + key, q.x >= x, q.x < x + width else { return nil }
        return min(rubOut, Int((q.x - x) / key))
    }
    /// The middle of key `k`: where the ghost finger taps.
    static func spot(_ k: Int, x: Double, y: Double) -> CGPoint { CGPoint(x: x + key * Double(k) + key / 2, y: y + key / 2) }
    /// Where the lesson's Check block goes: two squares right of the pad.
    static func checkAt(x: Double, y: Double) -> CGPoint { CGPoint(x: x + width + 2, y: y) }

    /// The number in the box after key `k`: a digit on the end (`fresh`: the box starts again, after a miss), the last
    /// digit rubbed out (nil: empty), at most `most` digits.
    static func press(_ k: Int, _ value: Int?, fresh: Bool, most: Int = 3) -> Int? {
        let was = fresh ? "" : value.map(String.init) ?? ""
        if k == rubOut { let s = String(was.dropLast()); return s.isEmpty ? nil : Int(s) }
        let s = was.count >= most ? was : was + "\(k)"
        return Int(s)
    }

    /// A step's box written with the pad: what's in it, and whether it's red (it was checked as it is and it's wrong).
    static func typed(_ s: PaperState, _ box: String, want: Int) -> (value: Int?, wrong: Bool) {
        let v = s.typed[box].flatMap { Double($0) }.map { Int($0.rounded()) }
        let checked = s.run.kept["chk"].map { Int($0.rounded()) }
        return (v, v != nil && v == checked && v != want)
    }
    /// The pad's hands: its keys on the picture, and Check.
    static func hands(_ s: PaperState, _ box: String, want: Int, x: Double, y: Double) -> Hands {
        let (v, wrong) = typed(s, box, want: want)
        return Hands(tap: { q in
            guard let k = tapped(q, x: x, y: y) else { return nil }
            return HandMove(hand: nil, missHand: nil, set: [(box, press(k, v, fresh: wrong).map(Double.init))], check: false)
        }, actions: ["Check": {
            guard let v else { return HandMove(hand: nil, missHand: nil) }
            return HandMove(hand: nil, missHand: nil, set: [(box, Double(v))], keep: ["chk": Double(v)], check: true)
        }])
    }
    /// Show me: the number's digits tapped, then Check.
    static func demo(_ n: Int, x: Double, y: Double) -> [GhostMove] {
        String(n).compactMap { $0.wholeNumberValue }.map { .tap(.picture(spot($0, x: x, y: y))) } + [.tap(.action("Check"))]
    }
}
