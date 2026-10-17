import SwiftUI

/// The whole app is one sheet of paper: one 3D scene seen through one camera, with words and controls pinned on top.
struct PaperScreen: View {
    @State var model: PaperModel
    @State private var lastDrag: CGSize = .zero
    @State private var lastPinch: CGFloat = 1

    init(model: PaperModel) { _model = State(initialValue: model) }

    var body: some View {
        // the outer reader keeps the safe area, so it knows where the notch and home bar are
        GeometryReader { safe in
        GeometryReader { geo in
            TimelineView(.animation(paused: !animating)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                let cam = model.camera(at: t)
                ZStack(alignment: .topLeading) {
                    // RealityKit's view keeps the size it was made at, so a new screen shape (rotating) makes a new one
                    PaperScene(model: model, time: t)
                        .id("\(Int(model.screen.width))x\(Int(model.screen.height))")
                    if model.lesson == nil && model.bars == nil && model.steps == nil {
                        PiecesLayer(camera: cam, time: t, drawnAt: model.drawnAt, from: model.drawFrom, selected: model.selected)
                    }
                    if let lesson = model.lesson {
                        UnitCubesView(model: lesson, time: t)
                    } else {
                        surfaceGestures
                    }
                    if let bars = model.bars {
                        AddFractionsView(model: bars, camera: cam, time: t)
                    }
                    if let steps = model.steps {
                        StepsLessonView(model: steps, camera: cam, time: t)
                    }
                    TopBar(model: model, top: max(16, safe.safeAreaInsets.top + 8), bottom: max(16, safe.safeAreaInsets.bottom + 8))
                }
                .onChange(of: t) { _, now in Perf.frame(now); model.settle(at: now); model.lesson?.settle(at: now) }
            }
            .onAppear {
                model.screen = Size(geo.size.width, geo.size.height)
                model.reduceMotion(UIAccessibility.isReduceMotionEnabled)
                if !Shots.active { model.frameGroup(duration: 0) }
                Shots.run(model)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)) { _ in
                model.reduceMotion(UIAccessibility.isReduceMotionEnabled)
            }
            .onChange(of: geo.size) { _, s in model.screen = Size(s.width, s.height) }
        }
        .ignoresSafeArea()
        }
    }

    /// The clock only runs while something moves or draws, so a still paper costs nothing.
    private var animating: Bool {
        model.moving || PaperClock.now - model.drawnAt < Piece.drawTime + 0.2 || (model.lesson?.animating ?? false) || (model.bars?.animating ?? false) || (model.steps?.animating ?? false)
    }

    private var surfaceGestures: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 4)
                .onChanged { v in
                    model.pan(v.translation.width - lastDrag.width, v.translation.height - lastDrag.height); lastDrag = v.translation }
                .onEnded { _ in lastDrag = .zero })
            .simultaneousGesture(MagnifyGesture()
                .onChanged { v in
                    model.zoom(by: v.magnification / lastPinch, at: .init(v.startLocation.x, v.startLocation.y)); lastPinch = v.magnification }
                .onEnded { _ in lastPinch = 1 })
            .simultaneousGesture(SpatialTapGesture().onEnded { v in model.tap(at: .init(v.location.x, v.location.y)) })
    }
}

/// The words on the paper: the chapter title, each lesson's name, the Up next tag and the Start block.
/// The lessons' pictures and the grid are in the 3D scene underneath (PaperScene); this draws on top with the same camera.
struct PiecesLayer: View {
    let camera: PaperCamera
    let time: Double
    let drawnAt: Double
    let from: Point?
    let selected: Piece?

    var body: some View {
        Canvas { ctx, _ in
          Perf.time("words") {
            let z = camera.zoom
            ctx.translateBy(x: camera.x, y: camera.y); ctx.scaleBy(x: z, y: z)
            // chapter titles, baselines on a grid line: a dot in the chapter's colour, the title, and how many are learned
            for g in Map.groups {
                let o = g.origin, done = g.lessons.filter { Progress.shared.learned.contains($0.id) }.count
                ctx.fill(Path(ellipseIn: CGRect(x: o.x, y: o.y + 22, width: 10, height: 10)), with: .color(g.chapter.color))
                ctx.draw(Text(g.chapter.title).font(Typeface.title).foregroundStyle(Ink.ink), at: CGPoint(x: o.x + 20, y: o.y + 40), anchor: .bottomLeading)
                let w = MathLineView.width(g.chapter.title, 26)
                ctx.draw(Text("\(done) of \(g.lessons.count)").font(Typeface.font(15)).foregroundStyle(Ink.ink3), at: CGPoint(x: o.x + 32 + w, y: o.y + 37), anchor: .bottomLeading)
            }
            for p in Map.pieces { draw(p, k: Piece.drawIn(p, time: time, drawnAt: drawnAt, from: from), in: &ctx) }
          }
        }
        .allowsHitTesting(false)
    }

    private func draw(_ p: Piece, k: Double, in ctx: inout GraphicsContext) {
        let r = CGRect(x: p.at.x, y: p.at.y, width: Piece.size.width, height: Piece.size.height)
        let on = selected?.id == p.id
        var t = ctx; t.opacity = k
        t.draw(Text(p.name).font(Typeface.name).foregroundStyle(Ink.ink), at: CGPoint(x: r.minX, y: r.maxY + 28), anchor: .bottomLeading)
        if p.state == .now {
            let tag = CGRect(x: r.maxX - 80, y: r.minY - 20, width: 80, height: 20)
            t.fill(Path(tag), with: .color(p.chapter.color))
            t.draw(Text("Up next").font(Typeface.font(12, .semibold)).foregroundStyle(.white), at: CGPoint(x: tag.midX, y: tag.midY))
        }
        if on && p.opens {
            let s = CGRect(x: p.start.x, y: p.start.y, width: p.start.width, height: p.start.height)
            t.fill(Path(s), with: .color(Ink.surface))
            t.stroke(Path(s.insetBy(dx: 0.75, dy: 0.75)), with: .color(Ink.ink), lineWidth: 1.5)
            t.draw(Text("Start").font(Typeface.button).foregroundStyle(Ink.ink), at: CGPoint(x: s.minX + 16, y: s.midY), anchor: .leading)
            // the icon's shape, filled with ink like the arrows on the other buttons
            let a = CGRect(x: s.maxX - 30, y: s.midY - 10, width: 20, height: 20)
            t.drawLayer { l in l.clipToLayer { $0.draw(Image("ph-arrow-right"), in: a) }; l.fill(Path(a), with: .color(Ink.ink)) }
        }
    }
}
