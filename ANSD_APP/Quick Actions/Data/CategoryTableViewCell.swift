//
//  CategoryTableViewCell.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 15/01/26.
//

import UIKit

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
