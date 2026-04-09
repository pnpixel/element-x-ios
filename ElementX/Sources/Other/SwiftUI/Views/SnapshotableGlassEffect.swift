//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

extension View {
    /// Similar to the `.glassProminent` button style, `.glassEffect` breaks our preview tests so this modifier provides a fallback.
    /// https://github.com/pointfreeco/swift-snapshot-testing/issues/1029#issuecomment-3366942138
    func snapshotableGlassEffect(snapshotBackground: Color, in shape: some Shape) -> some View {
        background(snapshotBackground, in: shape)
    }
}
