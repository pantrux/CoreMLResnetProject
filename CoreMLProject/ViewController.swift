//
//  ViewController.swift
//  CoreMLProject
//
//  Created by Skynet on 2026-02-27.
//

import UIKit

class ViewController: UIViewController {

    // MARK: - UI Elements

    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .lightGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true // Para permitir seleccionar imágenes
        return imageView
    }()

    let selectImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Seleccionar Imagen", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let classifyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clasificar Imagen", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false // Deshabilitado hasta que haya una imagen
        return button
    }()

    let resultLabel: UILabel = {
        let label = UILabel()
        label.text = "Resultado: -"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Classification Service

    lazy var classificationService: ImageClassificationServicing? = ViewController.makeDefaultClassificationService()

    private static func makeDefaultClassificationService() -> ImageClassificationServicing? {
        do {
            return try VisionImageClassificationService(modelName: ModelClassifierFactory.defaultModelName)
        } catch {
            print("⚠️ Failed to load Vision ML model: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()

        if classificationService == nil {
            classifyButton.isEnabled = false
            resultLabel.text = "Error: no se pudo cargar el modelo ML."
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        selectImageButton.addTarget(self, action: #selector(selectImageTapped), for: .touchUpInside)
        classifyButton.addTarget(self, action: #selector(classifyImageTapped), for: .touchUpInside)

        view.addSubview(imageView)
        view.addSubview(selectImageButton)
        view.addSubview(classifyButton)
        view.addSubview(resultLabel)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 250),
            imageView.heightAnchor.constraint(equalToConstant: 250),

            selectImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectImageButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            selectImageButton.widthAnchor.constraint(equalToConstant: 200),
            selectImageButton.heightAnchor.constraint(equalToConstant: 44),

            classifyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            classifyButton.topAnchor.constraint(equalTo: selectImageButton.bottomAnchor, constant: 10),
            classifyButton.widthAnchor.constraint(equalToConstant: 200),
            classifyButton.heightAnchor.constraint(equalToConstant: 44),

            resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultLabel.topAnchor.constraint(equalTo: classifyButton.bottomAnchor, constant: 20),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    // MARK: - Actions

    @objc private func selectImageTapped() {
        presentImagePicker()
    }

    @objc private func classifyImageTapped() {
        resultLabel.text = "Clasificando imagen..."
        updateClassifications()
    }

    // MARK: - Core ML Logic

    func updateClassifications() {
        guard let image = imageView.image else {
            resultLabel.text = "Por favor, selecciona una imagen para clasificar."
            return
        }

        guard let service = classificationService else {
            resultLabel.text = "Modelo no disponible. Reinicia la app o verifica el archivo .mlmodel."
            return
        }

        service.classify(image: image) { [weak self] result in
            DispatchQueue.main.async {
                self?.render(result: result)
            }
        }
    }

    // MARK: - Presentation

    var classificationConfig: ClassificationConfigProviding = DefaultClassificationConfig() {
        didSet {
            resultPresenter = ClassificationResultPresenter(config: classificationConfig)
        }
    }

    var resultPresenter: ClassificationResultPresenting = ClassificationResultPresenter(
        config: DefaultClassificationConfig()
    )

    private func render(result: Result<[ClassificationItem], ClassificationServiceError>) {
        resultLabel.text = resultPresenter.message(for: result)
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)

        if let selectedImage = info[.originalImage] as? UIImage {
            imageView.image = selectedImage
            classifyButton.isEnabled = true // Habilitar el botón de clasificar
            resultLabel.text = "Imagen seleccionada. Lista para clasificar."
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
