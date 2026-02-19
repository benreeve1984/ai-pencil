import SwiftData
import Foundation

@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var name: String
    var topic: String
    var createdAt: Date
    var updatedAt: Date

    /// PKDrawing.dataRepresentation() — stored externally to avoid bloating the SQLite DB
    @Attribute(.externalStorage) var canvasData: Data?

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
    var messages: [ChatMessage]

    init(name: String, topic: String) {
        self.id = UUID()
        self.name = name
        self.topic = topic
        self.createdAt = Date()
        self.updatedAt = Date()
        self.messages = []
    }

    var sortedMessages: [ChatMessage] {
        messages.sorted { $0.createdAt < $1.createdAt }
    }
}
