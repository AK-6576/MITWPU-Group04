//
//  CalendarViewController.swift
//  ANSD_APP
//
//  Created by SDC-USER on 06/01/26.
//

import UIKit

// Delegate protocol for communicating selected date back to the presenting controller
protocol CalendarDelegate: AnyObject {
    func didSelectDate(_ date: Date)
}

class CalenderViewController: UIViewController {

    @IBOutlet weak var datePicker: UIDatePicker!
    
    weak var delegate: CalendarDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSheet()
        setupDatePicker()
    }

    // Configures the sheet presentation to display as a medium-sized modal
    private func setupSheet() {
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
    }

    // Sets up the date picker with inline calendar style and change detection
    private func setupDatePicker() {
        datePicker.preferredDatePickerStyle = .inline
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
    }

    // Notifies the delegate when the user selects a different date
    @objc private func dateChanged(_ sender: UIDatePicker) {
        delegate?.didSelectDate(sender.date)
    }

    // Dismisses the calendar sheet when the exit button is tapped
    @IBAction func exitButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
