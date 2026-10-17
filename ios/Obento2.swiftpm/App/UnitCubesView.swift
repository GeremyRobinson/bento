import SwiftUI

/// Unit cubes as a 3D lesson. Its squares and cubes live in the paper's own scene (PaperScene); this is the words,
/// buttons and gestures on top. One cube sits on one big square.
/// It opens flat, lined up with the paper exactly; it only tilts when the squares rise into cubes.
/// Words and buttons are pinned to points on the paper, so they travel with it and always face the child.
struct UnitCubesView: View {
    let model: UnitCubesModel
    let time: Double
    let top: CGFloat
    let onBack: () -> Void
    @State private var lastDrag: CGSize = .zero
    @State private var lastPinch: CGFloat = 1

    init(model: UnitCubesModel, time: Double, top: CGFloat, onBack: @escaping () -> Void) { self.model = model; self.time = time; self.top = top; self.onBack = onBack }

    var body: some View {
        let v = model.view(at: time)
        let k = v.scale / Paper.unit
        ZStack(alignment: .topLeading) {
            Color.clear.contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 4)
                    .onChanged { g in model.pan(g.translation.width - lastDrag.width, g.translation.height - lastDrag.height); lastDrag = g.translation }
                    .onEnded { _ in lastDrag = .zero })
                .simultaneousGesture(MagnifyGesture()
                    .onChanged { g in model.pinch(g.magnification / lastPinch); lastPinch = g.magnification }
                    .onEnded { _ in lastPinch = 1 })
                .simultaneousGesture(SpatialTapGesture().onEnded { g in model.tapScreen(.init(g.location.x, g.location.y)) })
            pins(v, k)
            LessonHeader(title: "Unit cubes", subtitle: "Volume · Lesson 02", top: top, onBack: onBack)
        }
    }

    @ViewBuilder private func pins(_ v: PaperView3D, _ k: Double) -> some View {
        let o = model.origin, b = model.box, L = Double(b.length), W = Double(b.width), H = Double(b.height)
        let tilt = model.tilt(at: time)
        let words = model.lesson.words
        let fresh = ease((time - model.wordsAt) / 0.5)
        let at = { (p: Vec3) -> CGPoint in let s = v.project(p, screen: model.screen); return CGPoint(x: s.x, y: s.y) }

        VStack(alignment: .leading, spacing: 0) {
            Text(words.say).font(Typeface.question).foregroundStyle(Ink.ink).frame(height: 40, alignment: .leading)
            Text(words.hint).font(Typeface.hint).foregroundStyle(Ink.ink2).frame(height: 20, alignment: .leading)
        }
        .frame(width: 480, alignment: .leading)
        .opacity(fresh).offset(y: (1 - fresh) * 8)
        .pinned(at(Vec3(o.x - 0.4 * tilt, 4.6 * tilt, o.z - 0.6 * (1 - tilt))), .bottomLeading, k)

        Text("\(b.length)").font(Typeface.label).foregroundStyle(Ink.ink).pinned(at(Vec3(o.x + L / 2, 0, o.z + W + 0.3)), .center, k)
        Text("\(b.width)").font(Typeface.label).foregroundStyle(Ink.ink).pinned(at(Vec3(o.x - 0.3, 0, o.z + W / 2)), .center, k)
        Text("\(b.height)").font(Typeface.label).foregroundStyle(Ink.ink).opacity(model.heightLabel(at: time))
            .pinned(at(Vec3(o.x + L + 0.3, H / 2, o.z + W)), .center, k)

        if model.lesson.step.task != nil {
            Group {
                if let m = model.message { Text(m.text).foregroundStyle(m.ok ? Ink.right : model.chapter.color) }
                else { Text(model.lesson.countLine ?? "").foregroundStyle(Ink.ink2) }
            }
            .font(Typeface.font(17, .medium)).fixedSize()
            .pinned(at(Vec3(o.x, 0, o.z + W + 0.6)), .topLeading, k)
        }

        HStack(spacing: -1.5) {
            if model.lesson.step.task != nil {
                CellButton(action: model.showMe) { Icon(name: "play") }
                CellButton(action: model.reset) { Icon(name: "arrow-counter-clockwise") }
                Color.clear.frame(width: 40, height: 40)
            }
            MainCellButton(title: words.action, action: model.go)
        }
        .pinned(at(Vec3(o.x, 0, o.z + W + 1)), .topLeading, k)
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
