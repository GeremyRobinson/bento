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

    static let block = Paper.unit, sq = Paper.cell
    /// The next block line at or after `x`.
    static func next(_ x: Double) -> Double { (x / block - 1e-6).rounded(.up) * block }
    static func floorSq(_ x: Double) -> Double { (x / sq).rounded(.down) * sq }

    struct Piece { var w = 0.0, h = 0.0; var empty: Bool { w <= 0 } }

    static func layout(_ m: WorkProblem) -> WorkProblem.Layout {
        let l = m.lesson, id = l.spec.id, n = l.numbers, k = LessonPictures.scale(id, n)
        // the picture and the work, as big as they get over the problem's steps
        var pb: CGRect?, wb: CGRect?
        for step in l.steps {
            let d = LessonPictures.drawing(id, n, step.picture.merging(step.onMiss) { $1 })
            if let b = d.picture.bounds { pb = pb.map { $0.union(b) } ?? b }
            if let b = d.work.bounds { wb = wb.map { $0.union(b) } ?? b }
        }
        func piece(_ b: CGRect?) -> Piece { b.map { Piece(w: $0.maxX - floorSq($0.minX), h: $0.maxY - floorSq($0.minY)) } ?? Piece() }
        let P = piece(pb), W = piece(wb)

        // the step, in its own points before k: what to do (one row, two when long), its hint, the line, Check, and
        // what a miss says under Check; the keypad beside the line
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
        let stepH = max(actions + 3 * sq + sq + 3 * 2 * sq, 240)
        let S = Piece(w: stepW * k, h: stepH * k)

        // the arrangements: each piece's corner, and the space they take
        typealias Plan = (pic: CGPoint, work: CGPoint, step: CGPoint, size: CGSize)
        func beside(_ x: Double) -> Double { next(x + 2 * sq) }
        func under(_ y: Double) -> Double { next(y + sq) }
        var plans: [Plan] = []
        // picture and work side by side, the step under them
        do {
            let wx = W.empty ? 0 : beside(P.w), sy = under(max(P.h, W.h))
            plans.append((CGPoint(x: 0, y: 0), CGPoint(x: wx, y: 0), CGPoint(x: 0, y: sy), CGSize(width: max(wx + W.w, S.w), height: sy + S.h)))
        }
        // the picture, and beside it the work over the step
        do {
            let cx = beside(P.w), sy = W.empty ? 0 : under(W.h)
            plans.append((CGPoint(x: 0, y: 0), CGPoint(x: cx, y: 0), CGPoint(x: cx, y: sy), CGSize(width: cx + max(W.w, S.w), height: max(P.h, sy + S.h))))
        }
        // the picture across the top, the step and the work side by side under it
        do {
            let y = under(P.h), wx = beside(S.w)
            plans.append((CGPoint(x: 0, y: 0), CGPoint(x: wx, y: y), CGPoint(x: 0, y: y), CGSize(width: max(P.w, W.empty ? S.w : wx + W.w), height: y + max(S.h, W.h))))
        }
        // three columns
        do {
            let wx = beside(P.w), sx = W.empty ? wx : beside(wx + W.w)
            plans.append((CGPoint(x: 0, y: 0), CGPoint(x: wx, y: 0), CGPoint(x: sx, y: 0), CGSize(width: sx + S.w, height: max(P.h, W.h, S.h))))
        }
        // the one the screen shows biggest (the sum's row over it too)
        let availW = screen.width - 4 * sq, availH = screen.height - 24 - 120 - 4 * sq, sumH = block * k
        let best = plans.max { a, b in
            let fa = min(availW / a.size.width, availH / (a.size.height + sumH)), fb = min(availW / b.size.width, availH / (b.size.height + sumH))
            return fa < fb - 1e-9
        }!

        var out = WorkProblem.Layout()
        out.scale = k
        // the picture and the work moved so their corners land where their pieces start, by whole squares
        out.pictureOffset = CGPoint(x: best.pic.x - floorSq(Double(pb?.minX ?? 0)), y: best.pic.y - floorSq(Double(pb?.minY ?? 0)))
        out.workOffset = CGPoint(x: best.work.x - floorSq(Double(wb?.minX ?? 0)), y: best.work.y - floorSq(Double(wb?.minY ?? 0)))
        // the step's own positions, in its points before k (drawn k times bigger from the problem's origin)
        let sx = best.step.x / k, sy = best.step.y / k
        out.stepX = sx; out.stepY = sy; out.lineY = sy + lineY; out.actions = sy + actions
        out.keypadX = sx + keyX; out.keypadY = sy + lineY - sq
        out.column = stepW; out.messageBelow = true
        out.total = best.size.width / k
        out.width = (best.size.width + 2 * block) / block / k
        out.height = (best.size.height + sumH + 3 * block) / block / k
        return out
    }
}
