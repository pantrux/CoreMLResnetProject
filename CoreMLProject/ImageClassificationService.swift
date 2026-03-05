import UIKit
import Vision

enum ClassificationServiceError: Error {
    case invalidImage
    case invalidResultType
    case missingResults(Error?)
    case visionFailed(Error)
}

protocol ImageClassificationServicing {
    /// Clasifica la imagen proporcionada.
    /// - Note: El closure `completion` puede ser invocado en cualquier hilo.
    ///         Los llamadores son responsables de volver al hilo principal si es necesario.
    func classify(
        image: UIImage,
        completion: @escaping (Result<[ClassificationItem], ClassificationServiceError>) -> Void
    )
}

final class VisionImageClassificationService: ImageClassificationServicing {
    private let visionModel: VNCoreMLModel
    private let workerQueue: DispatchQueue

    init(
        modelName: String = ModelClassifierFactory.defaultModelName,
        workerQueue: DispatchQueue = DispatchQueue.global(qos: .userInitiated)
    ) throws {
        visionModel = try ModelClassifierFactory.makeVisionModel(modelName: modelName)
        self.workerQueue = workerQueue
    }

    func classify(
        image: UIImage,
        completion: @escaping (Result<[ClassificationItem], ClassificationServiceError>) -> Void
    ) {
        let completionLock = NSLock()
        var hasResolved = false

        func resolve(_ result: Result<[ClassificationItem], ClassificationServiceError>) {
            completionLock.lock()
            defer { completionLock.unlock() }

            guard !hasResolved else {
                return
            }
            hasResolved = true

            workerQueue.async {
                completion(result)
            }
        }

        guard let ciImage = CIImage(image: image) else {
            resolve(.failure(.invalidImage))
            return
        }

        let request = VNCoreMLRequest(model: visionModel) { request, error in
            switch ClassificationPresenter.parsePayload(request.results) {
            case .success(let items):
                resolve(.success(items))
            case .failure(.missingResults):
                resolve(.failure(.missingResults(error)))
            case .failure(.invalidType):
                resolve(.failure(.invalidResultType))
            }
        }
        request.imageCropAndScaleOption = .centerCrop

        workerQueue.async {
            let handler = VNImageRequestHandler(ciImage: ciImage)
            do {
                try handler.perform([request])
            } catch {
                resolve(.failure(.visionFailed(error)))
            }
        }
    }
}
