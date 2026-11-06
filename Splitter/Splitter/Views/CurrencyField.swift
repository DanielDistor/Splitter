import SwiftUI

/// A money text field that stores whole cents.
struct CurrencyField: View {
    @Binding var cents: Int
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 2) {
            Text(Money.currencySymbol)
                .foregroundStyle(.secondary)
            TextField("0.00", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .focused($isFocused)
                .frame(minWidth: 70, maxWidth: 120)
        }
        .onAppear { text = display(cents) }
        .onChange(of: text) { _, newText in
            if isFocused { cents = Money.parseCents(newText) ?? 0 }
        }
        .onChange(of: cents) { _, newCents in
            if !isFocused { text = display(newCents) }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused { text = display(cents) }
        }
    }

    private func display(_ cents: Int) -> String {
        cents == 0 ? "" : Money.plain(cents)
    }
}
