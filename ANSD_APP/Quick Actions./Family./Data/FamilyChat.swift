//
//  Chat(Breakfast).swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 12/12/25.
//

import Foundation

struct ChatMessage1 {
    let text: String
    let isIncoming: Bool
    let sender: String
}

struct ChatData1 {
    static let fullConversation: [ChatMessage1] = [
        ChatMessage1(
            text: "Good morning everyone! Pancakes are ready on the table.",
            isIncoming: true,
            sender: "Marie Parker"
        ),
        ChatMessage1(
            text: "Smells amazing! I'll be down in two minutes.",
            isIncoming: false,
            sender: "Me"
        ),
        ChatMessage1(
            text: "I'm already eating. These are delicious, Marie.",
            isIncoming: true,
            sender: "Henry Parker"
        ),
        ChatMessage1(
            text: "Thanks Henry. David, don't forget we have that appointment at 10.",
            isIncoming: true,
            sender: "Marie Parker"
        ),
        ChatMessage1(
            text: "Right, the dentist. I remember.",
            isIncoming: false,
            sender: "Me"
        ),
        ChatMessage1(
            text: "Do you need a ride? I'm heading past there anyway.",
            isIncoming: true,
            sender: "Henry Parker"
        ),
        ChatMessage1(
            text: "That would be great, thanks Dad. Saves me an Uber.",
            isIncoming: false,
            sender: "Me"
        ),
        ChatMessage1(
            text: "Anna is still sleeping? She's going to miss the bus.",
            isIncoming: true,
            sender: "Marie Parker"
        ),
        ChatMessage1(
            text: "I think she was up late studying. Let her sleep a bit more.",
            isIncoming: true,
            sender: "Henry Parker"
        ),
        ChatMessage1(
            text: "Alright, but save some pancakes for her before you finish them all!",
            isIncoming: false,
            sender: "Me"
        )
    ]
}
