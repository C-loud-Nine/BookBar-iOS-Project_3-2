import SwiftUI
import Firebase
import FirebaseAuth

class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.isAuthenticated = user != nil
            self?.isLoading = false
        }
    }
}
