import SwiftUI

/// Setting up, the first time the app opens (G 26 Oct, design/prototype/front-door.html section 1): about a minute, a
/// grown-up and the child together, drawn on the paper like everything else, every piece on its squares. One child per
/// iPad, so there are no profiles.
/// 1. Welcome: a rectangle draws itself in and fills block by block, "Math you can see.", and Start.
/// 2. Name (it can be skipped): typed a letter to a square on a line of squares, with the iPad's keyboard.
/// 3. Grade: K to 12 as a row of blocks; 5th has lessons, the others are dead blocks that only say they're coming soon.
/// 4. For a grown-up: a daily reminder and sound, and how to find the grown-ups' page later.
/// Every step after the welcome has Back, a plain block after the others (G 26 Oct).
/// Done: setting up erases itself and the paper glides down to the map, "Start here, Mia." beside the first lesson.
/// What's picked is saved as it's picked (AppSettings.profile); setting up never shows again once it's done.
@MainActor @Observable
final class SetupPage {
    /// Its top-left corner on the paper: above the map, on the strong lines, so Done glides down to it.
    static let corner = Point(0, -9 * Paper.unit)
    static let u = Paper.unit, c = Paper.cell

    private(set) var step: Setup.Step = .welcome
    /// The name as it's typed (kept as the child's name at Next).
    private(set) var name = ""
    /// The grade block last tapped, whose words show under the row; nil until one is.
    private(set) var gradeSaid: Int?
    /// When this step starts drawing in.
    private(set) var stepAt: Double = 0
    /// Bumped by every change, so its drawing knows to change.
    private(set) var version = 0
    /// Bumped when the name's squares are tapped: the keyboard comes back.
    private(set) var nameTaps = 0

    /// From the welcome, drawing in at `t`.
    func start(at t: Double) { step = .welcome; name = ""; gradeSaid = nil; stepAt = t; version += 1 }
    /// Screenshots only: at this step, with this name typed and this grade tapped.
    func showForShots(_ s: Setup.Step, name n: String = "", gradeSaid g: Int? = nil) { step = s; name = n; gradeSaid = g; stepAt = PaperClock.now - 100; version += 1 }

    /// Typing (NameEntry): kept as a name is (Setup.cleanName), a space between words allowed while it's typed.
    func type(_ raw: String) {
        let clean = Setup.cleanName(raw)
        let typed = raw.last == " " && !clean.isEmpty && clean.count < Setup.nameLength ? clean + " " : clean
        guard typed != name else { return }
        name = typed; version += 1
    }

    // MARK: what it shows

    enum Action: Equatable { case start, next, skip, back, nameBoxes, grade(Int), reminder(Reminder), sound(Bool), done }
    @MainActor struct Sheet {
        var sketch = Sketch()
        var taps: [(rect: CGRect, action: Action)] = []
        var frame = Rect(x: 0, y: 0, width: 1, height: 1)
    }

