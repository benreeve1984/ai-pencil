import SwiftUI
import PencilKit

/// UIViewRepresentable bridge for PKCanvasView.
///
/// Key design decisions:
/// - The PKCanvasView instance lives in CanvasViewModel (not created here)
///   to survive SwiftUI view lifecycle changes.
/// - drawingPolicy = .pencilOnly — finger gestures scroll, only Apple Pencil draws.
/// - The PKToolPicker is shown after the view enters the window hierarchy.
/// - Canvas follows the system dark/light mode. In dark mode the canvas uses a black
///   background with white default ink; exports are inverted before being sent to the AI
///   so strokes always appear dark-on-white.
struct PencilCanvasView: UIViewRepresentable {

    @ObservedObject var viewModel: CanvasViewModel

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = viewModel.canvasView

        viewModel.applyDrawingPolicy()
        canvasView.isOpaque = true
        canvasView.delegate = context.coordinator

        // Record the initial style so updateUIView can detect real changes later.
        context.coordinator.lastAppliedStyle = resolvedStyle
        applyAppearance(to: canvasView, setDefaultTool: true)

        // Show PencilKit tool picker once the view is in the hierarchy
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showToolPicker(for: canvasView)
        }

        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        let style = resolvedStyle
        // Only reset the ink colour when the light/dark style actually changes.
        // Regular SwiftUI redraws must not overwrite a custom colour the user picked.
        let styleChanged = context.coordinator.lastAppliedStyle != style
        if styleChanged {
            context.coordinator.lastAppliedStyle = style
            // Reset so the next becomeFirstResponder() also gets the correct ink
            // (e.g. user switches canvas pane away and back after changing mode).
            viewModel.toolInitialized = false
        }
        applyAppearance(to: uiView, setDefaultTool: styleChanged)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    // MARK: - Appearance

    private var resolvedStyle: UIUserInterfaceStyle {
        colorScheme == .dark ? .dark : .light
    }

    /// Apply the resolved appearance to the canvas and tool picker.
    /// - Parameter setDefaultTool: `true` resets ink to the mode-appropriate default
    ///   (white for dark canvas, black for light). Only pass `true` on first setup or
    ///   when the light/dark style has genuinely changed.
    private func applyAppearance(to canvasView: PKCanvasView, setDefaultTool: Bool) {
        let style = resolvedStyle
        let isDark = style == .dark

        canvasView.overrideUserInterfaceStyle = style
        canvasView.backgroundColor = isDark ? .black : .white

        viewModel.isDarkCanvas = isDark

        // Set the picker's colour scheme FIRST so PencilKit is in the right mode
        // before we apply our explicit tool colour below.
        viewModel.toolPicker.colorUserInterfaceStyle = isDark ? .dark : .light

        if setDefaultTool {
            // Black ink on white canvas; white ink on dark canvas.
            // Setting this AFTER colorUserInterfaceStyle ensures it overrides any
            // colour PencilKit automatically selects for the new mode.
            canvasView.tool = PKInkingTool(.pen, color: isDark ? .white : .black, width: 3)
        }
    }

    // MARK: - Tool Picker

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

        // becomeFirstResponder() causes PencilKit to synchronously apply whatever tool
        // colour it has stored for the current picker mode — potentially a stale white
        // from a previous session. Re-set the mode-correct default on the very first show,
        // after PencilKit has finished its synchronous setup.
        if !viewModel.toolInitialized {
            viewModel.toolInitialized = true
            let isDark = viewModel.isDarkCanvas
            DispatchQueue.main.async {
                canvasView.tool = PKInkingTool(.pen, color: isDark ? .white : .black, width: 3)
            }
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, PKCanvasViewDelegate {
        let viewModel: CanvasViewModel
        /// Tracks the last applied UIUserInterfaceStyle so updateUIView can detect genuine
        /// light↔dark transitions and reset the default ink colour only when needed.
        var lastAppliedStyle: UIUserInterfaceStyle?

        init(viewModel: CanvasViewModel) {
            self.viewModel = viewModel
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            viewModel.debouncedSave()
            // Notify SwiftUI so toolbar re-evaluates canUndo/canRedo
            viewModel.objectWillChange.send()
        }
    }
}
