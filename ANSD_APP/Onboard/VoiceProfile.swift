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
    @Attribute(.unique) var id: Int
    var name: String
    var embedding: [Float]
    var createdAt: Date
    
    init(id: Int = 0, name: String, embedding: [Float], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.embedding = embedding
        self.createdAt = createdAt
    }
}
