import SwiftUI

/// Unit cubes as a 3D lesson. Its squares, cubes and words live in the paper's own scene (PaperScene, CubesWords);
/// this is the gestures on top. A tap on a block presses it; anywhere else it lands on the paper.
struct UnitCubesView: View {
    let model: UnitCubesModel
    let time: Double
    @State private var lastDrag: CGSize = .zero
    @State private var lastPinch: CGFloat = 1

    init(model: UnitCubesModel, time: Double) { self.model = model; self.time = time }

    var body: some View {
        Color.clear.contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 4)
                .onChanged { g in model.pan(g.translation.width - lastDrag.width, g.translation.height - lastDrag.height); lastDrag = g.translation }
                .onEnded { _ in lastDrag = .zero })
            .simultaneousGesture(MagnifyGesture()
                .onChanged { g in model.pinch(g.magnification / lastPinch); lastPinch = g.magnification }
                .onEnded { _ in lastPinch = 1 })
            .simultaneousGesture(SpatialTapGesture().onEnded { g in tap(.init(g.location.x, g.location.y)) })
    }

    private func tap(_ p: Point) {
        switch CubesLayout.block(at: p, model) {
        // hands off while a See beat plays
        case .some where model.busy: return
        case .main: model.go()
        case .showMe: model.showMe()
        case .reset: model.reset()
        case nil: model.tapScreen(p)
        }
    }
}

extension View {
    /// Puts this view's `anchor` on a screen point, scaled with the paper.
    func pinned(_ p: CGPoint, _ anchor: UnitPoint, _ k: Double) -> some View {
        let h: HorizontalAlignment = anchor.x == 0 ? .leading : anchor.x == 1 ? .trailing : .center
        let v: VerticalAlignment = anchor.y == 0 ? .top : anchor.y == 1 ? .bottom : .center
        return fixedSize()
            .scaleEffect(k, anchor: anchor)
            .frame(width: 0, height: 0, alignment: Alignment(horizontal: h, vertical: v))
            .position(p)
    }
}
