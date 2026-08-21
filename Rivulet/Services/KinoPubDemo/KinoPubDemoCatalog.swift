#if DEBUG
//
//  KinoPubDemoCatalog.swift
//  Rivulet
//
//  The offline kino.pub catalogue: real titles, real synopses, real artwork
//  URLs, frozen into JSON. Nothing here talks to kino.pub at runtime — only the
//  image CDNs are hit, and only by the image loader.
//

import Foundation

struct KinoPubDemoCatalog: Decodable, Sendable {
    struct Person: Decodable, Sendable {
        let name: String
        let role: String?
        let kind: String?
        let imageURL: URL?
    }

    struct Item: Decodable, Sendable {
        let id: String
        let kind: String
        let title: String
        let originalTitle: String?
        let year: Int?
        let overview: String?
        let tagline: String?
        let genres: [String]
        let runtimeMinutes: Int?
        let officialRating: String?
        let imdbRating: Double?
        let kinopoiskRating: Double?
        let posterURL: URL?
        let posterWideURL: URL?
        let backdropURL: URL?
        let logoURL: URL?
        let people: [Person]
        let seasonCount: Int?

        var isSeries: Bool { kind == "series" }

        /// kino.pub reports an age gate as `age18`; the UI shows it verbatim.
        var displayRating: String? {
            guard let officialRating, officialRating.hasPrefix("age") else { return officialRating }
            return String(officialRating.dropFirst(3)) + "+"
        }

        var runtimeSeconds: TimeInterval? {
            runtimeMinutes.map { TimeInterval($0) * 60 }
        }

        var actors: [Person] { people.filter { ($0.kind ?? "").lowercased() == "actor" } }
        var directors: [Person] { people.filter { ($0.kind ?? "").lowercased() == "director" } }
        var writers: [Person] { people.filter { ($0.kind ?? "").lowercased() == "writer" } }
    }

    struct Row: Decodable, Sendable {
        let id: String
        let title: String
        let itemIDs: [String]
    }

    let items: [Item]
    let rows: [Row]
    /// Seconds already watched, for the Continue Watching rail.
    let resume: [String: Double]

    static let shared: KinoPubDemoCatalog = {
        guard let url = Bundle.main.url(forResource: "KinoPubDemoCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(KinoPubDemoCatalog.self, from: data)
        else {
            // A demo build with no catalogue is a broken build, not a degraded
            // one — an empty Home would read as a bug in the app.
            preconditionFailure("KinoPubDemoCatalog.json missing or unreadable")
        }
        return catalog
    }()

    private var index: [String: Item] {
        Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
    }

    func item(id: String) -> Item? { index[id] }

    func items(inRow id: String) -> [Item] {
        guard let row = rows.first(where: { $0.id == id }) else { return [] }
        let byID = index
        return row.itemIDs.compactMap { byID[$0] }
    }

    var movies: [Item] { items.filter { !$0.isSeries } }
    var series: [Item] { items.filter { $0.isSeries } }
}
#endif
