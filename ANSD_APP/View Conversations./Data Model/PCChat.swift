//
//  PCChat.swift
//  ANSD_APP
//
//  Created by SDC-USER on 16/12/25.
//

import Foundation
struct PCChatMessage {
    let text: String
    let isIncoming: Bool
    let sender: String
}

struct PCChatData {
    static let fullConversation: [PCChatMessage] = [
        
        PCChatMessage(text: "Bucky Barnes, right ? How do you spell your surname ?", isIncoming: false, sender: "Me"),
        
        PCChatMessage(text: "B-A-R-N-E-S, Sir. From Brooklyn.", isIncoming: true, sender: "Person 1"),
        
        PCChatMessage(text: "Nice to meet you, Bucky. Just give me a moment here. I'm looking for the right building.", isIncoming: false, sender: "Me"),
        
        PCChatMessage(text: "Yeah, I think it is that one over there. The one with the red paint peeling off.", isIncoming: false, sender: "Me"),
        
        PCChatMessage(text: "You want to dropped here then or near the bus stop? I'm not sure which one is closer.", isIncoming: true, sender: "Person 1"),
        PCChatMessage(text: "The gate would be fine, thanks.", isIncoming: false, sender: "Me"),
        
        PCChatMessage(text: "What is the code, Sir?", isIncoming: true, sender: "Person 1"),
        PCChatMessage(text: "The code is 10042005.", isIncoming: false, sender: "Me"),
        
        PCChatMessage(text: "The fare is 120 bucks, Sir. Cash please.", isIncoming: true, sender: "Person 1"),
        PCChatMessage(text: "120! Jesus, the fare has sky-rocketed a lot!", isIncoming: false, sender: "Me"),
        PCChatMessage(text: "I know, Sir. But after inflation, this is the best we can do.", isIncoming: true, sender: "Person 1"),
        PCChatMessage(text: "Public transport would have been cheaper.", isIncoming: false, sender: "Me")
    ]
}
