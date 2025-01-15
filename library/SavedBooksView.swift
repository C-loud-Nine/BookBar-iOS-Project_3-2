import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SavedBooksView: View {
    @State private var savedBooks: [SavedBook] = []
    @State private var isLoading = true
    @State private var isGridView = true
    
    struct SavedBook: Identifiable {
        let id: String
        let title: String
        let authors: [String]
        let imageUrl: String
        let categories: [String]
        let savedAt: Date
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with view toggle
            HStack {
                Text("Saved Books")
                    .font(.system(size: 28, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                Spacer()
                
                Button(action: { isGridView = true }) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isGridView ? .blue : .gray)
                }
                Button(action: { isGridView = false }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 24))
                        .foregroundColor(isGridView ? .gray : .blue)
                }
            }
            .padding(.trailing, 10)
            
            if isLoading {
                ProgressView()
            } else if savedBooks.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No saved books yet")
                        .font(.headline)
                    Text("Books you save will appear here")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else {
                if isGridView {
                    gridView
                } else {
                    listView
                }
            }
            Spacer()
        }
        .padding(.top)
        .onAppear(perform: loadSavedBooks)
    }
    
    // Grid View
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 200))
            ], spacing: 8) {
                ForEach(savedBooks) { book in
                    VStack {
                        AsyncImage(url: URL(string: book.imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            case .success(let image):
                                image
                                    .resizable()
                                    .frame(width: 80, height: 120)
                                    .clipped()
                            case .failure:
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 80, height: 120)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 80, height: 120)
                        
                        VStack {
                            Text(book.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            
                            Text(book.authors.joined(separator: ", "))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .padding(EdgeInsets(top: 0, leading: 5, bottom: 5, trailing: 5))
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // List View
    private var listView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(savedBooks) { book in
                    HStack(spacing: 16) {
                        AsyncImage(url: URL(string: book.imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            case .success(let image):
                                image
                                    .resizable()
                                    .frame(width: 80, height: 120)
                                    .clipped()
                            case .failure:
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 80, height: 120)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 80, height: 120)
                        
                        VStack(alignment: .leading) {
                            Text(book.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(book.authors.joined(separator: ", "))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            if let category = book.categories.first {
                                Text(category)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.leading, 10)
                        
                        Spacer()
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func loadSavedBooks() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("webBooks")
            .whereField("userId", isEqualTo: userId)
            .order(by: "savedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                isLoading = false
                
                if let error = error {
                    print("Error loading saved books: \(error.localizedDescription)")
                    return
                }
                
                savedBooks = snapshot?.documents.compactMap { document -> SavedBook? in
                    let data = document.data()
                    return SavedBook(
                        id: document.documentID,
                        title: data["bookTitle"] as? String ?? "",
                        authors: data["authors"] as? [String] ?? [],
                        imageUrl: data["imageUrl"] as? String ?? "",
                        categories: data["categories"] as? [String] ?? [],
                        savedAt: (data["savedAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                } ?? []
            }
    }
} 