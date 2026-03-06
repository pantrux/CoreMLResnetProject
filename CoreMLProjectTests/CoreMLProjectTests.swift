import XCTest
import UIKit
@testable import CoreMLProject

final class CoreMLProjectTests: XCTestCase {
    struct DummyClassificationError: LocalizedError {
        var errorDescription: String? {
            "error-controlado"
        }
    }

    final class MockClassificationService: ImageClassificationServicing {
        var classifyCallCount = 0
        var lastImage: UIImage?
        var result: Result<[ClassificationItem], ClassificationServiceError>

        init(result: Result<[ClassificationItem], ClassificationServiceError>) {
            self.result = result
        }

        func classify(
            image: UIImage,
            completion: @escaping (Result<[ClassificationItem], ClassificationServiceError>) -> Void
        ) {
            classifyCallCount += 1
            lastImage = image
            completion(result)
        }
    }

    func testModelRequestFactoryBuildsClassificationRequest() throws {
        let request = try ModelClassifierFactory.makeRequest(modelName: ModelClassifierFactory.defaultModelName)

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

    func testClassificationMessageSupportsTopThreeWhenRequested() {
        let items = [
            ClassificationItem(identifier: "tabby", confidence: 0.8765),
            ClassificationItem(identifier: "tiger_cat", confidence: 0.5432),
            ClassificationItem(identifier: "chair", confidence: 0.3234),
            ClassificationItem(identifier: "notebook", confidence: 0.2234)
        ]

        let message = ClassificationPresenter.makeSuccessMessage(from: items, topCount: 3)

        XCTAssertEqual(
            message,
            "Clasificación:\n87.65% tabby\n54.32% tiger_cat\n32.34% chair"
        )
        XCTAssertFalse(message.contains("notebook"))
    }

    func testClassificationMessageAppliesConfidenceThreshold() {
        let items = [
            ClassificationItem(identifier: "tabby", confidence: 0.8765),
            ClassificationItem(identifier: "tiger_cat", confidence: 0.5432),
            ClassificationItem(identifier: "chair", confidence: 0.1234)
        ]

        let message = ClassificationPresenter.makeSuccessMessage(
            from: items,
            topCount: 3,
            minConfidence: 0.20
        )

        XCTAssertEqual(
            message,
            "Clasificación:\n87.65% tabby\n54.32% tiger_cat"
        )
        XCTAssertFalse(message.contains("chair"))
    }

    func testClassificationMessageWhenThresholdFiltersEverything() {
        let items = [
            ClassificationItem(identifier: "chair", confidence: 0.1234),
            ClassificationItem(identifier: "table", confidence: 0.1134)
        ]

        let message = ClassificationPresenter.makeSuccessMessage(
            from: items,
            topCount: 3,
            minConfidence: 0.20
        )

        XCTAssertEqual(message, "Sin resultados con confianza suficiente.")
    }

    func testClassificationMessageIncludesItemExactlyAtThreshold() {
        let items = [
            ClassificationItem(identifier: "tabby", confidence: 0.8765),
            ClassificationItem(identifier: "borderline", confidence: 0.20),
            ClassificationItem(identifier: "low", confidence: 0.1999)
        ]

        let message = ClassificationPresenter.makeSuccessMessage(
            from: items,
            topCount: 3,
            minConfidence: 0.20
        )

        XCTAssertEqual(
            message,
            "Clasificación:\n87.65% tabby\n20.00% borderline"
        )
        XCTAssertFalse(message.contains("low"))
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

    func testVisionImageClassificationServiceReturnsInvalidImageForEmptyUIImage() throws {
        let queue = DispatchQueue(label: "VisionImageClassificationServiceTests.queue")
        let sut = try VisionImageClassificationService(
            modelName: ModelClassifierFactory.defaultModelName,
            workerQueue: queue
        )
        let expectation = expectation(description: "Invalid image completion")

        sut.classify(image: UIImage()) { result in
            switch result {
            case .failure(.invalidImage):
                XCTAssertTrue(true)
            default:
                XCTFail("Expected invalidImage error")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testVisionImageClassificationServiceInitThrowsWhenModelDoesNotExist() {
        XCTAssertThrowsError(
            try VisionImageClassificationService(modelName: "ModelThatDoesNotExist")
        ) { error in
            guard case ModelLoaderError.compiledModelNotFound(let modelName) = error else {
                return XCTFail("Expected compiledModelNotFound")
            }
            XCTAssertEqual(modelName, "ModelThatDoesNotExist")
        }
    }

    // MARK: - UI smoke tests

    func testViewControllerInitialUIState() {
        let sut = makeSUT()

        XCTAssertEqual(sut.selectImageButton.title(for: .normal), "Seleccionar Imagen")
        XCTAssertEqual(sut.classifyButton.title(for: .normal), "Clasificar Imagen")
        XCTAssertFalse(sut.classifyButton.isEnabled)
        // No validamos resultLabel aquí para evitar dependencia de carga de modelo en runtime.
    }

    func testUpdateClassificationsWithoutImageShowsPrompt() {
        let sut = makeSUT()

        sut.updateClassifications()

        XCTAssertEqual(
            sut.resultLabel.text,
            "Por favor, selecciona una imagen para clasificar."
        )
    }

    func testUpdateClassificationsWithImageButWithoutModelShowsModelUnavailable() {
        let sut = makeSUT()

        sut.imageView.image = makeDummyImage()
        sut.classificationService = nil

        sut.updateClassifications()

        XCTAssertEqual(
            sut.resultLabel.text,
            "Modelo no disponible. Reinicia la app o verifica el archivo .mlmodel."
        )
    }

    func testUpdateClassificationsUsesInjectedServiceAndRendersSuccess() {
        let sut = makeSUT()
        let expectedItems = [
            ClassificationItem(identifier: "tabby", confidence: 0.8765),
            ClassificationItem(identifier: "tiger_cat", confidence: 0.5432),
            ClassificationItem(identifier: "chair", confidence: 0.3234),
            ClassificationItem(identifier: "notebook", confidence: 0.2234)
        ]
        let service = MockClassificationService(result: .success(expectedItems))
        sut.classificationService = service
        sut.imageView.image = makeDummyImage()

        sut.updateClassifications()
        flushMainQueue()

        XCTAssertEqual(service.classifyCallCount, 1)
        XCTAssertNotNil(service.lastImage)
        XCTAssertEqual(
            sut.resultLabel.text,
            "Clasificación:\n87.65% tabby\n54.32% tiger_cat\n32.34% chair"
        )
        XCTAssertFalse(sut.resultLabel.text?.contains("notebook") ?? false)
    }

    func testUpdateClassificationsUsesInjectedServiceAndRendersEmptySuccess() {
        let sut = makeSUT()
        let service = MockClassificationService(result: .success([]))
        sut.classificationService = service
        sut.imageView.image = makeDummyImage()

        sut.updateClassifications()
        flushMainQueue()

        XCTAssertEqual(service.classifyCallCount, 1)
        XCTAssertEqual(sut.resultLabel.text, "Nada reconocido.")
    }

    func testUpdateClassificationsRendersThresholdMessageWhenNoItemPassesMinimumConfidence() {
        let sut = makeSUT()
        let service = MockClassificationService(result: .success([
            ClassificationItem(identifier: "chair", confidence: 0.1234),
            ClassificationItem(identifier: "table", confidence: 0.1134)
        ]))
        sut.classificationService = service
        sut.imageView.image = makeDummyImage()

        sut.updateClassifications()
        flushMainQueue()

        XCTAssertEqual(service.classifyCallCount, 1)
        XCTAssertEqual(sut.resultLabel.text, "Sin resultados con confianza suficiente.")
    }

    func testUpdateClassificationsUsesInjectedServiceAndRendersFailure() {
        let sut = makeSUT()
        let service = MockClassificationService(result: .failure(.missingResults(DummyClassificationError())))
        sut.classificationService = service
        sut.imageView.image = makeDummyImage()

        sut.updateClassifications()
        flushMainQueue()

        XCTAssertEqual(service.classifyCallCount, 1)
        XCTAssertEqual(sut.resultLabel.text, "Incapaz de clasificar la imagen.\nerror-controlado")
    }

    func testUpdateClassificationsRendersInvalidResultTypeMessage() {
        let sut = makeSUT()
        let service = MockClassificationService(result: .failure(.invalidResultType))
        sut.classificationService = service
        sut.imageView.image = makeDummyImage()

        sut.updateClassifications()
        flushMainQueue()

        XCTAssertEqual(sut.resultLabel.text, "Resultado inesperado de Vision (tipo inválido).")
    }

    func testUpdateClassificationsRendersInvalidImageMessage() {
        let sut = makeSUT()
        let service = MockClassificationService(result: .failure(.invalidImage))
        sut.classificationService = service
        sut.imageView.image = makeDummyImage()

        sut.updateClassifications()
        flushMainQueue()

        XCTAssertEqual(sut.resultLabel.text, "No se pudo procesar la imagen seleccionada.")
    }

    func testUpdateClassificationsRendersVisionFailedMessage() {
        let sut = makeSUT()
        let nsError = NSError(domain: "VisionTests", code: 37, userInfo: [NSLocalizedDescriptionKey: "vision boom"])
        let service = MockClassificationService(result: .failure(.visionFailed(nsError)))
        sut.classificationService = service
        sut.imageView.image = makeDummyImage()

        sut.updateClassifications()
        flushMainQueue()

        XCTAssertEqual(sut.resultLabel.text, "Fallo al clasificar: vision boom")
    }

    func testViewDidLoadWithNilServiceShowsModelLoadError() {
        let sut = ViewController()
        sut.classificationService = nil

        sut.loadViewIfNeeded()

        XCTAssertFalse(sut.classifyButton.isEnabled)
        XCTAssertEqual(sut.resultLabel.text, "Error: no se pudo cargar el modelo ML.")
    }

    func testImagePickerDidFinishPickingEnablesClassificationAndUpdatesLabel() {
        let sut = makeSUT()
        let picker = UIImagePickerController()
        let image = makeDummyImage()

        sut.imagePickerController(picker, didFinishPickingMediaWithInfo: [.originalImage: image])

        XCTAssertEqual(sut.imageView.image?.size, image.size)
        XCTAssertTrue(sut.classifyButton.isEnabled)
        XCTAssertEqual(sut.resultLabel.text, "Imagen seleccionada. Lista para clasificar.")
    }

    // MARK: - Helpers

    private func makeSUT() -> ViewController {
        let sut = ViewController()
        sut.loadViewIfNeeded()
        return sut
    }

    private func makeDummyImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }

    private func flushMainQueue() {
        let expectation = expectation(description: "Flush main queue")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
