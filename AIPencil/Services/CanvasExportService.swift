import PencilKit
import UIKit

/// Exports a PKDrawing to a downscaled grayscale JPEG base64 string
/// suitable for sending to the Anthropic Vision API.
///
/// The export pipeline:
/// 1. Crop to stroke bounds (not full canvas) to minimize wasted pixels
/// 2. Convert to grayscale (math is monochrome — saves file size)
/// 3. Resize to max 1024px on longest edge (~1,400 tokens at 1024x1024)
/// 4. Encode as JPEG base64
struct CanvasExportService {

    /// Export the drawing as a base64-encoded JPEG string.
    /// Returns `nil` if the drawing has no strokes (empty canvas).
    static func exportDrawing(
        _ drawing: PKDrawing,
        canvasBounds: CGRect,
        maxDimension: CGFloat = Constants.maxImageDimension,
        jpegQuality: CGFloat = Constants.jpegQuality
    ) -> String? {
        guard !drawing.strokes.isEmpty else { return nil }

        // Crop to actual content with padding
        let drawingBounds = drawing.bounds
        let padding: CGFloat = 20
        let paddedBounds = drawingBounds.insetBy(dx: -padding, dy: -padding)

        // Render at screen scale for crisp output
        let image = drawing.image(from: paddedBounds, scale: UIScreen.main.scale)

        // Grayscale → resize → JPEG
        let grayscale = ImageProcessor.convertToGrayscale(image)
        let resized = ImageProcessor.resize(grayscale, maxDimension: maxDimension)

        guard let jpegData = resized.jpegData(compressionQuality: jpegQuality) else {
            return nil
        }

        // If still over the 5MB API limit, try lower quality
        if jpegData.count > Constants.maxImageSizeBytes {
            guard let lowerQuality = resized.jpegData(
                compressionQuality: Constants.jpegQualityFallback
            ) else {
                return nil
            }
            return lowerQuality.base64EncodedString()
        }

        return jpegData.base64EncodedString()
    }
}
