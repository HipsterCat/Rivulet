// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Copyright (C) 2025-2026 Bain Gurley

#if DEBUG
//
//  ComponentSandboxHostCells.swift
//  Rivulet
//
//  Host / demo cells for interactive Component Sandbox sections (toasts,
//  skip pills, banners, play pills, Up Next, etc.).
//

import SwiftUI
import UIKit
import Combine

// MARK: - Shared helpers

@MainActor
enum SandboxHostHelpers {
    static func makePillButton(title: String, action: @escaping () -> Void) -> FocusableActionButton {
        let button = FocusableActionButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 22
        button.onPrimaryAction = action

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textColor = .white
        button.addSubview(label)
        button.invertOnFocus = [label]

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 28),
            label.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -28),
            label.topAnchor.constraint(equalTo: button.topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -16),
            button.heightAnchor.constraint(equalToConstant: 56)
        ])
        return button
    }

    static func pin(_ child: UIView, to host: UIView, insets: UIEdgeInsets = .zero) {
        child.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(child)
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: host.topAnchor, constant: insets.top),
            child.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: insets.left),
            child.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -insets.right),
            child.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -insets.bottom)
        ])
    }
}

// MARK: - Toast / popup triggers

final class SandboxTriggersCell: UICollectionViewCell {
    static let reuseID = "SandboxTriggersCell"

    private let stack = UIStackView()
    private var buttons: [FocusableActionButton] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .horizontal
        stack.spacing = 20
        stack.alignment = .center
        SandboxHostHelpers.pin(stack, to: contentView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func configure(titles: [String], handler: @escaping (Int) -> Void) {
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()
        for (index, title) in titles.enumerated() {
            let button = SandboxHostHelpers.makePillButton(title: title) { handler(index) }
            stack.addArrangedSubview(button)
            buttons.append(button)
        }
    }

    override var canBecomeFocused: Bool { false }
    override var preferredFocusEnvironments: [UIFocusEnvironment] { buttons }

    override func prepareForReuse() {
        super.prepareForReuse()
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()
    }
}

// MARK: - Connection banner

final class SandboxBannerCell: UICollectionViewCell {
    static let reuseID = "SandboxBannerCell"

    private let banner = ConnectionErrorBannerView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        SandboxHostHelpers.pin(banner, to: contentView)
        banner.setMessage("Showing cached content")
        banner.onRetry = { /* sandbox no-op */ }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var canBecomeFocused: Bool { false }
    override var preferredFocusEnvironments: [UIFocusEnvironment] { [banner] }
}

// MARK: - Home state

final class SandboxHomeStateCell: UICollectionViewCell {
    static let reuseID = "SandboxHomeStateCell"

    private let stateView = HomeStateView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 20
        contentView.layer.cornerCurve = .continuous
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        contentView.clipsToBounds = true
        SandboxHostHelpers.pin(stateView, to: contentView)
        stateView.onAction = { /* sandbox no-op */ }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func configure(kind: HomeStateView.Kind) {
        stateView.configure(kind: kind)
    }

    override var canBecomeFocused: Bool { false }
    override var preferredFocusEnvironments: [UIFocusEnvironment] { [stateView] }
}

// MARK: - Skip pills + auto-skip fill

final class SandboxSkipPillsCell: UICollectionViewCell {
    static let reuseID = "SandboxSkipPillsCell"

    private let pillsStack = UIStackView()
    private let controlsStack = UIStackView()
    private var pills: [SkipPillButton] = []
    private var controlButtons: [FocusableActionButton] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        pillsStack.axis = .horizontal
        pillsStack.spacing = 20
        pillsStack.alignment = .center

        controlsStack.axis = .horizontal
        controlsStack.spacing = 16
        controlsStack.alignment = .center

        let root = UIStackView(arrangedSubviews: [pillsStack, controlsStack])
        root.axis = .vertical
        root.spacing = 28
        root.alignment = .leading
        SandboxHostHelpers.pin(root, to: contentView)

        let titles = ["Skip Intro", "Skip Credits", "Skip Recap", "Skip Ad"]
        for title in titles {
            let pill = SkipPillButton()
            pill.setTitle(title, for: .normal)
            pill.onSelect = { [weak pill] in pill?.cancelFill() }
            pillsStack.addArrangedSubview(pill)
            pills.append(pill)
        }

        let start = SandboxHostHelpers.makePillButton(title: "Start 5s Fill") { [weak self] in
            self?.pills.forEach { $0.beginFill(duration: 5) }
        }
        let cancel = SandboxHostHelpers.makePillButton(title: "Cancel Fill") { [weak self] in
            self?.pills.forEach { $0.cancelFill() }
        }
        controlsStack.addArrangedSubview(start)
        controlsStack.addArrangedSubview(cancel)
        controlButtons = [start, cancel]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var canBecomeFocused: Bool { false }
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        pills + controlButtons
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        pills.forEach { $0.cancelFill() }
    }
}

