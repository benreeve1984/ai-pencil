import SwiftUI

/// Bottom input bar with text field, send/stop button, and quick action
/// buttons ("I need help", "Finished"). The send button always captures the
/// current canvas state alongside the typed text.
struct ChatInputBar: View {

    @Binding var text: String
    let isStreaming: Bool
    let isConfigured: Bool
    let onSend: () -> Void
    let onHelp: () -> Void
    let onFinished: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Quick action buttons
            HStack(spacing: 12) {
                Button(action: onHelp) {
                    Label("I need help", systemImage: "questionmark.circle")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .disabled(isStreaming || !isConfigured)

                Button(action: onFinished) {
                    Label("Finished", systemImage: "checkmark.circle")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .disabled(isStreaming || !isConfigured)

                Spacer()
            }
            .padding(.horizontal)

            // Text input + send/stop
            HStack(spacing: 8) {
                TextField("Type a message...", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .disabled(isStreaming)

                if isStreaming {
                    Button(action: onCancel) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                    .accessibilityLabel("Stop generating")
                } else {
                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                    .disabled(
                        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || !isConfigured
                    )
                    .accessibilityLabel("Send message")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
    }
}
