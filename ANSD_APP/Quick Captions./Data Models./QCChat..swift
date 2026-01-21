//
//  QCChat.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import Foundation

struct QCChatMessage: Sendable {
    let text: String
    let isIncoming: Bool
    let sender: String
}

struct QCChatData {
    static let fullConversation: [QCChatMessage] = [
        QCChatMessage(text: "Bucky Barnes, right? How do you spell your surname?", isIncoming: false, sender: "Me"),
        QCChatMessage(text: "B-A-R-N-E-S, Sir. From Brooklyn.", isIncoming: true, sender: "Person 1"),
        QCChatMessage(text: "Nice to meet you, Bucky. Just give me a moment here. I'm looking for the right building.", isIncoming: false, sender: "Me"),
        QCChatMessage(text: "Yeah, I think it is that one over there. The one with the red paint peeling off.", isIncoming: false, sender: "Me"),
        QCChatMessage(text: "You want to dropped here then or near the bus stop? I'm not sure which one is closer.", isIncoming: true, sender: "Person 1"),
        QCChatMessage(text: "The gate would be fine, thanks.", isIncoming: false, sender: "Me"),
        QCChatMessage(text: "What is the code, Sir?", isIncoming: true, sender: "Person 1"),
        QCChatMessage(text: "The code is 10042005.", isIncoming: false, sender: "Me"),
        QCChatMessage(text: "The fare is 120 bucks, Sir. Cash please.", isIncoming: true, sender: "Person 1"),
        QCChatMessage(text: "120! Jesus, the fare has sky-rocketed a lot!", isIncoming: false, sender: "Me"),
        QCChatMessage(text: "I know, Sir. But after inflation, this is the best we can do.", isIncoming: true, sender: "Person 1"),
        QCChatMessage(text: "Public transport would have been cheaper.", isIncoming: false, sender: "Me")
    ]
}

// MARK: - AI Helper Extension
extension Array where Element == QCChatMessage {
    func toTranscriptString() -> String {
        return self.map { "\($0.sender): \($0.text)" }.joined(separator: "\n")
    }
}
