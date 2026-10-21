import SwiftUI
import UIKit

/// Launch with `-shot <name>` to open the app straight on one moment, with every move finished.
/// GitHub's Mac machines use it to take the same screenshots on every build.
@MainActor
enum Shots {
    static var name: String? {
        let a = ProcessInfo.processInfo.arguments
        guard let i = a.firstIndex(of: "-shot"), i + 1 < a.count else { return nil }
        return a[i + 1]
    }
    static var active: Bool { name != nil }
    /// `-reduce-motion`: the moment runs as it does for a child with Reduce Motion on (cuts, nothing drawing in), and
    /// otherwise for real: the How to plays, the work is kept (in memory only) and comes back.
    static var reduceMotion: Bool { ProcessInfo.processInfo.arguments.contains("-reduce-motion") }
    /// A moment's pages have the same numbers every time it's taken (light and dark, before and after a change), from
    /// its name and the lesson; nil outside screenshots (fresh numbers).
    static func seed(_ id: String) -> UInt64? {
        guard let name else { return nil }
        // FNV-1a: the same on every launch (Swift's own hashes aren't)
        return "\(name) \(id)".utf8.reduce(UInt64(14_695_981_039_346_656_037)) { ($0 ^ UInt64($1)) &* 1_099_511_628_211 }
    }

