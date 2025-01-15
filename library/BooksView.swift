import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct BooksView: View {
    @State private var selectedOption = "Catalog"
    @State private var isSidebarVisible = false
    @State private var searchText = ""
    @State private var navigateToCatalog = false // State for navigation
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    topBar
                    ZStack(alignment: .topLeading) {
                        if isSidebarVisible {
                            sideBar
                                .frame(width: 280)
                                .transition(.move(edge: .leading))
                                .zIndex(1)
                        }
                        HStack(spacing: 0) {
                            mainContent
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToCatalog) {
                CatalogPageContainerView()
            }
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 16) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isSidebarVisible.toggle()
                }
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                TextField("Search books...", text: $searchText)
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button(action: {}) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Sidebar
    private var sideBar: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Library Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Library")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal)
                        
                        VStack(spacing: 4) {
                            MenuButton(
                                title: "Catalog",
                                icon: "books.vertical",
                                selected: selectedOption == "Catalog",
                                action: {
                                    selectedOption = "Catalog"
                                }
                            )
                            MenuButton(
                                title: "My Books",
                                icon: "book.closed",
                                selected: selectedOption == "My Books",
                                action: { selectedOption = "My Books" }
                            )
                            MenuButton(
                                title: "My links",
                                icon: "book.closed",
                                selected: selectedOption == "Links",
                                action: { 
                                    selectedOption = "Links"
                                    navigateToCatalog = true
                                }
                            )
                            MenuButton(
                                title: "Saved Books",
                                icon: "bookmark.fill",
                                selected: selectedOption == "SavedBooks",
                                action: { selectedOption = "SavedBooks" }
                            )
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reading Lists")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal)
                        
                        VStack(spacing: 4) {
                            MenuButton(
                                title: "Want to Read",
                                icon: "star",
                                selected: selectedOption == "Want to Read",
                                action: { selectedOption = "Want to Read" }
                            )
                            MenuButton(
                                title: "In Progress",
                                icon: "book",
                                selected: selectedOption == "In Progress",
                                action: { selectedOption = "In Progress" }
                            )
                            MenuButton(
                                title: "Completed",
                                icon: "checkmark.circle",
                                selected: selectedOption == "Completed",
                                action: { selectedOption = "Completed" }
                            )
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            
            Divider()
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(userName.prefix(2).uppercased())
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(userName)
                            .font(.system(size: 15, weight: .medium))
                        Text(userEmail)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(12)
            }
        }
        .background(Color(.systemBackground))
        .frame(maxHeight: .infinity)
        .onAppear(perform: loadUserProfile)
    }
    
    private func loadUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error loading profile: \(error.localizedDescription)")
                return
            }
            
            if let data = snapshot?.data() {
                userName = data["name"] as? String ?? "User"
                userEmail = data["email"] as? String ?? ""
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack {
            // Placeholder content view
            VStack(spacing: 16) {
                switch selectedOption {
                case "Catalog":
                    CatalogContentView()
                case "My Books":
                    MyBooksContentView()
                case "Links":
                    CatalogPageContainerView()
                case "SavedBooks":
                    SavedBooksView()
                default:
                    Text("Select an option")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.top)
            
            Spacer()
        }
    }
}


struct CatalogPageContainerView: View {
    var body: some View {
        NavigationView {
            CatalogPageViewControllerWrapper()
                .edgesIgnoringSafeArea(.all)
                .background(Color.white)
                .navigationTitle("Catalog") // Set a title for navigation bar
        }
    }
}

// MARK: - Catalog Content View
struct CatalogContentView: View {
    private var books: [Books] = Books.allBooks
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Catalog")
                .font(.system(size: 28, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            List {
                ForEach(books) { book in
                    NavigationLink(destination: BookDetailsView(book: book)) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(book.title).font(.system(size: 18, weight: .bold))
                            Text(book.author).font(.system(size: 14))
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }}
            }.listStyle(.insetGrouped)
                .padding(.top, 8)
        }
        .padding(.top)
    }
}

// MARK: - My Books Content View
struct MyBooksContentView: View {
    @State private var isGridView = true
    private var books: [Books] = Books.allBooks
    @State private var booksFromFirestore: [Books] = []
    @State private var userID: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("My Books")
                    .font(.system(size: 28, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                Spacer()
                
                Button(action: {
                    isGridView = true
                }) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isGridView ? .blue : .gray)
                }
                Button(action: {
                    isGridView = false
                }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 24))
                        .foregroundColor(isGridView ? .gray : .blue)
                }
            }.padding(.trailing, 10)
            
            if isGridView {
                gridView
            } else {
                listView
            }
            Spacer()
        }
        .padding(.top)
        .onAppear {
            getBooks()
        }
    }
    
    // Grid View
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 200))
            ], spacing: 8) {
                ForEach(booksFromFirestore) { book in
                    NavigationLink(destination: BookDetailsView(book: book)) {
                        VStack {
                            AsyncImage(url: URL(string: book.img)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                case .success(let image):
                                    image
                                        .resizable()
//                                        .scaledToFit()
                                        .frame(width: 80, height: 120)
                                        .clipped()
                                        .padding(0)
                                case .failure:
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .frame(width: 80, height: 120)
                                @unknown default:
                                    EmptyView()
                                }
                            }.frame(width: 80, height: 120)
                            VStack {
                                Text(book.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text(book.author)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }.padding(EdgeInsets(top: 0, leading: 5, bottom: 5, trailing: 5))
                        }
                        //                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    //     List View
    private var listView: some View {
        VStack(spacing: 16) {
            ScrollView{
                ForEach(booksFromFirestore, id: \.title) { book in
                    NavigationLink(destination: BookDetailsView(book: book)) {
                        HStack(spacing: 16) {
                            AsyncImage(url: URL(string: book.img)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                case .success(let image):
                                    image
                                        .resizable()
//                                        .scaledToFit()
                                        .frame(width:80, height: 120)
                                        .clipped()
                                        .padding(0)
                                case .failure:
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .frame(width: 80, height: 120)
                                @unknown default:
                                    EmptyView()
                                }
                            }.frame(width: 80, height: 120)
                            VStack {
                                VStack(alignment: .leading) {
                                    Text(book.title)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Text(book.author)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            }.padding(.leading, 10)
                            
                            Spacer()
                        }
                        //                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    func getBooks() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("User is not logged in.")
            return
        }
        let db = Firestore.firestore()
        let bookRef = db.collection("users").document(uid).collection("books")
        bookRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting book IDs: \(error.localizedDescription)")
            } else {
                var bookIDs: [String] = []
                for document in querySnapshot!.documents {
                    if let bookID = document.documentID as? String {
                        bookIDs.append(bookID)
                    }
                }
                self.fetchBooksFromJSON(bookIDs: bookIDs)
            }
        }
    }
    
    
    
    func fetchBooksFromJSON(bookIDs: [String]) {
        let matchingBooks = books.filter { book in
            bookIDs.contains(String(book.id))
        }
        self.booksFromFirestore = matchingBooks
    }
}

// MARK: - Supporting Views
struct MenuButton: View {
    let title: String
    let icon: String
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: selected ? "\(icon).fill" : icon)
                    .font(.system(size: 16))
                    .foregroundColor(selected ? .blue : .primary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(selected ? .blue : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(selected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BooksView()
}
