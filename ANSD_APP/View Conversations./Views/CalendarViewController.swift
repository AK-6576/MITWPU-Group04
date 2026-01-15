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

class CalendarViewController: UIViewController {

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

    // Sets up the date picker with inline calendar style and modern action handling
    private func setupDatePicker() {
        datePicker.preferredDatePickerStyle = .inline
        datePicker.datePickerMode = .date
        
        // Modern UIControl API (iOS 14+)
        // Replaces addTarget(_:action:for:) and the @objc selector
        datePicker.addAction(UIAction { [weak self] action in
            guard let self = self, let sender = action.sender as? UIDatePicker else { return }
            self.delegate?.didSelectDate(sender.date)
        }, for: .valueChanged)
    }

    // Dismisses the calendar sheet when the exit button is tapped
    @IBAction func exitButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
