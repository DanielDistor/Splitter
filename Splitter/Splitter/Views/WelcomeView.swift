import SwiftUI

/// First-launch screen, in the spirit of the original 2024 welcome screen.
struct WelcomeView: View {
    let onStart: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Theme.heroGradient.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image("Logo")
                    .resizable()
                    .frame(width: 112, height: 112)
                    .clipShape(.rect(cornerRadius: 26))
                    .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.8, bounce: 0.35), value: appeared)

                VStack(spacing: 12) {
                    Text("Welcome to Splitter")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Manage your bills effortlessly, splitting costs among friends with precision.")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .fadeIn(appeared, delay: 0.3)

                VStack(alignment: .leading, spacing: 18) {
                    feature("doc.text.viewfinder", "Scan the receipt", "Items and tax fill themselves in.")
                    feature("person.2.fill", "Pick who had what", "Share a pizza, split a bottle of wine.")
                    feature("checkmark.seal.fill", "Fair to the penny", "Tax and tip follow what you ordered.")
                }
                .padding(22)
                .background(.white.opacity(0.12), in: .rect(cornerRadius: 24))
                .fadeIn(appeared, delay: 0.6)

                Spacer()

                Button(action: onStart) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(Theme.brandDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(.white, in: Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                }
                .fadeIn(appeared, delay: 0.9)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.bottom, 12)
        }
        .onAppear { appeared = true }
        .preferredColorScheme(.dark) // white status bar on the blue
    }

    private func feature(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.18), in: .rect(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}

private extension View {
    func fadeIn(_ visible: Bool, delay: Double) -> some View {
        opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 16)
            .animation(.easeOut(duration: 0.7).delay(delay), value: visible)
    }
}

#Preview {
    WelcomeView {}
}
