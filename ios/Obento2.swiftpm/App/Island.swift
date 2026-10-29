import SwiftUI

/// Where the app's own pages live for now: placeholders until G has them (G, 29 Oct). While one is nil, its block says
/// "Coming soon." instead of opening anything.
enum AppInfo {
    /// The privacy policy's web page.
    static let privacyURL: URL? = nil
    /// Where "Email us" writes to.
    static let supportEmail: String? = nil
    /// The app's version, from the bundle: "0.1 (1)".
    static var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let short = info["CFBundleShortVersionString"] as? String ?? "–", build = info["CFBundleVersion"] as? String ?? ""
        return build.isEmpty || build == short ? short : "\(short) (\(build))"
    }
}

/// The island (G approved 29 Oct, design/prototype/island.html): what a grown-up reads or sets grows out of the pill,
/// the way ⋯ More does, and shrinks back into it. The paper keeps the maths and the progress pictures; the island is the
/// app itself (settings, privacy, help, and later the plan), behind the same 3-second hold, never in front of the child.
enum Island {
    enum Tab: String, CaseIterable { case settings = "Settings", privacy = "Privacy", help = "Help", plan = "Plan" }
    /// Its width: a readable column of words (at most 556 points) with room round it.
    static func width(screen: Double) -> Double { min(600, screen - 48) }
    /// The words' sizes in it.
    static let body = Typeface.font(17), small = Typeface.font(15), key = Typeface.font(17, .semibold), heading = Typeface.font(20, .semibold)
}

// MARK: the hold

/// The hold, inside the island (⋯ More's "For grown-ups"): a square in a ring that fills while it's held down, 3
/// seconds, with the child's paper still behind. Let go too soon, the ring empties and it says to keep holding.
struct IslandGate: View {
    let opened: () -> Void
    @State private var fill: CGFloat = 0
    @State private var holding = false
    @State private var letGo = false
    @State private var timer: Task<Void, Never>?
    /// A finger is on the square: false again when it lifts or the touch is cancelled (onEnded hears only a lift).
    @GestureState private var down = false
    private var ui: BarUI { BarUI.shared }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().stroke(Ink.sunk, lineWidth: 6)
                Circle().trim(from: 0, to: ui.shotFill ?? fill).stroke(Ink.ink, style: StrokeStyle(lineWidth: 6, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
                Rectangle().strokeBorder(Ink.ink, lineWidth: 1.5).frame(width: 30, height: 30)
                    .background(holding ? Ink.sunk : .clear)
            }
            .frame(width: 76, height: 76)
            .contentShape(Rectangle().inset(by: -16))
            .gesture(DragGesture(minimumDistance: 0).updating($down) { _, d, _ in d = true })
            .onChange(of: down) { _, d in if d { if !holding { press() } } else { release() } }
            .accessibilityElement()
            .accessibilityLabel("Hold for 3 seconds")
            .accessibilityAddTraits(.isButton)
            Text("For grown-ups").font(Island.key).foregroundStyle(Ink.ink)
            Text(letGo ? "Keep holding until the ring is full." : "Hold the square for 3 seconds.")
                .font(Island.small).foregroundStyle(Ink.ink2)
                .contentTransition(.opacity)
        }
        .padding(.vertical, 24)
        .frame(width: 360)
        .onDisappear { timer?.cancel() }
    }

    private func press() {
        holding = true
        // how long is left, from how full the ring is now (an early let go may not have emptied it yet)
        let left = GrownUpPage.hold * (1 - fill)
        withAnimation(.linear(duration: left)) { fill = 1 }
        timer = Task { @MainActor in
            try? await Task.sleep(for: .seconds(left + 0.05))
            guard !Task.isCancelled, holding else { return }
            holding = false
            opened()
        }
    }
    private func release() {
        guard holding else { return }
        holding = false; timer?.cancel()
        withAnimation(.easeOut(duration: 0.35)) { fill = 0; letGo = true }
    }
}

// MARK: the tabs

/// Once the hold is passed: Settings · Privacy · Help · Plan along its top, the tab's words under them, scrolling inside
/// when they're taller than the screen has room for. Each tab's height is measured ahead (`IslandMeasure`), so a tab
/// switch resizes the island in one spring while the words cross-fade.
struct IslandTabs: View {
    let model: PaperModel
    /// The most room its words have (the screen above the pill, less the tabs).
    let room: Double
    let width: Double
    private var ui: BarUI { BarUI.shared }

