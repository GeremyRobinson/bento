import SwiftUI

/// Where a problem's pieces go (G 19 Oct): a layout on the grid, in the iPad's shape. A problem is three pieces, each
/// measured in the paper's points: its picture, its work as school writes it, and its step (the words, the line being
/// worked, Check and the keypad, sized for its widest step so nothing moves between steps). Each piece starts on the
/// next block line after the one before it, at least a square below or two squares beside it. The problem's sum sits
/// in its own row over them. Several arrangements are tried, and the one that fills the screen best is used: a wide
/// picture ends up across the top with the rest under it, a tall one side by side with the rest.
@MainActor
enum ProblemGrid {
    /// The screen the problem is shown on (set as it changes), and what the bar and its edges leave of it.
    static var screen = Size(1366, 1024)
    /// While testing (G 19 Oct): a dashed box round each section of a problem (the sum, the picture, the work, the step).
    static let showSections = false

    static let block = Paper.unit, sq = Paper.cell
    /// The next block line at or after `x`.
    static func next(_ x: Double) -> Double { (x / block - 1e-6).rounded(.up) * block }
    static func floorSq(_ x: Double) -> Double { (x / sq).rounded(.down) * sq }

    struct Piece { var w = 0.0, h = 0.0; var empty: Bool { w <= 0 } }

    /// The plan for a problem: the pieces' biggest sizes over its steps (the arrangement is chosen from these, so it
    /// never changes partway), and the step's own measures. Kept per numbers and screen.
    struct Plan { var P: Piece, W: Piece, S: Piece, arrangement: Int, k: Double, lineY: Double, actions: Double, keyX: Double, stepW: Double
        /// Answered in the work: the work's own width (what to do goes beside it), and what to do's width.
        var inline = false, workW = 0.0, sayW = 0.0
        /// The lesson placed its picture and work itself in one set of squares (G 20 Oct): their corner over all its
        /// steps, and the work's left edge there (Check starts on it).
        var shared = false, corner = CGPoint.zero, workLeft = 0.0 }
    private static var plans: [String: Plan] = [:]

