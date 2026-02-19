import SwiftUI
import SwiftData

/// The main workspace view showing chat and canvas side-by-side (landscape)
/// or stacked (portrait). Uses GeometryReader to detect orientation by
/// comparing width vs height — more reliable than UIDevice.orientation on iPad.
struct WorkspaceView: View {

    let session: Session

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var anthropicService: AnthropicChatService

    @StateObject private var canvasVM = CanvasViewModel()
    @State private var chatVM: ChatViewModel?
    @State private var dividerRatio: CGFloat = Constants.dividerDefaultRatio

    var body: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > geometry.size.height

            if isWide {
                // Landscape: Chat LEFT | Divider | Canvas RIGHT
                HStack(spacing: 0) {
                    chatPane
                        .frame(width: geometry.size.width * dividerRatio)

                    DraggableDivider(
                        isVerticalDivider: true,
                        ratio: $dividerRatio,
                        totalSize: geometry.size.width
                    )

                    canvasPane
                        .frame(maxWidth: .infinity)
                }
            } else {
                // Portrait: Chat TOP | Divider | Canvas BOTTOM
                VStack(spacing: 0) {
                    chatPane
                        .frame(height: geometry.size.height * dividerRatio)

                    DraggableDivider(
                        isVerticalDivider: false,
                        ratio: $dividerRatio,
                        totalSize: geometry.size.height
                    )

                    canvasPane
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            let vm = ChatViewModel(
                session: session,
                anthropicService: anthropicService,
                modelContext: modelContext
            )
            chatVM = vm
            canvasVM.loadDrawing(for: session)
            vm.triggerInitialResponseIfNeeded()
        }
        .onDisappear {
            canvasVM.saveDrawing()
            chatVM?.cancelStreaming()
        }
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var chatPane: some View {
        if let chatVM {
            ChatPaneView(viewModel: chatVM, canvasVM: canvasVM)
        } else {
            ProgressView()
        }
    }

    private var canvasPane: some View {
        CanvasPaneView(viewModel: canvasVM)
    }
}
