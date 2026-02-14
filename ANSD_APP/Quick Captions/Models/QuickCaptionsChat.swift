//
//  QuickCaptionsChat.swift
//  ANSD_APP
//
//  Created by Anshul Kumaria on 25/11/25.
//

import Foundation

struct QuickCaptionsChat: Sendable {
    var sender: String
    var text: String
    var isIncoming: Bool
    var speakerID : Int?
}
