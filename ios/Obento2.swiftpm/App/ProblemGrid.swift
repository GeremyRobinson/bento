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
        var inline = false, workW = 0.0, sayW = 0.0 }
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
        let wb = d.box.map { b in (d.work.bounds ?? boxRect(b)).union(boxRect(b)) } ?? d.work.bounds
        if plan.inline {
            let P = piece(pb), W = piece(wb), k = plan.k
            let wx = plan.arrangement == 1 ? next(P.w + 2 * sq) : 0, wy = plan.arrangement == 1 ? 0 : next(P.h + sq)
            var out = WorkProblem.Layout()
            out.scale = k; out.inline = true
            out.pictureOffset = CGPoint(x: -floorSq(Double(pb?.minX ?? 0)), y: -floorSq(Double(pb?.minY ?? 0)))
            out.workOffset = CGPoint(x: wx - floorSq(Double(wb?.minX ?? 0)), y: wy - floorSq(Double(wb?.minY ?? 0)))
            // the box where the work puts it; what to do level with it, beside the work; Check a square under the work
            if let b = d.box { out.box = (b.right + out.workOffset.x, b.mid + out.workOffset.y, b.cell) }
            // what to do: level with the box when there is one, else on the work's first row; always on a line of the
            // grid and never above the work, so it keeps its square from the picture (G 19 Oct: nothing floats)
            let sayX = wx + next(plan.workW + 2 * sq)
            let row = out.box.map { (($0.mid - Sketch.row * k / 2) / sq).rounded() * sq } ?? wy
            out.sayAt = CGPoint(x: sayX, y: max(wy, row))
            out.sayWidth = plan.sayW
            out.checkAt = CGPoint(x: wx, y: ((wy + W.h + sq) / sq).rounded(.up) * sq)
            out.column = 600
            let width = max(plan.arrangement == 1 ? wx + plan.W.w : max(P.w, plan.W.w), 1)
            out.total = width / k
            // what to do takes as many rows as its words wrap to (up to two), its box holding all of them
            let sayFont = PaperText.font(Sketch.Words.say.size * k, Sketch.Words.say.weight)
            let rows = Double(min(2, PaperText.wrap(m.intro ?? l.words.say, sayFont, width: max(plan.sayW, 300)).count))
            out.sections = [CGRect(x: 0, y: 0, width: P.w, height: P.h), CGRect(x: wx, y: wy, width: W.w, height: W.h),
                            CGRect(x: sayX, y: out.sayAt.y, width: plan.sayW, height: Sketch.row * k * max(1, rows)),
                            CGRect(x: wx, y: out.checkAt.y, width: 120 * k, height: 40 * k)]
            out.width = (width + 2 * block) / block / k
            out.height = (max(P.h, wy + plan.W.h) + 3 * block) / block / k
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

    /// The answer box as wide as it starts (three digits) in the work's points.
    static func boxRect(_ b: (right: Double, mid: Double, cell: Double)) -> CGRect {
        // with its half cell of room for the cursor, so the box stays inside the work's section
        CGRect(x: b.right - 3 * b.cell, y: b.mid - b.cell / 2, width: 3.5 * b.cell, height: b.cell)
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
        var pb: CGRect?, wb: CGRect?, inline = false
        for step in l.steps {
            let keys = step.picture.merging(step.onMiss) { $1 }.merging(["box": step.answer.map { $0.choices == nil ? 1 : 0 } ?? 0]) { $1 }
            let d = LessonPictures.drawing(id, n, keys)
            if let b = d.box { inline = true; wb = (wb ?? boxRect(b)).union(boxRect(b)) }
            if let b = d.picture.bounds { pb = pb.map { $0.union(b) } ?? b }
            if let b = d.work.bounds { wb = wb.map { $0.union(b) } ?? b }
        }
        func piece(_ b: CGRect?) -> Piece { b.map { Piece(w: $0.maxX - floorSq($0.minX), h: $0.maxY - floorSq($0.minY)) } ?? Piece() }
        let P = piece(pb), W = piece(wb)

        if inline {
            // what to do beside the work (as wide as its longest, up to six blocks), Check a square under it
            let sayFont = PaperText.font(Sketch.Words.say.size * k, Sketch.Words.say.weight)
            let sayW = min(600 * k, l.steps.map { PaperText.width($0.words.say, sayFont) }.max() ?? 0)
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
