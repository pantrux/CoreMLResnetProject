import CoreML
import Vision

enum ModelLoaderError: LocalizedError {
    case compiledModelNotFound(String)

    var errorDescription: String? {
        switch self {
        case .compiledModelNotFound(let modelName):
            return "No se encontró \(modelName).mlmodelc en el bundle"
        }
    }
}

enum ModelClassifierFactory {
    static let defaultModelName = "Resnet50"

    static func makeVisionModel(modelName: String = defaultModelName) throws -> VNCoreMLModel {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw ModelLoaderError.compiledModelNotFound(modelName)
        }

        let mlModel = try MLModel(contentsOf: modelURL)
        return try VNCoreMLModel(for: mlModel)
    }

    static func makeRequest(
        modelName: String = defaultModelName,
        completionHandler: VNRequestCompletionHandler? = nil
    ) throws -> VNCoreMLRequest {
        let visionModel = try makeVisionModel(modelName: modelName)

        let request = VNCoreMLRequest(model: visionModel, completionHandler: completionHandler)
        request.imageCropAndScaleOption = .centerCrop
        return request
    }
}
