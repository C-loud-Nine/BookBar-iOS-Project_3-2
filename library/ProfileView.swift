import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Cloudinary
import PhotosUI

struct ProfileView: View {
    @State private var imageUrl: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var errorMessage = ""
    @State private var userName: String = ""
    @State private var joinedDate: String = ""
    @State private var userEmail: String = ""
    @State private var showSaveButton: Bool = false
    @State private var showPasswordChange = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var userStats: [String: Any] = [:]  // For statistics

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                profileImageSection
                userInfoSection
                statisticsSection
                passwordChangeSection
                errorView
                actionButtonsView  // Add action buttons row here
                saveButtonView
                Spacer()
            }
            .padding()
            .background(
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
            )
            .onAppear {
                loadUserProfile()
                loadUserStats()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var profileImageSection: some View {
        VStack(spacing: 16) {
            Group {
                if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                    profileImageView(uiImage: uiImage)
                } else if !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        profileImageView(image: image)
                    } placeholder: {
                        defaultProfileImage
                    }
                } else {
                    defaultProfileImage
                }
            }
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                Text("Change Profile Picture")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [.blue, .blue.opacity(0.8)],
                                     startPoint: .leading,
                                     endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3)
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let selectedItem = selectedItem {
                        do {
                            let data = try await selectedItem.loadTransferable(type: Data.self)
                            selectedImageData = data
                            showSaveButton = true
                        } catch {
                            errorMessage = "Failed to load image data: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
        .padding(.top, 30)
    }

    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            infoRow(title: "Name", value: userName)
            infoRow(title: "Email", value: userEmail)
            infoRow(title: "Joined", value: joinedDate)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(LinearGradient(gradient: Gradient(colors: [.white, .blue.opacity(0.1)]), startPoint: .top, endPoint: .bottom))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    private var statisticsSection: some View {
        VStack(spacing: 20) {
            Text("User Statistics")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            // Example stats (books, reading progress, etc.)
            statRow(title: "Books in Library", value: "\(userStats["booksCount"] as? Int ?? 0)")
            statRow(title: "Books Read", value: "\(userStats["booksRead"] as? Int ?? 0)")
            statRow(title: "Reading Progress", value: "\(userStats["readingProgress"] as? Double ?? 0)%")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(LinearGradient(gradient: Gradient(colors: [.white, .green.opacity(0.1)]), startPoint: .top, endPoint: .bottom))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    private var passwordChangeSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Change Password")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.red)

            if showPasswordChange {
                VStack(spacing: 10) {
                    SecureField("Current Password", text: $currentPassword)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.systemGray5)))
                        .autocapitalization(.none)
                    
                    SecureField("New Password", text: $newPassword)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.systemGray5)))
                        .autocapitalization(.none)
                    
                    SecureField("Confirm New Password", text: $confirmPassword)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.systemGray5)))
                        .autocapitalization(.none)

                    Button(action: changePassword) {
                        Text("Change Password")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                            .clipShape(Capsule())
                    }
                    .padding(.top, 10)
                }
            } else {
                Button(action: { showPasswordChange.toggle() }) {
                    Text("Edit Password")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.blue))
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(LinearGradient(gradient: Gradient(colors: [.white, .orange.opacity(0.1)]), startPoint: .top, endPoint: .bottom))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    private var errorView: some View {
        Group {
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 5)
                    .transition(.opacity)
            }
        }
        .padding(.top, 20)
    }

    private var saveButtonView: some View {
        Group {
            if showSaveButton {
                Button(action: saveProfilePicture) {
                    Text("Save Profile Picture")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.green, .green.opacity(0.8)],
                                         startPoint: .leading,
                                         endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3)
                        .scaleEffect(showSaveButton ? 1.05 : 1)
                        .animation(.easeInOut(duration: 0.2), value: showSaveButton)
                }
                .padding(.bottom, 20)
            }
        }
    }

    private var actionButtonsView: some View {
        HStack(spacing: 20) {
            Button(action: logout) {
                HStack {
                    Image(systemName: "lock.fill")
                    Text("Logout")
                        .fontWeight(.semibold)
                }
                .font(.system(size: 12))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Capsule())
            }
            Spacer()
            Button(action: deleteAccount) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete Account")
                        .fontWeight(.semibold)
                }
                .font(.system(size: 12))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(colors: [.black, .black.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Capsule())
            }
        }
        .padding()
    }

    private func profileImageView(uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()
            .frame(width: 160, height: 160)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
            )
    }

    private func profileImageView(image: Image) -> some View {
        image
            .resizable()
            .scaledToFill()
            .frame(width: 160, height: 160)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
            )
    }

    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 160, height: 160)
            .foregroundColor(Color(UIColor.systemGray4))
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
            )
    }

    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(value)
                .font(.title3)
                .fontWeight(.medium)
            Divider()
                .background(Color.gray.opacity(0.2))
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.bold)
        }
        .padding(.vertical, 5)
    }

    // Fetch user profile data
    private func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").document(uid).getDocument { document, error in
            if let error = error {
                errorMessage = "Error loading profile: \(error.localizedDescription)"
                return
            }

            if let document = document, document.exists {
                userName = document.get("name") as? String ?? "No Name"
                userEmail = Auth.auth().currentUser?.email ?? "No Email"
                
                if let timestamp = document.get("created_at") as? Timestamp {
                    let date = timestamp.dateValue()
                    let formatter = DateFormatter()
                    formatter.dateStyle = .long
                    formatter.timeStyle = .none
                    joinedDate = formatter.string(from: date)
                }
                imageUrl = document.get("imageUrl") as? String ?? ""
            }
        }
    }

    private func loadUserStats() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let booksCollectionRef = Firestore.firestore().collection("users").document(uid).collection("books")

        booksCollectionRef.getDocuments { snapshot, error in
            if let error = error {
                errorMessage = "Error loading user stats: \(error.localizedDescription)"
                return
            }

            guard let snapshot = snapshot else {
                errorMessage = "No books found"
                return
            }

            let totalBooks = snapshot.documents.count
            
            let booksRead = snapshot.documents.filter { document in
                let status = document.get("status") as? String
                return status == "Completed"
            }.count
            
            userStats["booksCount"] = totalBooks
            userStats["booksRead"] = booksRead
            userStats["readingProgress"] = totalBooks == 0 ? 0 : (Double(booksRead) / Double(totalBooks)) * 100
        }
    }


    private func changePassword() {
        guard !currentPassword.isEmpty, !newPassword.isEmpty, newPassword == confirmPassword else {
            errorMessage = "Please ensure all fields are filled out correctly."
            return
        }
        
        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
            if let error = error {
                errorMessage = "Error changing password: \(error.localizedDescription)"
            } else {
                errorMessage = "Password changed successfully."
            }
        }
    }

    private func saveProfilePicture() {
        uploadImage()
        showSaveButton = false
    }

    private func uploadImage() {
        guard let selectedImageData else { return }

        let config = CLDConfiguration(cloudName: "dbmxtao2a", apiKey: "394734589667949")
        let cloudinary = CLDCloudinary(configuration: config)

        cloudinary.createUploader().upload(data: selectedImageData, uploadPreset: "library1") { result, error in
            if let error = error {
                errorMessage = "Failed to upload image: \(error.localizedDescription)"
                return
            }

            if let secureUrl = result?.secureUrl {
                updateFirestoreImageUrl(url: secureUrl)
            }
        }
    }

    private func updateFirestoreImageUrl(url: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").document(uid).updateData(["imageUrl": url]) { error in
            if let error = error {
                errorMessage = "Failed to update image URL: \(error.localizedDescription)"
            } else {
                imageUrl = url
            }
        }
    }

    private func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = "Error logging out: \(error.localizedDescription)"
        }
    }

    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user is signed in."
            return
        }

        user.delete { error in
            if let error = error {
                errorMessage = "Error deleting account: \(error.localizedDescription)"
            } else {
                errorMessage = "Your account has been deleted."
            }
        }
    }
}
