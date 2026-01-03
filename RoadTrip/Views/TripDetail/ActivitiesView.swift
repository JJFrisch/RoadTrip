// Views/TripDetail/ActivitiesView.swift
import SwiftUI
import SwiftData

struct ActivitiesView: View {
    @Environment(\.modelContext) private var modelContext
    let trip: Trip
    @State private var showingAddActivity = false
    @State private var showingImportActivity = false
    @State private var selectedDay: TripDay?
    @State private var showingMap = false
    @State private var editingActivity: Activity?
    @State private var activityToDelete: Activity?
    @State private var editMode: EditMode = .inactive

    
    var body: some View {
        List {
            Section {
                Button {
                    showingMap = true
                } label: {
                    Label("Show Activities on Map", systemImage: "map")
                }
            }
            
            ForEach(trip.days.sorted(by: { $0.dayNumber < $1.dayNumber })) { day in
                Section {
                    if day.activities.isEmpty {
                        Text("No activities yet")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        ForEach(day.activities.sorted(by: { $0.order < $1.order })) { activity in
                            HStack(spacing: 12) {
                                Button {
                                    activity.isCompleted.toggle()
                                } label: {
                                    Image(systemName: activity.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(activity.isCompleted ? .green : .gray)
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                                
                                ActivityRowView(activity: activity)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingActivity = activity
                                    }
                            }
                            .contextMenu {
                                Button {
                                    editingActivity = activity
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    activityToDelete = activity
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onMove { indices, newOffset in
                            moveActivity(in: day, from: indices, to: newOffset)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            selectedDay = day
                            showingImportActivity = false
                            showingAddActivity = true
                        } label: {
                            Label("Add Activity", systemImage: "plus.circle")
                        }
                        
                        Button {
                            selectedDay = day
                            showingAddActivity = false
                            showingImportActivity = true
                        } label: {
                            Label("Import Activities", systemImage: "arrow.down.circle")
                        }
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
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingMap) {
            let allActivities = trip.days.flatMap { $0.activities }
            ActivitiesMapView(activities: allActivities)
        }
        .sheet(isPresented: $showingAddActivity) {
            if let day = selectedDay {
                AddActivityView(day: day)
                    .environment(\.modelContext, modelContext)
                    .presentationBackground(.white)
                    .presentationDragIndicator(.hidden)
                    .interactiveDismissDisabled(false)
            }
        }
        .sheet(isPresented: $showingImportActivity) {
            if let day = selectedDay {
                ActivityImportSheet(day: day)
            }
        }
        .sheet(item: $editingActivity) { activity in
            if let day = trip.days.first(where: { $0.activities.contains(where: { $0.id == activity.id }) }) {
                EditActivityView(activity: activity, day: day)
            }
        }
        .alert("Delete Activity", isPresented: .constant(activityToDelete != nil), presenting: activityToDelete) { activity in
            Button(role: .destructive) {
                deleteActivity(activity)
                activityToDelete = nil
            } label: {
                Text("Delete")
            }
            Button(role: .cancel) {
                activityToDelete = nil
            } label: {
                Text("Cancel")
            }
        } message: { activity in
            Text("Are you sure you want to delete \"\(activity.name)\"?")
        }
    }
    
    private func deleteActivity(_ activity: Activity) {
        modelContext.delete(activity)
    }
    
    private func moveActivity(in day: TripDay, from source: IndexSet, to destination: Int) {
        var sortedActivities = day.activities.sorted(by: { $0.order < $1.order })
        sortedActivities.move(fromOffsets: source, toOffset: destination)
        
        // Update order property for all activities in this day
        for (index, activity) in sortedActivities.enumerated() {
            activity.order = index
        }
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                
                Image(systemName: categoryIcon)
                    .font(.caption)
                    .foregroundStyle(categoryColor)
            }
            .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if let time = activity.scheduledTime {
                        Text(time.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.red.opacity(0.6))
                    
                    Text(activity.location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                if let duration = activity.duration {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange.opacity(0.6))
                        
                        Text("\(Int(duration * 60)) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Add the "Open in Maps" button here
            Button {
                let query = activity.location.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
                if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Image(systemName: "map.circle.fill")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
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
    @Environment(\.modelContext) private var modelContext
    let day: TripDay
    
    @State private var activityName = ""
    @State private var location = ""
    @State private var category = "Attraction"
    @State private var includeTime = false
    @State private var scheduledTime = Date()
    @State private var duration: Double = 1.0
    @State private var notes = ""
    @State private var showingTemplates = false
    @State private var useSuggestedTime = true
    
    @Query private var templates: [ActivityTemplate]
    
    let categories = ["Food", "Attraction", "Hotel", "Other"]
    
    var isFormValid: Bool {
        !activityName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    init(day: TripDay) {
        self.day = day
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showingTemplates = true
                    } label: {
                        Label("Use Template", systemImage: "doc.on.doc")
                    }
                }
                
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
                    .onChange(of: category) { _, newValue in
                        updateSuggestedTime()
                    }
                }
                
                Section("Schedule") {
                    Toggle("Set Time", isOn: $includeTime)
                    
                    if includeTime {
                        Toggle("Use Smart Suggestion", isOn: $useSuggestedTime)
                            .onChange(of: useSuggestedTime) { _, newValue in
                                if newValue {
                                    updateSuggestedTime()
                                }
                            }
                        
                        DatePicker("Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                            .disabled(useSuggestedTime)
                        
                        Stepper("Duration: \(Int(duration * 60)) min", value: $duration, in: 0.25...8, step: 0.25)
                        
                        if useSuggestedTime {
                            Text("Time suggested based on previous activities")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingTemplates) {
                TemplatePickerView(templates: templates, onSelect: { template in
                    applyTemplate(template)
                })
            }
        }
    }
    
    private func addActivity() {
        let activity = Activity(name: activityName.trimmingCharacters(in: .whitespaces), 
                               location: location.trimmingCharacters(in: .whitespaces), 
                               category: category)
        
        // Set order to be at the end
        activity.order = day.activities.count
        
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
        
        activity.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        day.activities.append(activity)
        dismiss()
    }
    
    private func updateSuggestedTime() {
        guard useSuggestedTime && includeTime else { return }
        
        Task {
            do {
                let (suggestedTime, suggestedDuration) = await TimeHelper.calculateSmartTimeForNewActivity(
                    day: day,
                    newActivityCategory: category,
                    newActivityName: activityName
                )
                
                await MainActor.run {
                    scheduledTime = suggestedTime
                    duration = suggestedDuration
                }
            } catch {
                // If suggestion fails, use defaults
                await MainActor.run {
                    scheduledTime = Date()
                    duration = 1.0
                }
            }
        }
    }
    
    private func applyTemplate(_ template: ActivityTemplate) {
        activityName = template.name
        category = template.category
        if let suggestedDuration = template.suggestedDuration {
            duration = suggestedDuration
        }
        if let templateNotes = template.notes {
            notes = templateNotes
        }
        
        // Update use count
        template.useCount += 1
        template.lastUsed = Date()
        
        updateSuggestedTime()
        showingTemplates = false
    }
}
