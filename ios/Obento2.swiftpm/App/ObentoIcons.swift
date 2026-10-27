import SwiftUI

/// Obento²'s own icons (G 17 Oct): drawn like the lesson pictures, thin square-ended lines on a 24-unit grid, one shape
/// softly tinted. Each is a few SVG-style paths, the same ones as the toolbar mockup, read by `SVGPath`.
enum ObentoIcon: String, CaseIterable {
    case today, lessons, me, more, back, hint, show, restart, read, every, find, grade, dark, settings, lock, close

    /// How a part is painted: lines only, a soft tint inside its lines, solid, or the paper's colour inside its lines.
    enum Style { case line, tint, solid, paper }

    var parts: [(String, Style)] {
        switch self {
        case .today: [("M3 5h18v16H3ZM3 9.5h18M8 2.5v4M16 2.5v4", .line), ("M13 13h4v4h-4Z", .tint)]
        case .lessons: [("M3 3h7v7H3Z", .tint), ("M14 3h7v7h-7ZM3 14h7v7H3ZM14 14h7v7h-7Z", .line)]
        case .me: [("M4 21.5v-2.5a5 5 0 0 1 5-5h6a5 5 0 0 1 5 5v2.5Z", .tint), ("M16 7a4 4 0 1 1-8 0a4 4 0 1 1 8 0Z", .line)]
        case .more: [("M5.7 12a2.2 2.2 0 1 1-4.4 0a2.2 2.2 0 1 1 4.4 0ZM14.2 12a2.2 2.2 0 1 1-4.4 0a2.2 2.2 0 1 1 4.4 0ZM22.7 12a2.2 2.2 0 1 1-4.4 0a2.2 2.2 0 1 1 4.4 0Z", .solid)]
        case .back: [("M20 12H4.5M10 6l-6 6 6 6", .line)]
        case .hint: [("M12 3a6 6 0 0 0-3.5 10.9V17h7v-3.1A6 6 0 0 0 12 3Z", .tint), ("M9.5 20.5h5", .line)]
        case .show: [("M3 4h18v16H3Z", .tint), ("M10 8.5v7l5.5-3.5Z", .solid)]
        case .restart: [("M3.5 12a8.5 8.5 0 1 0 8.5-8.5c-2.4 0-4.6 1-6.2 2.6L3.5 8.5M3.5 3.5v5h5", .line)]
        case .read: [("M4 9h4l5-4v14l-5-4H4Z", .tint), ("M16.5 9.5a3.5 3.5 0 0 1 0 5M19 7a7 7 0 0 1 0 10", .line)]
        case .every: [("M3 8V3h5M16 3h5v5M21 16v5h-5M8 21H3v-5", .line), ("M8 8h8v8H8Z", .tint)]
        case .find: [("M19 12a7 7 0 1 1-14 0a7 7 0 1 1 14 0ZM12 1.5v4M12 18.5v4M1.5 12h4M18.5 12h4", .line), ("M13.5 12a1.5 1.5 0 1 1-3 0a1.5 1.5 0 1 1 3 0Z", .solid)]
        case .grade: [("M17 2h5v20h-5Z", .tint), ("M2 17h5v5H2ZM9.5 9.5h5V22h-5Z", .line)]
        case .dark: [("M20 14.5A8.5 8.5 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5Z", .tint)]
        // ⋯ More open: close it, a cross in a softly tinted square (the square the Lessons icon's squares are measured on)
        case .close: [("M5 5h14v14H5Z", .tint), ("M9 9l6 6M15 9l-6 6", .line)]
        // the grown-ups' page: a padlock, its body tinted
        case .lock: [("M4.5 11h15v10h-15Z", .tint), ("M8 11V7.5a4 4 0 0 1 8 0V11", .line)]
        case .settings: [("M9.89 5.11L10.17 2.58L13.83 2.58L14.11 5.11L15.38 5.64L17.37 4.04L19.96 6.63L18.36 8.62L18.89 9.89L21.42 10.17L21.42 13.83L18.89 14.11L18.36 15.38L19.96 17.37L17.37 19.96L15.38 18.36L14.11 18.89L13.83 21.42L10.17 21.42L9.89 18.89L8.62 18.36L6.63 19.96L4.04 17.37L5.64 15.38L5.11 14.11L2.58 13.83L2.58 10.17L5.11 9.89L5.64 8.62L4.04 6.63L6.63 4.04L8.62 5.64Z", .tint),
                         ("M15 12a3 3 0 1 1-6 0a3 3 0 1 1 6 0Z", .paper)]
        }
    }
}

/// An Obento² icon, drawn in the current foreground colour.
struct ObentoIconView: View {
    let icon: ObentoIcon
    var size: CGFloat = 28

