import SwiftUI

/// Shows what the scanner found so you can untick mistakes before adding to the bill.
struct ReceiptReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var receipt: ScannedReceipt
    @State private var useTax = true
    @State private var useTip = true
    let onAdd: (_ items: [ScannedItem], _ taxCents: Int?, _ tipCents: Int?) -> Void

    init(receipt: ScannedReceipt, onAdd: @escaping ([ScannedItem], Int?, Int?) -> Void) {
        _receipt = State(initialValue: receipt)
        self.onAdd = onAdd
    }

    private var chosen: [ScannedItem] { receipt.items.filter(\.include) }

    var body: some View {
        NavigationStack {
            Form {
                if receipt.items.isEmpty {
                    ContentUnavailableView(
                        "No Prices Found",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Try again with the receipt flat, well lit, and filling the photo.")
                    )
                } else {
                    Section {
                        ForEach($receipt.items) { $item in
                            Toggle(isOn: $item.include) {
                                LabeledContent(item.name, value: Money.format(item.priceCents))
                            }
                            .toggleStyle(CheckboxStyle())
                        }
                    } header: {
                        Text("Items Found")
                    } footer: {
                        if !receipt.itemsMatchSubtotal, let subtotal = receipt.subtotalCents {
                            Label("These add up to \(Money.format(receipt.itemsSumCents)), but the receipt says \(Money.format(subtotal)). Check for a missed or misread line — you can fix items after adding them.",
                                  systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                        } else if receipt.subtotalCents != nil {
                            Label("Matches the receipt subtotal.", systemImage: "checkmark.circle")
                                .foregroundStyle(.green)
                        }
                    }

                    if receipt.taxCents != nil || receipt.tipCents != nil {
                        Section("Also Found") {
                            if let tax = receipt.taxCents {
                                Toggle("Use tax of \(Money.format(tax))", isOn: $useTax)
                            }
                            if let tip = receipt.tipCents {
                                Toggle("Use tip of \(Money.format(tip))", isOn: $useTip)
                            }
                        }
                    }
                }
            }
            .monospacedDigit()
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Scanned Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(chosen.count == 1 ? "Add 1 Item" : "Add \(chosen.count) Items") {
                        onAdd(chosen, useTax ? receipt.taxCents : nil, useTip ? receipt.tipCents : nil)
                        dismiss()
                    }
                    .disabled(chosen.isEmpty)
                }
            }
        }
    }
}

private struct CheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(configuration.isOn ? Color.accentColor : Color.secondary)
                    .imageScale(.large)
                configuration.label
                    .opacity(configuration.isOn ? 1 : 0.4)
            }
        }
        .tint(.primary)
    }
}
