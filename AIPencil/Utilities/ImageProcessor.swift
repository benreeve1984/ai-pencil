import UIKit
import CoreImage

/// Handles image transformations for canvas export:
/// grayscale conversion and downscaling to reduce API token cost.
struct ImageProcessor {

    private static let ciContext = CIContext()

    /// Convert a UIImage to grayscale using Core Image's CIPhotoEffectMono filter.
    /// Falls back to the original image if conversion fails.
    static func convertToGrayscale(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }

        let filter = CIFilter(name: "CIPhotoEffectMono")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)

        guard let output = filter.outputImage,
              let cgImage = ciContext.createCGImage(output, from: output.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    /// Composite `image` (which may have a transparent background) onto a solid `background` colour.
    /// Used before inverting a dark-mode drawing so the transparent areas become black, not white.
    static func composite(_ image: UIImage, on background: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { ctx in
            background.setFill()
            ctx.fill(CGRect(origin: .zero, size: image.size))
            image.draw(at: .zero)
        }
    }

    /// Invert all pixel colours using CIColorInvert.
    /// Used to convert white-strokes-on-black into black-strokes-on-white for AI export.
    static func invertColors(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }

        let filter = CIFilter(name: "CIColorInvert")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)

        guard let output = filter.outputImage,
              let cgImage = ciContext.createCGImage(output, from: output.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    /// Resize an image so its longest edge is at most `maxDimension` pixels.
    /// Preserves aspect ratio. Returns the original if already within bounds.
    static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
