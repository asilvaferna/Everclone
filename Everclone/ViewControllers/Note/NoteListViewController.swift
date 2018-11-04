//
//  NoteListViewController.swift
//  Everclone
//
//  Created by Adrián Silva on 01/11/2018.
//  Copyright © 2018 Adrián Silva. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class NoteListViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - Properties
    private let notebook: Notebook
    private let coreDataStack: CoreDataStack
    private let animator = Animator()

    private var notes: [Note] = [] {
        didSet {
            self.collectionView.reloadData()
            addNotesToMap()
        }
    }

    // MARK: - Initializers
    init(notebook: Notebook, coreDataStack: CoreDataStack) {
        self.notebook = notebook
        self.notes = (notebook.notes?.array as? [Note]) ?? []
        self.coreDataStack = coreDataStack
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()

        configureNavigationBar()
    }
    
    @IBAction func indexChanged(_ sender: Any) {

        switch segmentedControl.selectedSegmentIndex {
        case 0:
            collectionView.isHidden = false
            mapView.isHidden = true
        case 1:
            collectionView.isHidden = true
            mapView.isHidden = false
        default:
            break
        }
    }
}

// MARK: - Private methods
private extension NoteListViewController {
    func configureView() {
        title = "Notes"
        mapView.showsUserLocation = true

        collectionView.backgroundColor = .white
        collectionView.register(UINib(nibName: "NoteCell", bundle: nil), forCellWithReuseIdentifier: Constants.kNoteCell)
    }

    func addNotesToMap() {
        notes.forEach { note in
            let location = CLLocationCoordinate2D(latitude: note.latitude, longitude: note.longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            mapView.addAnnotation(annotation)
        }
    }

    func configureNavigationBar() {
        let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNote))
        let exportButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(exportCSV))

        self.navigationItem.rightBarButtonItems = [addButtonItem, exportButtonItem]
    }

    func showExportFinishedAlert(_ exportPath: String) {
        let message = "El archivo CSV se encuentra en \(exportPath)"
        let alertController = UIAlertController(title: "Exportacion terminada", message: message, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default)
        alertController.addAction(dismissAction)

        present(alertController, animated: true)
    }

    func notesFetchRequest(from notebook: Notebook) -> NSFetchRequest<Note> {
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "notebook == %@", notebook)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        return fetchRequest
    }
}

// MARK: - Actions
private extension NoteListViewController {
    @objc func addNote() {
        let noteDetailViewController = NoteDetailViewController(kind: .new(notebook: notebook), managedContext: coreDataStack.managedContext)
        noteDetailViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: noteDetailViewController)
        self.present(navigationController, animated: true, completion: nil)
    }

    @objc func exportCSV() {

        coreDataStack.storeContainer.performBackgroundTask { [unowned self] context in

            var results: [Note] = []

            do {
                results = try self.coreDataStack.managedContext.fetch(self.notesFetchRequest(from: self.notebook))
            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
            }

            let exportPath = NSTemporaryDirectory() + "export.csv"
            let exportURL = URL(fileURLWithPath: exportPath)
            FileManager.default.createFile(atPath: exportPath, contents: Data(), attributes: nil)

            let fileHandle: FileHandle?
            do {
                fileHandle = try FileHandle(forWritingTo: exportURL)
            } catch let error as NSError {
                print(error.localizedDescription)
                fileHandle = nil
            }

            if let fileHandle = fileHandle {
                for note in results {
                    fileHandle.seekToEndOfFile()
                    guard let csvData = note.csv().data(using: .utf8, allowLossyConversion: false) else { return }
                    fileHandle.write(csvData)
                }

                fileHandle.closeFile()
                DispatchQueue.main.async { [weak self] in
                    self?.showExportFinishedAlert(exportPath)
                }

            } else {
                print("no podemos exportar la data")
            }
        }

    }
}

// MARK:- UICollectionView Delegate

extension NoteListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let noteDetailViewController = NoteDetailViewController(kind: .existing(note: notes[indexPath.row]), managedContext: coreDataStack.managedContext)
        noteDetailViewController.delegate = self

        // Transition with custom animation
        let navVC = UINavigationController(rootViewController: noteDetailViewController)
        navVC.transitioningDelegate = self
        present(navVC, animated: true, completion: nil)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath)
        headerView.frame.size.height = 100
        return headerView
    }
}

// MARK: - UICollectionView DataSource
extension NoteListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return notes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.kNoteCell, for: indexPath) as! NoteCell
        cell.configure(with: notes[indexPath.row])
        return cell
    }
}

// MARK: - NoteDetailsViewControllerProtocol
extension NoteListViewController: NoteDetailsViewControllerProtocol {
    func didSaveNote() {
        self.notes = (notebook.notes?.array as? [Note]) ?? []
    }
}

// MARK: - UICollectionViewFlowLayout Delegate
extension NoteListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 150)
    }
}

// MARK: - UIViewControllerTransitioning Delegate
extension NoteListViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let indexPath = (collectionView.indexPathsForSelectedItems?.first!)!
        let cell = collectionView.cellForItem(at: indexPath)
        animator.originFrame = cell!.superview!.convert(cell!.frame, to: nil)

        animator.presenting = true

        return animator
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}

extension NoteListViewController: MKMapViewDelegate {
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        addNotesToMap()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }

        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "note") as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "note")
            annotationView!.canShowCallout = true
        } else {
            annotationView!.annotation = annotation
        }

        return annotationView
    }
}
