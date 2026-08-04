// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Copyright (C) 2025-2026 Bain Gurley

#if DEBUG
//
//  MockDetailLauncher.swift
//  Rivulet
//
//  Presents the real detail UIKit surfaces with MockDetailProvider fixtures.
//  Trigger via sidebar "Detail Template" tab or RIVULET_OPEN_DETAIL env:
//    show | movie | episode | 1
//

import SwiftUI
import UIKit

enum MockDetailKind: String, CaseIterable {
    case show
    case movie
    case episode

    static func fromEnvironment(_ raw: String?) -> MockDetailKind? {
        guard let raw, !raw.isEmpty else { return nil }
        let value = raw.lowercased()
        if value == "1" || value == "true" || value == "yes" { return .show }
        return MockDetailKind(rawValue: value)
    }
}

enum MockDetailLauncher {
    /// Register the in-memory provider so chrome / below-fold resolve without Plex.
    @MainActor
    static func installProvider() {
        MediaProviderRegistry.shared.register(MockDetailProvider())
    }

    @MainActor
    static func present(kind: MockDetailKind = .show, from presenter: UIViewController? = nil) {
        installProvider()
        guard let top = presenter ?? topPresentedViewController() else { return }

        let item: MediaItem
        switch kind {
        case .show: item = MockDetailFixtures.show()
        case .movie: item = MockDetailFixtures.movie()
        case .episode: item = MockDetailFixtures.episode()
        }

        if item.kind == .episode {
            let page = MediaItemDetailPageViewController(
                item: item,
                seriesTitle: MockDetailFixtures.show().title,
                onPlay: { _ in top.dismiss(animated: true) }
            )
            top.present(page, animated: true)
        } else {
            let detail = PreviewCarouselViewController(
                items: [item],
                selectedIndex: 0,
                sourceFrame: .zero,
                sourceTarget: nil,
                standaloneDetail: true,
                onDismiss: { _ in }
            )
            top.present(detail, animated: true)
        }
    }

    @MainActor
    private static func topPresentedViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first,
              var top = window.rootViewController else { return nil }
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}

/// DEBUG sidebar host: three buttons that open the real detail templates.
struct MockDetailTemplateView: View {
    var body: some View {
        VStack(spacing: 28) {
            Text("Detail Template")
                .font(.largeTitle.bold())
            Text("Opens the real detail UI with canned data — no Plex or network.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 900)

            HStack(spacing: 24) {
                Button("Show Detail") { MockDetailLauncher.present(kind: .show) }
                Button("Movie Detail") { MockDetailLauncher.present(kind: .movie) }
                Button("Episode Detail") { MockDetailLauncher.present(kind: .episode) }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .onAppear { MockDetailLauncher.installProvider() }
    }
}
#endif
