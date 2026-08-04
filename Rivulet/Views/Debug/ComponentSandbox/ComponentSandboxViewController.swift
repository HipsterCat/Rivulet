// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Copyright (C) 2025-2026 Bain Gurley

#if DEBUG
//
//  ComponentSandboxViewController.swift
//  Rivulet
//
//  DEBUG catalog of UIKit media cells + interactive demos (toasts, skip
//  pills, empty states, Up Next, badges…) driven by ComponentSandboxMocks.
//  No Plex credentials required — focus/scroll cells and chrome in isolation.
//

import UIKit

nonisolated private enum SandboxSection: Int, CaseIterable, Hashable, Sendable {
    case toasts
    case connectionBanner
    case homeStates
    case search
    case skipPills
    case countdown
    case playPills
    case heroButtons
    case badges
    case upNext
    case transport
    case insightsTabs
    case actor
    case skeletons
    case popups
    case posters
    case continueWatching
    case watchlist
    case seasonPills
    case episodes
    case cast
    case related
    case about
    case info
    case chrome

    var title: String {
        switch self {
        case .toasts: return "Toasts"
        case .connectionBanner: return "Connection Banner"
        case .homeStates: return "Home States"
        case .search: return "Search States"
        case .skipPills: return "Skip Pills (Auto-Skip Fill)"
        case .countdown: return "Countdown Ring"
        case .playPills: return "Play Pills"
        case .heroButtons: return "Hero Buttons"
        case .badges: return "Badges"
        case .upNext: return "Up Next"
        case .transport: return "Transport Controls"
        case .insightsTabs: return "Insights Tabs"
        case .actor: return "Actor Header"
        case .skeletons: return "Skeletons / Loading"
        case .popups: return "Popups"
        case .posters: return "Posters"
        case .continueWatching: return "Continue Watching"
        case .watchlist: return "Watchlist"
        case .seasonPills: return "Season Pills"
        case .episodes: return "Episodes"
        case .cast: return "Cast"
        case .related: return "Related"
        case .about: return "About"
        case .info: return "Information"
        case .chrome: return "Detail Chrome"
        }
    }
}

nonisolated private enum SandboxItem: Hashable, Sendable {
    case toastTriggers
    case connectionBanner
    case homeState(String)
    case searchPrompt
    case searchState(String)
    case skipPills
    case countdown
    case playPills
    case heroButtons
    case badges
    case upNext
    case transport
    case insightsTabs
    case actorHeader(Bool) // loading
    case skeleton(String)
    case heroLoading
    case popupTriggers
    case poster(String)
    case continueWatching(String)
    case watchlist(String)
    case seasonPill(String)
    case episode(String)
    case cast(String)
    case related(String)
    case about
    case info
    case chrome
}

@MainActor
final class ComponentSandboxViewController: UIViewController {

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<SandboxSection, SandboxItem>!

    private let watchlistToast = WatchlistToastView()

    private let posters = ComponentSandboxMocks.posterRow()
    private let continueWatching = ComponentSandboxMocks.continueWatchingItems()
    private let watchlist = ComponentSandboxMocks.watchlistRow()
    private let seasonPills = ComponentSandboxMocks.seasonLabels()
    private let episodes = ComponentSandboxMocks.episodeRow()
    private let cast = ComponentSandboxMocks.castRow()
    private let related = ComponentSandboxMocks.relatedRow()
    private let detail = ComponentSandboxMocks.detail()
    private let upNextEpisodes = ComponentSandboxMocks.upNextEpisodes()

