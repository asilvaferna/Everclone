//
//  NoteCell.swift
//  Everclone
//
//  Created by Adrián Silva on 01/11/2018.
//  Copyright © 2018 Adrián Silva. All rights reserved.
//

import UIKit

class NoteCell: UICollectionViewCell {

    @IBOutlet weak var noteImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configure(with note: Note) {
        let imageData = note.image as Data?
        let image = UIImage(data: imageData ?? Data())
        noteImageView.image = image

        titleLabel.text = note.title

        let date = note.creationDate! as Date
        creationDateLabel.text = date.creationStringDate()
    }

}
