//
//  Chat.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import Foundation

struct GJChatMessage {
    let text: String
    let isIncoming: Bool
    let sender: String
}

struct GJChatData {
    static let fullConversation: [GJChatMessage] = [
        
        GJChatMessage(
            text: "Did everyone finish the assignment? It is due tomorrow and ma’am is strict.",
            isIncoming: true,
            sender: "Peter Parker"
        ),

        GJChatMessage(
            text: "Almost done! Just need to proofread.",
            isIncoming: false,
            sender: "Me"
        ),
        
        GJChatMessage(
            text: "I haven’t started... Help?",
            isIncoming: true,
            sender: "Bruce Banner"
        ),
        
        GJChatMessage(
            text: "Sure, I’m free after 4 PM.",
            isIncoming: false,
            sender: "Me"
        ),
        
        GJChatMessage(
            text: "I have a family outing at 4 PM. How about tomorrow ?",
            isIncoming: true,
            sender: "Peter Parker"
        ),
        
        GJChatMessage(
            text: "Jesus ! So late ? Oh, hell naw. I am out.",
            isIncoming: false,
            sender: "Me"
        ),
        
        GJChatMessage(
            text: "Steve. don’t do that. I am already panicking.",
            isIncoming: true,
            sender: "Bruce Banner"
        ),
        
        GJChatMessage(
            text: "And rightfully so. We had 3 weeks to do it.",
            isIncoming: false,
            sender: "Me"
        ),
        
        GJChatMessage(
            text: "Don’t do that. Don’t push your luck, Steve.",
            isIncoming: true,
            sender: "Peter Parker"
        ),
        
        GJChatMessage(
            text: "Yeah yeah, I know. Gotta go ! Good luck !",
            isIncoming: false,
            sender: "Me"
        )
    ]
}
