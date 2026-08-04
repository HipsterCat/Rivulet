// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Copyright (C) 2025-2026 Bain Gurley

#if DEBUG
//
//  MockDetailFixtures.swift
//  Rivulet
//
//  Hardcoded MediaItem / MediaItemDetail graph for the DEBUG detail template.
//  Artwork from m.staticpop.net so chrome + below-fold render without Plex.
//

import Foundation

enum MockDetailFixtures {
    static let providerID = "mock-detail"

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
    private static let thumbURL = wide(3)
    private static let logoURL = wide(4)
    private static let castURL = medium(5)
    private static let castBURL = medium(6)
    private static let castCURL = medium(7)

    // MARK: - Entry items

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

    static func movie() -> MediaItem {
        MediaItem(
            ref: MediaItemRef(providerID: providerID, itemID: "movie-1"),
            kind: .movie,
            title: "Riverlight",
            sortTitle: nil,
            overview: "A courier races a rising flood to deliver a sealed map before the locks close for good.",
            year: 2022,
            contentRating: "PG-13",
            runtime: 7_200,
            isMusic: false,
            parentRef: nil,
            grandparentRef: nil,
            episodeNumber: nil,
            seasonNumber: nil,
            childProgress: nil,
            userState: MediaUserState(isPlayed: false, viewOffset: 2_880, isFavorite: false, lastViewedAt: Date()),
            artwork: MediaArtwork(poster: posterBURL, backdrop: backdropURL, thumbnail: thumbURL, logo: logoURL),
            parentArtwork: nil,
            grandparentArtwork: nil
        )
    }

    static func episode() -> MediaItem {
        episode(id: "ep-3", title: "Undertow", number: 3, progress: 0.35)
    }

    // MARK: - Detail payloads

