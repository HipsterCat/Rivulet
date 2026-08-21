// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Copyright (C) 2025-2026 Bain Gurley

//
//  ConnectionErrorBannerView.swift
//  Rivulet
//
//  RESTORED for the Component Sandbox. Upstream replaced the inline offline
//  banner with a popup plus a playback gate and deleted this view, but
//  ComponentSandboxHostCells still hosts it — so the target stopped compiling.
//  Recovered verbatim from 3c6883a^ rather than gutting the sandbox entry.
//

import UIKit

final class ConnectionErrorBannerView: UIView {

    var onRetry: (() -> Void)?

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let textStack = UIStackView()
    private let rowStack = UIStackView()
    private let backgroundView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setUp() {
        backgroundColor = .clear

        // Rounded yellow-tinted background w/ stroke (matches SwiftUI).
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.15)
        backgroundView.layer.cornerRadius = 16
        backgroundView.layer.cornerCurve = .continuous
        backgroundView.layer.borderWidth = 1
        backgroundView.layer.borderColor = UIColor.systemYellow.withAlphaComponent(0.3).cgColor
        addSubview(backgroundView)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: "wifi.exclamationmark")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold))
        iconView.tintColor = .systemYellow
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.text = "Cannot Connect to Plex"

        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        messageLabel.numberOfLines = 0

        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(messageLabel)

        retryButton.setTitle("Retry", for: .normal)
        retryButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .primaryActionTriggered)
        retryButton.setContentHuggingPriority(.required, for: .horizontal)

        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 14
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        rowStack.addArrangedSubview(iconView)
        rowStack.addArrangedSubview(textStack)
        rowStack.addArrangedSubview(retryButton)
        backgroundView.addSubview(rowStack)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 48),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -48),

            rowStack.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 16),
            rowStack.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -16),
            rowStack.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 24),
            rowStack.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -24)
        ])
    }

    func setMessage(_ message: String?) {
        messageLabel.text = message ?? "Showing cached content"
    }

    @objc private func retryTapped() {
        onRetry?()
    }
}
