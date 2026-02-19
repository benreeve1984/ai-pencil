import SwiftUI

/// A single row in the session list showing the session name, topic preview,
/// and last-updated timestamp.
struct SessionRowView: View {

    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.name)
                .font(.headline)
                .lineLimit(1)

            Text(session.topic)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Text(session.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("ago")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Text("\(session.messages.count) messages")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
