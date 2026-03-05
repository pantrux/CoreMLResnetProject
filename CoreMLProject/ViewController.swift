//
//  ViewController.swift
//  CoreMLProject
//
//  Created by Skynet on 2026-02-27.
//

import UIKit
import CoreML // Importamos CoreML para interactuar con el modelo
import Vision // Importamos Vision para facilitar la integración con Core ML

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
        button.addTarget(self, action: #selector(selectImageTapped), for: .touchUpInside)
        return button
    }()

    let classifyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clasificar Imagen", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(classifyImageTapped), for: .touchUpInside)
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


    // MARK: - Core ML Model
    // Instancia del modelo Core ML.
    // Usamos optional para evitar crash si el modelo no carga.
    lazy var classificationRequest: VNCoreMLRequest? = {
        do {
            // Cargar el modelo generado automáticamente por Core ML
            let model = try VNCoreMLModel(for: Resnet50().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            // El modelo espera una imagen de 224x224, escala la imagen para ajustarse
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            print("⚠️ Failed to load Vision ML model: \(error)")
            return nil
        }
    }()


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()

        if classificationRequest == nil {
            classifyButton.isEnabled = false
            resultLabel.text = "Error: no se pudo cargar el modelo ML."
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
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

        guard let request = classificationRequest else {
            resultLabel.text = "Modelo no disponible. Reinicia la app o verifica el archivo .mlmodel."
            return
        }

        guard let ciImage = CIImage(image: image) else {
            resultLabel.text = "No se pudo procesar la imagen seleccionada."
            return
        }

        // Ejecutar la petición de Vision en un hilo de fondo
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let handler = VNImageRequestHandler(ciImage: ciImage)
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self?.resultLabel.text = "Fallo al clasificar: \(error.localizedDescription)"
                }
            }
        }
    }

    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                let err = error?.localizedDescription ?? "(sin detalle)"
                self.resultLabel.text = "Incapaz de clasificar la imagen.\n\(err)"
                return
            }

            // The classification request handler returns an array of VNClassificationObservation objects.
            guard let classifications = results as? [VNClassificationObservation] else {
                self.resultLabel.text = "Resultado inesperado de Vision (tipo inválido)."
                return
            }

            if classifications.isEmpty {
                self.resultLabel.text = "Nada reconocido."
            } else {
                // Display top 2 classifications
                let topClassifications = classifications.prefix(2)
                let descriptions = topClassifications.map { classification in
                    // Format the classification for display.
                    return String(format: "%.2f", classification.confidence * 100) + "% " + classification.identifier
                }
                self.resultLabel.text = "Clasificación:\n" + descriptions.joined(separator: "\n")
            }
        }
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

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
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
