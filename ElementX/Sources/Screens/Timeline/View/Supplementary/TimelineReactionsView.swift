//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

@MainActor
struct TimelineReactionsView: View {
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection

    let context: TimelineViewModel.Context
    let itemID: TimelineItemIdentifier
    let reactions: [AggregatedReaction]
    let isLayoutRTL: Bool
    
    private var collapsed: Binding<Bool>
    
    init(context: TimelineViewModel.Context,
         itemID: TimelineItemIdentifier,
         reactions: [AggregatedReaction],
         isLayoutRTL: Bool = false) {
        self.context = context
        self.itemID = itemID
        self.reactions = reactions
        self.isLayoutRTL = isLayoutRTL
        
        collapsed = Binding(get: {
            context.reactionsCollapsed[itemID] ?? true
        }, set: {
            context.reactionsCollapsed[itemID] = $0
        })
    }
    
    var reactionsLayoutDirection: LayoutDirection {
        guard isLayoutRTL else { return layoutDirection }
        return layoutDirection == .leftToRight ? .rightToLeft : .leftToRight
    }
    
    var body: some View {
        layout {
            ForEach(reactions) { reaction in
                TimelineReactionButton(reaction: reaction) { key in
                    feedbackGenerator.impactOccurred()
                    context.send(viewAction: .toggleReaction(key: key, itemID: itemID))
                } showReactionSummary: { key in
                    context.send(viewAction: .displayReactionSummary(itemID: itemID, key: key))
                }
                .reactionLayoutItem(.reaction)
                .environment(\.layoutDirection, layoutDirection)
            }
            
            if isCollapsible {
                Button {
                    collapsed.wrappedValue.toggle()
                } label: {
                    TimelineCollapseButtonLabel(collapsed: collapsed.wrappedValue)
                        .transaction { $0.animation = nil }
                }
                .reactionLayoutItem(.expandCollapse)
                .environment(\.layoutDirection, layoutDirection)
            }
            
            Button {
                context.send(viewAction: .displayEmojiPicker(itemID: itemID))
            } label: {
                TimelineReactionAddMoreButtonLabel()
            }
            .reactionLayoutItem(.addMore)
        }
        .environment(\.layoutDirection, reactionsLayoutDirection)
        .animation(.easeInOut(duration: 0.1).disabledDuringTests(), value: reactions)
        .padding(.leading, 4)
    }
    
    // MARK: - Private
    
    private var isCollapsible: Bool {
        reactions.count > 5
    }
    
    private var layout: AnyLayout {
        if isCollapsible {
            return AnyLayout(CollapsibleReactionLayout(itemSpacing: 4,
                                                       rowSpacing: 4,
                                                       collapsed: collapsed.wrappedValue,
                                                       rowsBeforeCollapsible: 2))
        }
        
        return AnyLayout(HStackLayout(spacing: 4.0))
    }
}

/// The pill shape for the label that surrounds both the reaction and collapse buttons.
struct TimelineReactionButtonLabel<Content: View>: View {
    var isHighlighted = false
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        content()
            .background(backgroundShape.inset(by: 1).fill(overlayBackgroundColor))
            .overlay(backgroundShape.inset(by: 2.0).strokeBorder(overlayBorderColor))
            .overlay(backgroundShape.strokeBorder(Color.compound.bgCanvasDefault, lineWidth: 2))
            .accessibilityElement(children: .combine)
    }
    
    var backgroundShape: some InsettableShape {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
    }
    
    var overlayBackgroundColor: Color {
        isHighlighted ? Color.compound.bgSubtlePrimary : .compound.bgSubtleSecondary
    }
    
    var overlayBorderColor: Color {
        isHighlighted ? Color.compound.borderInteractivePrimary : .clear
    }
}

struct TimelineCollapseButtonLabel: View {
    var collapsed: Bool
    @ScaledMetric(relativeTo: .subheadline) private var lineHeight = 20
    
    var body: some View {
        TimelineReactionButtonLabel {
            Text(collapsed ? L10n.screenRoomTimelineReactionsShowMore : L10n.screenRoomTimelineReactionsShowLess)
                .frame(height: lineHeight, alignment: .center)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
        }
    }
}

