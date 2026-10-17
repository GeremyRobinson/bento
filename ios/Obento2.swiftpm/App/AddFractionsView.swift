import SwiftUI

/// Add with different bottoms: the words, numbers and buttons on top of the bars. The bars themselves are in the
/// paper's scene (PaperScene). Everything is pinned to the paper with the paper's own camera, so it pans and zooms as one sheet.
struct AddFractionsView: View {
    let model: AddFractionsModel
    let camera: PaperCamera
    let time: Double
    /// The How to's own block, once it has played.
    var watchAgain: (() -> Void)?

    var body: some View {
        let k = camera.zoom, s = model.problem, l = model.lesson, words = l.words
        let o = model.origin, W = model.wholeWidth, e = model.coverEnd
        let r1 = AddFractionsModel.row1, r2 = AddFractionsModel.row2, h = AddFractionsModel.barHeight
        let at = { (x: Double, y: Double) -> CGPoint in let p = camera.toScreen(Point(o.x + x, o.y + y)); return CGPoint(x: p.x, y: p.y) }
        let shown = model.words(at: time), fresh = ease((time - model.wordsAt) / 0.5)
        let chapter = model.chapter.color

        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                // a story runs onto more lines, growing up from the hint
                Text(words.say).font(Typeface.question).foregroundStyle(Ink.ink).lineLimit(4).fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 40, alignment: .bottomLeading)
                Text(words.hint).font(Typeface.hint).foregroundStyle(Ink.ink2).frame(height: 20, alignment: .leading)
            }
            .frame(width: 480, alignment: .leading)
            .opacity(fresh).offset(y: (1 - fresh) * 8)
            .pinned(at(0, 0), .bottomLeading, k)

            Group {
                Text(s.sum).font(Typeface.font(40, .medium)).monospacedDigit().foregroundStyle(Ink.ink)
                    .pinned(at(0, 60), .bottomLeading, k)
                Text("1 whole · \(s.wholeCells) cells").font(Typeface.font(13)).foregroundStyle(Ink.ink2)
                    .pinned(at(W / 2, 88), .bottom, k)
                Text(AddFractions.plural(s.a)).font(Typeface.font(15, .medium)).foregroundStyle(Ink.ink2)
                    .pinned(at(0, r1 - 8), .bottomLeading, k)
                Text(AddFractions.plural(s.b)).font(Typeface.font(15, .medium)).foregroundStyle(Ink.ink2)
                    .pinned(at(0, r2 - 8), .bottomLeading, k)
            }
            .opacity(shown)

            if l.picture["waiting"] == 1 && l.marked.isEmpty {
                Text("+ \(s.q)/\(s.b)").font(Typeface.font(15, .medium)).monospacedDigit().foregroundStyle(Ink.ink2)
                    .pinned(at(W + 20, r2 - 8), .bottomLeading, k)
            }
            if l.picture["match"] == 1 {
                Text("\(s.p)/\(s.a) = \(s.covered)/\(s.b)").font(Typeface.font(22, .medium)).monospacedDigit().foregroundStyle(chapter)
                    .pinned(at(e + 24, r2 - 12), .bottomLeading, k)
            }
            if l.picture["guide"] == 1, let look = l.step.look {
                Text(look).font(Typeface.font(13)).foregroundStyle(Ink.ink2).opacity(model.guide(at: time))
                    .pinned(at(e + 10, r1 - 24), .bottomLeading, k)
            }
            // a pick-one step: the choices are cell blocks under the bars, the message under them
            if let choices = l.step.answer?.choices {
                HStack(spacing: -1.5) {
                    ForEach(Array(choices.enumerated()), id: \.offset) { i, c in
                        CellButton(width: 120, main: l.typed["c"] == String(i), action: { model.choose(i) }) { Text(c).font(Typeface.button) }
                    }
                }
                .opacity(shown)
                .pinned(at(0, r2 + h + 12), .topLeading, k)
                if let m = model.message {
                    Text(m.text).font(Typeface.font(17, .medium)).foregroundStyle(chapter).fixedSize()
                        .pinned(at(0, r2 + h + 60), .topLeading, k)
                }
            }
            if let count = l.countLine {
                Group {
                    if let m = model.message { Text(m.text).foregroundStyle(m.ok ? Ink.right : chapter) }
                    else { Text(count).foregroundStyle(Ink.ink2) }
                }
                .font(Typeface.font(17, .medium)).fixedSize()
                .pinned(at(0, r2 + h + 20), .topLeading, k)
            }
            if l.picture["total"] == 1 {
                Text("\(s.sum) = \(s.total)/\(s.b)").font(Typeface.font(22, .medium)).monospacedDigit().foregroundStyle(chapter)
                    .opacity(ease((time - model.wordsAt - 0.5) / 0.4))
                    .pinned(at(0, r2 + h + 40), .topLeading, k)
            }

            // the action blocks: Show me (not in the skill check; outlined when it's the third hint), Reset, the main action.
            // Hands off while a See beat plays: they grey out until it ends. A solved problem has none: it stays solved.
            // The How to plays itself, and offers Watch again once it has.
            HStack(spacing: -1.5) {
                if model.auto {
                    if model.solved, let watchAgain { MainCellButton(title: "Watch again", action: watchAgain) }
                } else if !model.solved {
                    if l.step.task != nil {
                        if l.helps { CellButton(main: l.picture["showMe"] == 1, action: model.showMe) { Icon(name: "play") } }
                        CellButton(action: model.reset) { Icon(name: "arrow-counter-clockwise") }
                        Color.clear.frame(width: 40, height: 40)
                    }
                    MainCellButton(title: words.action, action: model.go)
                }
            }
            .opacity(model.busy ? 0.35 * shown : shown).allowsHitTesting(!model.busy)
            .pinned(at(0, 440), .topLeading, k)

            Text(model.label + (model.solved && !model.auto ? " · done" : "")).font(Typeface.font(13, .medium))
                .foregroundStyle(model.solved && !model.auto ? chapter : Ink.ink3).opacity(shown)
                .pinned(at(0, 500), .topLeading, k)

        }
    }
}
