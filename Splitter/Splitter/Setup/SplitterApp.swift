import SwiftUI

@main
struct SplitterApp: App {
    @State private var store = SplitterApp.makeStore()
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenWelcome || ProcessInfo.processInfo.arguments.contains("-skipWelcome") {
                    BillListView()
                        .transition(.opacity)
                } else {
                    WelcomeView {
                        withAnimation(.easeInOut(duration: 0.4)) { hasSeenWelcome = true }
                    }
                    .transition(.opacity)
                }
            }
            .environment(store)
            .tint(Theme.brand)
        }
    }

    private static func makeStore() -> BillStore {
        #if DEBUG
        // `-demo` launches with sample bills in a throwaway file (used for screenshots / simulator runs).
        if ProcessInfo.processInfo.arguments.contains("-demo") {
            let store = BillStore(fileURL: .temporaryDirectory.appending(path: "demo-bills.json"))
            store.bills = DemoData.bills
            return store
        }
        #endif
        return BillStore()
    }
}
