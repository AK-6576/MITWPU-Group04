import UIKit
import AVFoundation
import Speech
import Supabase
import Realtime

class GroupNewViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Outlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    
    // MARK: - Properties
    let speechManager = SpeechManager()
    let supabase = SupabaseManager.shared.client
    var channel: RealtimeChannelV2?
    
    var isRecording = false
    var isPaused = false
    var messages: [GroupNewChatMessage] = []
    
    var currentSessionID: String = ""
    var myName = UIDevice.current.name
    var isHost = true
    var selectedLanguageCode = "en-US"
    var otherPersonName = "Person 1"

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        
        if currentSessionID.isEmpty {
            self.currentSessionID = "\(Int.random(in: 1000...9999))"
        }
        self.title = isHost ? "Host: \(currentSessionID)" : "Joined: \(currentSessionID)"
        
        handleAuthentication()
    }

    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = .zero
            layout.minimumLineSpacing = 10
        }
    }

    // MARK: - Supabase Logic
    
    func handleAuthentication() {
        Task {
            do {
                if try await supabase.auth.session == nil {
                    try await SupabaseManager.shared.signInAnonymously()
                }
                // Call these sequentially
                await setupRealtimeSubscription()
                await fetchMessageHistory()
            } catch {
                print("Supabase Auth Error: \(error)")
            }
        }
    }

    func setupRealtimeSubscription() async {
        // Cleanup existing channel
        if let existingChannel = self.channel {
            await existingChannel.unsubscribe()
        }

        let newChannel = supabase.realtimeV2.channel("room_\(currentSessionID)")
        self.channel = newChannel
        
        // Postgres filter for Realtime
        let filter = "session_id=eq.\(currentSessionID)"
        
        newChannel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "chat_messages",
            filter: filter
        ) { [weak self] change in
            guard let self = self else { return }
            do {
                // FIX: Added 'decoder: JSONDecoder()'
                let newMessage = try change.decodeRecord(as: GroupNewChatMessage.self, decoder: JSONDecoder())
                Task { await self.processIncomingMessage(newMessage) }
            } catch {
                print("❌ Realtime decoding error: \(error)")
            }
        }
        
        do {
            // Ensure you await the subscription
            try await newChannel.subscribe()
            print("✅ Subscribed to Session: \(currentSessionID)")
        } catch {
            print("❌ Subscription failed: \(error)")
        }
    }
    private func fetchMessageHistory() async {
        do {
            // FIX: execute() must have parentheses.
            // The '.value' property automatically decodes to your [GroupNewChatMessage] type.
            let response: [GroupNewChatMessage] = try await supabase
                .from("chat_messages")
                .select()
                .eq("session_id", value: currentSessionID)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            let myID = try? await supabase.auth.session.user.id.uuidString

            await MainActor.run {
                self.messages = response.map { msg in
                    var m = msg
                    // Determine if it's incoming based on senderID
                    m.isIncoming = (m.senderID != myID)
                    return m
                }
                self.collectionView.reloadData()
                self.scrollToBottom()
            }
        } catch {
            print("❌ History fetch error: \(error)")
        }
    }
    private func processIncomingMessage(_ newMessage: GroupNewChatMessage) async {
        let session = try? await self.supabase.auth.session
        let myID = session?.user.id.uuidString

        if newMessage.senderID != myID {
            await MainActor.run {
                var incomingMsg = newMessage
                incomingMsg.isIncoming = true
                self.messages.append(incomingMsg)
                self.collectionView.insertItems(at: [IndexPath(item: self.messages.count - 1, section: 0)])
                self.scrollToBottom()
            }
        }
    }

    // MARK: - Transcription Logic
    
    func startLiveTranscription() {
        Task {
            let session = try? await supabase.auth.session
            let myID = session?.user.id.uuidString ?? "unknown"
            
            let newMessage = GroupNewChatMessage(
                text: "Listening...",
                sender: self.myName,
                senderID: myID,
                sessionID: currentSessionID,
                isIncoming: false
            )
            
            await MainActor.run {
                self.messages.append(newMessage)
                let lastIndex = self.messages.count - 1
                self.collectionView.insertItems(at: [IndexPath(item: lastIndex, section: 0)])
                self.scrollToBottom()
                
                self.speechManager.startTranscribing(languageCode: self.selectedLanguageCode) { [weak self] partialText in
                    guard let self = self else { return }
                    self.messages[lastIndex].text = partialText
                    self.collectionView.reloadItems(at: [IndexPath(item: lastIndex, section: 0)])
                }
            }
        }
    }

    func stopLiveTranscription() {
        let finalTranscribedText = speechManager.stopTranscribing()
        guard !messages.isEmpty else { return }
        let lastIndex = messages.count - 1
        
        let cleanedText = finalTranscribedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedText.isEmpty || cleanedText == "Listening..." {
            messages.remove(at: lastIndex)
            collectionView.reloadData()
            return
        }
        
        messages[lastIndex].text = cleanedText
        let messageToPublish = messages[lastIndex]
        
        Task {
            do {
                try await supabase.from("chat_messages").insert(messageToPublish).execute()
            } catch {
                print("❌ Publish error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - IBActions
    
    @IBAction func didTapMicButton(_ sender: UIButton) {
        if !isRecording {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .defaultToSpeaker)
                try audioSession.setActive(true)
                startLiveTranscription()
                micButton.tintColor = .systemRed
                micButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
            } catch { print(error) }
        } else {
            stopLiveTranscription()
            micButton.tintColor = .systemBlue
            micButton.setImage(UIImage(systemName: "mic"), for: .normal)
        }
        isRecording = !isRecording
    }

    @IBAction func didTapStopButton(_ sender: UIButton) {
        let alert = UIAlertController(title: "End Session?", message: "Generate summary?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "End", style: .destructive) { _ in
            if self.isRecording { self.stopLiveTranscription() }
            self.navigateToSummary()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @IBAction func addPersonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Add Participant", message: "Invite others to \(currentSessionID)", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Share Invitation Link", style: .default) { _ in
            self.shareRoomInvitation()
        })
        alert.addAction(UIAlertAction(title: "Add from Contacts", style: .default) { _ in
            self.presentParticipantSelection()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - UI Helpers
    
    func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
    }

    func navigateToSummary() {
        let storyboard = UIStoryboard(name: "Group-New", bundle: nil)
        if let summaryNav = storyboard.instantiateViewController(withIdentifier: "SummaryNavController") as? UINavigationController,
           let summaryVC = summaryNav.topViewController as? GroupNewSummaryViewController {
            summaryVC.transcriptMessages = self.messages
            summaryNav.modalPresentationStyle = .pageSheet
            self.present(summaryNav, animated: true)
        }
    }

    func shareRoomInvitation() {
        let invitationMessage = "Join my session: ansdapp://join/\(currentSessionID)"
        let activityVC = UIActivityViewController(activityItems: [invitationMessage], applicationActivities: nil)
        present(activityVC, animated: true)
    }

    func presentParticipantSelection() {
        let storyboard = UIStoryboard(name: "Group-New", bundle: nil)
        if let selectionVC = storyboard.instantiateViewController(withIdentifier: "ParticipantSelectionViewController") as? ParticipantSelectionViewController {
            let nav = UINavigationController(rootViewController: selectionVC)
            present(nav, animated: true)
        }
    }

    func showRenameAlert() {
        let alert = UIAlertController(title: "Rename Speaker", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.text = self.otherPersonName }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                self.otherPersonName = newName
                for i in 0..<self.messages.count where self.messages[i].isIncoming {
                    self.messages[i].sender = newName
                }
                self.collectionView.reloadData()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - CollectionView DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages[indexPath.row]
        if message.isIncoming {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "IncomingCell", for: indexPath) as! GroupNewIncomingCell
            cell.messageLabel.text = message.text
            cell.nameLabel.text = message.sender
            cell.onLabelTapped = { [weak self] in self?.showRenameAlert() }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OutgoingCell", for: indexPath) as! GroupNewOutgoingCell
            cell.messageLabel.text = message.text
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = messages[indexPath.row].text
        let width = collectionView.frame.width
        let estimatedHeight = NSString(string: text).boundingRect(with: CGSize(width: width - 100, height: 1000), options: .usesLineFragmentOrigin, attributes: [.font: UIFont.systemFont(ofSize: 17)], context: nil).height
        return CGSize(width: width, height: estimatedHeight + 60)
    }
}
