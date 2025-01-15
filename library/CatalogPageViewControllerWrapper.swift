import SwiftUI

struct CatalogPageViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CatalogPageViewController {
        let controller = CatalogPageViewController()
        // Reduce the bottom safe area inset
        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        return controller
    }

    func updateUIViewController(_ uiViewController: CatalogPageViewController, context: Context) {
        // Updates if needed
    }
}

struct CatalogPageView: View {
    var body: some View {
        CatalogPageViewControllerWrapper()
            .edgesIgnoringSafeArea(.all)  // Makes the view fullscreen
            .background(Color.white) // Optional: Add a background color to match the UIKit setup
    }
}

struct CatalogPageView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogPageView()
            .previewDevice("iPhone 13") // Set the preview device if needed
            .previewLayout(.sizeThatFits) // Optional: Adjusts the size to fit content
    }
}
