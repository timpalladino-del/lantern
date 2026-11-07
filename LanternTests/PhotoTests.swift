import XCTest
import UIKit
@testable import Lantern

final class PhotoTests: XCTestCase {
    private func image(width: CGFloat, height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { ctx in
            UIColor.orange.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    func testAvatarPhotosAreDownscaledToTheLongestSide() {
        let big = image(width: 2000, height: 1000)
        let small = PhotoPickerButton.scaled(big, maxPixels: 800)
        XCTAssertEqual(small.size.width * small.scale, 800, accuracy: 1)
        XCTAssertEqual(small.size.height * small.scale, 400, accuracy: 1)
    }

    func testSmallPhotosAndFullSizeRequestsAreLeftAlone() {
        let img = image(width: 300, height: 500)
        XCTAssertEqual(PhotoPickerButton.scaled(img, maxPixels: 800).size, img.size)
        XCTAssertEqual(PhotoPickerButton.scaled(image(width: 4000, height: 3000), maxPixels: nil).size.width, 4000)
    }

    func testInitialsForNames() {
        XCTAssertEqual(Person.initials(for: "Maria Alvarez"), "MA")
        XCTAssertEqual(Person.initials(for: "leo"), "L")
        XCTAssertEqual(Person.initials(for: ""), "?")
    }
}
