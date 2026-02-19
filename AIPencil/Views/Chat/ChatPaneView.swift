import SwiftUI

/// The chat pane: scrollable message list with an input bar at the bottom.
/// Houses the quick action buttons ("I need help", "Finished") and the
/// text input field with send/stop controls.
struct ChatPaneView: View {

    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject var canvasVM: CanvasViewModel

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Message List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.sortedMessages) { message in
                            MessageBubbleView(
                                message: message,
                                onDelete: { viewModel.deleteMessage(message) },
                                onEdit: { newText in
                                    viewModel.editMessage(message, newText: newText)
                                },
                                onRegenerate: message.role == .assistant
                                    ? { viewModel.regenerateResponse(for: message) }
                                    : nil,
                                isStreaming: message.isStreaming
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    scrollToBottom(proxy: proxy, animated: false)
                }
                .onChange(of: viewModel.sortedMessages.last?.text) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.sortedMessages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
            }

            Divider()

            // MARK: - Input Bar
            ChatInputBar(
                text: $viewModel.inputText,
                isStreaming: viewModel.isStreaming,
                isConfigured: true,
                onSend: {
                    let imageBase64 = canvasVM.exportForAPI()
                    viewModel.sendMessage(canvasExportBase64: imageBase64)
                },
                onHelp: {
                    let imageBase64 = canvasVM.exportForAPI()
                    viewModel.sendHelpRequest(canvasExportBase64: imageBase64)
                },
                onFinished: {
                    let imageBase64 = canvasVM.exportForAPI()
                    viewModel.sendFinishedRequest(canvasExportBase64: imageBase64)
                },
                onCancel: {
                    viewModel.cancelStreaming()
                }
            )
        }
        .background(Color(.systemGroupedBackground))
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        if let lastID = viewModel.sortedMessages.last?.id {
            if animated {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            } else {
                proxy.scrollTo(lastID, anchor: .bottom)
            }
        }
    }
}
