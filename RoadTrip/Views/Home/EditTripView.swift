// Views/Home/EditTripView.swift
import SwiftUI

struct EditTripView: View {
    @Environment(\.dismiss) private var dismiss
    let trip: Trip
    
    @State private var tripName: String = ""
    @State private var tripDescription: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var coverImage: String = ""
    
    var isFormValid: Bool {
        !tripName.trimmingCharacters(in: .whitespaces).isEmpty && endDate >= startDate
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    TextField("Trip Name", text: $tripName)
                    TextField("Description", text: $tripDescription)
                }
                
                Section("Dates") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    
                    if endDate < startDate {
                        Text("End date must be after or equal to start date")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                Section("Appearance") {
                    HStack {
                        Text("Cover Icon")
                        Spacer()
                        TextField("SF Symbol", text: $coverImage)
                            .multilineTextAlignment(.trailing)
                            .font(.title2)
                    }
                    
                    if !coverImage.isEmpty {
                        VStack {
                            Image(systemName: coverImage)
                                .font(.system(size: 60))
                                .foregroundStyle(.blue.gradient)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                tripName = trip.name
                tripDescription = trip.tripDescription ?? ""
                startDate = trip.startDate
                endDate = trip.endDate
                coverImage = trip.coverImage ?? ""
            }
        }
    }
    
    private func saveChanges() {
        trip.name = tripName.trimmingCharacters(in: .whitespaces)
        trip.tripDescription = tripDescription.trimmingCharacters(in: .whitespaces).isEmpty ? nil : tripDescription
        trip.startDate = startDate
        trip.endDate = endDate
        trip.coverImage = coverImage.isEmpty ? nil : coverImage
        dismiss()
    }
}
