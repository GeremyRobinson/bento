import SwiftUI

/// Obento²'s master components (G 19 Oct): every screen on the paper (the map, a lesson's page of problems, a problem,
/// the How to) builds its words and controls from these, so a change made here is made everywhere. Each draws into a
/// Sketch, so it draws itself in and undraws the same way (SketchDrawer), and each keeps to the grid: words in rows of
/// squares, starting on the left edge they're given; numbers in their squares; blocks on grid lines.
extension Sketch {
    /// A row of words is two squares tall.
    static let row = 2 * Paper.cell

    /// How a kind of words looks, everywhere it appears.
    struct Words {
        let size: CGFloat, weight: UIFont.Weight, colour: Colour
        /// A problem's name over it ("Together 1"), a card's status, a test's line.
        static let name = Words(size: 17, weight: .medium, colour: .ink3)
        /// A part's heading on the page of problems ("Together"), a chapter's title is bigger (`chapter`).
        static let heading = Words(size: 26, weight: .semibold, colour: .ink)
        static let chapter = Words(size: 30, weight: .medium, colour: .ink)
        /// What to do now.
        static let say = Words(size: 28, weight: .medium, colour: .ink)
        /// The hint under it, and a story.
        static let hint = Words(size: 20, weight: .regular, colour: .ink2)
        static let story = Words(size: 20, weight: .regular, colour: .ink)
        /// What a miss (or Show me) says.
        static let message = Words(size: 20, weight: .medium, colour: .chapter)
        /// A thumbnail's name under its frame, and its status under that.
        static let label = Words(size: 20, weight: .medium, colour: .ink)
        static let status = Words(size: 16, weight: .regular, colour: .ink3)
        /// A count beside a title ("3 of 5").
        static let count = Words(size: 17, weight: .regular, colour: .ink3)
        /// A tab's word ("Done", "Up next", "Start").
        static let tab = Words(size: 14, weight: .semibold, colour: .hex(0xFFFFFF, 0xFFFFFF))
        /// A block's word ("Check").
        static let block = Words(size: 17, weight: .medium, colour: .ink)
        func colour(_ c: Colour) -> Words { Words(size: size, weight: weight, colour: c) }
    }

    /// Words in rows of squares from `top`, each line centred in its row and starting on `x`, wrapped to `width`;
    /// `k` draws them bigger (a big problem). Returns how many rows.
    @discardableResult
    mutating func words(_ id: String, _ text: String, _ w: Words, x: Double, top: Double, width: Double, max: Int = 1, k: Double = 1) -> Int {
        let lines = Array(PaperText.wrap(text, PaperText.font(w.size * k, w.weight), width: width).prefix(max))
        for (i, line) in lines.enumerated() {
            self.text("\(id)\(i):\(line)", line, at: CGPoint(x: x, y: top + (Double(i) + 0.5) * Self.row * k), size: w.size * k, weight: w.weight, w.colour,
                      anchor: UnitPoint(x: 0, y: 0.5), digits: false)
        }
        return lines.count
    }

    /// One line of words with its baseline at `at` (a thumbnail's name and status under its frame).
    mutating func label(_ id: String, _ text: String, _ w: Words, at p: CGPoint, anchor: UnitPoint = UnitPoint(x: 0, y: 1)) {
        self.text("\(id):\(text)", text, at: p, size: w.size, weight: w.weight, w.colour, anchor: anchor, digits: false)
    }

    /// A problem's sum as written at the top of the problem and on its card: one line of big numbers starting exactly
    /// on the left edge (or centred on `at` when `centred`), a fraction stacked a digit to a square. Returns its width.
    @discardableResult
    mutating func sum(_ id: String, _ line: MathLine, at p: CGPoint, size: CGFloat = 40, k: Double = 1, centred: Bool = false) -> Double {
        let lay = MathLineView.layout(line, size: 28)
        if lay.h > 2 {
            // a fraction: stacked on the squares, a digit to a square
            let cell = Paper.cell * k, w = Double(lay.w) * cell
            let x = centred ? p.x - ((w / 2) / cell).rounded() * cell : p.x
            mathLine(id, line, at: CGPoint(x: x, y: centred ? p.y - 2 * cell : p.y - cell), size: 30 * k, cell: cell)
            return w
        }
        // words after a number get a space before them ("6.723 ≈ ? (nearest tenth)")
        var text = ""
        for m in line {
            switch m {
            case .num(let x): text += fmt(x)
            case .op(let o): text += " \(o) "
            case .text(let t): text += (text.isEmpty || text.hasSuffix(" ") ? "" : " ") + t
            case .box: text += "?"
            case .frac: break
            }
        }
        let f = PaperText.font(size * k, .medium, digits: true)
        self.text("\(id):\(text)", text, at: centred ? p : CGPoint(x: p.x, y: p.y + Self.row * k), size: size * k, anchor: centred ? .center : UnitPoint(x: 0, y: 0.5))
        return PaperText.width(text, f)
    }

