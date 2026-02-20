import PencilKit
import UIKit

/// Exports a PKDrawing to a downscaled grayscale JPEG base64 string
/// suitable for sending to the Anthropic Vision API.
///
/// The export pipeline:
/// 1. Crop to stroke bounds (not full canvas) to minimise wasted pixels
/// 2. Normalise for dark-mode: composite on black background then invert,
///    so strokes are always dark on white regardless of canvas theme
/// 3. Convert to grayscale (maths is monochrome — saves file size)
/// 4. Resize to max 1024px on longest edge (~1,400 tokens at 1024x1024)
/// 5. Encode as JPEG base64
struct CanvasExportService {

    /// Export the drawing as a base64-encoded JPEG string.
    /// Returns `nil` if the drawing has no strokes (empty canvas).
    static func exportDrawing(
        _ drawing: PKDrawing,
        canvasBounds: CGRect,
        isDarkCanvas: Bool = false,
        maxDimension: CGFloat = Constants.maxImageDimension,
        jpegQuality: CGFloat = Constants.jpegQuality
    ) -> String? {
        guard !drawing.strokes.isEmpty else { return nil }

        // Crop to actual content with padding
        let drawingBounds = drawing.bounds
        let padding: CGFloat = 20
        let paddedBounds = drawingBounds.insetBy(dx: -padding, dy: -padding)

        // Render at screen scale for crisp output (transparent background)
        let raw = drawing.image(from: paddedBounds, scale: UIScreen.main.scale)

        // Dark canvas: strokes are light-coloured on a transparent background.
        // Composite on black so transparent areas become black, then invert the
        // whole image → dark strokes on white, ready for the AI.
        let normalised: UIImage
        if isDarkCanvas {
            let onBlack = ImageProcessor.composite(raw, on: .black)
            normalised = ImageProcessor.invertColors(onBlack)
        } else {
            normalised = raw
        }

        // Grayscale → resize → JPEG
        let grayscale = ImageProcessor.convertToGrayscale(normalised)
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
