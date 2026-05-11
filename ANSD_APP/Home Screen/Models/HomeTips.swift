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
/// Shown anchored to the profile button (top-right navigation bar item).
struct ProfileButtonTip: Tip {
    var title: Text {
        Text("Your Profile")
    }
    var message: Text? {
        Text("Tap to update your name, photo, and voice settings.")
    }
    var image: Image? {
        Image(systemName: "person.crop.circle")
    }
}

// MARK: - Quick Actions Tip
/// Shown below the "Quick Actions" section header.
struct QuickActionsTip: Tip {
    var title: Text {
        Text("Quick Actions")
    }
    var message: Text? {
        Text("Schedule recurring conversations for Office, Family, or Friends. Tap + to add your first one.")
    }
    var image: Image? {
        Image(systemName: "bolt.fill")
    }
}

// MARK: - New Conversation Tip
/// Shown anchored to the "New Conversation" area on the home screen.
struct NewConversationTip: Tip {
    var title: Text {
        Text("Start Captioning")
    }
    var message: Text? {
        Text("Tap here to start a new live-captioned session and share a room code with others.")
    }
    var image: Image? {
        Image(systemName: "waveform.and.mic")
    }
}

// MARK: - Join Conversation Tip
/// Shown anchored to the "Join Conversation" area.
struct JoinConversationTip: Tip {
    var title: Text {
        Text("Join a Session")
    }
    var message: Text? {
        Text("Have a room code? Tap here to join an active captioning session.")
    }
    var image: Image? {
        Image(systemName: "person.2.wave.2")
    }
}

// MARK: - View Conversations Tip
/// Shown below the "View Conversations" section header.
struct ViewConversationsTip: Tip {
    var title: Text {
        Text("Conversation History")
    }
    var message: Text? {
        Text("Your recent sessions appear here. Tap any card to review the full transcript.")
    }
    var image: Image? {
        Image(systemName: "clock.fill")
    }
}
