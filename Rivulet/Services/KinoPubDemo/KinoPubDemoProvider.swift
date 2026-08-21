#if DEBUG
//
//  KinoPubDemoProvider.swift
//  Rivulet
//
//  A MediaProvider over the offline kino.pub catalogue, registered into the
//  ordinary registry so the real detail surfaces resolve without Plex —
//  the same seam MockDetailProvider uses, with real Russian content behind it.
//

import Foundation

final class KinoPubDemoProvider: MediaProvider, @unchecked Sendable {
    static let providerID = "kinopub-demo"

    nonisolated let id = KinoPubDemoProvider.providerID
    nonisolated let kind = MediaProviderKind.plex
    nonisolated let displayName = "kino.pub"
    let connectionState = ConnectionState.connected
    let supportsWatchlist = true

    private let catalog = KinoPubDemoCatalog.shared
    private var watchlistIDs: Set<String> = []

    // MARK: - Browse

    func libraries() async throws -> [MediaLibrary] {
        [
            MediaLibrary(id: "kinopub-movies", providerID: id, title: "Фильмы", kind: .movies),
            MediaLibrary(id: "kinopub-series", providerID: id, title: "Сериалы", kind: .shows),
        ]
    }

    func items(
        in library: MediaLibrary,
        sort: SortOption,
        page: Page
    ) async throws -> PagedResult<MediaItem> {
        let pool = library.id == "kinopub-series" ? catalog.series : catalog.movies
        let mapped = pool.map(mediaItem)
        return PagedResult(items: mapped, total: mapped.count, nextPage: nil)
    }

    /// Series get synthesised seasons, and seasons synthesised episodes — the
    /// catalogue stops at the title, and a series page with no children reads as
    /// a dead end rather than as a design to judge.
    func children(of itemRef: MediaItemRef) async throws -> [MediaItem] {
        if let raw = catalog.item(id: itemRef.itemID), raw.isSeries {
            return (1...(raw.seasonCount ?? 1)).map { season(raw, number: $0) }
        }
        if let (raw, number) = parseSeason(itemRef.itemID) {
            return (1...8).map { episode(raw, season: number, number: $0) }
        }
        return []
    }

    func allEpisodes(of showRef: MediaItemRef) async throws -> [MediaItem] {
        guard let raw = catalog.item(id: showRef.itemID), raw.isSeries else { return [] }
        return (1...(raw.seasonCount ?? 1)).flatMap { seasonNumber in
            (1...8).map { episode(raw, season: seasonNumber, number: $0) }
        }
    }

