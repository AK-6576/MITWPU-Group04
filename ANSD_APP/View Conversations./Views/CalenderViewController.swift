//
//  CalendarViewController.swift
//  ANSD_APP
//
//  Created by SDC-USER on 06/01/26.
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
        setupDatePicker()
    }

    private func setupSheet() {
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
    }

    private func setupDatePicker() {
        datePicker.preferredDatePickerStyle = .inline
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
    }

    @objc private func dateChanged(_ sender: UIDatePicker) {
        delegate?.didSelectDate(sender.date)
    }

    @IBAction func exitButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
