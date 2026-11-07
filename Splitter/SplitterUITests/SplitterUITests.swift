import XCTest

final class SplitterUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Creates a bill from scratch the way a person would and checks the split.
    func testSplittingANewBill() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-skipWelcome"]
        app.launch()

        app.buttons["New Bill"].tap()
        let title = app.textFields["What's this bill for?"]
        title.tap()
        title.typeText("Tacos")

        let addPerson = app.textFields["Add a person"]
        addPerson.tap()
        addPerson.typeText("Dani\n")
        addPerson.typeText("Sam\n")

        app.buttons["Add Item"].tap()
        let itemName = app.textFields["Item name"]
        XCTAssertTrue(itemName.waitForExistence(timeout: 3))
        itemName.typeText("Taco Platter")
        app.textFields["Price"].tap()
        app.textFields["Price"].typeText("30")
        app.buttons["Save"].tap()

        app.buttons["0%"].tap()
        app.swipeUp()

        XCTAssertTrue(app.anyElement(containing: "$30.00").exists)
        XCTAssertTrue(app.buttons["Dani, $15.00"].waitForExistence(timeout: 2), "Each person should owe half")
        snapshot(app, "4-new-bill")
    }

    func testDemoBillBreakdown() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-skipWelcome", "-openBill"]
        app.launch()
        app.swipeUp()
        snapshot(app, "5-totals")
        app.swipeUp()
        let alice = app.buttons["Alice, $45.36"]
        XCTAssertTrue(alice.waitForExistence(timeout: 2), "Alice owes her food + proportional tax and tip")
        if !alice.isHittable { app.swipeUp() }
        alice.tap()
        XCTAssertTrue(app.staticTexts["Margherita Pizza (÷2)"].waitForExistence(timeout: 2))
        snapshot(app, "6-who-owes")
    }

    /// The simulator has no camera, so `-scanDemoReceipt` feeds the scanner a rendered sample receipt.
    func testScanningAReceiptFillsTheBill() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-skipWelcome", "-scanDemoReceipt"]
        app.launch()
        app.buttons["New Bill"].tap()

        XCTAssertTrue(app.navigationBars["Scanned Receipt"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Matches the receipt subtotal."].exists)
        snapshot(app, "7-scan-review")

        app.buttons["Add 4 Items"].tap()
        XCTAssertTrue(app.anyElement(containing: "Ribeye").waitForExistence(timeout: 3))
        app.swipeUp()
        snapshot(app, "8-scan-added")
        XCTAssertTrue(app.anyElement(containing: "$106.00").exists, "Subtotal from the scanned items")
        XCTAssertTrue(app.anyElement(containing: "$10.16").exists, "Tax picked up from the receipt")
    }

    /// "Maybe it was 4 people after all": add someone to an existing bill and change what they had.
    func testAddingAFourthPersonToAnExistingBill() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-skipWelcome", "-openBill"]
        app.launch()

        let addPerson = app.buttons["Add Person"]
        for _ in 0..<4 where !addPerson.isHittable { app.swipeUp() }
        addPerson.tap()
        app.alerts.textFields["Name"].typeText("Dana")
        app.alerts.buttons["Add"].tap()

        // Dana automatically shares the wine (marked Everyone): $42 / 4 = $10.50 plus tax and tip.
        let dana = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Dana, $'")).firstMatch
        XCTAssertTrue(dana.waitForExistence(timeout: 3))
        XCTAssertEqual(dana.label, "Dana, $13.61")
        snapshot(app, "9-four-people")

        // Give Dana a slice of the pizza too.
        dana.tap()
        let edit = app.buttons["Edit what Dana had"]
        XCTAssertTrue(edit.waitForExistence(timeout: 2))
        for _ in 0..<3 where !edit.isHittable || edit.frame.maxY > app.frame.maxY - 60 { app.swipeUp() }
        edit.tap()
        app.buttons["Margherita Pizza"].tap()
        snapshot(app, "10-person-editor")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label == 'Dana, $21.38'")).firstMatch.waitForExistence(timeout: 3))
    }

    func testDeleteThenUndoAndSplitAnItem() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-skipWelcome", "-openBill"]
        app.launch()

        let ribeye = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Ribeye'")).firstMatch
        ribeye.tap()
        app.buttons["Delete Item"].tap()
        XCTAssertFalse(ribeye.waitForExistence(timeout: 1))
        let undo = app.buttons["Undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 2))
        snapshot(app, "11-undo")
        undo.tap()
        XCTAssertTrue(ribeye.waitForExistence(timeout: 2), "Undo brings the item back")

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Caesar Salad'")).firstMatch.tap()
        app.buttons["Split into Separate Items"].tap()
        app.buttons["2 items, $6.00 each"].tap()
        let salads = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Caesar Salad'"))
        XCTAssertTrue(salads.element(boundBy: 1).waitForExistence(timeout: 2))
        XCTAssertEqual(salads.count, 2)
    }

    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let shot = app.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appending(path: "\(name).png"))
        }
    }
}

private extension XCUIApplication {
    func anyElement(containing text: String) -> XCUIElement {
        descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text)).firstMatch
    }
}
