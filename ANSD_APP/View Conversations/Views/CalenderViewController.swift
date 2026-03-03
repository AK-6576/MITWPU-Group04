//
//  CalenderViewController.swift
//  ANSD_APP
//
//  Created by Omkar Varpe on 15/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit

// MARK: - Calendar Delegate
// Protocol for notifying the delegate when a date is selected from the calendar.
protocol CalendarDelegate: AnyObject {
    func didSelectDate(_ date: Date)
}

// MARK: - Calendar View Controller
// Manages the calendar interface, allowing users to filter conversations by date.
class CalenderViewController: UIViewController {

    @IBOutlet weak var datePicker: UIDatePicker!
    
    weak var delegate: CalendarDelegate?

    // Function - Initializes the view lifecycle, calling setup methods for the sheet and date picker.
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSheet()

    }

    // Function - Configures the modal presentation style to be a medium detent (half-screen) with a visible grabber.
    private func setupSheet() {
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
    }


    // Function - Delegate method triggered when the user selects a date, passing the date back to the main controller.
    @objc private func dateChanged(_ sender: UIDatePicker) {
        delegate?.didSelectDate(sender.date)
    }

    // Function - Dismisses the calendar view controller when the exit button is tapped.
    @IBAction func exitButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    
    
    
}
