import SwiftUI
import SwiftData

/// Orchestrates the chat: message CRUD, API streaming, conversation history
/// building, and all user-facing chat actions (send, edit, delete, regenerate).
@MainActor
final class ChatViewModel: ObservableObject {

    // MARK: - Published State

    @Published var inputText: String = ""
    @Published var isStreaming: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Dependencies

    let session: Session
    private let anthropicService: AnthropicChatService
    private let modelContext: ModelContext
    private var currentStreamingTask: Task<Void, Never>?

    init(session: Session, anthropicService: AnthropicChatService, modelContext: ModelContext) {
        self.session = session
        self.anthropicService = anthropicService
        self.modelContext = modelContext
    }

    var sortedMessages: [ChatMessage] {
        session.messages.sorted { $0.createdAt < $1.createdAt }
    }

    // MARK: - Send

    /// Send a message with optional canvas snapshot. Creates the user message,
    /// adds a placeholder assistant message, and starts streaming the response.
    func sendMessage(canvasExportBase64: String?) {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || canvasExportBase64 != nil else { return }
        guard !isStreaming else { return }

        // Persist user message
        let userMessage = ChatMessage(
            role: .user,
            text: text.isEmpty ? "[Canvas drawing submitted]" : text,
            imageBase64: canvasExportBase64
        )
        session.messages.append(userMessage)
        session.updatedAt = Date()
        inputText = ""

        // Create streaming placeholder for the assistant response
        let assistantMessage = ChatMessage(role: .assistant, text: "")
        assistantMessage.isStreaming = true
        session.messages.append(assistantMessage)

        trySave()
        startStreaming(assistantMessage: assistantMessage)
    }

    /// Quick action: "I need help"
    func sendHelpRequest(canvasExportBase64: String?) {
        inputText = "I'm stuck and need help with this step. Can you give me a hint?"
        sendMessage(canvasExportBase64: canvasExportBase64)
    }

    /// Quick action: "Finished"
    func sendFinishedRequest(canvasExportBase64: String?) {
        inputText = "I think I'm done with this problem. Can you check my work?"
        sendMessage(canvasExportBase64: canvasExportBase64)
    }

    // MARK: - Message Management

    /// Delete a message. If it's a user message, also delete all subsequent
    /// messages (since the conversation thread from that point is invalid).
    func deleteMessage(_ message: ChatMessage) {
        if message.role == .user {
            let sorted = sortedMessages
            if let idx = sorted.firstIndex(where: { $0.id == message.id }) {
                for msg in sorted[idx...] {
                    modelContext.delete(msg)
                }
            }
        } else {
            modelContext.delete(message)
        }
        trySave()
    }

    /// Edit a message's text content in-place.
    func editMessage(_ message: ChatMessage, newText: String) {
        message.text = newText
        trySave()
    }

    /// Regenerate an assistant response: delete it and re-stream from the
    /// conversation history up to that point.
    func regenerateResponse(for assistantMessage: ChatMessage) {
        guard assistantMessage.role == .assistant, !isStreaming else { return }

        modelContext.delete(assistantMessage)
        trySave()

        let newAssistant = ChatMessage(role: .assistant, text: "")
        newAssistant.isStreaming = true
        session.messages.append(newAssistant)
        trySave()

        startStreaming(assistantMessage: newAssistant)
    }

    /// Cancel an in-progress streaming response.
    func cancelStreaming() {
        currentStreamingTask?.cancel()
        currentStreamingTask = nil
        isStreaming = false

        for msg in session.messages where msg.isStreaming {
            msg.isStreaming = false
            if msg.text.isEmpty {
                msg.text = "[Response cancelled]"
            }
        }
        trySave()
    }

    /// Trigger the initial AI response for a new session (where the last
    /// message is the user's topic and there's no assistant response yet).
    func triggerInitialResponseIfNeeded() {
        let sorted = sortedMessages
        guard let last = sorted.last, last.role == .user else { return }
        let hasResponse = sorted.contains { $0.role == .assistant }
        guard !hasResponse else { return }

        let assistantMessage = ChatMessage(role: .assistant, text: "")
        assistantMessage.isStreaming = true
        session.messages.append(assistantMessage)
        trySave()

        startStreaming(assistantMessage: assistantMessage)
    }

    // MARK: - Private

    private func startStreaming(assistantMessage: ChatMessage) {
        isStreaming = true

        // Build history from all non-streaming messages
        let history = AnthropicChatService.buildConversationHistory(
            from: sortedMessages.filter { $0.id != assistantMessage.id }
        )

        currentStreamingTask = Task { [weak self] in
            guard let self else { return }

            await self.anthropicService.streamResponse(
                conversationHistory: history,
                systemPrompt: SystemPrompt.tutor,
                onDelta: { [weak self] accumulated in
                    self?.onStreamDelta(assistantMessage, text: accumulated)
                },
                onComplete: { [weak self] finalText in
                    self?.onStreamComplete(assistantMessage, text: finalText)
                },
                onError: { [weak self] error in
                    self?.onStreamError(assistantMessage, error: error)
                }
            )
        }
    }

    private func onStreamDelta(_ message: ChatMessage, text: String) {
        message.text = text
        // Explicitly notify observers so the ForEach/ChatPaneView re-renders.
        // SwiftData @Model is Observable, but the parent ForEach may not
        // re-diff children when only a child's property changes.
        objectWillChange.send()
    }

    private func onStreamComplete(_ message: ChatMessage, text: String) {
        message.text = text
        message.isStreaming = false
        isStreaming = false
        currentStreamingTask = nil
        trySave()
    }

    private func onStreamError(_ message: ChatMessage, error: Error) {
        message.isStreaming = false
        if message.text.isEmpty {
            message.text = "[Error: \(error.localizedDescription)]"
        }
        isStreaming = false
        currentStreamingTask = nil
        errorMessage = error.localizedDescription
        showError = true
        trySave()
    }

    private func trySave() {
        do {
            try modelContext.save()
        } catch {
            // REVIEW: Surface this to the user if it becomes a persistent issue
            print("SwiftData save failed: \(error)")
        }
    }
}
