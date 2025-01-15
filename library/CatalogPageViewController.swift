import UIKit
import FirebaseFirestore
import FirebaseAuth

// Model to store book data
struct Book: Codable {
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let imageLinks: ImageLinks?
    let categories: [String]?
}

struct ImageLinks: Codable {
    let thumbnail: String?
}

struct BookSearchResponse: Codable {
    let items: [Book]
}

class CatalogPageViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate {

    var books: [Book] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var filteredBooks: [Book] = []
    
    private var searchBar: UISearchBar!
    private var genreFilter: UISegmentedControl!
    private var collectionView: UICollectionView!
    
    private var isLoading = false
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // Custom initializer
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    private func setupUI() {
        // Setup Search Bar
        searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search for books..."
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.backgroundColor = .clear
        view.addSubview(searchBar)
        
        // Genre Filter with custom style
        let genres = ["All", "Science", "Fiction", "History", "Art"]
        genreFilter = UISegmentedControl(items: genres)
        genreFilter.selectedSegmentIndex = 0
        genreFilter.backgroundColor = .systemBackground
        genreFilter.selectedSegmentTintColor = .systemBlue
        genreFilter.setTitleTextAttributes([.foregroundColor: UIColor.systemGray], for: .normal)
        genreFilter.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        genreFilter.addTarget(self, action: #selector(genreChanged), for: .valueChanged)
        genreFilter.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(genreFilter)

        // Setup Collection View with custom layout
        let layout = createCompositionalLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemBackground
        collectionView.register(BookCell.self, forCellWithReuseIdentifier: "BookCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        // Add activity indicator
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            genreFilter.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            genreFilter.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            genreFilter.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            collectionView.topAnchor.constraint(equalTo: genreFilter.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor)
        ])
        
        // Initial fetch
        fetchBooks(query: "popular books", genre: "All")
    }
    
    private func createCompositionalLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(280)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 8,
            bottom: 8,
            trailing: 8
        )
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        layout.configuration.contentInsetsReference = .safeArea
        
        return layout
    }

    private func fetchBooks(query: String, genre: String) {
        guard !isLoading else { return }
        isLoading = true
        activityIndicator.startAnimating()
        
        // Clear previous results if it's a new search
        books = []
        filteredBooks = []
        collectionView.reloadData()
        
        var urlComponents = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")!
        var queryItems = [URLQueryItem]()
        
        // Build the query string
        var searchQuery = query.isEmpty ? "popular books" : query
        if genre != "All" {
            searchQuery += "+subject:\(genre.lowercased())"
        }
        
        queryItems.append(URLQueryItem(name: "q", value: searchQuery))
        queryItems.append(URLQueryItem(name: "maxResults", value: "20"))
        queryItems.append(URLQueryItem(name: "orderBy", value: "relevance"))
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            isLoading = false
            activityIndicator.stopAnimating()
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.activityIndicator.stopAnimating()
                
                if let error = error {
                    print("Error fetching books: \(error)")
                    return
                }
                
                guard let data = data else { return }
                
                do {
                    let result = try JSONDecoder().decode(BookSearchResponse.self, from: data)
                    self?.books = result.items
                    self?.filteredBooks = result.items
                    self?.collectionView.reloadData()
                } catch {
                    print("Error decoding data: \(error)")
                }
            }
        }
        task.resume()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredBooks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookCell", for: indexPath) as! BookCell
        let book = filteredBooks[indexPath.row]
        cell.configure(with: book)
        return cell
    }

    // Debounce search to prevent too many API calls
    private var searchWorkItem: DispatchWorkItem?
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.fetchBooks(
                query: searchText,
                genre: self?.genreFilter.titleForSegment(at: self?.genreFilter.selectedSegmentIndex ?? 0) ?? "All"
            )
        }
        
        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    @objc func genreChanged() {
        fetchBooks(
            query: searchBar.text ?? "",
            genre: genreFilter.titleForSegment(at: genreFilter.selectedSegmentIndex) ?? "All"
        )
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let book = filteredBooks[indexPath.row]
        showBookDetails(for: book)
    }
    
    private func showBookDetails(for book: Book) {
        let detailVC = BookDetailViewController(book: book)
        let nav = UINavigationController(rootViewController: detailVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

class BookCell: UICollectionViewCell {
    private var imageView: UIImageView!
    private var titleLabel: UILabel!
    private var authorLabel: UILabel!
    private var containerView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Container View
        containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowRadius = 4
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Image View
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        
        // Title Label
        titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Author Label
        authorLabel = UILabel()
        authorLabel.font = .systemFont(ofSize: 12)
        authorLabel.textColor = .systemGray
        authorLabel.numberOfLines = 1
        authorLabel.textAlignment = .center
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(authorLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 120),
            imageView.heightAnchor.constraint(equalToConstant: 180),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            authorLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            authorLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            authorLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.layer.shadowPath = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: 12).cgPath
    }
    
    func configure(with book: Book) {
        titleLabel.text = book.volumeInfo.title
        authorLabel.text = book.volumeInfo.authors?.joined(separator: ", ") ?? "Unknown Author"
        
        // Reset image and add loading state
        imageView.image = UIImage(systemName: "book.closed")
        imageView.tintColor = .systemGray4
        imageView.backgroundColor = .systemGray6
        
        if let thumbnailURL = book.volumeInfo.imageLinks?.thumbnail,
           let url = URL(string: thumbnailURL.replacingOccurrences(of: "http://", with: "https://")) {
            imageView.cancelImageLoad()
            imageView.loadImage(from: url)
        }
    }
}

