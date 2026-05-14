//
//  HomeTips.swift
//  ANSD_APP
//
//  Created by MIT-WPU Group 4.
//  Copyright © 2025 MIT-WPU Group 4. All rights reserved.
//
//  TipKit tips for the Home Screen — shown only on the user's first launch after account creation.
//

import TipKit

// MARK: - Profile Button Tip
struct ProfileButtonTip: Tip {
    var title: Text { Text("Your Profile") }
    var message: Text? { Text("Update your voice profile, name, and preferences here.") }
    var image: Image? { Image(systemName: "person.crop.circle.fill") }
}

// MARK: - Quick Captioning Tip
struct QuickCaptioningTip: Tip {
    var title: Text { Text("Quick Captioning") }
    var message: Text? { Text("Start instant, real-time transcription with a single tap.") }
    var image: Image? { Image(systemName: "waveform.and.mic") }
}

// MARK: - Quick Actions Tip
struct QuickActionsTip: Tip {
    var title: Text { Text("Quick Actions") }
    var message: Text? { Text("Quickly access your recurring sessions for Office, Family, or Friends.") }
    var image: Image? { Image(systemName: "bolt.fill") }
}

// MARK: - New Conversation Tip
struct NewConversationTip: Tip {
    var title: Text { Text("New Conversation") }
    var message: Text? { Text("Set up a new session and get a room code to invite participants.") }
    var image: Image? { Image(systemName: "square.and.pencil") }
}

// MARK: - Join Conversation Tip
struct JoinConversationTip: Tip {
    var title: Text { Text("Join Session") }
    var message: Text? { Text("Enter a room code here to join someone else's transcription.") }
    var image: Image? { Image(systemName: "person.bubble") }
}

// MARK: - View Conversations Tip
struct ViewConversationsTip: Tip {
    var title: Text { Text("Recent History") }
    var message: Text? { Text("Review transcripts and summaries from your previous sessions.") }
    var image: Image? { Image(systemName: "clock.fill") }
}
