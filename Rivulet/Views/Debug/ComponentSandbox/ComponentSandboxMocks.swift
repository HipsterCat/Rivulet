// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Copyright (C) 2025-2026 Bain Gurley

#if DEBUG
//
//  ComponentSandboxMocks.swift
//  Rivulet
//
//  Hardcoded MediaItem / MediaPerson / MediaItemDetail factories for the
//  DEBUG Components tab. Artwork from m.staticpop.net so cells load
//  without a Plex server or token.
//

import Foundation

enum ComponentSandboxMocks {
    static let providerID = "sandbox"

    // staticpop CDN — `medium` = vertical poster, `wide` = landscape art.
    private static func medium(_ n: Int) -> URL {
        URL(string: "https://m.staticpop.net/poster/item/medium/\(n).jpg")!
    }
    private static func wide(_ n: Int) -> URL {
        URL(string: "https://m.staticpop.net/poster/item/wide/\(n).jpg")!
    }

    private static let posterURL = medium(1)
    private static let posterBURL = medium(2)
    private static let posterCURL = medium(3)
    private static let backdropURL = wide(1)
    private static let backdropBURL = wide(2)
    private static let thumbURL = wide(3)
    private static let logoURL = wide(4)
    private static let castURL = medium(5)
    private static let castBURL = medium(6)
    private static let castCURL = medium(7)
    private static let musicURL = medium(8)

    // MARK: - Movies / music

    static func movieUnwatched() -> MediaItem {
        movie(
            id: "movie-unwatched",
            title: "Riverlight",
            progress: 0,
            played: false,
            poster: posterURL
        )
    }

    static func movieInProgress() -> MediaItem {
        movie(
            id: "movie-progress",
            title: "Night Harbor",
            progress: 0.42,
            played: false,
            poster: posterBURL,
            runtime: 7200
        )
    }

    static func movieWatched() -> MediaItem {
        movie(
            id: "movie-watched",
            title: "Copper Sky",
            progress: 0,
            played: true,
            poster: posterCURL
        )
    }

    static func musicAlbum() -> MediaItem {
        MediaItem(
            ref: MediaItemRef(providerID: providerID, itemID: "album-1"),
            kind: .unknown,
            title: "Tidal EP",
            sortTitle: nil,
            overview: "Instrumental sketches.",
            year: 2024,
            contentRating: nil,
            runtime: nil,
            isMusic: true,
            parentRef: nil,
            grandparentRef: nil,
            episodeNumber: nil,
            seasonNumber: nil,
            childProgress: nil,
            userState: MediaUserState(isPlayed: false, viewOffset: 0, isFavorite: true, lastViewedAt: nil),
            artwork: MediaArtwork(poster: musicURL, backdrop: nil, thumbnail: musicURL, logo: nil),
            parentArtwork: nil,
            grandparentArtwork: nil
        )
    }

    // MARK: - Show / episode / CW

    static func show() -> MediaItem {
        MediaItem(
            ref: MediaItemRef(providerID: providerID, itemID: "show-1"),
            kind: .show,
            title: "Rivulet",
            sortTitle: nil,
            overview: "A crew charts forgotten waterways while something below the surface wakes.",
            year: 2023,
            contentRating: "TV-14",
            runtime: nil,
            isMusic: false,
            parentRef: nil,
            grandparentRef: nil,
            episodeNumber: nil,
            seasonNumber: nil,
            childProgress: ChildProgress(played: 4, total: 10),
            userState: MediaUserState(isPlayed: false, viewOffset: 0, isFavorite: true, lastViewedAt: Date()),
            artwork: MediaArtwork(poster: posterURL, backdrop: backdropURL, thumbnail: thumbURL, logo: logoURL),
            parentArtwork: nil,
            grandparentArtwork: nil
        )
    }

