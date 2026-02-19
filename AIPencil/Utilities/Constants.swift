import Foundation
import CoreGraphics

enum Constants {
    static let modelID = "claude-sonnet-4-6"
    static let apiVersion = "2023-06-01"
    static let maxImageDimension: CGFloat = 1024
    static let jpegQuality: CGFloat = 0.7
    static let jpegQualityFallback: CGFloat = 0.3
    static let maxImageSizeBytes = 5 * 1024 * 1024
    static let maxOutputTokens = 4096
    static let temperature = 0.7
    static let dividerMinRatio: CGFloat = 0.25
    static let dividerMaxRatio: CGFloat = 0.75
    static let dividerDefaultRatio: CGFloat = 0.4
    static let keychainServiceKey = "com.aipencil.anthropic-api-key"
    static let canvasSaveDebounceInterval: TimeInterval = 1.0
}