    static func showDetail() -> MediaItemDetail {
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
            mediaSources: [sampleSource(duration: 2_700)],
            trailerURL: nil,
            contentRating: "TV-14",
            regionOfOrigin: "United States",
            rating: 8.2,
            nextEpisode: episode(),
            collections: ["Sandbox Samples"],
            extras: [
                MediaItemDetail.Extra(
                    id: "trailer-1",
                    title: "Official Trailer",
                    thumbnailURL: thumbURL,
                    duration: 142,
                    playbackKey: nil,
                    subtype: .trailer
                ),
                MediaItemDetail.Extra(
                    id: "bts-1",
                    title: "Building the Lockhouse",
                    thumbnailURL: thumbURL,
                    duration: 310,
                    playbackKey: nil,
                    subtype: .behindTheScenes
                )
            ],
            contentAdvisory: ContentAdvisory(
                ageRating: "13+",
                starRating: 4.0,
                oneLiner: "A thoughtful adventure with mild peril.",
                parentsNeedToKnow: "Suspense and atmospheric danger; light language.",
                topics: [
                    ContentAdvisory.Topic(label: "Violence & Scariness", rating: 2, isPositive: false),
                    ContentAdvisory.Topic(label: "Positive Messages", rating: 4, isPositive: true)
                ]
            )
        )
    }

    static func movieDetail() -> MediaItemDetail {
        let item = movie()
        return MediaItemDetail(
            item: item,
            tagline: "The map remembers.",
            genres: ["Thriller", "Adventure"],
            studios: ["Rivulet Studios"],
            cast: castRow(),
            directors: [person(id: "d2", name: "Mira Cole", role: "Director", image: castCURL)],
            writers: [person(id: "w2", name: "Ellis Voss", role: "Writer", image: castURL)],
            chapters: [],
            mediaSources: [sampleSource(duration: 7_200)],
            trailerURL: nil,
            contentRating: "PG-13",
            regionOfOrigin: "Canada",
            rating: 7.4,
            nextEpisode: nil,
            collections: ["Sandbox Samples"],
            extras: [
                MediaItemDetail.Extra(
                    id: "trailer-movie",
                    title: "Trailer",
                    thumbnailURL: thumbURL,
                    duration: 118,
                    playbackKey: nil,
                    subtype: .trailer
                )
            ],
            contentAdvisory: ContentAdvisory(ageRating: "13+", starRating: 3.5, oneLiner: nil, parentsNeedToKnow: nil, topics: [])
        )
    }

    static func episodeDetail() -> MediaItemDetail {
        let item = episode()
        return MediaItemDetail(
            item: item,
            tagline: nil,
            genres: ["Adventure", "Mystery"],
            studios: ["Rivulet Studios"],
            cast: castRow(),
            directors: [person(id: "d1", name: "Lena Holt", role: "Director", image: castBURL)],
            writers: [],
            chapters: [],
            mediaSources: [sampleSource(duration: 2_700)],
            trailerURL: nil,
            contentRating: "TV-14",
            regionOfOrigin: "United States",
            rating: 8.0,
            nextEpisode: episode(id: "ep-4", title: "Silt", number: 4, progress: 0),
            collections: [],
            extras: [],
            contentAdvisory: nil
        )
    }

    // MARK: - Hierarchy / related

    static func seasons() -> [MediaItem] {
        [
            season(id: "season-1", number: 1, title: "Season 1"),
            season(id: "season-2", number: 2, title: "Season 2"),
            season(id: "season-3", number: 3, title: "Season 3")
        ]
    }

    static func allEpisodes() -> [MediaItem] {
        [
            episode(id: "ep-1", title: "First Confluence", number: 1, progress: 0, played: true),
            episode(id: "ep-2", title: "Lockhouse", number: 2, progress: 0, played: true),
            episode(id: "ep-3", title: "Undertow", number: 3, progress: 0.35),
            episode(id: "ep-4", title: "Silt", number: 4, progress: 0),
            episode(id: "ep-5", title: "Floodgate", number: 5, progress: 0)
        ]
    }

    static func related() -> [MediaItem] {
        [movie(), show(), movie(id: "movie-2", title: "Copper Sky", poster: posterCURL)]
    }

    static func castRow() -> [MediaPerson] {
        [
            person(id: "p1", name: "Ava Meridian", role: "Captain", image: castURL),
            person(id: "p2", name: "Jonah Reed", role: "Navigator", image: castBURL),
            person(id: "p3", name: "Sable Quinn", role: "Engineer", image: castCURL),
            person(id: "p4", name: "Theo Marsh", role: "Cartographer", image: castURL)
        ]
    }

    static func detail(for ref: MediaItemRef) -> MediaItemDetail? {
        switch ref.itemID {
        case "show-1": return showDetail()
        case "movie-1", "movie-2": return movieDetail().replacingItemID(ref.itemID)
        case let id where id.hasPrefix("ep-"): return episodeDetail().replacingItem(episodeMatching(id) ?? episode())
        case let id where id.hasPrefix("season-"):
            let seasons = seasons()
            guard let season = seasons.first(where: { $0.ref.itemID == id }) else { return nil }
            return MediaItemDetail(
                item: season,
                tagline: nil,
                genres: ["Adventure"],
                studios: ["Rivulet Studios"],
                cast: castRow(),
                directors: [],
                writers: [],
                chapters: [],
                mediaSources: [],
                trailerURL: nil,
                contentRating: "TV-14",
                regionOfOrigin: "United States",
                rating: nil,
                nextEpisode: nil,
                collections: []
            )
        default:
            return nil
        }
    }

    // MARK: - Helpers

    private static func season(id: String, number: Int, title: String) -> MediaItem {
        MediaItem(
            ref: MediaItemRef(providerID: providerID, itemID: id),
            kind: .season,
            title: title,
            sortTitle: nil,
            overview: nil,
            year: 2023,
            contentRating: "TV-14",
            runtime: nil,
            isMusic: false,
            parentRef: MediaItemRef(providerID: providerID, itemID: "show-1"),
            grandparentRef: nil,
            episodeNumber: nil,
            seasonNumber: number,
            childProgress: ChildProgress(played: number == 1 ? 2 : 0, total: 5),
            userState: MediaUserState(isPlayed: false, viewOffset: 0, isFavorite: false, lastViewedAt: nil),
            artwork: MediaArtwork(poster: posterURL, backdrop: backdropURL, thumbnail: thumbURL, logo: nil),
            parentArtwork: MediaArtwork(poster: posterURL, backdrop: backdropURL, thumbnail: thumbURL, logo: logoURL),
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
        let runtime: TimeInterval = 2_700
        let offset = progress > 0 && progress < 1 ? runtime * progress : 0
        return MediaItem(
            ref: MediaItemRef(providerID: providerID, itemID: id),
            kind: .episode,
            title: title,
            sortTitle: nil,
            overview: "The crew maps a dead canal and finds lights still burning in the lockhouse.",
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
                lastViewedAt: progress > 0 ? Date() : nil
            ),
            artwork: MediaArtwork(poster: nil, backdrop: nil, thumbnail: thumbURL, logo: nil),
            parentArtwork: showArt,
            grandparentArtwork: showArt
        )
    }

    private static func movie(id: String, title: String, poster: URL) -> MediaItem {
        MediaItem(
            ref: MediaItemRef(providerID: providerID, itemID: id),
            kind: .movie,
            title: title,
            sortTitle: nil,
            overview: "A sandbox stand-in for the related row.",
            year: 2021,
            contentRating: "PG-13",
            runtime: 6_300,
            isMusic: false,
            parentRef: nil,
            grandparentRef: nil,
            episodeNumber: nil,
            seasonNumber: nil,
            childProgress: nil,
            userState: MediaUserState(isPlayed: false, viewOffset: 0, isFavorite: false, lastViewedAt: nil),
            artwork: MediaArtwork(poster: poster, backdrop: backdropURL, thumbnail: thumbURL, logo: logoURL),
            parentArtwork: nil,
            grandparentArtwork: nil
        )
    }

    private static func episodeMatching(_ id: String) -> MediaItem? {
        allEpisodes().first(where: { $0.ref.itemID == id })
    }

    private static func person(id: String, name: String, role: String, image: URL?) -> MediaPerson {
        MediaPerson(id: id, name: name, role: role, imageURL: image)
    }

    private static func sampleSource(duration: TimeInterval) -> MediaSource {
        MediaSource(
            id: "source-1",
            container: "mkv",
            duration: duration,
            bitrate: 28_000_000,
            fileSize: 12_000_000_000,
            fileName: "4K HDR",
            videoResolution: "4k",
            videoTracks: [
                VideoTrack(
                    id: "v1",
                    codec: "hevc",
                    profile: "Main 10",
                    level: 150,
                    width: 3840,
                    height: 2160,
                    frameRate: 23.976,
                    bitrate: 22_000_000,
                    videoRange: .hdr10,
                    isDefault: true,
                    scanType: "progressive"
                )
            ],
            audioTracks: [
                AudioTrack(
                    id: "a1",
                    index: 1,
                    codec: "eac3",
                    profile: nil,
                    channels: 6,
                    channelLayout: "5.1(side)",
                    language: "en",
                    title: "English",
                    extendedTitle: "English (E-AC3 5.1)",
                    bitrate: 768_000,
                    samplingRate: 48_000,
                    isDefault: true,
                    isForced: false,
                    isSelected: true
                )
            ],
            subtitleTracks: [
                SubtitleTrack(
                    id: "s1",
                    index: 2,
                    codec: "srt",
                    language: "en",
                    title: "English",
                    extendedTitle: "English (SRT)",
                    isDefault: false,
                    isForced: false,
                    isHearingImpaired: false,
                    isEmbedded: true,
                    externalURL: nil,
                    isSelected: false
                )
            ],
            streamKind: .directPlay,
            streamURL: nil
        )
    }
}

