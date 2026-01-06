// Views/Shared/TripSharingView.swift
import SwiftUI

struct TripSharingView: View {
    @Environment(\.dismiss) private var dismiss
    let trip: Trip
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "square.and.arrow.up.circle")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)

                Text("Trip sharing")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Coming soon")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Share Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TripSharingView(trip: Trip(name: "Test Trip", startDate: Date(), endDate: Date()))
}
