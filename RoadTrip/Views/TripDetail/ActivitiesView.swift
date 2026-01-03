// Views/TripDetail/ActivitiesView.swift
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

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
    @State private var draggedActivity: Activity?

    
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
                        // Drop zone for empty days
                        Text("No activities yet")
                            .foregroundStyle(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                            .onDrop(of: [.text], isTargeted: nil) { providers in
                                handleDrop(providers: providers, targetDay: day, targetIndex: 0)
                            }
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
                            // MARK: - Swipe Actions
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    withAnimation {
                                        activity.isCompleted.toggle()
                                    }
                                } label: {
                                    Label(
                                        activity.isCompleted ? "Unmark" : "Complete",
                                        systemImage: activity.isCompleted ? "xmark.circle" : "checkmark.circle"
                                    )
                                }
                                .tint(activity.isCompleted ? .orange : .green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    activityToDelete = activity
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .onDrag {
                                draggedActivity = activity
                                return NSItemProvider(object: activity.id.uuidString as NSString)
                            }
                            .onDrop(of: [.text], isTargeted: nil) { providers in
                                handleDrop(providers: providers, targetDay: day, targetIndex: activity.order)
                            }
                            .contextMenu {
                                // Move to day submenu
                                Menu {
                                    ForEach(trip.days.sorted(by: { $0.dayNumber < $1.dayNumber })) { targetDay in
                                        if targetDay.id != day.id {
                                            Button {
                                                moveActivityToDay(activity, from: day, to: targetDay)
                                            } label: {
                                                Label("Day \(targetDay.dayNumber)", systemImage: "calendar")
                                            }
                                        }
                                    }
                                } label: {
                                    Label("Move to Day", systemImage: "arrow.right.circle")
                                }
                                
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
                            showingAddActivity = true
                        } label: {
                            Label("Add Activity", systemImage: "plus.circle")
                        }
                        
                        Button {
                            selectedDay = day
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
        .sheet(isPresented: $showingAddActivity, onDismiss: { selectedDay = nil }) {
            if let day = selectedDay {
                AddActivityView(day: day)
            }
        }
        .sheet(isPresented: $showingImportActivity, onDismiss: { selectedDay = nil }) {
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
    
    // MARK: - Cross-Day Drag & Drop
    
    private func handleDrop(providers: [NSItemProvider], targetDay: TripDay, targetIndex: Int) -> Bool {
        guard let draggedActivity = draggedActivity else { return false }
        
        // Find source day
        guard let sourceDay = trip.days.first(where: { $0.activities.contains(where: { $0.id == draggedActivity.id }) }) else {
            return false
        }
        
        // If dropping in same day, just reorder
        if sourceDay.id == targetDay.id {
            reorderActivityInDay(draggedActivity, in: sourceDay, to: targetIndex)
        } else {
            // Move to different day
            moveActivityToDay(draggedActivity, from: sourceDay, to: targetDay, atIndex: targetIndex)
        }
        
        self.draggedActivity = nil
        return true
    }
    
    private func reorderActivityInDay(_ activity: Activity, in day: TripDay, to newIndex: Int) {
        var sortedActivities = day.activities.sorted(by: { $0.order < $1.order })
        
        // Find current index
        guard let currentIndex = sortedActivities.firstIndex(where: { $0.id == activity.id }) else { return }
        
        // Remove and reinsert
        sortedActivities.remove(at: currentIndex)
        let insertIndex = min(newIndex, sortedActivities.count)
        sortedActivities.insert(activity, at: insertIndex)
        
        // Update order for all
        for (index, act) in sortedActivities.enumerated() {
            act.order = index
        }
    }
    
    private func moveActivityToDay(_ activity: Activity, from sourceDay: TripDay, to targetDay: TripDay, atIndex: Int? = nil) {
        // Remove from source day
        sourceDay.activities.removeAll { $0.id == activity.id }
        
        // Update order in source day
        let sourceSorted = sourceDay.activities.sorted(by: { $0.order < $1.order })
        for (index, act) in sourceSorted.enumerated() {
            act.order = index
        }
        
        // Add to target day
        let targetIndex = atIndex ?? targetDay.activities.count
        activity.order = targetIndex
        targetDay.activities.append(activity)
        
        // Update order in target day
        var targetSorted = targetDay.activities.sorted(by: { $0.order < $1.order })
        for (index, act) in targetSorted.enumerated() {
            act.order = index
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
    @State private var endTime = Date()
    @State private var duration: Double = 1.0
    @State private var notes = ""
    @State private var showingTemplates = false
    @State private var useSuggestedTime = true
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
    
    @Query private var templates: [ActivityTemplate]
    
    let categories = ["Food", "Attraction", "Hotel", "Other"]
    let costCategories = ["Gas", "Food", "Lodging", "Attractions", "Other"]
    
    var isFormValid: Bool {
        !activityName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // Computed search region based on searchNearLocation
    var searchRegionAddress: String? {
        if useSearchNear && !searchNearLocation.isEmpty {
            return searchNearLocation
        }
        return day.startLocation.isEmpty ? nil : day.startLocation
    }
    
    init(day: TripDay) {
        self.day = day
        // Initialize searchNearLocation with day's start location
        _searchNearLocation = State(initialValue: day.startLocation)
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
                        
                        DatePicker("Start Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                            .disabled(useSuggestedTime)
                            .onChange(of: scheduledTime) { _, newValue in
                                if lastEditedTimeField != .startTime { return }
                                // Keep duration fixed, adjust end time
                                endTime = Calendar.current.date(byAdding: .minute, value: Int(duration * 60), to: newValue) ?? newValue
                            }
                        
                        DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                            .disabled(useSuggestedTime)
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
                                
                                Slider(value: $duration, in: 0.0833...8, step: 0.0833) // 5-minute steps (5/60 = 0.0833)
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
            .onAppear {
                // Initialize end time based on default duration
                endTime = Calendar.current.date(byAdding: .minute, value: Int(duration * 60), to: scheduledTime) ?? scheduledTime
            }
            // Track which time field is being edited
            .onChange(of: scheduledTime) { _, _ in lastEditedTimeField = .startTime }
            .onChange(of: endTime) { _, _ in lastEditedTimeField = .endTime }
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
        
        // Budget tracking
        if includeCost && estimatedCost > 0 {
            activity.estimatedCost = estimatedCost
            activity.costCategory = costCategory
        }
        
        activity.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        day.activities.append(activity)
        dismiss()
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
    
    private func updateSuggestedTime() {
        guard useSuggestedTime && includeTime else { return }
        
        Task {
            let (suggestedTime, suggestedDuration) = await TimeHelper.calculateSmartTimeForNewActivity(
                day: day,
                newActivityCategory: category,
                newActivityName: activityName
            )
            
            await MainActor.run {
                scheduledTime = suggestedTime
                duration = suggestedDuration
                endTime = Calendar.current.date(byAdding: .minute, value: Int(suggestedDuration * 60), to: suggestedTime) ?? suggestedTime
            }
        }
    }
    
    private func applyTemplate(_ template: ActivityTemplate) {
        activityName = template.name
        category = template.category
        if let suggestedDuration = template.suggestedDuration {
            duration = suggestedDuration
            endTime = Calendar.current.date(byAdding: .minute, value: Int(suggestedDuration * 60), to: scheduledTime) ?? scheduledTime
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
