//  LoginView.swift
//  library
//
//  Created by Shafi on 12/30/24.

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showRegister = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 15) {
                            Image(systemName: "books.vertical.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.blue)
                                .padding(.top, 40)
                            
                            Text("Welcome Back!")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Sign in to continue")
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 20)
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            // Email Field
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 40)
                                TextField("Email Address", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            
                            // Password Field
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 40)
                                SecureField("Password", text: $password)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        
                        // Login Button
                        Button(action: signIn) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        .disabled(isLoading)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Register Navigation
                        NavigationLink(destination: RegisterView()
                            .navigationBarBackButtonHidden(true)
                        ) {
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .foregroundColor(.gray)
                                Text("Register")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 20)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func signIn() {
        isLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false
            
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
                return
            }
            
            // Successfully logged in
            // The app will automatically navigate to the main view
            // because of the authentication state listener
        }
    }
}

#Preview {
    LoginView()
}
