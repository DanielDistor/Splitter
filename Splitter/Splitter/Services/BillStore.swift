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

    /// Bills whose title or any person's name contains `text`, newest first.
    func search(_ text: String) -> [Bill] {
        let query = text.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return sortedBills }
        return sortedBills.filter { bill in
            bill.title.localizedCaseInsensitiveContains(query)
                || bill.people.contains { $0.name.localizedCaseInsensitiveContains(query) }
        }
    }

    /// Groups bills by the month they happened in, newest month first.
    static func byMonth(_ bills: [Bill], calendar: Calendar = .current) -> [(month: Date, bills: [Bill])] {
        let groups = Dictionary(grouping: bills) { calendar.dateInterval(of: .month, for: $0.date)?.start ?? $0.date }
        return groups.keys.sorted(by: >).map { (month: $0, bills: groups[$0]!.sorted { $0.date > $1.date }) }
    }

    func addBill() -> Bill {
        let bill = Bill(title: "")
        bills.append(bill)
        return bill
    }

    /// The bills removed by the last delete, so the list can offer Undo.
    var recentlyDeleted: UndoAction?

    func delete(ids: [UUID]) {
        let removed = bills.filter { ids.contains($0.id) }
        guard !removed.isEmpty else { return }
        bills.removeAll { ids.contains($0.id) }
        let name = removed.count == 1 ? (removed[0].title.isEmpty ? "Untitled Bill" : removed[0].title) : "\(removed.count) bills"
        recentlyDeleted = UndoAction(message: "Deleted \(name)") { [weak self] in
            self?.bills.append(contentsOf: removed)
        }
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