    static func layout(_ m: WorkProblem) -> WorkProblem.Layout {
        let l = m.lesson, id = l.spec.id, n = l.numbers
        let key = "\(id) \(n) \(screen)"
        let plan = plans[key] ?? { let p = makePlan(m); plans[key] = p; return p }()
        // what's drawn now: each piece as big as it is on this step, so there's no gap waiting for what's to come;
        // as it grows the pieces after it glide along, and the camera eases out
        let d = LessonPictures.drawing(id, n, m.drawingKeys)
        func piece(_ b: CGRect?) -> Piece { b.map { Piece(w: $0.maxX - floorSq($0.minX), h: $0.maxY - floorSq($0.minY)) } ?? Piece() }
        let pb = d.picture.bounds
        // the answer box is part of the work: what comes under it starts under the box
        let wb = withBoxes(d.work.bounds, d.boxes)
        if plan.inline {
            let P = piece(pb), W = piece(wb), k = plan.k
            var out = WorkProblem.Layout()
            out.scale = k; out.inline = true
            // where the work starts, and where its bottom is now (Check goes a square under it)
            let wx: Double, wy: Double, bottom: Double
            if plan.shared {
                // the lesson's own placing: picture and work move together, so their rows stay level
                let o = CGPoint(x: -plan.corner.x, y: -plan.corner.y)
                out.pictureOffset = o; out.workOffset = o
                wx = plan.workLeft + o.x; wy = 0
                bottom = [pb, wb].compactMap { $0 }.reduce(CGRect.null) { $0.union($1) }.maxY + o.y
            } else {
                wx = plan.arrangement == 1 ? next(P.w + 2 * sq) : 0; wy = plan.arrangement == 1 ? 0 : next(P.h + sq)
                out.pictureOffset = CGPoint(x: -floorSq(Double(pb?.minX ?? 0)), y: -floorSq(Double(pb?.minY ?? 0)))
                out.workOffset = CGPoint(x: wx - floorSq(Double(wb?.minX ?? 0)), y: wy - floorSq(Double(wb?.minY ?? 0)))
                bottom = wy + W.h
            }
            // the boxes where the work puts them; what to do level with the first, beside the work; Check a square
            // under the work
            out.boxes = d.boxes.map { $0.moved(out.workOffset) }
            // what to do: level with the box when there is one, else on the work's first row; always on a line of the
            // grid and never above the work, so it keeps its square from the picture (G 19 Oct: nothing floats)
            let sayX = (plan.shared ? 0 : wx) + next(plan.workW + 2 * sq)
            let row = out.boxes.first.map { (($0.mid - Sketch.row * k / 2) / sq).rounded() * sq } ?? wy
            out.sayAt = CGPoint(x: sayX, y: max(wy, row))
            out.sayWidth = plan.sayW
            out.checkAt = CGPoint(x: wx, y: ((bottom + sq) / sq).rounded(.up) * sq)
            out.column = 600
            let width = max(plan.shared ? plan.W.w : plan.arrangement == 1 ? wx + plan.W.w : max(P.w, plan.W.w), 1)
            out.total = width / k
            // what to do takes as many rows as its words wrap to (up to two), its box holding all of them
            let sayFont = PaperText.font(Sketch.Words.say.size * k, Sketch.Words.say.weight)
            let rows = Double(min(2, PaperText.wrap(m.intro ?? l.words.say, sayFont, width: max(plan.sayW, 300)).count))
            out.sections = [CGRect(x: 0, y: 0, width: P.w, height: P.h), CGRect(x: wx, y: wy, width: W.w, height: W.h),
                            CGRect(x: sayX, y: out.sayAt.y, width: plan.sayW, height: Sketch.row * k * max(1, rows)),
                            CGRect(x: wx, y: out.checkAt.y, width: 120 * k, height: 40 * k)]
            out.width = (width + 2 * block) / block / k
            out.height = ((plan.shared ? plan.W.h : max(P.h, wy + plan.W.h)) + 3 * block) / block / k
            return out
        }
        let placed = arrange(plan.arrangement, P: piece(pb), W: piece(wb), S: plan.S)
        let k = plan.k
        var out = WorkProblem.Layout()
        out.scale = k
        out.pictureOffset = CGPoint(x: placed.pic.x - floorSq(Double(pb?.minX ?? 0)), y: placed.pic.y - floorSq(Double(pb?.minY ?? 0)))
        out.workOffset = CGPoint(x: placed.work.x - floorSq(Double(wb?.minX ?? 0)), y: placed.work.y - floorSq(Double(wb?.minY ?? 0)))
        let sx = placed.step.x / k, sy = placed.step.y / k
        out.stepX = sx; out.stepY = sy; out.lineY = sy + plan.lineY; out.actions = sy + plan.actions
        out.keypadX = sx + plan.keyX; out.keypadY = sy + plan.lineY - sq
        out.column = plan.stepW; out.messageBelow = true
        out.total = placed.size.width / k
        let P = piece(pb), W = piece(wb)
        let tall = MathLineView.layout(l.spec.display(n), size: 28).h > 2
        out.sections = [CGRect(x: 0, y: -block * k - (tall ? 2 * sq : 0), width: placed.size.width, height: block * k + (tall ? 2 * sq : 0)),
                        CGRect(x: placed.pic.x, y: placed.pic.y, width: P.w, height: P.h),
                        CGRect(x: placed.step.x, y: placed.step.y, width: plan.S.w, height: plan.S.h)]
            + (W.empty ? [] : [CGRect(x: placed.work.x, y: placed.work.y, width: W.w, height: W.h)])
        out.width = (placed.size.width + 2 * block) / block / k
        out.height = (placed.size.height + block * k + 3 * block) / block / k
        return out
    }

    // MARK: stacked: a lesson on the paper (G 20 Oct, design/README.md rule 1)

