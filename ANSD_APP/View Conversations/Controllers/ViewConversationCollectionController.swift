//
//  ViewConversationCollectionController.swift
//  ANSD_APP
//
//  Created by Omkar Varpe on 15/12/25.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit
import Foundation
import SwiftData

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
    
    // Tracks the current filter
    var activeSelectedDate: Date? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupCollectionView()
        setupSearchBarUI()
        loadConversationData()
        originalBottomConstant = searchBarBottomConstraint.constant
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDataUpdate), name: NSNotification.Name("ActionsUpdated"), object: nil)
    }
    
    @objc func handleDataUpdate() {
        DispatchQueue.main.async { [weak self] in
            self?.loadConversationData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
        // ONLY fetch everything if we are NOT currently filtering by a calendar date
        if activeSelectedDate == nil {
            loadConversationData()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let selectedConversation = conversationSections[indexPath.section].conversations[indexPath.row]
        
        guard let chatVC = self.storyboard?.instantiateViewController(withIdentifier: "ChatHistory2ViewController") as? ChatHistoryViewController else { return }
        chatVC.histconversationData = selectedConversation
        
        guard let navController = self.navigationController else { return }
        navController.pushViewController(chatVC, animated: true)
        searchBar.resignFirstResponder()
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let isPinned = self.conversationSections[indexPath.section].conversations[indexPath.row].isPinned
            let pinTitle = isPinned ? "Unpin" : "Pin"
            let pinImage = isPinned ? UIImage(systemName: "pin.slash") : UIImage(systemName: "pin")
            
            let pinAction = UIAction(title: pinTitle, image: pinImage) { action in
                let updatedConvo = self.conversationSections[indexPath.section].conversations[indexPath.row]
                updatedConvo.isPinned.toggle()
                DataManager.shared.saveData()
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
    
    func showRenameAlert(for indexPath: IndexPath) {
        let currentTitle = conversationSections[indexPath.section].conversations[indexPath.row].title
        let alert = UIAlertController(title: "Rename Conversation", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = currentTitle
            textField.autocapitalizationType = .sentences
        }
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                let updatedConvo = self.conversationSections[indexPath.section].conversations[indexPath.row]
                updatedConvo.title = newName
                DataManager.shared.saveData()
                self.collectionView.reloadItems(at: [indexPath])
            }
        }
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func showDeleteConfirmation(for indexPath: IndexPath) {
        let alert = UIAlertController(title: "Delete Conversation?", message: "This action cannot be undone.", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.performSingleDeletion(at: indexPath)
        }
        alert.addAction(deleteAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func performSingleDeletion(at indexPath: IndexPath) {
        let convoToDelete = conversationSections[indexPath.section].conversations[indexPath.row]
        DataManager.shared.deleteConversation(convoToDelete)
        
        collectionView.performBatchUpdates({
            self.conversationSections[indexPath.section].conversations.remove(at: indexPath.row)
            self.collectionView.deleteItems(at: [indexPath])
            if self.conversationSections[indexPath.section].conversations.isEmpty {
                self.conversationSections.remove(at: indexPath.section)
                self.collectionView.deleteSections(IndexSet(integer: indexPath.section))
            }
        }, completion: nil)
    }
    
    func setupSearchBarUI() {
        searchBar.backgroundImage = UIImage()
        searchBar.barTintColor = .clear
        searchBar.backgroundColor = .clear
        searchBar.isTranslucent = true
        searchBar.isUserInteractionEnabled = true
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .clear
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
    
    func setupNavBar() {
        collectionView.backgroundColor = .systemGroupedBackground
        view.backgroundColor = .systemGroupedBackground
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber else { return }
        
        let animationCurve = UIView.AnimationOptions(rawValue: curveValue.uintValue << 16)
        let targetHeight = keyboardFrame.height
        let distanceToLift = targetHeight - view.safeAreaInsets.bottom
        
        UIView.animate(withDuration: duration, delay: 0, options: [animationCurve], animations: {
            self.searchBarBottomConstraint.constant = -distanceToLift + self.originalBottomConstant
            let bottomInset = distanceToLift + self.searchBar.frame.height + 10
            self.collectionView.contentInset.bottom = bottomInset
            self.collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber else { return }
        
        let animationCurve = UIView.AnimationOptions(rawValue: curveValue.uintValue << 16)
        let originalBottomPadding: CGFloat = 100.0
        
        UIView.animate(withDuration: duration, delay: 0, options: [animationCurve], animations: {
            self.searchBarBottomConstraint.constant = self.originalBottomConstant
            self.collectionView.contentInset.bottom = originalBottomPadding
            self.collectionView.verticalScrollIndicatorInsets.bottom = originalBottomPadding
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
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
            let bottomSpacing: CGFloat = 12.0
            layout.sectionInset = UIEdgeInsets(top: 0, left: horizontalPadding, bottom: bottomSpacing, right: horizontalPadding)
        }
        collectionView.contentInset.bottom = 100
    }
    
    func loadConversationData() {
        let allConvos = DataManager.shared.fetchConversations()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        
        var sectionsDict: [String: [Conversation]] = [:]
        var sectionTitles: [String] = []
        
        for convo in allConvos {
            let title = convo.calendarDate != nil ? formatter.string(from: convo.calendarDate!) : "Recent History"
            if sectionsDict[title] == nil {
                sectionsDict[title] = []
                sectionTitles.append(title)
            }
            sectionsDict[title]?.append(convo)
        }
        
        var loadedSections: [ConversationSection] = []
        for title in sectionTitles {
            loadedSections.append(ConversationSection(title: title, conversations: sectionsDict[title]!))
        }
        
        if loadedSections.isEmpty {
            loadedSections = [ConversationSection(title: "No Conversations Found.", conversations: [])]
        }
        
        allConversationSections = loadedSections
        conversationSections = loadedSections
        collectionView.reloadData()
    }
    
    // UPDATED: Properly resets the title and rebuilds the calendar button
    @objc func clearFilter() {
        // 1. Reset the active date
        self.activeSelectedDate = nil
        
        // 2. Reset the navigation bar UI safely using self.title
        self.title = "View Conversations"
        
        // 3. Rebuild the Calendar button and connect it back to your Storyboard action
        let calendarIcon = UIImage(systemName: "calendar")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: calendarIcon,
            style: .plain,
            target: self,
            action: #selector(calenderbuttontapped(_:))
        )
        
        // 4. Reload all data
        self.loadConversationData()
     
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return conversationSections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return conversationSections[section].conversations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "conversationCell", for: indexPath) as? ConversationCollectionViewCell else {
            return UICollectionViewCell()
        }
        let item = conversationSections[indexPath.section].conversations[indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "headerId", for: indexPath) as! SimpleMonthHeaderView
            header.label.text = conversationSections[indexPath.section].title
            return header
        }
        return UICollectionReusableView()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width - 32, height: 110)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 50)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.conversationSections = self.allConversationSections
        } else {
            let lowercasedSearchText = searchText.lowercased()
            self.conversationSections = self.allConversationSections.compactMap { section in
                let filtered = section.conversations.filter { convo in
                    convo.title.lowercased().contains(lowercasedSearchText) ||
                    convo.details.lowercased().contains(lowercasedSearchText)
                }
                return filtered.isEmpty ? nil : ConversationSection(title: section.title, conversations: filtered)
            }
        }
        self.collectionView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    struct ConversationSection {
        let title: String
        var conversations: [Conversation]
    }
    
    @IBAction func calenderbuttontapped(_ sender: Any) {
        guard let calendarVC = self.storyboard?.instantiateViewController(withIdentifier: "calenderViewController") as? CalenderViewController else { return }
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
    
    func didSelectDate(_ date: Date) {
       
        
        self.activeSelectedDate = date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let displayDate = formatter.string(from: date)
        
        // Ask DataManager to fetch only the relevant records
        let filteredConversations = DataManager.shared.fetchConversations(for: date)
        
        // Update UI state
        if filteredConversations.isEmpty {
            self.conversationSections = [ConversationSection(title: "No chats on \(displayDate)", conversations: [])]
        } else {
            self.conversationSections = [ConversationSection(title: displayDate, conversations: filteredConversations)]
        }
        
        self.collectionView.reloadData()
        
        // UPDATED: Update Navigation Bar safely using self.title and boldly stylized Clear button
        self.title = displayDate
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear",
            style: .plain,
            target: self,
            action: #selector(clearFilter)
        )
    
    }
}
