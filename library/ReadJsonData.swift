//
//  ReadJsonData.swift
//  library
//
//  Created by Shafi on 1/9/25.
//

import Foundation

// MARK: - Book
struct Books: Codable, Identifiable {
    let id: Int
    let title, author, edition, published: String
    let pages, publisher: String
    let categories: [String]
    let description: String
    let img: String
    static let allBooks: [Books] = Bundle.main.decode(file: "BookDetails.json")
    static let sampleBook: Books = allBooks[0]
}

extension Bundle {
    func decode<T:Decodable>(file: String) -> T {
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("Could not find \(file) in bundle")
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Could not load \(file) fron bundle")
        }
        let decoder = JSONDecoder()
        guard let loadedData = try? decoder.decode(T.self, from: data) else {
            fatalError("Could not decode \(file) from bundle")
        }
        return loadedData
    }
}
