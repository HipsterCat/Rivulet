// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Copyright (C) 2025-2026 Bain Gurley

#if DEBUG
//
//  MockDetailProvider.swift
//  Rivulet
//
//  In-memory MediaProvider that feeds the real detail surfaces
//  (PreviewCarousel standalone + MediaItemDetailPage) without network I/O.
//

import Foundation

final class MockDetailProvider: MediaProvider, @unchecked Sendable {
    nonisolated static let idValue = MockDetailFixtures.providerID

    nonisolated let id = MockDetailFixtures.providerID
    nonisolated let kind = MediaProviderKind.plex
    nonisolated let displayName = "Mock Detail"
    let connectionState = ConnectionState.connected
    let supportsWatchlist = true

    private var watchlistIDs: Set<String> = []

    func libraries() async throws -> [MediaLibrary] { [] }

    func items(in library: MediaLibrary, sort: SortOption, page: Page) async throws -> PagedResult<MediaItem> {
        PagedResult(items: [], total: 0, nextPage: nil)
    }

    func children(of itemRef: MediaItemRef) async throws -> [MediaItem] {
        switch itemRef.itemID {
        case "show-1":
            return MockDetailFixtures.seasons()
        case "season-1":
            return MockDetailFixtures.allEpisodes()
        default:
            return []
        }
    }

    func search(_ query: String) async throws -> [MediaItem] { [] }

    func collectionItems(matching collectionName: String, in library: MediaLibrary) async throws -> [MediaItem] {
        MockDetailFixtures.related()
    }

    func relatedItems(for itemRef: MediaItemRef) async throws -> [MediaItem] {
        MockDetailFixtures.related().filter { $0.ref != itemRef }
    }

    func allEpisodes(of showRef: MediaItemRef) async throws -> [MediaItem] {
        guard showRef.itemID == "show-1" else { return [] }
        return MockDetailFixtures.allEpisodes()
    }

    func fullDetail(for itemRef: MediaItemRef) async throws -> MediaItemDetail {
        guard let detail = MockDetailFixtures.detail(for: itemRef) else {
            throw MediaProviderError.notFound
        }
        return detail
    }

    func continueWatching(limit: Int) async throws -> [MediaItem] {
        Array(MockDetailFixtures.allEpisodes().prefix(limit))
    }

    func recentlyAdded(limit: Int) async throws -> [MediaItem] {
        Array(([MockDetailFixtures.movie()] + MockDetailFixtures.allEpisodes()).prefix(limit))
    }

    func hubs() async throws -> [MediaHub] { [] }
    func hubs(in library: MediaLibrary) async throws -> [MediaHub] { [] }

    func resolveStream(for itemRef: MediaItemRef, sourceID: String?) async throws -> StreamInfo {
        throw MediaProviderError.notPlayable
    }

    func progressReporter(for itemRef: MediaItemRef, playSessionID: String?) -> any ProgressReporter {
        MockDetailProgressReporter()
    }

    func setSelectedAudioTrack(_ trackID: String, source sourceID: String, of itemRef: MediaItemRef) async throws {}
    func setSelectedSubtitleTrack(_ trackID: String?, source sourceID: String, of itemRef: MediaItemRef) async throws {}
    func markPlayed(_ itemRef: MediaItemRef) async throws {}
    func markUnplayed(_ itemRef: MediaItemRef) async throws {}
    func updateProgress(_ itemRef: MediaItemRef, position: TimeInterval) async throws {}

    func isOnWatchlist(_ ref: MediaItemRef) async -> Bool {
        watchlistIDs.contains(ref.itemID)
    }

    func addToWatchlist(_ ref: MediaItemRef) async throws {
        watchlistIDs.insert(ref.itemID)
    }

    func removeFromWatchlist(_ ref: MediaItemRef) async throws {
        watchlistIDs.remove(ref.itemID)
    }

    func contentAdvisory(for ref: MediaItemRef) async throws -> ContentAdvisory? {
        try await fullDetail(for: ref).contentAdvisory
    }
}

struct MockDetailProgressReporter: ProgressReporter {
    func start() async {}
    func progress(position: TimeInterval) async {}
    func paused(at position: TimeInterval) async {}
    func stopped(at position: TimeInterval) async {}
}
#endif