    static func episode(inProgress: Bool) -> MediaItem {
        let showArt = MediaArtwork(poster: posterURL, backdrop: backdropURL, thumbnail: thumbURL, logo: logoURL)
        let runtime: TimeInterval = 2700
        let offset: TimeInterval = inProgress ? runtime * 0.35 : 0
        return MediaItem(
            ref: MediaItemRef(providerID: providerID, itemID: inProgress ? "ep-progress" : "ep-1"),
            kind: .episode,
            title: inProgress ? "Undertow" : "First Confluence",
            sortTitle: nil,
            overview: "The crew maps a dead canal and finds lights still burning in the lockhouse.",
            year: 2023,
            contentRating: "TV-14",
            runtime: runtime,
            isMusic: false,
            parentRef: MediaItemRef(providerID: providerID, itemID: "season-1"),
            grandparentRef: MediaItemRef(providerID: providerID, itemID: "show-1"),
            episodeNumber: inProgress ? 3 : 1,
            seasonNumber: 1,
            childProgress: nil,
            userState: MediaUserState(
                isPlayed: false,
                viewOffset: offset,
                isFavorite: false,
                lastViewedAt: inProgress ? Date() : nil
            ),
            artwork: MediaArtwork(poster: nil, backdrop: nil, thumbnail: thumbURL, logo: nil),
            parentArtwork: showArt,
            grandparentArtwork: showArt
        )
    }

    static func continueWatchingItems() -> [MediaItem] {
        [
            episode(inProgress: true),
            movieInProgress().withBackdrop(backdropBURL),
            movie(
                id: "cw-movie-2",
                title: "Glass Current",
                progress: 0.68,
                played: false,
                poster: posterCURL,
                runtime: 5400
            ).withBackdrop(backdropURL)
        ]
    }

    // MARK: - Rows

    static func posterRow() -> [MediaItem] {
        [movieUnwatched(), movieInProgress(), movieWatched(), musicAlbum(), show()]
    }

    static func watchlistRow() -> [MediaItem] {
        [movieUnwatched(), show(), movieWatched()]
    }

    static func relatedRow() -> [MediaItem] {
        [movieUnwatched(), movieInProgress(), movieWatched(), show()]
    }

    static func episodeRow() -> [MediaItem] {
        [
            episode(inProgress: false),
            episode(inProgress: true),
            episode(id: "ep-2", title: "Lockhouse", number: 2, progress: 0),
            episode(id: "ep-4", title: "Silt", number: 4, progress: 0, played: true)
        ]
    }

    static func seasonLabels() -> [(label: String, selected: Bool)] {
        [
            ("Season 1", true),
            ("Season 2", false),
            ("Season 3", false),
            ("Specials", false)
        ]
    }

    static func castRow() -> [MediaPerson] {
        [
            person(id: "p1", name: "Ava Meridian", role: "Captain", image: castURL),
            person(id: "p2", name: "Jonah Reed", role: "Navigator", image: castBURL),
            person(id: "p3", name: "Sable Quinn", role: "Engineer", image: castCURL),
            person(id: "p4", name: "Theo Marsh", role: "Cartographer", image: castURL)
        ]
    }

    static func detail() -> MediaItemDetail {
        let item = show()
        return MediaItemDetail(
            item: item,
            tagline: "Follow the water.",
            genres: ["Adventure", "Mystery", "Sci-Fi"],
            studios: ["Rivulet Studios"],
            cast: castRow(),
            directors: [person(id: "d1", name: "Lena Holt", role: "Director", image: castBURL)],
            writers: [person(id: "w1", name: "Kai Novak", role: "Writer", image: nil)],
            chapters: [],
            mediaSources: [],
            trailerURL: nil,
            contentRating: "TV-14",
            regionOfOrigin: "United States",
            rating: 8.2,
            nextEpisode: episode(inProgress: true),
            collections: ["Sandbox Samples"]
        )
    }

    // MARK: - Up Next / actor

    /// Stub season for `UpNextListView`. Thumbs stay nil (no Plex transcode
    /// server in the sandbox) — rows still show watched / now / up-next states.
    static func upNextEpisodes() -> [PlexMetadata] {
        (1...5).map { n in
            PlexMetadata(
                ratingKey: "upnext-\(n)",
                type: "episode",
                title: ["First Confluence", "Lockhouse", "Undertow", "Silt", "Floodgate"][n - 1],
                summary: "Sandbox episode for the Up Next rail.",
                duration: 2_700_000,
                parentIndex: 1,
                grandparentTitle: "Rivulet",
                index: n,
                viewCount: n <= 2 ? 1 : 0
            )
        }
    }

