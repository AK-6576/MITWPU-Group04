//
//  Chat.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 25/11/25.
//

import Foundation

struct ChatMessage {
    let text: String
    let isIncoming: Bool
    let sender: String
}

struct ChatData {
    static let fullConversation: [ChatMessage] = [
        
        ChatMessage(
            text: "Did everyone finish the last task? It is due tomorrow and the client is annoying.",
            isIncoming: true,
            sender: "Julius Robert Oppenheimer"
        ),

        ChatMessage(
            text: "Almost done! Just need to proofread.",
        
            isIncoming: false,
            sender: "Me"
        ),
        
        ChatMessage(
            text: "I haven’t started... Help?",
            isIncoming: true,
            sender: "Richard Feynman"
        ),
        
        ChatMessage(
            text: "Sure, I’m free after 4 PM.",
            isIncoming: false,
            sender: "Me"
        ),
        
        ChatMessage(
            text: "I have a family outing at 4 PM. How about tomorrow ?",
            isIncoming: true,
            sender: "Julius Robert Oppenheimerr"
        ),
        
        ChatMessage(
            text: "Jesus ! So late ? Oh, hell naw. I am out.",
            isIncoming: false,
            sender: "Me"
        ),
        
        ChatMessage(
            text: "Please don’t do that. I am already panicking.",
            isIncoming: true,
            sender: "Richard Feynman"
        ),
        
        ChatMessage(
            text: "And rightfully so. We had 3 days to do it.",
            isIncoming: false,
            sender: "Me"
        ),
        
        ChatMessage(
            text: "Don’t do that. Don’t push your luck.",
            isIncoming: true,
            sender: "Julius Robert Oppenheimer"
        ),
        
        ChatMessage(
            text: "Yeah yeah, I know. Gotta go ! Good luck !",
            isIncoming: false,
            sender: "Me"
        )
    ]
}
