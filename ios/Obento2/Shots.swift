import SwiftUI
import UIKit
import ObentoCore

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
        if ProcessInfo.processInfo.arguments.contains("-landscape"),
           let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.requestGeometryUpdate(UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeRight))
        }
        // let the window settle into its final size, then jump to the moment
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if name == "demo" { await demo(m); return }
            m.instant = true
            m.drawnAt = PaperClock.now - 100
            m.shotBox = .init(length: 4, width: 3, height: 2)
            m.frameGroup(duration: 0)
            let uc = Volume.pieces.first { $0.id == "uc" }!
            switch name {
            case "paper": break
            case "selected": m.select(uc)
            default:
                m.open(uc)
                guard let l = m.lesson else { return }
                if name == "flat" { return }
                l.go()
                if name == "cover" { for c in [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1)] { l.tap(.init(c.0, c.1)) }; return }
                _ = l.showMe(); l.go()
                if name == "tilt" { return }
                l.go()
            }
        }
    }

    /// The whole Paper proof playing on its own, at real speed, for the build's video.
    static func demo(_ m: PaperModel) async {
        func wait(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
        m.shotBox = .init(length: 4, width: 3, height: 2)
        m.frameGroup(duration: 0)
        m.drawnAt = PaperClock.now
        await wait(2.4)
        let uc = Volume.pieces.first { $0.id == "uc" }!
        m.select(uc); await wait(2)
        m.open(uc); await wait(2)
        guard let l = m.lesson else { return }
        l.go(); await wait(1.4)
        for c in [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1)] { l.tap(.init(c.0, c.1)); await wait(0.35) }
        l.go(); await wait(1.4)
        l.showMe(); await wait(1.4)
        l.go(); await wait(3)
        l.go(); await wait(3)
        m.close(); await wait(2)
    }
}
