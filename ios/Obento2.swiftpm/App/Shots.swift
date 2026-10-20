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

    static func run(_ m: PaperModel) {
        guard let name else { return }
        // as a child does it: tap the lesson (the glide), then Start
        func start(_ p: Piece) { m.select(p); m.open(p) }
        // the same progress every time, and nothing saved: two lessons learned
        Progress.shared.saving = false
        Progress.shared.reset(to: ["g5-mult2", "add"])
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-landscape") || args.contains("-portrait"),
           let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.requestGeometryUpdate(UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: args.contains("-portrait") ? .portrait : .landscapeRight))
        }
        // let the window settle into its final size, then jump to the moment
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if name == "demo" { await demo(m); return }
            if name.hasPrefix("teach") {
                // the How to taught a tap at a time: teach-0 is the idea, teach-N after N taps
                m.frameGroup(duration: 0); m.drawnAt = PaperClock.now - 100
                let ad = Map.pieces.first { $0.id == "ad" }!
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
                guard let p = Map.pieces.first(where: { $0.id == id }) else { return }
                m.instant = true; m.select(p); m.open(p); m.instant = false
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
                guard let p = Map.pieces.first(where: { $0.id == id }) else { return }
                PageStore.clear(id)
                m.frameGroup(duration: 0); m.drawnAt = PaperClock.now - 100
                func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
                m.select(p); await wait(1); m.open(p); await wait(2)
                for _ in 0..<10 { m.bars?.skipHowTo(); await wait(1.3) }
                guard let page = m.bars, let w = page.problems.first as? WorkProblem else { return }
                await wait(2); page.open(w); await wait(3)
                w.showMe(); await wait(0.5); w.go(); await wait(2)
                page.backToProblems()
                return
            }
            if name.hasPrefix("live-") {
                // the real path, not instant, to watch things draw in and the camera follow: the How to tapped through,
                // the first problem opened, its answer box tapped, a step worked
                let id = String(name.dropFirst(5))
                guard let p = Map.pieces.first(where: { $0.id == id }) else { return }
                PageStore.clear(id)
                m.frameGroup(duration: 0); m.drawnAt = PaperClock.now - 100
                func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
                m.select(p); await wait(1); m.open(p); await wait(2)
                for _ in 0..<10 { m.bars?.skipHowTo(); await wait(1.3) }
                guard let page = m.bars, let w = page.problems.first as? WorkProblem else { return }
                await wait(1.5); page.open(w); await wait(2.5)
                if let box = w.lesson.step.answer?.boxes.first { w.select(box) }
                await wait(2); w.showMe(); await wait(1); w.go(); await wait(3)
                w.showMe(); await wait(1); w.go(); await wait(2)
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
                let ad = Map.pieces.first { $0.id == "ad" }!
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
                let ad = Map.pieces.first { $0.id == "ad" }!
                m.select(ad); try? await Task.sleep(for: .seconds(1.5))
                m.open(ad)
                return
            }
            if name == "leave-ad" {
                // the lesson page, then back to the map, for watching the page erase itself
                m.frameGroup(duration: 0); m.drawnAt = PaperClock.now - 100
                m.instant = true; m.shotProblem = .init(a: 4, p: 1, b: 8, q: 1)
                m.select(Map.pieces.first { $0.id == "ad" }!); m.open(Map.pieces.first { $0.id == "ad" }!); m.instant = false
                try? await Task.sleep(for: .seconds(2.5))
                m.close()
                return
            }
            if name == "page-zoom" {
                // the lesson page: out to see it all and back in to a problem, again and again, for -perf timings
                m.frameGroup(duration: 0); m.drawnAt = PaperClock.now - 100
                m.instant = true; m.shotProblem = .init(a: 4, p: 1, b: 8, q: 1)
                m.select(Map.pieces.first { $0.id == "ad" }!); m.open(Map.pieces.first { $0.id == "ad" }!); m.instant = false
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
                m.instant = true; m.shotProblem = .init(a: 4, p: 1, b: 8, q: 1)
                m.select(Map.pieces.first { $0.id == "ad" }!); m.open(Map.pieces.first { $0.id == "ad" }!); m.instant = false
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
                for id in ["ad", "uc", "g5-pow10", "uc", "g5-mult2", "uc"] {
                    m.select(Map.pieces.first { $0.id == id }!); try? await Task.sleep(for: .seconds(1.2))
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
            defer { if ProcessInfo.processInfo.arguments.contains("-rotate") { rotate() } }
            m.instant = true
            m.drawnAt = PaperClock.now - 100
            m.shotBox = .init(length: 4, width: 3, height: 2)
            m.frameGroup(duration: 0)
            m.shotProblem = .init(a: 4, p: 1, b: 8, q: 1)
            let uc = Map.pieces.first { $0.id == "uc" }!
            switch name {
            case "paper": break
            case "selected": m.select(uc)
            case let n where n.hasPrefix("cards-"):
                // cards-<lesson id>[-done]: the page of problems after the How to; -done: the together ones solved, the
                // first own one with a miss (a fresh one comes for it), two more right, and the page back
                let rest = String(n.dropFirst(6)), done = rest.hasSuffix("-done"), id = done ? String(rest.dropLast(5)) : rest
                guard let p = Map.pieces.first(where: { $0.id == id }) else { return }
                m.select(p); m.open(p)
                guard done, let page = m.bars else { return }
                @MainActor func work(_ w: WorkProblem, miss: Bool) {
                    page.open(w)
                    var missed = !miss
                    while !w.solved {
                        if let a = w.lesson.step.answer {
                            if a.choices != nil { w.choose(Int(a.expected["c"] ?? 0)) }
                            else if !missed { w.type("1"); w.go(); missed = true; w.reset() }
                            _ = w.lesson.step.answer.map { _ in w.showMe() }
                        }
                        w.go()
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
                guard let p = Map.pieces.first(where: { $0.id == id }) else { return }
                m.select(p); m.open(p)
                guard let page = m.bars, page.problems.indices.contains(which), let w = page.problems[which] as? WorkProblem else { return }
                // -numbers a=1,b=2,…: that problem with these numbers (the lesson's own worked-out ones added by its spec);
                // -story: told as its story
                if let i = args.firstIndex(of: "-numbers"), i + 1 < args.count {
                    var given: Numbers = [:]
                    for pair in args[i + 1].split(separator: ",") { let kv = pair.split(separator: "="); if kv.count == 2, let v = Double(kv[1]) { given[String(kv[0])] = v } }
                    w.use(["add", "sub", "mix"].contains(id) ? UnlikeFractions.numbers(a: Int(given["a"] ?? 1), b: Int(given["b"] ?? 2), c: Int(given["c"] ?? 1), d: Int(given["d"] ?? 3), minus: given["minus"] == 1) : given,
                          story: args.contains("-story"))
                }
                page.open(w)
                defer { if ProcessInfo.processInfo.arguments.contains("-keypad"), let box = w.lesson.step.answer?.boxes.first { w.select(box) } }
                // -wrong: a wrong answer typed and checked, so its box and words show red
                defer { if ProcessInfo.processInfo.arguments.contains("-wrong") { w.type("1"); w.go() } }
                for _ in 0..<max(0, k) { if w.lesson.step.answer != nil { w.lesson.step.answer?.choices != nil ? w.choose(Int(w.lesson.step.answer!.expected["c"] ?? 0)) : w.showMe() }; w.go() }
            case "tests":
                // the map with Add with different bottoms learned: its chapter's test opens; frame on Fractions
                Progress.shared.reset(to: ["ad"]); m.frameChapter(2)
            case "tests-all":
                Progress.shared.reset(to: ["ad", "uc"]); Progress.shared.tested("test-fractions", level: 3)
                m.frameGroup(duration: 0)
            case "tests-taken":
                Progress.shared.reset(to: ["ad"]); Progress.shared.tested("test-fractions", level: 3, right: 10, of: 12); m.frameChapter(2)
            case "grade-test":
                Progress.shared.reset(to: ["ad"]); Progress.shared.tested("test-fractions", level: 4)
                m.select(Map.tests.first { $0.id == "test-grade" }!)
            case "test-page":
                Progress.shared.reset(to: ["ad"])
                let t = Map.tests.first { $0.id == "test-fractions" }!
                m.select(t); m.open(t)
            case "selected-ad": m.select(Map.pieces.first { $0.id == "ad" }!)
            case "selected-many":
                // tap five lessons one after another: the zoom mustn't creep in
                for id in ["g5-mult2", "ad", "g5-round", "uc", "add"] { m.select(Map.pieces.first { $0.id == id }!) }
            case "theme":
                // flip to dark while the app runs, as the moon in the top bar does
                UserDefaults.standard.set("light", forKey: "theme")
                try? await Task.sleep(for: .seconds(1))
                UserDefaults.standard.set("dark", forKey: "theme")
            case "recheck":
                Progress.shared.makeDue("ad")
                start(Map.pieces.first { $0.id == "ad" }!)
            case "back": start(Map.pieces.first { $0.id == "ad" }!); m.close()
            case let n where n.hasPrefix("fractions"):
                // the page: the How to has played (instant), the 16 problems are on the paper
                start(Map.pieces.first { $0.id == "ad" }!)
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
        let uc = Map.pieces.first { $0.id == "uc" }!
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
