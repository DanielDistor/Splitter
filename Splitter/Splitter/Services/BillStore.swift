import Foundation
import Observation

/// Keeps bills on the device as a JSON file. No accounts, no network.
@Observable
final class BillStore {
    var bills: [Bill] = [] {
        didSet { save() }
    }

    @ObservationIgnored private let fileURL: URL

    init(fileURL: URL = URL.documentsDirectory.appending(path: "bills.json")) {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([Bill].self, from: data) {
            bills = saved
        }
    }

    var sortedBills: [Bill] {
        bills.sorted { $0.date > $1.date }
    }

    func addBill() -> Bill {
        let bill = Bill(title: "")
        bills.append(bill)
        return bill
    }

    func delete(ids: [UUID]) {
        bills.removeAll { ids.contains($0.id) }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(bills)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Couldn't save bills: \(error)")
        }
    }
}
