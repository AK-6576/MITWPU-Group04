//
//  ViewConversationCollection.swift
//  Group_4-ANSD_App
//
//  Created by Omkar Varpe on 26/11/25.
//

import UIKit
import Foundation

class SimpleMonthHeaderView: UICollectionReusableView {
    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // Configures the header label with proper constraints and styling
    private func setupView() {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textColor = .label
    }
}

class ViewConversationCollection: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet weak var searchBarBottomConstraint: NSLayoutConstraint!
    
    var allConversationSections: [ConversationSection] = []
    var conversationSections: [ConversationSection] = []
    var originalBottomConstant: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupCollectionView()
        setupSearchBarUI()
        loadConversationData()
        originalBottomConstant = searchBarBottomConstraint.constant
    }
    
    // Registers keyboard observers when view appears
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // Removes keyboard observers when view disappears
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    // Handles conversation selection and navigates to chat history
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let selectedConversation = conversationSections[indexPath.section].conversations[indexPath.row]
        
        guard let chatVC = self.storyboard?.instantiateViewController(withIdentifier: "ChatHistory2ViewController") as? ChatHistory2ViewController else {
            print("DIAGNOSTIC FAILURE: Could not instantiate chatHistory2ViewController. Check Storyboard ID.")
            return
        }
        
        chatVC.histconversationData = selectedConversation
        
        guard let navController = self.navigationController else {
            print("Error: Navigation Controller missing")
            return
        }
        
        navController.pushViewController(chatVC, animated: true)
        searchBar.resignFirstResponder()
    }
    
    // Provides context menu with pin, rename, and delete options for long press
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            
            let isPinned = self.conversationSections[indexPath.section].conversations[indexPath.row].isPinned
            let pinTitle = isPinned ? "Unpin" : "Pin"
            let pinImage = isPinned ? UIImage(systemName: "pin.slash") : UIImage(systemName: "pin")
            
            let pinAction = UIAction(title: pinTitle, image: pinImage) { action in
                self.conversationSections[indexPath.section].conversations[indexPath.row].isPinned.toggle()
                self.collectionView.reloadItems(at: [indexPath])
            }
            
            let renameAction = UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { action in
                self.showRenameAlert(for: indexPath)
            }
            
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.showDeleteConfirmation(for: indexPath)
            }
            
            return UIMenu(title: "", children: [pinAction, renameAction, deleteAction])
        }
    }
    
    // Displays alert to rename a conversation
    func showRenameAlert(for indexPath: IndexPath) {
        let currentTitle = conversationSections[indexPath.section].conversations[indexPath.row].title
        let alert = UIAlertController(title: "Rename Conversation", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = currentTitle
            textField.autocapitalizationType = .sentences
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                self.conversationSections[indexPath.section].conversations[indexPath.row].title = newName
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // Displays confirmation alert before deleting a conversation
    func showDeleteConfirmation(for indexPath: IndexPath) {
        let alert = UIAlertController(title: "Delete Conversation?", message: "This action cannot be undone.", preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.performSingleDeletion(at: indexPath)
        }
        
        alert.addAction(deleteAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // Removes a conversation from the collection and updates UI
    func performSingleDeletion(at indexPath: IndexPath) {
        collectionView.performBatchUpdates({
            self.conversationSections[indexPath.section].conversations.remove(at: indexPath.row)
            self.collectionView.deleteItems(at: [indexPath])
            
            if self.conversationSections[indexPath.section].conversations.isEmpty {
                self.conversationSections.remove(at: indexPath.section)
                self.collectionView.deleteSections(IndexSet(integer: indexPath.section))
            }
        }, completion: nil)
    }
    
    // Configures search bar appearance with rounded corners and shadow
    func setupSearchBarUI() {
        searchBar.backgroundImage = UIImage()
        searchBar.barTintColor = .clear
        searchBar.backgroundColor = .clear
        searchBar.isTranslucent = true
        searchBar.isUserInteractionEnabled = true
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .white
            textField.textColor = .black
            textField.layer.cornerRadius = 24
            textField.layer.masksToBounds = true
            
            searchBar.layer.shadowColor = UIColor.black.cgColor
            searchBar.layer.shadowOpacity = 0.1
            searchBar.layer.shadowOffset = CGSize(width: 0, height: 4)
            searchBar.layer.shadowRadius = 6
            
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search",
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
            )
        }
    }
    
    // Sets up navigation bar and background colors
    func setupNavBar() {
        collectionView.backgroundColor = .systemGroupedBackground
        view.backgroundColor = .systemGroupedBackground
    }
    
    // Animates search bar and collection view when keyboard appears
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber else { return }
        
        let animationCurve = UIView.AnimationOptions(rawValue: curveValue.uintValue << 16)
        let targetHeight = keyboardFrame.height
        let distanceToLift = targetHeight - view.safeAreaInsets.bottom
        
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [animationCurve],
            animations: {
                self.searchBarBottomConstraint.constant = -distanceToLift + self.originalBottomConstant
                let bottomInset = distanceToLift + self.searchBar.frame.height + 10
                self.collectionView.contentInset.bottom = bottomInset
                self.collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }
    
    // Animates search bar and collection view back to original position when keyboard hides
    @objc func keyboardWillHide(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber else { return }
        
        let animationCurve = UIView.AnimationOptions(rawValue: curveValue.uintValue << 16)
        let originalBottomPadding: CGFloat = 100.0
        
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [animationCurve],
            animations: {
                self.searchBarBottomConstraint.constant = self.originalBottomConstant
                self.collectionView.contentInset.bottom = originalBottomPadding
                self.collectionView.verticalScrollIndicatorInsets.bottom = originalBottomPadding
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }
    
    // Registers cells, headers, and configures collection view layout
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        searchBar.delegate = self
        
        let nib = UINib(nibName: "ConversationCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "conversationCell")
        collectionView.register(SimpleMonthHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "headerId")
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = .zero
            layout.minimumLineSpacing = 8
            let horizontalPadding: CGFloat = 16.0
            let topSpacing: CGFloat = 0
            let bottomSpacing: CGFloat = 12.0
            layout.sectionInset = UIEdgeInsets(top: topSpacing, left: horizontalPadding, bottom: bottomSpacing, right: horizontalPadding)
        }
        
        collectionView.contentInset.bottom = 100
    }
    
    // Loads conversation data from repository and organizes into sections
    func loadConversationData() {
        let response = ConversationsResponse()
        var loadedSections: [ConversationSection] = []
        
        if !response.conversations.isEmpty {
            loadedSections.append(ConversationSection(title: "October", conversations: response.conversations))
        }
        
        for monthData in response.previousMonths {
            loadedSections.append(ConversationSection(title: monthData.month, conversations: monthData.conversations))
        }
        
        allConversationSections = loadedSections
        conversationSections = loadedSections
        collectionView.reloadData()
    }
    
    // Returns the number of sections in the collection view
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return conversationSections.count
    }
    
    // Returns the number of items in each section
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return conversationSections[section].conversations.count
    }
    
    // Configures and returns a cell for the given index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "conversationCell", for: indexPath) as? ConversationCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let item = conversationSections[indexPath.section].conversations[indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    // Configures and returns section headers with month titles
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "headerId", for: indexPath) as! SimpleMonthHeaderView
            header.label.text = conversationSections[indexPath.section].title
            return header
        }
        return UICollectionReusableView()
    }
    
    // Defines the size for each conversation cell
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width - 32, height: 110)
    }
    
    // Defines the size for section headers
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 50)
    }
    
    // Filters conversations based on search text input
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.conversationSections = self.allConversationSections
        } else {
            let lowercasedSearchText = searchText.lowercased()
            self.conversationSections = self.allConversationSections.compactMap { section in
                let filtered = section.conversations.filter { convo in
                    convo.title.lowercased().contains(lowercasedSearchText) ||
                    convo.description.lowercased().contains(lowercasedSearchText)
                }
                return filtered.isEmpty ? nil : ConversationSection(title: section.title, conversations: filtered)
            }
        }
        self.collectionView.reloadData()
    }
    
    // Dismisses keyboard when search button is tapped
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // Data structure to group conversations by month
    struct ConversationSection {
        let title: String
        var conversations: [Conversation]
    }
    
    // Presents calendar view controller as a sheet
    @IBAction func calenderbuttontapped(_ sender: Any) {
        guard let calendarVC = self.storyboard?.instantiateViewController(withIdentifier: "calenderViewController") as? CalenderViewController else {
            print("Error: Could not find calenderViewController in Storyboard. Check the Storyboard ID.")
            return
        }
        
        calendarVC.delegate = self
        
        if let sheet = calendarVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        
        present(calendarVC, animated: true)
    }
}

extension ViewConversationCollection: CalendarDelegate {
    
    // Filters conversations by selected date from calendar
    func didSelectDate(_ date: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let displayDate = formatter.string(from: date)
        
        self.conversationSections = self.allConversationSections.compactMap { section in
            let filtered = section.conversations.filter { convo in
                guard let convoDate = convo.cal else { return false }
                return Calendar.current.isDate(convoDate, inSameDayAs: date)
            }
            return filtered.isEmpty ? nil : ConversationSection(title: section.title, conversations: filtered)
        }

        self.collectionView.reloadData()
        self.navigationItem.title = displayDate
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(clearFilter)
        )
    }
    
    // Clears date filter and restores all conversations
    @objc func clearFilter() {
        self.conversationSections = self.allConversationSections
        self.navigationItem.title = "View Conversations"
        self.navigationItem.rightBarButtonItem = nil
        self.collectionView.reloadData()
    }
}