struct TimelineReactionButton: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    
    let reaction: AggregatedReaction
    let toggleReaction: (String) -> Void
    let showReactionSummary: (String) -> Void
    @ScaledMetric(relativeTo: .subheadline) private var lineHeight = 20
    
    private var accessibilityLabel: String {
        if reaction.isHighlighted {
            return reaction.count > 1 ? L10n.tr("Localizable", "screen_room_timeline_reaction_including_you_a11y", reaction.count - 1, reaction.displayKey) : L10n.screenRoomTimelineReactionYouA11y(reaction.displayKey)
        }
        return L10n.tr("Localizable", "screen_room_timeline_reaction_a11y", reaction.count, reaction.displayKey)
    }
    
    private var toggleReactionAccessibilityActionName: String {
        reaction.isHighlighted ? L10n.a11yRemoveReaction(reaction.displayKey) : L10n.a11yAddReaction(reaction.displayKey)
    }
    
    var body: some View {
        label
            .onTapGesture {
                toggleReaction(reaction.key)
            }
            .longPressWithFeedback {
                showReactionSummary(reaction.key)
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(toggleReactionAccessibilityActionName)
            .accessibilityAction(named: L10n.screenRoomTimelineReactionsShowReactionsSummary) {
                showReactionSummary(reaction.key)
            }
    }
    
    var label: some View {
        TimelineReactionButtonLabel(isHighlighted: reaction.isHighlighted) {
            HStack(spacing: 4) {
                // Designs have bodyMD for the key but practically this makes
                // emojis too big. bodySM gives a more appropriate size when compared
                // to the count text and the lineHeight/padding in the designs.
                Text(reaction.displayKey)
                    .font(.compound.bodySM)
                if reaction.count > 1 {
                    Text(String(reaction.count))
                        .font(.compound.bodyMD)
                        .foregroundColor(textColor)
                }
            }
            .frame(height: lineHeight, alignment: .center)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
        }
    }
    
    var textColor: Color {
        reaction.isHighlighted ? Color.compound.textPrimary : .compound.textSecondary
    }
}

struct TimelineReactionAddMoreButtonLabel: View {
    var body: some View {
        TimelineReactionButtonLabel {
            CompoundIcon(\.reactionAdd, size: .xSmall, relativeTo: .compound.bodySM)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .foregroundColor(.compound.iconSecondary)
                .accessibilityLabel(L10n.actionReact)
        }
    }
}

// MARK: - Suggested Reactions

/// A row of chip buttons for bot-suggested reactions, shown above regular reactions
/// until the current user has reacted with any of the suggested emojis.
@MainActor
struct SuggestedReactionsView: View {
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)

    let context: TimelineViewModel.Context
    let itemID: TimelineItemIdentifier
    let suggestions: [SuggestedReaction]

    var body: some View {
        SuggestedReactionsLayout(suggestions: suggestions) { suggestion, isTruncated in
            Button {
                feedbackGenerator.impactOccurred()
                context.send(viewAction: .toggleReaction(key: suggestion.emoji, itemID: itemID))
            } label: {
                SuggestedReactionButtonLabel(text: suggestion.displayText, isTruncated: isTruncated)
            }
        }
        .padding(.leading, 4)
    }
}

struct SuggestedReactionButtonLabel: View {
    let text: String
    var isTruncated = false
    @ScaledMetric(relativeTo: .subheadline) private var lineHeight = 20
    private let fadeWidth: CGFloat = 24

