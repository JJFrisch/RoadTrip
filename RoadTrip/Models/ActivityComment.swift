//
//  ActivityComment.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import Foundation
import SwiftData

@Model
class ActivityComment {
    var id: UUID = UUID()
    var userId: String = ""
    var userEmail: String = ""
    var text: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date?

    @Relationship(deleteRule: .nullify, inverse: \Activity.commentsStorage)
    var activity: Activity?
    
    init(userId: String, userEmail: String, text: String) {
        self.userId = userId
        self.userEmail = userEmail
        self.text = text
    }
}
