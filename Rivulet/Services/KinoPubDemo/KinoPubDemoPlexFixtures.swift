#if DEBUG
//
//  KinoPubDemoPlexFixtures.swift
//  Rivulet
//
//  The demo signs in against a server that does not exist, so every refresh
//  PlexDataStore kicks off would fail and repaint an error over the seeded
//  rails. These answer those three fetches in the Plex shape instead.
//
//  Artwork stays absolute: `PlexMediaMapper.artworkURL` passes absolute URLs
//  through untouched, so the CDN links need no proxying.
//

import Foundation

enum KinoPubDemoPlexFixtures {
    private static var catalog: KinoPubDemoCatalog { .shared }

    static func hubs() -> [PlexHub] {
        catalog.rows.map { row in
            PlexHub(
                hubIdentifier: row.id == "continue" ? "continueWatching" : "kinopub.\(row.id)",
                title: row.title.capitalized,
                type: "mixed",
                hubKey: "/kinopub/\(row.id)",
                key: "/kinopub/\(row.id)",
                more: false,
                size: row.itemIDs.count,
                promoted: true,
                Metadata: catalog.items(inRow: row.id).map(metadata)
            )
        }
    }

    static func continueWatchingHub() -> PlexHub? {
        hubs().first { $0.hubIdentifier == "continueWatching" }
    }

    static func libraries() -> [PlexLibrary] {
        [
            library(key: KinoPubDemo.moviesKey, type: "movie", title: "Фильмы"),
            library(key: KinoPubDemo.seriesKey, type: "show", title: "Сериалы"),
        ]
    }

    private static func library(key: String, type: String, title: String) -> PlexLibrary {
        PlexLibrary(
            key: key,
            type: type,
            title: title,
            agent: "tv.plex.agents.kinopub",
            scanner: "KinoPub Demo",
            language: "ru-RU",
            uuid: "\(key)-uuid",
            updatedAt: nil,
            createdAt: nil,
            scannedAt: nil,
            Location: nil
        )
    }

    static func metadata(_ raw: KinoPubDemoCatalog.Item) -> PlexMetadata {
        var meta = PlexMetadata()
        meta.ratingKey = raw.id
        meta.key = "/library/metadata/\(raw.id)"
        meta.guid = "kinopub://\(raw.id)"
        meta.type = raw.isSeries ? "show" : "movie"
        meta.title = raw.title
        meta.originalTitle = raw.originalTitle
        meta.summary = raw.overview
        meta.tagline = raw.tagline
        meta.year = raw.year
        meta.contentRating = raw.displayRating
        meta.rating = raw.imdbRating
        meta.audienceRating = raw.kinopoiskRating
        meta.thumb = raw.posterURL?.absoluteString
        meta.art = (raw.backdropURL ?? raw.posterWideURL)?.absoluteString
        meta.Image = raw.logoURL.map {
            [PlexImage(alt: raw.title, type: "clearLogo", url: $0.absoluteString)]
        }
        meta.Genre = raw.genres.map { PlexTag(tag: $0.capitalized) }
        meta.duration = raw.runtimeMinutes.map { $0 * 60_000 }
        meta.librarySectionTitle = raw.isSeries ? "Сериалы" : "Фильмы"
        meta.Role = raw.actors.prefix(18).map {
            PlexRole(tag: $0.name, role: $0.role, thumb: $0.imageURL?.absoluteString)
        }
        if raw.isSeries {
            meta.childCount = raw.seasonCount
            meta.leafCount = (raw.seasonCount ?? 1) * 8
            meta.viewedLeafCount = 0
        }
        // Resume positions exist only for the Continue Watching rail; the value
        // is what makes its progress bars render at all.
        if let watched = catalog.resume[raw.id] {
            meta.viewOffset = Int(watched * 1000)
            meta.viewCount = 0
        }
        return meta
    }

    // MARK: - Paged answers for the calls Home, library pages and search make

    /// `hubKey` is what `hubs()` handed out: `/kinopub/<row id>`.
    static func hubItems(hubKey: String, start: Int, count: Int) -> (items: [PlexMetadata], totalSize: Int?) {
        let rowID = hubKey
            .replacingOccurrences(of: "/kinopub/", with: "")
            .replacingOccurrences(of: "kinopub-", with: "")
        let all = catalog.items(inRow: rowID).map(metadata)
        return (page(all, start: start, count: count), all.count)
    }

    static func sectionItems(sectionId: String, start: Int, size: Int) -> (items: [PlexMetadata], totalSize: Int?) {
        let pool = sectionId == KinoPubDemo.seriesKey ? catalog.series : catalog.movies
        let all = pool.map(metadata)
        return (page(all, start: start, count: size), all.count)
    }

    static func libraryHubs(sectionId: String, count: Int) -> [PlexHub] {
        let wantsSeries = sectionId == KinoPubDemo.seriesKey
        return catalog.rows
            .filter { $0.id.hasPrefix("genre-") }
            .map { row in
                let items = catalog.items(inRow: row.id)
                    .filter { $0.isSeries == wantsSeries }
                    .prefix(count)
                    .map(metadata)
                return PlexHub(
                    hubIdentifier: "kinopub.\(sectionId).\(row.id)",
                    title: row.title.capitalized,
                    type: wantsSeries ? "show" : "movie",
                    hubKey: "/kinopub/\(row.id)",
                    key: "/kinopub/\(row.id)",
                    more: false,
                    size: items.count,
                    Metadata: Array(items)
                )
            }
            .filter { ($0.Metadata?.count ?? 0) >= 4 }
    }

    static func search(_ query: String, limit: Int) -> [PlexMetadata] {
        let needle = query.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return [] }
        return catalog.items.filter {
            $0.title.localizedCaseInsensitiveContains(needle)
                || ($0.originalTitle?.localizedCaseInsensitiveContains(needle) ?? false)
                || $0.genres.contains { $0.localizedCaseInsensitiveContains(needle) }
        }
        .prefix(limit)
        .map(metadata)
    }

    private static func page(_ all: [PlexMetadata], start: Int, count: Int) -> [PlexMetadata] {
        guard start < all.count else { return [] }
        return Array(all[start..<min(start + count, all.count)])
    }
}
#endif
