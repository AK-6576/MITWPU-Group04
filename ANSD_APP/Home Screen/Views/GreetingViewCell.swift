//
//  GreetingViewCell.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 08/02/26.
//

import UIKit

class GreetingViewCell: UIView {
    
    @IBOutlet weak var helloLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    func configure(name: String) {
        helloLabel.text = "Hello,"
        nameLabel.text = name
    }
}
