import SwiftUI

/// A draggable handle between the chat and canvas panes.
///
/// - `isVerticalDivider: true` = vertical line between horizontal panes (landscape)
/// - `isVerticalDivider: false` = horizontal line between vertical panes (portrait)
///
/// The ratio is clamped to [0.25, 0.75] to prevent either pane from collapsing.
struct DraggableDivider: View {

    let isVerticalDivider: Bool
    @Binding var ratio: CGFloat
    let totalSize: CGFloat

    @State private var isDragging = false

    var body: some View {
        ZStack {
            // Background bar
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(
                    width: isVerticalDivider ? 10 : nil,
                    height: isVerticalDivider ? nil : 10
                )

            // Drag handle indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(.systemGray3))
                .frame(
                    width: isVerticalDivider ? 4 : 40,
                    height: isVerticalDivider ? 40 : 4
                )
                .scaleEffect(isDragging ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isDragging)
        }
        .contentShape(Rectangle().size(
            width: isVerticalDivider ? 30 : 10000,
            height: isVerticalDivider ? 10000 : 30
        ))
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    guard totalSize > 0 else { return }
                    isDragging = true
                    let delta = isVerticalDivider
                        ? value.translation.width
                        : value.translation.height
                    let newRatio = ratio + (delta / totalSize) * 0.05
                    ratio = min(
                        Constants.dividerMaxRatio,
                        max(Constants.dividerMinRatio, newRatio)
                    )
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
        .accessibilityLabel("Resize divider")
        .accessibilityHint("Drag to resize the chat and canvas panes")
    }
}
