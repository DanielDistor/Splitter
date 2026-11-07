import SwiftUI

/// Splitter's look: the steel blue from the app icon, soft blue-gray backgrounds, rounded cards.
enum Theme {
    static let brand = Color(light: 0x225E82, dark: 0x5AA3D6)
    static let brandBright = Color(hex: 0x3C85B5)
    static let brandDeep = Color(hex: 0x163F5A)

    static let heroGradient = LinearGradient(
        colors: [brandBright, Color(hex: 0x225E82), brandDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let background = Color(light: 0xEEF3F8, dark: 0x0B1620)
    static let card = Color(light: 0xFFFFFF, dark: 0x15232F)
    static let field = Color(light: 0xF2F6FA, dark: 0x1D2E3C)
    static let shadow = Color.black.opacity(0.06)

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
    static func money(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// A white rounded card with a small colored heading.
struct CardSection<Content: View>: View {
    let title: String
    let systemImage: String
    var footer: String?
    @ViewBuilder let content: Content

    init(_ title: String, systemImage: String, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.brand)
            content
            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.card, in: .rect(cornerRadius: 24))
        .shadow(color: Theme.shadow, radius: 16, y: 6)
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
            .background(color.gradient, in: Circle())
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
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .foregroundStyle(isSelected ? Color.white : Theme.brand)
            .background(isSelected ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.brand.opacity(0.1)), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}
