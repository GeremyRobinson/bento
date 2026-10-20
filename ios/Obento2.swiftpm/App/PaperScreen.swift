import SwiftUI

/// The whole app is one sheet of paper: one 3D scene seen through one camera, with words and controls pinned on top.
struct PaperScreen: View {
    @State var model: PaperModel
    @State private var lastDrag: CGSize = .zero
    @State private var lastPinch: CGFloat = 1
    /// A drag is under way (its first move has decided what it does), and a pinch is.
    @State private var dragging = false
    @State private var pinching = false

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
                    Toolbar(model: model, time: t, bottom: max(16, safe.safeAreaInsets.bottom + 8, model.keyboard + 8))
                    // iPadOS's own number keyboard (G 19 Oct), up by itself whenever the problem being worked wants a
                    // number written (no tap needed), so a Mac's or a hardware keyboard types straight away too; only for
                    // a box the drawing shows (G 20 Oct): a step answered by the hands never raises it
                    let typing = (model.bars?.current as? WorkProblem).flatMap { w in model.bars?.mode == .work && w.wantsTyping ? w : nil }
                    NumberEntry(problem: typing, step: typing.map { "\($0.id) \($0.lesson.index)" } ?? "")
                        // beside the box being typed into: iPadOS's number pad pops up from it (a docked keyboard
                        // doesn't mind where it is)
                        .offset(typing.flatMap { w in NumberEntry.anchor(w, cam) } ?? .zero)
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
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { n in
                // the keyboard's top, so the camera frames the problem in the paper still showing above it
                guard let f = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                model.keyboardAppeared(max(0, geo.frame(in: .global).maxY - f.minY))
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in model.keyboardAppeared(0) }
        }
        .ignoresSafeArea()
        }
    }

    /// The clock only runs while something moves or draws, so a still paper costs nothing.
    private var animating: Bool {
        model.moving || model.leaving || model.mapDrawing || PaperClock.now - model.pinchedAt < 1.3 || PaperClock.now - model.drawnAt < Piece.drawTime + 0.2 || (model.lesson?.animating ?? false) || (model.bars?.animating ?? false) || (model.steps?.animating ?? false)
    }

    private var surfaceGestures: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 4)
                .onChanged { v in
                    // the drag's first move decides: a hand move on the problem (it took hold of something the child can
                    // move), or the paper panning; a drag that started as a pinch only ever pans
                    if !dragging { dragging = true; if !pinching { model.dragStart(at: .init(v.startLocation.x, v.startLocation.y)) } }
                    if model.handDrag { model.dragMove(to: .init(v.location.x, v.location.y)) }
                    else { model.pan(v.translation.width - lastDrag.width, v.translation.height - lastDrag.height) }
                    lastDrag = v.translation }
                .onEnded { _ in model.dragEnd(); lastDrag = .zero; dragging = false })
            .simultaneousGesture(MagnifyGesture()
                .onChanged { v in
                    pinching = true
                    // a hand holding something on the problem keeps it: the paper doesn't zoom under it
                    guard !model.handDrag else { lastPinch = v.magnification; return }
                    model.zoom(by: v.magnification / lastPinch, at: .init(v.startLocation.x, v.startLocation.y)); lastPinch = v.magnification }
                .onEnded { _ in lastPinch = 1; pinching = false })
            .simultaneousGesture(SpatialTapGesture().onEnded { v in model.tap(at: .init(v.location.x, v.location.y)) })
    }
}

/// Takes typing from iPadOS's keyboard (or a hardware one) for the answer box being filled: digits, the point, delete,
/// and return to check. It shows the number keys while a step wants a number, and puts the keyboard away when not.
struct SystemKeys: UIViewRepresentable {
    let active: Bool
    let type: (String) -> Void
    let enter: () -> Void

    func makeUIView(context: Context) -> KeyView { KeyView() }
    func updateUIView(_ v: KeyView, context: Context) {
        v.type = type; v.enter = enter
        if active && !v.isFirstResponder { DispatchQueue.main.async { v.becomeFirstResponder() } }
        if !active && v.isFirstResponder { DispatchQueue.main.async { v.resignFirstResponder() } }
    }

    final class KeyView: UIView, UIKeyInput {
        var type: (String) -> Void = { _ in }
        var enter: () -> Void = {}
        var keyboardType: UIKeyboardType = .decimalPad
        var autocorrectionType: UITextAutocorrectionType = .no
        var returnKeyType: UIReturnKeyType = .done
        override var canBecomeFirstResponder: Bool { true }
        var hasText: Bool { true }
        func insertText(_ text: String) {
            for ch in text {
                if ch == "\n" { enter() }
                else if ch.isNumber, let d = ch.wholeNumberValue { type(String(d)) }
                else if ch == "." || ch == "," { type(".") }
            }
        }
        func deleteBackward() { type("del") }
    }
}

/// Typing for the answer box (G 19 Oct): a hidden text field, focused while a number is wanted, so the iPad's own
/// number keys come up and a Mac's or hardware keyboard types too. It holds a single space: whatever is typed after it
/// goes to the box, a delete that takes the space is a delete in the box, and it goes back to the space each time.
struct NumberEntry: View {
    let problem: WorkProblem?
    let step: String

    /// Where the hidden field sits on the screen: just past the right end of the box being typed into, level with its
    /// middle, so iPadOS's number pad (a popover on iPadOS 26) comes up beside the box, not over the words.
    @MainActor static func anchor(_ w: WorkProblem, _ cam: PaperCamera) -> CGSize? {
        guard let a = w.lesson.step.answer, let id = w.lesson.active ?? a.boxes.first,
              let r = ProblemLayout.blocks(w).first(where: { $0.kind == .field(id) })?.rect else { return nil }
        let p = cam.toScreen(Point(r.maxX + Paper.cell / 2, r.midY))
        return CGSize(width: p.x, height: p.y)
    }
    @State private var text = " "
    @FocusState private var focused: Bool

    var body: some View {
        TextField("", text: $text)
            .keyboardType(.decimalPad)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($focused)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .allowsHitTesting(false)
            .onChange(of: text) { _, new in
                guard new != " " else { return }
                if new.count < 1 { problem?.type("del") }
                else { for ch in new.dropFirst() { if ch.isNumber, let d = ch.wholeNumberValue { problem?.type(String(d)) } else if ch == "." || ch == "," { problem?.type(".") } } }
                text = " "
            }
            .onSubmit { problem?.go(); focused = problem != nil }
            .onChange(of: step) { _, _ in text = " "; focused = problem != nil }
            .onAppear { focused = problem != nil }
    }
}
