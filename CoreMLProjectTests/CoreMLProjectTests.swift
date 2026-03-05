import XCTest
@testable import CoreMLProject

final class CoreMLProjectTests: XCTestCase {
    func testModelRequestFactoryBuildsClassificationRequest() throws {
        let request = try ModelClassifierFactory.makeRequest()

        XCTAssertEqual(
            request.imageCropAndScaleOption,
            .centerCrop,
            "Unexpected image crop/scale option for Resnet50 request."
        )
    }
}
