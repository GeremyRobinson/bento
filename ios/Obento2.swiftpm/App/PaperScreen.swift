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
                let t = PaperClock.frozen ?? ctx.date.timeIntervalSinceReferenceDate
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
                    Toolbar(model: model, time: t, bottom: max(16, safe.safeAreaInsets.bottom + 8, model.keyboard + 8))
                    // the problem's sounds, and its words read aloud when the grown-ups asked for that
                    Listener(model: model)
                    // iPadOS's own number keyboard (G 19 Oct), up by itself whenever the problem being worked wants a
                    // number written (no tap needed), so a Mac's or a hardware keyboard types straight away too; only for
                    // a box the drawing shows (G 20 Oct): a step answered by the hands never raises it; a box tapped
                    // brings the keys back
                    let typing = typingProblem
                    NumberEntry(problem: typing, step: typing.map { "\($0.id) \($0.lesson.index) \(($0 as? WorkProblem)?.boxTapped ?? 0)" } ?? "")
                        // iPadOS's number pad pops up from the hidden field: for a problem laid out stacked it sits in the
                        // screen's bottom-right corner, clear of the picture and the record (as the paper lessons have it)
                        .position(NumberEntry.anchor(screen: model.screen, bottom: max(16, safe.safeAreaInsets.bottom + 8), stacked: typing?.stacked ?? true))
                }
                .onChange(of: t) { _, now in Perf.frame(now); model.settle(at: now); model.lesson?.settle(at: now) }
            }
            .onAppear {
                model.screen = Size(geo.size.width, geo.size.height)
                model.setReduceMotion(UIAccessibility.isReduceMotionEnabled)
                if !Shots.active { model.frameGroup(duration: 0); model.beginStartHere() }
                Shots.run(model)
            }
            // leaving the app with a finger down: no hold carries on (the grown-ups' square opens only for a real 3 seconds)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in model.pressEnded() }
            .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)) { _ in
                model.setReduceMotion(UIAccessibility.isReduceMotionEnabled)
            }
            .onChange(of: geo.size) { _, s in model.screen = Size(s.width, s.height) }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { n in
                // the keyboard's top, so the camera frames the problem in the paper still showing above it; only a
                // keyboard docked across the bottom counts (iPadOS's floating number pad covers just its corner)
                guard let f = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                let screen = geo.frame(in: .global)
                let docked = f.width >= screen.width * 0.8 && f.maxY >= screen.maxY - 1
                // a paper lesson's camera then frames its record above it (WorkProblem.stageFrame)
                WorkProblem.keyboard = docked ? max(0, screen.maxY - f.minY) : 0
                model.keyboardAppeared(WorkProblem.keyboard)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in WorkProblem.keyboard = 0; model.keyboardAppeared(0) }
        }
        .ignoresSafeArea()
        }
    }

    /// The problem being worked that wants a typed number now (NumberTyping.wantsTyping): a typed step's, or Volume of a
    /// box's record.
    private var typingProblem: (any NumberTyping)? {
        guard let page = model.bars, page.mode == .work, let p = page.current as? any NumberTyping else { return nil }
        return p.wantsTyping ? p : nil
    }

    /// The clock only runs while something moves or draws, so a still paper costs nothing.
    private var animating: Bool {
        model.moving || model.leaving || model.mapDrawing || model.placeDrawing || PaperClock.now - model.placeAt < 2.5 || model.grownUp.animating
            || (model.startHere?.playing(at: PaperClock.now) ?? false)
            || PaperClock.now - model.pinchedAt < 1.3 || PaperClock.now - model.drawnAt < Piece.drawTime + 0.2 || (model.lesson?.animating ?? false) || (model.bars?.animating ?? false)
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
            // a finger down, from the moment it touches (a tap or a drag is only known later): the grown-ups' hold
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { v in model.press(at: .init(v.location.x, v.location.y)) }
                .onEnded { _ in model.pressEnded() })
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
    let problem: (any NumberTyping)?
    let step: String

    /// Where the hidden field sits on the screen. iPadOS's number pad (a popover on iPadOS 26) comes up from it. A paper
    /// lesson (stacked): the bottom-right corner, just over the floating bar, the record's empty right-hand side, so the
    /// pad never covers the picture, the words, the box or Check. The lessons not moved yet (their words beside the box,
    /// Check under it): the top-right corner.
    static func anchor(screen: Size, bottom: Double, stacked: Bool) -> CGPoint {
        stacked ? CGPoint(x: screen.width - 48, y: screen.height - bottom - 76) : CGPoint(x: screen.width - 48, y: 32)
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