    /// A paper lesson's plan, in squares from the problem's corner, made once for its numbers: the story (when it's
    /// told as one), what to do (rows 0–2, words 28), what a miss says or the hint (rows 3–4, words 20), the picture
    /// (from row 6, its names at its right end), the record (3 rows under the picture). The rows kept for words are the
    /// most any step needs, and the record's row is under the picture's biggest step, so nothing jumps.
    struct StackPlan {
        var storyRows = 0, sayRows = 1, msgRows = 1
        /// What the words wrap to (the picture's width, or the record's), and how far the picture's end labels reach
        /// left of the edge everything starts on.
        var width = 40.0, left = 0.0
        var sayTop = 0.0, msgTop = 3.0, pictureTop = 6.0, recordTop = 24.0
        /// The words, the blocks and the record drawn k times bigger (PaperLesson.scale: 1, or 2 for a big problem).
        var k = 1.0
        /// The record beside the picture (PaperLesson.recordBeside): its left edge, on a block line past the picture,
        /// its blocks under it; 0 when it's under the picture. `recordFirst`: the record's first row, from its top, where
        /// its blocks start before it's written.
        var recordLeft = 0.0, recordFirst = 0.0
        var beside: Bool { recordLeft > 0 }
    }
    /// A stacked problem on the step it's on: its plan, its blocks' row (two squares under what's drawn now), and the
    /// rectangle the camera frames for the step (paper points from the origin).
    struct Stack {
        var plan: StackPlan
        var blocksTop = 0.0
        /// The blocks' left edge, in squares (the record's, when it's beside the picture).
        var blocksLeft = 0.0
        var frame = CGRect.zero
    }

    static func stackPlan(_ m: WorkProblem) -> StackPlan {
        var p = StackPlan()
        guard let paper = m.paper else { return p }
        let l = m.lesson, k = paper.scale(l.numbers)
        p.k = k
        // the picture and the record, as big as they get over the problem's steps, a hint's drawings and the room a
        // move makes included
        var pic: CGRect?, rec: CGRect?
        let base = PaperState(run: l, index: l.index)
        for i in l.steps.indices {
            let d = paper.draw(base.at(i, hint: true))
            for b in [d.picture.bounds, d.extent].compactMap({ $0 }) { pic = pic.map { $0.union(b) } ?? b }
            if let b = withBoxes(d.record.bounds, d.boxes) { rec = rec.map { $0.union(b) } ?? b }
        }
        p.left = min(0, ((pic?.minX ?? 0) / sq).rounded(.down))
        let picW = ((pic?.maxX ?? 0) / sq).rounded(.up), picH = ((pic?.maxY ?? 0) / sq).rounded(.up)
        let recW = ((rec?.maxX ?? 0) / sq).rounded(.up), recH = ((rec?.maxY ?? 0) / sq).rounded(.up)
        /// The plan with the record under the picture, or beside it (its left edge on a block line, two squares past the
        /// picture at least): the words wrap to what's under them.
        func made(beside: Bool) -> StackPlan {
            var q = p
            q.recordLeft = beside ? next((picW + 2 * k) * sq) / sq : 0
            q.width = max(30, beside ? q.recordLeft + recW : max(picW, recW))
            let width = q.width * sq
            // what to do, each step's (a story's pick says "Pick what to do"), and the How to's idea when it plays
            let say = PaperText.font(Sketch.Words.say.size * k, Sketch.Words.say.weight)
            var texts = l.steps.map { st in l.story && st.answer?.choices != nil ? st.words.hint : st.words.say }
            if m.auto { texts.append(l.spec.idea(l.numbers)) }
            q.sayRows = max(1, texts.map { PaperText.wrap($0, say, width: width).count }.max() ?? 1)
            if l.story, let story = l.spec.story?(l.numbers) {
                q.storyRows = PaperText.wrap(story, PaperText.font(Sketch.Words.tell.size * k, Sketch.Words.tell.weight), width: width).count
            }
            q.msgRows = paper.messageRows(l.numbers)
            q.sayTop = q.storyRows > 0 ? Double(2 * q.storyRows + 1) * k : 0
            q.msgTop = q.sayTop + Double(2 * q.sayRows + 1) * k
            q.pictureTop = q.msgTop + Double(2 * q.msgRows + 1) * k
            q.recordTop = beside ? q.pictureTop + (paper.recordBeside(l.numbers) ?? 0) : q.pictureTop + picH + 3 * k
            return q
        }
        let under = made(beside: false)
        guard paper.recordBeside(l.numbers) != nil, rec != nil else { return under }
        let side = made(beside: true)
        // the one that shows the problem bigger on this screen (G 19 Oct rule 10): its words, its picture, its record and
        // the blocks under the record, all framed
        func shown(_ q: StackPlan) -> Double {
            let blocks = 4 * k, recordEnd = q.recordTop + recH + blocks
            let h = q.beside ? max(q.pictureTop + picH, recordEnd) : recordEnd
            return ProblemGrid.zoom(squares: q.width - q.left, h)
        }
        return shown(side) > shown(under) ? side : under
    }

