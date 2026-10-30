import SwiftUI

/// Me, the child's own page on the paper (G's plan of 18 Oct, step 7; G 20 Oct: drawn on the paper, never a card that
/// pops up). Today at the top: today's pick (Mastery.upNext), with why in plain words, and the daily review. Under it
/// the three shelves of the child's lessons, side by side, a lesson moving right as its checks pass: Needs work (due back
/// for a check, or its last check came back low), Learning (passed, on its way through the four checks), Learned (all
/// four passed; G 29 Oct chose the three names). Every card opens what it shows. It lives on the sheet left of the map, on the strong lines,
/// and draws itself in and out like everything else (SketchDrawer).
/// A shelf shows as many cards as fit on the screen with all of Me in view (`rows`); a longer one ends on a card
/// "6 more", which opens that shelf on its own, every card of it in three columns, with Back under them.
@MainActor
enum MePage {
    /// Its top-left corner on the paper: left of the map, clear of it, on the strong lines.
    static let corner = Point(-16 * Paper.unit, 0)
    static let u = Paper.unit, c = Paper.cell
    /// Its width: three shelves of cards three blocks wide, a block apart.
    static let width = 11 * Paper.unit
    /// Name and grade at the top (G 26 Oct): a block for them, then Today.
    static let band = Paper.unit
    /// Where the shelves' cards start: under the name, Today (its cards, their names and why) and the shelves' names.
    static let shelfTop = band + 5 * Paper.unit
    /// An opened shelf's cards go in three columns, where the three shelves stand.
    static let columns = 3
    /// The least a shelf shows (its first card, and "and 6 more").
    static let fewestRows = 2

    /// What a tap on one of its cards does: open a lesson or the daily review, open a long shelf to all its cards, or go
    /// back from it to the whole of Me.
    enum Action: Equatable { case lesson(String), review, shelf(Int), back, grade(Int) }

    /// How many cards a shelf shows on a screen this tall: as many rows as fit under Today with all of Me framed at 75%
    /// (its words still big enough to read), clear of the bar, so nothing runs under the bar or off the screen; never
    /// fewer than 2. `pad`: the room the camera leaves round what it frames.
    static func rows(screenHeight h: Double, pad: Double) -> Int {
        let room = (h - PaperModel.chrome.top - PaperModel.chrome.bottom - 2 * pad) / 0.75
        return max(fewestRows, Int(((room - shelfTop - c) / u).rounded(.down)))
    }

    /// Me as it stands: its drawing, where its cards are and what each opens, and the part the camera shows.
    @MainActor struct Sheet {
        var sketch = Sketch()
        var taps: [(rect: CGRect, action: Action)] = []
        var frame = Rect(x: 0, y: 0, width: 1, height: 1)
    }

    /// The three shelves, in order, with what each says when it's empty.
    static let shelves: [(name: String, empty: String)] = [
        ("Needs work", "Nothing here."), ("Learning", "Lessons you pass go here."), ("Learned", "Lessons go here after 4 checks."),
    ]

