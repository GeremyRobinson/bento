import SwiftUI
import StoreKit

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
    /// The space between its pages as they slide.
    static let gap = 40.0
    /// A pull past the end, as rubber gives: nearly all of a short pull, less and less of a long one, never more than
    /// `size` (the way iPadOS's own scrolling pulls past its edge).
    static func rubber(_ x: Double, _ size: Double) -> Double {
        let d = abs(x); return (1 - 1 / (d * 0.55 / size + 1)) * size * (x < 0 ? -1 : 1)
    }
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
                    // pressed in under the finger while it holds
                    .scaleEffect(holding ? 0.88 : 1)
                    .animation(holding ? Motion.snap : Motion.flick, value: holding)
            }
            .frame(width: 76, height: 76)
            .contentShape(Rectangle().inset(by: -16))
            .gesture(DragGesture(minimumDistance: 0).updating($down) { _, d, _ in d = true })
            .onChange(of: down) { _, d in if d { if !holding { press() } } else { release() } }
            .accessibilityElement()
            .accessibilityLabel("Hold for 3 seconds")
            .accessibilityAddTraits(.isButton)
            Text("For grown-ups").font(Island.key).foregroundStyle(Ink.ink)
            Text(letGo ? "Keep holding" : "Hold for 3 seconds")
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
        withAnimation(Motion.close) { fill = 0; letGo = true }
    }
}

// MARK: the tabs

/// Once the hold is passed: Settings · Privacy · Help · Plan along its top, the tab's words under them. A slider (G 29 Oct:
/// "the shift of page causes the pill to move around"): the island is one height for every tab, the tallest one's (each
/// measured ahead, `IslandMeasure`), so it never resizes on a switch; the pages lie side by side and slide across together,
/// following a finger's swipe, and the capsule behind the tab names glides to the chosen one. A page taller than the
/// screen has room for scrolls inside.
struct IslandTabs: View {
    let model: PaperModel
    /// The most room its words have (the screen above the pill, less the tabs).
    let room: Double
    let width: Double
    private var ui: BarUI { BarUI.shared }
    @Namespace private var tabsSpace
    /// How far a finger has dragged the pages (points; 0 when nothing's held).
    @State private var drag = 0.0
    /// This touch is swiping the pages (not a control's, not up and down).
    @State private var paging = false

