//
//  VoiceProfile.swift
//  ANSD_APP
//
//  Created by SDC-USER on 04/03/26.
//

import Foundation
import SwiftData

@Model
class VoiceProfile {
    @Attribute(.unique) var ownerUID: String
    var name: String
    var embedding: [Float]
    var createdAt: Date
    
    init(ownerUID: String, name: String, embedding: [Float], createdAt: Date = Date()) {
        self.ownerUID = ownerUID
        self.name = name
        self.embedding = embedding
        self.createdAt = createdAt
    }
}
