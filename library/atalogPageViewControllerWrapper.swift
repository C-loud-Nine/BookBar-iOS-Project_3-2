import SwiftUI

struct CatalogPageViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CatalogPageViewController {
        return CatalogPageViewController() // Initialize the CatalogPageViewController
    }

    func updateUIViewController(_ uiViewController: CatalogPageViewController, context: Context) {
        // You can update your view controller here, such as passing data, if needed.
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
