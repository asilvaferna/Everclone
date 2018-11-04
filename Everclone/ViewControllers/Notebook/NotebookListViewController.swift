//
//  NotebookListViewController.swift
//  Everclone
//
//  Created by Adrián Silva on 31/10/2018.
//  Copyright © 2018 Adrián Silva. All rights reserved.
//

import UIKit
import CoreData

final class NotebookListViewController: UITableViewController {

    private let coreDataStack: CoreDataStack
    private var fetchedResultsController: NSFetchedResultsController<Notebook>!

    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()

        configureSearchController()

        showAll()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }
}

// MARK: - View Setup Private Methods
private extension NotebookListViewController {
    func setupView() {
        title = "Notebooks"
        tableView.register(UINib(nibName: "NotebookCell", bundle: nil), forCellReuseIdentifier: Constants.kNotebookCell)
    }

    func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNotebook))
        let exportButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(exportCSV))
        navigationItem.rightBarButtonItems = [addButton, exportButtonItem]
    }

    @objc func addNotebook() {
        let alert = UIAlertController(title: "New Notebook", message: "Add new notebook", preferredStyle: .alert)

        let saveAction = UIAlertAction(title: "Save", style: .default) { [unowned self] action in
            guard
                let textField = alert.textFields?.first,
                let nameToSave = textField.text
                else { return }

            let notebook = Notebook(context: self.coreDataStack.managedContext)
            notebook.name = nameToSave
            notebook.creationDate = NSDate()

            do {
                try self.coreDataStack.managedContext.save()
            } catch let error as NSError {
                print("TODO Error handling: \(error.debugDescription)")
            }

            self.showAll()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .default)

        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    func configureSearchController() {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search Notebook"
        navigationItem.searchController = search
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
    }
}

// MARK: - CoreData Private Methods
private extension NotebookListViewController {
    func getFetchedResultsController(with predicate: NSPredicate = NSPredicate(value: true)) -> NSFetchedResultsController<Notebook> {

        let fetchRequest: NSFetchRequest<Notebook> = Notebook.fetchRequest()
        fetchRequest.predicate = predicate

        let sort = NSSortDescriptor(key: #keyPath(Notebook.creationDate), ascending: true)
        fetchRequest.sortDescriptors = [sort]

        fetchRequest.fetchBatchSize = 20

        return NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: coreDataStack.managedContext,
            sectionNameKeyPath: #keyPath(Notebook.creationDate),
            cacheName: nil)
    }

    func setNewFetchedResultsController(_ newfrc: NSFetchedResultsController<Notebook>) {
        let oldfrc = fetchedResultsController
        if (newfrc != oldfrc) {
            fetchedResultsController = newfrc
            newfrc.delegate = self
            do {
                try fetchedResultsController.performFetch()
            } catch let error as NSError {
                print("COuld not fetch \(error)")
            }
            tableView.reloadData()
        }
    }

    @objc func exportCSV() {
        var notebooks: [Notebook] = []

        do {
            notebooks = try self.coreDataStack.managedContext.fetch(Notebook.fetchRequest())
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }

        var csv = ""
        notebooks.forEach { csv = "\(csv)\($0.csv())\n" }

        let activityView = UIActivityViewController(activityItems: [csv], applicationActivities: nil)
        self.present(activityView, animated: true)
    }

    func notesFetchRequest() -> NSFetchRequest<Notebook> {
        let fetchRequest: NSFetchRequest<Notebook> = Notebook.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        return fetchRequest
    }
}

// MARK: - TableView DataSource
extension NotebookListViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let section = fetchedResultsController.sections else { return 1 }
        return section.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultsController.sections?[section] else { return 0 }
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.kNotebookCell, for: indexPath) as! NotebookCell
        // Get the notebook at indexPath
        let notebook = fetchedResultsController.object(at: indexPath)
        // Configure the cell with the given notebook
        cell.configure(with: notebook)

        return cell
    }
}

// MARK: - TableView Delegate Methods
extension NotebookListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notebook = fetchedResultsController.object(at: indexPath)

        let noteListViewController = NoteListViewController(notebook: notebook, coreDataStack: coreDataStack)
        show(noteListViewController, sender: nil)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

// MARK:- UISearchResultsUpdating Methods
extension NotebookListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text, !text.isEmpty {
            // Show filtered results
            showFilteredResults(with: text)
        } else {
            // Show all results
            showAll()
        }
    }

    private func showFilteredResults(with query: String) {
        let predicate = NSPredicate(format: "name CONTAINS[c] %@", query)
        let frc = getFetchedResultsController(with: predicate)
        setNewFetchedResultsController(frc)
    }

    private func showAll() {
        let frc = getFetchedResultsController()
        setNewFetchedResultsController(frc)
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Could not fetch \(error)")
        }
    }
}

// MARK: - NSFetchedResultsController Delegate Methods
extension NotebookListViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        default:
            break
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {

        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            tableView.insertSections(indexSet, with: .automatic)
        case .delete:
            tableView.deleteSections(indexSet, with: .automatic)
        default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
