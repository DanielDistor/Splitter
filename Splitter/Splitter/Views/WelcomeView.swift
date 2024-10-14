import SwiftUI

struct WelcomeView: View {
    @Binding var isSignedIn: Bool
    @State private var fadeInOut = false
    @State private var isAttemptingToSignIn = false
    @State private var showSignInView = false
    @State private var showRegisterView = false

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue]),
                           startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Spacer()

                Text("Welcome to Splitter")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .opacity(fadeInOut ? 1 : 0)
                    .animation(Animation.easeIn(duration: 1.0).delay(0.5), value: fadeInOut)

                Text("Manage your bills effortlessly, splitting costs among participants with precision. Make sure to register then sign in.")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                    .padding()
                    .multilineTextAlignment(.center)
                    .opacity(fadeInOut ? 1 : 0)
                    .animation(Animation.easeIn(duration: 1.5).delay(0.5), value: fadeInOut)

                Spacer()

                Button("Register") {
                    showRegisterView = true
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .cornerRadius(10)
                .padding(.horizontal)
                .opacity(fadeInOut ? 1 : 0)
                .animation(Animation.easeIn(duration: 2.0).delay(0.5), value: fadeInOut)
                .sheet(isPresented: $showRegisterView) {
                    FirebaseAuthView(isSignedIn: $isSignedIn)
                }

                Button("Sign In") {
                    showSignInView = true
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
                .opacity(fadeInOut ? 1 : 0)
                .animation(Animation.easeIn(duration: 2.0).delay(0.5), value: fadeInOut)
                .sheet(isPresented: $showSignInView) {
                    SignInView(isSignedIn: $isSignedIn)
                }

                Spacer()
            }
        }
        .onAppear {
            fadeInOut = true
        }
    }
}
