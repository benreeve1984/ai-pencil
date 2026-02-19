import SwiftUI

/// Sidebar list of all saved sessions, sorted by most recently updated.
struct SessionListView: View {

    let sessions: [Session]
    @Binding var selectedSession: Session?
    let onDelete: (Session) -> Void

    var body: some View {
        List(selection: $selectedSession) {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No Sessions Yet",
                    systemImage: "text.book.closed",
                    description: Text("Tap + to start a new learning session.")
                )
            } else {
                ForEach(sessions) { session in
                    SessionRowView(session: session)
                        .tag(session)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        onDelete(sessions[index])
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
}
