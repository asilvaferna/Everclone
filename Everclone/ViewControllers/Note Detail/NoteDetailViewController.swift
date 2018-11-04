//
//  NoteDetailViewController.swift
//  Everclone
//
//  Created by Adrián Silva on 31/10/2018.
//  Copyright © 2018 Adrián Silva. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

// MARK:- NoteDetailsViewControllerProtocol

protocol NoteDetailsViewControllerProtocol: class {
    func didSaveNote()
}

final class NoteDetailViewController: UIViewController {

    weak var delegate: NoteDetailsViewControllerProtocol?

    // Kind type
    enum Kind {
        case new(notebook: Notebook)
        case existing(note: Note)
    }

    // MARK: IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!
    @IBOutlet weak var lastSeenDateLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!

    private let kind: Kind
    private let managedContext: NSManagedObjectContext
    private let locationManager = CLLocationManager()
    private var coordinates: (latitude: Double, longitude: Double) = (0, 0)

    init(kind: Kind, managedContext: NSManagedObjectContext) {
        self.kind = kind
        self.managedContext = managedContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: Helper methods

    private func configure() {
        let saveButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveNote))
        self.navigationItem.rightBarButtonItem = saveButtonItem
        let cancelButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        self.navigationItem.leftBarButtonItem = cancelButtonItem

        title = kind.title
        titleTextField.text = kind.note?.title
        //tagsLabel.text = note.tags?.joined(separator: ",")
        creationDateLabel.text = "Creado: \((kind.note?.creationDate as Date?)?.creationStringDate() ?? "ND")"
        lastSeenDateLabel.text = "Visto: \((kind.note?.lastSeenDate as Date?)?.creationStringDate() ?? "ND")"
        descriptionTextView.text = kind.note?.text ?? "Ingrese texto..."

        guard let data = kind.note?.image as Data? else {
            imageView.image = #imageLiteral(resourceName: "note")
            return
        }

        imageView.image = UIImage(data: data)
    }

    @IBAction private func pickImage(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showPhotoMenu()
        } else {
            choosePhotoFromLibrary()
        }
    }

    @objc private func saveNote() {

        func addProperties(to note: Note) -> Note {
            note.title = titleTextField.text
            note.text = descriptionTextView.text

            let imageData: NSData?
            if let image = imageView.image,
                let data = image.pngData() {
                imageData = NSData(data: data)
            } else {
                imageData = nil
            }
            note.image = imageData
            note.latitude = coordinates.latitude
            note.longitude = coordinates.longitude

            return note
        }

        switch kind {
        case .existing(let note):
            let modifiedNote = addProperties(to: note)
            modifiedNote.lastSeenDate = NSDate()

        case .new(let notebook):
            let note = Note(context: managedContext)
            let modifiedNote = addProperties(to: note)
            modifiedNote.creationDate = NSDate()
            modifiedNote.notebook = notebook

            if let notes = notebook.notes?.mutableCopy() as? NSMutableOrderedSet {
                notes.add(note)
                notebook.notes = notes
            }
        }

        do {
            try managedContext.save()
            delegate?.didSaveNote()
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }

        dismiss(animated: true, completion: nil)

    }

    @objc private func cancel() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK:- UIImagePickerControllerDelegate & related methods

extension NoteDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
            return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
        }

        func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
            return input.rawValue
        }

        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        let rawImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage

        let imageSize = CGSize(width: self.imageView.bounds.width * UIScreen.main.scale, height: self.imageView.bounds.height * UIScreen.main.scale)

        DispatchQueue.global(qos: .default).async {
            let image = rawImage?.resizedImageWithContentMode(.scaleAspectFill, bounds: imageSize, interpolationQuality: .high)

            DispatchQueue.main.async {
                if let image = image {
                    self.imageView.contentMode = .scaleAspectFill
                    self.imageView.clipsToBounds = true
                    self.imageView.image = image
                }
            }
        }

        dismiss(animated: true, completion: nil)
    }

    private func showPhotoMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .default, handler: { _ in self.takePhotoWithCamera() })
        let chooseFromLibrary = UIAlertAction(title: "Choose From Library", style: .default, handler: { _ in self.choosePhotoFromLibrary() })

        alertController.addAction(cancelAction)
        alertController.addAction(takePhotoAction)
        alertController.addAction(chooseFromLibrary)

        present(alertController, animated: true, completion: nil)
    }

    private func choosePhotoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }

    private func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
}

extension NoteDetailViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinates = manager.location?.coordinate else { return }
        self.coordinates = (coordinates.latitude, coordinates.longitude)
    }
}

// MARK:- NoteDetailsViewController.Kind extension

private extension NoteDetailViewController.Kind {
    var note: Note? {
        guard case let .existing(note) = self else { return nil }
        return note
    }

    var title: String {
        switch self {
        case .existing:
            return "Detalle"
        case .new:
            return "Nueva Nota"
        }
    }
}
