//
//  HeaderCells.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 15/01/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

class HeaderCells: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel?
    @IBOutlet weak var chevronButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .systemBackground
    }
}
