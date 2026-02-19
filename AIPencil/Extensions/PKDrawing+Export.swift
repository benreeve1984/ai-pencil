import PencilKit
import UIKit

extension PKDrawing {

    /// Convenience to export this drawing as a base64 JPEG for the Anthropic API.
    /// Returns `nil` if the drawing is empty.
    func exportAsBase64JPEG(canvasBounds: CGRect) -> String? {
        CanvasExportService.exportDrawing(self, canvasBounds: canvasBounds)
    }
}
