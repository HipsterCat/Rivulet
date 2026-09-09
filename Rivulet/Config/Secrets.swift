//
//  Secrets.swift
//  Rivulet
//
//  Local-only secrets. DO NOT commit this file.
//  Copied from Secrets.swift.template with Sentry disabled (empty DSN).
//

import Foundation

enum Secrets {
    /// Empty = Sentry stays off (RivuletApp skips SDK start).
    static let sentryDSN = ""
}
