//
//  HearingCell.swift
//  ANSD_APP
//
//  Created by Daiwiik Harihar on 22/01/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

protocol HearingCellDelegate: AnyObject {
    func didUpdateHearingLevel(value: Float)
}

class HearingCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    
    weak var delegate: HearingCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Style the slider to match Figma (Blue tint)
        slider.minimumValue = 0
        slider.maximumValue = 2
        slider.tintColor = .systemBlue
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        // Snap to steps: 0 (Mild), 1 (Moderate), 2 (Severe)
        let step = round(sender.value)
        sender.setValue(step, animated: false)
        delegate?.didUpdateHearingLevel(value: step)
    }
}
