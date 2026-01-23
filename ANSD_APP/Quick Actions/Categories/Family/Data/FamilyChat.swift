//
//  Chat(Breakfast).swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 12/12/25.
//

import Foundation

struct FamilyMessage {
    let text: String
    let isIncoming: Bool
    let sender: String
}

struct ChatData1 {
    static let fullConversation: [FamilyMessage] = [
        FamilyMessage(
            text: "Good morning everyone! Pancakes are ready on the table.",
            isIncoming: true,
            sender: "Marie Parker"
        ),
        FamilyMessage(
            text: "Smells amazing! I'll be down in two minutes.",
            isIncoming: false,
            sender: "Me"
        ),
        FamilyMessage(
            text: "I'm already eating. These are delicious, Marie.",
            isIncoming: true,
            sender: "Henry Parker"
        ),
        FamilyMessage(
            text: "Thanks Henry. David, don't forget we have that appointment at 10.",
            isIncoming: true,
            sender: "Marie Parker"
        ),
        FamilyMessage(
            text: "Right, the dentist. I remember.",
            isIncoming: false,
            sender: "Me"
        ),
        FamilyMessage(
            text: "Do you need a ride? I'm heading past there anyway.",
            isIncoming: true,
            sender: "Henry Parker"
        ),
        FamilyMessage(
            text: "That would be great, thanks Dad. Saves me an Uber.",
            isIncoming: false,
            sender: "Me"
        ),
        FamilyMessage(
            text: "Anna is still sleeping? She's going to miss the bus.",
            isIncoming: true,
            sender: "Marie Parker"
        ),
        FamilyMessage(
            text: "I think she was up late studying. Let her sleep a bit more.",
            isIncoming: true,
            sender: "Henry Parker"
        ),
        FamilyMessage(
            text: "Alright, but save some pancakes for her before you finish them all!",
            isIncoming: false,
            sender: "Me"
        )
    ]
}
