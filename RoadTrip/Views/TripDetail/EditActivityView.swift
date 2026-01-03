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
                    
                    LocationSearchField(
                        title: "Location",
                        location: $location,
                        icon: "mappin.circle.fill",
                        iconColor: .blue
                    )
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
                
                Section {
                    Toggle("Schedule Time", isOn: $includeTime)
                    
                    if includeTime {
                        DatePicker("Start Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                        
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text("\(formatDuration(duration))")
                                .foregroundStyle(.secondary)
                        }
                        
                        Picker("Duration", selection: $duration) {
                            Text("15 min").tag(0.25)
                            Text("30 min").tag(0.5)
                            Text("45 min").tag(0.75)
                            Text("1 hour").tag(1.0)
                            Text("1.5 hours").tag(1.5)
                            Text("2 hours").tag(2.0)
                            Text("2.5 hours").tag(2.5)
                            Text("3 hours").tag(3.0)
                            Text("4 hours").tag(4.0)
                            Text("5 hours").tag(5.0)
                            Text("6 hours").tag(6.0)
                            Text("8 hours").tag(8.0)
                        }
                        .pickerStyle(.wheel)
                        
                        if let endTime = calculateEndTime() {
                            HStack {
                                Text("End Time")
                                Spacer()
                                Text(endTime.formatted(date: .omitted, time: .shortened))
                                    .foregroundStyle(.secondary)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                } header: {
                    Text("Schedule")
                } footer: {
                    if includeTime {
                        Text("Set a specific time for this activity to see it in your schedule timeline")
                            .font(.caption)
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
    
    private func formatDuration(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        if totalMinutes < 60 {
            return "\(totalMinutes) min"
        } else {
            let h = totalMinutes / 60
            let m = totalMinutes % 60
            if m == 0 {
                return "\(h) hour\(h == 1 ? "" : "s")"
            } else {
                return "\(h)h \(m)m"
            }
        }
    }
    
    private func calculateEndTime() -> Date? {
        guard includeTime else { return nil }
        return Calendar.current.date(byAdding: .minute, value: Int(duration * 60), to: scheduledTime)
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
