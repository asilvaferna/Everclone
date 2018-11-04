//
//  NotebookCell.swift
//  Everclone
//
//  Created by Adrián Silva on 31/10/2018.
//  Copyright © 2018 Adrián Silva. All rights reserved.
//

import UIKit

class NotebookCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var creationDateLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = "Placeholder Title"
        creationDateLabel.text = ""
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        creationDateLabel.text = nil
    }

    func configure(with notebook: Notebook) {
        titleLabel.text = notebook.name
        let date = notebook.creationDate! as Date
        creationDateLabel.text = date.creationStringDate()
    }
    
}
