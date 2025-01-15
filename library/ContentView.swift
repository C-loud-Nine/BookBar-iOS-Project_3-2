import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var isActive = false

    var body: some View {
        Group {
            if !isActive {
                SplashScreenView(isActive: $isActive)
            } else if !authViewModel.isAuthenticated {
                RegisterView()
            } else {
                MainTabView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthenticationViewModel())
    }
}
