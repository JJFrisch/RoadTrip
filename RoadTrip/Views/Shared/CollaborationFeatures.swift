//
//  CollaborationFeatures.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import SwiftUI

// Trip sharing / QR-code collaboration is currently disabled.

#if false

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
    }
}

#endif