    func sheet(now: Double) -> Sheet {
        var out = Sheet(), s = Sketch()
        let x0 = Self.corner.x, y0 = Self.corner.y, c = Self.c
        func R(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> CGRect { CGRect(x: x0 + x * c, y: y0 + y * c, width: w * c, height: h * c) }
        switch step {
        case .welcome:
            // the app's idea in one move: a rectangle 6 blocks by 4 strokes on, then fills a block at a time
            let rect = R(0, 0, 30, 20)
            s.startAt = stepAt
            // its squares, over the fills that come under them: the strong lines every 5 a little stronger
            var minor: [(CGPoint, CGPoint)] = [], major: [(CGPoint, CGPoint)] = []
            for i in 1..<30 {
                let x = rect.minX + Double(i) * c, seg = (CGPoint(x: x, y: rect.minY), CGPoint(x: x, y: rect.maxY))
                if i % 5 == 0 { major.append(seg) } else { minor.append(seg) }
            }
            for j in 1..<20 {
                let y = rect.minY + Double(j) * c, seg = (CGPoint(x: rect.minX, y: y), CGPoint(x: rect.maxX, y: y))
                if j % 5 == 0 { major.append(seg) } else { minor.append(seg) }
            }
            s.box("su-rect", rect, .chapter, width: Sketch.stroke)
            s.startAt = stepAt + 0.35
            s.segments("su-minor", minor, .tint(0.3), width: 0.75)
            s.segments("su-major", major, .tint(0.55), width: Sketch.stroke)
            for r in 0..<4 {
                for k in 0..<6 {
                    let i = r * 6 + k
                    s.startAt = stepAt + 0.9 + Double(i) * 0.07
                    s.fill("su-block\(i)", R(Double(k) * 5, Double(r) * 5, 5, 5), .tint(0.2))
                }
            }
            s.startAt = stepAt + 2.8
            s.text("su-title", "Math you can see.", at: CGPoint(x: rect.midX, y: y0 + 22 * c), size: Sketch.maths, weight: .medium, .ink, digits: false)
            s.startAt = stepAt + 3.2
            let start = R(10, 25, 10, 2)
            s.block("su-start", start, .main, word: "Start", arrow: true)
            out.taps.append((start, .start))
            out.frame = Rect(x: rect.minX, y: rect.minY, width: rect.width, height: start.maxY - rect.minY)

        case .name:
            s.words("su-ask-name", "What's your name?", .say, x: x0, top: y0, width: 1200)
            let boxes = s.nameSquares("su-name", name, x: x0, y: y0 + 5 * c, cursor: true)
            out.taps.append((boxes.insetBy(dx: -c / 2, dy: -c / 2), .nameBoxes))
            let next = R(0, 10, 7, 2), skip = R(10, 10, 6, 2)
            s.block("su-next", next, .main, word: "Next", arrow: true)
            s.block("su-skip", skip, .plain, word: "Skip")
            // Back (G 26 Oct, kids mis-tap): a plain block after the others, on the next strong line
            let back = R(20, 10, 6, 2)
            s.block("su-back", back, .plain, word: "Back")
            out.taps += [(next, .next), (skip, .skip), (back, .back)]
            out.frame = Rect(x: x0, y: y0, width: boxes.width, height: next.maxY - y0)

        case .grade:
            s.words("su-ask-grade", Setup.whichGrade(AppSettings.name), .say, x: x0, top: y0, width: 1400)
            // a block 4 squares a side for each grade, each starting on a strong line
            for (rect, g) in s.gradeRow("su-grade", x: x0, y: y0 + 5 * c, side: 4, pitch: 5, chosen: AppSettings.profile.grade, size: Sketch.wordSize) {
                out.taps.append((rect, .grade(g)))
            }
            if let g = gradeSaid {
                s.label("su-said", Grades.picked(g), Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink2), at: CGPoint(x: x0, y: y0 + 11 * c),
                        anchor: UnitPoint(x: 0, y: 0.5), slot: "su-said")
            }
            let next = R(0, 15, 7, 2)
            s.block("su-next", next, .main, word: "Next", arrow: true)
            let back = R(10, 15, 6, 2)
            s.block("su-back", back, .plain, word: "Back")
            out.taps += [(next, .next), (back, .back)]
            out.frame = Rect(x: x0, y: y0, width: 64 * c, height: next.maxY - y0)

        case .grownUp:
            s.words("su-ask-grownup", "For grown-ups", .heading, x: x0, top: y0, width: 1200)
            let p = AppSettings.profile, ask = Sketch.Words.say
            s.words("su-rem", "Daily reminder", ask, x: x0, top: y0 + 5 * c, width: 1200)
            var bx = x0 + 15 * c
            for r in Reminder.allCases {
                let b = CGRect(x: bx, y: y0 + 5 * c, width: GrownUpPage.blockWidth(r.words), height: 2 * c)
                s.block("su-rem-\(r.rawValue)-\(r == p.reminder)", b, r == p.reminder ? GrownUpPage.chosen : GrownUpPage.other, word: r.words)
                out.taps.append((b, .reminder(r))); bx = b.maxX + c
            }
            let right = bx - c
            s.words("su-sound", "Sound", ask, x: x0, top: y0 + 10 * c, width: 1200)
            bx = x0 + 15 * c
            for (word, on) in [("On", true), ("Off", false)] {
                let chosen = AppSettings.sound == on
                let b = CGRect(x: bx, y: y0 + 10 * c, width: GrownUpPage.blockWidth(word), height: 2 * c)
                s.block("su-sound-\(word)-\(chosen)", b, chosen ? GrownUpPage.chosen : GrownUpPage.other, word: word)
                out.taps.append((b, .sound(on))); bx = b.maxX + c
            }
            s.words("su-later", "You can change these later in More › For grown-ups.", Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink2),
                    x: x0, top: y0 + 15 * c, width: 1400)
            let done = R(0, 20, 7, 2)
            s.block("su-done", done, .main, word: "Done", arrow: true)
            let back = R(10, 20, 6, 2)
            s.block("su-back", back, .plain, word: "Back")
            out.taps += [(done, .done), (back, .back)]
            out.frame = Rect(x: x0, y: y0, width: right - x0, height: done.maxY - y0)
        }
        out.sketch = s
        return out
    }

    // MARK: what a tap does

    func tap(_ p: Point, model: PaperModel) {
        let q = CGPoint(x: p.x, y: p.y)
        guard let action = sheet(now: PaperClock.now).taps.first(where: { $0.rect.contains(q) })?.action else { return }
        act(action, model: model)
    }

    func act(_ action: Action, model: PaperModel) {
        let saving = !model.shotMode
        var profile = AppSettings.profile
        switch action {
        case .start: go(.name, model)
        case .nameBoxes: nameTaps += 1
        case .next where step == .name, .skip:
            if action == .skip { name = "" }
            name = Setup.cleanName(name)
            profile.name = name
            AppSettings.set(profile: profile, saving: saving)
            go(.grade, model)
        case .next: go(.grownUp, model)
        case .back:
            // a step back; what was picked stays picked (the name stays typed)
            if step == .name { name = Setup.cleanName(name) }
            go(Setup.Step(rawValue: step.rawValue - 1) ?? .welcome, model)
            if step == .name { name = AppSettings.profile.name }
        case .grade(let g):
            gradeSaid = g
            // only a grade with lessons can be chosen; the others only say they're coming
            if Grades.isLive(g) { profile.grade = g; AppSettings.set(profile: profile, saving: saving) }
        case .reminder(let r):
            profile.reminder = r
            AppSettings.set(profile: profile, saving: saving)
            // the iPad asks once whether to allow it (its own prompt); turned down, it's Off and setting up carries on
            Reminders.set(r, name: profile.name) { [self] ok in
                guard !ok else { return }
                var p = AppSettings.profile; p.reminder = .off
                AppSettings.set(profile: p, saving: saving); version += 1
            }
        case .sound(let on): AppSettings.set(sound: on, saving: saving)
        case .done:
            profile.setUp = true
            AppSettings.set(profile: profile, saving: saving)
            model.finishSetup()
        }
        version += 1
    }

    /// On to the next step: this one erases itself as the next draws in, a moment later, and the camera frames it.
    private func go(_ next: Setup.Step, _ model: PaperModel) {
        step = next; gradeSaid = nil
        stepAt = model.instant ? PaperClock.now - 100 : PaperClock.now + 0.3
        version += 1
        model.reframePlace()
    }
}