// Improve image loading with cancellation support
extension UIImageView {
    private static var taskKey = "ImageLoadTaskKey"
    
    private var currentTask: URLSessionDataTask? {
        get { objc_getAssociatedObject(self, &UIImageView.taskKey) as? URLSessionDataTask }
        set { objc_setAssociatedObject(self, &UIImageView.taskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    func cancelImageLoad() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    func loadImage(from url: URL) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self else { return }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = image
                    self.backgroundColor = .clear
                }
            }
            self.currentTask = nil
        }
        
        currentTask = task
        task.resume()
    }
}

class BookDetailViewController: UIViewController {
    private let book: Book
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    init(book: Book) {
        self.book = book
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation Bar setup
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(dismissVC)
        )
        
        // Add Save Button to navigation bar
        let saveButton = UIButton(type: .system)
        saveButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        saveButton.addTarget(self, action: #selector(saveBookToList), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(containerView)
        
        // Book Cover
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        if let thumbnailURL = book.volumeInfo.imageLinks?.thumbnail,
           let url = URL(string: thumbnailURL.replacingOccurrences(of: "http://", with: "https://")) {
            imageView.loadImage(from: url)
        }
        
        // Book Info
        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.spacing = 16
        infoStack.alignment = .leading
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        let titleLabel = createLabel(text: book.volumeInfo.title, font: .boldSystemFont(ofSize: 24))
        
        // Authors
        let authorsLabel = createLabel(
            text: book.volumeInfo.authors?.joined(separator: ", ") ?? "Unknown Author",
            font: .systemFont(ofSize: 18),
            color: .secondaryLabel
        )
        
        // Categories
        let categoriesLabel = createLabel(
            text: book.volumeInfo.categories?.joined(separator: ", ") ?? "Uncategorized",
            font: .systemFont(ofSize: 16),
            color: .systemBlue
        )
        
        // Add to stack
        infoStack.addArrangedSubview(titleLabel)
        infoStack.addArrangedSubview(authorsLabel)
        infoStack.addArrangedSubview(categoriesLabel)
        
        // Add to container
        containerView.addSubview(imageView)
        containerView.addSubview(infoStack)
        
        // Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 160),
            imageView.heightAnchor.constraint(equalToConstant: 240),
            
            infoStack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 24),
            infoStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            infoStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            infoStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createLabel(text: String, font: UIFont, color: UIColor = .label) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.numberOfLines = 0
        return label
    }
    
    @objc private func dismissVC() {
        dismiss(animated: true)
    }
    
    @objc private func saveBookToList() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let webBookRef = db.collection("webBooks").document()
        
        let bookData: [String: Any] = [
            "userId": userId,
            "bookId": webBookRef.documentID,
            "bookTitle": book.volumeInfo.title,
            "authors": book.volumeInfo.authors ?? [],
            "imageUrl": book.volumeInfo.imageLinks?.thumbnail ?? "",
            "categories": book.volumeInfo.categories ?? [],
            "savedAt": Timestamp(),
            "source": "Google Books"
        ]
        
        webBookRef.setData(bookData) { [weak self] error in
            if let error = error {
                print("Error saving book: \(error.localizedDescription)")
                return
            }
            
            // Show success message
            let alert = UIAlertController(
                title: "Success", 
                message: "Book saved to your list", 
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
            
            // Update save button
            if let button = self?.navigationItem.rightBarButtonItem?.customView as? UIButton {
                button.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
                button.tintColor = .systemGreen
            }
        }
    }
}