    var body: some View {
        TimelineReactionButtonLabel {
            Text(text)
                .font(.compound.bodySM)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: lineHeight, alignment: .center)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .foregroundColor(.compound.textSecondary)
                .overlay(alignment: .trailing) {
                    if isTruncated {
                        LinearGradient(colors: [.compound.bgSubtleSecondary.opacity(0),
                                                .compound.bgSubtleSecondary],
                                       startPoint: .leading,
                                       endPoint: .trailing)
                            .frame(width: fadeWidth)
                            .padding(.vertical, 6)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
}

/// A view that lays out suggested reactions using SuggestedReactionsFlowLayout,
/// passing `isTruncated` to each button based on whether it was compressed.
struct SuggestedReactionsLayout<ButtonContent: View>: View {
    let suggestions: [SuggestedReaction]
    let buttonBuilder: (SuggestedReaction, Bool) -> ButtonContent

    @State private var containerWidth: CGFloat = 0

    var body: some View {
        SuggestedReactionsFlowLayout(spacing: 4) {
            ForEach(suggestions, id: \.emoji) { suggestion in
                buttonBuilder(suggestion, isTruncated(for: suggestion))
            }
        }
        .background(GeometryReader { geo in
            Color.clear
                .onAppear { containerWidth = geo.size.width }
                .onChange(of: geo.size.width) { _, newValue in containerWidth = newValue }
        })
    }

    private func isTruncated(for suggestion: SuggestedReaction) -> Bool {
        guard containerWidth > 0 else { return false }
        let font = UIFont.preferredFont(forTextStyle: .footnote)
        let textWidth = (suggestion.displayText as NSString)
            .size(withAttributes: [.font: font]).width
        // Add padding (12 + 12) + border (2 + 2) + some margin
        let buttonNaturalWidth = textWidth + 28
        return buttonNaturalWidth > containerWidth
    }
}

/// Flow layout that fills remaining row space with oversized items.
///
/// Short items keep their natural width. Items wider than the remaining space
/// are compressed to fill the rest of the row (and get a fade-out via FadingText).
/// A minimum width threshold prevents items from being squeezed too small —
/// they wrap to the next line instead.
struct SuggestedReactionsFlowLayout: Layout {
    var spacing: CGFloat = 4
    /// If an item would be squeezed below this fraction of the row width, wrap it instead.
    private let minWidthFraction: CGFloat = 0.3

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        var height: CGFloat = 0
        for (index, row) in rows.enumerated() {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight + (index > 0 ? spacing : 0)
        }
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            let usedByFixed = row.map { min($0.sizeThatFits(.unspecified).width, maxWidth) }.reduce(0, +)
                + CGFloat(max(row.count - 1, 0)) * spacing

            for subview in row {
                let idealWidth = subview.sizeThatFits(.unspecified).width
                let remainingWidth = maxWidth - x + bounds.minX
                let width: CGFloat
                if idealWidth <= remainingWidth {
                    width = idealWidth
                } else {
                    width = remainingWidth
                }
                let height = subview.sizeThatFits(.unspecified).height
                subview.place(at: CGPoint(x: x, y: y),
                              proposal: ProposedViewSize(width: width, height: height))
                x += width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [[LayoutSubview]] {
        var rows = [[LayoutSubview]]()
        var currentRow = [LayoutSubview]()
        var currentWidth: CGFloat = 0
        let minItemWidth = maxWidth * minWidthFraction

        for subview in subviews {
            let idealWidth = subview.sizeThatFits(.unspecified).width
            let remainingWidth = maxWidth - currentWidth - (currentRow.isEmpty ? 0 : spacing)

            if currentRow.isEmpty {
                // First item always goes on current row
                currentRow.append(subview)
                currentWidth = min(idealWidth, maxWidth)
            } else if idealWidth <= remainingWidth {
                // Fits naturally
                currentRow.append(subview)
                currentWidth += spacing + idealWidth
            } else if remainingWidth >= minItemWidth {
                // Doesn't fit naturally but there's enough room to show it truncated
                currentRow.append(subview)
                currentWidth = maxWidth
            } else {
                // Not enough room — wrap to next line
                rows.append(currentRow)
                currentRow = [subview]
                currentWidth = min(idealWidth, maxWidth)
            }
        }
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        return rows
    }
}

struct TimelineReactionViewPreviewsContainer: View {
    var body: some View {
        VStack(spacing: 8) {
            TimelineReactionsView(context: TimelineViewModel.mock.context,
                                  itemID: .randomEvent,
                                  reactions: [AggregatedReaction.mockReactionWithLongText,
                                              AggregatedReaction.mockReactionWithLongTextRTL])
            Divider()
            TimelineReactionsView(context: TimelineViewModel.mock.context,
                                  itemID: .randomEvent,
                                  reactions: Array(AggregatedReaction.mockReactions.prefix(3)))
            Divider()
            TimelineReactionsView(context: TimelineViewModel.mock.context,
                                  itemID: .randomEvent,
                                  reactions: AggregatedReaction.mockReactions)
            Divider()
            TimelineReactionsView(context: TimelineViewModel.mock.context,
                                  itemID: .randomEvent,
                                  reactions: AggregatedReaction.mockReactions,
                                  isLayoutRTL: true)
        }
        .background(Color.red)
        .frame(maxWidth: 250, alignment: .leading)
    }
}

struct TimelineReactionView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        TimelineReactionViewPreviewsContainer()
    }
}
