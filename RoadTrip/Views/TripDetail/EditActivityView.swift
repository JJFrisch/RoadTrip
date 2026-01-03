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
    @State private var endTime = Date()
    @State private var duration: Double = 1.0
    @State private var notes = ""
    
    // Search near location
    @State private var searchNearLocation = ""
    @State private var useSearchNear = false
    
    // Budget tracking
    @State private var includeCost = false
    @State private var estimatedCost: Double = 0
    @State private var costCategory = "Other"
    
    // Track which field was last edited to handle auto-adjustments
    @State private var lastEditedTimeField: TimeField = .startTime
    
    enum TimeField {
        case startTime, endTime, duration
    }
    
    let categories = ["Food", "Attraction", "Hotel", "Other"]
    let costCategories = ["Gas", "Food", "Lodging", "Attractions", "Other"]
    
    var isFormValid: Bool {
        !activityName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Search Near Location") {
                    Toggle("Search near specific location", isOn: $useSearchNear)
                    
                    if useSearchNear {
                        LocationSearchField(
                            title: "Search Near",
                            location: $searchNearLocation,
                            icon: "location.magnifyingglass",
                            iconColor: .orange,
                            placeholder: "Enter city or address"
                        )
                        
                        if !searchNearLocation.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Location searches will be near: \(searchNearLocation)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "location.circle")
                                .foregroundStyle(.secondary)
                            Text("Searching near: \(day.startLocation.isEmpty ? "No location set" : day.startLocation)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Activity Details") {
                    TextField("Activity Name", text: $activityName)
                    
                    LocationSearchField(
                        title: "Location",
                        location: $location,
                        icon: "mappin.circle.fill",
                        iconColor: .blue,
                        searchRegionAddress: useSearchNear ? searchNearLocation : day.startLocation
                    )
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
                
                Section("Schedule") {
                    Toggle("Set Time", isOn: $includeTime)
                    
                    if includeTime {
                        DatePicker("Start Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                            .onChange(of: scheduledTime) { _, newValue in
                                if lastEditedTimeField != .startTime { return }
                                // Keep duration fixed, adjust end time
                                endTime = Calendar.current.date(byAdding: .minute, value: Int(duration * 60), to: newValue) ?? newValue
                            }
                        
                        DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                            .onChange(of: endTime) { _, newValue in
                                if lastEditedTimeField != .endTime { return }
                                // Adjust duration based on start and end time
                                let diff = newValue.timeIntervalSince(scheduledTime)
                                if diff > 0 {
                                    duration = diff / 3600.0 // Convert seconds to hours
                                }
                            }
                        
                        // Duration with finer control
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Duration")
                                Spacer()
                                Text(formatDuration(duration))
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack(spacing: 12) {
                                Button {
                                    adjustDuration(by: -5)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                                .disabled(duration <= 5.0/60.0)
                                
                                Slider(value: $duration, in: 0.0833...8, step: 0.0833) // 5-minute steps
                                    .onChange(of: duration) { _, newValue in
                                        if lastEditedTimeField != .duration { return }
                                        // Adjust end time based on duration
                                        endTime = Calendar.current.date(byAdding: .minute, value: Int(newValue * 60), to: scheduledTime) ?? scheduledTime
                                    }
                                
                                Button {
                                    adjustDuration(by: 5)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                                .disabled(duration >= 8)
                            }
                            
                            // Quick duration buttons
                            HStack(spacing: 8) {
                                ForEach([15, 30, 45, 60, 90, 120], id: \.self) { minutes in
                                    Button {
                                        setDuration(minutes: minutes)
                                    } label: {
                                        Text(minutes < 60 ? "\(minutes)m" : "\(minutes/60)h\(minutes % 60 > 0 ? "\(minutes % 60)m" : "")")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Int(duration * 60) == minutes ? Color.blue : Color.gray.opacity(0.2))
                                            .foregroundStyle(Int(duration * 60) == minutes ? .white : .primary)
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
                
                Section("Budget") {
                    Toggle("Add Estimated Cost", isOn: $includeCost)
                    
                    if includeCost {
                        HStack {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField("0.00", value: $estimatedCost, format: .number.precision(.fractionLength(2)))
                                .keyboardType(.decimalPad)
                        }
                        
                        Picker("Cost Category", selection: $costCategory) {
                            ForEach(costCategories, id: \.self) { cat in
                                HStack {
                                    Image(systemName: iconForCostCategory(cat))
                                    Text(cat)
                                }.tag(cat)
                            }
                        }
                        
                        // Quick cost buttons
                        HStack(spacing: 8) {
                            ForEach([10, 25, 50, 100, 200], id: \.self) { amount in
                                Button {
                                    estimatedCost = Double(amount)
                                } label: {
                                    Text("$\(amount)")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Int(estimatedCost) == amount ? Color.green : Color.gray.opacity(0.2))
                                        .foregroundStyle(Int(estimatedCost) == amount ? .white : .primary)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                // Activity info section
                Section("Activity Info") {
                    if activity.isCompleted {
                        Label("Marked as completed", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("Not completed", systemImage: "circle")
                            .foregroundStyle(.secondary)
                    }
                    
                    if let rating = activity.rating {
                        HStack {
                            Text("Rating")
                            Spacer()
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                        .foregroundStyle(.yellow)
                                        .font(.caption)
                                }
                            }
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let website = activity.website, !website.isEmpty {
                        Link(destination: URL(string: website) ?? URL(string: "https://google.com")!) {
                            Label("Website", systemImage: "globe")
                        }
                    }
                    
                    if let phone = activity.phoneNumber, !phone.isEmpty {
                        Link(destination: URL(string: "tel:\(phone)") ?? URL(string: "tel:")!) {
                            Label(phone, systemImage: "phone.fill")
                        }
                    }
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
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                loadActivityData()
            }
            // Track which time field is being edited
            .onChange(of: scheduledTime) { _, _ in lastEditedTimeField = .startTime }
            .onChange(of: endTime) { _, _ in lastEditedTimeField = .endTime }
        }
    }
    
    private func loadActivityData() {
        activityName = activity.name
        location = activity.location
        category = activity.category
        notes = activity.notes ?? ""
        searchNearLocation = day.startLocation
        
        // Load time settings
        if let time = activity.scheduledTime {
            includeTime = true
            scheduledTime = time
            if let dur = activity.duration {
                duration = dur
                endTime = Calendar.current.date(byAdding: .minute, value: Int(dur * 60), to: time) ?? time
            } else {
                endTime = Calendar.current.date(byAdding: .minute, value: Int(duration * 60), to: time) ?? time
            }
        } else {
            // Initialize end time based on default duration
            endTime = Calendar.current.date(byAdding: .minute, value: Int(duration * 60), to: scheduledTime) ?? scheduledTime
        }
        
        // Load budget settings
        if let cost = activity.estimatedCost, cost > 0 {
            includeCost = true
            estimatedCost = cost
            costCategory = activity.costCategory ?? "Other"
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
                return "\(h) hr"
            } else {
                return "\(h) hr \(m) min"
            }
        }
    }
    
    private func adjustDuration(by minutes: Int) {
        lastEditedTimeField = .duration
        let newDuration = duration + Double(minutes) / 60.0
        if newDuration >= 5.0/60.0 && newDuration <= 8 {
            duration = newDuration
            endTime = Calendar.current.date(byAdding: .minute, value: Int(duration * 60), to: scheduledTime) ?? scheduledTime
        }
    }
    
    private func setDuration(minutes: Int) {
        lastEditedTimeField = .duration
        duration = Double(minutes) / 60.0
        endTime = Calendar.current.date(byAdding: .minute, value: minutes, to: scheduledTime) ?? scheduledTime
    }
    
    private func iconForCostCategory(_ category: String) -> String {
        switch category {
        case "Gas": return "fuelpump.fill"
        case "Food": return "fork.knife"
        case "Lodging": return "bed.double.fill"
        case "Attractions": return "star.fill"
        default: return "dollarsign.circle"
        }
    }
    
    private func saveActivity() {
        activity.name = activityName.trimmingCharacters(in: .whitespaces)
        activity.location = location.trimmingCharacters(in: .whitespaces)
        activity.category = category
        activity.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        
        // Save time settings
        if includeTime {
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
            activity.scheduledTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                    minute: timeComponents.minute ?? 0,
                                                    second: 0,
                                                    of: day.date)
            activity.duration = duration
        } else {
            activity.scheduledTime = nil
            activity.duration = nil
        }
        
        // Save budget settings
        if includeCost && estimatedCost > 0 {
            activity.estimatedCost = estimatedCost
            activity.costCategory = costCategory
        } else {
            activity.estimatedCost = nil
            activity.costCategory = nil
        }
        
        dismiss()
    }
}
