import SwiftAnthropic
import Foundation

/// Wraps the SwiftAnthropic SDK for our specific needs: streaming chat with
/// vision (canvas images) using Claude Sonnet 4.6 as a Socratic math tutor.
@MainActor
final class AnthropicChatService: ObservableObject {

    @Published var isConfigured: Bool = false

    private var service: (any AnthropicService)?

    // MARK: - Configuration

    func configure(apiKey: String) {
        self.service = AnthropicServiceFactory.service(
            apiKey: apiKey,
            apiVersion: Constants.apiVersion,
            betaHeaders: nil
        )
        self.isConfigured = true
    }

    func reset() {
        self.service = nil
        self.isConfigured = false
    }

    // MARK: - Streaming

    /// Send the full conversation history and stream the assistant's response.
    ///
    /// - Parameters:
    ///   - conversationHistory: All prior messages (rebuilt from SwiftData each call)
    ///   - systemPrompt: The Socratic tutor system prompt
    ///   - onDelta: Called with the accumulated response text on each SSE chunk
    ///   - onComplete: Called once with the final full response text
    ///   - onError: Called if the request or stream fails
    func streamResponse(
        conversationHistory: [MessageParameter.Message],
        systemPrompt: String,
        onDelta: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) async {
        guard let service else {
            onError(AIPencilError.apiKeyNotConfigured)
            return
        }

        let parameters = MessageParameter(
            model: .other(Constants.modelID),
            messages: conversationHistory,
            maxTokens: Constants.maxOutputTokens,
            system: .text(systemPrompt),
            stream: true,
            temperature: Constants.temperature
        )

        do {
            let stream = try await service.streamMessage(parameters)
            var fullText = ""

            for try await response in stream {
                // Check for task cancellation between chunks
                try Task.checkCancellation()

                switch response.streamEvent {
                case .contentBlockDelta:
                    if let text = response.delta?.text {
                        fullText += text
                        onDelta(fullText)
                    }

                case .messageDelta:
                    if let stopReason = response.delta?.stopReason,
                       stopReason == "refusal" {
                        onError(AIPencilError.modelRefused)
                        return
                    }

                case .messageStop:
                    onComplete(fullText)
                    return

                default:
                    break
                }
            }

            // Stream ended without messageStop — treat accumulated text as complete
            if !fullText.isEmpty {
                onComplete(fullText)
            }
        } catch is CancellationError {
            // Task was cancelled (user hit stop or switched sessions) — not an error
            return
        } catch {
            onError(AIPencilError.apiError(error.localizedDescription))
        }
    }

    // MARK: - Conversation History Builder

    /// Build the API message array from persisted ChatMessages.
    ///
    /// Each user message may include an image content block (the canvas snapshot)
    /// followed by a text content block. Assistant messages are text-only.
    static func buildConversationHistory(
        from messages: [ChatMessage]
    ) -> [MessageParameter.Message] {
        let sorted = messages
            .filter { !$0.isStreaming }
            .sorted { $0.createdAt < $1.createdAt }

        return sorted.compactMap { message -> MessageParameter.Message? in
            let role: MessageParameter.Message.Role =
                message.role == .user ? .user : .assistant

            if let imageBase64 = message.imageBase64, message.role == .user {
                // User message with canvas image: image block + text block
                let imageSource = MessageParameter.Message.Content.ImageSource(
                    type: .base64,
                    mediaType: .jpeg,
                    data: imageBase64
                )
                return MessageParameter.Message(
                    role: role,
                    content: .list([
                        .image(imageSource),
                        .text(message.text)
                    ])
                )
            } else {
                // Text-only message (assistant response or user message without image)
                return MessageParameter.Message(
                    role: role,
                    content: .text(message.text)
                )
            }
        }
    }
}
