import SwiftUI

/// Edit one person on a bill: their name, what they had, or take them off the bill.
struct PersonEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var bill: Bill
    let personID: UUID
    let onRemove: () -> Void
    @State private var confirmRemove = false

    private var index: Int? { bill.people.firstIndex { $0.id == personID } }

    var body: some View {
        NavigationStack {
            if let index {
                form(index: index)
            }
        }
        .presentationDetents([.large])
        .presentationCornerRadius(28)
    }

    private func form(index: Int) -> some View {
        let person = bill.people[index]
        let name = person.name.isEmpty ? "Person" : person.name
        return Form {
            headerSection(index: index)
            itemsSection(color: Theme.color(for: index), name: person.name)
            Section {
                Button("Remove \(name) from Bill", role: .destructive) { confirmRemove = true }
                    .frame(maxWidth: .infinity)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .confirmationDialog("Remove \(name)?", isPresented: $confirmRemove, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                dismiss()
                onRemove()
            }
        } message: {
            Text("Their share gets split among everyone else who had the same items.")
        }
    }

    private func headerSection(index: Int) -> some View {
        let share = Split.summarize(bill).shares.first { $0.id == personID }
        return Section {
            HStack(spacing: 14) {
                Avatar(name: bill.people[index].name, color: Theme.color(for: index), size: 48)
                TextField("Name", text: $bill.people[index].name)
                    .font(.title3.weight(.semibold))
            }
            if let share {
                LabeledContent("Owes", value: Money.format(share.totalCents))
                    .font(.headline)
            }
        }
    }

    private func itemsSection(color: Color, name: String) -> some View {
        Section {
            if bill.items.isEmpty {
                Text("No items on this bill yet.")
                    .foregroundStyle(.secondary)
            }
            ForEach(bill.items) { item in
                ItemToggleRow(bill: $bill, personID: personID, item: item, color: color)
            }
        } header: {
            Text("What did \(name.isEmpty ? "they" : name) have?")
        } footer: {
            Text("Shared items are split evenly between everyone who had them. An item only one person had can't be unticked — give it to someone else first.")
        }
    }
}

private struct ItemToggleRow: View {
    @Binding var bill: Bill
    let personID: UUID
    let item: BillItem
    let color: Color

    var body: some View {
        let had = bill.person(personID, had: item)
        let sharers = bill.sharers(of: item)
        Button {
            withAnimation(.snappy(duration: 0.2)) {
                _ = bill.setPerson(personID, had: !had, itemID: item.id)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: had ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(had ? color : Color.secondary.opacity(0.5))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name.isEmpty ? "Unnamed item" : item.name)
                        .foregroundStyle(.primary)
                    Text(sharerLabel(sharers))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(Money.format(item.priceCents))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.primary)
        .disabled(had && sharers.count == 1)
        .accessibilityLabel(item.name)
        .accessibilityAddTraits(had ? .isSelected : [])
    }

    private func sharerLabel(_ sharers: [Person]) -> String {
        if sharers.count == bill.people.count { return "Everyone" }
        return sharers.map(\.name).formatted(.list(type: .and))
    }
}
