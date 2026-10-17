import SwiftUI
import ObentoCore

/// The whole app is one sheet of paper. The grid, the lessons and the controls all sit on its cells.
struct PaperScreen: View {
    @State var model: PaperModel
    @State private var lastDrag: CGSize = .zero
    @State private var lastPinch: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(paused: !animating)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                let cam = model.camera(at: t)
                ZStack(alignment: .topLeading) {
                    Ink.paper
                    if model.lesson == nil {
                        GridLayer(camera: cam)
                        PiecesLayer(camera: cam, time: t, drawnAt: model.drawnAt, selected: model.selected)
                    }
                    if let lesson = model.lesson {
                        UnitCubesView(model: lesson, time: t, onBack: { model.close() })
                    } else {
                        surfaceGestures
                    }
                    ZoomCells(model: model, lessonOpen: model.lesson != nil)
                }
                .onChange(of: t) { _, now in model.settle(at: now); model.lesson?.settle(at: now) }
            }
            .onAppear { model.screen = Size(geo.size.width, geo.size.height); if !Shots.active { model.frameGroup(duration: 0) } ; Shots.run(model) }
            .onChange(of: geo.size) { _, s in model.screen = Size(s.width, s.height) }
        }
        .ignoresSafeArea()
    }

    /// The clock only runs while something moves or draws, so a still paper costs nothing.
    private var animating: Bool {
        model.moving || Clock.now - model.drawnAt < PiecesLayer.drawTime + 0.2 || (model.lesson?.animating ?? false)
    }

    private var surfaceGestures: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 4)
                .onChanged { v in
                    model.pan(v.translation.width - lastDrag.width, v.translation.height - lastDrag.height); lastDrag = v.translation }
                .onEnded { _ in lastDrag = .zero })
            .simultaneousGesture(MagnifyGesture()
                .onChanged { v in
                    model.zoom(by: v.magnification / lastPinch, at: .init(v.startLocation.x, v.startLocation.y)); lastPinch = v.magnification }
                .onEnded { _ in lastPinch = 1 })
            .simultaneousGesture(SpatialTapGesture().onEnded { v in model.tap(at: .init(v.location.x, v.location.y)) })
    }
}

