// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Copyright (C) 2025-2026 Bain Gurley

#if DEBUG
//
//  DemoContentSeeder.swift
//  Rivulet
//
//  Fills Home / Library tabs with canned MediaItem rails so the app is
//  browsable without Plex. On by default in DEBUG when there's no Plex
//  session (scheme also sets RIVULET_DEMO=1). Opt out with RIVULET_DEMO=0.
//

import Foundation

@MainActor
enum DemoContentSeeder {
    static var isEnabled: Bool {
        let env = ProcessInfo.processInfo.environment["RIVULET_DEMO"]
        if env == "0" { return false }
        if env == "1" { return true }
        if UserDefaults.standard.object(forKey: "rivuletDemoMode") != nil {
            return UserDefaults.standard.bool(forKey: "rivuletDemoMode")
        }
        // Default: seed whenever there's nothing to show from Plex.
        return PlexAuthManager.shared.selectedServerToken == nil
    }

    static func install() {
        guard isEnabled else { return }
        MockDetailLauncher.installProvider()
        PlexDataStore.shared.installDemoContent(
            libraries: demoLibraries(),
            homeRail: demoHomeRail(),
            libraryRails: demoLibraryRails()
        )
    }

    private static func demoLibraries() -> [PlexLibrary] {
        [
            PlexLibrary(
                key: "demo-movies",
                type: "movie",
                title: "Movies",
                agent: "com.rivulet.demo",
                scanner: "demo",
                language: "en",
                uuid: "demo-movies-uuid",
                updatedAt: nil,
                createdAt: nil,
                scannedAt: nil,
                Location: nil
            ),
            PlexLibrary(
                key: "demo-shows",
                type: "show",
                title: "TV Shows",
                agent: "com.rivulet.demo",
                scanner: "demo",
                language: "en",
                uuid: "demo-shows-uuid",
                updatedAt: nil,
                createdAt: nil,
                scannedAt: nil,
                Location: nil
            )
        ]
    }

    private static func demoHomeRail() -> CachedHomeRail {
        let posters = ComponentSandboxMocks.posterRow()
        let cw = ComponentSandboxMocks.continueWatchingItems()
        let related = ComponentSandboxMocks.relatedRow()
        return [
            CachedHomeHub(
                id: "demo-cw",
                title: "Continue Watching",
                isContinueWatching: true,
                hubKey: "demo-cw",
                hubIdentifier: "continueWatching",
                totalSize: cw.count,
                items: cw
            ),
            CachedHomeHub(
                id: "demo-recent",
                title: "Recently Added",
                isContinueWatching: false,
                hubKey: "demo-recent",
                hubIdentifier: "home.movies.recent",
                totalSize: posters.count,
                items: posters
            ),
            CachedHomeHub(
                id: "demo-related",
                title: "Because You Watched Rivulet",
                isContinueWatching: false,
                hubKey: "demo-related",
                hubIdentifier: "movie.recentlyViewed.similar",
                totalSize: related.count,
                items: related
            )
        ]
    }

    private static func demoLibraryRails() -> [String: CachedHomeRail] {
        let posters = ComponentSandboxMocks.posterRow()
        let episodes = ComponentSandboxMocks.episodeRow()
        let moviesRail: CachedHomeRail = [
            CachedHomeHub(
                id: "lib-movies-recent",
                title: "Recently Added",
                isContinueWatching: false,
                hubKey: "lib-movies-recent",
                hubIdentifier: "movie.recentlyAdded",
                totalSize: posters.count,
                items: posters
            )
        ]
        let showsRail: CachedHomeRail = [
            CachedHomeHub(
                id: "lib-shows-recent",
                title: "Recently Added",
                isContinueWatching: false,
                hubKey: "lib-shows-recent",
                hubIdentifier: "show.recentlyAdded",
                totalSize: episodes.count,
                items: [ComponentSandboxMocks.show()] + posters.filter { $0.kind == .show || $0.kind == .movie }
            )
        ]
        return [
            "demo-movies": moviesRail,
            "demo-shows": showsRail
        ]
    }
}
#endif
