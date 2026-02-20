import SwiftUI
import LaTeXSwiftUI

/// A single chat message bubble with LaTeX rendering, canvas image thumbnail,
/// and context menu for edit/delete/regenerate actions.
///
/// User messages appear right-aligned in accent color.
/// Assistant messages appear left-aligned in a cream/paper tone with an avatar.
struct MessageBubbleView: View {

    let message: ChatMessage
    let onDelete: () -> Void
    let onEdit: (String) -> Void
    let onRegenerate: (() -> Void)?
    let isStreaming: Bool

    @State private var isEditing = false
    @State private var editText = ""
    @State private var showingFullImage = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant {
                assistantAvatar
            }

            if message.role == .user { Spacer(minLength: 60) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                if isEditing {
                    editView
                } else {
                    contentView
                }

                // Timestamp
                if !isStreaming {
                    Text(message.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .background(bubbleBackground, in: RoundedRectangle(cornerRadius: 16))
            .contextMenu { contextMenuItems }

            if message.role == .assistant { Spacer(minLength: 60) }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        // Canvas image thumbnail (user messages only) — tap to expand
        if let imageBase64 = message.imageBase64,
           let data = Data(base64Encoded: imageBase64),
           let uiImage = UIImage(data: data) {
            Button { showingFullImage = true } label: {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingFullImage) {
                CanvasImageFullScreen(image: uiImage, sentAt: message.createdAt)
            }
        }

        // Text / LaTeX rendering
        if isStreaming && message.text.isEmpty {
            StreamingIndicator()
        } else if isStreaming {
            // Markdown Text during streaming — LaTeX's MathJax renderer is too
            // heavy for real-time updates and blocks the SSE stream processing.
            // AttributedString(markdown:) renders **bold**, *italic*, etc.
            Text(Self.markdownAttributedString(message.text))
                .font(.body)
                .foregroundStyle(message.role == .user ? .white : .primary)
                .textSelection(.enabled)
        } else {
            // Full LaTeX rendering after streaming completes
            LaTeX(message.text)
                .parsingMode(.onlyEquations)
                .errorMode(.original)
                .font(.body)
                .foregroundStyle(message.role == .user ? .white : .primary)
        }
    }

    // MARK: - Edit Mode

    private var editView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            TextEditor(text: $editText)
                .frame(minHeight: 60, maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            HStack(spacing: 12) {
                Button("Cancel") {
                    isEditing = false
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    onEdit(editText)
                    isEditing = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: - Helpers

    /// Convert a String to an AttributedString with markdown rendering.
    /// Falls back to plain text if markdown parsing fails (e.g. unbalanced delimiters).
    private static func markdownAttributedString(_ text: String) -> AttributedString {
        (try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)
    }

    // MARK: - Style

    private var bubbleBackground: some ShapeStyle {
        message.role == .user
            ? AnyShapeStyle(Color.accentColor)
            : AnyShapeStyle(Color(.secondarySystemGroupedBackground))
    }

    private var assistantAvatar: some View {
        Image(systemName: "graduationcap.circle.fill")
            .font(.title2)
            .foregroundStyle(.tint)
            .accessibilityLabel("Tutor")
    }

    // MARK: - Context Menu

    // MARK: - Full-screen canvas image

    @ViewBuilder
    private var contextMenuItems: some View {
        if !isStreaming {
            Button {
                editText = message.text
                isEditing = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            if let onRegenerate {
                Button {
                    onRegenerate()
                } label: {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                }
            }

            Divider()

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Full-screen canvas image sheet

private struct CanvasImageFullScreen: View {
    let image: UIImage
    let sentAt: Date

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .navigationTitle(Text(sentAt, style: .time))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
