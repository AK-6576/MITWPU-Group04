//
//  FamilyChat.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 12/12/25.
//

import Foundation

struct FamilyChat {
    let text: String
    let isIncoming: Bool
    let sender: String
}

struct FamilyChatParticipants {
    static let fullConversation: [FamilyChat] = [
        FamilyChat(
            text: "Good morning everyone! Pancakes are ready on the table.",
            isIncoming: true,
            sender: "Marie Parker"
        ),
        FamilyChat(
            text: "Smells amazing! I'll be down in two minutes.",
            isIncoming: false,
            sender: "Me"
        ),
        FamilyChat(
            text: "I'm already eating. These are delicious, Marie.",
            isIncoming: true,
            sender: "Henry Parker"
        ),
        FamilyChat(
            text: "Thanks Henry. David, don't forget we have that appointment at 10.",
            isIncoming: true,
            sender: "Marie Parker"
        ),
        FamilyChat(
            text: "Right, the dentist. I remember.",
            isIncoming: false,
            sender: "Me"
        ),
        FamilyChat(
            text: "Do you need a ride? I'm heading past there anyway.",
            isIncoming: true,
            sender: "Henry Parker"
        ),
        FamilyChat(
            text: "That would be great, thanks Dad. Saves me an Uber.",
            isIncoming: false,
            sender: "Me"
        ),
        FamilyChat(
            text: "Anna is still sleeping? She's going to miss the bus.",
            isIncoming: true,
            sender: "Marie Parker"
        ),
        FamilyChat(
            text: "I think she was up late studying. Let her sleep a bit more.",
            isIncoming: true,
            sender: "Henry Parker"
        ),
        FamilyChat(
            text: "Alright, but save some pancakes for her before you finish them all!",
            isIncoming: false,
            sender: "Me"
        )
    ]
}
