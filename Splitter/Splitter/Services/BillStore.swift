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
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            bills = try JSONDecoder().decode([Bill].self, from: data)
        } catch {
            // Never silently overwrite bills we couldn't read — set the file aside first.
            let stamp = Int(Date.now.timeIntervalSince1970)
            let backup = fileURL.deletingLastPathComponent().appending(path: "bills-unreadable-\(stamp).json")
            try? FileManager.default.moveItem(at: fileURL, to: backup)
            print("Couldn't read saved bills (\(error)); kept a copy at \(backup.lastPathComponent)")
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
