// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Copyright (C) 2025-2026 Bain Gurley

import Foundation

enum SentryConfig {
    /// Sentry is release-only. DEBUG builds — including Xcode Previews — never
    /// start the SDK, so there is no DSN file to maintain locally.
    static var isEnabled: Bool {
        #if DEBUG
        return false
        #else
        return !dsn.isEmpty
        #endif
    }

    /// Injected at build time via `RIVULET_SENTRY_DSN` → Info.plist
    /// `RivuletSentryDSN`. Empty in local and CI debug builds.
    static var dsn: String {
        (Bundle.main.object(forInfoDictionaryKey: "RivuletSentryDSN") as? String) ?? ""
    }
}
