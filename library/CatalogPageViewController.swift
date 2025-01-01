import UIKit

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
    
    // Custom initializer
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Header Label
        let headerLabel = UILabel()
        headerLabel.text = "Catalog"
        headerLabel.font = UIFont.boldSystemFont(ofSize: 24)
        headerLabel.textAlignment = .center
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerLabel)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Genre Filter (Segmented Control)
        genreFilter = UISegmentedControl(items: ["All", "Science", "Fiction", "History", "Art"])
        genreFilter.selectedSegmentIndex = 0
        genreFilter.addTarget(self, action: #selector(genreChanged), for: .valueChanged)
        genreFilter.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(genreFilter)
        
        NSLayoutConstraint.activate([
            genreFilter.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 10),
            genreFilter.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            genreFilter.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
        
        // Search Bar
        searchBar = UISearchBar()
        searchBar.placeholder = "Search Books"
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: genreFilter.bottomAnchor, constant: 20),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
        
        // Setup Collection View
        setupCollectionView()
        
        // Fetch initial books
        fetchBooks(query: "", genre: "")
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.bounds.width - 20, height: 100)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10

        collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(BookCell.self, forCellWithReuseIdentifier: "BookCell")
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func fetchBooks(query: String, genre: String) {
        var urlString = "https://www.googleapis.com/books/v1/volumes?q=\(query)"
        
        if genre != "All" {
            urlString += "+subject:\(genre)"
        }
        
        urlString += "&maxResults=20"
        
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error fetching books: \(error)")
                return
            }
            guard let data = data else { return }

            do {
                let result = try JSONDecoder().decode(BookSearchResponse.self, from: data)
                DispatchQueue.main.async {
                    self.books = result.items
                    self.filteredBooks = result.items // Initialize filteredBooks
                }
            } catch {
                print("Error decoding data: \(error)")
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

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        fetchBooks(query: searchText, genre: genreFilter.titleForSegment(at: genreFilter.selectedSegmentIndex) ?? "")
    }

    @objc func genreChanged() {
        fetchBooks(query: searchBar.text ?? "", genre: genreFilter.titleForSegment(at: genreFilter.selectedSegmentIndex) ?? "")
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
        containerView = UIView()
        containerView.layer.cornerRadius = 8
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowRadius = 4
        containerView.backgroundColor = .white
        contentView.addSubview(containerView)
        
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        containerView.addSubview(imageView)
        
        titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.numberOfLines = 2
        containerView.addSubview(titleLabel)
        
        authorLabel = UILabel()
        authorLabel.font = UIFont.systemFont(ofSize: 12)
        authorLabel.textColor = .gray
        containerView.addSubview(authorLabel)
        
        // Setup layout constraints
        containerView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 120),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            authorLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
            authorLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
    }
    
    func configure(with book: Book) {
        titleLabel.text = book.volumeInfo.title
        authorLabel.text = book.volumeInfo.authors?.joined(separator: ", ") ?? "Unknown Author"
        if let thumbnailURL = book.volumeInfo.imageLinks?.thumbnail, let url = URL(string: thumbnailURL) {
            imageView.loadImage(from: url)
        }
    }
}

// Extension to load image from URL asynchronously
extension UIImageView {
    func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }.resume()
    }
}
