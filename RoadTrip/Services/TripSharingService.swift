// Services/TripSharingService.swift
import Foundation
import SwiftData
import UIKit

/// Manages trip sharing, collaboration, and invite handling
@MainActor
class TripSharingService: ObservableObject {
    static let shared = TripSharingService()
    
    @Published var pendingInvites: [TripShareInvite] = []
    @Published var isProcessingInvite: Bool = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Create Share Invite
    
    /// Generate a share invite for a trip
    func createShareInvite(for trip: Trip, role: TripCollaborator.CollaboratorRole = .editor) -> TripShareInvite? {
        guard let authService = AuthService.shared.currentUser else {
            // Allow sharing even without account, use placeholder
            let invite = TripShareInvite(
                tripId: trip.id,
                tripName: trip.name,
                inviterName: "A friend",
                inviterEmail: "",
                role: role
            )
            
            // Store share code on trip
            trip.shareCode = invite.shareCode
            trip.isShared = true
            
            return invite
        }
        
        let invite = TripShareInvite(
            tripId: trip.id,
            tripName: trip.name,
            inviterName: authService.displayName,
            inviterEmail: authService.email,
            role: role
        )
        
        // Store share code on trip
        trip.shareCode = invite.shareCode
        trip.isShared = true
        trip.ownerId = authService.cloudUserId
        trip.ownerEmail = authService.email
        
        return invite
    }
    
    // MARK: - Share via System Share Sheet
    
    /// Share trip via email, text, or other apps
    func shareTrip(_ trip: Trip, from viewController: UIViewController? = nil) {
        guard let invite = createShareInvite(for: trip) else { return }
        
        let shareText = invite.shareMessage
        let activityItems: [Any] = [shareText]
        
        let activityVC = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // Exclude some activity types that don't make sense
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks
        ]
        
        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            let presenter = viewController ?? rootVC
            
            // For iPad, configure popover
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = presenter.view
                popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            presenter.present(activityVC, animated: true)
        }
    }
    
    // MARK: - Join via Share Code
    
    /// Join a shared trip using a share code
    func joinTrip(withCode code: String, modelContext: ModelContext? = nil) async throws -> TripShareInvite {
        isProcessingInvite = true
        errorMessage = nil
        
        defer { isProcessingInvite = false }
        
        // Validate code format
        let cleanCode = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard (6...8).contains(cleanCode.count) else {
            throw SharingError.invalidCode
        }

        // Fast path: already processed this invite in this session
        if let existing = pendingInvites.first(where: { $0.shareCode == cleanCode }) {
            return existing
        }
        
        do {
            guard let record = try await CloudSyncService.shared.joinTrip(withCode: cleanCode) else {
                throw SharingError.inviteNotFound
            }

            guard let trip = CloudSyncService.shared.materializeTrip(from: record, into: modelContext) else {
                throw SharingError.inviteNotFound
            }

            let inviterName = trip.ownerEmail?.components(separatedBy: "@").first ?? "Trip Owner"
            var invite = TripShareInvite(
                tripId: trip.id,
                tripName: trip.name,
                inviterName: inviterName,
                inviterEmail: trip.ownerEmail ?? "",
                role: .editor
            )
            invite.shareCode = cleanCode
            pendingInvites.append(invite)
            return invite
        } catch let error as CloudSyncError {
            switch error {
            case .accountNotAvailable:
                throw SharingError.accountUnavailable
            case .recordNotFound:
                throw SharingError.inviteNotFound
            case .syncFailed(let message):
                self.errorMessage = message
                throw SharingError.networkError
            }
        } catch {
            throw SharingError.networkError
        }
    }
    
    // MARK: - Manage Collaborators
    
    /// Get list of collaborators for a trip
    func getCollaborators(for trip: Trip) -> [TripCollaborator] {
        var collaborators: [TripCollaborator] = []
        
        // Add owner
        if let ownerId = trip.ownerId {
            collaborators.append(TripCollaborator(
                id: ownerId,
                email: trip.ownerEmail ?? "Unknown",
                displayName: trip.ownerEmail?.components(separatedBy: "@").first ?? "Owner",
                role: .owner,
                joinedAt: trip.createdAt
            ))
        }
        
        // In real app, fetch collaborator details from cloud
        for userId in trip.sharedWith {
            collaborators.append(TripCollaborator(
                id: userId,
                email: "collaborator@example.com",
                displayName: "Collaborator",
                role: .editor,
                joinedAt: Date()
            ))
        }
        
        return collaborators
    }
    
    /// Remove a collaborator from a trip
    func removeCollaborator(_ collaborator: TripCollaborator, from trip: Trip) {
        trip.sharedWith.removeAll { $0 == collaborator.id }
        
        if trip.sharedWith.isEmpty {
            trip.isShared = false
        }
    }
    
    /// Copy share link to clipboard
    func copyShareLink(for trip: Trip) -> Bool {
        guard let invite = createShareInvite(for: trip) else { return false }

        UIPasteboard.general.string = invite.shareURL?.absoluteString ?? invite.shareCode
        return true
    }
    
    // MARK: - Error Types
    
    enum SharingError: LocalizedError {
        case invalidCode
        case inviteNotFound
        case inviteExpired
        case alreadyMember
        case networkError
        case accountUnavailable
        
        var errorDescription: String? {
            switch self {
            case .invalidCode:
                return "Invalid share code. Please check and try again."
            case .inviteNotFound:
                return "This invite was not found. It may have been revoked."
            case .inviteExpired:
                return "This invite has expired. Ask for a new one."
            case .alreadyMember:
                return "You're already a member of this trip."
            case .networkError:
                return "Network error. Please check your connection."
            case .accountUnavailable:
                return "iCloud is not available. Please sign in to iCloud and try again."
            }
        }
    }
}