// MARK: - Countdown ring

final class SandboxCountdownCell: UICollectionViewCell {
    static let reuseID = "SandboxCountdownCell"

    private let totalSeconds = 10
    private var remainingSeconds = 10
    private var isPaused = false
    private var timer: Timer?
    private var host: UIHostingController<CountdownRing>?
    private let controls = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        let hosting = UIHostingController(rootView: CountdownRing(
            totalSeconds: totalSeconds,
            remainingSeconds: remainingSeconds,
            isPaused: isPaused
        ))
        hosting.view.backgroundColor = .clear
        host = hosting

        controls.axis = .horizontal
        controls.spacing = 16
        controls.alignment = .center

        let restartButton = SandboxHostHelpers.makePillButton(title: "Restart") { [weak self] in
            self?.restartCountdown()
        }
        let pauseButton = SandboxHostHelpers.makePillButton(title: "Pause / Resume") { [weak self] in
            self?.isPaused.toggle()
            self?.refreshRing()
        }
        controls.addArrangedSubview(restartButton)
        controls.addArrangedSubview(pauseButton)

        let root = UIStackView(arrangedSubviews: [hosting.view, controls])
        root.axis = .horizontal
        root.spacing = 40
        root.alignment = .center
        SandboxHostHelpers.pin(root, to: contentView)

        restartCountdown()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        restartCountdown()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            timer?.invalidate()
            timer = nil
        } else if timer == nil {
            restartCountdown()
        }
    }

    private func restartCountdown() {
        timer?.invalidate()
        remainingSeconds = totalSeconds
        isPaused = false
        refreshRing()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                guard !self.isPaused else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                    self.refreshRing()
                } else {
                    self.timer?.invalidate()
                    self.timer = nil
                }
            }
        }
    }

    private func refreshRing() {
        host?.rootView = CountdownRing(
            totalSeconds: totalSeconds,
            remainingSeconds: remainingSeconds,
            isPaused: isPaused
        )
    }
}

// MARK: - Play pills

final class SandboxPlayPillsCell: UICollectionViewCell {
    static let reuseID = "SandboxPlayPillsCell"

    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .horizontal
        stack.spacing = 24
        stack.alignment = .center
        SandboxHostHelpers.pin(stack, to: contentView)

        let variants: [(label: String, progress: Double?)] = [
            ("Play", nil),
            ("Play S1E1", nil),
            ("S1E3 · 29m", 0.42),
            ("Play Again", nil)
        ]
        for variant in variants {
            stack.addArrangedSubview(makePlayPill(title: variant.label, progress: variant.progress))
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// Mirrors `MediaDetailChromeView.makePlayPill` for sandbox previews.
    private func makePlayPill(title: String, progress: Double?) -> FocusableActionButton {
        let height = HeroPillButton.buttonHeight
        let pill = FocusableActionButton()
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.layer.cornerRadius = height / 2
        pill.layer.cornerCurve = .continuous

        let playIcon = UIImageView(image: UIImage(systemName: "play.fill"))
        playIcon.translatesAutoresizingMaskIntoConstraints = false
        playIcon.tintColor = .white
        playIcon.contentMode = .scaleAspectFit

        let track = UIView()
        track.translatesAutoresizingMaskIntoConstraints = false
        track.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        track.layer.cornerRadius = 2
        track.clipsToBounds = true
        track.isHidden = progress == nil

        let fill = UIView()
        fill.translatesAutoresizingMaskIntoConstraints = false
        fill.backgroundColor = .white
        track.addSubview(fill)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.text = title

        let contentStack = UIStackView(arrangedSubviews: [playIcon, track, titleLabel])
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 12
        pill.addSubview(contentStack)

        NSLayoutConstraint.activate([
            pill.widthAnchor.constraint(equalToConstant: HeroPillButton.pillWidth),
            pill.heightAnchor.constraint(equalToConstant: height),
            contentStack.centerXAnchor.constraint(equalTo: pill.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: pill.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: pill.trailingAnchor, constant: -18),
            playIcon.widthAnchor.constraint(equalToConstant: 20),
            playIcon.heightAnchor.constraint(equalToConstant: 20),
            track.widthAnchor.constraint(equalToConstant: 56),
            track.heightAnchor.constraint(equalToConstant: 4),
            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: CGFloat(progress ?? 0))
        ])

        pill.invertOnFocus = [playIcon, titleLabel]
        pill.invertBackgroundOnFocus = [track]
        return pill
    }

