//
//  ContactCell.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 07/01/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

class ContactCell: UITableViewCell {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
    }
}
