// Views/TripDetail/EditActivityView.swift
import SwiftUI

struct EditActivityView: View {
    @Environment(\.dismiss) private var dismiss
    let activity: Activity
    let day: TripDay
    
    @State private var activityName = ""
    @State private var location = ""
    @State private var category = "Attraction"
    @State private var includeTime = false
    @State private var scheduledTime = Date()
    @State private var duration: Double = 1.0
    @State private var notes = ""
    
    let categories = ["Food", "Attraction", "Hotel", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Activity Details") {
                    TextField("Activity Name", text: $activityName)
                    TextField("Location", text: $location)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
                
                Section("Schedule") {
                    Toggle("Set Time", isOn: $includeTime)
                    
                    if includeTime {
                        DatePicker("Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                        
                        Stepper("Duration: \(Int(duration * 60)) min", value: $duration, in: 0.25...8, step: 0.25)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveActivity()
                    }
                    .disabled(activityName.isEmpty || location.isEmpty)
                }
            }
            .onAppear {
                activityName = activity.name
                location = activity.location
                category = activity.category
                notes = activity.notes ?? ""
                
                if let time = activity.scheduledTime {
                    includeTime = true
                    scheduledTime = time
                }
                if let dur = activity.duration {
                    duration = dur
                }
            }
        }
    }
    
    private func saveActivity() {
        activity.name = activityName
        activity.location = location
        activity.category = category
        activity.notes = notes.isEmpty ? nil : notes
        activity.duration = includeTime ? duration : nil
        
        if includeTime {
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
            activity.scheduledTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                    minute: timeComponents.minute ?? 0,
                                                    second: 0,
                                                    of: day.date)
        } else {
            activity.scheduledTime = nil
        }
        
        dismiss()
    }
}