    private lazy var postersByID = Dictionary(uniqueKeysWithValues: posters.map { ($0.ref.itemID, $0) })
    private lazy var cwByID = Dictionary(uniqueKeysWithValues: continueWatching.map { ($0.ref.itemID, $0) })
    private lazy var watchlistByID = Dictionary(uniqueKeysWithValues: watchlist.map { ($0.ref.itemID, $0) })
    private lazy var episodesByID = Dictionary(uniqueKeysWithValues: episodes.map { ($0.ref.itemID, $0) })
    private lazy var relatedByID = Dictionary(uniqueKeysWithValues: related.map { ($0.ref.itemID, $0) })
    private lazy var castByID = Dictionary(uniqueKeysWithValues: cast.map { ($0.id, $0) })
    private lazy var pillsByID = Dictionary(uniqueKeysWithValues: seasonPills.map { ($0.label, $0) })

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        // Chrome / below-fold detail paths resolve through the registry.
        MockDetailLauncher.installProvider()
        configureCollectionView()
        configureDataSource()
        applySnapshot()
        installToastOverlay()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] { [collectionView] }

    // MARK: - Toast overlay

    private func installToastOverlay() {
        view.addSubview(watchlistToast)
        NSLayoutConstraint.activate([
            watchlistToast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            watchlistToast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -48),
            watchlistToast.widthAnchor.constraint(lessThanOrEqualToConstant: 720)
        ])
    }

    private func showWatchlistToast(message: String?, autoHideAfter: TimeInterval = 2.5) {
        view.bringSubviewToFront(watchlistToast)
        watchlistToast.show(message: message, autoHideAfter: autoHideAfter)
    }

    // MARK: - Collection

    private func configureCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .black
        collectionView.remembersLastFocusedIndexPath = true
        collectionView.delegate = self
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentInset = UIEdgeInsets(top: 60, left: 0, bottom: 80, right: 0)
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        collectionView.register(SandboxTriggersCell.self, forCellWithReuseIdentifier: SandboxTriggersCell.reuseID)
        collectionView.register(SandboxBannerCell.self, forCellWithReuseIdentifier: SandboxBannerCell.reuseID)
        collectionView.register(SandboxHomeStateCell.self, forCellWithReuseIdentifier: SandboxHomeStateCell.reuseID)
        collectionView.register(SearchPromptCell.self, forCellWithReuseIdentifier: SearchPromptCell.reuseID)
        collectionView.register(SearchStateCell.self, forCellWithReuseIdentifier: SearchStateCell.reuseID)
        collectionView.register(SandboxSkipPillsCell.self, forCellWithReuseIdentifier: SandboxSkipPillsCell.reuseID)
        collectionView.register(SandboxCountdownCell.self, forCellWithReuseIdentifier: SandboxCountdownCell.reuseID)
        collectionView.register(SandboxPlayPillsCell.self, forCellWithReuseIdentifier: SandboxPlayPillsCell.reuseID)
        collectionView.register(SandboxHeroButtonsCell.self, forCellWithReuseIdentifier: SandboxHeroButtonsCell.reuseID)
        collectionView.register(SandboxBadgesCell.self, forCellWithReuseIdentifier: SandboxBadgesCell.reuseID)
        collectionView.register(SandboxUpNextCell.self, forCellWithReuseIdentifier: SandboxUpNextCell.reuseID)
        collectionView.register(SandboxTransportCell.self, forCellWithReuseIdentifier: SandboxTransportCell.reuseID)
        collectionView.register(SandboxInsightsTabsCell.self, forCellWithReuseIdentifier: SandboxInsightsTabsCell.reuseID)
        collectionView.register(SandboxActorHeaderCell.self, forCellWithReuseIdentifier: SandboxActorHeaderCell.reuseID)
        collectionView.register(PosterSkeletonCell.self, forCellWithReuseIdentifier: PosterSkeletonCell.reuseID)
        collectionView.register(HeroLoadingCell.self, forCellWithReuseIdentifier: HeroLoadingCell.reuseID)
        collectionView.register(PosterCell.self, forCellWithReuseIdentifier: PosterCell.reuseID)
        collectionView.register(ContinueWatchingCell.self, forCellWithReuseIdentifier: ContinueWatchingCell.reuseID)
        collectionView.register(WatchlistPosterCell.self, forCellWithReuseIdentifier: WatchlistPosterCell.reuseID)
        collectionView.register(SeasonPillCollectionCell.self, forCellWithReuseIdentifier: SeasonPillCollectionCell.reuseID)
        collectionView.register(EpisodeCollectionCell.self, forCellWithReuseIdentifier: EpisodeCollectionCell.reuseID)
        collectionView.register(CastCollectionCell.self, forCellWithReuseIdentifier: CastCollectionCell.reuseID)
        collectionView.register(RelatedPosterCell.self, forCellWithReuseIdentifier: RelatedPosterCell.reuseID)
        collectionView.register(AboutCollectionCell.self, forCellWithReuseIdentifier: AboutCollectionCell.reuseID)
        collectionView.register(InfoColumnsCollectionCell.self, forCellWithReuseIdentifier: InfoColumnsCollectionCell.reuseID)
        collectionView.register(SandboxChromeCell.self, forCellWithReuseIdentifier: SandboxChromeCell.reuseID)
        collectionView.register(
            BelowFoldSectionHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: BelowFoldSectionHeader.reuseID
        )
    }

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self, let section = SandboxSection(rawValue: sectionIndex) else { return nil }
            switch section {
            case .toasts, .popups:
                return self.fullWidth(height: 72)
            case .connectionBanner:
                return self.fullWidth(height: 110)
            case .homeStates:
                return self.shelf(itemW: 520, itemH: 360, gap: 28)
            case .search:
                return self.shelf(itemW: 900, itemH: 420, gap: 28)
            case .skipPills:
                return self.fullWidth(height: 180)
            case .countdown:
                return self.fullWidth(height: 140)
            case .playPills:
                return self.fullWidth(height: 90)
            case .heroButtons:
                return self.fullWidth(height: 260)
            case .badges:
                return self.fullWidth(height: 320)
            case .upNext:
                return self.shelf(itemW: 520, itemH: 560, gap: 28)
            case .transport:
                return self.fullWidth(height: 90)
            case .insightsTabs:
                return self.fullWidth(height: 72)
            case .actor:
                return self.shelf(itemW: 440, itemH: 420, gap: 28)
            case .skeletons:
                return self.shelf(
                    itemW: MediaRowMetrics.posterWidth,
                    itemH: MediaRowMetrics.posterHeight + MediaRowMetrics.focusGrowthPadding,
                    gap: MediaRowMetrics.posterGap
                )
            case .posters, .watchlist, .related:
                return self.shelf(
                    itemW: MediaRowMetrics.posterWidth,
                    itemH: MediaRowMetrics.posterHeight + MediaRowMetrics.focusGrowthPadding,
                    gap: MediaRowMetrics.posterGap
                )
            case .continueWatching:
                return self.shelf(
                    itemW: MediaRowMetrics.cwWidth,
                    itemH: MediaRowMetrics.cwHeight + MediaRowMetrics.focusGrowthPadding,
                    gap: MediaRowMetrics.cwGap
                )
            case .seasonPills:
                return self.shelf(itemW: 180, itemH: 64, gap: 16)
            case .episodes:
                return self.shelf(itemW: EpisodeCell.cardWidth, itemH: 435, gap: 16)
            case .cast:
                return self.shelf(itemW: CastCell.circleSize, itemH: 355, gap: 40)
            case .about:
                return self.fullWidth(height: 370)
            case .info:
                return self.fullWidth(height: 460)
            case .chrome:
                return self.fullWidth(height: 420)
            }
        }
    }

    private func shelf(itemW: CGFloat, itemH: CGFloat, gap: CGFloat) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(
            widthDimension: .absolute(itemW), heightDimension: .absolute(itemH)))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .absolute(itemW), heightDimension: .absolute(itemH)),
            subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = gap
        section.contentInsets = .init(
            top: 8,
            leading: MediaRowMetrics.rowLeading,
            bottom: 40,
            trailing: MediaRowMetrics.rowTrailing
        )
        section.boundarySupplementaryItems = [headerItem()]
        return section
    }

    private func fullWidth(height: CGFloat) -> NSCollectionLayoutSection {
        let size = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(height)
        )
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(
            top: 8,
            leading: MediaRowMetrics.rowLeading,
            bottom: 48,
            trailing: MediaRowMetrics.rowTrailing
        )
        section.boundarySupplementaryItems = [headerItem()]
        return section
    }

    private func headerItem() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(44)
        )
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }

    // MARK: - Data source

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<SandboxSection, SandboxItem>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            guard let self else { return UICollectionViewCell() }
            switch item {
            case .toastTriggers:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SandboxTriggersCell.reuseID, for: indexPath) as! SandboxTriggersCell
                cell.configure(titles: [
                    "Watchlist Error",
                    "Long Toast (5s)",
                    "Hide Toast"
                ]) { [weak self] index in
                    switch index {
                    case 0:
                        self?.showWatchlistToast(message: "Couldn't update Watchlist")
                    case 1:
                        self?.showWatchlistToast(
                            message: "Still syncing your Watchlist…",
                            autoHideAfter: 5
                        )
                    default:
                        self?.showWatchlistToast(message: nil)
                    }
                }
                return cell

            case .connectionBanner:
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: SandboxBannerCell.reuseID, for: indexPath)

            case .homeState(let key):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SandboxHomeStateCell.reuseID, for: indexPath) as! SandboxHomeStateCell
                cell.configure(kind: self.homeKind(for: key))
                return cell

            case .searchPrompt:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SearchPromptCell.reuseID, for: indexPath) as! SearchPromptCell
                cell.configure(recentSearches: ["Rivulet", "Night Harbor", "Copper Sky"])
                return cell

            case .searchState(let key):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SearchStateCell.reuseID, for: indexPath) as! SearchStateCell
                cell.configure(state: self.searchState(for: key))
                cell.onRetry = { /* sandbox no-op */ }
                return cell

            case .skipPills:
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: SandboxSkipPillsCell.reuseID, for: indexPath)

            case .countdown:
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: SandboxCountdownCell.reuseID, for: indexPath)

            case .playPills:
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: SandboxPlayPillsCell.reuseID, for: indexPath)

            case .heroButtons:
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: SandboxHeroButtonsCell.reuseID, for: indexPath)

            case .badges:
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: SandboxBadgesCell.reuseID, for: indexPath)

            case .upNext:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SandboxUpNextCell.reuseID, for: indexPath) as! SandboxUpNextCell
                cell.configure(
                    episodes: self.upNextEpisodes,
                    currentRatingKey: ComponentSandboxMocks.upNextCurrentRatingKey
                )
                return cell

            case .transport:
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: SandboxTransportCell.reuseID, for: indexPath)

            case .insightsTabs:
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: SandboxInsightsTabsCell.reuseID, for: indexPath)

            case .actorHeader(let loading):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SandboxActorHeaderCell.reuseID, for: indexPath) as! SandboxActorHeaderCell
                cell.configure(loading: loading)
                return cell

            case .skeleton(let key):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: PosterSkeletonCell.reuseID, for: indexPath) as! PosterSkeletonCell
                cell.configure(layout: key == "cw" ? .continueWatching : .poster)
                return cell

            case .heroLoading:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: HeroLoadingCell.reuseID, for: indexPath) as! HeroLoadingCell
                // Spinner starts in didMoveToWindow / layout; ensure visible.
                return cell

            case .popupTriggers:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SandboxTriggersCell.reuseID, for: indexPath) as! SandboxTriggersCell
                cell.configure(titles: [
                    "Confirm",
                    "Destructive",
                    "Tile Menu"
                ]) { [weak self] index in
                    self?.presentSandboxPopup(index: index)
                }
                return cell

            case .poster(let id):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: PosterCell.reuseID, for: indexPath) as! PosterCell
                if let media = self.postersByID[id] { cell.configure(item: media) }
                return cell
            case .continueWatching(let id):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ContinueWatchingCell.reuseID, for: indexPath) as! ContinueWatchingCell
                if let media = self.cwByID[id] { cell.configure(item: media) }
                return cell
            case .watchlist(let id):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: WatchlistPosterCell.reuseID, for: indexPath) as! WatchlistPosterCell
                if let media = self.watchlistByID[id] { cell.configure(item: media) }
                return cell
            case .seasonPill(let id):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SeasonPillCollectionCell.reuseID, for: indexPath) as! SeasonPillCollectionCell
                if let pill = self.pillsByID[id] {
                    cell.configure(label: pill.label, isSelected: pill.selected)
                }
                return cell
            case .episode(let id):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: EpisodeCollectionCell.reuseID, for: indexPath) as! EpisodeCollectionCell
                if let media = self.episodesByID[id] {
                    cell.configure(episode: media, showSeasonPrefix: true)
                    // Sandbox: both thumb + description are eligible focus stops.
                    cell.contentView.subviews
                        .compactMap { $0 as? EpisodeCell }
                        .forEach { $0.setSandboxFocusEligible(true) }
                }
                return cell
            case .cast(let id):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CastCollectionCell.reuseID, for: indexPath) as! CastCollectionCell
                if let person = self.castByID[id] {
                    cell.configure(person: person, fallbackSubtitle: person.role)
                }
                return cell
            case .related(let id):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: RelatedPosterCell.reuseID, for: indexPath) as! RelatedPosterCell
                if let media = self.relatedByID[id] { cell.configure(item: media) }
                return cell
            case .about:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: AboutCollectionCell.reuseID, for: indexPath) as! AboutCollectionCell
                cell.configure(detail: self.detail)
                return cell
            case .info:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: InfoColumnsCollectionCell.reuseID, for: indexPath) as! InfoColumnsCollectionCell
                cell.configure(detail: self.detail)
                return cell
            case .chrome:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SandboxChromeCell.reuseID, for: indexPath) as! SandboxChromeCell
                cell.configure(item: self.detail.item)
                return cell
            }
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader,
                  let section = self?.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            else { return nil }
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: BelowFoldSectionHeader.reuseID,
                for: indexPath
            ) as! BelowFoldSectionHeader
            header.configure(title: section.title)
            return header
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<SandboxSection, SandboxItem>()
        snapshot.appendSections(SandboxSection.allCases)

        snapshot.appendItems([.toastTriggers], toSection: .toasts)
        snapshot.appendItems([.connectionBanner], toSection: .connectionBanner)
        snapshot.appendItems(
            ["notConnected", "loading", "error", "empty"].map { .homeState($0) },
            toSection: .homeStates
        )
        snapshot.appendItems(
            [.searchPrompt, .searchState("searching"), .searchState("error"), .searchState("noResults")],
            toSection: .search
        )
        snapshot.appendItems([.skipPills], toSection: .skipPills)
        snapshot.appendItems([.countdown], toSection: .countdown)
        snapshot.appendItems([.playPills], toSection: .playPills)
        snapshot.appendItems([.heroButtons], toSection: .heroButtons)
        snapshot.appendItems([.badges], toSection: .badges)
        snapshot.appendItems([.upNext], toSection: .upNext)
        snapshot.appendItems([.transport], toSection: .transport)
        snapshot.appendItems([.insightsTabs], toSection: .insightsTabs)
        snapshot.appendItems([.actorHeader(false), .actorHeader(true)], toSection: .actor)
        snapshot.appendItems(
            [.skeleton("poster"), .skeleton("cw"), .heroLoading],
            toSection: .skeletons
        )
        snapshot.appendItems([.popupTriggers], toSection: .popups)

        snapshot.appendItems(posters.map { .poster($0.ref.itemID) }, toSection: .posters)
        snapshot.appendItems(continueWatching.map { .continueWatching($0.ref.itemID) }, toSection: .continueWatching)
        snapshot.appendItems(watchlist.map { .watchlist($0.ref.itemID) }, toSection: .watchlist)
        snapshot.appendItems(seasonPills.map { .seasonPill($0.label) }, toSection: .seasonPills)
        snapshot.appendItems(episodes.map { .episode($0.ref.itemID) }, toSection: .episodes)
        snapshot.appendItems(cast.map { .cast($0.id) }, toSection: .cast)
        snapshot.appendItems(related.map { .related($0.ref.itemID) }, toSection: .related)
        snapshot.appendItems([.about], toSection: .about)
        snapshot.appendItems([.info], toSection: .info)
        snapshot.appendItems([.chrome], toSection: .chrome)

        dataSource.apply(snapshot, animatingDifferences: false)
    }

    // MARK: - Mapping helpers

    private func homeKind(for key: String) -> HomeStateView.Kind {
        switch key {
        case "notConnected": return .notConnected
        case "loading": return .loading
        case "error": return .error(message: "The sandbox server is unreachable.")
        default: return .empty
        }
    }

    private func searchState(for key: String) -> SearchStateCell.State {
        switch key {
        case "searching": return .searching
        case "error": return .error(message: "Couldn't reach Plex. Check your connection.")
        default: return .noResults
        }
    }

    private func presentSandboxPopup(index: Int) {
        switch index {
        case 0:
            let popup = ConfirmationPopupViewController(
                title: "Remove from Watchlist?",
                message: "Night Harbor will no longer appear in your Watchlist.",
                confirmTitle: "Remove",
                cancelTitle: "Cancel",
                destructive: false,
                onConfirm: { [weak self] in
                    self?.showWatchlistToast(message: "Removed from Watchlist")
                }
            )
            present(popup, animated: true)
        case 1:
            let popup = ConfirmationPopupViewController(
                title: "Delete Download?",
                message: "This can't be undone.",
                confirmTitle: "Delete",
                cancelTitle: "Cancel",
                destructive: true,
                onConfirm: {}
            )
            present(popup, animated: true)
        default:
            let menu = TileMenuPopupViewController(sections: [[
                TileMenuAction(title: "Play", systemImage: "play.fill", handler: {}),
                TileMenuAction(title: "Add to Watchlist", systemImage: "plus", handler: {}),
                TileMenuAction(title: "Mark as Watched", systemImage: "checkmark.circle", handler: {})
            ], [
                TileMenuAction(title: "Remove", systemImage: "trash", destructive: true, handler: {})
            ]], sourceFrame: CGRect(x: 200, y: 200, width: 220, height: 330))
            present(menu, animated: false)
        }
    }
}

// MARK: - Focus

extension ComponentSandboxViewController: UICollectionViewDelegate {
    /// Match below-fold: episodes/about/chrome host nested focus targets.
    /// Host demo cells also keep focus on their inner controls, not the cell frame.
    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return false }
        switch item {
        case .episode, .about, .chrome, .info,
             .toastTriggers, .popupTriggers, .skipPills, .playPills,
             .heroButtons, .transport, .insightsTabs, .countdown,
             .connectionBanner, .upNext, .homeState:
            return false
        default:
            return true
        }
    }
}

private extension EpisodeCell {
    /// Sandbox-only: unlock the description focus stop so both thumb + text work.
    func setSandboxFocusEligible(_ eligible: Bool) {
        func visit(_ view: UIView) {
            if let description = view as? EpisodeDescriptionView {
                description.isFocusEligible = eligible
            }
            view.subviews.forEach(visit)
        }
        visit(self)
    }
}
#endif
