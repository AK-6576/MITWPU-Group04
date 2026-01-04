//
//  RoutineTableViewCell.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 27/11/25.
//

import UIKit

class RoutineTableViewCell1: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var infoButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
