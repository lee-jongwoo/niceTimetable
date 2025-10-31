//
//  Layouts.swift
//  NiceTimetable
//
//  Created by 이종우 on 10/31/25.
//

import SwiftUI

struct TwoColumnFillingLayout: Layout {
    var spacing: CGFloat = 4
    var columnSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        // We’ll just assume full width; height is container-limited
        CGSize(width: proposal.width ?? 0, height: proposal.height ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let totalHeight = proposal.height ?? Optional(bounds.height) else { return }

        let columnWidth = (bounds.width - columnSpacing) / 2
        let xOffsets = [bounds.minX, bounds.minX + columnWidth + columnSpacing]
        var currentColumn = 0
        var yOffsets = [bounds.minY, bounds.minY]

        for subview in subviews {
            let size = subview.sizeThatFits(.init(width: columnWidth, height: nil))

            // Check if adding this would overflow the column height
            if yOffsets[currentColumn] + size.height + spacing > bounds.minY + totalHeight, currentColumn == 0 {
                currentColumn = 1 // switch to next column
            }

            subview.place(
                at: CGPoint(x: xOffsets[currentColumn], y: yOffsets[currentColumn]),
                proposal: .init(width: columnWidth, height: size.height)
            )

            yOffsets[currentColumn] += size.height + spacing
        }
    }
}
