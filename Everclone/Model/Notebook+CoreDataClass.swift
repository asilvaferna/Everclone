//
//  Notebook+CoreDataClass.swift
//  Everclone
//
//  Created by Adrián Silva on 01/11/2018.
//  Copyright © 2018 Adrián Silva. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Notebook)
public class Notebook: NSManagedObject {

}

extension Notebook {
    func csv() -> String {
        let exportedName = name ?? "Default"
        let exportedCreationDate = (creationDate as Date?)?.creationStringDate() ?? "No date"

        var exportedNotes = ""
        notes?
            .map { $0 as? Note }
            .compactMap { $0 }
            .forEach { exportedNotes = "\(exportedNotes)\($0.csv())\n" }

        return "\(exportedCreationDate),\(exportedName)\n\(exportedNotes)"
    }
}
