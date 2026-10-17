import SwiftUI
import UIKit

/// The paper's colours. Same tokens as the prototype; light and dark follow the device.
enum Ink {
    static let paper = dynamic(0xF3F2EF, 0x121211)
    static let surface = dynamic(0xFBFBFA, 0x1B1B1A)
    static let sunk = dynamic(0xEFEEE9, 0x232321)
    static let ink = dynamic(0x1A1A19, 0xECEBE7)
    static let ink2 = dynamic(0x6B6964, 0xA3A19B)
    static let pencil = dynamic(0xCFCCC5, 0x3D3C39)
    static let lineStrong = dynamic(0xCFCCC5, 0x3A3A37)
    static let line = dynamic(0xE3E1DC, 0x2C2C2A)
    static let ink3 = dynamic(0x8C867D, 0x878177)
    static let right = dynamic(0x178A57, 0x3CCF8E)
    /// Grid lines, already mixed into the paper so they draw the same in 2D and 3D.
    static let gridMinor = dynamic(mix(0xF3F2EF, 0x1A1A19, 0.045), mix(0x121211, 0xECEBE7, 0.035))
    static let gridMajor = dynamic(mix(0xF3F2EF, 0x1A1A19, 0.09), mix(0x121211, 0xECEBE7, 0.07))

    static func dynamic(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }

    /// a + (b - a) * k, per channel.
    static func mix(_ a: UInt32, _ b: UInt32, _ k: Double) -> UInt32 {
        func ch(_ v: UInt32, _ s: UInt32) -> Double { Double((v >> s) & 0xFF) }
        func m(_ s: UInt32) -> UInt32 { UInt32((ch(a, s) + (ch(b, s) - ch(a, s)) * k).rounded()) << s }
        return m(16) | m(8) | m(0)
    }
}

/// Chapter colours. Colour lives only in the maths.
enum Chapter: String, CaseIterable {
    case whole, decimals, fractions, measurement
    var hex: UInt32 {
        switch self { case .whole: 0x7A5CF0; case .decimals: 0xE0559B; case .fractions: 0x3B6CFF; case .measurement: 0xE39B00 }
    }
    var color: Color { Color(UIColor(hex: hex)) }
    var title: String {
        switch self { case .whole: "Whole numbers"; case .decimals: "Decimals"; case .fractions: "Fractions"; case .measurement: "Measurement" }
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

/// Soft, rounded type. One line to switch to Inter later.
enum Typeface {
    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight, design: .rounded) }
    static let question = font(28, .medium)
    static let hint = font(16)
    static let label = font(20, .semibold)
    static let button = font(15, .medium)
    static let name = font(17, .medium)
    static let title = font(26, .medium)
}

/// One square button the size of two cells, drawn on the paper like everything else.
struct CellButton<Label: View>: View {
    var width: CGFloat = 40
    var main = false
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    var body: some View {
        Button(action: action) {
            label()
                .frame(width: width, height: 40)
                .background(Ink.surface, ignoresSafeAreaEdges: [])
                .overlay(Rectangle().strokeBorder(main ? Ink.ink : Ink.lineStrong, lineWidth: 1.5))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Ink.ink)
    }
}

struct Icon: View {
    let name: String
    var size: CGFloat = 20
    var body: some View { Image("ph-\(name)").resizable().renderingMode(.template).frame(width: size, height: size) }
}

/// The main action: words on the left, an arrow on the right, nine cells wide.
struct MainCellButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        CellButton(width: 180, main: true, action: action) {
            HStack { Text(title).font(Typeface.button); Spacer(); Icon(name: "arrow-right") }
                .padding(.leading, 16).padding(.trailing, 10)
        }
    }
}
