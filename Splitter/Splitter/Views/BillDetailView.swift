import PhotosUI
import SwiftUI

struct BillDetailView: View {
    @Environment(BillStore.self) private var store
    let billID: UUID

    var body: some View {
        @Bindable var store = store
        if let index = store.bills.firstIndex(where: { $0.id == billID }) {
            BillEditor(bill: $store.bills[index])
        } else {
            ContentUnavailableView("Bill Deleted", systemImage: "trash")
        }
    }
}

private struct BillEditor: View {
    @Binding var bill: Bill
    @State private var newPersonName = ""
    @State private var editingItem: BillItem?
    @FocusState private var addPersonFocused: Bool

    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var isScanning = false
    @State private var scanned: ScannedReceipt?
    @State private var scanError: String?

    private static let tipPresets = [0, 15, 18, 20]
    private static let customTip = -1

    var body: some View {
        let summary = Split.summarize(bill)
        Form {
            Section {
                TextField("What's this bill for?", text: $bill.title)
                    .font(.headline)
                DatePicker("Date", selection: $bill.date, displayedComponents: .date)
            }

            peopleSection
            itemsSection
            taxAndTipSection(summary)
            totalsSection(summary)
            if !summary.shares.isEmpty {
                whoOwesSection(summary)
            }
        }
        .navigationTitle(bill.title.isEmpty ? "New Bill" : bill.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ShareLink(item: shareText(summary)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .disabled(summary.shares.isEmpty)
        }
        .sheet(item: $editingItem) { item in
            ItemEditor(item: item, people: bill.people) { saved in
                if let index = bill.items.firstIndex(where: { $0.id == saved.id }) {
                    bill.items[index] = saved
                } else {
                    bill.items.append(saved)
                }
            }
        }
        .sheet(item: $scanned) { receipt in
            ReceiptReviewView(receipt: receipt, onAdd: addScanned)
        }
        .fullScreenCover(isPresented: $showCamera) {
            DocumentCamera { image in
                showCamera = false
                scan(image)
            } onCancel: {
                showCamera = false
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $pickedPhoto, matching: .images)
        .onChange(of: pickedPhoto) { _, item in
            guard let item else { return }
            pickedPhoto = nil
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    scan(image)
                } else {
                    scanError = "That photo couldn't be opened."
                }
            }
        }
        .overlay {
            if isScanning {
                ProgressView("Reading receipt…")
                    .padding(24)
                    .background(.regularMaterial, in: .rect(cornerRadius: 16))
            }
        }
        .alert("Couldn't Scan", isPresented: Binding { scanError != nil } set: { if !$0 { scanError = nil } }) {
            Button("OK") {}
        } message: {
            Text(scanError ?? "")
        }
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-scanDemoReceipt"), scanned == nil {
                scan(DemoData.receiptImage())
            }
            #endif
        }
    }

    // MARK: Sections

    private var peopleSection: some View {
        Section {
            ForEach($bill.people) { $person in
                TextField("Name", text: $person.name)
            }
            .onDelete { bill.removePeople(at: $0) }

            HStack {
                TextField("Add a person", text: $newPersonName)
                    .focused($addPersonFocused)
                    .submitLabel(.next)
                    .onSubmit(addPerson)
                Button("Add", systemImage: "plus.circle.fill", action: addPerson)
                    .labelStyle(.iconOnly)
                    .disabled(newPersonName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } header: {
            Text("People")
        }
    }

    private var itemsSection: some View {
        Section {
            ForEach(bill.items) { item in
                Button {
                    editingItem = item
                } label: {
                    ItemRow(item: item, people: bill.people)
                }
                .tint(.primary)
            }
            .onDelete { bill.items.remove(atOffsets: $0) }

            Button("Add Item", systemImage: "plus") {
                editingItem = BillItem(name: "", priceCents: 0)
            }
            Menu {
                if DocumentCamera.isAvailable {
                    Button("Take Photo", systemImage: "camera") { showCamera = true }
                }
                Button("Choose from Photos", systemImage: "photo.on.rectangle") { showPhotoPicker = true }
            } label: {
                Label("Scan Receipt", systemImage: "doc.text.viewfinder")
            }
            .disabled(isScanning)
        } header: {
            Text("Items")
        } footer: {
            if !bill.items.isEmpty {
                Text("Tap an item to change who shared it.")
            }
        }
    }

    private func taxAndTipSection(_ summary: BillSummary) -> some View {
        Section("Tax & Tip") {
            LabeledContent("Tax") {
                CurrencyField(cents: $bill.taxCents)
            }
            Picker("Tip", selection: tipChoice(summary)) {
                ForEach(Self.tipPresets, id: \.self) { Text("\($0)%").tag($0) }
                Text("Custom").tag(Self.customTip)
            }
            .pickerStyle(.segmented)

            if case .amount = bill.tip {
                LabeledContent("Tip Amount") {
                    CurrencyField(cents: customTipCents)
                }
            }
        }
    }

    private func totalsSection(_ summary: BillSummary) -> some View {
        Section {
            LabeledContent("Subtotal", value: Money.format(summary.subtotalCents))
            LabeledContent("Tax", value: Money.format(summary.taxCents))
            LabeledContent(tipLabel, value: Money.format(summary.tipCents))
            LabeledContent {
                Text(Money.format(summary.totalCents)).bold()
            } label: {
                Text("Total").bold()
            }
        }
        .monospacedDigit()
    }

    private func whoOwesSection(_ summary: BillSummary) -> some View {
        Section {
            ForEach(summary.shares) { share in
                DisclosureGroup {
                    ForEach(Array(share.items.enumerated()), id: \.offset) { _, item in
                        LabeledContent(item.splitCount > 1 ? "\(item.name) (÷\(item.splitCount))" : item.name,
                                       value: Money.format(item.cents))
                    }
                    LabeledContent("Tax", value: Money.format(share.taxCents))
                    LabeledContent("Tip", value: Money.format(share.tipCents))
                } label: {
                    LabeledContent {
                        Text(Money.format(share.totalCents))
                            .font(.headline)
                            .foregroundStyle(.tint)
                    } label: {
                        Text(share.person.name.isEmpty ? "Unnamed" : share.person.name)
                            .font(.headline)
                    }
                }
                .font(.subheadline)
            }
        } header: {
            Text("Who Owes What")
        } footer: {
            Text("Tax and tip are split based on how much each person ordered.")
        }
        .monospacedDigit()
    }

    // MARK: Helpers

    private var tipLabel: String {
        if case .percent(let percent) = bill.tip {
            return "Tip (\(percent.formatted())%)"
        }
        return "Tip"
    }

    private func tipChoice(_ summary: BillSummary) -> Binding<Int> {
        Binding {
            if case .percent(let percent) = bill.tip, Self.tipPresets.contains(Int(percent)), percent == percent.rounded() {
                return Int(percent)
            }
            return Self.customTip
        } set: { choice in
            bill.tip = choice == Self.customTip ? .amount(cents: summary.tipCents) : .percent(Double(choice))
        }
    }

    private var customTipCents: Binding<Int> {
        Binding {
            if case .amount(let cents) = bill.tip { return cents }
            return 0
        } set: {
            bill.tip = .amount(cents: $0)
        }
    }

    private func scan(_ image: UIImage) {
        isScanning = true
        Task {
            defer { isScanning = false }
            do {
                scanned = try await ReceiptScanner.scan(image)
            } catch {
                scanError = error.localizedDescription
            }
        }
    }

    private func addScanned(_ items: [ScannedItem], taxCents: Int?, tipCents: Int?) {
        bill.items += items.map { BillItem(name: $0.name, priceCents: $0.priceCents) }
        if let taxCents { bill.taxCents = taxCents }
        if let tipCents { bill.tip = .amount(cents: tipCents) }
    }

    private func addPerson() {
        let name = newPersonName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        bill.people.append(Person(name: name))
        newPersonName = ""
        addPersonFocused = true
    }

    private func shareText(_ summary: BillSummary) -> String {
        var lines = ["\(bill.title.isEmpty ? "Our bill" : bill.title) — \(bill.date.formatted(date: .abbreviated, time: .omitted))"]
        lines += summary.shares.map { "\($0.person.name): \(Money.format($0.totalCents))" }
        lines.append("Total: \(Money.format(summary.totalCents))")
        return lines.joined(separator: "\n")
    }
}

private struct ItemRow: View {
    let item: BillItem
    let people: [Person]

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name.isEmpty ? "Unnamed item" : item.name)
                Text(sharedByLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(Money.format(item.priceCents))
                .monospacedDigit()
        }
    }

    private var sharedByLabel: String {
        let names = people.filter { item.sharedBy.contains($0.id) }.map(\.name)
        if names.isEmpty || names.count == people.count { return "Everyone" }
        return names.formatted(.list(type: .and))
    }
}

#if DEBUG
#Preview {
    let store = BillStore(fileURL: .temporaryDirectory.appending(path: "preview.json"))
    store.bills = DemoData.bills
    return NavigationStack {
        BillDetailView(billID: store.bills[0].id)
    }
    .environment(store)
}
#endif
