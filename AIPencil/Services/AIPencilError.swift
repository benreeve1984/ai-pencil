import Foundation

/// Domain errors surfaced to the user via alerts in the chat pane.
enum AIPencilError: LocalizedError {
    case apiKeyNotConfigured
    case modelRefused
    case apiError(String)
    case canvasExportFailed
    case networkUnavailable
    case rateLimited(retryAfter: Int?)
    case contextTooLong

    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "API key not set. Go to Settings to enter your Anthropic API key."
        case .modelRefused:
            return "The AI declined to respond. Try rephrasing your message."
        case .apiError(let message):
            return "API error: \(message)"
        case .canvasExportFailed:
            return "Failed to export canvas drawing."
        case .networkUnavailable:
            return "No internet connection. Check your network and try again."
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Rate limited. Please wait \(seconds) seconds."
            }
            return "Rate limited. Please wait a moment before trying again."
        case .contextTooLong:
            return "Conversation is too long. Start a new session or delete some messages."
        }
    }
}
