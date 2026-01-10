


import UIKit




protocol CalendarDelegate: AnyObject {
    func didSelectDate(_ date: Date)
}
class CalenderViewController: UIViewController {

    // MARK: - Outlets
    // In Storyboard, drag a 'Date Picker' and connect it to this outlet
    @IBOutlet weak var datePicker: UIDatePicker!
    
    weak var delegate: CalendarDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSheet()
        setupDatePicker()
    }

    private func setupSheet() {
        if let sheet = self.sheetPresentationController {
            sheet.detents = [.medium()] // Half screen is perfect for DatePicker
            sheet.prefersGrabberVisible = true
        }
    }

    private func setupDatePicker() {
        // Sets the style to the modern 'Inline' calendar look
        datePicker.preferredDatePickerStyle = .inline
        datePicker.datePickerMode = .date
        
        // Add action to detect when the user changes the date
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
    }

    @objc func dateChanged(_ sender: UIDatePicker) {
        // Send the selected date back to the main screen
        delegate?.didSelectDate(sender.date)
    }

    @IBAction func exitButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