extension Sketch {
    /// A name on a line of squares, a letter to a square (G 26 Oct): squares two small squares a side, as many as a name
    /// can have, their lines quiet; the next one to type in outlined in ink while it's being typed. Returns the line.
    @discardableResult
    mutating func nameSquares(_ id: String, _ name: String, x: Double, y: Double, cursor: Bool) -> CGRect {
        let c = Paper.cell, side = 2 * c, n = Setup.nameLength
        let line = CGRect(x: x, y: y, width: Double(n) * side, height: side)
        box("\(id)-line", line, .line, width: Sketch.stroke)
        segments("\(id)-cuts", (1..<n).map { i in (CGPoint(x: x + Double(i) * side, y: y), CGPoint(x: x + Double(i) * side, y: y + side)) }, .line, width: Sketch.stroke)
        for (i, ch) in name.enumerated() where ch != " " {
            text("\(id)-\(i)\(ch)", String(ch), at: CGPoint(x: x + (Double(i) + 0.5) * side, y: y + side / 2), size: Sketch.wordSize, weight: .medium, .ink, digits: false)
        }
        if cursor, name.count < n {
            // its id stays the same as it moves, so it glides to the next square
            let r = CGRect(x: x + Double(name.count) * side, y: y, width: side, height: side).insetBy(dx: Sketch.stroke / 2, dy: Sketch.stroke / 2)
            box("\(id)-at", r, .ink, width: Sketch.stroke)
        }
        return line
    }

