import SwiftUI
import FirebaseAuth
import FirebaseFirestore

//MARK: - SocialView
struct SocialView: View {
    @State private var cards: [Card] = []
    @State private var displayedCards: [Card] = []
    @State private var isLoading = false
    @State private var selectedCard: Card? = nil
    @State private var currentPage = 1
    @State private var totalPages = 1
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Book Reviews")
                    .font(.system(size: 28, weight: .bold))
                Text("See what others are reading")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
            )

            // Content ScrollView
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(cards) { card in
                        CardView(card: card)
                            .onTapGesture {
                                selectedCard = card
                            }
                    }
                    
                    // Load More section
                    if !isLoading && displayedCards.count < cards.count {
                        Button(action: loadMoreCards) {
                            HStack {
                                Text("Load More Reviews")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.down.circle.fill")
                            }
                            .foregroundColor(.blue)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                        }
                        .padding()
                    } else if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(item: $selectedCard) { card in
            CardDetailView(card: card)
        }
        .onAppear {
            Card.fetchCards { fetchedCards in
                self.cards = fetchedCards
                self.totalPages = (fetchedCards.count / 5) + (fetchedCards.count % 5 > 0 ? 1 : 0)
                self.loadMoreCards()
            }
        }
    }
    
    func loadMoreCards() {
        guard !isLoading else { return }
        isLoading = true
        let startIndex = (currentPage - 1) * 5
        let endIndex = min(startIndex + 5, cards.count)
        if startIndex < cards.count {
                let newCards = Array(cards[startIndex..<endIndex])
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    displayedCards.append(contentsOf: newCards)
                    currentPage += 1
                    
                    isLoading = false
                    
                    if displayedCards.count >= cards.count {
                        self.isLoading = false
                    }
                }
            } else {
                isLoading = false
            }
    }
}

//MARK: - Card
struct Card: Identifiable {
    var id = UUID()
    var heading: String
    var author: String
    var text: String
    var likes: Int
    var comments: Int
    var date: Date
    var bookTitle: String
    var bookSerial: Int
    var authorImageUrl: String
    
    static var sampleCards: [Card] = []
    
    static func fetchCards(completion: @escaping ([Card]) -> Void) {
        let bookList: [Books] = Books.allBooks
        let db = Firestore.firestore()
        
        db.collection("reviews").getDocuments { snapshot, error in
            if let error = error {
                print("Error getting reviews: \(error.localizedDescription)")
                completion([])
                return
            }
            
            var fetchedCards: [Card] = []
            let group = DispatchGroup()
            
            snapshot?.documents.forEach({ (documentSnapshot) in
                let reviewID = documentSnapshot.documentID
                let components = reviewID.split(separator: "_")
                
                if components.count == 2 {
                    let userName = String(components[0])
                    let bookId = Int(components[1]) ?? 0
                    
                    group.enter()
                    // Fetch user profile image
                    db.collection("users").whereField("name", isEqualTo: userName).getDocuments { userSnapshot, userError in
                        defer { group.leave() }
                        
                        var userImageUrl = ""
                        if let userDoc = userSnapshot?.documents.first {
                            userImageUrl = userDoc.get("imageUrl") as? String ?? ""
                        }
                        
                        let reviewData = documentSnapshot.data()
                        let reviewTitle = reviewData["reviewTitle"] as? String ?? "No Title"
                        let reviewDescription = reviewData["reviewDescription"] as? String ?? "No Description"
                        let likes = reviewData["likeCount"] as? Int ?? 0
                        let comments = reviewData["comments"] as? [[String: String]] ?? [[:]]
                        let commentNum = comments.count 
                        let dateTimestamp = reviewData["date"] as? Timestamp
                        let date = dateTimestamp?.dateValue() ?? Date()
                        
                        if let book = bookList.first(where: { $0.id == bookId }) {
                            let card = Card(
                                heading: reviewTitle,
                                author: userName,
                                text: reviewDescription,
                                likes: likes,
                                comments: commentNum,
                                date: date,
                                bookTitle: book.title,
                                bookSerial: bookId,
                                authorImageUrl: userImageUrl
                            )
                            fetchedCards.append(card)
                        }
                    }
                }
            })
            
            group.notify(queue: .main) {
                completion(fetchedCards)
            }
        }
    }
}


//MARK: - CardView
struct CardView: View {
    var card: Card
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                // Profile Image
                Group {
                    if !card.authorImageUrl.isEmpty {
                        AsyncImage(url: URL(string: card.authorImageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.blue.opacity(0.3))
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.blue.opacity(0.3))
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.author)
                        .font(.headline)
                    Text(formattedDate(card.date))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(card.heading)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(card.bookTitle)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                Text(card.text)
                    .font(.body)
                    .lineLimit(3)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Footer
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(card.likes)")
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "bubble.right.fill")
                        .foregroundColor(.blue)
                    Text("\(card.comments)")
                        .foregroundColor(.gray)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

//MARK: - CardDetailView
struct CardDetailView: View {
    var card: Card
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isLiked = false
    @State private var newComment = ""
    @State private var comments: [Comment] = []
    @State private var likeCount: Int = 0
    @State private var commentsCount: Int = 0
    
    let db = Firestore.firestore()
    