private extension MediaItemDetail {
    func replacingItemID(_ itemID: String) -> MediaItemDetail {
        MediaItemDetail(
            item: MediaItem(
                ref: MediaItemRef(providerID: item.ref.providerID, itemID: itemID),
                kind: item.kind,
                title: item.title,
                sortTitle: item.sortTitle,
                overview: item.overview,
                year: item.year,
                releaseDate: item.releaseDate,
                contentRating: item.contentRating,
                runtime: item.runtime,
                isMusic: item.isMusic,
                parentRef: item.parentRef,
                grandparentRef: item.grandparentRef,
                episodeNumber: item.episodeNumber,
                seasonNumber: item.seasonNumber,
                childProgress: item.childProgress,
                userState: item.userState,
                artwork: item.artwork,
                parentArtwork: item.parentArtwork,
                grandparentArtwork: item.grandparentArtwork
            ),
            tagline: tagline,
            genres: genres,
            studios: studios,
            cast: cast,
            directors: directors,
            writers: writers,
            chapters: chapters,
            mediaSources: mediaSources,
            trailerURL: trailerURL,
            contentRating: contentRating,
            regionOfOrigin: regionOfOrigin,
            rating: rating,
            nextEpisode: nextEpisode,
            collections: collections,
            extras: extras,
            contentAdvisory: contentAdvisory
        )
    }

    func replacingItem(_ item: MediaItem) -> MediaItemDetail {
        MediaItemDetail(
            item: item,
            tagline: tagline,
            genres: genres,
            studios: studios,
            cast: cast,
            directors: directors,
            writers: writers,
            chapters: chapters,
            mediaSources: mediaSources,
            trailerURL: trailerURL,
            contentRating: contentRating,
            regionOfOrigin: regionOfOrigin,
            rating: rating,
            nextEpisode: nextEpisode,
            collections: collections,
            extras: extras,
            contentAdvisory: contentAdvisory
        )
    }
}
#endif
