import XCTest
@testable import Splitter

final class AllocateTests: XCTestCase {
    func testEvenSplitHandsLeftoverPenniesToFirstPeople() {
        XCTAssertEqual(Split.allocate(100, weights: [1, 1, 1]), [34, 33, 33])
    }

    func testProportionalSplitAlwaysSumsToTotal() {
        let result = Split.allocate(1_001, weights: [1_000, 2_000, 3_333])
        XCTAssertEqual(result.reduce(0, +), 1_001)
    }

    func testZeroWeightsFallBackToEvenSplit() {
        XCTAssertEqual(Split.allocate(10, weights: [0, 0]), [5, 5])
    }

    func testNoRecipientsGetsNothing() {
        XCTAssertEqual(Split.allocate(10, weights: []), [])
    }
}

final class SummaryTests: XCTestCase {
    private let alice = Person(name: "Alice")
    private let bob = Person(name: "Bob")
    private let cara = Person(name: "Cara")

    private func share(_ summary: BillSummary, _ person: Person) -> PersonShare {
        summary.shares.first { $0.person.id == person.id }!
    }

    /// The original app only counted each person's first dish.
    func testEveryItemAPersonOrderedIsCounted() {
        var bill = Bill(title: "Dinner", people: [alice, bob])
        bill.items = [
            BillItem(name: "Soup", priceCents: 1_000, sharedBy: [alice.id]),
            BillItem(name: "Salad", priceCents: 1_000, sharedBy: [alice.id]),
            BillItem(name: "Steak", priceCents: 4_000, sharedBy: [bob.id]),
        ]
        bill.tip = .percent(0)
        let summary = Split.summarize(bill)
        XCTAssertEqual(share(summary, alice).subtotalCents, 2_000)
        XCTAssertEqual(share(summary, bob).subtotalCents, 4_000)
    }

    /// The original app split tax and tip evenly; they should follow what you ordered.
    func testTaxAndTipAreProportionalToWhatYouOrdered() {
        var bill = Bill(title: "Dinner", people: [alice, bob])
        bill.items = [
            BillItem(name: "Pasta", priceCents: 2_000, sharedBy: [alice.id]),
            BillItem(name: "Steak", priceCents: 4_000, sharedBy: [bob.id]),
        ]
        bill.taxCents = 600
        bill.tip = .percent(20) // 20% of 60.00 = 12.00
        let summary = Split.summarize(bill)

        XCTAssertEqual(summary.tipCents, 1_200)
        XCTAssertEqual(share(summary, alice).taxCents, 200)
        XCTAssertEqual(share(summary, alice).tipCents, 400)
        XCTAssertEqual(share(summary, alice).totalCents, 2_600)
        XCTAssertEqual(share(summary, bob).totalCents, 5_200)
        XCTAssertEqual(summary.totalCents, 7_800)
    }

    func testSharedItemSplitsEvenlyAmongItsSharers() {
        var bill = Bill(title: "Pizza", people: [alice, bob, cara])
        bill.items = [BillItem(name: "Pizza", priceCents: 1_000, sharedBy: [alice.id, bob.id, cara.id])]
        bill.tip = .percent(0)
        let subtotals = Split.summarize(bill).shares.map(\.subtotalCents)
        XCTAssertEqual(subtotals, [334, 333, 333])
    }

    func testUnassignedItemIsSplitAmongEveryone() {
        var bill = Bill(title: "Drinks", people: [alice, bob])
        bill.items = [BillItem(name: "Pitcher", priceCents: 1_500)]
        bill.tip = .percent(0)
        let subtotals = Split.summarize(bill).shares.map(\.subtotalCents)
        XCTAssertEqual(subtotals, [750, 750])
    }

    func testFixedTipAmount() {
        var bill = Bill(title: "Lunch", people: [alice, bob])
        bill.items = [BillItem(name: "Tacos", priceCents: 3_000)]
        bill.tip = .amount(cents: 500)
        let summary = Split.summarize(bill)
        XCTAssertEqual(summary.tipCents, 500)
        XCTAssertEqual(summary.totalCents, 3_500)
    }

    func testPeopleTotalsAlwaysAddUpToBillTotal() {
        var bill = Bill(title: "Awkward numbers", people: [alice, bob, cara])
        bill.items = [
            BillItem(name: "A", priceCents: 1_337, sharedBy: [alice.id, bob.id]),
            BillItem(name: "B", priceCents: 999, sharedBy: [cara.id]),
            BillItem(name: "C", priceCents: 2_501),
        ]
        bill.taxCents = 427
        bill.tip = .percent(18)
        let summary = Split.summarize(bill)
        XCTAssertEqual(summary.shares.map(\.totalCents).reduce(0, +), summary.totalCents)
    }

