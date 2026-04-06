//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A reaction suggested by a bot via the `com.myorg.suggested_reactions` event content field.
///
/// The field supports two item formats:
/// - A plain emoji string: `"👍"`
/// - An object with emoji and optional label: `{"emoji": "👍", "label": "Нравится"}`
struct SuggestedReaction: Hashable {
    /// The Matrix event content field key used to transmit suggested reactions.
    static let contentKey = "com.myorg.suggested_reactions"

    /// The emoji key used when sending the reaction.
    let emoji: String
    /// An optional human-readable label to display alongside the emoji.
    let label: String?

    /// The text displayed on the chip button: "emoji label" if a label is present, otherwise just "emoji".
    var displayText: String {
        if let label {
            return "\(emoji) \(label)"
        }
        return emoji
    }
}
