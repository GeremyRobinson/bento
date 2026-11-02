import SwiftUI

/// What's drawn on the paper as things VoiceOver (and the real-touch tests) can find: the page's cards, and the How to's
/// blocks while it waits. Each is an invisible box over where it's drawn now; it never takes a touch, so a tap on it
/// lands on the paper underneath and goes the way a finger's would.
struct PaperAccess: View {
    let model: PaperModel
    let cam: PaperCamera

    private struct Item: Identifiable { let id: String; let label: String; let value: String; let rect: CGRect }

    private var items: [Item] {
        guard let b = model.bars else { return [] }
        func onScreen(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> CGRect {
            let a = cam.toScreen(Point(x, y)), z = cam.toScreen(Point(x + w, y + h))
            return CGRect(x: a.x, y: a.y, width: z.x - a.x, height: z.y - a.y)
        }
        if b.mode == .choose {
            return b.cards.map { Item(id: $0.id, label: $0.title, value: $0.line, rect: onScreen($0.rect.x, $0.rect.y, $0.rect.width, $0.rect.height)) }
        }
        if b.mode == .howTo, !b.howToGone {
            return ProblemLayout.blocks(b.howTo).compactMap { k in
                let word: String
                switch k.kind { case .next: word = "Next step"; case .practise: word = "Practice"; case .again: word = "Watch again"; case .skip: word = "Skip"; default: return nil }
                return Item(id: "howto-\(word)", label: word, value: "", rect: onScreen(k.rect.minX, k.rect.minY, k.rect.width, k.rect.height))
            }
        }
        return []
    }

    var body: some View {
        ForEach(items) { it in
            Color.clear
                .frame(width: max(1, it.rect.width), height: max(1, it.rect.height))
                .position(x: it.rect.midX, y: it.rect.midY)
                .accessibilityElement()
                .accessibilityLabel(it.label)
                .accessibilityValue(it.value)
                .accessibilityAddTraits(.isButton)
                .allowsHitTesting(false)
        }
    }
}
