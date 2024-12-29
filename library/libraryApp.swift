import SwiftUI
import Firebase

@main
struct libraryApp: App {
    
    // Declare AppDelegate as a property here
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView() // Your initial view
        }
    }
}

// AppDelegate to handle Firebase configuration
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Firebase
        print("Configuring Firebase...")
        FirebaseApp.configure()
        print("Firebase configured successfully.")
        return true
    }
}
