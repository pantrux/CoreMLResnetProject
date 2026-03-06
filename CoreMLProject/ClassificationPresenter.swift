import Vision

enum ClassificationPayloadError: Error {
    case missingResults
    case invalidType
}

struct ClassificationItem: Equatable {
    let identifier: String
    let confidence: Float
}

protocol ClassificationConfigProviding {
    var topCount: Int { get }
    var minConfidence: Float? { get }
}

struct DefaultClassificationConfig: ClassificationConfigProviding {
    let topCount: Int
    let minConfidence: Float?

    init(topCount: Int = 3, minConfidence: Float? = 0.20) {
        self.topCount = topCount
        self.minConfidence = minConfidence
    }
}

protocol ClassificationResultPresenting {
    func message(for result: Result<[ClassificationItem], ClassificationServiceError>) -> String
}

struct ClassificationResultPresenter: ClassificationResultPresenting {
    let config: ClassificationConfigProviding

    func message(for result: Result<[ClassificationItem], ClassificationServiceError>) -> String {
        switch result {
        case .success(let items):
            return ClassificationPresenter.makeSuccessMessage(
                from: items,
                topCount: config.topCount,
                minConfidence: config.minConfidence
            )
        case .failure(.missingResults(let error)):
            return ClassificationPresenter.makeFailureMessage(for: error)
        case .failure(.invalidResultType):
            return "Resultado inesperado de Vision (tipo inválido)."
        case .failure(.invalidImage):
            return "No se pudo procesar la imagen seleccionada."
        case .failure(.visionFailed(let error)):
            return "Fallo al clasificar: \(error.localizedDescription)"
        }
    }
}

enum ClassificationPresenter {
    static func parsePayload(_ payload: Any?) -> Result<[ClassificationItem], ClassificationPayloadError> {
        guard let payload else {
            return .failure(.missingResults)
        }

        guard let classifications = payload as? [VNClassificationObservation] else {
            return .failure(.invalidType)
        }

        let items = classifications.map {
            ClassificationItem(identifier: $0.identifier, confidence: $0.confidence)
        }

        return .success(items)
    }

    static func makeSuccessMessage(
        from items: [ClassificationItem],
        topCount: Int = 2,
        minConfidence: Float? = nil
    ) -> String {
        guard !items.isEmpty else {
            return "Nada reconocido."
        }

        let filteredItems: [ClassificationItem]
        if let minConfidence {
            filteredItems = items.filter { $0.confidence >= minConfidence }
            guard !filteredItems.isEmpty else {
                return "Sin resultados con confianza suficiente."
            }
        } else {
            filteredItems = items
        }

        let topClassifications = filteredItems.prefix(topCount)
        let descriptions = topClassifications.map { item in
            String(format: "%.2f", item.confidence * 100) + "% " + item.identifier
        }

        return "Clasificación:\n" + descriptions.joined(separator: "\n")
    }

    static func makeFailureMessage(for error: Error?) -> String {
        let detail = error?.localizedDescription ?? "(sin detalle)"
        return "Incapaz de clasificar la imagen.\n\(detail)"
    }
}