    static func run(_ m: PaperModel) {
        guard let name else { return }
        // as a child does it: tap the lesson (the glide), then Start
        func start(_ p: Piece) { m.select(p); m.open(p) }
        // the same progress every time, and nothing saved: two lessons learned, the two that worked (G 20 Oct)
        Progress.shared.saving = false
        PageStore.saving = false
        AppSettings.shots = true
        Progress.shared.reset(to: ["g5-round", "add"])
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-landscape") || args.contains("-portrait"),
           let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.requestGeometryUpdate(UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: args.contains("-portrait") ? .portrait : .landscapeRight)) { e in
                NSLog("OBENTO-SHOT orientation refused: \(e)")
            }
        }
        // let the window settle into its final size, then jump to the moment
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if name == "demo" { await demo(m); return }
            if name.hasPrefix("teach") {
                // the How to taught a tap at a time: teach-0 is the idea, teach-N after N taps
                m.frameGroup(duration: 0); m.drawnAt = PaperClock.now - 100
                let ad = Map.piece("ad")!
                PageStore.clear("ad")
                m.shotProblem = .init(a: 4, p: 3, b: 8, q: 1)
                func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
                m.select(ad); await wait(1); m.open(ad); await wait(3.5)
                for _ in 0..<(Int(name.dropFirst(6)) ?? 0) { m.bars?.skipHowTo(); await wait(2.2) }
                return
            }
            if name.hasPrefix("type-") {
                // typing into the answer box, a digit a second: the box widens by squares, the numbers show at once
                let id = String(name.dropFirst(5))
                guard let p = Map.piece(id) else { return }
                m.shotMode = true; m.select(p); m.open(p); m.shotMode = false
                guard let page = m.bars, let w = page.problems.first as? WorkProblem else { return }
                page.open(w)
                func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
                await wait(3)
                if let box = w.lesson.step.answer?.boxes.first { w.select(box) }
                for d in ["1", "2", "3", "4"] { await wait(1); w.type(d) }
                return
            }
            if name.hasPrefix("roll-") {
                // the page of problems, one step of the first problem, and back: its status rolls over like a clock
                let id = String(name.dropFirst(5))
                guard let p = Map.piece(id) else { return }
                PageStore.clear(id)
                m.frameGroup(duration: 0); m.drawnAt = PaperClock.now - 100
                func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
                m.select(p); await wait(1); m.open(p); await wait(2)
                for _ in 0..<10 { m.bars?.skipHowTo(); await wait(1.3) }
                guard let page = m.bars, let w = page.problems.first as? WorkProblem else { return }
                await wait(2); page.open(w); await wait(3)
                w.answerForShots(); await wait(2)
                page.backToProblems()
                return
            }
            if name.hasPrefix("howto-") {
                // howto-<lesson id>[-<taps>]: the real path, not instant: the lesson opens and its How to plays (the ghost
                // finger making each step's move), Next pressed that many times, each as soon as it shows (a child's
                // tap while the move still plays does nothing); -numbers as page-
                let rest = name.dropFirst(6).split(separator: "-")
                let taps = Int(rest.last ?? "") ?? 0, id = (Int(rest.last ?? "") != nil ? rest.dropLast() : rest[...]).joined(separator: "-")
                guard let p = Map.pieces.first(where: { $0.id == id }) else { return }
                PageStore.clear(id)
                m.shotNumbers = given(id)
                m.frameGroup(duration: 0); m.drawnAt = PaperClock.now - 100
                func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
                m.select(p); await wait(1); m.open(p); await wait(2.5)
                for _ in 0..<taps {
                    var n = 0
                    while m.bars?.howTo.howToButtons.isEmpty != false, n < 150 { await wait(0.1); n += 1 }
                    await wait(0.6); m.bars?.skipHowTo(); await wait(0.4)
                }
                return
            }
            if name.hasPrefix("live-") {
                // the real path, not instant, to watch things draw in and the camera follow: the How to tapped through,
                // the first problem opened, its answer box tapped, a step worked
                let id = String(name.dropFirst(5))
                guard let p = Map.piece(id) else { return }
                PageStore.clear(id)
                m.frameGroup(duration: 0); m.drawnAt = PaperClock.now - 100
                func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
                m.select(p); await wait(1); m.open(p); await wait(2)
                for _ in 0..<10 { m.bars?.skipHowTo(); await wait(1.3) }
                guard let page = m.bars, let w = page.problems.first as? WorkProblem else { return }
                await wait(1.5); page.open(w); await wait(2.5)
                if let box = w.lesson.step.answer?.boxes.first { w.select(box) }
                await wait(2); w.answerForShots(); await wait(3)
                w.answerForShots(); await wait(2)
                // back to the page, the same problem again straight away, and back once more (G found it stuck); then
                // another problem, and back
                page.backToProblems(); await wait(0.3)
                page.open(w); await wait(1.5)
                page.backToProblems(); await wait(1.5)
                page.open(page.problems[3]); await wait(3)
                // dark while it's open, then back (G found it stuck after this)
                UserDefaults.standard.set("dark", forKey: "theme"); await wait(1.5)
                page.backToProblems()
                return
            }
            if name.hasPrefix("resume") {
                // the real path, not instant: open the lesson, skip the How to, work problem 2 partway, leave, come back
                PageStore.clear("ad")
                m.frameGroup(duration: 0); m.drawnAt = PaperClock.now - 100
                let ad = Map.piece("ad")!
                func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
                m.select(ad); await wait(1); m.open(ad); await wait(1.5)
                for _ in 0..<12 { m.bars?.skipHowTo(); await wait(1.6) }
                guard let page = m.bars else { return }
                let b = page.problems[1] as! AddFractionsModel
                page.open(b)
                for i in 0..<b.problem.covered { b.tap(i) }
                b.go(); await wait(1)
                if name == "resume-map" { m.close(); await wait(2); return }
                if name == "resume-select" { m.close(); await wait(2); m.select(ad); return }
                m.close(); await wait(2)
                m.select(ad); await wait(1); m.open(ad)
                return
            }
            if name == "open-ad" {
                // tap the lesson and open it as a hand would, the How to playing, for -perf timings
                m.frameGroup(duration: 0); m.drawnAt = PaperClock.now - 100
                try? await Task.sleep(for: .seconds(2))
                let ad = Map.piece("ad")!
                m.select(ad); try? await Task.sleep(for: .seconds(1.5))
                m.open(ad)
                return
            }
            if name == "leave-ad" {
                // the lesson page, then back to the map, for watching the page erase itself
                m.frameGroup(duration: 0); m.drawnAt = PaperClock.now - 100
                m.shotMode = true; m.shotProblem = .init(a: 4, p: 1, b: 8, q: 1)
                m.select(Map.piece("ad")!); m.open(Map.piece("ad")!); m.shotMode = false
                try? await Task.sleep(for: .seconds(2.5))
                m.close()
                return
            }
            if name == "page-zoom" {
                // the lesson page: out to see it all and back in to a problem, again and again, for -perf timings
                m.frameGroup(duration: 0); m.drawnAt = PaperClock.now - 100
                m.shotMode = true; m.shotProblem = .init(a: 4, p: 1, b: 8, q: 1)
                m.select(Map.piece("ad")!); m.open(Map.piece("ad")!); m.shotMode = false
                try? await Task.sleep(for: .seconds(2))
                guard let page = m.bars else { return }
                for _ in 0..<3 {
                    m.frameAll(); try? await Task.sleep(for: .seconds(1.2))
                    m.frameCurrent(BarsPage.box(of: page.problems[5])); try? await Task.sleep(for: .seconds(1.2))
                }
                return
            }
            if name == "page-hop" {
                // the lesson page: frame one problem after another, as taps on them would, for -perf timings
                m.frameGroup(duration: 0); m.drawnAt = PaperClock.now - 100
                m.shotMode = true; m.shotProblem = .init(a: 4, p: 1, b: 8, q: 1)
                m.select(Map.piece("ad")!); m.open(Map.piece("ad")!); m.shotMode = false
                try? await Task.sleep(for: .seconds(2))
                guard let page = m.bars else { return }
                for i in [0, 1, 2, 3, 7, 6, 5, 4, 0] {
                    m.frameCurrent(BarsPage.box(of: page.problems[i])); try? await Task.sleep(for: .seconds(1))
                }
                return
            }
            if name == "hop" {
                // glide from group to group, as a hand would, to watch the words keep up with the pictures
                m.frameGroup(duration: 0); m.drawnAt = PaperClock.now - 100
                try? await Task.sleep(for: .seconds(2))
                for id in ["add", "g5-volume", "g5-pow10", "g5-volume", "g5-mult2", "g5-volume"] {
                    m.select(Map.piece(id)!); try? await Task.sleep(for: .seconds(1.2))
                }
                return
            }
            if name == "move" {
                // drag across the map and pinch in and out, about as a hand would, for -perf timings
                m.frameGroup(duration: 0); try? await Task.sleep(for: .seconds(2.5))
                for _ in 0..<120 { m.pan(-6, -2); try? await Task.sleep(for: .milliseconds(16)) }
                for _ in 0..<60 { m.zoom(by: 1.015, at: .init(m.screen.width / 2, m.screen.height / 2)); try? await Task.sleep(for: .milliseconds(16)) }
                for _ in 0..<60 { m.zoom(by: 1 / 1.015, at: .init(m.screen.width / 2, m.screen.height / 2)); try? await Task.sleep(for: .milliseconds(16)) }
                return
            }
            if await structure(m, name) { return }
            defer { if ProcessInfo.processInfo.arguments.contains("-rotate") { rotate() } }
            m.shotMode = true
            m.drawnAt = PaperClock.now - 100
            m.shotBox = .init(length: 4, width: 3, height: 2)
            m.frameGroup(duration: 0)
            m.shotProblem = .init(a: 4, p: 1, b: 8, q: 1)
            let uc = Map.piece("uc")!
            switch name {
            case "paper": break
            // the Paper proof's pieces are off the map (20 Oct): a lesson on it is chosen instead
            case "selected": m.select(Map.piece("g5-volume"))
            case let n where n.hasPrefix("cards-"):
                // cards-<lesson id>[-done]: the page of problems after the How to; -done: the together ones solved, the
                // first own one with a miss (a fresh one comes for it), two more right, and the page back
                let rest = String(n.dropFirst(6)), done = rest.hasSuffix("-done"), id = done ? String(rest.dropLast(5)) : rest
                guard let p = Map.piece(id) else { return }
                m.select(p); m.open(p)
                guard done, let page = m.bars else { return }
                @MainActor func work(_ w: WorkProblem, miss: Bool) {
                    page.open(w)
                    var missed = !miss
                    while !w.solved {
                        if w.lesson.step.answer != nil, !missed { w.answerForShots(wrong: true); missed = true; w.reset() }
                        w.answerForShots()
                    }
                }
                for i in [0, 1, 2, 3, 4, 5] { if let w = page.problems[i] as? WorkProblem { work(w, miss: i == 3) } }
                page.backToProblems()
            case let n where n.hasPrefix("page-") && n != "page-zoom" && n != "page-hop":
                // page-<lesson id>[@<problem>][-<step>]: a lesson's page, How to skipped; its first problem (or that one)
                // worked to that step
                let parts = n.dropFirst(5).split(separator: "-")
                let k = Int(parts.last ?? "") ?? -1, named = (k >= 0 ? parts.dropLast() : parts[...]).joined(separator: "-")
                let id = String(named.split(separator: "@").first ?? ""), which = Int(named.split(separator: "@").dropFirst().first ?? "") ?? 0
                guard let p = Map.piece(id) else { return }
                // -howto N: its How to, taught a tap at a time (CubesProblem.swift)
                if args.contains("-howto") { await howToTaps(m, p, args: args); return }
                m.select(p); m.open(p)
                // Volume of a box: worked by the hands (CubesProblem.swift)
                if let page = m.bars, page.problems.indices.contains(which), let c = page.problems[which] as? CubesProblem {
                    await cubes(m, page, c, stage: k, args: args); return
                }
                guard let page = m.bars, page.problems.indices.contains(which), let w = page.problems[which] as? WorkProblem else { return }
                // -numbers a=1,b=2,…: that problem with these numbers (the lesson's own worked-out ones added by its spec);
                // -story: told as its story
                if let n = given(id) { w.use(n, story: args.contains("-story")) }
                page.open(w)
                // each step before it answered as a child would: a hand step by its moves, a number typed, a pick picked
                for _ in 0..<max(0, k) { w.answerForShots() }
                // -wrong: a slip on this step (a wrong move, or a wrong number typed and checked), so what a miss says shows
                if args.contains("-wrong") { w.answerForShots(wrong: true) }
                // -type <digits>: those typed into the step's first box and checked (a slip the lesson names)
                if let i = args.firstIndex(of: "-type"), i + 1 < args.count, let box = w.lesson.step.answer?.boxes.first {
                    w.select(box)
                    for ch in args[i + 1] { w.type(String(ch)) }
                    w.go()
                }
                // -hint: the step's hint, as the bar's Hint shows it
                if args.contains("-hint") { w.showHint() }
                // -hand key=value,…: the hand mid-move (a ruler being dragged, a point held, pieces being slid)
                if let i = args.firstIndex(of: "-hand"), i + 1 < args.count {
                    var hand: Numbers = [:]
                    for pair in args[i + 1].split(separator: ",") { let kv = pair.split(separator: "="); if kv.count == 2, let v = Double(kv[1]) { hand[String(kv[0])] = v } }
                    w.hand = hand
                }
                // -tapsq x,y / -drag x0,y0,x1,y1 / -block Name: a finger's tap or drag on the picture (in its squares) or a
                // tap on a block, made through the camera and the paper's own gesture handling, as a real finger's would be
                @MainActor func screen(_ x: Double, _ y: Double) -> Point {
                    let o = w.contentOrigin, l = w.layout
                    return m.camera(at: PaperClock.now).toScreen(Point(o.x + l.pictureOffset.x + x * Paper.cell, o.y + l.pictureOffset.y + y * Paper.cell))
                }
                func numbers(_ flag: String) -> [Double]? {
                    guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
                    return args[i + 1].split(separator: ",").compactMap { Double($0) }
                }
                // a finger comes after the camera has framed the step, as a child's does
                if args.contains("-tapsq") || args.contains("-drag") || args.contains("-block") { try? await Task.sleep(for: .seconds(1.5)) }
                if let t = numbers("-tapsq"), t.count == 2 { m.tap(at: screen(t[0], t[1])) }
                if let d = numbers("-drag"), d.count == 4 {
                    m.dragStart(at: screen(d[0], d[1]))
                    for k in 1...12 { let f = Double(k) / 12; m.dragMove(to: screen(d[0] + (d[2] - d[0]) * f, d[1] + (d[3] - d[1]) * f)) }
                    if !args.contains("-hold") { m.dragEnd() }
                }
                if let i = args.firstIndex(of: "-block"), i + 1 < args.count,
                   let b = ProblemLayout.blocks(w).first(where: { $0.kind == .action(args[i + 1]) || ($0.kind == .main && args[i + 1] == "Check") }) {
                    m.tap(at: m.camera(at: PaperClock.now).toScreen(Point(b.rect.midX, b.rect.midY)))
                }
                // -ghost [seconds]: Show me's ghost finger stopped that far into its moves
                if let i = args.firstIndex(of: "-ghost") {
                    let at = i + 1 < args.count ? Double(args[i + 1]) : nil
                    w.play(.preview, frozen: at ?? 1.2)
                }
                if args.contains("-keypad"), let box = w.lesson.step.answer?.boxes.first { w.select(box) }
            case "tests":
                // the map with Whole numbers' lessons learned: its chapter's test opens; frame on Whole numbers
                Progress.shared.reset(to: whole); m.frameChapter(0)
            case "tests-all":
                Progress.shared.reset(to: Set(Map.gradeLessons), tests: ["test-whole": 12, "test-decimals": 10, "test-fractions": 11, "test-measurement": 7])
                m.frameGroup(duration: 0)
            case "tests-taken":
                Progress.shared.reset(to: whole, tests: ["test-whole": 10]); m.frameChapter(0)
            case "grade-test":
                Progress.shared.reset(to: Set(Map.gradeLessons), tests: ["test-whole": 12, "test-decimals": 10, "test-fractions": 11, "test-measurement": 10])
                m.select(Map.tests.first { $0.id == "test-grade" }!)
            case "test-page":
                // a chapter's test, its 12 problems mixed from its lessons (-chapter=<n>: that chapter's; Whole numbers')
                let n = args.first { $0.hasPrefix("-chapter=") }.flatMap { Int($0.dropFirst(9)) } ?? 0
                let t = Map.tests[min(max(0, n), Map.tests.count - 2)]
                Progress.shared.reset(to: Set(Map.pieces.filter { $0.chapter == t.chapter }.map(\.id)))
                m.select(t); m.open(t)
            case "selected-ad": m.select(Map.piece("add"))
            case "selected-many":
                // tap five lessons one after another: the zoom mustn't creep in
                for id in ["g5-mult2", "sub", "g5-round", "g5-volume", "add"] { m.select(Map.piece(id)) }
            case "theme":
                // flip to dark while the app runs, as the moon in the top bar does
                UserDefaults.standard.set("light", forKey: "theme")
                try? await Task.sleep(for: .seconds(1))
                UserDefaults.standard.set("dark", forKey: "theme")
            case "back": start(Map.piece("ad")!); m.close()
            case let n where n.hasPrefix("fractions"):
                // the page: the How to has played (instant), the 16 problems are on the paper
                start(Map.piece("ad")!)
                guard let page = m.bars, n != "fractions" else { return }
                let b = (n == "fractions-story" ? page.problems[2] : n == "fractions-check" ? page.problems[12] : page.problems[0]) as! AddFractionsModel
                if n == "fractions-activate" {
                    // a tap on the empty bottom corner of problem 2's box makes it the one being worked
                    let r = BarsPage.box(of: page.problems[1]), s = m.camera(at: PaperClock.now).toScreen(Point(r.x + 30, r.y + r.height - 30))
                    m.tap(at: s); return
                }
                if n == "fractions-row" {
                    // a problem from each row: 1 together, 5 less help, 9 final answer only
                    return
                }
                if n == "fractions-final-miss" {
                    let f = page.problems[8] as! AddFractionsModel; page.open(f); f.tap(0); f.go(); return
                }
                if n == "fractions-taps" {
                    // a finger's taps, by where they land on the screen: the pieces, then Check, then a choice on the story
                    @MainActor func tap(_ p: CGPoint) { let s = m.camera(at: PaperClock.now).toScreen(Point(p.x, p.y)); m.tap(at: s) }
                    for i in 0..<b.problem.covered { tap(CGPoint(x: b.origin.x + (Double(i) + 0.5) * b.pieceWidth, y: b.origin.y + AddFractionsModel.row2 + 30)) }
                    if let check = ProblemLayout.blocks(b).first(where: { $0.kind == .main }) { tap(CGPoint(x: check.rect.midX, y: check.rect.midY)) }
                    return
                }
                if n == "fractions-overview" { let p0 = page.problems[0] as! AddFractionsModel; for i in 0..<p0.problem.covered { p0.tap(i) }; p0.go(); m.frameAll(); return }
                if n == "fractions-story" { b.choose(2); b.go(); return }
                if n == "fractions-wrong" || n == "fractions-check" { b.tap(b.problem.covered + 1); b.go(); return }
                if n == "fractions-hint2" { b.tap(b.problem.covered + 1); b.go(); b.go(); return }
                for i in 0..<b.problem.covered { b.tap(i) }
                b.go()
                if n == "fractions-add" { return }
                if n == "fractions-two" { for i in b.problem.covered..<b.problem.total { b.tap(i) }; b.go(); (page.problems[1] as! AddFractionsModel).tap(0); return }
                for i in b.problem.covered..<b.problem.total { b.tap(i) }
                b.go()
            default:
                start(uc)
                guard let l = m.lesson else { return }
                if name == "flat" { return }
                l.go()
                if name.hasPrefix("cover") { for c in [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1)] { l.tap(.init(c.0, c.1)) } }
                if name == "cover-hint1" { l.go(); return }
                if name == "cover-tapcheck" {
                    // press Check by where it shows on the screen, as a finger would
                    let v = l.view(at: PaperClock.now), a = v.project(CubesLayout.blocksAt(l), screen: l.screen), k = v.scale / Paper.unit
                    if let r = CubesLayout.blocks(l).first(where: { $0.kind == .main })?.rect {
                        let p = Point(a.x + r.midX * k, a.y + r.midY * k)
                        if CubesLayout.block(at: p, l) == .main { l.go() }
                    }
                    return
                }
                if name == "cover-hint2" { l.go(); l.go(); return }
                if name == "cover" { return }
                for i in 0..<l.box.floor { l.tap(UnitCubes.cell(i, in: l.box)) }
                l.go()
                if name == "tilt" { return }
                l.go()
            }
        }
    }

    /// Whole numbers' lessons, for the tests' moments.
    static let whole: Set<String> = ["g5-mult2", "g5-divide", "g5-order"]

    /// The app's structure at its moments (G 20 Oct), each with its own progress, nothing saved, and the same numbers
    /// every time (Shots.seed). Lessons default to the two that worked (G 20 Oct: Rounding decimals, Adding fractions).
    /// - `map-fresh`: nothing learned. `map-learned`: some lessons learned, one due back and one whose recheck came back
    ///   low (both Go over), one whose test came back low and was never learned (its test to take again), a page
    ///   partway, and chapter tests locked, open, passed and to take again. `map-grade`: every chapter test passed, so the
    ///   grade's test is open. The map opens on today's chapter; `-whole` frames all of it, `-chapter=<n>` that chapter;
    ///   `-select=<id>` chooses a piece (its tab: Start, Continue, or Go over).
    /// - `plan-<partway|testopen|passed>-<lesson>`: its page of cards: partway (together done, own ones right, one with a
    ///   miss, one with Show me), the test open (6 right on their own), the test passed (11 of 12, Continue pressed).
    /// - `result-<pass|fail>-<lesson>`: a finished lesson test's result on the paper.
    /// - `hint-<first|together|own|used>-<lesson>`: a problem open with the bar's Hint: on their own before a miss, tapped
    ///   (the paper says why there's none); in a together problem, tapped (free); on their own after a miss; the page's
    ///   hints used up.
    /// - `recheck-<lesson>`: a due lesson opening on its recheck; `recheck-pass-<lesson>`, `recheck-fail-<lesson>`: its
    ///   result; `recheck-after-<lesson>`: one that came back low, Continue pressed: the page with problems to go over.
    /// - `test-result-<chapter>`, `test-fail-<chapter>`: a chapter test answered to the end (10 right; 7), its result.
    /// - `taught-<lesson>` (`-showing`: while the step is shown): opened as a child does; the same slip twice, then the
    ///   problem aimed at it, its step shown first by the app and then worked with no miss: right on their own.
    /// - `stuck-<lesson>`: a lesson test's last problem answered right and the bar's Problems pressed straight away: the
    ///   result shows (it never waits for a Next problem that's gone).
    /// - `lesson-<lesson>` (`-taps=<n>`: Next pressed n times), `back-<lesson>`: opened as a child does, not as a
    ///   screenshot: the How to plays; back: the How to tapped through, a problem started, the lesson left and opened
    ///   again, on the problem as it was left. With `-reduce-motion`, as Reduce Motion has it.
    /// - `cards-fit`: every lesson's cards written as they are on its page, checked inside their frames; printed.
    static func structure(_ m: PaperModel, _ name: String) async -> Bool {
        func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
        let args = ProcessInfo.processInfo.arguments
        let chapter = args.first { $0.hasPrefix("-chapter=") }.flatMap { Int($0.dropFirst(9)) }
        /// The map framed (today's chapter; `-whole`, or `-chapter=<n>`), and with `-select=<id>` that piece chosen, its
        /// tab saying Start, Continue or Go over.
        func frameMap() {
            if let chapter { m.frameChapter(chapter) } else if args.contains("-whole") { m.frameAll() } else { m.frameGroup(duration: 0) }
            if let id = args.first(where: { $0.hasPrefix("-select=") }).map({ String($0.dropFirst(8)) }), let p = Map.piece(id) { m.select(p) }
        }
        /// The lesson named after the moment's kind ("plan-partway-g5-round" → g5-round).
        func lesson(_ prefix: String) -> Piece? { Map.piece(String(name.dropFirst(prefix.count))) }
        /// Opens a lesson as a child does, at once: its page (the How to done), or its recheck.
        func open(_ p: Piece) -> BarsPage? { m.shotMode = true; m.select(p); m.open(p); return m.bars }
        m.drawnAt = PaperClock.now - 100
        switch name {
        case "map-fresh":
            Progress.shared.reset(to: [])
            m.shotMode = true; frameMap()
        case "map-learned":
            Progress.shared.reset(to: whole.union(["g5-pow10", "g5-round", "g5-adddec", "g5-multdec", "g5-divdec", "add", "sub", "g5-volume", "g5-units"]),
                                  due: ["g5-round"], tests: ["test-whole": 11, "test-measurement": 7])
            // Subtracting fractions: learned, its recheck came back low (Go over, still counted)
            Progress.shared.checked("sub", level: 1)
            // Adding and subtracting: its page done and its test 8 of 12, never learned: its test is there to take again
            seedPage("mix", own: LessonPlan.own, test: 8)
            Progress.shared.checked("mix", level: LessonPlan.level(8, of: LessonPlan.test))
            // Multiplying fractions: partway
            seedPage("g5-multfrac", own: 1)
            m.shotMode = true; frameMap()
        case "map-grade":
            Progress.shared.reset(to: Set(Map.gradeLessons), tests: ["test-whole": 12, "test-decimals": 10, "test-fractions": 11, "test-measurement": 10])
            m.shotMode = true; frameMap()
        case let n where n.hasPrefix("plan-"):
            let kind = n.dropFirst(5).prefix { $0 != "-" }
            guard let p = lesson("plan-\(kind)-"), let page = open(p) else { return true }
            await wait(0.3)
            let together = page.plan?.items.indices.filter { page.plan?.items[$0].part == .together } ?? []
            for i in together { page.open(page.problems[i]); await work(page.problems[i]) }
            if kind == "partway" {
                // the first own one right, the second with a miss (a fresh one comes), the third with Show me
                let own = page.problems.indices.filter { page.plan?.items[$0].part == .own }
                page.open(page.problems[own[0]]); await work(page.problems[own[0]])
                page.open(page.problems[own[1]]); await work(page.problems[own[1]], miss: true)
                page.open(page.problems[own[2]]); await work(page.problems[own[2]], showMe: true)
                page.open(page.problems[own[3]]); await work(page.problems[own[3]], steps: 1)
            } else {
                for i in page.problems.indices where page.plan?.items[i].part == .own && !page.problems[i].solved { page.open(page.problems[i]); await work(page.problems[i]) }
                if kind == "passed" {
                    page.openTest()
                    for (i, q) in page.testProblems.enumerated() { page.open(q); await work(q, miss: i == 4) }
                    page.goNext(); await wait(0.2)
                    page.continueFromResult(); await wait(0.2)
                    return true
                }
            }
            page.backToProblems()
        case let n where n.hasPrefix("result-"):
            let pass = n.hasPrefix("result-pass-")
            guard let p = lesson(pass ? "result-pass-" : "result-fail-"), let page = open(p) else { return true }
            await wait(0.3)
            for (i, q) in page.problems.enumerated() where page.plan?.items[i].part == .own || page.plan?.items[i].part == .together { page.open(q); await work(q) }
            page.openTest()
            for (i, q) in page.testProblems.enumerated() { page.open(q); await work(q, miss: pass ? i == 4 : i % 3 == 0) }
            page.goNext()
        case let n where n.hasPrefix("hint-"):
            let kind = n.dropFirst(5).prefix { $0 != "-" }
            guard let p = lesson("hint-\(kind)-"), let page = open(p) else { return true }
            await wait(0.3)
            // a together problem: its hint is free, and shows on the paper
            if kind == "together" { page.open(page.problems[0]); page.hint(); return true }
            /// The next own problem not done, told plainly (a story's first step is picking what to do).
            func nextOwn() -> Int? {
                page.problems.indices.first { i in page.plan.map { $0.items[i].part == .own && !$0.items[i].story } == true && !page.problems[i].solved }
            }
            if kind == "used" {
                // five own problems, each with a miss and its hint taken: the page's hints are used up
                for _ in 0..<LessonPlan.hints {
                    guard let i = nextOwn() else { break }
                    page.open(page.problems[i]); await work(page.problems[i], miss: true, afterMiss: { page.hint() })
                }
            }
            guard let i = nextOwn() else { return true }
            page.open(page.problems[i])
            // before a miss: Hint tapped anyway, and the paper says why there's none yet
            if kind == "first" { page.hint(); return true }
            await work(page.problems[i], miss: true, stopAfterMiss: true)
        case let n where n.hasPrefix("recheck"):
            // recheck-<lesson>, recheck-pass-, recheck-result- (the same), recheck-fail-, recheck-after-
            let kinds = ["recheck-pass-", "recheck-result-", "recheck-fail-", "recheck-after-", "recheck-"]
            let kind = kinds.first { n.hasPrefix($0) } ?? "recheck-"
            let id = n.count > kind.count ? String(n.dropFirst(kind.count)) : "g5-round"
            guard let p = Map.piece(id) else { return true }
            Progress.shared.reset(to: [id], due: [id])
            // its page as it was finished, days ago
            seedPage(id, own: LessonPlan.own, test: 11)
            guard let page = open(p), kind != "recheck-" else { return true }
            await wait(0.3)
            let fail = kind == "recheck-fail-" || kind == "recheck-after-"
            for (i, q) in page.recheckProblems.enumerated() { page.open(q); await work(q, miss: fail ? i < 2 : i == 2) }
            page.goNext()
            if kind == "recheck-after-" { await wait(0.3); page.continueFromResult() }
        case let n where n.hasPrefix("lesson-") || n.hasPrefix("back-"):
            let back = n.hasPrefix("back-")
            guard let p = lesson(back ? "back-" : "lesson-") else { return true }
            Progress.shared.reset(to: [])
            PageStore.clear(p.id)
            m.frameGroup(duration: 0)
            m.select(p); await wait(m.reduceMotion ? 0.2 : 1.2); m.open(p); await wait(1.5)
            // a tap each time the How to waits for one (its blocks are up)
            let taps = back ? 99 : args.first { $0.hasPrefix("-taps=") }.flatMap { Int($0.dropFirst(6)) } ?? 0
            await tapThrough(m, taps: taps)
            guard back, let page = m.bars, let i = page.problems.indices.first(where: { page.plan?.items[$0].part == .own }),
                  let w = page.problems[i] as? WorkProblem else { return true }
            await wait(0.8)
            page.open(w); await wait(1)
            await work(w, steps: 1)
            if let box = w.lesson.step.answer?.boxes.first { w.select(box); w.type("4") }
            await wait(0.5)
            m.close(); await wait(2)
            m.select(p); await wait(m.reduceMotion ? 0.2 : 1.2); m.open(p)
        case let n where n.hasPrefix("taught-"):
            // as a child does (the app's teaching never runs in a screenshot's instant page): the same slip twice on their
            // own, then the problem aimed at it, its step shown by the app first, then worked with no miss
            guard let p = lesson("taught-") else { return true }
            Progress.shared.reset(to: [])
            seedPage(p.id, own: 0)
            m.frameGroup(duration: 0)
            m.select(p); await wait(1.2); m.open(p); await wait(2.5)
            guard let page = m.bars else { return true }
            func own() -> [Int] { page.problems.indices.filter { page.plan?.items[$0].part == .own && page.plan?.items[$0].story == false } }
            for _ in 0..<2 {
                guard let i = own().first(where: { !page.problems[$0].solved }) else { return true }
                page.open(page.problems[i]); await wait(1.5)
                await work(page.problems[i], miss: true)
                await wait(1)
            }
            guard let t = page.problems.indices.first(where: { page.plan?.items[$0].focus?.teach == true }), let w = page.problems[t] as? WorkProblem else { return true }
            page.open(w)
            // the app shows the step (about 1.2 s in, for 2.4 s)
            await wait(2.4)
            if args.contains("-showing") { return true }
            for _ in 0..<60 where w.busy || w.message != nil { await wait(0.1) }
            await work(w)
            await wait(1)
            page.backToProblems()
        case let n where n.hasPrefix("stuck-"):
            // as a child does: the lesson test's last problem right, and the bar's Problems pressed as it's checked
            guard let p = lesson("stuck-") else { return true }
            Progress.shared.reset(to: [])
            seedPage(p.id, own: LessonPlan.own, test: 11, testAnswered: LessonPlan.test - 1)
            m.frameGroup(duration: 0)
            m.select(p); await wait(1.2); m.open(p); await wait(2.5)
            guard let page = m.bars, let last = page.testProblems.last else { return true }
            page.open(last); await wait(1.5)
            await work(last, steps: last.lesson.workSteps - 1)
            for _ in 0..<40 where last.busy { await wait(0.05) }
            guard last.lesson.step.answer != nil else { return true }
            last.answerForShots(wrong: false)
            page.backToProblems()
        case let n where n.hasPrefix("test-result-") || n.hasPrefix("test-fail-"):
            let fail = n.hasPrefix("test-fail-")
            guard let t = Map.piece("test-\(n.dropFirst(fail ? 10 : 12))") else { return true }
            Progress.shared.reset(to: Set(Map.gradeLessons))
            guard let page = open(t) else { return true }
            await wait(0.3)
            for (i, q) in page.problems.enumerated() { page.open(q); await work(q, miss: fail ? i % 3 == 1 || i == 0 : i == 2 || i == 7) }
            page.goNext()
        // Me, the review and the grown-ups' page (G 20 Oct), on seeded progress (seedMe): nothing learned, or a child
        // some way in (two to go over, five getting stronger, two known); with today's review done
        case "me-fresh":
            Progress.shared.reset(to: [])
            m.shotMode = true; m.go(to: .me)
        case "me", "me-review-done", "me-review-partway":
            seedMe()
            if name == "me-review-done" { Progress.shared.setReview(right: 6, of: 8, missed: ["g5-round", "sub"]) }
            if name == "me-review-partway" { PaperModel.shotPartway = 3 }
            m.shotMode = true; m.go(to: .me)
        case "me-review-reset":
            // today's review partway, then a grown-up's reset left only one lesson checked: the card still says how far
            // it got, lit, and opens to be finished
            Progress.shared.reset(to: [])
            Progress.shared.setCheck("g5-round", passes: 1, daysAgo: 2, dueIn: 1)
            PaperModel.shotPartway = 3
            m.shotMode = true; m.go(to: .me)
        case "review-after-reset":
            // the real path behind me-review-reset, not instant, so the review's page saves as it goes (in memory, as a
            // shot's pages do): today's review three problems in, then a grown-up resets every lesson but one (as the
            // grown-ups' page does it); Me's card, tapped where it's drawn, opens the review as it was left
            seedMe()
            m.go(to: .me); await wait(2.5)
            m.open(Map.review, from: .me); await wait(2)
            guard let page = m.bars else { return true }
            for q in page.problems.prefix(3) { page.open(q); await wait(1.5); await work(q); await wait(0.8) }
            page.backToProblems(); await wait(1)
            m.close(); await wait(2.5)
            for id in Map.gradeLessons where id != "g5-round" { Progress.shared.forget(id); PageStore.clear(id) }
            await wait(1.5)
            m.tap(at: m.camera(at: PaperClock.now).toScreen(Point(MePage.corner.x + 5.5 * Paper.unit, 2 * Paper.unit)))
        case "me-helps", "me-low":
            // today's pick is up next, never Go over, when it isn't on Me's Go over shelf: me-helps, a 1 on Dividing by a
            // decimal (never learned) picks Multiply by 10, 100, 1000 (never started) under it; me-low, a test that came
            // back low on a lesson never learned (Adding fractions learned, so the review is ready)
            Progress.shared.reset(to: [])
            if name == "me-helps" { Progress.shared.setCheck("g5-divdec", last: 1, best: 1, passes: 0, daysAgo: 1, dueIn: 0) }
            else {
                Progress.shared.setCheck("add", passes: 1, daysAgo: 1, dueIn: 2)
                Progress.shared.setCheck("g5-divdec", last: 2, best: 2, passes: 0, daysAgo: 2, dueIn: -1)
            }
            m.shotMode = true; m.go(to: .me)
        case "me-full", "me-full-open":
            // every lesson learned, most on their way through their checks: the longest shelves Me has; Getting stronger
            // too long for the screen ends on "and 11 more", which me-full-open has tapped
            seedMeFull()
            m.shotMode = true; m.go(to: .me)
            if name == "me-full-open" { m.openShelf(1) }
        case "path-shelf":
            // the real path, not instant, to watch a long shelf open and close: Me (as me-full), "and 11 more" tapped where
            // it's drawn (the other parts undraw, the shelf's cards glide to their columns, the rest draw in), then Back
            // to Me tapped where it's drawn
            seedMeFull()
            m.frameGroup(duration: 0)
            await wait(1)
            m.go(to: .me); await wait(3)
            func tap(_ action: MePage.Action) {
                guard let r = m.meSheet(now: PaperClock.now).taps.first(where: { $0.action == action })?.rect else { return }
                m.tap(at: m.camera(at: PaperClock.now).toScreen(Point(r.midX, r.midY)))
            }
            tap(.shelf(1)); await wait(3.5)
            tap(.back)
        case let n where n.hasPrefix("review-"):
            // review-page: its 8 problems, opened from Me; review-problem: the first open; review-result: all 8
            // answered (two missed), its result on the paper; review-result-missed: every one missed, so the result
            // names every lesson the review drew on (Volume of a box left out of it: its hand moves need a finger's
            // drags, which `work` can't make)
            seedMe()
            if n == "review-result-missed" { Progress.shared.forget("g5-volume") }
            m.shotMode = true; m.go(to: .me)
            m.open(Map.review, from: .me)
            guard let page = m.bars else { return true }
            await wait(0.3)
            if n == "review-page" { return true }
            if n == "review-problem" {
                // -wrong: a slip on its first step, so a miss in the review shows what a lesson's miss shows
                page.open(page.problems[0])
                if args.contains("-wrong"), let w = page.problems[0] as? WorkProblem { w.answerForShots(wrong: true) }
                return true
            }
            if n == "review-result-longest" {
                // the most the review can name: 8 problems from 8 lessons, all missed, the 8 longest names
                let ids = ["g5-unitdiv", "g5-mult2", "g5-improper", "g5-pow10", "mix", "sub", "g5-multfrac", "g5-divdec"]
                page.showResultForShots(.init(kind: .review, title: page.piece.name, right: 0, of: Review.problems, passed: true, missed: ids))
                return true
            }
            for (i, q) in page.problems.enumerated() { page.open(q); await work(q, miss: n == "review-result-missed" || i == 2 || i == 5) }
            page.goNext()
        case let n where n.hasPrefix("grownup"):
            // grownup-gate: shut; grownup-hold: its square held halfway (the clock stopped there); grownup: open;
            // grownup-confirm: a lesson's reset asked on the paper; grownup-confirm-all: everything's
            seedMe()
            m.shotMode = true; m.go(to: .grownUp)
            if n == "grownup-gate" { return true }
            if n == "grownup-hold" { m.grownUp.heldForShots(0.55); return true }
            m.grownUp.openForShots()
            if n == "grownup-confirm" { m.grownUp.confirmForShots(.lesson("g5-round")) }
            if n == "grownup-confirm-all" { m.grownUp.confirmForShots(.all) }
            m.reframePlace()
        case "path-me":
            // the real path, not instant, to watch the places draw in and out: the map, then Me, a lesson opened from Me
            // and closed (back to Me), the review opened and closed, then the map again
            seedMe()
            m.frameGroup(duration: 0)
            await wait(2)
            m.go(to: .me); await wait(3)
            if let p = Map.piece("g5-divide") { m.open(p, from: .me) }
            await wait(4)
            m.close(); await wait(3)
            m.open(Map.review, from: .me); await wait(3)
            m.close(); await wait(3)
            m.go(to: nil)
        case let n where n.hasPrefix("first-launch"):
            // the very first launch (nothing done yet): the map drawing itself in, for real, then the ghost finger's tap
            // on the first lesson up next and "Start here."; first-launch-<seconds>: held that far into the finger's moves
            Progress.shared.reset(to: [])
            m.frameGroup(duration: 0)
            m.drawnAt = PaperClock.now
            m.beginStartHere(force: true, frozen: Double(n.dropFirst("first-launch-".count)))
        case "cards-fit":
            // every lesson's cards checked inside their frames, printed for the build to read
            for line in CardText.check() { print("OBENTO-CARDS \(line)") }
            fflush(stdout)
            exit(0)
        default:
            return false
        }
        return true
    }

    /// `-seed-me` or `-seed-me-full` (the real-touch tests, never a screenshot): the app opens, for real, on a child some
    /// way in (seedMe) or with every lesson learned (seedMeFull), kept in memory only, with no page left on the iPad
    /// brought back, so a test always starts from the same place and never changes what's saved.
    static func seedForTests() {
        let args = ProcessInfo.processInfo.arguments, full = args.contains("-seed-me-full")
        guard !active, full || args.contains("-seed-me") else { return }
        Progress.shared.saving = false
        PageStore.saving = false
        for p in Map.all + Map.proof + [Map.review] { PageStore.clear(p.id) }
        if full { seedMeFull() } else { seedMe() }
    }

    /// Every lesson learned, most on their way through their checks (15 getting stronger, 2 known): Me's longest shelf.
    static func seedMeFull() {
        Progress.shared.reset(to: [])
        for (i, id) in Map.gradeLessons.enumerated() {
            Progress.shared.setCheck(id, passes: [1, 2, 3, 2, 1, 4][i % 6], daysAgo: Double(i % 5) + 1, dueIn: Double(i % 7) + 1)
        }
    }

    /// A child some way into 5th grade, for Me and the grown-ups' page: two lessons to go over (one due back for its
    /// check, one whose recheck came back low), five getting stronger (one to three checks passed), two known (all four).
    static func seedMe() {
        let p = Progress.shared
        p.reset(to: [])
        p.setCheck("g5-mult2", passes: 4, daysAgo: 30, dueIn: 30)
        p.setCheck("g5-divide", passes: 2, daysAgo: 5, dueIn: 2)
        p.setCheck("g5-order", last: 3, passes: 1, daysAgo: 1, dueIn: 2)
        p.setCheck("g5-pow10", passes: 3, daysAgo: 10, dueIn: 11)
        p.setCheck("g5-round", passes: 2, daysAgo: 8, dueIn: -1)
        p.setCheck("g5-adddec", passes: 1, daysAgo: 2, dueIn: 1)
        p.setCheck("add", passes: 4, daysAgo: 40, dueIn: 20)
        p.setCheck("sub", last: 1, best: 4, passes: 0, daysAgo: 0.2, dueIn: 0.8)
        p.setCheck("g5-volume", passes: 1, daysAgo: 1, dueIn: 2)
        // a test that came back low on a lesson never learned: it's checked (the review draws on it), never on a shelf
        p.setCheck("g5-multdec", last: 2, best: 2, passes: 0, daysAgo: 3, dueIn: -2)
    }

    /// Taps through the How to (`taps` times at most), each time it waits for a tap.
    static func tapThrough(_ m: PaperModel, taps: Int) async {
        var tapped = 0
        for _ in 0..<600 where tapped < taps && m.bars?.howToGone == false {
            if m.bars?.howTo.howToButtons.isEmpty == false { m.bars?.skipHowTo(); tapped += 1; try? await Task.sleep(for: .seconds(0.4)) }
            else { try? await Task.sleep(for: .seconds(0.1)) }
        }
    }

    /// A lesson's page as a child left it, in the page store (screenshots keep it in memory only): its together
    /// problems and `own` on their own worked right, and a test of 12 with `test` right (`testAnswered` of them
    /// answered), when there's one.
    static func seedPage(_ id: String, own: Int, test: Int? = nil, testAnswered: Int = LessonPlan.test) {
        guard let spec = Lessons.spec(id) else { return }
        // its own seed, not the page's (Shots.seed(id)): the page would make the same numbers again for what it adds
        var rng = SeededRandom(seed: seed("seeded \(id)") ?? 3)
        let plan = LessonPlan(spec, using: &rng)
        var runs = plan.items.indices.map { plan.run(spec, $0) }
        var made = 0
        for i in runs.indices where plan.items[i].part == .together || (plan.items[i].part == .own && made < own) {
            runs[i] = worked(runs[i]); if plan.items[i].part == .own { made += 1 }
        }
        var tests: [LessonRun] = []
        if let test {
            tests = LessonPlan.testRuns(spec, using: &rng)
            for i in tests.indices where i < testAnswered { tests[i] = worked(tests[i], miss: i >= test) }
        }
        PageStore.save(id, .init(date: Date(), plan: plan, problems: runs.map(\.snapshot), test: tests.map(\.snapshot), recheck: [], spot: nil,
                                 recorded: test != nil && testAnswered == LessonPlan.test, solved: runs.filter(\.isLast).count, hintsLeft: LessonPlan.hints))
    }

    /// A problem worked to its end in Core, as a child would with each step's answer; `miss`: its first step wrong first.
    static func worked(_ run: LessonRun, miss: Bool = false) -> LessonRun {
        var r = run, missed = !miss
        for _ in 0..<40 where !r.isLast {
            if let a = r.step.answer {
                if !missed {
                    missed = true
                    if let c = a.choices { r.choose((Int(a.expected["c"] ?? 0) + 1) % c.count) } else { for b in a.boxes { r.set(b, (a.expected[b] ?? 0) + 7) } }
                    _ = r.go()
                }
                if a.choices != nil { r.choose(Int(a.expected["c"] ?? 0)) } else { for b in a.boxes { r.set(b, a.expected[b]) } }
            }
            _ = r.go()
        }
        return r
    }

    /// Works a problem as a child does (screenshots): each step answered (typed, picked, or on a paper lesson by its
    /// hand moves: the problem's own answerForShots) and checked, waiting while the paper shows each step right or plays
    /// Show me. `miss`: the first step answered wrong first, then `afterMiss` (the bar's Hint, say), and with
    /// `stopAfterMiss` it's left there; `showMe`: Show me on every step first; `steps`: stop after that many steps.
    static func work(_ m: any PageProblem, miss: Bool = false, afterMiss: (() -> Void)? = nil, stopAfterMiss: Bool = false, showMe: Bool = false, steps: Int = 99) async {
        var missed = !miss, done = 0
        /// Hands off while the paper answers (a step right shows for a moment, Show me plays), not in an instant page.
        func settle() async { for _ in 0..<100 where m.busy { try? await Task.sleep(for: .seconds(0.05)) } }
        /// A step checked right: until the next step is in (the paper shows it right for a moment first; on a busy
        /// machine that moment can outlast the hands-off time, and the same step mustn't be answered twice).
        func moved(from at: Int) async {
            for _ in 0..<200 where m.lesson.index == at && !m.solved { try? await Task.sleep(for: .seconds(0.05)) }
            await settle()
        }
        for _ in 0..<40 {
            await settle()
            if m.solved || done >= steps { return }
            guard m.lesson.step.answer != nil else { let at = m.lesson.index; m.go(); await moved(from: at); continue }
            if !missed {
                missed = true
                let at = m.lesson.index
                m.answerForShots(wrong: true)
                afterMiss?()
                if stopAfterMiss { return }
                // one try: its answer is shown, and it moves on by itself (waited for: the paper may still be drawing)
                if m.lesson.oneTry {
                    for _ in 0..<60 where m.lesson.index == at && !m.solved { try? await Task.sleep(for: .seconds(0.05)) }
                    done += 1; continue
                }
                await settle()
                m.reset()
            }
            if showMe { m.showMe(); await settle() }
            let at = m.lesson.index
            m.answerForShots(wrong: false)
            await moved(from: at)
            done += 1
        }
    }

    /// `-numbers a=1,b=2,…`: a problem's numbers, the lesson's own worked-out ones added (the fractions' L, A, C, S).
    static func given(_ id: String) -> Numbers? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-numbers"), i + 1 < args.count else { return nil }
        var n: Numbers = [:]
        for pair in args[i + 1].split(separator: ",") { let kv = pair.split(separator: "="); if kv.count == 2, let v = Double(kv[1]) { n[String(kv[0])] = v } }
        guard ["add", "sub", "mix"].contains(id) else { return n }
        return UnlikeFractions.numbers(a: Int(n["a"] ?? 1), b: Int(n["b"] ?? 2), c: Int(n["c"] ?? 1), d: Int(n["d"] ?? 3), minus: n["minus"] == 1)
    }

    /// `-rotate`: turn the other way (from `-portrait` or `-landscape`) a moment after the moment opens, to check everything stays together.
    static func rotate() {
        Task {
            try? await Task.sleep(for: .seconds(1))
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            let turn: UIInterfaceOrientationMask = ProcessInfo.processInfo.arguments.contains("-portrait") ? .landscapeRight : .portrait
            scene.requestGeometryUpdate(UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: turn))
        }
    }

    /// The whole Paper proof playing on its own, at real speed, for the build's video.
    static func demo(_ m: PaperModel) async {
        func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
        m.shotBox = .init(length: 4, width: 3, height: 2)
        m.frameGroup(duration: 0)
        m.drawnAt = PaperClock.now
        await wait(2.4)
        let uc = Map.piece("uc")!
        m.select(uc); await wait(2)
        m.open(uc); await wait(2)
        guard let l = m.lesson else { return }
        l.go(); await wait(1.4)
        for c in [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1)] { l.tap(.init(c.0, c.1)); await wait(0.35) }
        l.go(); await wait(1.4)
        // Show me previews the step, then the child covers the rest of the floor themselves
        l.showMe(); await wait((l.preview?.end ?? PaperClock.now) - PaperClock.now + 0.3)
        for i in 0..<l.box.floor where l.lesson.marks[i] == nil { l.tap(UnitCubes.cell(i, in: l.box)); await wait(0.2) }
        l.go(); await wait(3)
        l.go(); await wait(3)
        m.close(); await wait(2)
    }
}
