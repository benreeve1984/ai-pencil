import SwiftUI

/// Sheet for creating a new learning session. User provides a name and
/// describes what they want to learn (the initial topic/prompt).
struct NewSessionSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var topic = ""

    let onCreate: (_ name: String, _ topic: String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Session Name") {
                    TextField("e.g., Calculus Practice", text: $name)
                }

                Section("What do you want to learn?") {
                    TextField(
                        "e.g., I want to learn integration by parts",
                        text: $topic,
                        axis: .vertical
                    )
                    .lineLimit(2...5)
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(
                            name.isEmpty ? "Untitled Session" : name,
                            topic.isEmpty ? "Help me practice math" : topic
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}
