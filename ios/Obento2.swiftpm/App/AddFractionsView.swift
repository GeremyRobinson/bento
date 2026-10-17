import SwiftUI

/// Add with different bottoms: the words, numbers and buttons on top of the bars. The bars themselves are in the
/// paper's scene (PaperScene). Everything is pinned to the paper with the paper's own camera, so it pans and zooms as one sheet.
struct AddFractionsView: View {
    let model: AddFractionsModel
    let camera: PaperCamera
    let time: Double
    let top: CGFloat
    let onBack: () -> Void

    var body: some View {
        let k = camera.zoom, s = model.problem, l = model.lesson, words = l.words
        let o = model.origin, W = model.wholeWidth, e = model.coverEnd
        let r1 = AddFractionsModel.row1, r2 = AddFractionsModel.row2, h = AddFractionsModel.barHeight
        let at = { (x: Double, y: Double) -> CGPoint in let p = camera.toScreen(Point(o.x + x, o.y + y)); return CGPoint(x: p.x, y: p.y) }
        let shown = model.words(at: time), fresh = ease((time - model.wordsAt) / 0.5)
        let chapter = model.chapter.color

        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Text(words.say).font(Typeface.question).foregroundStyle(Ink.ink).frame(height: 40, alignment: .leading)
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

            if l.step == .add && l.added.isEmpty {
                Text("+ \(s.q)/\(s.b)").font(Typeface.font(15, .medium)).monospacedDigit().foregroundStyle(Ink.ink2)
                    .pinned(at(W + 20, r2 - 8), .bottomLeading, k)
            }
            if l.step == .add || l.step == .done {
                Text("\(s.p)/\(s.a) = \(s.covered)/\(s.b)").font(Typeface.font(22, .medium)).monospacedDigit().foregroundStyle(chapter)
                    .pinned(at(e + 24, r2 - 12), .bottomLeading, k)
            }
            if l.step == .cover {
                Text(l.guideLine).font(Typeface.font(13)).foregroundStyle(Ink.ink2).opacity(model.guide(at: time))
                    .pinned(at(e + 10, r1 - 24), .bottomLeading, k)
            }
            if l.step == .cover || l.step == .add {
                Group {
                    if let m = model.message { Text(m.text).foregroundStyle(m.ok ? Ink.right : chapter) }
                    else { Text(l.countLine).foregroundStyle(Ink.ink2) }
                }
                .font(Typeface.font(17, .medium)).fixedSize()
                .pinned(at(0, r2 + h + 12), .topLeading, k)
            }
            if l.step == .done {
                Text("\(s.sum) = \(s.total)/\(s.b)").font(Typeface.font(22, .medium)).monospacedDigit().foregroundStyle(chapter)
                    .opacity(ease((time - model.wordsAt - 0.5) / 0.4))
                    .pinned(at(0, r2 + h + 40), .topLeading, k)
            }

            HStack(spacing: -1.5) {
                if l.step == .cover || l.step == .add {
                    CellButton(action: model.showMe) { Icon(name: "play") }
                    CellButton(action: model.reset) { Icon(name: "arrow-counter-clockwise") }
                    Color.clear.frame(width: 40, height: 40)
                }
                MainCellButton(title: words.action, action: model.go)
            }
            .opacity(shown)
            .pinned(at(0, 440), .topLeading, k)

            LessonHeader(title: "Add with different bottoms", subtitle: "Fractions · Lesson 03", top: top, onBack: onBack)
        }
    }
}
