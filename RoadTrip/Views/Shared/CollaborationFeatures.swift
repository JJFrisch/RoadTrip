//
//  CollaborationFeatures.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import Foundation
import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - QR Code Generator
class QRCodeGenerator {
    static let shared = QRCodeGenerator()
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    func generateQRCode(from shareCode: String) -> UIImage? {
        filter.message = Data(shareCode.utf8)
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - QR Code Share View
struct QRCodeShareView: View {
    let trip: Trip
    @State private var qrImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Share via QR Code")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let qrImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                } else {
                    ProgressView()
                        .frame(width: 250, height: 250)
                }
                
                VStack(spacing: 12) {
                    Text(trip.shareCode ?? "No share code")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .textSelection(.enabled)
                    
                    Text("Others can scan this QR code or enter the code above to join your trip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                HStack(spacing: 16) {
                    Button {
                        if let shareCode = trip.shareCode {
                            UIPasteboard.general.string = shareCode
                            ToastManager.shared.show("Code copied!", type: .success)
                        }
                    } label: {
                        Label("Copy Code", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    
                    ShareLink(item: generateShareMessage(), subject: Text("Join my trip!")) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            if let shareCode = trip.shareCode {
                qrImage = QRCodeGenerator.shared.generateQRCode(from: shareCode)
            }
        }
    }
    
    func generateShareMessage() -> String {
        """
        Join my RoadTrip: \(trip.name)
        
        Use code: \(trip.shareCode ?? "")
        
        Dates: \(trip.startDate.formatted(date: .abbreviated, time: .omitted)) - \(trip.endDate.formatted(date: .abbreviated, time: .omitted))
        """
    }
}

// MARK: - Activity Comments View
struct ActivityCommentsView: View {
    @Bindable var activity: Activity
    @State private var newComment = ""
    @State private var currentUserId = "user123"
    @State private var currentUserEmail = "user@example.com" // Replace with actual auth
    
    var body: some View {
        VStack(spacing: 0) {
            // Comments List
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if activity.comments.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No comments yet")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Be the first to comment!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(activity.comments.sorted(by: { $0.createdAt > $1.createdAt }), id: \.id) { comment in
                            CommentRow(comment: comment, currentUserId: currentUserId)
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Comment Input
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Add a comment...", text: $newComment, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                
                Button {
                    addComment()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func addComment() {
        let trimmed = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let comment = ActivityComment(userId: currentUserId, userEmail: currentUserEmail, text: trimmed)
        activity.comments.append(comment)
        newComment = ""
        
        // TODO: Sync to CloudKit for real-time updates
    }
}

struct CommentRow: View {
    let comment: ActivityComment
    let currentUserId: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 36, height: 36)
                .overlay {
                    Text(comment.userEmail.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.userEmail)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if comment.userId == currentUserId {
                        Text("(You)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(comment.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(comment.text)
                    .font(.body)
                
                if let updatedAt = comment.updatedAt {
                    Text("Edited \(updatedAt, style: .relative)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Activity Voting View
struct ActivityVotingView: View {
    @Bindable var activity: Activity
    @State private var currentUserId = "user123" // Replace with actual auth
    
    var currentUserVote: Int? {
        activity.votes[currentUserId]
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Upvote
            Button {
                toggleVote(value: 1)
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: currentUserVote == 1 ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.title3)
                    
                    Text("\(activity.votes.values.filter { $0 == 1 }.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .foregroundStyle(currentUserVote == 1 ? .green : .secondary)
            
            Divider()
                .frame(height: 40)
            
            // Vote Score
            VStack(spacing: 4) {
                Text("\(activity.voteScore)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(activity.voteScore > 0 ? .green : activity.voteScore < 0 ? .red : .secondary)
                
                Text("Score")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
                .frame(height: 40)
            
            // Downvote
            Button {
                toggleVote(value: -1)
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: currentUserVote == -1 ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .font(.title3)
                    
                    Text("\(activity.votes.values.filter { $0 == -1 }.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .foregroundStyle(currentUserVote == -1 ? .red : .secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    func toggleVote(value: Int) {
        if currentUserVote == value {
            // Remove vote if clicking same button
            activity.votes.removeValue(forKey: currentUserId)
        } else {
            // Add or change vote
            activity.votes[currentUserId] = value
        }
        
        // TODO: Sync to CloudKit for real-time updates
    }
}

// MARK: - Real-time Sync Manager
class CollaborationSyncManager: ObservableObject {
    static let shared = CollaborationSyncManager()
    
    @Published var isConnected = false
    @Published var lastSyncTime: Date?
    
    private init() {}
    
    // TODO: Implement CloudKit subscriptions for real-time updates
    func startListening(for trip: Trip) {
        // Subscribe to CloudKit changes for this trip
        isConnected = true
    }
    
    func stopListening() {
        isConnected = false
    }
    
    func syncComment(_ comment: ActivityComment, for activity: Activity) {
        // Push comment to CloudKit
        lastSyncTime = Date()
    }
    
    func syncVote(userId: String, value: Int, for activity: Activity) {
        // Push vote to CloudKit
        lastSyncTime = Date()
    }
}
