//
//  CalenderViewController.swift
//  ANSD_APP
//
//  Created by Omkar Varpe on 15/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

protocol CalendarDelegate: AnyObject {
    func didSelectDate(_ date: Date)
}

class CalenderViewController: UIViewController {

    @IBOutlet weak var datePicker: UIDatePicker!
    weak var delegate: CalendarDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSheet()
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
    }

    private func setupSheet() {
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
    }

    @objc private func dateChanged(_ sender: UIDatePicker) {
        // 1. Send the date to the delegate
        delegate?.didSelectDate(sender.date)
        // 2. Immediately dismiss the calendar
        dismiss(animated: true)
    }

    @IBAction func exitButtonTapped(_ sender: UIButton) {
        // Just close the calendar without triggering a search
        dismiss(animated: true)
    }
}