/// The paper's grid: a thin line every cell, a stronger line every five. Drawn from the camera, so it IS the paper.
struct GridLayer: View {
    let camera: PaperCamera
    var body: some View {
        Canvas { ctx, size in
            let step = Paper.cell * camera.zoom
            let tl = camera.toPaper(.init(0, 0)), br = camera.toPaper(.init(size.width, size.height))
            var minor = Path(), major = Path()
            let i0 = Int(floor(tl.x / Paper.cell)), i1 = Int(ceil(br.x / Paper.cell))
            let j0 = Int(floor(tl.y / Paper.cell)), j1 = Int(ceil(br.y / Paper.cell))
            for i in i0...i1 {
                let x = (Double(i) * step + camera.x).rounded() + 0.5
                var p = i % Paper.major == 0 ? major : minor
                p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height))
                if i % Paper.major == 0 { major = p } else { minor = p }
            }
            for j in j0...j1 {
                let y = (Double(j) * step + camera.y).rounded() + 0.5
                var p = j % Paper.major == 0 ? major : minor
                p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y))
                if j % Paper.major == 0 { major = p } else { minor = p }
            }
            ctx.stroke(minor, with: .color(Ink.gridMinor), lineWidth: 1)
            ctx.stroke(major, with: .color(Ink.gridMajor), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

/// Each lesson is a small drawing of its own maths. Learned = full colour; not yet = light pencil.
/// They draw themselves in when the paper opens, outward from today's lesson.
struct PiecesLayer: View {
    let camera: PaperCamera
    let time: Double
    let drawnAt: Double
    let selected: Piece?
    static let drawTime = 1.6

    var body: some View {
        Canvas { ctx, _ in
            let z = camera.zoom
            ctx.translateBy(x: camera.x, y: camera.y); ctx.scaleBy(x: z, y: z)
            let now = Volume.pieces.first { $0.state == .now }!.frame.mid
            // chapter title, baseline on a grid line
            ctx.draw(Text(Volume.title).font(Typeface.title).foregroundStyle(Ink.ink), at: CGPoint(x: 0, y: 40), anchor: .bottomLeading)
            for p in Volume.pieces {
                let d = hypot(p.frame.mid.x - now.x, p.frame.mid.y - now.y) / 900
                let k = ease((time - drawnAt - d) / 0.9)
                draw(p, k: k, in: &ctx)
            }
        }
        .allowsHitTesting(false)
    }

    private func draw(_ p: Piece, k: Double, in ctx: inout GraphicsContext) {
        let r = CGRect(x: p.at.x, y: p.at.y, width: Piece.size.width, height: Piece.size.height)
        let on = selected?.id == p.id
        let colour = p.state == .notYet ? Ink.pencil : p.chapter.color
        ctx.stroke(Path(r).trimmedPath(from: 0, to: k), with: .color(on ? Ink.ink : Ink.lineStrong), lineWidth: on ? 2 : 1.5)
        ctx.stroke(picture(p, in: r).trimmedPath(from: 0, to: k), with: .color(colour), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        var t = ctx; t.opacity = k
        t.draw(Text(p.name).font(Typeface.name).foregroundStyle(Ink.ink), at: CGPoint(x: r.minX, y: r.maxY + 28), anchor: .bottomLeading)
        if p.state == .now {
            let tag = CGRect(x: r.maxX - 80, y: r.minY - 20, width: 80, height: 20)
            t.fill(Path(tag), with: .color(p.chapter.color))
            t.draw(Text("Up next").font(Typeface.font(12, .semibold)).foregroundStyle(.white), at: CGPoint(x: tag.midX, y: tag.midY))
        }
        if on && p.opens {
            let s = CGRect(x: p.start.x, y: p.start.y, width: p.start.width, height: p.start.height)
            t.fill(Path(s), with: .color(Ink.surface))
            t.stroke(Path(s.insetBy(dx: 0.75, dy: 0.75)), with: .color(Ink.ink), lineWidth: 1.5)
            t.draw(Text("Start").font(Typeface.button).foregroundStyle(Ink.ink), at: CGPoint(x: s.minX + 16, y: s.midY), anchor: .leading)
            t.draw(Image("ph-arrow-right"), in: CGRect(x: s.maxX - 30, y: s.midY - 10, width: 20, height: 20))
        }
    }

    /// The lesson's own picture, every point on the grid.
    private func picture(_ p: Piece, in r: CGRect) -> Path {
        var path = Path()
        let c = Paper.cell
        switch p.id {
        case "sq": // a 4 x 3 floor of squares
            for i in 0...4 { path.move(to: CGPoint(x: r.minX + 40 + Double(i) * 2 * c, y: r.minY + 30)); path.addLine(to: CGPoint(x: r.minX + 40 + Double(i) * 2 * c, y: r.minY + 150)) }
            for j in 0...3 { path.move(to: CGPoint(x: r.minX + 40, y: r.minY + 30 + Double(j) * 2 * c)); path.addLine(to: CGPoint(x: r.minX + 200, y: r.minY + 30 + Double(j) * 2 * c)) }
        case "uc": // one cube, drawn on the grid
            let x = r.minX + 80, y = r.minY + 60, s = 4 * c, o = 2 * c
            path.addRect(CGRect(x: x, y: y, width: s, height: s))
            path.move(to: CGPoint(x: x, y: y)); path.addLine(to: CGPoint(x: x + o, y: y - o)); path.addLine(to: CGPoint(x: x + s + o, y: y - o)); path.addLine(to: CGPoint(x: x + s, y: y))
            path.move(to: CGPoint(x: x + s + o, y: y - o)); path.addLine(to: CGPoint(x: x + s + o, y: y + s - o)); path.addLine(to: CGPoint(x: x + s, y: y + s))
        case "ly": // two layers
            for k in 0..<2 { path.addRect(CGRect(x: r.minX + 40, y: r.minY + 50 + Double(k) * 2 * c, width: 8 * c, height: 2 * c)) }
        default: // a box with its three sides
            path.addRect(CGRect(x: r.minX + 40, y: r.minY + 60, width: 6 * c, height: 4 * c))
            path.move(to: CGPoint(x: r.minX + 40, y: r.minY + 60)); path.addLine(to: CGPoint(x: r.minX + 80, y: r.minY + 20)); path.addLine(to: CGPoint(x: r.minX + 200, y: r.minY + 20)); path.addLine(to: CGPoint(x: r.minX + 160, y: r.minY + 60))
            path.move(to: CGPoint(x: r.minX + 200, y: r.minY + 20)); path.addLine(to: CGPoint(x: r.minX + 200, y: r.minY + 100)); path.addLine(to: CGPoint(x: r.minX + 160, y: r.minY + 140))
        }
        return path
    }
}

/// The zoom cells: − % + | find next | fit the group. Inside a lesson the group button goes away.
struct ZoomCells: View {
    let model: PaperModel
    let lessonOpen: Bool
    var body: some View {
        let pct = model.lesson?.scale ?? model.camera(at: Clock.now).zoom
        HStack(spacing: -1.5) {
            CellButton(action: { lessonOpen ? model.lesson?.zoom(1 / 1.25) : model.zoomButton(1 / 1.25) }) { Icon(name: "minus") }
            CellButton(width: 64, action: {}) {
                Text("\(Int((pct * 100).rounded()))%").font(Typeface.font(14, .medium)).monospacedDigit()
            }
            CellButton(action: { lessonOpen ? model.lesson?.zoom(1.25) : model.zoomButton(1.25) }) { Icon(name: "plus") }
            Color.clear.frame(width: 20, height: 40)
            if !lessonOpen {
                CellButton(action: { model.findNext() }) { Icon(name: "crosshair") }
                CellButton(action: { model.frameGroup() }) { Icon(name: "frame-corners") }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: model.screen.width > 760 ? .topTrailing : .bottom)
        .padding(.top, 40).padding(.trailing, model.screen.width > 760 ? 40 : 0).padding(.bottom, 40)
    }
}