    override var canBecomeFocused: Bool { false }
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        stack.arrangedSubviews
    }
}

// MARK: - Hero button rows

final class SandboxHeroButtonsCell: UICollectionViewCell {
    static let reuseID = "SandboxHeroButtonsCell"

    private let playRow = HeroButtonRowView()
    private let watchlistRow = HeroButtonRowView()
    private let playLabel = UILabel()
    private let watchlistLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureCaption(playLabel, text: "Library match · Play")
        configureCaption(watchlistLabel, text: "Discover / TMDB · Watchlist primary")

        playRow.primaryAction = .play
        playRow.isOnWatchlist = false
        playRow.canAdvance = true
        playRow.onWatchlist = { [weak self] in
            guard let self else { return }
            self.playRow.isOnWatchlist.toggle()
        }

        watchlistRow.primaryAction = .watchlist
        watchlistRow.isOnWatchlist = false
        watchlistRow.canAdvance = false
        watchlistRow.onPlay = { [weak self] in
            guard let self else { return }
            self.watchlistRow.isOnWatchlist.toggle()
        }

        let playGroup = UIStackView(arrangedSubviews: [playLabel, playRow])
        playGroup.axis = .vertical
        playGroup.spacing = 12
        playGroup.alignment = .leading

        let watchGroup = UIStackView(arrangedSubviews: [watchlistLabel, watchlistRow])
        watchGroup.axis = .vertical
        watchGroup.spacing = 12
        watchGroup.alignment = .leading

        let root = UIStackView(arrangedSubviews: [playGroup, watchGroup])
        root.axis = .vertical
        root.spacing = 36
        root.alignment = .leading
        SandboxHostHelpers.pin(root, to: contentView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func configureCaption(_ label: UILabel, text: String) {
        label.text = text
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.55)
    }

    override var canBecomeFocused: Bool { false }
    override var preferredFocusEnvironments: [UIFocusEnvironment] { [playRow, watchlistRow] }
}

// MARK: - Badges

final class SandboxBadgesCell: UICollectionViewCell {
    static let reuseID = "SandboxBadgesCell"

    private var audioHost: UIHostingController<AnyView>?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let ratingRow = UIStackView()
        ratingRow.axis = .horizontal
        ratingRow.spacing = 12
        ratingRow.alignment = .center
        for text in ["PG-13", "TV-MA", "TV-14", "R"] {
            let badge = HeroRatingBadgeView()
            badge.text = text
            ratingRow.addArrangedSubview(badge)
        }

        let qualityRow = UIStackView()
        qualityRow.axis = .horizontal
        qualityRow.spacing = 12
        qualityRow.alignment = .center
        for text in ["4K", "DV", "HDR", "Atmos", "E-AC3 5.1"] {
            qualityRow.addArrangedSubview(makeQualityChip(text))
        }

        let watched = PosterWatchedBadge()
        watched.setStyle(.unwatchedCount(6))
        let watchedGlyph = WatchedGlyphView()

        let miscRow = UIStackView(arrangedSubviews: [watched, watchedGlyph])
        miscRow.axis = .horizontal
        miscRow.spacing = 20
        miscRow.alignment = .center

        let audio = HStack(spacing: 12) {
            AudioQualityBadge(quality: MusicAudioProcessor.audioQuality(codec: "flac", bitrate: nil, sampleRate: 96_000))
            AudioQualityBadge(quality: MusicAudioProcessor.audioQuality(codec: "flac", bitrate: nil, sampleRate: 44_100))
            AudioQualityBadge(quality: MusicAudioProcessor.audioQuality(codec: "aac", bitrate: 320, sampleRate: nil))
            AudioQualityBadge(quality: MusicAudioProcessor.audioQuality(codec: "mp3", bitrate: 192, sampleRate: nil))
        }
        .fixedSize()
        let hosting = UIHostingController(rootView: AnyView(audio))
        hosting.view.backgroundColor = .clear
        audioHost = hosting

        let captions = ["Content rating", "Quality", "Watched / rewatch", "Audio quality"]
        let rows: [UIView] = [ratingRow, qualityRow, miscRow, hosting.view]
        let labeled = zip(captions, rows).map { caption, row -> UIStackView in
            let label = UILabel()
            label.text = caption
            label.font = .systemFont(ofSize: 16, weight: .medium)
            label.textColor = UIColor.white.withAlphaComponent(0.45)
            let group = UIStackView(arrangedSubviews: [label, row])
            group.axis = .vertical
            group.spacing = 10
            group.alignment = .leading
            return group
        }

