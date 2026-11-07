import SwiftUI

struct BillListView: View {
    @Environment(BillStore.self) private var store
    @State private var path: [UUID] = []

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    header(topInset: geometry.safeAreaInsets.top)

                    if store.bills.isEmpty {
                        emptyState
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Bills")
                                .font(.title3.bold())
                                .padding(.horizontal, 4)
                            ForEach(store.sortedBills) { bill in
                                NavigationLink(value: bill.id) {
                                    BillCard(bill: bill)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Delete Bill", systemImage: "trash", role: .destructive) {
                                        withAnimation { store.delete(ids: [bill.id]) }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 110)
            }
            .ignoresSafeArea(edges: .top)
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .bottom) { newBillButton }
            .navigationDestination(for: UUID.self) { id in
                BillDetailView(billID: id)
            }
        }
        .onAppear(perform: openRequestedBill)
    }

    // MARK: Pieces

    private func header(topInset: CGFloat) -> some View {
        let total = store.bills.reduce(0) { $0 + Split.summarize($1).totalCents }
        let friends = Set(store.bills.flatMap { $0.people.map { $0.name.lowercased() } }).count

        return VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 12) {
                Image("Logo")
                    .resizable()
                    .frame(width: 38, height: 38)
                    .clipShape(.rect(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.3)))
                Text("Splitter")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("TOTAL SPLIT")
                    .font(.caption.weight(.semibold))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.7))
                Text(Money.format(total))
                    .font(.money(46))
                    .contentTransition(.numericText())
                Text("\(store.bills.count) \(store.bills.count == 1 ? "bill" : "bills") · \(friends) \(friends == 1 ? "person" : "people")")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.top, topInset + 8)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            UnevenRoundedRectangle(bottomLeadingRadius: 36, bottomTrailingRadius: 36)
                .fill(Theme.heroGradient)
                .shadow(color: Theme.brand.opacity(0.3), radius: 20, y: 10)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "receipt")
                .font(.system(size: 34))
                .foregroundStyle(Theme.brand)
                .frame(width: 76, height: 76)
                .background(Theme.brand.opacity(0.1), in: Circle())
            Text("No bills yet")
                .font(.title3.bold())
            Text("Tap New Bill, add who was there and what they had — or scan the receipt. Splitter works out who owes what.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Theme.card, in: .rect(cornerRadius: 24))
        .shadow(color: Theme.shadow, radius: 16, y: 6)
        .padding(.horizontal, 20)
    }

    private var newBillButton: some View {
        Button(action: addBill) {
            Label("New Bill", systemImage: "plus")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 17)
                .background(Theme.heroGradient, in: Capsule())
                .shadow(color: Theme.brandDeep.opacity(0.35), radius: 16, y: 8)
        }
        .padding(.bottom, 10)
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

private struct BillCard: View {
    let bill: Bill

    var body: some View {
        let summary = Split.summarize(bill)
        HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(bill.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(.caption2.weight(.bold))
                Text(bill.date.formatted(.dateTime.day()))
                    .font(.money(22))
            }
            .foregroundStyle(Theme.brand)
            .frame(width: 54, height: 54)
            .background(Theme.brand.opacity(0.1), in: .rect(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 7) {
                Text(bill.title.isEmpty ? "Untitled Bill" : bill.title)
                    .font(.headline)
                    .lineLimit(2)
                if bill.people.isEmpty {
                    Text("No one added yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    AvatarStack(people: bill.people, size: 24)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 4) {
                Text(Money.format(summary.totalCents))
                    .font(.money(19))
                    .foregroundStyle(Theme.brand)
                Text(bill.items.count == 1 ? "1 item" : "\(bill.items.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .fixedSize()
        }
        .padding(16)
        .background(Theme.card, in: .rect(cornerRadius: 22))
        .shadow(color: Theme.shadow, radius: 14, y: 5)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    let store = BillStore(fileURL: .temporaryDirectory.appending(path: "preview.json"))
    store.bills = DemoData.bills
    return BillListView().environment(store)
}
#endif
