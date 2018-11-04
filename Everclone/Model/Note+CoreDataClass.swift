//
//  Note+CoreDataClass.swift
//  Everclone
//
//  Created by Adrián Silva on 01/11/2018.
//  Copyright © 2018 Adrián Silva. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Note)
public class Note: NSManagedObject {

}

extension Note {
    func csv() -> String {
        let exportedTitle = title ?? "Default Title"
        let exportedText = text ?? ""
        let exportedCreationDate = (creationDate as Date?)?.creationStringDate() ?? "ND"

        return "\(exportedCreationDate),\(exportedTitle),\(exportedText)"
    }
}