        let root = UIStackView(arrangedSubviews: labeled)
        root.axis = .vertical
        root.spacing = 28
        root.alignment = .leading
        SandboxHostHelpers.pin(root, to: contentView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func makeQualityChip(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor.white.withAlphaComponent(0.9)

        let chip = UIView()
        chip.layer.borderWidth = 1.5
        chip.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        chip.layer.cornerRadius = 4
        chip.layer.cornerCurve = .continuous
        label.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: chip.topAnchor, constant: 3),
            label.bottomAnchor.constraint(equalTo: chip.bottomAnchor, constant: -3)
        ])
        return chip
    }
}

// MARK: - Up Next

final class SandboxUpNextCell: UICollectionViewCell {
    static let reuseID = "SandboxUpNextCell"

    private var listView: UpNextListView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        contentView.layer.cornerRadius = 20
        contentView.layer.cornerCurve = .continuous
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func configure(episodes: [PlexMetadata], currentRatingKey: String) {
        listView?.removeFromSuperview()
        let list = UpNextListView(
            episodes: episodes,
            currentRatingKey: currentRatingKey,
            seasonNumber: 1,
            serverURL: "https://sandbox.invalid",
            authToken: "sandbox",
            onSelect: { _ in }
        )
        SandboxHostHelpers.pin(list, to: contentView, insets: .init(top: 20, left: 20, bottom: 20, right: 20))
        listView = list
        contentView.layoutIfNeeded()
        list.prepareForPresentation()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        listView?.removeFromSuperview()
        listView = nil
    }
}

// MARK: - Transport controls

final class SandboxTransportCell: UICollectionViewCell {
    static let reuseID = "SandboxTransportCell"

    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .horizontal
        stack.spacing = 20
        stack.alignment = .center
        SandboxHostHelpers.pin(stack, to: contentView)

        let specs: [(String, String)] = [
            ("gobackward.10", "Skip back"),
            ("goforward.10", "Skip forward"),
            ("captions.bubble", "Subtitles"),
            ("info.circle", "Info"),
            ("list.bullet", "Up Next")
        ]
        for (symbol, label) in specs {
            let button = TransportControlButton(
                icon: UIImage(systemName: symbol),
                accessibilityLabel: label
            )
            button.onPress = { /* sandbox no-op */ }
            stack.addArrangedSubview(button)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var canBecomeFocused: Bool { false }
    override var preferredFocusEnvironments: [UIFocusEnvironment] { stack.arrangedSubviews }
}

// MARK: - Insights tabs

final class SandboxInsightsTabsCell: UICollectionViewCell {
    static let reuseID = "SandboxInsightsTabsCell"

    private let tabBar = PillTabBarView(
        titles: ["Top 10", "Cast", "Production", "Lore"],
        selectedIndex: 0
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        SandboxHostHelpers.pin(tabBar, to: contentView)
        tabBar.onSelect = { _ in /* sandbox no-op */ }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var canBecomeFocused: Bool { false }
    override var preferredFocusEnvironments: [UIFocusEnvironment] { [tabBar] }
}

// MARK: - Actor header

final class SandboxActorHeaderCell: UICollectionViewCell {
    static let reuseID = "SandboxActorHeaderCell"

    private let header = InsightsActorHeaderView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        contentView.layer.cornerRadius = 20
        contentView.layer.cornerCurve = .continuous
        SandboxHostHelpers.pin(header, to: contentView, insets: .init(top: 24, left: 32, bottom: 24, right: 32))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func configure(loading: Bool) {
        header.configure(
            name: "Ava Meridian",
            biography: loading ? nil : ComponentSandboxMocks.actorBiography(),
            portraitURL: ComponentSandboxMocks.actorPortraitURL(),
            isLoading: loading
        )
    }
}

// MARK: - Detail chrome (existing)

final class SandboxChromeCell: UICollectionViewCell {
    static let reuseID = "SandboxChromeCell"

    private let chrome = MediaDetailChromeView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        chrome.translatesAutoresizingMaskIntoConstraints = false
        chrome.mode = .expandedDetail
        contentView.addSubview(chrome)
        NSLayoutConstraint.activate([
            chrome.topAnchor.constraint(equalTo: contentView.topAnchor),
            chrome.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            chrome.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            chrome.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func configure(item: MediaItem) {
        chrome.item = item
        chrome.chromeAlpha = 1
    }

    override var canBecomeFocused: Bool { false }
    override var preferredFocusEnvironments: [UIFocusEnvironment] { [chrome] }

    override func prepareForReuse() {
        super.prepareForReuse()
        chrome.item = nil
    }
}
#endif
