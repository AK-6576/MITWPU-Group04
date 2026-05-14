//
//  CategoryTableViewCell.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 15/01/26.
//

//
//  CategoryTableViewCell.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 15/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

// MARK: - Category Table View Cell
// Custom table view cell for displaying categories with a title and interactive chevron.
class CategoryTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var chevronButton: UIButton!

    var onChevronTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.backgroundColor = .systemBackground
        self.backgroundColor = .clear
    }

    // MARK: - Actions
    @IBAction func didTapChevron(_ sender: UIButton) {
        onChevronTapped?()
    }
}
