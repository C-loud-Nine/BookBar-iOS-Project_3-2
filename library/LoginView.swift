import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isAuthenticated = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Title
                Text("Welcome Back!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.top, 40)

                // Icon
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)

                // Email Field
                TextFieldWithIcon(icon: "envelope.fill", placeholder: "Email Address", text: $email)

                // Password Field
                SecureFieldWithIcon(icon: "lock.fill", placeholder: "Password", text: $password)

                // Login Button
                Button(action: loginUser) {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .font(.headline)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                // Error Message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.2)]), startPoint: .top, endPoint: .bottom))
            .ignoresSafeArea()

            // Navigation to ContentView on successful login
            .navigationDestination(isPresented: $isAuthenticated) {
                ContentView() // Destination to navigate to
            }
        }
    }

    private func loginUser() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Login failed: \(error.localizedDescription)"
                return
            }

            // Reset fields on successful login
            email = ""
            password = ""
            isAuthenticated = true
            errorMessage = "Login successful!"
        }
    }
}

#Preview {
    LoginView()
}