    var body: some View {
        let tab = ui.tab, h = min(room, ui.heights[tab] ?? room)
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(Island.Tab.allCases, id: \.self) { t in
                    Button { ui.tab = t; ui.askStartOver = false } label: {
                        // the words never change (one weight, one colour), only how strongly they show, and the capsule
                        // behind fades in: a switch never re-lays the words out mid-spring
                        Text(t.rawValue).font(Typeface.font(16, .semibold)).foregroundStyle(Ink.ink)
                            .opacity(t == tab ? 1 : 0.62)
                            .padding(.horizontal, 14).frame(height: 36)
                            .background(Capsule().fill(Ink.sunk).opacity(t == tab ? 1 : 0))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(t == tab ? .isSelected : [])
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 6)
            Rectangle().fill(Ink.line).frame(height: 1).padding(.horizontal, 10)
            ScrollView {
                // the old tab's words go quickly and the new ones come just after, so the two barely overlap while the
                // island eases to the new height
                IslandPage(tab: tab, model: model)
                    .id(tab)
                    .transition(.asymmetric(insertion: .opacity.animation(.easeIn(duration: ui.slow ? 2 : 0.2).delay(ui.slow ? 1 : 0.1)),
                                            removal: .opacity.animation(.easeOut(duration: ui.slow ? 1.2 : 0.12))))
                    .frame(width: width)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(width: width, height: h)
        }
        .frame(width: width)
    }
}

/// Every tab laid out unseen at the island's width, so its height is known before it's shown (the island then grows or
/// shrinks to it in one spring, with no jump when the words arrive).
struct IslandMeasure: View {
    let model: PaperModel
    let width: Double
    /// What can change a tab's height: the settings, a question asked, a "Coming soon." said, the name.
    let key: String
    private var ui: BarUI { BarUI.shared }
    var body: some View {
        ZStack(alignment: .top) {
            ForEach(Island.Tab.allCases, id: \.self) { t in
                IslandPage(tab: t, model: model, measuring: true)
                    .frame(width: width)
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: Double.self) { $0.size.height } action: { h in
                        if abs((ui.heights[t] ?? 0) - h) > 0.5 { ui.heights[t] = h }
                    }
            }
        }
        .hidden()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A tab's words and controls.
struct IslandPage: View {
    let tab: Island.Tab
    let model: PaperModel
    /// Laid out unseen to be measured: the same size, no text field.
    var measuring = false
    private var ui: BarUI { BarUI.shared }