    var body: some View {
        let tabs = Island.Tab.allCases, tab = ui.tab
        let index = Double(tabs.firstIndex(of: tab) ?? 0)
        let h = min(room, tabs.compactMap { ui.heights[$0] }.max() ?? room)
        let slide = ui.slow ? Animation.smooth(duration: 3.5) : Motion.open
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(tabs, id: \.self) { t in
                    Button { go(t, slide) } label: {
                        // the words never change (one weight, one colour), only how strongly they show; the capsule
                        // behind them is one shape that glides from tab to tab
                        Text(t.rawValue).font(Typeface.font(16, .semibold)).foregroundStyle(Ink.ink)
                            .opacity(t == tab ? 1 : 0.62)
                            .padding(.horizontal, 14).frame(height: 36)
                            .background {
                                if t == tab { Capsule().fill(Ink.sunk).matchedGeometryEffect(id: "tab", in: tabsSpace) }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(Press(scale: 0.96))
                    .accessibilityAddTraits(t == tab ? .isSelected : [])
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 6)
            Rectangle().fill(Ink.line).frame(height: 1).padding(.horizontal, 10)
            // the pages side by side in a strip, one island wide each, seen through the island's frame: a switch slides
            // the strip, and a finger's drag carries it, the next page coming in beside the one leaving (G 29 Oct: a
            // drag showed an empty gap until let go)
            // a gap between pages (as Photos has), so a page settling in never shows the edge of the last one
            HStack(alignment: .top, spacing: Island.gap) {
                ForEach(tabs, id: \.self) { t in
                    ScrollView {
                        IslandPage(tab: t, model: model).frame(width: width)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .frame(width: width, height: h)
                    .allowsHitTesting(t == tab)
                    .accessibilityHidden(t != tab)
                }
            }
            .offset(x: -index * (width + Island.gap) + drag)
            .frame(width: width, height: h, alignment: .topLeading)
            .clipped()
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { v in
                        // sideways only; the page stays under the finger, and past the first or last page it pulls
                        // like rubber, giving less the further it goes
                        guard !ui.controlHeld, paging || abs(v.translation.width) > abs(v.translation.height) else { return }
                        paging = true
                        let edge = (index == 0 && v.translation.width > 0) || (Int(index) == tabs.count - 1 && v.translation.width < 0)
                        drag = edge ? Island.rubber(v.translation.width, width) : v.translation.width
                    }
                    .onEnded { v in
                        // whatever held this touch, it's let go now
                        ui.controlHeld = false
                        guard paging else { return }
                        paging = false
                        let i = Int(index), past = v.predictedEndTranslation.width
                        let to = past < -width / 4 ? min(i + 1, tabs.count - 1) : past > width / 4 ? max(i - 1, 0) : i
                        // thrown: the pages carry on at the finger's speed for the way left, and settle
                        let left = to == i ? abs(drag) : width + Island.gap - abs(drag)
                        let speed = to == i ? -v.velocity.width * (drag > 0 ? 1 : -1) : abs(v.velocity.width)
                        let throwIt = ui.slow ? slide : Motion.thrown(velocity: speed, distance: left, bounce: to == i ? 0.2 : 0.1)
                        if to == i { withAnimation(throwIt) { drag = 0 } } else { go(tabs[to], throwIt) }
                    })
        }
        .frame(width: width)
    }

    private func go(_ t: Island.Tab, _ slide: Animation) {
        let tabs = Island.Tab.allCases
        guard t != ui.tab else { withAnimation(slide) { drag = 0 }; return }
        ui.tabForward = (tabs.firstIndex(of: t) ?? 0) > (tabs.firstIndex(of: ui.tab) ?? 0)
        ui.askStartOver = false
        withAnimation(slide) { ui.tab = t; drag = 0 }
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
    private var saving: Bool { !model.shotMode }

    // MARK: Settings

    @ViewBuilder private var settings: some View {
        let p = AppSettings.profile
        setting("Name") {
            if measuring { Capsule().frame(width: 180, height: 36) } else { NameField(saving: saving) }
        }
        setting("Grade", ui.islandGrade) {
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
                    .buttonStyle(Press())
                    .accessibilityLabel(Grades.name(g))
                }
            }
        }
        setting("Daily reminder") {
            Choices(options: Reminder.allCases.map { ($0.words.replacingOccurrences(of: " pm", with: ""), $0 == p.reminder) }, label: "Daily reminder") { i in
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
        setting("Sound") {
            OnOff(on: AppSettings.sound, label: "Sound") { on in
                AppSettings.set(sound: on, saving: saving); ui.settingsVersion += 1
            }
        }
        setting("Read aloud") {
            OnOff(on: AppSettings.readAloud, label: "Read aloud") { on in
                AppSettings.set(readAloud: on, saving: saving); ui.settingsVersion += 1
            }
        }
        setting("Appearance", last: true) {
            Choices(options: [("Auto", AppSettings.theme == ""), ("Light", AppSettings.theme == "light"), ("Dark", AppSettings.theme == "dark")], label: "Appearance") { i in
                AppSettings.set(theme: ["", "light", "dark"][i], saving: saving); ui.settingsVersion += 1
            }
        }
        // Start over: set apart at the bottom, and asked first
        Rectangle().fill(Ink.line).frame(height: 1).padding(.top, 14)
        Text("Start over").font(Island.key).foregroundStyle(Ink.ink).padding(.top, 14)
        if ui.askStartOver {
            Text("Erase everything and set up again?").font(Island.body).foregroundStyle(Ink.ink)
                .fixedSize(horizontal: false, vertical: true).padding(.top, 6)
            HStack(spacing: 10) {
                RoundButton(word: "Start over", strong: true) {
                    ui.askStartOver = false; ui.open = nil
                    model.startOver()
                }
                RoundButton(word: "Cancel") { ui.askStartOver = false }
            }
            .padding(.top, 10)
        } else {
            Text("Erases all progress and settings.").font(Island.body).foregroundStyle(Ink.ink2)
                .fixedSize(horizontal: false, vertical: true).padding(.top, 6)
            RoundButton(word: "Start over…", strong: true) { ui.askStartOver = true }.padding(.top, 10)
        }
    }

    /// A setting's row: its name and what it does on the left, its choices on the right, a line under it.
    private func setting<C: View>(_ title: String, _ line: String? = nil, last: Bool = false, @ViewBuilder control: () -> C) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Island.key).foregroundStyle(Ink.ink)
                    if let line { Text(line).font(Island.small).foregroundStyle(Ink.ink2).contentTransition(.opacity) }
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
        // said once, plainly (G 29 Oct: no list of promises)
        heading("Privacy")
        paragraph("\(name.isEmpty ? "Your child's" : name + "'s") name, grade and progress are saved on this iPad and nowhere else.")
        paragraph("Start over, in Settings, erases all of it.")
        link("Privacy policy", tab: .privacy) {
            guard let url = AppInfo.privacyURL else { return false }
            UIApplication.shared.open(url); return true
        }
    }

