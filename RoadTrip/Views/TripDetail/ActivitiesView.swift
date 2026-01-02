// Views/TripDetail/ActivitiesView.swift
import SwiftUI
import SwiftData

struct ActivitiesView: View {
    @Environment(\.modelContext) private var modelContext
    let trip: Trip
    @State private var showingAddActivity = false
    @State private var selectedDay: TripDay?
    @State private var showingMap = false

    
    var body: some View {
        Button {
            showingMap = true
        } label: {
            Label("Show Activities on Map", systemImage: "map")
        }
        .sheet(isPresented: $showingMap) {
            let allActivities = trip.days.flatMap { $0.activities }
            ActivitiesMapView(activities: allActivities)
        }
        List {
            ForEach(trip.days.sorted(by: { $0.dayNumber < $1.dayNumber })) { day in
                Section {
                    if day.activities.isEmpty {
                        Text("No activities yet")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        ForEach(day.activities) { activity in
                            ActivityRowView(activity: activity)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteActivity(activity)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    
                    Button {
                        selectedDay = day
                        showingAddActivity = true
                    } label: {
                        Label("Add Activity", systemImage: "plus.circle")
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day \(day.dayNumber)")
                            .font(.headline)
                        Text("\(day.startLocation) → \(day.endLocation)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showingAddActivity) {
            if let day = selectedDay {
                AddActivityView(day: day)
            }
        }
    }
    
    private func deleteActivity(_ activity: Activity) {
        modelContext.delete(activity)
    }
}

struct ActivityRowView: View {
    let activity: Activity
    
    var categoryColor: Color {
        switch activity.category {
        case "Food": return .orange
        case "Attraction": return .blue
        case "Hotel": return .purple
        default: return .gray
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: categoryIcon)
                .foregroundStyle(categoryColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.headline)
                Text(activity.location)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let time = activity.scheduledTime {
                Text(time.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Add the "Open in Maps" button here
            Button {
                let query = activity.location.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
                if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Image(systemName: "map")
            }
            .buttonStyle(.borderless)
        }
    }
    
    private var categoryIcon: String {
        switch activity.category {
        case "Food": return "fork.knife"
        case "Attraction": return "star.fill"
        case "Hotel": return "bed.double.fill"
        default: return "mappin.circle.fill"
        }
    }
}


struct AddActivityView: View {
    @Environment(\.dismiss) private var dismiss
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
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addActivity()
                    }
                    .disabled(activityName.isEmpty || location.isEmpty)
                }
            }
        }
    }
    
    private func addActivity() {
        let activity = Activity(name: activityName, location: location, category: category)
        
        if includeTime {
            // Combine day's date with selected time
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
            activity.scheduledTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                    minute: timeComponents.minute ?? 0,
                                                    second: 0,
                                                    of: day.date)
            activity.duration = duration
        }
        
        activity.notes = notes.isEmpty ? nil : notes
        day.activities.append(activity)
        dismiss()
    }
}
