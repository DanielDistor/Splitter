import SwiftUI
import FirebaseAuthUI
import FirebaseEmailAuthUI

struct FirebaseAuthView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var isSignedIn: Bool

    func makeUIViewController(context: Context) -> UINavigationController {
        let authUI = FUIAuth.defaultAuthUI()!
        authUI.delegate = context.coordinator
        let providers: [FUIAuthProvider] = [
            FUIEmailAuth()
        ]
        authUI.providers = providers
        return authUI.authViewController()
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, FUIAuthDelegate {
        var parent: FirebaseAuthView
        
        init(_ parent: FirebaseAuthView) {
            self.parent = parent
        }
        
        func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
            if let user = authDataResult?.user {
                print("User \(user.email ?? "unknown") logged in")
                parent.isSignedIn = true
                parent.presentationMode.wrappedValue.dismiss()
            } else if let error = error {
                print("Authentication error: \(error.localizedDescription)")
            }
        }
    }
}