    // MARK: Help

    @ViewBuilder private var help: some View {
        question("How a lesson works", "Watch the How to, do three problems together, then six alone. Six right opens the lesson test, and 10 of 12 passes it.")
        question("Checks", "A passed lesson comes back for a short check after 3, 7, 21 and 60 days. If a check goes badly, it comes back the next day.")
        question("Resetting a lesson", "On the page behind this, open Lessons and tap the lesson.", line: false)
        link("Email us", tab: .help) {
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

    /// The plan (G 30 Oct, the money plan): All grades, monthly or yearly, a week free to start; or, once it's the
    /// family's, when it renews and where to manage it. Buying is Apple's own sheet (Store).
    @ViewBuilder private var plan: some View {
        let store = Store.shared
        heading("All grades").padding(.top, -8)
        paragraph("Every grade, and every new one as it's made. For every iPad in the family.")
        if let a = store.active {
            let yearly = a.id == Store.yearly
            planRow("Your plan") { Text(yearly ? "Yearly" : "Monthly").font(Island.key).foregroundStyle(Ink.ink) }
            if let d = a.renews {
                paragraph("\(a.willRenew ? "Renews" : "Ends") \(d.formatted(date: .long, time: .omitted)).")
            }
            HStack(spacing: 10) {
                RoundButton(word: "Manage", strong: true) {
                    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                    Task { try? await AppStore.showManageSubscriptions(in: scene) }
                }
                RoundButton(word: "Restore Purchases") { Task { await store.restore() } }
            }
            .padding(.top, 14)
        } else if store.loading == .failed {
            paragraph("Prices didn't load. Check the internet connection and try again.")
            RoundButton(word: "Try again", strong: true) { Task { await store.load() } }.padding(.top, 14)
        } else {
            let id = store.yearly ? Store.yearly : Store.monthly
            let price = store.price(id) ?? "–", per = store.yearly ? "a year" : "a month"
            planRow("Billing") {
                // what yearly saves (G 30 Oct): a green pill, outlined, the paper's own green
                if let save = store.yearlySaving {
                    Text(save).font(Typeface.font(13, .semibold)).foregroundStyle(Ink.right)
                        .padding(.horizontal, 10).frame(height: 26)
                        .overlay(Capsule().strokeBorder(Ink.right, lineWidth: 1.5))
                        .padding(.trailing, 6)
                }
                Choices(options: [("Monthly", !store.yearly), ("Yearly", store.yearly)], segment: 84, label: "Billing") { i in
                    withAnimation(Motion.snap) { store.yearly = i == 1 }
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(price).font(Typeface.font(34, .bold)).monospacedDigit().foregroundStyle(Ink.ink)
                    .contentTransition(.numericText())
                Text(per).font(Island.body).foregroundStyle(Ink.ink2)
                Spacer(minLength: 0)
                if store.yearly, let m = store.yearlyPerMonth {
                    Text("About \(m) a month").font(Island.small).foregroundStyle(Ink.ink2).transition(.opacity)
                }
            }
            .padding(.top, 12)
            .animation(Motion.snap, value: store.yearly)
            RoundButton(word: store.buying ? "One moment…" : store.trialOffered ? "Try 7 days free" : "Subscribe", strong: true) {
                Task { await store.buy(id) }
            }
            .disabled(store.buying || store.loading != .ready)
            .padding(.top, 14)
            Text(store.trialOffered ? "Free for 7 days, then \(price) \(per). Cancel any time in Settings." : "\(price) \(per). Cancel any time in Settings.")
                .font(Island.small).foregroundStyle(Ink.ink2).padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
            Text("The first chapter of every grade stays free.").font(Island.small).foregroundStyle(Ink.ink2).padding(.top, 2)
        }
        if let said = store.said {
            Text(said).font(Island.small).foregroundStyle(Ink.ink).padding(.top, 10).fixedSize(horizontal: false, vertical: true)
        }
        // what Apple asks a subscription to show: restore, the terms, the privacy policy
        HStack(spacing: 18) {
            if store.active == nil { smallLink("Restore Purchases") { Task { await store.restore() } } }
            smallLink("Terms of Use") {
                if let u = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") { UIApplication.shared.open(u) }
            }
            smallLink("Privacy Policy") {
                if let u = AppInfo.privacyURL { UIApplication.shared.open(u) } else { ui.said[.plan] = "Coming soon." }
            }
        }
        .padding(.top, 18)
        if let said = ui.said[.plan] { Text(said).font(Island.small).foregroundStyle(Ink.ink2).padding(.top, 6) }
        // builds from Xcode have every chapter open (G's daughter keeps everything); this shows them as a new family sees
        // them, to try the locks. Never in an App Store build.
        if Store.fromXcode {
            Rectangle().fill(Ink.line).frame(height: 1).padding(.top, 18)
            planRow("Preview as a new family") {
                OnOff(on: store.previewLocked, label: "Preview as a new family") { on in store.previewLocked = on; ui.settingsVersion += 1 }
            }
            Text("Only in builds from Xcode. Locks every chapter after the first, the way a family without the plan sees it.")
                .font(Island.small).foregroundStyle(Ink.ink2).padding(.top, 4).fixedSize(horizontal: false, vertical: true)
        }
    }

    /// A row of the plan: its name on the left, what it is on the right.
    private func planRow<C: View>(_ title: String, @ViewBuilder _ right: () -> C) -> some View {
        HStack {
            Text(title).font(Island.key).foregroundStyle(Ink.ink)
            Spacer(minLength: 8)
            right()
        }
        .padding(.top, 16)
    }

    private func smallLink(_ word: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(word).font(Island.small).foregroundStyle(Ink.ink2).underline() }.buttonStyle(Press())
    }

    // MARK: pieces

    private func heading(_ s: String) -> some View { Text(s).font(Island.heading).foregroundStyle(Ink.ink).padding(.top, 18) }
    private func paragraph(_ s: String) -> some View {
        Text(s).font(Island.body).foregroundStyle(Ink.ink2).lineSpacing(3).fixedSize(horizontal: false, vertical: true).padding(.top, 6)
    }

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
    /// Every segment's width, the same for each, so the thumb slides a whole segment at a time.
    var segment: Double = 64
    /// What it sets, said by VoiceOver (and found by the real-touch tests).
    var label = ""
    let pick: (Int) -> Void
    /// A slider (G 29 Oct): one raised thumb under the chosen word. It's a thing the finger holds: dragged, it follows the
    /// finger exactly; let go, it's thrown to the nearest word at the finger's speed and settles there with a little
    /// give (G 29 Oct: springs, so it moves like something real). A tap sends it to the word tapped.
    @State private var finger: Double?
    @State private var pressed = false

    var body: some View {
        let picked = options.firstIndex(where: \.1) ?? 0, last = Double(options.count - 1) * segment
        let x = finger ?? Double(picked) * segment
        let near = max(0, min(options.count - 1, Int((x / segment).rounded())))
        ZStack(alignment: .leading) {
            Capsule().fill(Self.raised).shadow(color: .black.opacity(0.12), radius: 1.5, y: 1)
                .frame(width: segment, height: 32)
                .scaleEffect(pressed ? 0.95 : 1)
                .offset(x: x)
            HStack(spacing: 0) {
                ForEach(options.indices, id: \.self) { i in
                    // one weight and colour (a choice never changes width as it's picked); the one under the thumb full strength
                    Text(options[i].0).font(Typeface.font(15, .semibold)).lineLimit(1).fixedSize()
                        .foregroundStyle(Ink.ink).opacity(i == near ? 1 : 0.55)
                        .frame(width: segment, height: 32)
                }
            }
            .animation(Motion.snap, value: near)
        }
        .padding(3)
        .background(Ink.sunk, in: Capsule())
        .contentShape(Capsule())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { v in
                if !pressed { withAnimation(Motion.snap) { pressed = true } }
                BarUI.shared.controlHeld = true
                guard finger != nil || abs(v.translation.width) > 4 else { return }
                // held on the thumb, it moves with the finger; held beside it, it comes to the finger first
                let onThumb = abs(v.startLocation.x - 3 - (Double(picked) + 0.5) * segment) < segment / 2
                let to = min(last, max(0, onThumb ? Double(picked) * segment + v.translation.width : v.location.x - 3 - segment / 2))
                if finger == nil && !onThumb { withAnimation(Motion.snap) { finger = to } } else { finger = to }
            }
            .onEnded { v in
                let from = finger ?? Double(picked) * segment
                // a tap: the word tapped; a drag: where the throw would carry it
                let landing = finger == nil ? v.location.x - 3 - segment / 2 : from + (v.predictedEndTranslation.width - v.translation.width) / 2
                let i = max(0, min(options.count - 1, Int((landing / segment).rounded())))
                let distance = Double(i) * segment - from
                let move = finger == nil ? Motion.flick
                    : Motion.thrown(velocity: distance >= 0 ? v.velocity.width : -v.velocity.width, distance: abs(distance), bounce: 0.24)
                BarUI.shared.controlHeld = false
                withAnimation(move) { finger = nil; pressed = false; pick(i) }
            })
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityIdentifier("slider-\(label)")
        .accessibilityValue(options[picked].0)
        .accessibilityAdjustableAction { d in
            let i = d == .increment ? min(picked + 1, options.count - 1) : max(picked - 1, 0)
            withAnimation(Motion.flick) { pick(i) }
        }
    }
}

/// On or off (G 29 Oct): a switch. On is the ink track; off the sunken one. Its knob is a thing the finger holds: touched,
/// it stretches a little toward the middle the way a fingertip presses it; dragged, it follows the finger and the track
/// changes as it crosses the middle; let go (or tapped), it's flicked to its end with a little bounce.
struct OnOff: View {
    let on: Bool
    /// What it turns on, said by VoiceOver (and found by the real-touch tests).
    var label = ""
    let set: (Bool) -> Void
    @State private var finger: Double?
    @State private var pressed = false
    /// How far the knob travels: the track less the knob and its 3 points each side.
    private static let travel = 54.0 - 26 - 6
    var body: some View {
        let travel = Self.travel, x = finger ?? (on ? travel : 0)
        let shown = finger.map { $0 > travel / 2 } ?? on
        let stretch = pressed ? 7.0 : 0
        ZStack(alignment: .leading) {
            Capsule().fill(shown ? Ink.ink : Ink.sunk)
            Capsule().fill(Choices.raised).shadow(color: .black.opacity(0.18), radius: 1.5, y: 1)
                .frame(width: 26 + stretch, height: 26)
                // stretched, it grows toward the middle, never past the track's end
                .offset(x: min(x, travel - stretch))
                .padding(3)
        }
        .frame(width: 54, height: 32)
        .animation(Motion.snap, value: shown)
        .contentShape(Capsule())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { v in
                if !pressed { withAnimation(Motion.snap) { pressed = true } }
                BarUI.shared.controlHeld = true
                guard finger != nil || abs(v.translation.width) > 4 else { return }
                finger = min(travel, max(0, (on ? travel : 0) + v.translation.width))
            }
            .onEnded { v in
                // a tap flips it; a drag goes the way it was thrown
                let to = finger.map { $0 + (v.predictedEndTranslation.width - v.translation.width) / 2 > travel / 2 } ?? !on
                BarUI.shared.controlHeld = false
                withAnimation(Motion.flick) { set(to); finger = nil; pressed = false }
            })
        .accessibilityElement()
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(label)
        .accessibilityIdentifier("switch-\(label)")
        .accessibilityValue(on ? "On" : "Off")
        .accessibilityAction { withAnimation(Motion.flick) { set(!on) } }
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
        .buttonStyle(Press())
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