    /// How a block looks: its outline, its fill and its word.
    struct Block {
        var stroke: Colour = .hex(0xCFCCC5, 0x3A3A37), fill: Colour = .hex(0xFBFBFA, 0x1B1B1A), text: Colour = .ink
        /// The main one (Check, Next): outlined in ink.
        static let main = Block(stroke: .ink)
        static let plain = Block()
        /// A picked choice: in the chapter's colour.
        static let picked = Block(stroke: .chapter, fill: .tint(0.12), text: .chapter)
    }

    /// A block on the paper (a button, an answer box, a key): its outline strokes on, its fill under it, then its word
    /// (from the left, with an arrow on the right when `arrow`) or its centred number or icon.
    /// `size`: the centred number's size (a key's 30, a typed answer's 26, a choice's words 17).
    mutating func block(_ id: String, _ r: CGRect, _ b: Block, word: String? = nil, arrow: Bool = false, centred: String? = nil, size: CGFloat = 30, icon: String? = nil, k: Double = 1) {
        fill("\(id)f\(r)\(b.fill)", r, b.fill)
        let i = r.insetBy(dx: 0.75 * k, dy: 0.75 * k)
        line("\(id)o\(r)\(b.stroke)", [CGPoint(x: i.minX, y: i.minY), CGPoint(x: i.maxX, y: i.minY), CGPoint(x: i.maxX, y: i.maxY), CGPoint(x: i.minX, y: i.maxY), CGPoint(x: i.minX, y: i.minY)], b.stroke, width: 1.5 * k)
        if let word { text("\(id)w\(word)", word, at: CGPoint(x: r.minX + 20 * k, y: r.midY), size: Words.block.size * k, weight: .medium, b.text, anchor: UnitPoint(x: 0, y: 0.5), digits: false) }
        if arrow { self.icon("\(id)a", "arrow-right", in: CGRect(x: r.maxX - 30 * k, y: r.midY - 10 * k, width: 20 * k, height: 20 * k), b.text) }
        if let centred { text("\(id)c\(centred)", centred, at: CGPoint(x: r.midX, y: r.midY), size: size * k, weight: .medium, b.text, digits: size > 20) }
        if let icon { self.icon("\(id)i", icon, in: CGRect(x: r.midX - 13 * k, y: r.midY - 13 * k, width: 26 * k, height: 26 * k), b.text) }
    }

    /// A tab on a frame's top-right corner, in the chapter's colour ("Done", "Now", "Up next", "Start"), with an arrow
    /// when it's something to tap.
    /// `colour`: its chapter's (the map draws many chapters at once, so it says which).
    mutating func tab(_ id: String, frame r: CGRect, _ word: String, width: Double = 80, arrow: Bool = false, colour: Colour = .chapter) {
        let t = CGRect(x: r.maxX - width, y: r.minY - Paper.cell, width: width, height: Paper.cell)
        fill("\(id)tab\(word)\(width)\(colour)", t, colour)
        if arrow {
            text("\(id)tabw\(word)", word, at: CGPoint(x: t.minX + 12, y: t.midY), size: Words.tab.size, weight: Words.tab.weight, Words.tab.colour, anchor: UnitPoint(x: 0, y: 0.5), digits: false)
            self.icon("\(id)taba", "arrow-right", in: CGRect(x: t.maxX - 26, y: t.midY - 8, width: 16, height: 16), Words.tab.colour)
        } else {
            text("\(id)tabw\(word)", word, at: CGPoint(x: t.midX, y: t.midY), size: Words.tab.size, weight: Words.tab.weight, Words.tab.colour, digits: false)
        }
    }

    /// A thumbnail's frame (a lesson on the map, a problem on its page): its outline in the chapter's colour, light
    /// unless it's the one being worked; dashed while it waits; lightly filled once done.
    enum FrameState { case open, now, done, locked }
    mutating func frame(_ id: String, _ r: CGRect, _ state: FrameState) {
        let corners = [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.minX, y: r.minY)]
        switch state {
        case .locked: line(id + "o-locked", corners, .tint(0.35), width: 1.5, dashed: true)
        case .now: line(id + "o-now", corners, .chapter, width: 2.5)
        case .done:
            fill(id + "f", r, .tint(0.08))
            line(id + "o", corners, .tint(0.3), width: 1.5)
        case .open: line(id + "o", corners, .tint(0.3), width: 1.5)
        }
    }
}
