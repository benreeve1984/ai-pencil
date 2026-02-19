import SwiftUI
import SwiftData

/// Root view: NavigationSplitView with a session list sidebar and a
/// workspace detail view showing the chat + canvas for the selected session.
struct ContentView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Session.updatedAt, order: .reverse) private var sessions: [Session]
    @EnvironmentObject private var anthropicService: AnthropicChatService

    @State private var selectedSession: Session?
    @State private var showNewSession = false
    @State private var showSettings = false

    var body: some View {
        NavigationSplitView {
            SessionListView(
                sessions: sessions,
                selectedSession: $selectedSession,
                onDelete: deleteSession
            )
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewSession = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationTitle("Sessions")
        } detail: {
            if let session = selectedSession {
                WorkspaceView(session: session)
                    .id(session.id) // Force recreation on session switch
            } else {
                ContentUnavailableView(
                    "No Session Selected",
                    systemImage: "pencil.and.scribble",
                    description: Text("Create or select a session to start learning.")
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showNewSession) {
            NewSessionSheet { name, topic in
                createSession(name: name, topic: topic)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
    }

    // MARK: - Actions

    private func createSession(name: String, topic: String) {
        let session = Session(name: name, topic: topic)

        // Seed the conversation with the user's topic as the first message
        let topicMessage = ChatMessage(role: .user, text: topic)
        session.messages.append(topicMessage)

        modelContext.insert(session)
        try? modelContext.save()

        selectedSession = session
    }

    private func deleteSession(_ session: Session) {
        if selectedSession?.id == session.id {
            selectedSession = nil
        }
        modelContext.delete(session)
        try? modelContext.save()
    }
}