    /// How big a frame `w` squares wide and `h` tall shows on this screen: what the camera fits it to, clear of the bar
    /// with its margins, at most 125% (the same fit the camera makes, PaperModel.framingBelowBar).
    static func zoom(squares w: Double, _ h: Double) -> Double {
        min(CameraTiming.lessonMax, (screen.width - 4 * sq) / (max(1, w) * sq), (screen.height - 24 - 120 - 4 * sq) / (max(1, h) * sq))
    }

    /// A stacked problem's layout for the state it's in.
    static func stackedLayout(_ m: WorkProblem, _ s: PaperState) -> WorkProblem.Layout {
        let plan = m.plan ?? { let p = stackPlan(m); m.plan = p; return p }()
        var out = WorkProblem.Layout()
        out.inline = true; out.scale = 1
        out.pictureOffset = CGPoint(x: 0, y: plan.pictureTop * sq)
        out.workOffset = CGPoint(x: plan.recordLeft * sq, y: plan.recordTop * sq)
        out.sayAt = CGPoint(x: 0, y: plan.sayTop * sq); out.sayWidth = plan.width * sq
        out.total = plan.width * sq; out.column = plan.width * sq
        guard let paper = m.paper else { return out }
        let d = paper.draw(s), k = plan.k
        out.boxes = d.boxes.map { $0.moved(out.workOffset) }
        // the lesson's own blocks ("Cut"), in the How to too: the ghost finger presses them there
        out.lessonBlocks = s.run.isLast ? [] : d.actions
        // the blocks: two squares under what the step draws (the record once it's there, else the picture, with the
        // room the step's move will make, and its hint's drawings, so a miss or a hint never moves the camera); with the
        // record beside the picture, under the record (where it starts, before it's written)
        let hinted = paper.draw(s.at(s.index, hint: true))
        var bottom = plan.pictureTop * sq + ([d.picture.bounds?.maxY, d.extent?.maxY, hinted.picture.bounds?.maxY].compactMap { $0 }.max() ?? 0)
        let recordBottom = withBoxes(d.record.bounds, d.boxes).map { plan.recordTop * sq + $0.maxY }
        if !plan.beside, let r = recordBottom { bottom = max(bottom, r) }
        let blocksTop = plan.beside ? recordBottom.map { ($0 / sq).rounded(.up) + 2 * k } ?? plan.recordTop : (bottom / sq).rounded(.up) + 2 * k
        let a = s.step.answer
        // a story's choices: a row of them with Check under it, or beside a tall picture one under another
        let choiceRows = Double(a?.choices.map { plan.beside ? 3 * $0.count + 2 : 5 } ?? 0)
        let rows = k * (a?.choices != nil ? choiceRows : (!out.lessonBlocks.isEmpty || (a != nil && a?.byHand == false && !m.auto) || (s.run.isLast && !m.auto) || !m.howToButtons.isEmpty) ? 2 : 0)
        let frameBottom = max(rows > 0 ? (blocksTop + rows) * sq : 0, bottom, recordBottom ?? 0)
        out.checkAt = CGPoint(x: plan.recordLeft * sq, y: blocksTop * sq)
        out.stack = Stack(plan: plan, blocksTop: blocksTop, blocksLeft: plan.recordLeft, frame: CGRect(x: plan.left * sq, y: 0, width: (plan.width - plan.left) * sq, height: frameBottom))
        // its box (BarsPage.box: taps land in it) holds it all, in whole blocks
        out.width = ((plan.width - plan.left) * sq + 2 * block) / block
        out.height = (frameBottom + 3 * block) / block
        out.sections = [CGRect(x: 0, y: plan.pictureTop * sq, width: plan.width * sq, height: bottom - plan.pictureTop * sq)]
        return out
    }

