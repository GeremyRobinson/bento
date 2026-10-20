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
                    Toolbar(model: model, time: t, bottom: max(16, safe.safeAreaInsets.bottom + 8))
                    // the keypad: fixed to the screen's right, while the problem being worked wants a number typed
                    if let w = model.bars?.current as? WorkProblem, !w.auto, !w.solved, let a = w.lesson.step.answer, a.choices == nil {
                        FloatingKeypad(type: w.type)
                            .padding(.trailing, 24).padding(.bottom, max(16, safe.safeAreaInsets.bottom + 8) + 96)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    }
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
        model.moving || model.leaving || PaperClock.now - model.pinchedAt < 1.3 || PaperClock.now - model.drawnAt < Piece.drawTime + 0.2 || (model.lesson?.animating ?? false) || (model.bars?.animating ?? false) || (model.steps?.animating ?? false)
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


/// The keypad for a typed step: the paper's cell blocks, on a card at the screen's edge.
struct FloatingKeypad: View {
    let type: (String) -> Void
    var body: some View {
        VStack(spacing: -1.5) {
            ForEach([["7", "8", "9"], ["4", "5", "6"], ["1", "2", "3"], [".", "0", "del"]], id: \.self) { row in
                HStack(spacing: -1.5) {
                    ForEach(row, id: \.self) { key in
                        CellButton(width: 64, height: 64, action: { type(key) }) {
                            if key == "del" { Icon(name: "backspace", size: 24) }
                            else { Text(key).font(Typeface.font(26, .medium)) }
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 20).fill(Ink.surface).shadow(color: .black.opacity(0.10), radius: 15, y: 8))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Ink.line, lineWidth: 1))
    }
}
