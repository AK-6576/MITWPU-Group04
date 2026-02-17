//
//  FriendChat.swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 12/12/25.
//

import Foundation

struct FriendsChat {
    let text: String
    let isIncoming: Bool
    let sender: String
}

struct FriendsChatData {
    static let fullConversation: [FriendsChat] = [
        FriendsChat(
            text: "Yo, are we still on for the movies tonight?",
            isIncoming: true,
            sender: "Alex Jordan"
        ),
        FriendsChat(
            text: "Definitely. I've been waiting to see this one for months.",
            isIncoming: false,
            sender: "Me"
        ),
        FriendsChat(
            text: "I'm in! But can we grab food first? I'm starving.",
            isIncoming: true,
            sender: "Sarah Miller"
        ),
        FriendsChat(
            text: "Same here. That burger place near the theater is good.",
            isIncoming: true,
            sender: "Mike Ross"
        ),
        FriendsChat(
            text: "Good call. Let's meet there at 6?",
            isIncoming: false,
            sender: "Me"
        ),
        FriendsChat(
            text: "6 works for me. I'm driving if anyone needs a lift.",
            isIncoming: true,
            sender: "Alex Jordan"
        ),
        FriendsChat(
            text: "Could you swing by and pick me up? My car is in the shop.",
            isIncoming: true,
            sender: "Mike Ross"
        ),
        FriendsChat(
            text: "No problem. Be ready by 5:45.",
            isIncoming: true,
            sender: "Alex Jordan"
        ),
        FriendsChat(
            text: "Sarah, are you meeting us there or riding with Alex?",
            isIncoming: false,
            sender: "Me"
        ),
        FriendsChat(
            text: "I'll meet you guys there! Don't start eating without me.",
            isIncoming: true,
            sender: "Sarah Miller"
        )
    ]
}
