import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            
            NavigationView {
                SocialView()
            }
            .tabItem {
                Label("Social", systemImage: "bubble.right.fill")
            }
            
            NavigationView {
                BooksView()
            }
            .tabItem {
                Label("Library", systemImage: "book.fill")
            }
        }
        .accentColor(.blue)
    }
}
