import SwiftUI

@main
struct Obento2App: App {
    var body: some Scene {
        WindowGroup { PaperScreen(model: PaperModel()).statusBarHidden() }
    }
}
