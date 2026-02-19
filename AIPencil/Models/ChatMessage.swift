import SwiftData
import Foundation

/// Represents the role of a chat message participant.
enum MessageRole: String, Codable {
    case user
    case assistant
}

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var role: MessageRole
    var text: String

    /// Base64-encoded JPEG of the canvas snapshot sent with this message.
    /// Only present on user messages that included a non-empty canvas drawing.
    var imageBase64: String?

    var createdAt: Date

    /// True while the assistant response is being streamed. Drives UI state.
    var isStreaming: Bool

    var session: Session?

    init(role: MessageRole, text: String, imageBase64: String? = nil) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.imageBase64 = imageBase64
        self.createdAt = Date()
        self.isStreaming = false
    }
}
