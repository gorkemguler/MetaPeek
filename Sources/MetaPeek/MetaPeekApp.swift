import SwiftUI

extension Notification.Name {
    static let metaPeekOpenFile = Notification.Name("metaPeekOpenFile")
}

struct MetaPeekApp: App {
    @StateObject private var store = FileReportStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 900, minHeight: 600)
                .tint(Theme.accent)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(L10n.open + "…") {
                    NotificationCenter.default.post(name: .metaPeekOpenFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
