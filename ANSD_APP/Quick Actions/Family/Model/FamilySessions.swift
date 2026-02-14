//
//  Sessions..swift
//  ANSD_APP
//
//  Created by Dhiraj Bodake on 25/11/25.
//

import Foundation

struct SessionModel {
    var title: String
    let subtitle: String
    let category: ChatCategory // Links the session to Family, Friends, or Work
    let date: Date
}