    /// The grades K to 12 as a row of blocks (G 26 Oct), `side` squares a side, one every `pitch` squares: the chosen
    /// grade outlined in ink and lightly filled (as the grown-ups' chosen settings are); a grade with lessons plain; the
    /// rest dead, dashed and quiet, until their lessons come. Returns each block and its grade.
    @discardableResult
    mutating func gradeRow(_ id: String, x: Double, y: Double, side: Double, pitch: Double, chosen: Int, size: CGFloat) -> [(CGRect, Int)] {
        let c = Paper.cell
        return Grades.all.map { g in
            let r = CGRect(x: x + Double(g) * pitch * c, y: y, width: side * c, height: side * c)
            if !Grades.isLive(g) {
                box("\(id)-\(g)-dead", r.insetBy(dx: Sketch.stroke / 2, dy: Sketch.stroke / 2), .hex(0xC4C0B8, 0x45443F), width: Sketch.stroke, dashed: true)
                text("\(id)-\(g)-w", Grades.short(g), at: CGPoint(x: r.midX, y: r.midY), size: size, weight: .medium, .ink3, digits: true)
            } else {
                block("\(id)-\(g)-\(g == chosen)", r, g == chosen ? GrownUpPage.chosen : GrownUpPage.other, centred: Grades.short(g), size: size)
            }
            return (r, g)
        }
    }
}

/// Typing a name (setting up): a hidden text field, focused while a name is being typed, so
/// the iPad's own keyboard comes up (or a hardware one types). What's typed goes to the name's squares on the paper.
struct NameEntry: View {
    let model: PaperModel
    @FocusState private var focused: Bool

    var body: some View {
        let active = model.typingName
        TextField("", text: Binding(get: { model.nameDraft }, set: { model.typeName($0) }))
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.next)
            .focused($focused)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .allowsHitTesting(false)
            .onSubmit { model.nameEntered() }
            .onChange(of: active) { _, a in focused = a }
            .onChange(of: model.nameTaps) { _, _ in focused = model.typingName }
            .onAppear { focused = active }
    }
}

extension PaperModel {
    /// A name is being typed: setting up's name step (the island's Settings has a field of its own).
    var typingName: Bool {
        guard bars == nil, !leaving else { return false }
        return place == .setup && setup.step == .name
    }
    var nameDraft: String { setup.name }
    var nameTaps: Int { setup.nameTaps }
    func typeName(_ raw: String) {
        if place == .setup { setup.type(raw) }
    }
    /// Return on the keyboard: setting up goes on to the grade.
    func nameEntered() {
        if place == .setup, setup.step == .name { setup.act(.next, model: self) }
    }
}
