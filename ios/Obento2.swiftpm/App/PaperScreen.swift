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
                    if let lesson = model.lesson {
                        UnitCubesView(model: lesson, time: t)
                    } else {
                        surfaceGestures
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
