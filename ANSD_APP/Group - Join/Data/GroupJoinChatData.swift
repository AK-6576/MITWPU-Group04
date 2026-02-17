//
//  GroupJoinChatData.swift
//  ANSD_APP
//
//  Created by SDC-USER on 25/11/26.
//

import Foundation

struct GroupJoinChat {
    static let fullConversation: [GroupJoin] = [
        GroupJoin(
            text: "Did everyone finish the assignment? It is due tomorrow and ma'am is strict.",
            isIncoming: true,
            sender: "Peter Parker"
        ),
        GroupJoin(
            text: "Almost done! Just need to proofread.",
            isIncoming: false,
            sender: "Me"
        ),
        GroupJoin(
            text: "I haven't started... Help?",
            isIncoming: true,
            sender: "Bruce Banner"
        ),
        GroupJoin(
            text: "Sure, I'm free after 4 PM.",
            isIncoming: false,
            sender: "Me"
        ),
        GroupJoin(
            text: "I have a family outing at 4 PM. How about tomorrow ?",
            isIncoming: true,
            sender: "Peter Parker"
        ),
        GroupJoin(
            text: "Jesus ! So late ? Oh, hell naw. I am out.",
            isIncoming: false,
            sender: "Me"
        ),
        GroupJoin(
            text: "Steve. don't do that. I am already panicking.",
            isIncoming: true,
            sender: "Bruce Banner"
        ),
        GroupJoin(
            text: "And rightfully so. We had 3 weeks to do it.",
            isIncoming: false,
            sender: "Me"
        ),
        GroupJoin(
            text: "Don't do that. Don't push your luck, Steve.",
            isIncoming: true,
            sender: "Peter Parker"
        ),
        GroupJoin(
            text: "Yeah yeah, I know. Gotta go ! Good luck !",
            isIncoming: false,
            sender: "Me"
        )
    ]
}
