import Foundation

/// Show me is a preview, never the child's work (G, 17 Oct): the right cells fill on the paper one after another,
/// hold so they can be seen, then fade back to what the child had marked. The lesson's own marks don't change.
struct ShowMePreview {
    let cells: [Int]
    let at: Double
    /// Seconds between one cell and the next.
    let step: Double
    static let hold = 0.9, fade = 0.4

    var end: Double { at + step * Double(cells.count) + 0.26 + Self.hold + Self.fade }

    /// How far a cell is filled by the preview at time t (0...1).
    func level(_ cell: Int, at t: Double) -> Double {
        guard let n = cells.firstIndex(of: cell) else { return 0 }
        let rise = ease((t - at - step * Double(n)) / 0.26)
        let fall = 1 - ease((t - (end - Self.fade)) / Self.fade)
        return rise * fall
    }
}