    /// Me now. `rows`: the most cards a shelf shows (MePage.rows); `open`: a shelf opened to all its cards, drawn on its
    /// own instead of Today and the three shelves.
    static func sheet(now: Double, rows: Int, open: Int? = nil, gradeSaid: Int? = nil) -> Sheet {
        var out = Sheet(), s = Sketch()
        let x0 = corner.x, y0 = corner.y, checks = Progress.shared.checks
        func R(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> CGRect { CGRect(x: x, y: y, width: w, height: h) }

        // the shelves: a lesson moves right as its checks pass; getting stronger: the next check soonest first, so
        // what's coming is on top
        let sh = Mastery.shelves(Map.gradeLessons, checks: checks, now: now)
        let lists = [sh.goOver, sh.gettingStronger.sorted { (checks[$0]?.due ?? 0) < (checks[$1]?.due ?? 0) }, sh.knowIt]
        if let k = open, lists.indices.contains(k) {
            openShelf(&s, &out, k, lists[k], now: now)
            out.sketch = s
            return out
        }

        // the child's name (or Me) and grade, and the grade row: 5th has lessons, the others only say they're coming
        nameAndGrade(&s, &out, gradeSaid: gradeSaid)
        // Today: the pick, and the review
        let ty = y0 + band
        s.words("me-today", "Today", .heading, x: x0, top: ty + u / 2 - Sketch.row / 2, width: 1200)
        let pickRect = R(x0, ty + u, 3 * u, 2 * u)
        if let pick = Map.today {
            let reason = todayReason(pick, now: now)
            let pen = Pen.chapter(pick.chapter)
            // Go over means one thing on Me: what its Go over shelf holds (a lesson learned that's due back, or whose
            // check came back low). A lesson picked to help with one that came back low, or a test to take again on a
            // lesson never learned, is up next
            let goOver = Mastery.goOver(checks, pick.id, now: now)
            s.frame("me-pick-\(pick.id)", pickRect, .now, pen: pen)
            picture(&s, pick, in: pickRect)
            s.tab("me-pick-\(pick.id)", frame: pickRect, goOver ? "Go over" : "Up next", pen: pen)
            s.label("me-pick-name", pick.name, .label, at: CGPoint(x: pickRect.minX, y: pickRect.maxY + 30), anchor: UnitPoint(x: 0, y: 0.5))
            // why, in plain words, lit: it's news; two lines when it runs long
            let lines = PaperText.wrap(why(reason, pick), PaperText.font(Sketch.small, .regular), width: 3.6 * u).prefix(2)
            for (i, line) in lines.enumerated() {
                s.label("me-pick-why\(i)", line, Sketch.Words.status.colour(pen.full), at: CGPoint(x: pickRect.minX, y: pickRect.maxY + 50 + 20 * Double(i)), anchor: UnitPoint(x: 0, y: 0.5))
            }
            out.taps.append((pickRect, .lesson(pick.id)))
        }
        reviewCard(&s, &out, R(x0 + 4 * u, ty + u, 3 * u, 2 * u), now: now)

        // the shelves, side by side, each as long as fits (`rows`): a longer one ends on "and 6 more", which opens it
        let top = y0 + shelfTop, most = max(fewestRows, rows)
        for (k, list) in lists.enumerated() {
            let x = x0 + 4 * Double(k) * u
            heading(&s, k, count: list.count, x: x, mid: top - u / 2)
            if list.isEmpty { emptyCard(&s, k, in: R(x, top, 3 * u, u)); continue }
            let capped = list.count > most, shown = capped ? Array(list.prefix(most - 1)) : list
            // the shelf's cards stacked one on another, a block each, as a shelf of them
            for (j, id) in shown.enumerated() {
                guard let piece = Map.piece(id), let check = checks[id] else { continue }
                let r = R(x, top + Double(j) * u, 3 * u, u)
                lessonCard(&s, piece, check, shelf: k, in: r, now: now, last: !capped && j == shown.count - 1)
                out.taps.append((r, .lesson(id)))
            }
            if capped {
                let r = R(x, top + Double(shown.count) * u, 3 * u, u)
                moreCard(&s, k, more: list.count - shown.count, in: r)
                out.taps.append((r, .shelf(k)))
            }
        }
        let tallest = max(1, lists.map { min($0.count, most) }.max() ?? 1)
        out.frame = Rect(x: x0, y: corner.y, width: width, height: shelfTop + Double(tallest) * u + c)
        out.sketch = s
        return out
    }

    /// Me's top (G 26 Oct, front-door.html section 3): the child's name big (Me when it was skipped), their grade and
    /// how many lessons are learned under it (only once there's one to count); beside them the grades as a row of
    /// blocks, 5th chosen, the others dead blocks that only say they're coming soon when tapped.
    private static func nameAndGrade(_ s: inout Sketch, _ out: inout Sheet, gradeSaid: Int?) {
        let x0 = corner.x, y0 = corner.y, profile = AppSettings.profile
        s.text("me-name:\(profile.name)", Setup.title(profile.name), at: CGPoint(x: x0, y: y0 + c), size: Sketch.maths, weight: .semibold, .ink,
               anchor: UnitPoint(x: 0, y: 0.5), digits: false)
        let learned = Map.gradeLessons.filter { Progress.shared.learned.contains($0) }.count
        let line = Grades.name(profile.grade) + (Fresh.showsCount(learned: learned) ? " · \(learned) of \(Map.gradeLessons.count) passed" : "")
        s.label("me-grade-line", line, .status, at: CGPoint(x: x0, y: y0 + 3 * c), anchor: UnitPoint(x: 0, y: 0.5), slot: "me-grade-line")
        // the row starts on the third strong line, clear of a long name; small blocks, two squares a side
        let gx = x0 + 3 * u
        for (r, g) in s.gradeRow("me-grade", x: gx, y: y0, side: 2, pitch: 3, chosen: profile.grade, size: Sketch.small) {
            out.taps.append((r, .grade(g)))
        }
        if let g = gradeSaid {
            s.label("me-grade-said", Grades.onMe(g), .status, at: CGPoint(x: gx, y: y0 + 3 * c), anchor: UnitPoint(x: 0, y: 0.5), slot: "me-grade-said")
        }
    }

    /// A long shelf opened (from its "and 6 more"): its name where Today's is, every one of its cards in three columns
    /// where the three shelves stand (filled down, as a shelf is, the soonest check first), and Back to Me under them.
    /// Its cards keep their names on the paper, so they glide from the shelf to their places and back.
    private static func openShelf(_ s: inout Sketch, _ out: inout Sheet, _ k: Int, _ list: [String], now: Double) {
        let x0 = corner.x, y0 = corner.y, top = y0 + u, checks = Progress.shared.checks
        heading(&s, k, count: list.count, x: x0, mid: y0 + u / 2)
        let perColumn = max(1, (list.count + columns - 1) / columns)
        if list.isEmpty { emptyCard(&s, k, in: CGRect(x: x0, y: top, width: 3 * u, height: u)) }
        for (j, id) in list.enumerated() {
            guard let piece = Map.piece(id), let check = checks[id] else { continue }
            let col = j / perColumn, row = j % perColumn
            let r = CGRect(x: x0 + Double(col) * 4 * u, y: top + Double(row) * u, width: 3 * u, height: u)
            lessonCard(&s, piece, check, shelf: k, in: r, now: now, last: row == perColumn - 1 || j == list.count - 1)
            out.taps.append((r, .lesson(id)))
        }
        // the way back, a square under the cards, as the result's Back to problems is a quieter block
        let word = "Back", b = CGRect(x: x0, y: top + Double(perColumn) * u + c, width: GrownUpPage.blockWidth(word, least: 9), height: 2 * c)
        s.block("me-back", b, .plain, word: word)
        out.taps.append((b, .back))
        out.frame = Rect(x: x0, y: y0, width: width, height: b.maxY + c - y0)
    }

    // MARK: the cards

    /// A shelf's name, big, with how many lessons it holds beside it, small: centred on `mid`.
    private static func heading(_ s: inout Sketch, _ k: Int, count: Int, x: Double, mid: Double) {
        let name = shelves[k].name
        s.words("me-shelf\(k)", name, .heading, x: x, top: mid - Sketch.row / 2, width: 3.6 * u)
        let w = PaperText.width(name, PaperText.font(Sketch.Words.heading.size, Sketch.Words.heading.weight))
        s.text("me-shelf\(k)n:\(count)", "\(count)", at: CGPoint(x: x + w + 12, y: mid), size: Sketch.small, weight: .regular, .ink3,
               anchor: UnitPoint(x: 0, y: 0.5), slot: "me-shelf\(k)n")
    }

    /// An empty shelf: dashed, with what comes there.
    private static func emptyCard(_ s: inout Sketch, _ k: Int, in r: CGRect) {
        s.frame("me-empty\(k)", r, .locked, pen: .ink)
        s.label("me-empty\(k)w", shelves[k].empty, Sketch.Words.status, at: CGPoint(x: r.minX + c, y: r.midY), anchor: UnitPoint(x: 0, y: 0.5))
    }

    /// The last place on a shelf too long for the screen: in ink (it holds lessons of every chapter), "and 6 more" where
    /// a card's name goes and what a tap does under it. It opens the shelf.
    private static func moreCard(_ s: inout Sketch, _ k: Int, more: Int, in r: CGRect) {
        let id = "me-more\(k)"
        s.frame(id, r, .open, pen: .ink)
        s.label("\(id)name", "\(more) more", .label, at: CGPoint(x: r.minX + c, y: r.minY + 1.5 * c), anchor: UnitPoint(x: 0, y: 0.5), slot: "\(id)name")
        s.label("\(id)line", "See all", .status, at: CGPoint(x: r.minX + c, y: r.minY + 3.5 * c), anchor: UnitPoint(x: 0, y: 0.5))
    }

    /// A lesson on a shelf: a card three blocks by one in its chapter's colour, its name on its top row and where it
    /// stands on the row under it: to go over, why; otherwise its four checks as a bar of four squares, as many shaded as
    /// are passed (a bar like the fractions', so it reads as "2 of 4"), and when the next one is.
    /// `last`: the last card stacked in its column draws its bottom edge; one with a card under it leaves the line they
    /// share to that card's top, so two chapters' colours never fight over one line.
    private static func lessonCard(_ s: inout Sketch, _ p: Piece, _ check: CheckRecord, shelf: Int, in r: CGRect, now: Double, last: Bool) {
        let pen = Pen.chapter(p.chapter), id = "me-card-\(p.id)"
        // to go over is something to do: lit, as up next is on the map; the others are learned: lightly filled
        s.frame(id, r, shelf == 0 ? .now : .done, pen: pen, bottom: last)
        let top = r.minY + 1.5 * c, low = r.minY + 3.5 * c
        s.label("\(id)name", p.name, .label, at: CGPoint(x: r.minX + c, y: top), anchor: UnitPoint(x: 0, y: 0.5))
        if shelf == 0 {
            let due = Mastery.dueBack(Progress.shared.checks, p.id, now: now)
            s.label("\(id)line", due ? "Check today" : "Try it again", Sketch.Words.status.colour(pen.full),
                    at: CGPoint(x: r.minX + c, y: low), anchor: UnitPoint(x: 0, y: 0.5))
            return
        }
        let passed = min(Mastery.reviewDays.count, check.passes)
        checksBar(&s, id, passed: passed, at: CGPoint(x: r.minX + c, y: low - c / 2), pen: pen)
        let line: String = {
            if passed >= Mastery.reviewDays.count { return "4 of 4 checks" }
            let days = Today.days(until: check.due, from: now)
            return days <= 0 ? "Check today" : days == 1 ? "Check tomorrow" : "Check in \(days) days"
        }()
        s.label("\(id)line", line, .status, at: CGPoint(x: r.minX + 6 * c, y: low), anchor: UnitPoint(x: 0, y: 0.5), slot: "\(id)line")
    }

    /// The four checks as a bar four squares long, cut into its four, `passed` of them shaded (a bar like the
    /// fractions', so it reads as "2 of 4").
    static func checksBar(_ s: inout Sketch, _ id: String, passed: Int, at o: CGPoint, pen: Pen) {
        let n = Mastery.reviewDays.count, r = CGRect(x: o.x, y: o.y, width: Double(n) * c, height: c)
        // over the card's own light fill (a plate, and lines over plates), so the two never fight for the same depth
        if passed > 0 { s.plate("\(id)bar-f\(passed)", CGRect(x: o.x, y: o.y, width: Double(passed) * c, height: c), pen.tint(0.45)) }
        s.overLine("\(id)bar-o", [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.minX, y: r.minY)],
                   pen.tint(0.7), width: Sketch.stroke)
        for i in 1..<n { s.overLine("\(id)bar-cut\(i)", [CGPoint(x: o.x + Double(i) * c, y: o.y), CGPoint(x: o.x + Double(i) * c, y: o.y + c)], pen.tint(0.7), width: Sketch.stroke) }
    }

