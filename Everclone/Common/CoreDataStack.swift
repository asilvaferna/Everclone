//
//  CoreDataStack.swift
//  Everclone
//
//  Created by Adrián Silva on 01/11/2018.
//  Copyright © 2018 Adrián Silva. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {

    public static var shared: CoreDataStack {
        return CoreDataStack(modelName: "Everclone")
    }

    private let modelName: String

    lazy var managedContext: NSManagedObjectContext = {
        return self.storeContainer.viewContext
    }()

    lazy var backgroundContext: NSManagedObjectContext = {
        return self.storeContainer.newBackgroundContext()
    }()

    private init(modelName: String) {
        self.modelName = modelName
    }

    lazy var storeContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: self.modelName)
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Unresolved  error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    func saveContext() {
        guard managedContext.hasChanges else { return }

        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Unresolved error \(error), \(error.userInfo)")
        }
    }
}

