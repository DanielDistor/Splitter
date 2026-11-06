import SwiftUI

struct BillListView: View {
    @Environment(BillStore.self) private var store
    @State private var path: [UUID] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if store.bills.isEmpty {
                    ContentUnavailableView {
                        Label("No Bills Yet", systemImage: "receipt")
                    } description: {
                        Text("Add a bill, list who was there and what they had. Splitter works out who owes what, including tax and tip.")
                    } actions: {
                        Button("New Bill", action: addBill)
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(store.sortedBills) { bill in
                            NavigationLink(value: bill.id) {
                                BillRow(bill: bill)
                            }
                        }
                        .onDelete { offsets in
                            let sorted = store.sortedBills
                            store.delete(ids: offsets.map { sorted[$0].id })
                        }
                    }
                }
            }
            .navigationTitle("Splitter")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Bill", systemImage: "plus", action: addBill)
                }
            }
            .navigationDestination(for: UUID.self) { id in
                BillDetailView(billID: id)
            }
        }
        .onAppear(perform: openRequestedBill)
    }

    private func addBill() {
        path.append(store.addBill().id)
    }

    /// `-openBill` (debug only) jumps straight into the newest bill, for simulator screenshots.
    private func openRequestedBill() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-openBill"), path.isEmpty, let first = store.sortedBills.first {
            path = [first.id]
        }
        #endif
    }
}

private struct BillRow: View {
    let bill: Bill

    var body: some View {
        let summary = Split.summarize(bill)
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bill.title.isEmpty ? "Untitled Bill" : bill.title)
                    .font(.headline)
                Text("\(bill.date.formatted(date: .abbreviated, time: .omitted)) · \(peopleLabel)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(Money.format(summary.totalCents))
                .font(.headline)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }

    private var peopleLabel: String {
        bill.people.count == 1 ? "1 person" : "\(bill.people.count) people"
    }
}

#Preview {
    BillListView()
        .environment(BillStore(fileURL: .temporaryDirectory.appending(path: "preview.json")))
}