    /// The daily review's card: what it is in its frame (8 problems, from the child's lessons; once done today, how it
    /// went), its name under it and how it stands. In ink: it mixes every chapter. Waiting (fewer than two lessons
    /// checked yet, and none started today), dashed. Whatever it says, a tap does: one started today opens to be
    /// finished, even after a grown-up's reset leaves fewer than two lessons checked.
    private static func reviewCard(_ s: inout Sketch, _ out: inout Sheet, _ r: CGRect, now: Double) {
        let p = Progress.shared, id = "me-review"
        let done = p.todaysReview, partway = PaperModel.reviewPartway(now: now)
        let opens = Review.ready(Map.gradeLessons, checks: p.checks) || done != nil || partway != nil
        let state: Sketch.FrameState = done != nil ? .done : partway != nil ? .now : opens ? .open : .locked
        s.frame(id, r, state, pen: .ink)
        if done != nil { s.tab(id, frame: r, "Done", pen: .ink) }
        let big = done.map { "\($0.right) of \($0.of) right" } ?? "\(Review.problems) problems"
        let small = done != nil ? "Done today" : "from your lessons"
        s.text("\(id)big:\(big)", big, at: CGPoint(x: r.midX, y: r.minY + 4 * c), size: Sketch.wordSize, weight: .medium, opens ? .ink : .ink3, digits: true)
        s.text("\(id)small:\(small)", small, at: CGPoint(x: r.midX, y: r.minY + 6 * c), size: Sketch.small, weight: .regular, .ink2, digits: false)
        s.label("\(id)name", "Daily review", .label, at: CGPoint(x: r.minX, y: r.maxY + 30), anchor: UnitPoint(x: 0, y: 0.5))
        let line: (String, Sketch.Colour) = {
            if done != nil { return ("A new one tomorrow", .ink3) }
            if let n = partway { return ("\(n) of \(Review.problems) done", .ink) }
            if !opens { return ("Pass two lessons first", .ink3) }
            return ("One try each", .ink3)
        }()
        s.label("\(id)line", line.0, Sketch.Words.status.colour(line.1), at: CGPoint(x: r.minX, y: r.maxY + 50), anchor: UnitPoint(x: 0, y: 0.5), slot: "\(id)line")
        if opens { out.taps.append((r, .review)) }
    }

