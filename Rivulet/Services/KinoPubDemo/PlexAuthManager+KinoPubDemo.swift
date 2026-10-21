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
    @MainActor
    func applyKinoPubDemoSession() {
        applyOfflineDemoSession(
            serverURL: KinoPubDemo.serverURL,
            serverName: "kino.pub",
            username: "Демо",
            token: KinoPubDemo.token
        )
    }
}
#endif
