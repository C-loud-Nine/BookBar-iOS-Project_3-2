import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct BookDetailsView: View {
    let book: Books
    @State private var activeIndex = 0
    @State private var showingPopover = false
    @State private var selectedStatus: String? = nil
    @State private var userID: String? = nil
    let headers = ["Overview", "Details", "Reviews"]
    let statuses = ["Planning", "Reading", "Dropped", "Completed"]
    var body: some View {
        VStack {
            Text("\(book.title)").font(.system(size: 32, weight: .bold)).foregroundColor(.primary)
            HStack {
                Menu(selectedStatus ?? "Add To Collections") {
                    ForEach(statuses, id: \.self) { status in
                        Button(action: {
                            selectedStatus = status
                            saveBookStatus(status: status)
                        }, label: {
                            Text(status)
                                .foregroundStyle(Color.white)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.black))
                        })
                    }
                }
                .padding(.all, 5)
                .foregroundStyle(Color.white)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.green))
                if selectedStatus == "Completed" {
                    Spacer()
                    Button("Add A Review") {
                        showingPopover.toggle()
                    }.padding(.all, 5)
                        .foregroundStyle(Color.black)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.brown))
                        .sheet(isPresented: $showingPopover) {
                            ReviewProviderView(book: book)
                        }
                }
            }.padding(.horizontal)
            HStack {
                ForEach(0..<headers.count, id: \.self) { index in
                    Text(headers[index])
                        .font(.system(size: 16))
                        .foregroundColor(self.activeIndex == index ? .blue : .gray)
                        .padding(.horizontal, 10)
                        .onTapGesture {
                            activeIndex = index
                        }
                }
            }
            .padding(.top)
            Divider()
                .frame(height: 2)
                .background(Color.black)
                .padding(.bottom)
            TabView(selection: $activeIndex) {
                ForEach(0..<headers.count, id: \.self) { index in
                    VStack {
                        if index == 0 {
                            OverviewView(book: book)
                        } else if index == 1 {
                            DetailsView(book: book)
                        } else if index == 2 {
                            ReviewsView()
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .padding()
        .onAppear {
            fetchUserID()
            fetchBookStatus()
        }
    }
    
    func fetchUserID() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("User is not logged in.")
            return
        }
        self.userID = uid
    }
    
    func fetchBookStatus() {
        guard let uid = userID else {
            print("User is not logged in.")
            return
        }
        let db = Firestore.firestore()
        let bookID = String(book.id)
        let bookRef = db.collection("users").document(uid).collection("books").document(bookID)
        bookRef.getDocument { (document, error) in
            if let error = error {
                print("Error fetching book status: \(error.localizedDescription)")
            } else if let document = document, document.exists {
                if let status = document.data()?["status"] as? String {
                    self.selectedStatus = status
                }
            } else {
                //                print("Book does not exist in the database.")
            }
        }
    }
    
    func saveBookStatus(status: String) {
        guard let uId = userID else {
            print("User ID not available")
            return
        }
        let db = Firestore.firestore()
        let bookID = String(book.id)
        let bookRef = db.collection("users").document(uId).collection("books").document(bookID)
        bookRef.setData([
            "status": status,
            "review": ""
        ]) { error in
            if let error = error {
                print("Error saving status: \(error.localizedDescription)")
            } else {
                print("Book status saved successfully!")
            }
        }
    }
}

// MARK: - OverView
struct OverviewView: View {
    let book: Books
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Author")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(book.author)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                    VStack(alignment: .leading) {
                        Text("Pages")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(book.pages)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                    VStack(alignment: .leading) {
                        Text("Published")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(book.published)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                }
                
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Edition")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(book.edition)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                    VStack(alignment: .leading) {
                        Text("Publisher")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(book.publisher)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                }
                
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Categories")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(book.categories.joined(separator: ", "))
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                }
            }
            Spacer()
            Divider()
                .frame(height: 200)
                .background(Color.gray)
            AsyncImage(url: URL(string: book.img)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                case .success(let image):
                    image
                        .resizable()
                        .frame(width: 80, height: 120)
                        .clipped()
                        .padding(.leading, 10)
                case .failure:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .frame(width: 160, height: 200)
                @unknown default:
                    EmptyView()
                }
            }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(5)
        Spacer()
    }
}

//MARK: - DetailsView
struct DetailsView: View {
    let book: Books
    var body: some View {
        
        ScrollView {
            Text("\(book.description)")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


//MARK: - ReviewsView
struct ReviewsView: View {
    var body: some View {
        VStack {
            Text("Welcome to Section C!")
                .font(.title)
                .padding()
            Text("Content specific to section C goes here. Customize each section as you like.")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

//MARK: - ReviewProvider
struct ReviewProviderView: View {
    let book: Books
    @Environment(\.dismiss) var dismiss
    @State private var reviewTitle: String = ""
    @State private var reviewDescription: String = ""
    @State private var userName: String? = nil
    @State private var currentDate: String = ""
    @State private var userID: String? = nil
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button("Submit") {
                            submitReview()
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.top)
                    Text("Write A Review")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    Text(book.title)
                        .font(.headline)
                        .padding(.bottom)
                    HStack {
                        Text("User: \(userName ?? "Anonymous")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(currentDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom)
                    
                    VStack(alignment: .leading) {
                        Text("Title")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("Enter review title", text: $reviewTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.bottom, 16)
                            .lineLimit(2)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Description")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("Enter review description", text: $reviewDescription, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.bottom, 16)
                            .lineLimit(10)
                    }
                    Spacer()
                }
                .padding()
                .onAppear {
                    fetchUserID()
                    currentDate = getCurrentDate()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
    
    func fetchUserID() {
        if let user = Auth.auth().currentUser {
            self.userID = user.uid
            fetchUsername(userID: user.uid)
        } else {
            print("User not logged in")
        }
    }
    
    func fetchUsername(userID: String) {
        let db = Firestore.firestore()
        db.collection("users")
            .document(userID)
            .getDocument { document, error in
                if let document = document, document.exists {
                    if let userName = document.data()?["name"] as? String {
                        self.userName = userName
                    }
                } else {
                    print("Error fetching user data: \(String(describing: error))")
                }
            }
    }
    
    func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: Date())
    }
    
    func submitReview() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("User is not logged in.")
            return
        }
        guard let userGName = userName else {
            print("Nothing found")
            return
        }
        let reviewID = "\(userGName)_\(book.id)"
        let db = Firestore.firestore()
        let bookID = String(book.id)
        let bookRef = db.collection("reviews").document(reviewID)
        let commentsList: [String: String] = [:]
        bookRef.setData([
            "reviewTitle": reviewTitle,
            "date": currentDate,
            "reviewDescription": reviewDescription,
            "likeCount": 0,
            "comments": commentsList
        ], merge: true) { error in
            if let error = error {
                print("Error saving review: \(error.localizedDescription)")
            } else {
                print("Review successfully saved!")
                dismiss()
            }
        }
    }
}
