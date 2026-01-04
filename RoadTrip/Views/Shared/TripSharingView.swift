// Views/Shared/TripSharingView.swift
import SwiftUI

struct TripSharingView: View {
    @Environment(\.dismiss) private var dismiss
    let trip: Trip
    
    @StateObject private var sharingService = TripSharingService.shared
    @StateObject private var authService = AuthService.shared
    
    @State private var shareRole: TripCollaborator.CollaboratorRole = .editor
    @State private var showingShareSheet = false
    @State private var shareCode: String = ""
    @State private var copiedToClipboard = false
    
    var body: some View {
        NavigationStack {
            List {
                // Share Code Section
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)
                        
                        Text("Share \"\(trip.name)\"")
                            .font(.headline)
                        
                        Text("Invite others to view or edit this trip")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                
                // Role Selection
                Section {
                    Picker("Permission", selection: $shareRole) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Can Edit")
                        }
                        .tag(TripCollaborator.CollaboratorRole.editor)
                        
                        HStack {
                            Image(systemName: "eye")
                            Text("View Only")
                        }
                        .tag(TripCollaborator.CollaboratorRole.viewer)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Permission Level")
                } footer: {
                    Text(shareRole == .editor ? "Editors can add, edit, and remove activities" : "Viewers can only see the trip details")
                }
                
                // Share Code Display
                if let code = trip.shareCode, !code.isEmpty {
                    Section("Share Code") {
                        HStack {
                            Text(code)
                                .font(.system(.title, design: .monospaced))
                                .fontWeight(.bold)
                                .tracking(4)
                            
                            Spacer()
                            
                            Button {
                                UIPasteboard.general.string = code
                                withAnimation {
                                    copiedToClipboard = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        copiedToClipboard = false
                                    }
                                }
                            } label: {
                                Image(systemName: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc")
                                    .foregroundStyle(copiedToClipboard ? .green : .blue)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Share Actions
                Section {
                    Button {
                        generateAndShare()
                    } label: {
                        Label("Share via Message or Email", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        generateCode()
                        if sharingService.copyShareLink(for: trip) {
                            withAnimation {
                                copiedToClipboard = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    copiedToClipboard = false
                                }
                            }
                        }
                    } label: {
                        Label(copiedToClipboard ? "Copied!" : "Copy Invite Link", systemImage: copiedToClipboard ? "checkmark.circle.fill" : "link")
                    }
                }
                
                // Current Collaborators
                let collaborators = sharingService.getCollaborators(for: trip)
                if !collaborators.isEmpty {
                    Section("People with Access") {
                        ForEach(collaborators) { collaborator in
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(collaborator.role == .owner ? Color.blue : Color.gray.opacity(0.3))
                                        .frame(width: 36, height: 36)
                                    
                                    Text(collaborator.displayName.prefix(1).uppercased())
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(collaborator.role == .owner ? .white : .primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(collaborator.displayName)
                                        .font(.subheadline)
                                    Text(collaborator.email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(collaborator.role.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(6)
                            }
                            .swipeActions(edge: .trailing) {
                                if collaborator.role != .owner {
                                    Button(role: .destructive) {
                                        sharingService.removeCollaborator(collaborator, from: trip)
                                    } label: {
                                        Label("Remove", systemImage: "person.badge.minus")
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Stop Sharing
                if trip.isShared {
                    Section {
                        Button(role: .destructive) {
                            stopSharing()
                        } label: {
                            Label("Stop Sharing", systemImage: "xmark.circle")
                        }
                    }
                }
            }
            .navigationTitle("Share Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func generateCode() {
        if trip.shareCode == nil || trip.shareCode?.isEmpty == true {
            _ = sharingService.createShareInvite(for: trip, role: shareRole)
        }
    }
    
    private func generateAndShare() {
        generateCode()
        sharingService.shareTrip(trip)
    }
    
    private func stopSharing() {
        trip.isShared = false
        trip.shareCode = nil
        trip.sharedWith.removeAll()
    }
}

// MARK: - Join Trip View (for accepting invites)
struct JoinTripView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sharingService = TripSharingService.shared
    
    @State private var shareCode = ""
    @State private var isJoining = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "person.2.badge.plus")
                    .font(.system(size: 70))
                    .foregroundStyle(.blue)
                
                VStack(spacing: 8) {
                    Text("Join a Shared Trip")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter the 6-character code shared with you")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Code input
                TextField("XXXXXX", text: $shareCode)
                    .font(.system(.title, design: .monospaced))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
                    .onChange(of: shareCode) { _, newValue in
                        // Limit to 6 characters and uppercase
                        shareCode = String(newValue.uppercased().prefix(6))
                    }
                
                Button {
                    joinTrip()
                } label: {
                    if isJoining {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Join Trip")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(shareCode.count == 6 ? Color.blue : Color.gray)
                .foregroundStyle(.white)
                .cornerRadius(12)
                .padding(.horizontal, 40)
                .disabled(shareCode.count != 6 || isJoining)
                
                Spacer()
                Spacer()
            }
            .navigationTitle("Join Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func joinTrip() {
        isJoining = true
        Task {
            do {
                _ = try await sharingService.joinTrip(withCode: shareCode)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isJoining = false
        }
    }
}

#Preview {
    TripSharingView(trip: Trip(name: "Test Trip", startDate: Date(), endDate: Date()))
}