    static let upNextCurrentRatingKey = "upnext-3"

    static func actorPortraitURL() -> URL { castURL }

    static func actorBiography() -> String {
        "Ava Meridian charts forgotten waterways for a living and still gets lost on purpose. "
            + "Between lockhouses and silt beds she keeps a notebook of lights that shouldn't be on."
    }

    // MARK: - Helpers

    private static func movie(
        id: String,
        title: String,
        progress: Double,
        played: Bool,
        poster: URL,
        runtime: TimeInterval = 6300
    ) -> MediaItem {
        let offset = progress > 0 && progress < 1 ? runtime * progress : 0
        return MediaItem(
            ref: MediaItemRef(providerID: providerID, itemID: id),
            kind: .movie,
            title: title,
            sortTitle: nil,
            overview: "A sandbox stand-in so UIKit cells can be focused without Plex.",
            year: 2022,
            contentRating: "PG-13",
            runtime: runtime,
            isMusic: false,
            parentRef: nil,
            grandparentRef: nil,
            episodeNumber: nil,
            seasonNumber: nil,
            childProgress: nil,
            userState: MediaUserState(
                isPlayed: played,
                viewOffset: offset,
                isFavorite: false,
                lastViewedAt: progress > 0 ? Date() : nil
            ),
            artwork: MediaArtwork(poster: poster, backdrop: backdropURL, thumbnail: thumbURL, logo: logoURL),
            parentArtwork: nil,
            grandparentArtwork: nil
        )
    }

    private static func episode(
        id: String,
        title: String,
        number: Int,
        progress: Double,
        played: Bool = false
    ) -> MediaItem {
        let showArt = MediaArtwork(poster: posterURL, backdrop: backdropURL, thumbnail: thumbURL, logo: logoURL)
        let runtime: TimeInterval = 2700
        let offset = progress > 0 && progress < 1 ? runtime * progress : 0
        return MediaItem(
            ref: MediaItemRef(providerID: providerID, itemID: id),
            kind: .episode,
            title: title,
            sortTitle: nil,
            overview: "Episode synopsis for the sandbox rail.",
            year: 2023,
            contentRating: "TV-14",
            runtime: runtime,
            isMusic: false,
            parentRef: MediaItemRef(providerID: providerID, itemID: "season-1"),
            grandparentRef: MediaItemRef(providerID: providerID, itemID: "show-1"),
            episodeNumber: number,
            seasonNumber: 1,
            childProgress: nil,
            userState: MediaUserState(
                isPlayed: played,
                viewOffset: offset,
                isFavorite: false,
                lastViewedAt: nil
            ),
            artwork: MediaArtwork(poster: nil, backdrop: nil, thumbnail: thumbURL, logo: nil),
            parentArtwork: showArt,
            grandparentArtwork: showArt
        )
    }

    private static func person(id: String, name: String, role: String, image: URL?) -> MediaPerson {
        MediaPerson(id: id, name: name, role: role, imageURL: image)
    }
}

private extension MediaItem {
    func withBackdrop(_ url: URL) -> MediaItem {
        MediaItem(
            ref: ref,
            kind: kind,
            title: title,
            sortTitle: sortTitle,
            overview: overview,
            year: year,
            releaseDate: releaseDate,
            contentRating: contentRating,
            runtime: runtime,
            isMusic: isMusic,
            parentRef: parentRef,
            grandparentRef: grandparentRef,
            episodeNumber: episodeNumber,
            seasonNumber: seasonNumber,
            childProgress: childProgress,
            userState: userState,
            artwork: MediaArtwork(
                poster: artwork.poster,
                backdrop: url,
                thumbnail: artwork.thumbnail,
                logo: artwork.logo
            ),
            parentArtwork: parentArtwork,
            grandparentArtwork: grandparentArtwork
        )
    }
}
#endif
