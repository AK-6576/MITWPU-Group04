//
//  QCChat.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import Foundation

struct QuickCaptionsChatMessage: Sendable {
    let text: String
    let isIncoming: Bool
    let sender: String
}

struct QuickCaptionsChatData {
    static let fullConversation: [QuickCaptionsChatMessage] = [
        QuickCaptionsChatMessage(text: "Bucky Barnes, right? How do you spell your surname?", isIncoming: false, sender: "Me"),
        QuickCaptionsChatMessage(text: "B-A-R-N-E-S, Sir. From Brooklyn.", isIncoming: true, sender: "Person 1"),
        QuickCaptionsChatMessage(text: "Nice to meet you, Bucky. Just give me a moment here. I'm looking for the right building.", isIncoming: false, sender: "Me"),
        QuickCaptionsChatMessage(text: "Yeah, I think it is that one over there. The one with the red paint peeling off.", isIncoming: false, sender: "Me"),
        QuickCaptionsChatMessage(text: "You want to dropped here then or near the bus stop? I'm not sure which one is closer.", isIncoming: true, sender: "Person 1"),
        QuickCaptionsChatMessage(text: "The gate would be fine, thanks.", isIncoming: false, sender: "Me"),
        QuickCaptionsChatMessage(text: "What is the code, Sir?", isIncoming: true, sender: "Person 1"),
        QuickCaptionsChatMessage(text: "The code is 10042005.", isIncoming: false, sender: "Me"),
        QuickCaptionsChatMessage(text: "The fare is 120 bucks, Sir. Cash please.", isIncoming: true, sender: "Person 1"),
        QuickCaptionsChatMessage(text: "120! Jesus, the fare has sky-rocketed a lot!", isIncoming: false, sender: "Me"),
        QuickCaptionsChatMessage(text: "I know, Sir. But after inflation, this is the best we can do.", isIncoming: true, sender: "Person 1"),
        QuickCaptionsChatMessage(text: "Public transport would have been cheaper.", isIncoming: false, sender: "Me")
    ]
}

// MARK: - AI Helper Extension
extension Array where Element == QuickCaptionsChatMessage {
    func toTranscriptString() -> String {
        return self.map { "\($0.sender): \($0.text)" }.joined(separator: "\n")
    }
}
