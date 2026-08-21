#if DEBUG
//
//  PlexAuthManager+KinoPubDemo.swift
//  Rivulet
//
//  Puts the auth manager into a signed-in state pointing at a server that does
//  not exist. Home paints "not connected" from auth state rather than from
//  whether it has content, so seeding rails alone is not enough — the app has
//  to believe it has a server before it will render one.
//

import Foundation

extension PlexAuthManager {
    /// The keys `hasCredentials` reads. Written verbatim because the demo has to
    /// satisfy the same gate a real sign-in does, and the properties holding
    /// these names are private.
    private enum DemoKey {
        static let serverURL = "selectedServerURL"
        static let serverName = "selectedServerName"
        static let username = "plexUsername"
        static let hasPersistedSession = "plexHasPersistedSession"
    }

    @MainActor
    func applyKinoPubDemoSession() {
        let defaults = UserDefaults.standard
        defaults.set(KinoPubDemo.serverURL, forKey: DemoKey.serverURL)
        defaults.set("kino.pub", forKey: DemoKey.serverName)
        defaults.set("Демо", forKey: DemoKey.username)
        defaults.set(true, forKey: DemoKey.hasPersistedSession)

        authToken = KinoPubDemo.token
        username = "Демо"
        selectedServerURL = KinoPubDemo.serverURL
        selectedServerToken = KinoPubDemo.token
        isConnected = true
        connectionError = nil
        state = .authenticated
    }
}
#endif