    /// The work's bounds with its answer boxes as wide as they start (and their half cell of room for the cursor), so
    /// the boxes stay inside the work's section.
    static func withBoxes(_ work: CGRect?, _ boxes: [WorkBox]) -> CGRect? {
        boxes.reduce(work) { r, b in r.map { $0.union(b.rect()) } ?? b.rect() }
    }

    typealias Placed = (pic: CGPoint, work: CGPoint, step: CGPoint, size: CGSize)
    /// The four arrangements, by number.
    static func arrange(_ i: Int, P: Piece, W: Piece, S: Piece) -> Placed {
        func beside(_ x: Double) -> Double { next(x + 2 * sq) }
        func under(_ y: Double) -> Double { next(y + sq) }
        switch i {
        case 0: // picture and work side by side, the step under them
            let wx = W.empty ? 0 : beside(P.w), sy = under(max(P.h, W.h))
            return (CGPoint(x: 0, y: 0), CGPoint(x: wx, y: 0), CGPoint(x: 0, y: sy), CGSize(width: max(wx + W.w, S.w), height: sy + S.h))
        case 1: // the picture, and beside it the work over the step
            let cx = beside(P.w), sy = W.empty ? 0 : under(W.h)
            return (CGPoint(x: 0, y: 0), CGPoint(x: cx, y: 0), CGPoint(x: cx, y: sy), CGSize(width: cx + max(W.w, S.w), height: max(P.h, sy + S.h)))
        case 2: // the picture across the top, the step and the work side by side under it
            let y = under(P.h), wx = beside(S.w)
            return (CGPoint(x: 0, y: 0), CGPoint(x: wx, y: y), CGPoint(x: 0, y: y), CGSize(width: max(P.w, W.empty ? S.w : wx + W.w), height: y + max(S.h, W.h)))
        default: // three columns
            let wx = beside(P.w), sx = W.empty ? wx : beside(wx + W.w)
            return (CGPoint(x: 0, y: 0), CGPoint(x: wx, y: 0), CGPoint(x: sx, y: 0), CGSize(width: sx + S.w, height: max(P.h, W.h, S.h)))
        }
    }

