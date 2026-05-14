//
//  GreetingViewCell.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 08/02/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

class GreetingViewCell: UIView {

    @IBOutlet weak var helloLabel: UILabel!
    @IBOutlet weak var quickConvoView: UIView!
    @IBOutlet weak var newConvoView: UIView!
    @IBOutlet weak var joinConvoView: UIView!

    func configure(name: String) {
        helloLabel.text = "Live Captioning"
    }
}
