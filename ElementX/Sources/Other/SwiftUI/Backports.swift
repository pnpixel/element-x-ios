//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

extension View {
    // MARK: iOS 26

    func backportTabBarMinimizeBehaviorOnScrollDown() -> some View {
        self
    }

    func backportSafeAreaBar(edge: VerticalEdge,
                             alignment: HorizontalAlignment = .center,
                             spacing: CGFloat? = nil,
                             content: () -> some View) -> some View {
        safeAreaInset(edge: edge, alignment: alignment, spacing: spacing) { content().background(Color.compound.bgCanvasDefault.ignoresSafeArea()) }
    }

    func backportScrollEdgeEffectHidden() -> some View {
        self
    }

    func backportButtonStyleGlass() -> some View {
        self
    }

    func backportButtonStyleGlassProminent() -> some View {
        buttonStyle(.borderedProminent)
    }
}

extension ToolbarContent {
    @ToolbarContentBuilder func backportSharedBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent {
        self
    }
}
