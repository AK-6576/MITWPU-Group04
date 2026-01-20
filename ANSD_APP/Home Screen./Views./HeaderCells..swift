//
//  HeaderCells..swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 15/01/26.
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
