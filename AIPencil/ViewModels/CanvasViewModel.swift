import SwiftUI
import PencilKit
import Combine

/// Manages the PencilKit canvas state, drawing persistence, and image export.
///
/// Owns the PKCanvasView instance to avoid UIViewRepresentable lifecycle issues
/// (SwiftUI can recreate UIViewRepresentable wrappers, losing the UIKit view).
@MainActor
final class CanvasViewModel: ObservableObject {

    let canvasView = PKCanvasView()

    /// Strong reference to the tool picker — if this is deallocated, the picker disappears.
    let toolPicker = PKToolPicker()

    /// When true, both finger and Apple Pencil can draw.
    /// When false, only Apple Pencil draws and fingers scroll/pan.
    @Published var allowFingerDrawing: Bool = false {
        didSet { applyDrawingPolicy() }
    }

    private var session: Session?
    private var saveDebounceTimer: Timer?

    // MARK: - Session Lifecycle

    /// Load the saved drawing data for a session into the canvas.
    /// Falls back to a blank canvas if data is missing or corrupt.
    func loadDrawing(for session: Session) {
        self.session = session

        // REVIEW: Could log deserialization failures for diagnostics
        guard let data = session.canvasData,
              let drawing = try? PKDrawing(data: data) else {
            canvasView.drawing = PKDrawing()
            return
        }
        canvasView.drawing = drawing
    }

    /// Persist the current canvas drawing to the session's SwiftData store.
    /// Called on a debounce timer after each stroke and on session switch/app background.
    func saveDrawing() {
        guard let session else { return }
        session.canvasData = canvasView.drawing.dataRepresentation()
        session.updatedAt = Date()
    }

    /// Schedule a debounced save (avoids excessive writes during rapid drawing).
    func debouncedSave() {
        saveDebounceTimer?.invalidate()
        saveDebounceTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.canvasSaveDebounceInterval,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.saveDrawing()
            }
        }
    }

    // MARK: - Export

    /// Export the current canvas as a base64 JPEG for the Anthropic Vision API.
    /// Returns `nil` if the canvas is empty (no strokes).
    func exportForAPI() -> String? {
        CanvasExportService.exportDrawing(
            canvasView.drawing,
            canvasBounds: canvasView.bounds
        )
    }

    // MARK: - Canvas Actions

    func clearCanvas() {
        canvasView.drawing = PKDrawing()
        saveDrawing()
    }

    func undo() {
        canvasView.undoManager?.undo()
        debouncedSave()
    }

    func redo() {
        canvasView.undoManager?.redo()
        debouncedSave()
    }

    var canUndo: Bool {
        canvasView.undoManager?.canUndo ?? false
    }

    var canRedo: Bool {
        canvasView.undoManager?.canRedo ?? false
    }

    // MARK: - Tool Picker

    /// Re-show the PencilKit tool picker by reclaiming first responder.
    /// The picker hides whenever the canvas loses focus (e.g. tapping into the chat pane).
    func showToolPicker() {
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }

    // MARK: - Drawing Policy

    func applyDrawingPolicy() {
        #if targetEnvironment(simulator)
        canvasView.drawingPolicy = .anyInput
        #else
        canvasView.drawingPolicy = allowFingerDrawing ? .anyInput : .pencilOnly
        #endif
    }
}
