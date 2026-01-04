// Views/Home/EditTripView.swift
import SwiftUI

struct EditTripView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let trip: Trip
    
    @State private var tripName: String = ""
    @State private var tripDescription: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var coverImage: String = ""
    @State private var showingDaysWarning = false
    
    var isFormValid: Bool {
        !tripName.trimmingCharacters(in: .whitespaces).isEmpty && endDate >= startDate
    }
    
    var currentDayCount: Int {
        trip.days.count
    }
    
    var newDayCount: Int {
        max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day! + 1)
    }
    
    var daysWillChange: Bool {
        newDayCount != currentDayCount
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    TextField("Trip Name", text: $tripName)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $tripDescription)
                            .frame(minHeight: 60)
                    }
                }
                
                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    
                    // Days preview
                    HStack {
                        Label("Duration", systemImage: "calendar")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(newDayCount) day\(newDayCount == 1 ? "" : "s")")
                            .fontWeight(.medium)
                        if newDayCount > 1 {
                            Text("(\(newDayCount - 1) night\(newDayCount - 1 == 1 ? "" : "s"))")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if daysWillChange {
                        HStack(spacing: 8) {
                            Image(systemName: newDayCount > currentDayCount ? "plus.circle.fill" : "minus.circle.fill")
                                .foregroundStyle(newDayCount > currentDayCount ? .green : .orange)
                            
                            if newDayCount > currentDayCount {
                                Text("\(newDayCount - currentDayCount) day\(newDayCount - currentDayCount == 1 ? "" : "s") will be added")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            } else {
                                Text("\(currentDayCount - newDayCount) day\(currentDayCount - newDayCount == 1 ? "" : "s") will be removed")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        if newDayCount < currentDayCount {
                            Text("Activities from removed days will be moved to the last day")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Dates")
                } footer: {
                    if endDate < startDate {
                        Text("End date must be after or equal to start date")
                            .foregroundStyle(.red)
                    }
                }
                
                Section("Appearance") {
                    HStack {
                        Text("Cover Icon")
                        Spacer()
                        TextField("SF Symbol name", text: $coverImage)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.never)
                    }
                    
                    if !coverImage.isEmpty {
                        HStack {
                            Spacer()
                            Image(systemName: coverImage)
                                .font(.system(size: 50))
                                .foregroundStyle(.blue.gradient)
                                .symbolRenderingMode(.hierarchical)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Icon suggestions
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(["car.fill", "airplane", "bicycle", "figure.hiking", "tent.fill", "beach.umbrella.fill", "mountain.2.fill", "building.2.fill"], id: \.self) { icon in
                                Button {
                                    coverImage = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundStyle(coverImage == icon ? .white : .blue)
                                        .frame(width: 44, height: 44)
                                        .background(coverImage == icon ? Color.blue : Color.blue.opacity(0.1))
                                        .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
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
                        if daysWillChange && newDayCount < currentDayCount {
                            showingDaysWarning = true
                        } else {
                            saveChanges()
                        }
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                tripName = trip.name
                tripDescription = trip.tripDescription ?? ""
                startDate = trip.startDate
                endDate = trip.endDate
                coverImage = trip.coverImage ?? ""
            }
            .alert("Adjust Trip Days?", isPresented: $showingDaysWarning) {
                Button("Cancel", role: .cancel) { }
                Button("Continue") {
                    saveChanges()
                }
            } message: {
                Text("Reducing the trip from \(currentDayCount) to \(newDayCount) days will move activities from removed days to Day \(newDayCount).")
            }
        }
    }
    
    private func saveChanges() {
        trip.name = tripName.trimmingCharacters(in: .whitespaces)
        trip.tripDescription = tripDescription.trimmingCharacters(in: .whitespaces).isEmpty ? nil : tripDescription
        trip.coverImage = coverImage.isEmpty ? nil : coverImage
        
        // Update dates and adjust days
        if startDate != trip.startDate || endDate != trip.endDate {
            trip.updateDates(newStartDate: startDate, newEndDate: endDate)
        }
        
        try? modelContext.save()
        dismiss()
    }
}