    /// A lesson's own picture from the map, drawn in its card as on the map: its lines in its chapter's colour, what
    /// matters in it softly filled.
    static func picture(_ s: inout Sketch, _ p: Piece, in r: CGRect) {
        let at = Piece(id: p.id, name: p.name, chapter: p.chapter, at: Point(r.minX, r.minY)), pen = Pen.chapter(p.chapter)
        for (i, poly) in at.softs.enumerated() { s.polygon("me-pic-\(p.id)-soft\(i)", poly, pen.tint(0.42)) }
        for (i, line) in at.strokes.enumerated() { s.line("me-pic-\(p.id)-\(i)", line, pen.full, width: Sketch.stroke) }
    }

    // MARK: words

    /// Why today's pick was picked (Today.reason, worked out as Mastery.upNext picked it).
    static func todayReason(_ pick: Piece, now: Double) -> Today.Reason {
        let open = Map.pieces.filter(\.opens).map(\.id), checks = Progress.shared.checks
        let deps = { (id: String) in Lessons.spec(id)?.depends ?? [] }
        let why = Mastery.upNext(open, depends: deps, checks: checks, grade: 5, now: now)?.why ?? .next
        return Today.reason((pick.id, why), lessons: open, depends: deps, checks: checks, now: now)
    }

    /// The reason in plain words (G 18 Oct): short, about the child's own lessons, and written as a card's line is (no
    /// full stop), the way the shelves say theirs.
    static func why(_ r: Today.Reason, _ pick: Piece) -> String {
        func name(_ id: String) -> String { Map.piece(id)?.name ?? id }
        switch r {
        case .due: return "Check today"
        // never learned: what came back low was its lesson test (there's no check before a lesson is learned)
        case .low: return Mastery.learnedEver(Progress.shared.checks, pick.id) ? "Missed its last check" : "Missed its test"
        case .helps(let id): return "Helps with \(name(id))"
        case .buildsOn(let id): return "Builds on \(name(id))"
        case .first: return "The first lesson"
        case .next: return "Next in \(pick.chapter.title)"
        case .oldest: return "Not practiced in a while"
        }
    }
}

