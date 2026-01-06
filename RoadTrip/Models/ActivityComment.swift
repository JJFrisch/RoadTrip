//
//  ActivityComment.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import Foundation
import SwiftData

// Collaboration features currently disabled
#if false

@Model
class ActivityComment {
    var id: UUID
    var userId: String
    var userEmail: String
    var text: String
    var createdAt: Date
    var updatedAt: Date?
    
    init(userId: String, userEmail: String, text: String) {
        self.id = UUID()
        self.userId = userId
        self.userEmail = userEmail
        self.text = text
        self.createdAt = Date()
    }
}

#endif
