import Vision

enum ClassificationPayloadError: Error {
    case missingResults
    case invalidType
}

struct ClassificationItem: Equatable {
    let identifier: String
    let confidence: Float
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
