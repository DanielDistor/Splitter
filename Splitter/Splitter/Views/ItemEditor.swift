import SwiftUI

struct ItemEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var item: BillItem
    @FocusState private var nameFocused: Bool
    let people: [Person]
    let onSave: (BillItem) -> Void

    init(item: BillItem, people: [Person], onSave: @escaping (BillItem) -> Void) {
        _item = State(initialValue: item)
        self.people = people
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item name", text: $item.name)
                        .focused($nameFocused)
                        .onAppear { nameFocused = item.name.isEmpty }
                    LabeledContent("Price") {
                        CurrencyField(cents: $item.priceCents)
                    }
                }

                Section {
                    if people.isEmpty {
                        Text("Add people to the bill to choose who shared this.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(people) { person in
                            Toggle(person.name.isEmpty ? "Unnamed" : person.name, isOn: isSharing(person))
                        }
                    }
                } header: {
                    HStack {
                        Text("Who had this?")
                        Spacer()
                        if !item.sharedBy.isEmpty {
                            Button("Everyone") { item.sharedBy = [] }
                                .font(.caption)
                                .textCase(nil)
                        }
                    }
                } footer: {
                    Text(splitDescription)
                }
            }
            .navigationTitle(item.name.isEmpty ? "Item" : item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(item)
                        dismiss()
                    }
                    .disabled(item.name.trimmingCharacters(in: .whitespaces).isEmpty && item.priceCents == 0)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var splitDescription: String {
        let count = item.sharedBy.isEmpty ? people.count : item.sharedBy.count
        guard count > 0, item.priceCents > 0 else { return "Nobody selected means everyone splits it." }
        let each = Money.format(item.priceCents / count)
        let who = item.sharedBy.isEmpty ? "Everyone splits it" : "Split between \(count)"
        return count == 1 ? "One person pays the full \(Money.format(item.priceCents))." : "\(who): about \(each) each."
    }

    private func isSharing(_ person: Person) -> Binding<Bool> {
        Binding {
            item.sharedBy.contains(person.id)
        } set: { isOn in
            if isOn { item.sharedBy.insert(person.id) } else { item.sharedBy.remove(person.id) }
        }
    }
}
