import SwiftUI
import PencilKit

/// UIViewRepresentable bridge for PKCanvasView.
///
/// Key design decisions:
/// - The PKCanvasView instance lives in CanvasViewModel (not created here)
///   to survive SwiftUI view lifecycle changes.
/// - drawingPolicy = .pencilOnly — finger gestures scroll, only Apple Pencil draws.
/// - The PKToolPicker is shown after the view enters the window hierarchy.
struct PencilCanvasView: UIViewRepresentable {

    @ObservedObject var viewModel: CanvasViewModel

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = viewModel.canvasView

        viewModel.applyDrawingPolicy()
        // Force light mode so strokes are always black on white — required because
        // the canvas is exported as a JPEG for the AI model, and dark mode would
        // produce white-on-white (invisible) after grayscale conversion.
        canvasView.overrideUserInterfaceStyle = .light
        canvasView.backgroundColor = .systemBackground
        canvasView.isOpaque = true
        canvasView.delegate = context.coordinator

        // Default tool: black pen, medium width
        canvasView.tool = PKInkingTool(.pen, color: .label, width: 3)

        // Show PencilKit tool picker once the view is in the hierarchy
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showToolPicker(for: canvasView)
        }

        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Intentionally empty — the ViewModel owns the drawing state.
        // Avoid resetting the drawing here to prevent losing strokes mid-draw.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    private func showToolPicker(for canvasView: PKCanvasView) {
        guard canvasView.window != nil else {
            // Retry if the view isn't in a window yet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showToolPicker(for: canvasView)
            }
            return
        }

        // Use the ViewModel's tool picker (must be retained — a local var would be deallocated)
        let toolPicker = viewModel.toolPicker
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, PKCanvasViewDelegate {
        let viewModel: CanvasViewModel

        init(viewModel: CanvasViewModel) {
            self.viewModel = viewModel
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            viewModel.debouncedSave()
        }
    }
}