    func testItemSharedOnlyByRemovedPeopleFallsBackToEveryone() {
        let ghost = UUID()
        var bill = Bill(title: "Dinner", people: [alice, bob])
        bill.items = [BillItem(name: "Wine", priceCents: 2_000, sharedBy: [ghost])]
        bill.tip = .percent(0)
        XCTAssertEqual(Split.summarize(bill).shares.map(\.subtotalCents), [1_000, 1_000])
    }

    func testBillWithNoPeopleStillTotals() {
        var bill = Bill(title: "Solo")
        bill.items = [BillItem(name: "Coffee", priceCents: 500)]
        bill.taxCents = 50
        bill.tip = .percent(20)
        let summary = Split.summarize(bill)
        XCTAssertTrue(summary.shares.isEmpty)
        XCTAssertEqual(summary.totalCents, 650)
    }
}

final class MoneyTests: XCTestCase {
    func testParsesTypedAmounts() {
        XCTAssertEqual(Money.parseCents("12.5"), 1_250)
        XCTAssertEqual(Money.parseCents("0.07"), 7)
        XCTAssertEqual(Money.parseCents("$19.99"), 1_999)
        XCTAssertNil(Money.parseCents(""))
        XCTAssertNil(Money.parseCents("abc"))
    }
}

final class BillStoreTests: XCTestCase {
    func testBillsSurviveRelaunch() {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: url) }

        let store = BillStore(fileURL: url)
        var bill = Bill(title: "Saved", people: [Person(name: "Alice")])
        bill.items = [BillItem(name: "Soup", priceCents: 800)]
        store.bills = [bill]

        let reopened = BillStore(fileURL: url)
        XCTAssertEqual(reopened.bills, [bill])
    }
}

final class EditingWhoHadWhatTests: XCTestCase {
    private let alice = Person(name: "Alice")
    private let bob = Person(name: "Bob")
    private let cara = Person(name: "Cara")

    func testNewPersonJoinsEverythingSharedByEveryone() {
        var bill = Bill(title: "Dinner", people: [alice, bob, cara])
        bill.items = [BillItem(name: "Wine", priceCents: 3_000)]
        bill.tip = .percent(0)
        let dana = Person(name: "Dana")
        bill.people.append(dana) // "it was 4 people after all"
        XCTAssertEqual(Split.summarize(bill).shares.map(\.subtotalCents), [750, 750, 750, 750])
    }

    func testTakingSomeoneOffAnEveryoneItem() {
        var bill = Bill(title: "Dinner", people: [alice, bob, cara])
        bill.items = [BillItem(name: "Wine", priceCents: 3_000)]
        XCTAssertTrue(bill.setPerson(cara.id, had: false, itemID: bill.items[0].id))
        XCTAssertEqual(bill.sharers(of: bill.items[0]).map(\.name), ["Alice", "Bob"])
    }

    func testAddingEveryoneBackMeansEveryone() {
        var bill = Bill(title: "Dinner", people: [alice, bob])
        bill.items = [BillItem(name: "Soup", priceCents: 800, sharedBy: [alice.id])]
        bill.setPerson(bob.id, had: true, itemID: bill.items[0].id)
        XCTAssertEqual(bill.items[0].sharedBy, [], "All selected should become Everyone")
    }

    func testCannotLeaveAnItemWithNobody() {
        var bill = Bill(title: "Dinner", people: [alice, bob])
        bill.items = [BillItem(name: "Soup", priceCents: 800, sharedBy: [alice.id])]
        XCTAssertFalse(bill.setPerson(alice.id, had: false, itemID: bill.items[0].id))
        XCTAssertEqual(bill.items[0].sharedBy, [alice.id])
    }

    func testRemovingAPersonDropsThemFromItems() {
        var bill = Bill(title: "Dinner", people: [alice, bob, cara])
        bill.items = [BillItem(name: "Pizza", priceCents: 1_000, sharedBy: [alice.id, cara.id])]
        bill.removePerson(cara.id)
        XCTAssertEqual(bill.sharers(of: bill.items[0]).map(\.name), ["Alice"])
    }
}

