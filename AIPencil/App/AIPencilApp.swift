import SwiftUI
import SwiftData

@main
struct AIPencilApp: App {

    @StateObject private var anthropicService = AnthropicChatService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(anthropicService)
                .onAppear {
                    configureAPIKey()
                }
        }
        .modelContainer(for: [Session.self, ChatMessage.self])
    }

    private func configureAPIKey() {
        // Try Keychain first (production path)
        if let key = KeychainService.shared.loadAPIKey() {
            anthropicService.configure(apiKey: key)
            return
        }

        // DEBUG: Fall back to environment variable for simulator testing
        #if DEBUG
        if let envKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"],
           !envKey.isEmpty {
            anthropicService.configure(apiKey: envKey)
            print("[DEBUG] API key configured from environment variable")
        }
        #endif
    }
}
