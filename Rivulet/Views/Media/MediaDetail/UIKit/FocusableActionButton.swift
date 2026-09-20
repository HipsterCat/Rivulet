// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Copyright (C) 2025-2026 Bain Gurley

//
//  FocusableActionButton.swift
//  Rivulet
//
//  A focusable rounded button for the expanded-detail action row (Play pill +
//  circle buttons). Renders its own background; the caller adds the content
//  (icon / label / progress) as subviews and registers which of those should
//  invert to black on focus. On tvOS the focus engine focuses it (canBecomeFocused)
//  and Select fires `.primaryActionTriggered`; the focused appearance (scale +
//  white fill + inverted content) animates on the UIFocusAnimationCoordinator so
//  it rides the system focus animation. Mirrors the focus pattern used by the
//  below-fold cells (see BelowFoldCells.swift).
//
//  These buttons are only focusable while an ancestor (the chrome) is
//  user-interaction-enabled — i.e. in `.expandedDetail` mode, not in
//  carousel-stable — so the carousel's focusless-modal model is unaffected.
//

import UIKit

final class FocusableActionButton: UIControl {
    /// Content views recolored to black on focus (UIImageView via tintColor,
    /// UILabel via textColor). Set by the builder after adding content.
    var invertOnFocus: [UIView] = []

    /// Plain views whose backgroundColor inverts on focus — e.g. the Play
    /// progress track, which is white at rest and would vanish on the white
    /// focused fill. Focused → dark, resting → translucent white (matches
    /// SwiftUI's track color).
    var invertBackgroundOnFocus: [UIView] = []

    /// Like `invertBackgroundOnFocus` but for the filled portion drawn on top of
    /// a track — it has to stay darker than the track it sits in, or the bar
    /// reads backwards on the white focused pill.
    var invertFillOnFocus: [UIView] = []

    /// Invoked on Select (`.primaryActionTriggered`).
    var onPrimaryAction: (() -> Void)?

    /// Focus appearance. `.pill` (default) inverts to a white fill with black
    /// content — the action-row look. `.glass` keeps the content white and uses
    /// the app's glass convention (subtle white fill + 1px border + gentle
    /// scale) — used for large soft targets like the bio panel, where a white
    /// pill would be jarring. See PersonHeaderCell.
    enum FocusStyle { case pill, glass }
    var focusStyle: FocusStyle = .pill

    private let restingFill = UIColor.white.withAlphaComponent(0.15)
    private let glassRestingFill = UIColor.white.withAlphaComponent(0.06)

    /// Real Liquid Glass material, behind the color fill. Shows through at
    /// rest, fades out on focus (matches HeroPillButton/HeroCircleButton).
    private let materialBackground = UIVisualEffectView(effect: UIGlassEffect(style: .regular))

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = restingFill
        layer.cornerCurve = .continuous

        materialBackground.translatesAutoresizingMaskIntoConstraints = false
        materialBackground.isUserInteractionEnabled = false
        insertSubview(materialBackground, at: 0)
        NSLayoutConstraint.activate([
            materialBackground.topAnchor.constraint(equalTo: topAnchor),
            materialBackground.bottomAnchor.constraint(equalTo: bottomAnchor),
            materialBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            materialBackground.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        addTarget(self, action: #selector(primary), for: .primaryActionTriggered)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        materialBackground.layer.cornerRadius = layer.cornerRadius
        materialBackground.layer.cornerCurve = .continuous
        materialBackground.clipsToBounds = true
    }

    @objc private func primary() { fireOnce() }

    // On tvOS a bare UIControl's `.primaryActionTriggered` is unreliable for the
    // remote Select press (it's delivered to the FOCUSED view's press handlers).
    // Handle it here too, debounced so primaryActionTriggered + pressesEnded
    // can't double-fire. Mirrors AboutCardControl.
    private var lastFireTime: CFTimeInterval = 0
    private func fireOnce() {
        let now = CACurrentMediaTime()
        guard now - lastFireTime > 0.3 else { return }
        lastFireTime = now
        onPrimaryAction?()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .select }) { return }
        super.pressesBegan(presses, with: event)
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .select }) { fireOnce(); return }
        super.pressesEnded(presses, with: event)
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        let focused = context.nextFocusedView === self
        if focusStyle == .glass {
            // Glass: content stays white; soften the fill, add a hairline border,
            // gentle 1.02 scale (the app's glass-row convention). No invert.
            coordinator.addCoordinatedAnimations { [weak self] in
                guard let self else { return }
                self.transform = focused ? CGAffineTransform(scaleX: 1.02, y: 1.02) : .identity
                self.backgroundColor = focused
                    ? UIColor.white.withAlphaComponent(0.18)
                    : self.glassRestingFill
                self.materialBackground.alpha = focused ? 0 : 1
                self.layer.borderWidth = 1
                self.layer.borderColor = (focused
                    ? UIColor.white.withAlphaComponent(0.25)
                    : UIColor.white.withAlphaComponent(0.08)).cgColor
            }
            return
        }
        coordinator.addCoordinatedAnimations { [weak self] in
            guard let self else { return }
            self.transform = focused ? CGAffineTransform(scaleX: 1.06, y: 1.06) : .identity
            self.backgroundColor = focused ? .white : self.restingFill
            self.materialBackground.alpha = focused ? 0 : 1
            for v in self.invertOnFocus {
                if let iv = v as? UIImageView { iv.tintColor = focused ? .black : .white }
                if let lb = v as? UILabel { lb.textColor = focused ? .black : .white }
            }
            for v in self.invertBackgroundOnFocus {
                v.backgroundColor = focused
                    ? UIColor.black.withAlphaComponent(0.2)
                    : UIColor.white.withAlphaComponent(0.25)
            }
            for v in self.invertFillOnFocus {
                v.backgroundColor = focused
                    ? UIColor.black.withAlphaComponent(0.7)
                    : UIColor.white
            }
        }
    }
}

// LAZY STEAL... GONNA FIX THIS UI bugs....

#if DEBUG
import SwiftUI

#Preview("Action Play pill") {
    UIKitPreviewHost {
        previewPlayPill(title: "Play", progress: nil)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black)
}

#Preview("Action Play pill in progress") {
    UIKitPreviewHost {
        previewPlayPill(title: "S1E3 · 29m", progress: 0.42)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.black)
}

/// Mirrors `SandboxPlayPillsCell.makePlayPill` so the action-row pill can
/// be previewed without pulling in the sandbox tab.
private func previewPlayPill(title: String, progress: Double?) -> FocusableActionButton {
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
#endif