/// A colour for the parts of a page that shows many chapters at once (Me, the daily review), or none: ink, for what
/// belongs to no chapter. Its full strength, and its tints mixed into the paper, light and dark.
struct Pen: Equatable {
    let light: UInt32, dark: UInt32
    /// How strongly a done frame is filled: ink's is lighter, as grey reads heavier than a colour's tint.
    var soft = 0.08
    var full: Sketch.Colour { .hex(light, dark) }
    func tint(_ f: Double) -> Sketch.Colour { .hex(Ink.mix(0xF3F2EF, light, f), Ink.mix(0x121211, dark, f)) }
    static func chapter(_ c: Chapter) -> Pen { Pen(light: c.hex, dark: c.hex) }
    static let ink = Pen(light: 0x1A1A19, dark: 0xECEBE7, soft: 0.035)
}

extension Sketch {
    /// A thumbnail's frame (Components' `frame`) in a pen of its own, not the drawing's chapter.
    /// `bottom` false: a card with another stacked under it (Me's shelves) leaves out its bottom edge, the line the two
    /// share, which the card under it draws as its top; one line, one colour.
    mutating func frame(_ id: String, _ r: CGRect, _ state: FrameState, pen: Pen, bottom: Bool = true) {
        let corners = bottom ? [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.minX, y: r.minY)]
            : [CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY)]
        switch state {
        case .locked: line(id + "o-locked", corners, pen.tint(0.35), width: Sketch.stroke, dashed: true)
        case .now: line(id + "o-now", corners, pen.full, width: Sketch.stroke)
        case .done:
            fill(id + "f", r, pen.tint(pen.soft))
            line(id + "o", corners, pen.tint(0.3), width: Sketch.stroke)
        case .open: line(id + "o", corners, pen.tint(0.3), width: Sketch.stroke)
        }
    }
    /// A tab on a frame's top-right corner (Components' `tab`) in a pen of its own: a chapter's with white words; ink's
    /// a soft grey with the paper's colour for its words, so it reads in the light and the dark.
    mutating func tab(_ id: String, frame r: CGRect, _ word: String, pen: Pen, width: Double = 80) {
        let t = CGRect(x: r.maxX - width, y: r.minY - Paper.cell, width: width, height: Paper.cell), ink = pen == .ink
        fill("\(id)tab\(word)\(width)", t, ink ? .ink2 : pen.full)
        text("\(id)tabw\(word)", word, at: CGPoint(x: t.midX, y: t.midY), size: Words.tab.size, weight: Words.tab.weight, ink ? .paper : Words.tab.colour, digits: false)
    }
}
