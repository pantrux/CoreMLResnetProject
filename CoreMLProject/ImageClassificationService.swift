import UIKit
import Vision

enum ClassificationServiceError: Error {
    case invalidImage
    case invalidResultType
    case missingResults(Error?)
    case visionFailed(Error)
}

protocol ImageClassificationServicing {
    func classify(
        image: UIImage,
        completion: @escaping (Result<[ClassificationItem], ClassificationServiceError>) -> Void
    )
}

final class VisionImageClassificationService: ImageClassificationServicing {
    private let visionModel: VNCoreMLModel

    init(modelName: String = ModelClassifierFactory.defaultModelName) throws {
        visionModel = try ModelClassifierFactory.makeVisionModel(modelName: modelName)
    }

    func classify(
        image: UIImage,
        completion: @escaping (Result<[ClassificationItem], ClassificationServiceError>) -> Void
    ) {
        guard let ciImage = CIImage(image: image) else {
            completion(.failure(.invalidImage))
            return
        }

        let request = VNCoreMLRequest(model: visionModel) { request, error in
            switch ClassificationPresenter.parsePayload(request.results) {
            case .success(let items):
                completion(.success(items))
            case .failure(.missingResults):
                completion(.failure(.missingResults(error)))
            case .failure(.invalidType):
                completion(.failure(.invalidResultType))
            }
        }
        request.imageCropAndScaleOption = .centerCrop

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage)
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(.visionFailed(error)))
            }
        }
    }
}
