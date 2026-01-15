//
//  CategoryTableViewCell.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 15/01/26.
//

import UIKit

class CategoryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var chevronButton: UIButton!
    
    // Callback: Tells the controller which section was tapped
    var onChevronTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Ensure the background is clear/white
        self.contentView.backgroundColor = .systemBackground
        self.backgroundColor = .clear
    }

    // MARK: - Actions
    @IBAction func didTapChevron(_ sender: UIButton) {
        onChevronTapped?()
    }
}
