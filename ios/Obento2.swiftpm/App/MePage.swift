import SwiftUI

/// Me, the child's own page on the paper (G's plan of 18 Oct, step 7; G 20 Oct: drawn on the paper, never a card that
/// pops up). Today at the top: today's pick (Mastery.upNext), with why in plain words, and the daily review. Under it
/// the three shelves of the child's lessons, side by side, a lesson moving right as its checks pass: Go over (due back
/// for a check, or its last check came back low), Getting stronger (learned, on its way through the four checks), Know
/// it (all four passed). Every card opens what it shows. It lives on the sheet left of the map, on the strong lines,
/// and draws itself in and out like everything else (SketchDrawer).
@MainActor
enum MePage {
    /// Its top-left corner on the paper: left of the map, clear of it, on the strong lines.
    static let corner = Point(-16 * Paper.unit, 0)
    static let u = Paper.unit, c = Paper.cell
    /// Its width: three shelves of cards three blocks wide, a block apart.
    static let width = 11 * Paper.unit

    /// What a tap on one of its cards does.
    enum Action: Equatable { case lesson(String), review }

    /// Me as it stands: its drawing, where its cards are and what each opens, and the part the camera shows.
    @MainActor struct Sheet {
        var sketch = Sketch()
        var taps: [(rect: CGRect, action: Action)] = []
        var frame = Rect(x: 0, y: 0, width: 1, height: 1)
    }

    /// The three shelves, in order, with what each says when it's empty.
    static let shelves: [(name: String, empty: String)] = [
        ("Go over", "Nothing to go over."), ("Getting stronger", "Learned lessons come here."), ("Know it", "Pass all four checks."),
    ]

