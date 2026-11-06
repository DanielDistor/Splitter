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
