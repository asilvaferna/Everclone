//
//  Date+CustomString.swift
//  Everclone
//
//  Created by Adrián Silva on 31/10/2018.
//  Copyright © 2018 Adrián Silva. All rights reserved.
//

import Foundation

extension Date {
    func creationStringDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current

        return "\(dateFormatter.string(from: self))"
    }
}
