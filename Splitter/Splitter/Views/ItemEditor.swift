import SwiftUI

struct ItemEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var item: BillItem
    @FocusState private var nameFocused: Bool
    @State private var showSplitChoices = false
    let people: [Person]
    let onDelete: (() -> Void)?
    let onSplit: ((BillItem, Int) -> Void)?
    let onSave: (BillItem) -> Void

    init(item: BillItem, people: [Person], onDelete: (() -> Void)? = nil, onSplit: ((BillItem, Int) -> Void)? = nil,
         onSave: @escaping (BillItem) -> Void) {
        _item = State(initialValue: item)
        self.people = people
        self.onDelete = onDelete
        self.onSplit = onSplit
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
                        ForEach(Array(people.enumerated()), id: \.element.id) { index, person in
                            let isOn = item.sharedBy.contains(person.id)
                            Button {
                                withAnimation(.snappy(duration: 0.2)) { isSharing(person).wrappedValue.toggle() }
                            } label: {
                                HStack(spacing: 12) {
                                    Avatar(name: person.name, color: Theme.color(for: index), size: 34)
                                    Text(person.name.isEmpty ? "Unnamed" : person.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(isOn ? Theme.color(for: index) : Color.secondary.opacity(0.5))
                                }
                            }
                            .accessibilityLabel(person.name)
                            .accessibilityAddTraits(isOn ? .isSelected : [])
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

                if let onSplit, item.priceCents > 1 {
                    Section {
                        Button {
                            showSplitChoices = true
                        } label: {
                            Label("Split into Separate Items", systemImage: "square.split.2x1")
                        }
                        .confirmationDialog("Split \(item.name.isEmpty ? "this item" : item.name) into…", isPresented: $showSplitChoices, titleVisibility: .visible) {
                            ForEach(2...8, id: \.self) { count in
                                Button("\(count) items, \(Money.format(item.priceCents / count)) each") {
                                    onSplit(item, count)
                                    dismiss()
                                }
                            }
                        }
                    } footer: {
                        Text("For things like 3 tacos on one line, so each can go to a different person.")
                    }
                }

                if let onDelete {
                    Section {
                        Button("Delete Item", role: .destructive) {
                            onDelete()
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
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
        .presentationDetents(onDelete == nil ? [.medium, .large] : [.large])
        .presentationCornerRadius(28)
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
