import SwiftUI

/// The grown-ups' page (G 20 Oct), drawn on the paper like everything else, reached from the bar's ⋯ More. It's shut
/// behind a simple gate: a square held down for 3 seconds while a ring around it fills (no maths question a child could
/// answer). Since G's island (design/prototype/island.html) the hold happens in the pill's island, and the page arrives
/// open (`pass`); its own gate on the paper is still here for a page arrived at shut. Open, it's in sections (G's
/// preview, design/prototype/grown-ups.html), switched by a row of blocks under its name: This week (what the child did
/// lately, read in ten seconds) and Lessons (each lesson's last check, its best and when it comes back; a lesson, or
/// everything, reset, confirmed on the paper, never a pop-up). What a grown-up reads or sets (settings, privacy, help)
/// is in the island. It shuts again whenever it's left.
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

    /// The hold was passed already (in the pill's island): the next time the page is arrived at, it's open.
    var pass = false

    /// Shut again (each time the page is arrived at), unless the hold was just passed in the island.
    func shut() { open = pass; pass = false; heldAt = nil; letGoAt = nil; letGoFill = 0; confirm = nil; section = .week; version += 1 }

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
    /// The hold passed in the island while the page was here, shut: it opens.
    func openNow() { open = true; heldAt = nil; letGoAt = nil; version += 1 }
    func confirmForShots(_ c: Confirm) { confirm = c; section = .lessons; version += 1 }

    // MARK: what it shows

    /// The page's sections (G's preview, design/prototype/grown-ups.html), switched by a row of blocks under its name:
    /// what the child did lately (This week), and the lessons' table with its resets (Lessons). Settings, privacy and
    /// help are in the pill's island.
    enum Section: CaseIterable {
        case week, lessons
        var word: String { switch self { case .week: "This week"; case .lessons: "Lessons" } }
        /// Its block's width, in squares (each block starts on the next strong line after the one before it).
        var width: Double { switch self { case .week: 9; case .lessons: 8 } }
    }
    /// The section shown: This week, each time the page opens.
    private(set) var section = Section.week
    /// Screenshots only: a section shown.
    func showForShots(_ s: Section) { section = s; version += 1 }

    /// What a tap on it does.
    enum Action: Equatable {
        case section(Section)
        case row(String), reset(String), resetAll, askAll, keep
    }
    @MainActor struct Sheet {
        var sketch = Sketch()
        var taps: [(rect: CGRect, action: Action)] = []
        var frame = Rect(x: 0, y: 0, width: 1, height: 1)
    }

    /// The part the camera shows: the gate, or the page's name, its blocks and the section shown.
    var frame: Rect { sheet(now: PaperClock.now).frame }

    /// The table's columns, in squares from the page's left edge: a lesson's name (after its chapter's dot), its last
    /// check, its best, when it comes back; and where How checks work goes beside it.
    static let nameX = 1.0, lastX = 15.0, bestX = 21.0, backX = 25.0, tableW = 33.0, besideX = 37.0
    /// Where a section starts, in squares under the page's top (the name and the blocks above it).
    static let top = 10.0

    /// The words' kinds on the page: a part's name, a line, a quiet note, and a big line (the headline, a count).
    static let head = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink)
    static let body = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink)
    static let note = Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink2)
    static let big = Sketch.Words(size: Sketch.wordSize, weight: .medium, colour: .ink)

    func sheet(now: Double) -> Sheet {
        var out = Sheet(), s = Sketch()
        let x0 = Self.corner.x, y0 = Self.corner.y, u = Self.u, c = Self.c
        s.text("gu-head", "For grown-ups", at: CGPoint(x: x0, y: y0 + u / 2), size: Sketch.maths, weight: .semibold, .ink, anchor: UnitPoint(x: 0, y: 0.5), digits: false)
        guard open else {
            // the gate: what to do, and the square to hold, its ring filling (the ring's fill is a live part)
            s.words("gu-hold-say", "Hold for 3 seconds", .say, x: x0, top: y0 + u, width: 1200)
            let r = square
            s.block("gu-hold", r, .main)
            ring(&s, "gu-ring", in: r, colour: .line)
            s.text("gu-hold-w", "Hold", at: CGPoint(x: r.midX, y: r.midY), size: Sketch.small, weight: .semibold, .ink, digits: false)
            if letGoAt != nil {
                s.words("gu-hold-again", "Keep holding", Sketch.Words.note, x: x0, top: r.maxY + c, width: 1200)
            }
            out.frame = Rect(x: x0, y: y0, width: 6 * u, height: r.maxY + 3 * c - y0)
            out.sketch = s
            return out
        }

        // the sections' blocks, a block under the name: the one shown outlined in ink and lightly filled (as a chosen
        // setting is), the others plain
        var bx = x0
        for sec in Section.allCases {
            let r = CGRect(x: bx, y: y0 + u, width: sec.width * c, height: 3 * c)
            s.block("gu-tab-\(sec)-\(sec == section)", r, sec == section ? Self.chosen : Self.other, word: sec.word)
            out.taps.append((r, .section(sec)))
            bx += ((sec.width + 1) / 5).rounded(.up) * u
        }
        // the section shown: drawn in as it's chosen, the one before erasing itself (only what changed redraws)
        let end: CGPoint
        switch section {
        case .week: end = week(&s, now: now)
        case .lessons: end = lessons(&s, &out, now: now)
        }
        out.frame = Rect(x: x0, y: y0, width: max(end.x, bx - c) - x0, height: end.y + c - y0)
        out.sketch = s
        return out
    }

    /// A point `x` squares right of the page's left edge and `y` squares under its top.
    private static func at(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: corner.x + x * c, y: corner.y + y * c) }

    // MARK: This week

    /// This week (G's preview): how many lessons are learned, a square for each in its chapter's colour, the days
    /// practised, the problems solved and about how long, the checks coming, and the lessons going well and worth a look.
    /// Returns its bottom-right corner.
    private func week(_ s: inout Sketch, now: Double) -> CGPoint {
        let c = Self.c, checks = Progress.shared.checks, lessons = Map.gradeLessons, name = AppSettings.name
        let started = Set(lessons.filter { PageStore.load($0) != nil }), records = Practice.shared.days
        func P(_ x: Double, _ y: Double) -> CGPoint { Self.at(x, y) }
        let left = UnitPoint(x: 0, y: 0.5)

        // the headline, its count a little firmer: "Mia has learned 9 of 17 lessons in 5th grade."
        let learned = lessons.filter { Mastery.learnedEver(checks, $0) }.count
        let line = Week.headline(name: name, learned: learned, of: lessons.count, grade: AppSettings.profile.grade)
        let firm = "\(learned) of \(lessons.count)"
        if let r = line.range(of: firm) {
            let pieces = [(String(line[..<r.lowerBound]), UIFont.Weight.medium), (firm, .semibold), (String(line[r.upperBound...]), .medium)]
            var x = P(0, 0).x
            for (i, (text, weight)) in pieces.enumerated() where !text.isEmpty {
                s.text("gu-wk-head\(i):\(text)", text, at: CGPoint(x: x, y: P(0, Self.top + 1.5).y), size: Sketch.wordSize, weight: weight, .ink, anchor: left, digits: false)
                // measured with a mark after it, so a space at its end counts
                let f = PaperText.font(Sketch.wordSize, weight)
                x += PaperText.width(text + "|", f) - PaperText.width("|", f)
            }
        }

        // a square for each lesson, three squares a side, a chapter's together and a square between chapters: filled
        // learned, shaded started, open not yet (the chapter's outline round them, cut into its lessons)
        var groups: [(chapter: Chapter, ids: [String])] = []
        for piece in Map.pieces {
            if groups.last?.chapter == piece.chapter { groups[groups.count - 1].ids.append(piece.id) } else { groups.append((piece.chapter, [piece.id])) }
        }
        let side = 3 * c, sy = P(0, 14).y
        var gx = P(0, 0).x
        for (chapter, ids) in groups {
            let pen = Pen.chapter(chapter)
            for (i, id) in ids.enumerated() {
                let r = CGRect(x: gx + Double(i) * side, y: sy, width: side, height: side)
                switch Week.standing(id, checks: checks, started: started) {
                case .learned: s.plate("gu-wk-sq-\(id)-learned", r, pen.full)
                case .started: s.plate("gu-wk-sq-\(id)-started", r, pen.tint(0.28))
                case .notYet: break
                }
            }
            let r = CGRect(x: gx, y: sy, width: Double(ids.count) * side, height: side)
            s.overLine("gu-wk-sqo-\(chapter)", [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.minX, y: r.minY)],
                       pen.tint(0.7), width: Sketch.stroke)
            for i in 1..<max(1, ids.count) {
                let x = gx + Double(i) * side
                s.overLine("gu-wk-sqc-\(chapter)\(i)", [CGPoint(x: x, y: sy), CGPoint(x: x, y: sy + side)], pen.tint(0.7), width: Sketch.stroke)
            }
            gx = r.maxX + c
        }
        let squaresEnd = gx - c
        s.label("gu-wk-key", "Each square is a lesson. Filled: passed. Shaded: started.", Self.note, at: P(0, 19), anchor: left)

        // nothing yet (a new install): one line instead of the week
        if Week.fresh(checks: checks, started: started, records: records) {
            s.label("gu-wk-empty", Week.empty(name: name), Self.body, at: P(0, 21), anchor: left)
            return CGPoint(x: squaresEnd, y: P(0, 22).y)
        }

        // the days practised: the last 7, today last, a square each, filled when practised, its day's letter under it
        s.label("gu-wk-days", "Days practiced", Self.head, at: P(0, 21), anchor: left)
        let days = Week.practised(records, now: now), letters = Week.letters(now: now)
        for (i, done) in days.enumerated() {
            let r = CGRect(origin: P(Double(i) * 3, 23), size: CGSize(width: 2 * c, height: 2 * c))
            if done { s.plate("gu-wk-day\(i)-f", r, .ink) }
            s.box("gu-wk-day\(i)-o\(done)", r.insetBy(dx: Sketch.stroke / 2, dy: Sketch.stroke / 2), done ? .ink : .ink3, width: Sketch.stroke)
            s.text("gu-wk-day\(i)-w:\(letters[i])", letters[i], at: CGPoint(x: r.midX, y: P(0, 26).y), size: Sketch.small, weight: .regular, .ink2, digits: false)
        }
        s.label("gu-wk-days-n", Week.daysLine(days), Self.note, at: P(0, 28), anchor: left, slot: "gu-wk-days-n")

        // this week's problems, and about how long
        let total = Week.total(records, now: now)
        s.label("gu-wk-week", "This week", Self.head, at: P(25, 21), anchor: left)
        let none = total.problems == 0 && total.seconds < Week.minute
        s.label("gu-wk-week-n", none ? "None yet" : Week.problems(total.problems), Self.big, at: P(25, 24), anchor: left, slot: "gu-wk-week-n")
        if !none { s.label("gu-wk-week-t", Week.duration(total.seconds), Self.note, at: P(25, 26), anchor: left, slot: "gu-wk-week-t") }

        // the checks coming this week
        let coming = Week.checksComing(lessons, checks: checks, now: now)
        s.label("gu-wk-checks", "Checks", Self.head, at: P(50, 21), anchor: left)
        s.label("gu-wk-checks-n", coming.isEmpty ? "None this week" : "\(coming.count) this week", Self.big, at: P(50, 24), anchor: left, slot: "gu-wk-checks-n")
        let next = lessons.filter { Mastery.learnedEver(checks, $0) }.compactMap { checks[$0]?.due }.min()
        if coming.isEmpty, let next {
            s.label("gu-wk-checks-t", "Next in \(Today.days(until: next, from: now)) days", Self.note, at: P(50, 26), anchor: left, slot: "gu-wk-checks-t")
        }

        // going well, and needs work: a lesson a row, its chapter's dot before its name
        s.line("gu-wk-rule", [P(0, 30), P(72, 30)], .line, width: Sketch.stroke)
        s.label("gu-wk-well", "Going well", Self.head, at: P(0, 32), anchor: left)
        s.label("gu-wk-look", "Needs work", Self.head, at: P(35, 32), anchor: left)
        let well = Week.goingWell(lessons, checks: checks, now: now)
        let looks = Week.worthALook(lessons, checks: checks, started: started, now: now)
        if well.isEmpty { s.label("gu-wk-well-none", "Nothing yet.", Self.note, at: P(0, 34), anchor: left) }
        for (i, id) in well.enumerated() { lessonLine(&s, "gu-wk-well\(i)", id, why: nil, at: P(0, 34 + 2 * Double(i))) }
        if looks.isEmpty { s.label("gu-wk-look-none", "Nothing right now.", Self.note, at: P(35, 34), anchor: left) }
        for (i, look) in looks.enumerated() { lessonLine(&s, "gu-wk-look\(i)", look.id, why: look.why, at: P(35, 34 + 2 * Double(i))) }
        let rows = max(1, well.count, looks.count)
        return CGPoint(x: P(72, 0).x, y: P(0, 33 + 2 * Double(rows)).y)
    }

    /// A lesson on a line: its chapter's dot, its name, and why after it, quieter. `mid`: the line's left end, at its
    /// middle.
    private func lessonLine(_ s: inout Sketch, _ id: String, _ lesson: String, why: String?, at mid: CGPoint) {
        guard let piece = Map.piece(lesson) else { return }
        let c = Self.c, left = UnitPoint(x: 0, y: 0.5)
        s.plate("\(id)-dot-\(lesson)", Rig.circle(CGPoint(x: mid.x + c / 2, y: mid.y), 5), Pen.chapter(piece.chapter).full)
        s.label("\(id)-name", piece.name, Self.body, at: CGPoint(x: mid.x + c, y: mid.y), anchor: left)
        guard let why else { return }
        let w = PaperText.width(piece.name, PaperText.font(Self.body.size, Self.body.weight))
        s.label("\(id)-why", "· " + why, Self.note, at: CGPoint(x: mid.x + c + w + c / 2, y: mid.y), anchor: left)
    }

    // MARK: Lessons

    /// The lessons (as the page has always had them): a row each, in the map's order, its chapter's dot before its name,
    /// its last check, its best and when it comes back; a lesson, or everything, reset (confirmed on the paper); and how
    /// checks work beside the table. Returns its bottom-right corner.
    private func lessons(_ s: inout Sketch, _ out: inout Sheet, now: Double) -> CGPoint {
        let x0 = Self.corner.x, c = Self.c
        let small = Sketch.Words(size: Sketch.small, weight: .medium, colour: .ink), head = Sketch.Words(size: Sketch.small, weight: .semibold, colour: .ink2)
        let quiet = Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink3)
        func X(_ col: Double) -> Double { x0 + col * c }
        var y = Self.at(0, Self.top).y
        let top = y
        for (col, word) in [(Self.nameX, "Lesson"), (Self.lastX, "Last check"), (Self.bestX, "Best"), (Self.backX, "Next check")] {
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
                // confirmed on the paper: under its lit row, Reset and Cancel
                let say = "Reset this lesson?"
                s.label("gu-ask-\(id)", say, Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink), at: CGPoint(x: X(Self.nameX), y: y + c), anchor: UnitPoint(x: 0, y: 0.5))
                var bx = X(Self.nameX) + (((PaperText.width(say, PaperText.font(Sketch.small, .regular)) + c) / c).rounded(.up) + 1) * c
                for (word, action, style) in [("Reset", Action.reset(id), Sketch.Block.main), ("Cancel", .keep, .plain)] {
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
            let say = "Reset every lesson, test and review?"
            s.label("gu-askall", say, Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink), at: CGPoint(x: x0, y: y + c), anchor: UnitPoint(x: 0, y: 0.5))
            y += 3 * c
            var bx = x0
            for (word, action, style) in [("Reset all", Action.resetAll, Sketch.Block.main), ("Cancel", .keep, .plain)] {
                let b = CGRect(x: bx, y: y, width: Self.blockWidth(word), height: 2 * c)
                s.block("gu-askall-\(word)", b, style, word: word)
                out.taps.append((b, action)); bx = b.maxX + c
            }
        } else {
            let b = CGRect(x: x0, y: y, width: Self.blockWidth("Reset all"), height: 2 * c)
            s.block("gu-all", b, .plain, word: "Reset all")
            s.label("gu-all-or", "or tap a lesson to reset it", Sketch.Words(size: Sketch.small, weight: .regular, colour: .ink2),
                    at: CGPoint(x: b.maxX + c, y: b.midY), anchor: UnitPoint(x: 0, y: 0.5))
            out.taps.append((b, .askAll))
        }
        y += 2 * c

        // how checks work, beside the table
        s.label("gu-how", "How checks work", Self.head, at: CGPoint(x: X(Self.besideX), y: top + c), anchor: UnitPoint(x: 0, y: 0.5))
        let how = "A check is scored out of 4, and 3 passes. A passed lesson comes back after 3, 7, 21 and 60 days, or the next day if a check goes badly."
        let rows = s.words("gu-how-say", how, Self.note, x: X(Self.besideX), top: top + 2 * c, width: 20 * c, max: 10)
        return CGPoint(x: X(Self.besideX + 20), y: max(y, top + 2 * c + Double(rows) * Sketch.row))
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
        guard let check = Progress.shared.checks[id] else { return (PageStore.load(id) != nil ? "In progress" : "Not started", true) }
        guard check.best >= Mastery.pass else { return ("Not passed yet", true) }
        let days = Today.days(until: check.due, from: now)
        return (check.due <= now || days <= 0 ? "Today" : days == 1 ? "Tomorrow" : "In \(days) days", false)
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
            if confirm != nil { confirm = nil; version += 1; model.reframePlace() }
            return
        }
        switch action {
        case .section(let sec):
            // another section: the one shown erases itself as the new one draws in, and the camera frames it
            section = sec; confirm = nil
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
        }
        version += 1
        // the page may have grown or shrunk (a question asked or put away, another section): the camera frames it again
        model.reframePlace()
    }
}
