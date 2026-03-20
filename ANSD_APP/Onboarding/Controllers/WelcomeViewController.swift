//
//  WelcomeViewController.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 19/02/26.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//

import UIKit
import GoogleSignIn
import FirebaseAuth

class WelcomeViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var appleSignInButton: UIButton!
    @IBOutlet weak var googleSignInButton: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // App logo styling
        logoImageView.layer.cornerRadius = 20
        logoImageView.clipsToBounds = true
        
        // Apple Sign In styling
        appleSignInButton.layer.cornerRadius = 25
        appleSignInButton.backgroundColor = .black
        appleSignInButton.setTitleColor(.white, for: .normal)
        
        // Google Sign In styling (Capsule shape with border)
        googleSignInButton.layer.cornerRadius = 25
        googleSignInButton.layer.borderWidth = 1
        googleSignInButton.layer.borderColor = UIColor.systemGray3.cgColor
        googleSignInButton.backgroundColor = .white
        
        var googleConfig = UIButton.Configuration.plain()
        if let googleIcon = UIImage(named: "Google")?.withRenderingMode(.alwaysOriginal) {
            let resizedIcon = googleIcon.resized(to: CGSize(width: 24, height: 24))
            googleConfig.image = resizedIcon
        }
        googleConfig.imagePadding = 12
        googleConfig.titleAlignment = .center
        
        var googleTitle = AttributedString("Sign in with Google")
        googleTitle.font = .systemFont(ofSize: 17, weight: .medium)
        googleTitle.foregroundColor = .black
        googleConfig.attributedTitle = googleTitle
        
        googleSignInButton.configuration = googleConfig
        
        // Secondary action buttons styling
        let secondaryButtons = [createAccountButton, loginButton]
        for button in secondaryButtons {
            button?.layer.cornerRadius = 25
            button?.layer.borderWidth = 1
            button?.layer.borderColor = UIColor.systemGray4.cgColor
        }
        
        createAccountButton.setTitle("Sign Up", for: .normal)
        loginButton.setTitle("Sign In", for: .normal)
    }

    // MARK: - Actions
    @IBAction func appleSignInTapped(_ sender: UIButton) {
        // Handle Apple Sign In
    }
    
    @IBAction func googleSignInTapped(_ sender: UIButton) {
        // Show loading if possible (optional, but good practice)
        googleSignInButton.isEnabled = false
        
        FirebaseManager.shared.signInWithGoogle(presenting: self) { [weak self] result in
            DispatchQueue.main.async {
                self?.googleSignInButton.isEnabled = true
                
                switch result {
                case .success(let user):
                    self?.restoreUserAndNavigate(user: user)
                    
                case .failure(let error):
                    self?.showAlert(title: "Sign In Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func restoreUserAndNavigate(user: User) {
        let uid = user.uid
        
        // Restore user profile
        FirebaseManager.shared.fetchUserProfile(uid: uid) { profileData in
            DispatchQueue.main.async {
                if let data = profileData {
                    let firstName = data["firstName"] as? String ?? ""
                    let lastName = data["lastName"] as? String ?? ""
                    if !firstName.isEmpty {
                        UserDefaults.standard.set(firstName, forKey: "user_first_name")
                    }
                    if !lastName.isEmpty {
                        UserDefaults.standard.set(lastName, forKey: "user_last_name")
                    }
                }
                
                // Restore conversation history
                FirebaseManager.shared.fetchConversationHistory(uid: uid) { conversations in
                    DispatchQueue.main.async {
                        for dict in conversations {
                            guard let id = dict["id"] as? String,
                                  let title = dict["title"] as? String else { continue }
                            
                            // Skip if already exists locally
                            if DataManager.shared.fetchConversation(byId: id) != nil { continue }
                            
                            // Fetch FULL DATA (Messages + Participants)
                            FirebaseManager.shared.fetchFullConversation(uid: uid, conversationID: id) { fullData in
                                DispatchQueue.main.async {
                                    let metadata = fullData?["metadata"] as? [String: Any] ?? dict
                                    let participantsDict = fullData?["participants"] as? [String: [String: Any]] ?? [:]
                                    let messagesDict = fullData?["messages"] as? [String: [String: Any]] ?? [:]
                                    
                                    // 1. Create Participants
                                    var historyParticipants: [Participant] = []
                                    for (_, pData) in participantsDict {
                                        let p = Participant(
                                            name: pData["name"] as? String ?? "Unknown",
                                            summary: pData["summary"] as? String ?? "",
                                            image: pData["image"] as? String ?? "person.circle.fill"
                                        )
                                        historyParticipants.append(p)
                                    }
                                    
                                    // 2. Create Messages
                                    var historyMessages: [Message] = []
                                    for (_, mData) in messagesDict {
                                        let m = Message(
                                            id: UUID(),
                                            text: mData["text"] as? String ?? "",
                                            senderId: mData["senderId"] as? String ?? "",
                                            senderName: mData["senderName"] as? String ?? "",
                                            isIncoming: mData["isIncoming"] as? Bool ?? false,
                                            timestamp: Date(timeIntervalSince1970: mData["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970),
                                            isHighlighted: mData["isHighlighted"] as? Bool ?? false,
                                            isEdited: mData["isEdited"] as? Bool ?? false
                                        )
                                        historyMessages.append(m)
                                    }
                                    
                                    // 3. Create Conversation
                                    let convo = Conversation(
                                        id: id,
                                        title: title,
                                        details: metadata["details"] as? String ?? "",
                                        date: metadata["date"] as? String ?? "",
                                        startTime: metadata["startTime"] as? String ?? "",
                                        endTime: metadata["endTime"] as? String ?? "",
                                        location: metadata["location"] as? String ?? "",
                                        category: metadata["category"] as? String ?? "",
                                        icon: metadata["icon"] as? String ?? "",
                                        info: metadata["info"] as? Bool,
                                        calendarDate: Date(timeIntervalSince1970: metadata["calendarDate"] as? TimeInterval ?? Date().timeIntervalSince1970),
                                        notes: metadata["notes"] as? String,
                                        isPinned: metadata["isPinned"] as? Bool ?? false,
                                        ownerUID: uid,
                                        participants: historyParticipants,
                                        messages: historyMessages
                                    )
                                    
                                    DataManager.shared.addConversation(convo)
                                }
                            }
                        }
                        
                        // Restore Quick Actions
                        FirebaseManager.shared.fetchQuickActions(uid: uid) { actions in
                            DispatchQueue.main.async {
                                for dict in actions {
                                    guard let id = dict["id"] as? String,
                                          let categoryTitle = dict["categoryTitle"] as? String,
                                          let conversationTopic = dict["conversationTopic"] as? String,
                                          let startTime = dict["startTime"] as? String,
                                          let status = dict["status"] as? String,
                                          let roomCode = dict["roomCode"] as? String,
                                          let iconName = dict["iconName"] as? String,
                                          let topicImage = dict["topicImage"] as? String,
                                          let timeImage = dict["timeImage"] as? String else { continue }
                                    
                                    let existing = QuickActionsRepository.shared.getAllActions()
                                    if existing.contains(where: { $0.id == id }) { continue }
                                    
                                    let action = RoutineConversation(
                                        id: id,
                                        iconName: iconName,
                                        categoryTitle: categoryTitle,
                                        status: status,
                                        conversationTopic: conversationTopic,
                                        topicImage: topicImage,
                                        startTime: startTime,
                                        description: dict["description"] as? String,
                                        date: dict["date"] as? String,
                                        timeImage: timeImage,
                                        roomCode: roomCode,
                                        participantNames: dict["participantNames"] as? [String] ?? []
                                    )
                                    QuickActionsRepository.shared.addAction(action)
                                }
                                
                                // Navigate to home screen
                                DispatchQueue.main.async {
                                    self.performSegue(withIdentifier: "googleSignInToHome", sender: self)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @IBAction func createAccountTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showCreateAccount", sender: self)
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showLoginAccount", sender: self)
    }
}

// MARK: - UIImage Extension
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
