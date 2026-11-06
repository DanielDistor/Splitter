import SwiftUI

@main
struct SplitterApp: App {
    @State private var store = SplitterApp.makeStore()

    var body: some Scene {
        WindowGroup {
            BillListView()
                .environment(store)
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
