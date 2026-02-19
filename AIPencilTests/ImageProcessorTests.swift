import XCTest
@testable import AIPencil

final class ImageProcessorTests: XCTestCase {

    func testResizeDownscalesLargeImage() {
        let size = CGSize(width: 2000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        let resized = ImageProcessor.resize(image, maxDimension: 1024)
        XCTAssertLessThanOrEqual(resized.size.width, 1024)
        XCTAssertLessThanOrEqual(resized.size.height, 1024)
    }

    func testResizePreservesAspectRatio() {
        let size = CGSize(width: 2000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        let resized = ImageProcessor.resize(image, maxDimension: 1024)
        let ratio = resized.size.width / resized.size.height
        XCTAssertEqual(ratio, 2.0, accuracy: 0.01)
    }

    func testResizeDoesNotUpscaleSmallImage() {
        let size = CGSize(width: 500, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.gray.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        let resized = ImageProcessor.resize(image, maxDimension: 1024)
        XCTAssertEqual(resized.size.width, 500)
        XCTAssertEqual(resized.size.height, 300)
    }

    func testGrayscaleConversion() {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        let grayscale = ImageProcessor.convertToGrayscale(image)
        XCTAssertNotNil(grayscale)
        XCTAssertEqual(grayscale.size.width, image.size.width, accuracy: 1.0)
    }
}
