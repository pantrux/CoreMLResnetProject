//
//  ViewController.swift
//  CoreMLProject
//
//  Created by Skynet on 2026-02-27.
//

import UIKit

class ViewController: UIViewController {

    // MARK: - UI Elements
    // Aquí es donde declararemos los elementos de la UI como UIImageView, UILabel, UIButton.
    // Los inicializaremos en setupUI()

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


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
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
        // Lógica para abrir el UIImagePickerController
        presentImagePicker()
    }

    @objc private func classifyImageTapped() {
        // Lógica para clasificar la imagen con Core ML
        resultLabel.text = "Clasificando imagen..."
        // Aquí llamaremos a nuestra función de Core ML
    }

    // MARK: - Core ML Integration (Coming Soon)
    // Aquí es donde añadiremos el código para cargar y usar el modelo Resnet50.mlmodel
    // Funciones para pre-procesar la imagen y post-procesar el resultado.

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