    var body: some View {
        VStack {
            HStack {
                Text("Back")
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.leading)
                    .padding(EdgeInsets(top: 0, leading: 15, bottom: 4, trailing: 0))
                    .onTapGesture {
                        presentationMode.wrappedValue.dismiss()
                    }
                Spacer()
            }
            Text(card.heading)
                .font(.title)
                .bold()
            Text(card.bookTitle)
                .font(.title2)
                .padding(.top, 3)
            Text("Posted by \(card.author) on \(formattedDate(card.date))")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom)
            HStack {
                Text("\(likeCount) Likes  .  \(commentsCount) Comments")
                    .foregroundColor(.white)
                    .padding()
                    .cornerRadius(10)
                Spacer()
            }
            .padding(.horizontal)
            .background(.green)
            ScrollView {
                Text(card.text)
                    .padding()
                HStack {
                    Button(action: toggleLike) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .white)
                            .padding()
                            .cornerRadius(10)
                        
                    }
                    Text("\(likeCount) Likes  .  \(commentsCount) Comments")
                        .foregroundColor(.white)
                        .padding()
                        .cornerRadius(10)
                    Spacer()
                }
                .background(.green)
                VStack(alignment: .leading) {
                    Text("Comments")
                        .font(.headline)
                        .padding(.top)
                    TextField("Enter your comment", text: $newComment, axis: .vertical)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .lineLimit(5)
                    
                    Button(action: submitComment) {
                        Text("Submit Comment")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 10)
                    
                    Divider().padding(.vertical)
                    ForEach(comments) { comment in
                        VStack(alignment: .leading) {
                            Text(comment.userName)
                                .font(.subheadline)
                                .bold()
                            Text(comment.commentText)
                                .font(.body)
                                .foregroundColor(.gray)
                                .padding(.bottom, 5)
                        }
                    }
                }
                .padding()
            }
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top)
        .onAppear {
            fetchComments()
            listenForLikeCount()
            //            listenForCommentsCount()
        }
    }
    
    func listenForLikeCount() {
        let userName = card.author
        let reviewID = "\(userName)_\(card.bookSerial)"
        db.collection("reviews").document(reviewID).addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)")
                return
            }
            guard let document = documentSnapshot, document.exists else {
                print("Document does not exist")
                return
            }
            if let data = document.data(), let newLikeCount = data["likeCount"] as? Int {
                DispatchQueue.main.async {
                    self.likeCount = newLikeCount
                }
            }
        }
    }
    
    func listenForCommentsCount() {
        let userName = card.author
        let reviewID = "\(userName)_\(card.bookSerial)"
        
        // Listen for real-time updates to the comments array
        db.collection("reviews").document(reviewID).addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)")
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                print("Document does not exist")
                return
            }
            
            // Retrieve the updated comments array from Firestore
            if let data = document.data(), let commentsArray = data["l"] as? [[String: String]] {
                // Update the local comments count based on the number of items in the "l" array
                DispatchQueue.main.async {
                    self.commentsCount = commentsArray.count
                }
            }
        }
    }
    
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func toggleLike() {
        isLiked.toggle()
        var likeVal = likeCount
        if isLiked {
            likeVal += 1
        } else {
            likeVal -= 1
        }
        let userName = card.author
        let reviewID = "\(userName)_\(card.bookSerial)"
        let commentDict: [String : String] = [userName : newComment]
        
        db.collection("reviews").document(reviewID).updateData([
            "likeCount": likeVal
        ]) { error in
            if let error = error {
                print("Error saving likeCount: \(error.localizedDescription)")
            } else {
            }
        }
    }
    
    func submitComment() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("User is not logged in.")
            return
        }
        
        if !newComment.isEmpty {
            let userName = card.author
            let reviewID = "\(userName)_\(card.bookSerial)"
            let commentDict: [String : String] = [userName : newComment]
            
            db.collection("reviews").document(reviewID).updateData([
                "comments": FieldValue.arrayUnion([commentDict])
            ]) { error in
                if let error = error {
                    print("Error saving comment: \(error.localizedDescription)")
                } else {
                    let newCommentObj = Comment(userName: userName, commentText: newComment)
                    comments.append(newCommentObj)
                    newComment = ""
                }
            }
        }
    }
    
    struct Comment: Identifiable {
        var id = UUID()
        var userName: String
        var commentText: String
    }
    
    func fetchComments() {
        let userName = card.author
        let reviewID = "\(userName)_\(card.bookSerial)"
        
        db.collection("reviews").document(reviewID).getDocument { document, error in
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("Document does not exist")
                return
            }
            
            if let reviewData = document.data() {
                if let commentArray = reviewData["comments"] as? [[String: String]] {
                    var fetchedComments: [Comment] = []
                    var count = 0
                    for comment in commentArray {
                        count += 1
                        for (userName, commentText) in comment {
                            let comment = Comment(userName: userName, commentText: commentText)
                            fetchedComments.append(comment)
                        }
                    }
                    DispatchQueue.main.async {
                        self.comments = fetchedComments
                        self.commentsCount = count
                    }
                } else {
                    print("Comments are not in the expected format.")
                }
            }
        }
    }
    
    
}

#Preview {
    SocialView()
}