    var body: some View {
        let _ = ui.settingsVersion
        VStack(alignment: .leading, spacing: 0) {
            switch tab {
            case .settings: settings
            case .privacy: privacy
            case .help: help
            case .plan: plan
            }
        }
        .padding(.horizontal, 22).padding(.top, 8).padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var name: String { AppSettings.name }
    /// "Mia" or "your child" (Your child's at the start of a line).
    private var child: String { name.isEmpty ? "your child" : name }
    private var saving: Bool { !model.shotMode }

    // MARK: Settings

    @ViewBuilder private var settings: some View {
        let p = AppSettings.profile
        setting("Name", "Shown in \u{201C}Start here\u{201D} and on Me") {
            if measuring { Capsule().frame(width: 180, height: 36) } else { NameField(saving: saving) }
        }
        setting("Grade", ui.islandGrade ?? "Only 5th grade so far") {
            HStack(spacing: 3) {
                ForEach(Grades.all, id: \.self) { g in
                    let here = g == p.grade, live = Grades.isLive(g)
                    Button {
                        ui.islandGrade = Grades.onMe(g).replacingOccurrences(of: ".", with: "")
                        if live { var q = AppSettings.profile; q.grade = g; AppSettings.set(profile: q, saving: saving) }
                        ui.settingsVersion += 1
                    } label: {
                        Text(Grades.short(g)).font(Typeface.font(12, here ? .bold : .medium)).monospacedDigit()
                            .frame(width: 26, height: 26)
                            .background(here ? Ink.sunk : .clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(here ? Ink.ink : Ink.ink3, style: StrokeStyle(lineWidth: here ? 1.5 : 1, dash: live ? [] : [3, 2])))
                            .foregroundStyle(here || live ? Ink.ink : Ink.ink3)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Grades.name(g))
                }
            }
        }
        setting("Daily reminder", "A note on the iPad") {
            Choices(options: Reminder.allCases.map { ($0.words.replacingOccurrences(of: " pm", with: ""), $0 == p.reminder) }) { i in
                let r = Reminder.allCases[i]
                var q = AppSettings.profile; q.reminder = r
                AppSettings.set(profile: q, saving: saving); ui.settingsVersion += 1
                // the iPad asks once whether to allow it (its own prompt); turned down, it's Off again
                Reminders.set(r, name: q.name) { ok in
                    guard !ok else { return }
                    var o = AppSettings.profile; o.reminder = .off
                    AppSettings.set(profile: o, saving: saving); BarUI.shared.settingsVersion += 1
                }
            }
        }
        setting("Sound", "Soft sounds for right and wrong") {
            Choices(options: [("On", AppSettings.sound), ("Off", !AppSettings.sound)]) { i in
                AppSettings.set(sound: i == 0, saving: saving); ui.settingsVersion += 1
            }
        }
        setting("Read aloud", "Reads out each step's words") {
            Choices(options: [("On", AppSettings.readAloud), ("Off", !AppSettings.readAloud)]) { i in
                AppSettings.set(readAloud: i == 0, saving: saving); ui.settingsVersion += 1
            }
        }
        setting("Paper", "Light or dark", last: true) {
            Choices(options: [("Match iPad", AppSettings.theme == ""), ("Light", AppSettings.theme == "light"), ("Dark", AppSettings.theme == "dark")]) { i in
                AppSettings.set(theme: ["", "light", "dark"][i], saving: saving); ui.settingsVersion += 1
            }
        }
        // Start over: set apart at the bottom, and asked first
        Rectangle().fill(Ink.line).frame(height: 1).padding(.top, 14)
        Text("Start over").font(Island.key).foregroundStyle(Ink.ink).padding(.top, 14)
        if ui.askStartOver {
            Text("Wipe every lesson, test, review and setting, and set up again?").font(Island.body).foregroundStyle(Ink.ink)
                .fixedSize(horizontal: false, vertical: true).padding(.top, 6)
            HStack(spacing: 10) {
                RoundButton(word: "Start over", strong: true) {
                    ui.askStartOver = false; ui.open = nil
                    model.startOver()
                }
                RoundButton(word: "Keep") { ui.askStartOver = false }
            }
            .padding(.top, 10)
        } else {
            Text("Wipes every lesson, test, review and setting, and sets up again. It asks first.").font(Island.body).foregroundStyle(Ink.ink2)
                .fixedSize(horizontal: false, vertical: true).padding(.top, 6)
            RoundButton(word: "Start over…", strong: true) { ui.askStartOver = true }.padding(.top, 10)
        }
    }

    /// A setting's row: its name and what it does on the left, its choices on the right, a line under it.
    private func setting<C: View>(_ title: String, _ line: String, last: Bool = false, @ViewBuilder control: () -> C) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Island.key).foregroundStyle(Ink.ink)
                    Text(line).font(Island.small).foregroundStyle(Ink.ink2).contentTransition(.opacity)
                }
                Spacer(minLength: 8)
                control()
            }
            .padding(.vertical, 12)
            if !last { Rectangle().fill(Ink.line).frame(height: 1) }
        }
    }

    // MARK: Privacy

    @ViewBuilder private var privacy: some View {
        Text(name.isEmpty ? "Your child's privacy" : "\(name)'s privacy").font(Island.heading).foregroundStyle(Ink.ink).padding(.top, 10)
        VStack(alignment: .leading, spacing: 10) {
            ForEach(["Everything stays on this iPad.", "No ads, ever.", "No tracking.", "No account needed."], id: \.self) { line in
                HStack(spacing: 12) {
                    // a small square with a square in it: the paper's own tick
                    Rectangle().strokeBorder(Ink.ink, lineWidth: 1.5).frame(width: 16, height: 16)
                        .overlay(Rectangle().fill(Ink.ink).frame(width: 7, height: 7))
                    Text(line).font(Island.key).foregroundStyle(Ink.ink)
                }
            }
        }
        .padding(.top, 10)
        heading("What the app keeps")
        paragraph("\(cap(name.isEmpty ? "your child's" : name + "'s")) name, grade, settings, and how each lesson went: checks, tests, the daily review, and how long was spent practising each day. It's saved only on this iPad, and Start over wipes all of it.")
        heading("What it never does")
        paragraph("It never sends anything about \(child) anywhere, never shows ads, and never asks for an email or a password.")
        link("Read the full policy →", tab: .privacy) {
            guard let url = AppInfo.privacyURL else { return false }
            UIApplication.shared.open(url); return true
        }
    }

    // MARK: Help

    @ViewBuilder private var help: some View {
        question("How does a lesson work?", "Watch the How to, solve three together, then six on your own. Six right opens the lesson test; 10 of 12 and it's learned.")
        question("Why do lessons come back?", "A learned lesson comes back for a short check after 3, 7, 21 and 60 days, and the next day after a low one, so it stays learned.")
        question("How do I reset one lesson?", "On the grown-ups' paper, open Lessons and tap the lesson.")
        question("Still stuck?", "We read every message.", line: false)
        link("Email us →", tab: .help) {
            guard let email = AppInfo.supportEmail, let url = URL(string: "mailto:\(email)") else { return false }
            UIApplication.shared.open(url); return true
        }
        Text("Version \(AppInfo.version)").font(Island.small).foregroundStyle(Ink.ink3).padding(.top, 18)
    }

    private func question(_ q: String, _ a: String, line: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(q).font(Island.key).foregroundStyle(Ink.ink)
            Text(a).font(Island.body).foregroundStyle(Ink.ink2).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) { if line { Rectangle().fill(Ink.line).frame(height: 1) } }
    }

    // MARK: Plan

    @ViewBuilder private var plan: some View {
        VStack(spacing: 8) {
            Text("How the app is paid for").font(Island.heading).foregroundStyle(Ink.ink)
            Text("Coming later, once we decide. A purchase would always appear here, behind the hold, never in front of \(child).")
                .font(Island.body).foregroundStyle(Ink.ink2).multilineTextAlignment(.center).lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: pieces

    private func heading(_ s: String) -> some View { Text(s).font(Island.heading).foregroundStyle(Ink.ink).padding(.top, 18) }
    private func paragraph(_ s: String) -> some View {
        Text(s).font(Island.body).foregroundStyle(Ink.ink2).lineSpacing(3).fixedSize(horizontal: false, vertical: true).padding(.top, 6)
    }
    private func cap(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }

    /// A way out of the app (the policy's page, an email): while its address isn't there yet (AppInfo), it says
    /// "Coming soon." instead of opening anything.
    private func link(_ word: String, tab: Island.Tab, open: @escaping () -> Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundButton(word: word, strong: true) { if !open() { ui.said[tab] = "Coming soon." } }
            if let said = ui.said[tab] { Text(said).font(Island.small).foregroundStyle(Ink.ink2).transition(.opacity) }
        }
        .padding(.top, 14)
    }
}

