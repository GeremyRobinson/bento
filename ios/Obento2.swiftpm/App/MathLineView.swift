import SwiftUI

/// A line of math laid out on the paper's cells, like on graph paper: each digit in its own cell, a sign in a cell with
/// an empty cell either side, an answer box two cells tall and whole cells wide, and a fraction's bar on a grid line.
/// The problem's sum, the line being worked and the work are drawn from this layout (Sketch.sum, Sketch.mathLine,
/// ProblemGrid, ProblemLayout), so everything lands on the grid.
enum MathLineView {
    struct Item: Identifiable {
        enum Kind { case char(String, ink: Bool), point, word(String), box(String), bar }
        let id: Int
        let kind: Kind
        /// Position and size, in cells.
        let col: Int, row: Int, w: Int, h: Int
    }

    static let cell = Paper.cell

    /// Lays the line out in cells: its pieces, and its width and height (two cells, or four with a fraction in it).
    static func layout(_ line: MathLine, typed: [String: String] = [:], size: CGFloat) -> (items: [Item], w: Int, h: Int) {
        var items: [Item] = [], col = 0
        let tall = line.contains { if case .frac = $0 { true } else { false } }
        let h = tall ? 4 : 2, mid = tall ? 1 : 0
        func add(_ k: Item.Kind, _ c: Int, _ r: Int, _ w: Int, _ hh: Int) { items.append(Item(id: items.count, kind: k, col: c, row: r, w: w, h: hh)) }
        /// One piece at (col, row); returns its width in cells.
        func place(_ m: Math, _ c: Int, _ r: Int) -> Int {
            switch m {
            case .num(let x):
                // a digit to a cell; the point sits on the line between two digits, as on graph paper
                var i = 0
                for ch in fmt(x) {
                    if ch == "." { add(.point, c + i, r, 0, 2) } else { add(.char(String(ch), ink: true), c + i, r, 1, 2); i += 1 }
                }
                return i
            case .op(let o): add(.char(o, ink: true), c, r, 1, 2); return 1
            case .text(let t):
                let w = cells(t)
                add(.word(t), c, r, w, 2); return w
            case .box(let id):
                let w = max(3, (typed[id] ?? "").count + 2)
                add(.box(id), c, r, w, 2); return w
            case .frac(let a, let b):
                let wa = measure(a), wb = measure(b), w = max(wa, wb)
                _ = place(a, c + (w - wa) / 2, r - 1); _ = place(b, c + (w - wb) / 2, r + 1)
                add(.bar, c, r + 1, w, 0)
                return w
            }
        }
        func measure(_ m: Math) -> Int {
            switch m {
            case .num(let x): fmt(x).filter { $0 != "." }.count
            case .op: 1
            case .text(let t): cells(t)
            case .box(let id): max(3, (typed[id] ?? "").count + 2)
            case .frac(let a, let b): max(measure(a), measure(b))
            }
        }
        func cells(_ t: String) -> Int { Int(((width(t, size * 0.7) + 2) / cell).rounded(.up)) }
        for (i, m) in line.enumerated() {
            if i > 0 { col += 1 }  // an empty cell between pieces
            col += place(m, col, tall ? (isFrac(m) ? 1 : mid) : 0)
        }
        return (items, col, h)
    }

    static func isFrac(_ m: Math) -> Bool { if case .frac = m { true } else { false } }

    static func width(_ t: String, _ size: CGFloat) -> CGFloat {
        var f = UIFont.systemFont(ofSize: size)
        if let d = f.fontDescriptor.withDesign(.rounded) { f = UIFont(descriptor: d, size: size) }
        return (t as NSString).size(withAttributes: [.font: f]).width
    }
}
