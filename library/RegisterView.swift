//
//  RegisterView.swift
//  library
//
//  Created by Shafi on 12/30/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showLogin = false

    var body: some View {
        VStack(spacing: 30) {
            // Title
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.green)
                .padding(.top, 40)

            // Icon
            Image(systemName: "person.badge.plus.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
                .padding(.bottom, 20)

            // Name Field
            TextFieldWithIcon(icon: "person.fill", placeholder: "Full Name", text: $name)

            // Email Field
            TextFieldWithIcon(icon: "envelope.fill", placeholder: "Email Address", text: $email)

            // Password Field
            SecureFieldWithIcon(icon: "lock.fill", placeholder: "Password", text: $password)

            // Register Button
            Button(action: registerUser) {
                Text("Register")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
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

            // Already Registered
            HStack {
                Text("Already registered?")
                    .foregroundColor(.gray)

                Button(action: { showLogin = true }) {
                    Text("Log in here")
                        .foregroundColor(.blue)
                        .underline()
                }
            }
            .padding(.top, 10)

            Spacer()
        }
        .padding()
        .background(LinearGradient(gradient: Gradient(colors: [Color.white, Color.green.opacity(0.2)]), startPoint: .top, endPoint: .bottom))
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
        }
    }

    private func registerUser() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "All fields are required."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Registration failed: \(error.localizedDescription)"
                return
            }

            if let uid = result?.user.uid {
                Firestore.firestore().collection("users").document(uid).setData([
                    "name": name,
                    "email": email,
                    "created_at": Timestamp()
                ]) { firestoreError in
                    if let firestoreError = firestoreError {
                        errorMessage = "Error saving user info: \(firestoreError.localizedDescription)"
                    } else {
                        // Reset fields on successful registration
                        name = ""
                        email = ""
                        password = ""
                        errorMessage = "Registration successful!"
                    }
                }
            }
        }
    }
}


#Preview(){
    RegisterView();
}
