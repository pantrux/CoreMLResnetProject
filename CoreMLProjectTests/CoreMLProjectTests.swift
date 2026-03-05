import XCTest
@testable import CoreMLProject

final class CoreMLProjectTests: XCTestCase {
    func testModelLoading() {
        let viewController = ViewController()

        XCTAssertNotNil(
            viewController.classificationRequest,
            "Failed to load CoreML model request (Resnet50)."
        )
    }
}
