// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Copyright (C) 2025-2026 Bain Gurley

#if DEBUG
//
//  ComponentSandboxBridge.swift
//  Rivulet
//
//  SwiftUI host for the DEBUG Components sidebar tab.
//

import SwiftUI
import UIKit

struct ComponentSandboxBridge: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ComponentSandboxViewController {
        ComponentSandboxViewController()
    }

    func updateUIViewController(_ uiViewController: ComponentSandboxViewController, context: Context) {}
}

struct ComponentSandboxContainer: View {
    var body: some View {
        ComponentSandboxBridge()
            .ignoresSafeArea()
    }
}
#endif