    /// Me now. `seed`: the day's review shows the lessons it will draw from (nothing random: it only says how many).
    static func sheet(now: Double) -> Sheet {
        var out = Sheet(), s = Sketch()
        let x0 = corner.x, y0 = corner.y, p = Progress.shared, checks = p.checks
        func R(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> CGRect { CGRect(x: x, y: y, width: w, height: h) }

        // Today: the pick, and the review
        s.words("me-today", "Today", .heading, x: x0, top: y0 + u / 2 - Sketch.row / 2, width: 1200)
        let pickRect = R(x0, y0 + u, 3 * u, 2 * u)
        if let pick = Map.today {
            let reason = todayReason(pick, now: now)
            let pen = Pen.chapter(pick.chapter)
            let goOver: Bool = { switch reason { case .due, .low, .helps: true; default: false } }()
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
        reviewCard(&s, &out, R(x0 + 4 * u, y0 + u, 3 * u, 2 * u), now: now)

        // the shelves, side by side: a lesson moves right as its checks pass
        // getting stronger: the next check soonest first, so what's coming is on top
        let sh = Mastery.shelves(Map.gradeLessons, checks: checks, now: now)
        let lists = [sh.goOver, sh.gettingStronger.sorted { (checks[$0]?.due ?? 0) < (checks[$1]?.due ?? 0) }, sh.knowIt]
        let top = y0 + 5 * u
        for (k, list) in lists.enumerated() {
            let x = x0 + 4 * Double(k) * u
            let (name, empty) = shelves[k]
            s.words("me-shelf\(k)", name, .heading, x: x, top: top - u / 2 - Sketch.row / 2, width: 3.6 * u)
            let w = PaperText.width(name, PaperText.font(Sketch.Words.heading.size, Sketch.Words.heading.weight))
            s.text("me-shelf\(k)n:\(list.count)", "\(list.count)", at: CGPoint(x: x + w + 12, y: top - u / 2), size: Sketch.small, weight: .regular, .ink3,
                   anchor: UnitPoint(x: 0, y: 0.5), slot: "me-shelf\(k)n")
            if list.isEmpty {
                let r = R(x, top, 3 * u, u)
                s.frame("me-empty\(k)", r, .locked, pen: .ink)
                s.label("me-empty\(k)w", empty, Sketch.Words.status, at: CGPoint(x: r.minX + c, y: r.midY), anchor: UnitPoint(x: 0, y: 0.5))
                continue
            }
            // the shelf's cards stacked one on another, a block each, as a shelf of them
            for (j, id) in list.enumerated() {
                guard let piece = Map.piece(id), let check = checks[id] else { continue }
                let r = R(x, top + Double(j) * u, 3 * u, u)
                lessonCard(&s, piece, check, shelf: k, in: r, now: now)
                out.taps.append((r, .lesson(id)))
            }
        }
        let rows = max(1, lists.map(\.count).max() ?? 1)
        out.frame = Rect(x: x0, y: y0, width: width, height: 5 * u + Double(rows) * u + c)
        out.sketch = s
        return out
    }

    // MARK: the cards

    /// A lesson on a shelf: a card three blocks by one in its chapter's colour, its name on its top row and where it
    /// stands on the row under it: to go over, why; otherwise its four checks as a bar of four squares, as many shaded as
    /// are passed (a bar like the fractions', so it reads as "2 of 4"), and when the next one is.
    private static func lessonCard(_ s: inout Sketch, _ p: Piece, _ check: CheckRecord, shelf: Int, in r: CGRect, now: Double) {
        let pen = Pen.chapter(p.chapter), id = "me-card-\(p.id)"
        // to go over is something to do: lit, as up next is on the map; the others are learned: lightly filled
        s.frame(id, r, shelf == 0 ? .now : .done, pen: pen)
        let top = r.minY + 1.5 * c, low = r.minY + 3.5 * c
        s.label("\(id)name", p.name, .label, at: CGPoint(x: r.minX + c, y: top), anchor: UnitPoint(x: 0, y: 0.5))
        if shelf == 0 {
            let due = Mastery.dueBack(Progress.shared.checks, p.id, now: now)
            s.label("\(id)line", due ? "Time to check it again" : "Came back low", Sketch.Words.status.colour(pen.full),
                    at: CGPoint(x: r.minX + c, y: low), anchor: UnitPoint(x: 0, y: 0.5))
            return
        }
        let passed = min(Mastery.reviewDays.count, check.passes)
        checksBar(&s, id, passed: passed, at: CGPoint(x: r.minX + c, y: low - c / 2), pen: pen)
        let line: String = {
            if passed >= Mastery.reviewDays.count { return "All four passed" }
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
    /// checked yet), dashed.
    private static func reviewCard(_ s: inout Sketch, _ out: inout Sheet, _ r: CGRect, now: Double) {
        let p = Progress.shared, id = "me-review"
        let ready = Review.ready(Map.gradeLessons, checks: p.checks)
        let done = p.todaysReview, partway = PaperModel.reviewPartway(now: now)
        let state: Sketch.FrameState = !ready && done == nil ? .locked : done != nil ? .done : partway != nil ? .now : .open
        s.frame(id, r, state, pen: .ink)
        if done != nil { s.tab(id, frame: r, "Done", pen: .ink) }
        let big = done.map { "\($0.right) of \($0.of) right" } ?? "\(Review.problems) problems"
        let small = done != nil ? "Done today" : "from your lessons"
        s.text("\(id)big:\(big)", big, at: CGPoint(x: r.midX, y: r.minY + 4 * c), size: Sketch.wordSize, weight: .medium, ready || done != nil ? .ink : .ink3, digits: true)
        s.text("\(id)small:\(small)", small, at: CGPoint(x: r.midX, y: r.minY + 6 * c), size: Sketch.small, weight: .regular, .ink2, digits: false)
        s.label("\(id)name", "Daily review", .label, at: CGPoint(x: r.minX, y: r.maxY + 30), anchor: UnitPoint(x: 0, y: 0.5))
        let line: (String, Sketch.Colour) = {
            if done != nil { return ("A new one tomorrow", .ink3) }
            if let n = partway { return ("\(n) of \(Review.problems) done", .ink) }
            if !ready { return ("Take two lesson tests first", .ink3) }
            return ("One try each, no help", .ink3)
        }()
        s.label("\(id)line", line.0, Sketch.Words.status.colour(line.1), at: CGPoint(x: r.minX, y: r.maxY + 50), anchor: UnitPoint(x: 0, y: 0.5), slot: "\(id)line")
        if ready || done != nil { out.taps.append((r, .review)) }
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
        case .due: return "Time to check it again"
        case .low: return "Its last check came back low"
        case .helps(let id): return "It helps with \(name(id))"
        case .buildsOn(let id): return "It builds on \(name(id))"
        case .first: return "The first lesson"
        case .next: return "Next in \(pick.chapter.title)"
        case .oldest: return "Checked the longest ago"
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
    mutating func frame(_ id: String, _ r: CGRect, _ state: FrameState, pen: Pen) {
        let corners = [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.minX, y: r.minY)]
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
