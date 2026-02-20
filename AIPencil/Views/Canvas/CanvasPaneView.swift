import SwiftUI

/// The canvas pane: PencilKit drawing surface with a floating toolbar
/// for undo, redo, and clear actions.
struct CanvasPaneView: View {

    @ObservedObject var viewModel: CanvasViewModel

    @State private var showClearConfirmation = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PencilCanvasView(viewModel: viewModel)

            // Floating toolbar overlay
            HStack(spacing: 12) {
                Button {
                    viewModel.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title3)
                }
                .disabled(!viewModel.canUndo)

                Button {
                    viewModel.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.title3)
                }
                .disabled(!viewModel.canRedo)

                Divider()
                    .frame(height: 20)

                // Show/hide PencilKit tool picker (pen, highlighter, eraser, etc.)
                Button {
                    viewModel.showToolPicker()
                } label: {
                    Image(systemName: "pencil.tip.crop.circle")
                        .font(.title3)
                }
                .accessibilityLabel("Show pencil tools")

                Divider()
                    .frame(height: 20)

                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(12)
        }
        .confirmationDialog(
            "Clear Canvas",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                viewModel.clearCanvas()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will erase everything on the canvas. This cannot be undone.")
        }
    }
}
