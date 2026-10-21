import SwiftUI

/// The grown-ups' page (G 20 Oct), drawn on the paper like everything else, reached from the bar's ⋯ More. It's shut
/// behind a simple gate: a square held down for 3 seconds while a ring around it fills (no maths question a child could
/// answer). Open, it shows each lesson's last check, its best and when it comes back; a lesson, or everything, can be
/// reset, confirmed on the paper (never a pop-up); and the settings: sound, read aloud, and the paper's colours (as the
/// iPad is set, light or dark). It shuts again whenever it's left.
@MainActor @Observable
final class GrownUpPage {
    /// Its top-left corner on the paper: left of Me, on the strong lines.
    static let corner = Point(-32 * Paper.unit, 0)
    static let u = Paper.unit, c = Paper.cell
    /// How long the square is held to open it.
    static let hold = 3.0

    /// Open once a grown-up has held the square down for 3 seconds.
    private(set) var open = false
    /// When the finger went down on the square (nil: it isn't held).
    private(set) var heldAt: Double?
    /// Let go too soon: when, and how full the ring was (it empties again), and a word to keep holding.
    private(set) var letGoAt: Double?
    private var letGoFill = 0.0
    /// What it's asking to confirm on the paper: one lesson's reset, or everything's.
    enum Confirm: Equatable { case lesson(String), all }
    private(set) var confirm: Confirm?
    /// Bumped by every change it makes (a reset, a setting), so its drawing knows to change.
    private(set) var version = 0

    /// Shut again (each time the page is arrived at).
    func shut() { open = false; heldAt = nil; letGoAt = nil; letGoFill = 0; confirm = nil }

    // MARK: the hold

    /// Where the square is.
    var square: CGRect { CGRect(x: Self.corner.x, y: Self.corner.y + 2 * Self.u, width: 2 * Self.u, height: 2 * Self.u) }

    /// How full the ring is at `t` (0 to 1): filling while held, emptying for a moment after an early let go.
    func fill(at t: Double) -> Double {
        if open { return 1 }
        if let k = shotFill { return k }
        if let h = heldAt { return min(1, max(0, (t - h) / Self.hold)) }
        if let l = letGoAt { return letGoFill * (1 - ease((t - l) / 0.35)) }
        return 0
    }
    /// The ring is filling or emptying: the clock keeps running.
    var animating: Bool { heldAt != nil || letGoAt.map { PaperClock.now - $0 < 2.6 } ?? false }
    var holding: Bool { heldAt != nil }

    /// A finger came down at paper point `p`: on the square, the hold starts. True when it did.
    @discardableResult
    func press(_ p: Point, at t: Double) -> Bool {
        guard !open, heldAt == nil, square.contains(CGPoint(x: p.x, y: p.y)) else { return false }
        heldAt = t; letGoAt = nil
        return true
    }
    /// The finger moved: off the square, the hold is let go.
    func moved(_ p: Point, at t: Double) {
        guard heldAt != nil, !square.insetBy(dx: -Self.c, dy: -Self.c).contains(CGPoint(x: p.x, y: p.y)) else { return }
        letGo(at: t)
    }
    /// The finger lifted, or left the square: too soon, the ring empties and the paper says to keep holding.
    func letGo(at t: Double) {
        guard heldAt != nil, !open else { return }
        letGoFill = fill(at: t); heldAt = nil; letGoAt = t
    }
    /// Each frame: held for 3 seconds, it opens. True the moment it does.
    func settle(at t: Double) -> Bool {
        guard shotFill == nil, let h = heldAt, t - h >= Self.hold else { return false }
        heldAt = nil; letGoAt = nil; open = true
        version += 1
        return true
    }
    /// Screenshots only: held, its ring this full, and kept there.
    func heldForShots(_ k: Double) { heldAt = PaperClock.now; shotFill = k }
    private var shotFill: Double?
    func openForShots() { open = true; version += 1 }
    func confirmForShots(_ c: Confirm) { confirm = c; version += 1 }

    // MARK: what it shows

    /// What a tap on it does.
    enum Action: Equatable {
        case row(String), reset(String), resetAll, askAll, keep
        case sound(Bool), readAloud(Bool), theme(String)
    }
    @MainActor struct Sheet {
        var sketch = Sketch()
        var taps: [(rect: CGRect, action: Action)] = []
        var frame = Rect(x: 0, y: 0, width: 1, height: 1)
    }

