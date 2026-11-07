<p align="center">
  <img src="docs/logo.png" width="96" alt="Splitter app icon">
</p>

<h1 align="center">Splitter</h1>

<p align="center">
  Scan the receipt, tap who had what, and Splitter figures out what everyone owes down to the penny, tax and tip included.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17.2%2B-225E82" alt="iOS 17.2+">
  <img src="https://img.shields.io/badge/SwiftUI-native-225E82" alt="SwiftUI">
  <img src="https://img.shields.io/badge/accounts-none-225E82" alt="No accounts">
  <img src="https://img.shields.io/badge/data-stays%20on%20your%20phone-225E82" alt="Data stays on your phone">
</p>

---

## First launch

The first time you open Splitter you get a quick welcome that shows what the app does, and you can pull it back up anytime with the ⓘ button on the home screen.

<p align="center">
  <img src="docs/screenshots/welcome.png" width="300" alt="Welcome to Splitter: scan the receipt, pick who had what, fair to the penny">
</p>

## Screenshots

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/home.png" width="240" alt="Home screen"><br><sub><b>Your bills</b><br>Everything you've split, grouped by month</sub></td>
    <td align="center"><img src="docs/screenshots/bill.png" width="240" alt="A bill"><br><sub><b>A bill</b><br>Who owes what, right at the top</sub></td>
    <td align="center"><img src="docs/screenshots/settle.png" width="240" alt="Who paid and settling up"><br><sub><b>Settle up</b><br>Who paid and who's paid them back</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/person.png" width="240" alt="One person's breakdown"><br><sub><b>One person</b><br>Their breakdown and a Venmo request</sub></td>
    <td align="center"><img src="docs/screenshots/scan.png" width="240" alt="Scanned receipt review"><br><sub><b>Scan a receipt</b><br>Check what it read before adding</sub></td>
    <td align="center"><img src="docs/screenshots/home-dark.png" width="240" alt="Dark mode"><br><sub><b>Dark mode</b></sub></td>
  </tr>
</table>

## What it does

**Scan the receipt** with your camera or pick a photo, and Splitter reads it right on your phone using Apple's Vision, filling in the items, tax and tip and checking them against the receipt's subtotal so you know nothing got missed. A line like "2 Iced Tea" or "Tacos x3" turns into separate items so each one can go to a different person.

**Tap who had what** by tapping people's initials under each item, whether it's a pizza two people shared or a bottle of wine for the whole table, and anyone you add later automatically joins the items everyone shared.

**It's fair to the penny** because tax and tip get split based on how much each person actually ordered instead of evenly, and all the math is done in whole cents so everyone's shares always add up to the exact total.

**Settle up** by marking who put the bill on their card, then everyone else shows up as owing them and you tick people off as they pay you back, while the home screen keeps track of which bills you're still waiting on.

**Get paid back** with a Venmo request that opens with the amount and bill name already filled in, a reminder text that writes itself, or one tap to share the whole split with the group chat.

**Edit anything** from adding a fourth person you forgot about to splitting one line into a few items or changing the tip, and every total updates as you go, with an Undo button in case you delete something by accident.

**Your bills stay private** since there are no accounts, servers or tracking, and everything is saved on your phone and never leaves it.

## How the split works

Take the Birthday Dinner from the screenshots, where Alice and Bob shared an $18 pizza, Cara had a $34 ribeye, Alice also had a $12 salad, and the whole table shared a $42 bottle of wine, with $10.16 in tax and a 20% tip.

| | Food | Share of tax | Share of tip | **Owes** |
|---|---:|---:|---:|---:|
| Alice | $9 + $12 + $14 = $35.00 | $3.36 | $7.00 | **$45.36** |
| Bob | $9 + $14 = $23.00 | $2.20 | $4.60 | **$29.80** |
| Cara | $34 + $14 = $48.00 | $4.60 | $9.60 | **$62.20** |
| **Total** | $106.00 | $10.16 | $21.20 | **$137.36** |

Tax and tip follow how much food each person had, so Cara ends up covering the biggest share since she ordered the most, and any leftover pennies from rounding go to whoever was closest to the next cent (the [largest remainder method](https://en.wikipedia.org/wiki/Largest_remainder_method)) so the shares always land exactly on the total.

## Build & run

All you need is a Mac with Xcode 16 or newer, and the app runs on iOS 17.2 and up. Clone the repo, open `Splitter/Splitter.xcodeproj`, pick a simulator or your iPhone at the top of the window and hit **Run** (⌘R). If you're running it on a real iPhone, go to the **Splitter** target under **Signing & Capabilities** and choose your team first. There's nothing else to install or set up, so no packages, API keys or backend.

> **Tip:** the simulator doesn't have a camera, so to try scanning there just drag a receipt photo onto the simulator window and use **Scan Receipt → Choose from Photos**.

### Debug launch arguments

You can add these under **Product → Scheme → Edit Scheme → Run → Arguments** in debug builds.

| Argument | What it does |
|---|---|
| `-demo` | Starts with sample bills kept in a temporary file, so your real data isn't touched |
| `-skipWelcome` | Goes straight to the home screen |
| `-openBill` | Opens the newest bill on launch |
| `-scanDemoReceipt` | Scans a built-in sample receipt when a bill opens |

## Tests

```sh
cd Splitter
xcodebuild test -project Splitter.xcodeproj -scheme Splitter \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

There are 45 tests in total. The 39 unit tests cover the split math and rounding, reading receipts (including pulling text off a real rendered receipt image), quantities, editing who had what, settling up, search, and saving and loading, including making sure bills saved by older versions still open. The 6 UI tests drive the actual app the way a person would, creating a bill, scanning a receipt, adding a fourth person to an existing bill, undoing a delete and settling up.

## Project structure

```
Splitter/
├── Splitter/
│   ├── Setup/        App entry point
│   ├── Models/       Bill, Split (the math), Money, ReceiptParser, DemoData
│   ├── Services/     BillStore (saves bills on the device), ReceiptScanner (Vision)
│   ├── Views/        Screens and the Theme (colors, cards, avatars)
│   └── PrivacyInfo.xcprivacy
├── SplitterTests/    Unit tests
└── SplitterUITests/  UI tests
```

## History

Splitter started in spring 2024 as a class project that used Firebase for sign-in and storage and had a recipe tab powered by TheMealDB, and in 2026 it got rebuilt from the ground up as a focused, offline bill splitter. The original is still here exactly as it was, under the [`v1-original`](https://github.com/DanielDistor/Splitter/tree/v1-original) tag and the [`original-2024`](https://github.com/DanielDistor/Splitter/tree/original-2024) branch, along with the original project write-up in [`docs/original-2024/`](docs/original-2024/aboutme.md).

---

<p align="center"><sub>Made by Daniel Distor</sub></p>
