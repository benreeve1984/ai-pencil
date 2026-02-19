import SwiftData
import Foundation

/// Mock data for SwiftUI previews.
enum PreviewData {

    static var sampleSession: Session {
        let session = Session(name: "Calculus Practice", topic: "I want to learn integration by parts")
        let msg1 = ChatMessage(role: .user, text: "I want to learn integration by parts")
        let msg2 = ChatMessage(
            role: .assistant,
            text: "Great choice! Integration by parts is a powerful technique. Let's start simple. Do you remember the product rule for derivatives? If $f(x) = u(x) \\cdot v(x)$, what is $f'(x)$? Try writing it on the canvas!"
        )
        let msg3 = ChatMessage(role: .user, text: "I wrote it on the canvas — is this right?")
        let msg4 = ChatMessage(
            role: .assistant,
            text: "Looking at your work, you wrote $f'(x) = u'v + uv'$ — that's exactly right! Now, if we integrate both sides, we get:\n\n$$\\int u \\, dv = uv - \\int v \\, du$$\n\nThis is the integration by parts formula. Can you identify what $u$ and $dv$ should be for $\\int x \\, e^x \\, dx$?"
        )
        session.messages = [msg1, msg2, msg3, msg4]
        return session
    }

    @MainActor
    static var previewContainer: ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Session.self, ChatMessage.self,
            configurations: config
        )
        container.mainContext.insert(sampleSession)
        return container
    }
}