    func search(_ query: String) async throws -> [MediaItem] {
        let needle = query.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return [] }
        return catalog.items.filter {
            $0.title.localizedCaseInsensitiveContains(needle)
                || ($0.originalTitle?.localizedCaseInsensitiveContains(needle) ?? false)
                || $0.genres.contains { $0.localizedCaseInsensitiveContains(needle) }
        }.map(mediaItem)
    }

    func collectionItems(
        matching collectionName: String,
        in library: MediaLibrary
    ) async throws -> [MediaItem] {
        catalog.items.filter { $0.genres.contains(collectionName) }.map(mediaItem)
    }

    func relatedItems(for itemRef: MediaItemRef) async throws -> [MediaItem] {
        guard let raw = catalog.item(id: itemRef.itemID) else { return [] }
        let genres = Set(raw.genres)
        return catalog.items
            .filter { $0.id != raw.id && !genres.isDisjoint(with: $0.genres) }
            .prefix(20)
            .map(mediaItem)
    }

    // MARK: - Detail

    func fullDetail(for itemRef: MediaItemRef) async throws -> MediaItemDetail {
        guard let raw = catalog.item(id: baseID(of: itemRef.itemID)) else {
            throw MediaProviderError.notFound
        }
        let item = mediaItem(raw)
        return MediaItemDetail(
            item: item,
            tagline: raw.tagline,
            genres: raw.genres.map { $0.capitalized },
            studios: [],
            cast: raw.actors.enumerated().map { person(raw, index: $0.offset, person: $0.element) },
            directors: raw.directors.enumerated().map {
                person(raw, index: 900 + $0.offset, person: $0.element)
            },
            writers: raw.writers.enumerated().map {
                person(raw, index: 800 + $0.offset, person: $0.element)
            },
            chapters: [],
            mediaSources: [],
            trailerURL: nil,
            contentRating: raw.displayRating,
            rating: raw.kinopoiskRating ?? raw.imdbRating,
            nextEpisode: raw.isSeries ? episode(raw, season: 1, number: 1) : nil,
            collections: []
        )
    }

    // MARK: - Home rails

    func continueWatching(limit: Int) async throws -> [MediaItem] {
        Array(catalog.items(inRow: "continue").map(mediaItem).prefix(limit))
    }

    func recentlyAdded(limit: Int) async throws -> [MediaItem] {
        Array(catalog.items(inRow: "latest").map(mediaItem).prefix(limit))
    }

    func hubs() async throws -> [MediaHub] {
        catalog.rows.map { row in
            MediaHub(
                id: row.id,
                providerID: id,
                title: row.title.capitalized,
                style: .shelf,
                items: catalog.items(inRow: row.id).map(mediaItem)
            )
        }
    }

    func hubs(in library: MediaLibrary) async throws -> [MediaHub] {
        let wantsSeries = library.id == "kinopub-series"
        return try await hubs()
            .filter { $0.id.hasPrefix("genre-") }
            .map { hub in
                MediaHub(
                    id: "\(library.id)-\(hub.id)",
                    providerID: id,
                    title: hub.title,
                    style: .shelf,
                    items: hub.items.filter { ($0.kind == .show) == wantsSeries }
                )
            }
            .filter { $0.items.count >= 4 }
    }

    // MARK: - Playback and state (deliberately inert)

    func resolveStream(for itemRef: MediaItemRef, sourceID: String?) async throws -> StreamInfo {
        throw MediaProviderError.notPlayable
    }

    func progressReporter(for itemRef: MediaItemRef, playSessionID: String?) -> any ProgressReporter {
        KinoPubDemoProgressReporter()
    }

    func setSelectedAudioTrack(
        _ trackID: String,
        source sourceID: String,
        of itemRef: MediaItemRef
    ) async throws {}

    func setSelectedSubtitleTrack(
        _ trackID: String?,
        source sourceID: String,
        of itemRef: MediaItemRef
    ) async throws {}

    func markPlayed(_ itemRef: MediaItemRef) async throws {}
    func markUnplayed(_ itemRef: MediaItemRef) async throws {}
    func updateProgress(_ itemRef: MediaItemRef, position: TimeInterval) async throws {}

    func isOnWatchlist(_ ref: MediaItemRef) async -> Bool { watchlistIDs.contains(ref.itemID) }
    func addToWatchlist(_ ref: MediaItemRef) async throws { watchlistIDs.insert(ref.itemID) }
    func removeFromWatchlist(_ ref: MediaItemRef) async throws { watchlistIDs.remove(ref.itemID) }

    func contentAdvisory(for ref: MediaItemRef) async throws -> ContentAdvisory? { nil }

    // MARK: - Mapping

    private func ref(_ itemID: String) -> MediaItemRef {
        MediaItemRef(providerID: id, itemID: itemID)
    }

    /// Season and episode ids encode their parent, so any ref can be resolved
    /// back to a catalogue entry without a lookup table.
    private func baseID(of itemID: String) -> String {
        itemID.split(separator: ":").first.map(String.init) ?? itemID
    }

    private func parseSeason(_ itemID: String) -> (KinoPubDemoCatalog.Item, Int)? {
        let parts = itemID.split(separator: ":")
        guard parts.count == 3, parts[1] == "s",
              let number = Int(parts[2]),
              let raw = catalog.item(id: String(parts[0]))
        else { return nil }
        return (raw, number)
    }

    private func artwork(_ raw: KinoPubDemoCatalog.Item) -> MediaArtwork {
        MediaArtwork(
            poster: raw.posterURL,
            backdrop: raw.backdropURL ?? raw.posterWideURL,
            thumbnail: raw.posterWideURL,
            logo: raw.logoURL
        )
    }

    func mediaItem(_ raw: KinoPubDemoCatalog.Item) -> MediaItem {
        let watched = catalog.resume[raw.id]
        return MediaItem(
            ref: ref(raw.id),
            kind: raw.isSeries ? .show : .movie,
            title: raw.title,
            sortTitle: nil,
            overview: raw.overview,
            year: raw.year,
            contentRating: raw.displayRating,
            runtime: raw.isSeries ? nil : raw.runtimeSeconds,
            isMusic: false,
            parentRef: nil,
            grandparentRef: nil,
            episodeNumber: nil,
            seasonNumber: nil,
            childProgress: raw.isSeries
                ? ChildProgress(played: 0, total: (raw.seasonCount ?? 1) * 8)
                : nil,
            userState: MediaUserState(
                isPlayed: false,
                viewOffset: watched ?? 0,
                isFavorite: false,
                lastViewedAt: watched == nil ? nil : Date()
            ),
            artwork: artwork(raw),
            parentArtwork: nil,
            grandparentArtwork: nil
        )
    }

    private func season(_ raw: KinoPubDemoCatalog.Item, number: Int) -> MediaItem {
        MediaItem(
            ref: ref("\(raw.id):s:\(number)"),
            kind: .season,
            title: "Сезон \(number)",
            sortTitle: nil,
            overview: nil,
            year: raw.year.map { $0 + number - 1 },
            contentRating: raw.displayRating,
            runtime: nil,
            isMusic: false,
            parentRef: ref(raw.id),
            grandparentRef: nil,
            episodeNumber: nil,
            seasonNumber: number,
            childProgress: ChildProgress(played: 0, total: 8),
            userState: MediaUserState(isPlayed: false, viewOffset: 0, isFavorite: false, lastViewedAt: nil),
            artwork: artwork(raw),
            parentArtwork: artwork(raw),
            grandparentArtwork: nil
        )
    }

    private func episode(_ raw: KinoPubDemoCatalog.Item, season: Int, number: Int) -> MediaItem {
        MediaItem(
            ref: ref("\(raw.id):e:\(season).\(number)"),
            kind: .episode,
            title: "Серия \(number)",
            sortTitle: nil,
            overview: nil,
            year: raw.year,
            contentRating: raw.displayRating,
            runtime: 45 * 60,
            isMusic: false,
            parentRef: ref("\(raw.id):s:\(season)"),
            grandparentRef: ref(raw.id),
            episodeNumber: number,
            seasonNumber: season,
            childProgress: nil,
            userState: MediaUserState(isPlayed: false, viewOffset: 0, isFavorite: false, lastViewedAt: nil),
            artwork: MediaArtwork(
                poster: raw.posterWideURL,
                backdrop: raw.backdropURL,
                thumbnail: raw.posterWideURL,
                logo: raw.logoURL
            ),
            parentArtwork: artwork(raw),
            grandparentArtwork: artwork(raw)
        )
    }

    private func person(
        _ raw: KinoPubDemoCatalog.Item,
        index: Int,
        person: KinoPubDemoCatalog.Person
    ) -> MediaPerson {
        MediaPerson(
            id: "\(raw.id)-p\(index)",
            name: person.name,
            role: person.role,
            imageURL: person.imageURL
        )
    }
}

struct KinoPubDemoProgressReporter: ProgressReporter {
    func start() async {}
    func progress(position: TimeInterval) async {}
    func paused(at position: TimeInterval) async {}
    func stopped(at position: TimeInterval) async {}
}
#endif
