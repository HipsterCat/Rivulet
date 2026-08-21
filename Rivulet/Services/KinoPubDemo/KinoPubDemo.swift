#if DEBUG
//
//  KinoPubDemo.swift
//  Rivulet
//
//  Look-and-feel demo on a frozen kino.pub catalogue: no Plex server, no
//  account, no network beyond the image CDNs.
//
//  Rides the affordance Rivulet already has for this — `installDemoContent`
//  plus a provider in the ordinary registry — so nothing in the fetch path is
//  touched. It replaces `DemoContentSeeder`'s canned English rails with 140
//  real kino.pub titles.
//
//  On by default in DEBUG, because a build launched from a device Home screen
//  has no launch environment to read. `RIVULET_KINOPUB_DEMO=0` gives back the
//  ordinary app.
//

import Foundation

@MainActor
enum KinoPubDemo {
    /// Fake server identity. Nothing connects to it — it exists so everything
    /// that asks "which server am I on?" gets a stable answer.
    static let serverURL = "https://kinopub.demo"
    static let token = "kinopub-demo-token"

    static var isEnabled: Bool {
        guard ProcessInfo.processInfo.environment["RIVULET_KINOPUB_DEMO"] != "0" else { return false }
        // Never displace a real session. Stays true once the demo has installed
        // itself, because by then the stored server IS the demo one.
        let current = PlexAuthManager.shared.selectedServerURL
        return current == nil || current == serverURL
    }

    /// Read from the nonisolated network layer, which cannot hop to the main
    /// actor just to ask whether the demo is on.
    nonisolated(unsafe) private(set) static var isActive = false

    static func install() {
        guard isEnabled else { return }
        Self.isActive = true
        let provider = KinoPubDemoProvider()
        MediaProviderRegistry.shared.register(provider)
        PlexAuthManager.shared.applyKinoPubDemoSession()
        PlexDataStore.shared.installDemoContent(
            libraries: libraries(),
            homeRail: homeRail(provider),
            libraryRails: libraryRails(provider)
        )
    }

    // MARK: - Libraries

    static let moviesKey = "kinopub-movies"
    static let seriesKey = "kinopub-series"

    private static func libraries() -> [PlexLibrary] {
        KinoPubDemoPlexFixtures.libraries()
    }

    // MARK: - Rails

    private static func homeRail(_ provider: KinoPubDemoProvider) -> CachedHomeRail {
        let catalog = KinoPubDemoCatalog.shared
        return catalog.rows.map { row in
            let items = catalog.items(inRow: row.id).map(provider.mediaItem)
            return CachedHomeHub(
                id: "kinopub-\(row.id)",
                title: row.title.capitalized,
                isContinueWatching: row.id == "continue",
                hubKey: "kinopub-\(row.id)",
                hubIdentifier: row.id == "continue" ? "continueWatching" : "kinopub.\(row.id)",
                totalSize: items.count,
                items: items
            )
        }
    }

    private static func libraryRails(_ provider: KinoPubDemoProvider) -> [String: CachedHomeRail] {
        let catalog = KinoPubDemoCatalog.shared
        let movies = catalog.movies.map(provider.mediaItem)
        let series = catalog.series.map(provider.mediaItem)
        return [
            moviesKey: [
                CachedHomeHub(
                    id: "kinopub-lib-movies",
                    title: "Новинки",
                    isContinueWatching: false,
                    hubKey: "kinopub-lib-movies",
                    hubIdentifier: "movie.recentlyAdded",
                    totalSize: movies.count,
                    items: movies
                )
            ],
            seriesKey: [
                CachedHomeHub(
                    id: "kinopub-lib-series",
                    title: "Новинки",
                    isContinueWatching: false,
                    hubKey: "kinopub-lib-series",
                    hubIdentifier: "show.recentlyAdded",
                    totalSize: series.count,
                    items: series
                )
            ],
        ]
    }
}
#endif
