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
            case let n where n.hasPrefix("L-"):
                // L-<lesson id>-<step>: open any lesson and work it to that step, each answer filled in by Show me
                let parts = n.dropFirst(2).split(separator: "-"), id = parts.dropLast().joined(separator: "-")
                guard let p = Map.pieces.first(where: { $0.id == id }), let k = Int(parts.last ?? "0") else { return }
                start(p)
                guard let s = m.steps else { return }
                for _ in 0..<k { if s.lesson.step.answer != nil { s.showMe() }; s.go() }
                if s.lesson.step.answer != nil, args.contains("-filled") { s.showMe() }
            case let n where n.hasPrefix("pow10"):
                m.shotNumbers = PowersOfTen.numbers(x: 4.6, k: 2)
                start(Map.pieces.first { $0.id == "g5-pow10" }!)
                guard let s = m.steps, n != "pow10" else { return }
                s.go(); s.type("2"); s.go()
                if n == "pow10-move" { for k in ["4", "6"] { s.type(k) }; s.go(); return }
                s.showMe(); s.go()
            case let n where n.hasPrefix("fractions"):
                // the page: the How to has played (instant), the 16 problems are on the paper
                start(Map.pieces.first { $0.id == "ad" }!)
                guard let page = m.bars, n != "fractions" else { return }
                let b = n == "fractions-story" ? page.problems[2] : n == "fractions-check" ? page.problems[12] : page.problems[0]
                if n == "fractions-howto" { page.watchAgain(); return }
                if n == "fractions-overview" { for i in 0..<page.problems[0].problem.covered { page.problems[0].tap(i) }; page.problems[0].go(); m.frameAll(); return }
                if n == "fractions-story" { b.choose(2); b.go(); return }
                if n == "fractions-wrong" || n == "fractions-check" { b.tap(b.problem.covered + 1); b.go(); return }
                if n == "fractions-hint2" { b.tap(b.problem.covered + 1); b.go(); b.go(); return }
                for i in 0..<b.problem.covered { b.tap(i) }
                b.go()
                if n == "fractions-add" { return }
                if n == "fractions-two" { for i in b.problem.covered..<b.problem.total { b.tap(i) }; b.go(); page.problems[1].tap(0); return }
                for i in b.problem.covered..<b.problem.total { b.tap(i) }
                b.go()
            default:
                start(uc)
                guard let l = m.lesson else { return }
                if name == "flat" { return }
                l.go()
                if name.hasPrefix("cover") { for c in [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1)] { l.tap(.init(c.0, c.1)) } }
                if name == "cover-hint1" { l.go(); return }
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
