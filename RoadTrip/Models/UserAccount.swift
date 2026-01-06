// Models/UserAccount.swift
import Foundation
import SwiftData

// Collaboration features currently disabled
#if false

@Model
class UserAccount {
    var id: UUID
    var email: String
    var displayName: String
    var createdAt: Date
    var lastLoginAt: Date?
    var profileImageURL: String?
    var cloudUserId: String? // ID from cloud auth provider
    
    var isLoggedIn: Bool
    
    init(email: String, displayName: String) {
        self.id = UUID()
        self.email = email
        self.displayName = displayName
        self.createdAt = Date()
        self.isLoggedIn = false
    }
}

// Represents a collaborator on a shared trip
struct TripCollaborator: Codable, Identifiable, Hashable {
    var id: String // User ID
    var email: String
    var displayName: String
    var role: CollaboratorRole
    var joinedAt: Date
    
    enum CollaboratorRole: String, Codable {
        case owner = "Owner"
        case editor = "Editor"
        case viewer = "Viewer"
    }
}

// Share invite that can be sent via email/text
struct TripShareInvite: Codable, Identifiable {
    var id: UUID
    var tripId: UUID
    var tripName: String
    var inviterName: String
    var inviterEmail: String
    var shareCode: String
    var role: TripCollaborator.CollaboratorRole
    var expiresAt: Date
    var createdAt: Date
    
    init(tripId: UUID, tripName: String, inviterName: String, inviterEmail: String, role: TripCollaborator.CollaboratorRole = .editor) {
        self.id = UUID()
        self.tripId = tripId
        self.tripName = tripName
        self.inviterName = inviterName
        self.inviterEmail = inviterEmail
        self.shareCode = Self.generateShareCode()
        self.role = role
        self.createdAt = Date()
        self.expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    }
    
    static func generateShareCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Avoid confusing characters
        return String((0..<6).map { _ in characters.randomElement()! })
    }
    
    var shareURL: URL? {
        URL(string: "roadtrip://join/\(shareCode)")
    }
    
    var shareMessage: String {
        """
        \(inviterName) invited you to collaborate on "\(tripName)" in RoadTrip!
        
        Join with code: \(shareCode)
        
        Or tap this link: \(shareURL?.absoluteString ?? "")
        
        Download RoadTrip: https://apps.apple.com/app/roadtrip
        """
    }
}
