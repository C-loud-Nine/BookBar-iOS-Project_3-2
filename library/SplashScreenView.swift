import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false

    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea() // Background color
            VStack {
                Image(systemName: "book.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)

                Text("Library App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isActive = true
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            RegisterView()
        }
    }
}
