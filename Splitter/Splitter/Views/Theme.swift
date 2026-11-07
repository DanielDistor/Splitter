import SwiftUI

/// Splitter's look: the steel blue from the app icon, soft blue-gray backgrounds, rounded cards.
enum Theme {
    static let brand = Color(light: 0x225E82, dark: 0x5AA3D6)
    static let brandDeep = Color(hex: 0x163F5A)
    /// Solid blue for the big header cards and primary buttons.
    static let brandFill = Color(light: 0x225E82, dark: 0x1B4A68)

    static let background = Color(light: 0xEEF3F8, dark: 0x0B1620)
    static let card = Color(light: 0xFFFFFF, dark: 0x15232F)
    static let field = Color(light: 0xF2F6FA, dark: 0x1D2E3C)
    static let border = Color(light: 0xDCE5EE, dark: 0x22344A)

    /// Each person on a bill gets their own color, in the order they were added.
    static let personColors: [Color] = [
        Color(hex: 0x3C85B5), Color(hex: 0x2BA59A), Color(hex: 0xE8894A),
        Color(hex: 0xD9667F), Color(hex: 0x7C6CD6), Color(hex: 0x4FAF5B),
    ]

    static func color(for index: Int) -> Color {
        personColors[index % personColors.count]
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}

extension Font {
    /// Rounded numbers that grow with the iPhone's text size setting (capped so totals still fit).
    static func money(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        let scaled = UIFontMetrics.default.scaledValue(for: size)
        return .system(size: min(scaled, size * 1.6), weight: weight, design: .rounded)
    }
}

extension View {
    /// Flat card: solid fill and a hairline border, no drop shadow.
    func card(cornerRadius: CGFloat = 20) -> some View {
        background(Theme.card, in: .rect(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(Theme.border, lineWidth: 1))
    }
}

/// A white rounded card with a plain heading.
struct CardSection<Content: View>: View {
    let title: String
    var footer: String?
    @ViewBuilder let content: Content

    init(_ title: String, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
            content
            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .card()
    }
}

/// A colored circle with someone's initials.
struct Avatar: View {
    let name: String
    let color: Color
    var size: CGFloat = 36

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color, in: Circle())
            .accessibilityHidden(true)
    }

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap(\.first).map(String.init).joined()
        return letters.isEmpty ? "?" : letters.uppercased()
    }
}

/// Overlapping avatars, e.g. for everyone on a bill.
struct AvatarStack: View {
    let people: [Person]
    var size: CGFloat = 26
    var outline: Color = Theme.card
    var limit = 4

    var body: some View {
        HStack(spacing: -size * 0.3) {
            ForEach(Array(people.prefix(limit).enumerated()), id: \.element.id) { index, person in
                Avatar(name: person.name, color: Theme.color(for: index), size: size)
                    .overlay(Circle().stroke(outline, lineWidth: 2))
            }
            if people.count > limit {
                Text("+\(people.count - limit)")
                    .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                    .frame(width: size, height: size)
                    .background(Theme.field, in: Circle())
                    .overlay(Circle().stroke(outline, lineWidth: 2))
            }
        }
    }
}

/// A small rounded pill button, used for the tip choices and quick actions.
struct PillButtonStyle: ButtonStyle {
    var isSelected = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .foregroundStyle(isSelected ? Color.white : Theme.brand)
            .background(isSelected ? Theme.brandFill : Theme.brand.opacity(0.1), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

/// Something that was just deleted and can be put back.
struct UndoAction: Identifiable {
    let id = UUID()
    let message: String
    let undo: () -> Void
}

/// "Deleted Dana · Undo" bar that disappears after a few seconds.
struct UndoToast: View {
    let action: UndoAction
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(action.message)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button("Undo") {
                action.undo()
                dismiss()
            }
            .fontWeight(.semibold)
            .foregroundStyle(Color(light: 0x9CCBEA, dark: 0x9CCBEA))
        }
        .font(.subheadline)
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color(light: 0x1F2A33, dark: 0x2C3A47), in: .rect(cornerRadius: 16))
        .padding(.horizontal, 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .task(id: action.id) {
            try? await Task.sleep(for: .seconds(5))
            dismiss()
        }
    }
}