/// The island's choices, the pill's own: a row of rounded segments in a sunk capsule, the chosen one raised.
struct Choices: View {
    /// The chosen segment: the pill's own white on the light paper, a lifted grey on the dark.
    static let raised = Ink.dynamic(0xFFFFFF, 0x3A3A37)
    let options: [(String, Bool)]
    let pick: (Int) -> Void
    var body: some View {
        HStack(spacing: 2) {
            ForEach(options.indices, id: \.self) { i in
                let (word, here) = options[i]
                Button { pick(i) } label: {
                    // one weight and colour (a choice never changes width as it's picked): the chosen one full strength, on
                    // a raised capsule that fades in
                    Text(word).font(Typeface.font(15, .semibold)).lineLimit(1).fixedSize()
                        .foregroundStyle(Ink.ink).opacity(here ? 1 : 0.55)
                        .padding(.horizontal, 12).frame(height: 32)
                        .background(Capsule().fill(Self.raised).shadow(color: .black.opacity(0.12), radius: 1.5, y: 1).opacity(here ? 1 : 0))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(word)
                .accessibilityAddTraits(here ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Ink.sunk, in: Capsule())
    }
}

/// A rounded button in the island: outlined in ink when it's the one to press.
struct RoundButton: View {
    let word: String
    var strong = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(word).font(Typeface.font(16, .semibold)).foregroundStyle(Ink.ink)
                .padding(.horizontal, 18).frame(height: 40)
                .overlay(Capsule().strokeBorder(strong ? Ink.ink : Ink.lineStrong, lineWidth: 1.5))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// The child's name in the island: typed in place, kept as it's typed (Setup.cleanName, a space between words allowed).
struct NameField: View {
    let saving: Bool
    @State private var draft = ""
    @FocusState private var focused: Bool
    var body: some View {
        let _ = BarUI.shared.settingsVersion
        // the name as it's kept, until it's being typed
        let text = Binding(get: { focused ? draft : AppSettings.name }, set: { draft = $0 })
        TextField("", text: text, prompt: Text("No name").foregroundStyle(Ink.ink3))
            .font(Typeface.font(16, .semibold)).foregroundStyle(Ink.ink)
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.words).autocorrectionDisabled()
            .submitLabel(.done)
            .focused($focused)
            .padding(.horizontal, 14).frame(width: 180, height: 36)
            .background(Ink.sunk, in: Capsule())
            .overlay(Capsule().strokeBorder(focused ? Ink.ink : .clear, lineWidth: 1.5))
            .accessibilityLabel("Name")
            .onChange(of: focused) { _, on in if on { draft = AppSettings.name } }
            .onChange(of: draft) { _, raw in
                guard focused else { return }
                let clean = Setup.cleanName(raw)
                let shown = raw.last == " " && !clean.isEmpty && clean.count < Setup.nameLength ? clean + " " : clean
                if shown != raw { draft = shown }
                guard clean != AppSettings.name else { return }
                var p = AppSettings.profile; p.name = clean
                AppSettings.set(profile: p, saving: saving)
                BarUI.shared.settingsVersion += 1
            }
            .onSubmit { focused = false }
    }
}
