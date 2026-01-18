//
//  Chat(Breakfast).swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 12/12/25.
//

import Foundation

struct ChatMessage2 {
    let text: String
    let isIncoming: Bool
    let sender: String
}

struct ChatData2 {
    static let fullConversation: [ChatMessage2] = [
        ChatMessage2(
            text: "Yo, are we still on for the movies tonight?",
            isIncoming: true,
            sender: "Alex Jordan"
        ),
        ChatMessage2(
            text: "Definitely. I've been waiting to see this one for months.",
            isIncoming: false,
            sender: "Me"
        ),
        ChatMessage2(
            text: "I'm in! But can we grab food first? I'm starving.",
            isIncoming: true,
            sender: "Sarah Miller"
        ),
        ChatMessage2(
            text: "Same here. That burger place near the theater is good.",
            isIncoming: true,
            sender: "Mike Ross"
        ),
        ChatMessage2(
            text: "Good call. Let's meet there at 6?",
            isIncoming: false,
            sender: "Me"
        ),
        ChatMessage2(
            text: "6 works for me. I'm driving if anyone needs a lift.",
            isIncoming: true,
            sender: "Alex Jordan"
        ),
        ChatMessage2(
            text: "Could you swing by and pick me up? My car is in the shop.",
            isIncoming: true,
            sender: "Mike Ross"
        ),
        ChatMessage2(
            text: "No problem. Be ready by 5:45.",
            isIncoming: true,
            sender: "Alex Jordan"
        ),
        ChatMessage2(
            text: "Sarah, are you meeting us there or riding with Alex?",
            isIncoming: false,
            sender: "Me"
        ),
        ChatMessage2(
            text: "I'll meet you guys there! Don't start eating without me.",
            isIncoming: true,
            sender: "Sarah Miller"
        )
    ]
}
