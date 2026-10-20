import SwiftUI
import RealityKit

extension Rig {
    /// A place of its own on the paper (Me, the grown-ups' page), drawn like everything else (SketchDrawer): it draws
    /// itself in as the camera arrives, only what changes redraws (a count rolls over, a question is asked on the
    /// paper), and leaving it undraws, last first. The grown-ups' ring fills as a live part, drawn at once.
    func drawPlace(_ model: PaperModel, at t: Double) {
        let isDark = dark ?? false
        guard let place = model.place else {
            if let d = placeDrawer { d.root.removeFromParent(); placeDrawer = nil }
            if model.placeDrawing { Task { @MainActor in model.setPlaceDrawing(false) } }
            return
        }
        // a fresh drawing when it's arrived again after undrawing
        if model.placeLeftAt == nil, placeDrawer?.leftAt != nil { placeDrawer?.root.removeFromParent(); placeDrawer = nil }
        let d = placeDrawer ?? { let d = SketchDrawer(); d.pace = 0.6; placeRoot.addChild(d.root); placeDrawer = d; return d }()
        if let left = model.placeLeftAt {
            d.undrawAll(at: left)
        } else {
            let p = Progress.shared
            let key: String
            switch place {
            case .me: key = "me \(p.checks) \(p.reviews) \(PageStore.version) \(Review.day(t)) \(isDark)"
            case .grownUp:
                let g = model.grownUp
                // the settings too: the bar's ⋯ can change the paper's colours while the page is up
                key = "gu \(g.open) \(g.letGoAt != nil) \(g.version) \(p.checks) \(PageStore.version) \(isDark) \(AppSettings.theme) \(AppSettings.sound) \(AppSettings.readAloud)"
            }
            if key != d.key {
                d.key = key
                let sketch = place == .me ? MePage.sheet(now: t).sketch : model.grownUp.sheet(now: t).sketch
                d.build(sketch, rig: self, chapter: Chapter.whole.hex, dark: isDark, origin: .zero, from: d.isEmpty ? model.placeAt : t, now: t)
            }
            // the hold's ring, filled as far as it's held
            let g = model.grownUp, k = place == .grownUp && !g.open ? g.fill(at: t) : 0
            let live = d.live, lk = "\(Int((k * 144).rounded())) \(isDark)"
            if lk != live.key {
                live.key = lk
                live.build(GrownUpPage.ringFill(k, in: g.square), rig: self, chapter: Chapter.whole.hex, dark: isDark, origin: .zero, from: t, now: t)
            }
        }
        let moving = d.update(at: t)
        if moving != model.placeDrawing { Task { @MainActor in model.setPlaceDrawing(moving) } }
    }
}