final class BillStoreSafetyTests: XCTestCase {
    /// If saved bills can't be read (e.g. after a format change), keep a backup instead of overwriting them.
    func testUnreadableFileIsBackedUpNotOverwritten() throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appending(path: "bills.json")
        try Data("not json".utf8).write(to: url)

        let store = BillStore(fileURL: url)
        store.bills = [Bill(title: "New")]

        let backups = try FileManager.default.contentsOfDirectory(atPath: dir.path).filter { $0.hasPrefix("bills-unreadable-") }
        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(try String(contentsOf: dir.appending(path: backups[0]), encoding: .utf8), "not json")
    }
}

final class UndoDeleteTests: XCTestCase {
    func testDeletedBillCanBeBroughtBack() {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = BillStore(fileURL: url)
        let bill = Bill(title: "Tacos")
        store.bills = [bill]

        store.delete(ids: [bill.id])
        XCTAssertTrue(store.bills.isEmpty)
        XCTAssertEqual(store.recentlyDeleted?.message, "Deleted Tacos")

        store.recentlyDeleted?.undo()
        XCTAssertEqual(store.bills, [bill])
    }
}

final class SettleUpTests: XCTestCase {
    private let alice = Person(name: "Alice")
    private let bob = Person(name: "Bob")
    private let cara = Person(name: "Cara")

    private func dinner() -> Bill {
        var bill = Bill(title: "Dinner", people: [alice, bob, cara])
        bill.items = [BillItem(name: "Pizza", priceCents: 3_000)]
        bill.tip = .percent(0)
        return bill
    }

    func testPayerWaitsOnEveryoneElse() {
        var bill = dinner()
        bill.paidBy = alice.id
        XCTAssertFalse(bill.stillOwes(alice.id))
        XCTAssertEqual(bill.outstandingCents, 2_000)
        bill.settled.insert(bob.id)
        XCTAssertEqual(bill.outstandingCents, 1_000)
        bill.settled.insert(cara.id)
        XCTAssertTrue(bill.isFullySettled)
    }

    func testNoPayerMeansNothingOutstanding() {
        XCTAssertEqual(dinner().outstandingCents, 0)
        XCTAssertFalse(dinner().isFullySettled)
    }

    func testRemovingThePayerClearsIt() {
        var bill = dinner()
        bill.paidBy = alice.id
        bill.removePerson(alice.id)
        XCTAssertNil(bill.paidBy)
    }

    /// Bills saved before "who paid" existed must still open.
    func testOldSavedBillsStillLoad() throws {
        let old = #"[{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","title":"Old","date":700000000,"people":[],"items":[],"taxCents":100,"tip":{"percent":{"_0":18}}}]"#
        let bills = try JSONDecoder().decode([Bill].self, from: Data(old.utf8))
        XCTAssertEqual(bills.first?.title, "Old")
        XCTAssertNil(bills.first?.paidBy)
        XCTAssertEqual(bills.first?.settled, [])
    }

    func testVenmoLink() {
        let url = Money.venmoRequestURL(cents: 2_980, note: "Birthday Dinner")
        XCTAssertEqual(url.absoluteString, "venmo://paycharge?txn=charge&amount=29.80&note=Birthday%20Dinner")
    }
}

final class SearchAndGroupingTests: XCTestCase {
    func testSearchMatchesTitlesAndPeople() {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = BillStore(fileURL: url)
        store.bills = [
            Bill(title: "Taco Night", people: [Person(name: "Sam")]),
            Bill(title: "Brunch", people: [Person(name: "Alice")]),
        ]
        XCTAssertEqual(store.search("taco").map(\.title), ["Taco Night"])
        XCTAssertEqual(store.search("ALICE").map(\.title), ["Brunch"])
        XCTAssertEqual(store.search("").count, 2)
    }

    func testGroupsByMonthNewestFirst() {
        let calendar = Calendar(identifier: .gregorian)
        let nov = calendar.date(from: DateComponents(year: 2026, month: 11, day: 5))!
        let nov2 = calendar.date(from: DateComponents(year: 2026, month: 11, day: 20))!
        let oct = calendar.date(from: DateComponents(year: 2026, month: 10, day: 31))!
        let bills = [Bill(title: "A", date: oct), Bill(title: "B", date: nov), Bill(title: "C", date: nov2)]
        let groups = BillStore.byMonth(bills, calendar: calendar)
        XCTAssertEqual(groups.map { $0.bills.map(\.title) }, [["C", "B"], ["A"]])
    }
}
