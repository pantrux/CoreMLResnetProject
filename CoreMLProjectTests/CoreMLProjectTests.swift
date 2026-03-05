import XCTest
@testable import CoreMLProject

final class CoreMLProjectTests: XCTestCase {
    struct DummyClassificationError: LocalizedError {
        var errorDescription: String? {
            "error-controlado"
        }
    }

    func testModelRequestFactoryBuildsClassificationRequest() throws {
        let request = try ModelClassifierFactory.makeRequest()

        XCTAssertEqual(
            request.imageCropAndScaleOption,
            .centerCrop,
            "Unexpected image crop/scale option for Resnet50 request."
        )
    }

    func testClassificationMessageShowsTopTwoWithPercentages() {
        let items = [
            ClassificationItem(identifier: "tabby", confidence: 0.8765),
            ClassificationItem(identifier: "tiger_cat", confidence: 0.5432),
            ClassificationItem(identifier: "chair", confidence: 0.1234)
        ]

        let message = ClassificationPresenter.makeSuccessMessage(from: items)

        XCTAssertEqual(
            message,
            "Clasificación:\n87.65% tabby\n54.32% tiger_cat"
        )
        XCTAssertFalse(message.contains("chair"))
    }

    func testClassificationMessageForEmptyResults() {
        let message = ClassificationPresenter.makeSuccessMessage(from: [])

        XCTAssertEqual(message, "Nada reconocido.")
    }

    func testParsePayloadReturnsMissingResultsWhenPayloadIsNil() {
        let result = ClassificationPresenter.parsePayload(nil)

        switch result {
        case .failure(.missingResults):
            XCTAssertTrue(true)
        default:
            XCTFail("Expected .missingResults")
        }
    }

    func testParsePayloadReturnsInvalidTypeForUnexpectedPayload() {
        let result = ClassificationPresenter.parsePayload(["not-a-vision-result"])

        switch result {
        case .failure(.invalidType):
            XCTAssertTrue(true)
        default:
            XCTFail("Expected .invalidType")
        }
    }

    func testFailureMessageUsesFallbackAndErrorDescription() {
        let fallbackMessage = ClassificationPresenter.makeFailureMessage(for: nil)
        XCTAssertEqual(fallbackMessage, "Incapaz de clasificar la imagen.\n(sin detalle)")

        let explicitErrorMessage = ClassificationPresenter.makeFailureMessage(for: DummyClassificationError())
        XCTAssertEqual(explicitErrorMessage, "Incapaz de clasificar la imagen.\nerror-controlado")
    }
}