    /// The part the camera shows: the gate, or the whole page.
    var frame: Rect { sheet(now: PaperClock.now).frame }

    /// The table's columns, in squares from the page's left edge: a lesson's name (after its chapter's dot), its last
    /// check, its best, when it comes back; and the settings' column.
    static let nameX = 1.0, lastX = 15.0, bestX = 21.0, backX = 25.0, tableW = 33.0, settingsX = 37.0

    func sheet(now: Double) -> Sheet {
        var out = Sheet(), s = Sketch()
        let x0 = Self.corner.x, y0 = Self.corner.y, u = Self.u, c = Self.c
        s.words("gu-head", "For grown-ups", .heading, x: x0, top: y0 + u / 2 - Sketch.row / 2, width: 1200)
        guard open else {
            // the gate: what to do, and the square to hold, its ring filling (the ring's fill is a live part)
            s.words("gu-hold-say", "Hold the square for 3 seconds.", .say, x: x0, top: y0 + u, width: 1200)
            let r = square
            s.block("gu-hold", r, .main)
            ring(&s, "gu-ring", in: r, colour: .line)
            s.text("gu-hold-w", "Hold", at: CGPoint(x: r.midX, y: r.midY), size: Sketch.small, weight: .semibold, .ink, digits: false)
            if letGoAt != nil {
                s.words("gu-hold-again", "Keep holding until the ring is full.", Sketch.Words.note, x: x0, top: r.maxY + c, width: 1200)
            }
            out.frame = Rect(x: x0, y: y0, width: 6 * u, height: r.maxY + 3 * c - y0)
            out.sketch = s
            return out
        }

        // the lessons: a row each, in the map's order, its chapter's dot before its name
        let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink), head = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink2)
        let quiet = Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink3)
        func X(_ col: Double) -> Double { x0 + col * c }
        var y = y0 + u
        for (col, word) in [(Self.nameX, "Lesson"), (Self.lastX, "Last check"), (Self.bestX, "Best"), (Self.backX, "Comes back")] {
            s.label("gu-col-\(word)", word, head, at: CGPoint(x: X(col), y: y + c), anchor: UnitPoint(x: 0, y: 0.5))
        }
        s.line("gu-col-rule", [CGPoint(x: x0, y: y + 2 * c), CGPoint(x: X(Self.tableW), y: y + 2 * c)], .line, width: Sketch.stroke)
        y += 2 * c
        let p = Progress.shared
        for piece in Map.pieces {
            let id = piece.id, check = p.checks[id], mid = y + c
            // a row asking to be reset is lit, under everything in it
            if confirm == .lesson(id) { s.fill("gu-lit-\(id)", CGRect(x: x0, y: y, width: Self.tableW * c, height: 5 * c), .hex(0xE9E7E1, 0x232321)) }
            // a plate, so it sits over the lit row (fills at one depth fight over it)
            s.plate("gu-dot-\(id)", Rig.circle(CGPoint(x: X(0.5), y: mid), 5), Pen.chapter(piece.chapter).full)
            s.label("gu-name-\(id)", piece.name, small, at: CGPoint(x: X(Self.nameX), y: mid), anchor: UnitPoint(x: 0, y: 0.5))
            let back = Self.comesBack(id, now: now)
            for (col, value, w) in [(Self.lastX, check.map { "\($0.last) of 4" } ?? "–", check == nil ? quiet : small),
                                    (Self.bestX, check.map { "\($0.best) of 4" } ?? "–", check == nil ? quiet : small),
                                    (Self.backX, back.text, back.quiet ? quiet : small)] {
                s.label("gu-\(col)-\(id)", value, w, at: CGPoint(x: X(col), y: mid), anchor: UnitPoint(x: 0, y: 0.5), slot: "gu-\(col)-\(id)")
            }
            let row = CGRect(x: x0, y: y, width: Self.tableW * c, height: 2 * c)
            y += 2 * c
            if confirm == .lesson(id) {
                // confirmed on the paper: under its lit row, what a reset does, with Reset and Keep
                let say = "Wipe its checks and its page?"
                s.label("gu-ask-\(id)", say, Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink), at: CGPoint(x: X(Self.nameX), y: y + c), anchor: UnitPoint(x: 0, y: 0.5))
                var bx = X(Self.nameX) + (((PaperText.width(say, PaperText.font(Sketch.small, .regular)) + c) / c).rounded(.up) + 1) * c
                for (word, action, style) in [("Reset", Action.reset(id), Sketch.Block.main), ("Keep", .keep, .plain)] {
                    let b = CGRect(x: bx, y: y, width: Self.blockWidth(word), height: 2 * c)
                    s.block("gu-ask-\(word)-\(id)", b, style, word: word)
                    out.taps.append((b, action)); bx = b.maxX + c
                }
                y += 3 * c
            } else if check != nil || PageStore.load(id) != nil {
                out.taps.append((row, .row(id)))
            }
        }
        s.line("gu-end-rule", [CGPoint(x: x0, y: y), CGPoint(x: X(Self.tableW), y: y)], .line, width: Sketch.stroke)

        // everything, reset: asked first on the paper
        y += c
        if confirm == .all {
            let say = "Wipe every lesson's checks and page, every test and every review?"
            s.label("gu-askall", say, Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink), at: CGPoint(x: x0, y: y + c), anchor: UnitPoint(x: 0, y: 0.5))
            y += 3 * c
            var bx = x0
            for (word, action, style) in [("Reset everything", Action.resetAll, Sketch.Block.main), ("Keep", .keep, .plain)] {
                let b = CGRect(x: bx, y: y, width: Self.blockWidth(word), height: 2 * c)
                s.block("gu-askall-\(word)", b, style, word: word)
                out.taps.append((b, action)); bx = b.maxX + c
            }
        } else {
            let b = CGRect(x: x0, y: y, width: Self.blockWidth("Reset everything"), height: 2 * c)
            s.block("gu-all", b, .plain, word: "Reset everything")
            s.label("gu-all-or", "or tap a lesson to reset just that one", Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink2),
                    at: CGPoint(x: b.maxX + c, y: b.midY), anchor: UnitPoint(x: 0, y: 0.5))
            out.taps.append((b, .askAll))
        }
        y += 3 * c
        let note = "Checks are scored 0 to 4, and 3 or 4 is learned. A learned lesson comes back for a check after 3, 7, 21 and 60 days, and the next day after a low one."
        let rows = s.words("gu-note", note, Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink2), x: x0, top: y, width: Self.tableW * c, max: 3)
        let bottom = y + Double(rows) * Sketch.row

        // the settings, beside the table
        let sx = X(Self.settingsX)
        var sy = y0 + u
        let settings: [(name: String, say: String, choices: [(String, Action, Bool)])] = [
            ("Sound", "A soft sound for right and wrong.", [("On", .sound(true), AppSettings.sound), ("Off", .sound(false), !AppSettings.sound)]),
            ("Read aloud", "Reads out each step's words.", [("On", .readAloud(true), AppSettings.readAloud), ("Off", .readAloud(false), !AppSettings.readAloud)]),
            ("Colours", "Light or dark paper.", [("Match the iPad", .theme(""), AppSettings.theme == ""), ("Light", .theme("light"), AppSettings.theme == "light"),
                                               ("Dark", .theme("dark"), AppSettings.theme == "dark")]),
        ]
        for setting in settings {
            s.label("gu-set-\(setting.name)", setting.name, Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink), at: CGPoint(x: sx, y: sy + c), anchor: UnitPoint(x: 0, y: 0.5))
            s.label("gu-set-\(setting.name)-say", setting.say, Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink2), at: CGPoint(x: sx, y: sy + 3 * c), anchor: UnitPoint(x: 0, y: 0.5))
            var bx = sx
            for (word, action, chosen) in setting.choices {
                let b = CGRect(x: bx, y: sy + 5 * c, width: Self.blockWidth(word, least: 5), height: 2 * c)
                s.block("gu-set-\(setting.name)-\(word)-\(chosen)", b, chosen ? Self.chosen : Self.other, word: word)
                out.taps.append((b, action)); bx = b.maxX + c
            }
            sy += 10 * c
        }
        let right = X(Self.settingsX) + 22 * c
        out.frame = Rect(x: x0, y: y0, width: right - x0, height: max(bottom, sy) - y0)
        out.sketch = s
        return out
    }

    /// A setting's chosen block: outlined in ink, lightly filled; the others plain, their words quieter. No colour: it's
    /// not maths.
    static let chosen = Sketch.Block(stroke: .ink, fill: .hex(0xE6E4DE, 0x2A2A28), text: .ink)
    static let other = Sketch.Block(stroke: .hex(0xCFCCC5, 0x3A3A37), text: .ink2)

    /// A block as long as its word needs, in whole squares (its word starts a square in, as every block's does).
    static func blockWidth(_ word: String, least: Double = 6) -> Double {
        max(least, ((PaperText.width(word, PaperText.font(Sketch.Words.block.size, .medium)) + 2 * c) / c).rounded(.up)) * c
    }

    /// When a lesson comes back, in plain words: never checked (not started, or being practised), not learned yet, or
    /// today, tomorrow, in so many days.
    static func comesBack(_ id: String, now: Double) -> (text: String, quiet: Bool) {
        guard let check = Progress.shared.checks[id] else { return (PageStore.load(id) != nil ? "Practising" : "Not started", true) }
        guard check.best >= Mastery.pass else { return ("Not learned yet", true) }
        if check.due <= now { return ("Due now", false) }
        let days = Today.days(until: check.due, from: now)
        return (days <= 0 ? "Later today" : days == 1 ? "Tomorrow" : "In \(days) days", false)
    }

    /// The hold's ring: a band round the square's middle, its outline; filled as far as `k` goes (a live part).
    private func ring(_ s: inout Sketch, _ id: String, in r: CGRect, colour: Sketch.Colour) {
        let mid = CGPoint(x: r.midX, y: r.midY), outer = 3.5 * Self.c, inner = 2.5 * Self.c
        for (n, radius) in [(0, outer), (1, inner)] {
            s.line("\(id)\(n)", (0...64).map { i in let a = Double(i) / 64 * 2 * .pi; return CGPoint(x: mid.x + radius * cos(a), y: mid.y + radius * sin(a)) }, colour, width: Sketch.stroke)
        }
    }

    /// The ring filled as far as `k` (0 to 1), clockwise from the top: a band of small pieces between its two circles.
    static func ringFill(_ k: Double, in r: CGRect) -> Sketch {
        var s = Sketch()
        guard k > 0.001 else { return s }
        let mid = CGPoint(x: r.midX, y: r.midY), outer = 3.5 * c, inner = 2.5 * c, n = 72
        let pieces = Int((Double(n) * min(1, k)).rounded(.up))
        for i in 0..<pieces {
            let a0 = -Double.pi / 2 + Double(i) / Double(n) * 2 * .pi
            let a1 = -Double.pi / 2 + min(Double(i + 1) / Double(n), k) * 2 * .pi
            let pts = [CGPoint(x: mid.x + inner * cos(a0), y: mid.y + inner * sin(a0)), CGPoint(x: mid.x + outer * cos(a0), y: mid.y + outer * sin(a0)),
                       CGPoint(x: mid.x + outer * cos(a1), y: mid.y + outer * sin(a1)), CGPoint(x: mid.x + inner * cos(a1), y: mid.y + inner * sin(a1))]
            s.polygon("gu-fill\(i)", pts, .ink2)
        }
        return s
    }

    // MARK: what a tap does

    func tap(_ p: Point, model: PaperModel) {
        guard open else { return }
        let q = CGPoint(x: p.x, y: p.y)
        guard let action = sheet(now: PaperClock.now).taps.first(where: { $0.rect.contains(q) })?.action else {
            // a tap anywhere else puts a question away
            if confirm != nil { confirm = nil; version += 1 }
            return
        }
        let saving = !model.shotMode
        switch action {
        case .row(let id): confirm = confirm == .lesson(id) ? nil : .lesson(id)
        case .askAll: confirm = .all
        case .keep: confirm = nil
        case .reset(let id):
            Progress.shared.forget(id); PageStore.clear(id)
            confirm = nil
        case .resetAll:
            Progress.shared.forgetAll()
            for piece in Map.all + [Map.review] { PageStore.clear(piece.id) }
            confirm = nil
        case .sound(let on): AppSettings.set(sound: on, saving: saving)
        case .readAloud(let on): AppSettings.set(readAloud: on, saving: saving)
        case .theme(let t): AppSettings.set(theme: t, saving: saving)
        }
        version += 1
        // the page may have grown or shrunk (a question asked or put away): the camera frames it again
        model.reframePlace()
    }
}