    var body: some View {
        Canvas { ctx, s in
            let k = s.width / 24
            let line = StrokeStyle(lineWidth: 1.75 * k, lineCap: .square, lineJoin: .miter)
            for (d, style) in icon.parts {
                let p = SVGPath.parse(d).applying(CGAffineTransform(scaleX: k, y: k))
                switch style {
                case .line: ctx.stroke(p, with: .foreground, style: line)
                case .tint:
                    var soft = ctx; soft.opacity = 0.16
                    soft.fill(p, with: .foreground)
                    ctx.stroke(p, with: .foreground, style: line)
                case .solid: ctx.fill(p, with: .foreground)
                case .paper: ctx.fill(p, with: .color(Ink.surface)); ctx.stroke(p, with: .foreground, style: line)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

extension ObentoIconView {
    init(_ icon: ObentoIcon, size: CGFloat = 28) { self.icon = icon; self.size = size }
}

/// Reads the SVG path syntax the icons are written in: M L H V C S A Z, upper and lower case. Arcs are circular.
enum SVGPath {
    static func parse(_ d: String) -> Path {
        var path = Path()
        var cmd: Character = "M"
        var cur = CGPoint.zero, start = CGPoint.zero, lastControl: CGPoint?
        var tokens: [(Character?, Double?)] = []
        var num = ""
        func flush() { if !num.isEmpty, let v = Double(num) { tokens.append((nil, v)) }; num = "" }
        for ch in d {
            if ch.isLetter && ch != "e" { flush(); tokens.append((ch, nil)) }
            else if ch == "-" { if num.last == "e" { num.append(ch) } else { flush(); num = "-" } }
            else if ch == "." { if num.contains(".") { flush() }; num.append(ch) }
            else if ch.isNumber || ch == "e" { num.append(ch) }
            else { flush() }
        }
        flush()
        var i = 0
        func take(_ n: Int) -> [Double]? {
            var out: [Double] = []
            var j = i
            while out.count < n, j < tokens.count, let v = tokens[j].1 { out.append(v); j += 1 }
            guard out.count == n else { return nil }
            i = j; return out
        }
        while i < tokens.count {
            if let c = tokens[i].0 { cmd = c; i += 1 }
            let rel = cmd.isLowercase
            func pt(_ x: Double, _ y: Double) -> CGPoint { rel ? CGPoint(x: cur.x + x, y: cur.y + y) : CGPoint(x: x, y: y) }
            switch cmd.uppercased().first! {
            case "M":
                guard let v = take(2) else { i += 1; continue }
                cur = pt(v[0], v[1]); start = cur; path.move(to: cur); lastControl = nil
                cmd = rel ? "l" : "L"
            case "L":
                guard let v = take(2) else { i += 1; continue }
                cur = pt(v[0], v[1]); path.addLine(to: cur); lastControl = nil
            case "H":
                guard let v = take(1) else { i += 1; continue }
                cur = CGPoint(x: rel ? cur.x + v[0] : v[0], y: cur.y); path.addLine(to: cur); lastControl = nil
            case "V":
                guard let v = take(1) else { i += 1; continue }
                cur = CGPoint(x: cur.x, y: rel ? cur.y + v[0] : v[0]); path.addLine(to: cur); lastControl = nil
            case "C":
                guard let v = take(6) else { i += 1; continue }
                let c1 = pt(v[0], v[1]), c2 = pt(v[2], v[3]), e = pt(v[4], v[5])
                path.addCurve(to: e, control1: c1, control2: c2); cur = e; lastControl = c2
            case "S":
                guard let v = take(4) else { i += 1; continue }
                let c1 = lastControl.map { CGPoint(x: 2 * cur.x - $0.x, y: 2 * cur.y - $0.y) } ?? cur
                let c2 = pt(v[0], v[1]), e = pt(v[2], v[3])
                path.addCurve(to: e, control1: c1, control2: c2); cur = e; lastControl = c2
            case "A":
                guard let v = take(7) else { i += 1; continue }
                let e = pt(v[5], v[6])
                arc(&path, from: cur, to: e, radius: v[0], large: v[3] != 0, sweep: v[4] != 0)
                cur = e; lastControl = nil
            case "Z":
                path.closeSubpath(); cur = start; lastControl = nil
            default:
                i += 1
            }
        }
        return path
    }

    /// A circular SVG arc from `a` to `b`, by its centre (the SVG spec's endpoint-to-centre conversion).
    private static func arc(_ path: inout Path, from a: CGPoint, to b: CGPoint, radius r0: Double, large: Bool, sweep: Bool) {
        let mx = (a.x - b.x) / 2, my = (a.y - b.y) / 2
        let d2 = mx * mx + my * my
        guard d2 > 0 else { return }
        let r = max(r0, sqrt(d2))
        var f = sqrt(max(0, (r * r - d2) / d2))
        if large == sweep { f = -f }
        let cx = (a.x + b.x) / 2 + f * my, cy = (a.y + b.y) / 2 - f * mx
        let start = atan2(a.y - cy, a.x - cx), end = atan2(b.y - cy, b.x - cx)
        // SVG's sweep is towards larger angles on a y-down screen; SwiftUI's `clockwise` names the opposite
        path.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: .radians(start), endAngle: .radians(end), clockwise: !sweep)
    }
}
