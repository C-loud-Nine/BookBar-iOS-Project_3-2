import SwiftUI

struct SplashScreenView: View {
    @Binding var isActive: Bool
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var isAnimating = false // Add animation state

    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            VStack {
                Image(systemName: "book.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                    .scaleEffect(isAnimating ? 1.0 : 0.5) // Add scale animation
                    .opacity(isAnimating ? 1 : 0) // Add fade animation

                Text("Library App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                    .opacity(isAnimating ? 1 : 0) // Add fade animation
            }
        }
        .onAppear {
            // Start animations when view appears
            withAnimation(.easeIn(duration: 1.2)) {
                isAnimating = true
            }
            
            // Wait for 2.5 seconds before deciding the next screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    isActive = true // Set isActive to true to navigate
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            // Navigate to the correct screen after splash
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                RegisterView()
            }
        }
    }
}

// Add Preview Provider
struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView(isActive: .constant(false))
            .environmentObject(AuthenticationViewModel())
    }
}