    static func makePlan(_ m: WorkProblem) -> Plan {
        let l = m.lesson, id = l.spec.id, n = l.numbers, k = LessonPictures.scale(id, n)
        // the picture and the work, as big as they get over the problem's steps
        var pb: CGRect?, wb: CGRect?, inline = false, shared = false
        for step in l.steps {
            let keys = step.picture.merging(step.onMiss) { $1 }.merging(["box": step.answer.map { $0.choices == nil ? 1 : 0 } ?? 0]) { $1 }
            let d = LessonPictures.drawing(id, n, keys)
            if !d.boxes.isEmpty { inline = true }
            shared = shared || d.shared
            if let b = d.picture.bounds { pb = pb.map { $0.union(b) } ?? b }
            if let b = withBoxes(d.work.bounds, d.boxes) { wb = wb.map { $0.union(b) } ?? b }
        }
        func piece(_ b: CGRect?) -> Piece { b.map { Piece(w: $0.maxX - floorSq($0.minX), h: $0.maxY - floorSq($0.minY)) } ?? Piece() }
        let P = piece(pb), W = piece(wb)

        if inline {
            // what to do beside the work (as wide as its longest, up to six blocks), Check a square under it
            let sayFont = PaperText.font(Sketch.Words.say.size * k, Sketch.Words.say.weight)
            let sayW = min(600 * k, l.steps.map { PaperText.width($0.words.say, sayFont) }.max() ?? 0)
            if shared {
                // the lesson placed its pieces: kept as they are, what to do beside them all, Check under the work
                let u = [pb, wb].compactMap { $0 }.reduce(CGRect.null) { $0.union($1) }
                let corner = CGPoint(x: floorSq(u.minX), y: floorSq(u.minY)), uw = u.maxX - corner.x
                // what to do wraps onto a second row rather than pushing the camera back (20 squares at most)
                let sayW = min(sayW, 400 * k)
                let Wfull = Piece(w: next(uw + 2 * sq) + sayW, h: u.maxY - corner.y + sq + 2 * sq * k + 3 * 2 * sq * k)
                return Plan(P: P, W: Wfull, S: Piece(), arrangement: 1, k: k, lineY: 0, actions: 0, keyX: 0, stepW: 600, inline: true,
                            workW: uw, sayW: sayW, shared: true, corner: corner, workLeft: floorSq(Double(wb?.minX ?? 0)))
            }
            let Wfull = Piece(w: next(W.w + 2 * sq) + sayW, h: W.h + sq + 2 * sq * k + 3 * 2 * sq * k)
            let availW = screen.width - 4 * sq, availH = screen.height - 24 - 120 - 4 * sq
            let side = CGSize(width: next(P.w + 2 * sq) + Wfull.w, height: max(P.h, Wfull.h))
            let stack = CGSize(width: max(P.w, Wfull.w), height: next(P.h + sq) + Wfull.h)
            let pick = min(availW / side.width, availH / side.height) >= min(availW / stack.width, availH / stack.height) ? 1 : 2
            return Plan(P: P, W: Wfull, S: Piece(), arrangement: pick, k: k, lineY: 0, actions: 0, keyX: 0, stepW: 600, inline: true, workW: W.w, sayW: sayW)
        }
        // the step, in its own points before k: what to do (one row, two when long), its hint, the line, Check, and
        // what a miss says under Check
        let sayFont = PaperText.font(Sketch.Words.say.size, Sketch.Words.say.weight), cap = 800.0
        let sayW = l.steps.map { PaperText.width($0.words.say, sayFont) }.max() ?? 0
        let rows: Double = sayW > cap ? 2 : 1
        let prompts = l.steps.compactMap { $0.answer.flatMap { $0.choices == nil ? $0.prompt : nil } }
        let lineCell = sq * WorkProblem.lineCell
        let lineW = prompts.map { Double(MathLineView.layout($0, size: 28).w + 2) * lineCell }.max() ?? 0
        let lineH = prompts.map { Double(MathLineView.layout($0, size: 28).h) * lineCell }.max() ?? 2 * lineCell
        let lineY = ((rows * 2 + 2) * sq / sq).rounded(.up) * sq + sq
        let actions = ((lineY + lineH + sq) / sq).rounded(.up) * sq
        let keyX = ((lineW + 2 * sq) / sq).rounded(.up) * sq
        let choices = l.steps.contains { $0.answer?.choices != nil } ? 720.0 : 0
        let stepW = max(min(sayW, cap), WorkProblem.drawnKeys ? keyX + 180 : lineW, choices, 260)
        // just what's always there: the words, the line and Check (a message under it grows the problem when it comes)
        let stepH = actions + 2 * sq
        let S = Piece(w: stepW * k, h: stepH * k)
        // the arrangement the screen shows biggest (the sum's row over it too)
        let availW = screen.width - 4 * sq, availH = screen.height - 24 - 120 - 4 * sq, sumH = block * k
        let best = (0..<4).max { a, b in
            let pa = arrange(a, P: P, W: W, S: S).size, pb = arrange(b, P: P, W: W, S: S).size
            return min(availW / pa.width, availH / (pa.height + sumH)) < min(availW / pb.width, availH / (pb.height + sumH)) - 1e-9
        }!
        return Plan(P: P, W: W, S: S, arrangement: best, k: k, lineY: lineY, actions: actions, keyX: keyX, stepW: stepW)
    }
}
