// Views/TripDetail/EditActivityView.swift
import SwiftUI

struct EditActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
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
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScreenHeader("Edit Activity", subtitle: "Update details, timing, and budget")

                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            FormSection("Search Context", subtitle: "Set where suggestions should focus") {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                    Toggle("Search near a specific area", isOn: $useSearchNear)

                                    if useSearchNear {
                                        LocationSearchField(
                                            title: "Search Near",
                                            location: $searchNearLocation,
                                            icon: "location.magnifyingglass",
                                            iconColor: .orange,
                                            placeholder: "Enter city or address"
                                        )

                                        if !searchNearLocation.isEmpty {
                                            Label("Searching near: \(searchNearLocation)", systemImage: "checkmark.circle.fill")
                                                .font(AppTheme.Typography.caption1)
                                                .foregroundStyle(.green)
                                        }
                                    } else {
                                        Label("Searching near: \(day.startLocation.isEmpty ? "No location set" : day.startLocation)", systemImage: "location.circle")
                                            .font(AppTheme.Typography.caption1)
                                            .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                                    }
                                }
                            }

                            FormSection("Activity Details", subtitle: "Core information") {
                                VStack(spacing: AppTheme.Spacing.md) {
                                    FormField(
                                        label: "Activity Name",
                                        placeholder: "e.g., Sunset viewpoint",
                                        text: $activityName,
                                        errorMessage: "Name is required",
                                        isValid: !activityName.trimmingCharacters(in: .whitespaces).isEmpty
                                    )

                                    LocationSearchField(
                                        title: "Location",
                                        location: $location,
                                        icon: "mappin.circle.fill",
                                        iconColor: .blue,
                                        searchRegionAddress: useSearchNear ? searchNearLocation : day.startLocation
                                    )

                                    if location.trimmingCharacters(in: .whitespaces).isEmpty {
                                        Label("Location is required", systemImage: "exclamationmark.circle.fill")
                                            .font(AppTheme.Typography.caption2)
                                            .foregroundStyle(AppTheme.Colors.danger)
                                    }

                                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                        Text("Category")
                                            .font(AppTheme.Typography.footnote)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))

                                        Picker("Category", selection: $category) {
                                            ForEach(categories, id: \.self) { cat in
                                                Text(cat).tag(cat)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                    }
                                }
                            }

                            FormSection("Schedule", subtitle: "Optional time and duration") {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                    Toggle("Set specific time", isOn: $includeTime)

                                    if includeTime {
                                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                            Text("Start Time")
                                                .font(AppTheme.Typography.footnote)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
                                            DatePicker("", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                                                .labelsHidden()
                                                .onChange(of: scheduledTime) { _, newValue in
                                                    if lastEditedTimeField != .startTime { return }
                                                    endTime = Calendar.current.date(byAdding: .minute, value: Int(duration * 60), to: newValue) ?? newValue
                                                }
                                        }

                                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                            Text("End Time")
                                                .font(AppTheme.Typography.footnote)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
                                            DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                                .labelsHidden()
                                                .onChange(of: endTime) { _, newValue in
                                                    if lastEditedTimeField != .endTime { return }
                                                    let diff = newValue.timeIntervalSince(scheduledTime)
                                                    if diff > 0 {
                                                        duration = diff / 3600.0
                                                    }
                                                }
                                        }

                                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                            HStack {
                                                Text("Duration")
                                                    .font(AppTheme.Typography.subheadline)
                                                    .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
                                                Spacer()
                                                Text(formatDuration(duration))
                                                    .font(AppTheme.Typography.callout)
                                                    .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                                            }

                                            HStack(spacing: AppTheme.Spacing.sm) {
                                                Button {
                                                    adjustDuration(by: -5)
                                                } label: {
                                                    Image(systemName: "minus.circle.fill")
                                                        .font(.title3)
                                                        .foregroundStyle(AppTheme.Colors.primary)
                                                }
                                                .buttonStyle(.plain)
                                                .disabled(duration <= 5.0 / 60.0)

                                                Slider(value: $duration, in: 0.0833...8, step: 0.0833)
                                                    .onChange(of: duration) { _, newValue in
                                                        if lastEditedTimeField != .duration { return }
                                                        endTime = Calendar.current.date(byAdding: .minute, value: Int(newValue * 60), to: scheduledTime) ?? scheduledTime
                                                    }

                                                Button {
                                                    adjustDuration(by: 5)
                                                } label: {
                                                    Image(systemName: "plus.circle.fill")
                                                        .font(.title3)
                                                        .foregroundStyle(AppTheme.Colors.primary)
                                                }
                                                .buttonStyle(.plain)
                                                .disabled(duration >= 8)
                                            }

                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: AppTheme.Spacing.xs) {
                                                    ForEach([15, 30, 45, 60, 90, 120], id: \.self) { minutes in
                                                        Button {
                                                            setDuration(minutes: minutes)
                                                        } label: {
                                                            Text(minutes < 60 ? "\(minutes)m" : "\(minutes/60)h\(minutes % 60 > 0 ? "\(minutes % 60)m" : "")")
                                                                .font(AppTheme.Typography.caption1)
                                                                .padding(.horizontal, AppTheme.Spacing.sm)
                                                                .padding(.vertical, AppTheme.Spacing.xs)
                                                                .background(Int(duration * 60) == minutes ? AppTheme.Colors.primary : AppTheme.Colors.divider.opacity(0.4))
                                                                .foregroundStyle(Int(duration * 60) == minutes ? Color.white : AppTheme.Colors.primaryText.color(for: colorScheme))
                                                                .cornerRadius(AppTheme.CornerRadius.small)
                                                        }
                                                        .buttonStyle(.plain)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(AppTheme.Spacing.sm)
                                        .background(AppTheme.Colors.background)
                                        .cornerRadius(AppTheme.CornerRadius.medium)
                                    }
                                }
                            }

                            FormSection("Notes", subtitle: "Optional planning details") {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                    Text("Notes")
                                        .font(AppTheme.Typography.footnote)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))

                                    TextEditor(text: $notes)
                                        .font(AppTheme.Typography.body)
                                        .frame(height: 100)
                                        .padding(AppTheme.Spacing.sm)
                                        .background(AppTheme.Colors.background)
                                        .cornerRadius(AppTheme.CornerRadius.medium)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                                .stroke(AppTheme.Colors.divider, lineWidth: 1)
                                        )
                                }
                            }

                            FormSection("Budget", subtitle: "Optional estimated cost") {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                    Toggle("Add estimated cost", isOn: $includeCost)

                                    if includeCost {
                                        HStack(spacing: AppTheme.Spacing.xs) {
                                            Text("$")
                                                .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                                            TextField("0.00", value: $estimatedCost, format: .number.precision(.fractionLength(2)))
                                                .keyboardType(.decimalPad)
                                        }
                                        .padding(AppTheme.Spacing.sm)
                                        .background(AppTheme.Colors.background)
                                        .cornerRadius(AppTheme.CornerRadius.medium)

                                        Picker("Cost Category", selection: $costCategory) {
                                            ForEach(costCategories, id: \.self) { cat in
                                                Label(cat, systemImage: iconForCostCategory(cat)).tag(cat)
                                            }
                                        }
                                        .pickerStyle(.menu)

                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: AppTheme.Spacing.xs) {
                                                ForEach([10, 25, 50, 100, 200], id: \.self) { amount in
                                                    Button {
                                                        estimatedCost = Double(amount)
                                                    } label: {
                                                        Text("$\(amount)")
                                                            .font(AppTheme.Typography.caption1)
                                                            .padding(.horizontal, AppTheme.Spacing.sm)
                                                            .padding(.vertical, AppTheme.Spacing.xs)
                                                            .background(Int(estimatedCost) == amount ? AppTheme.Colors.success : AppTheme.Colors.divider.opacity(0.4))
                                                            .foregroundStyle(Int(estimatedCost) == amount ? Color.white : AppTheme.Colors.primaryText.color(for: colorScheme))
                                                            .cornerRadius(AppTheme.CornerRadius.small)
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            FormSection("Activity Info", subtitle: "Reference details") {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                    if activity.isCompleted {
                                        Label("Included in schedule", systemImage: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    } else {
                                        Label("Not included in schedule", systemImage: "circle")
                                            .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                                    }

                                    if let rating = activity.rating {
                                        HStack {
                                            Text("Rating")
                                                .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
                                            Spacer()
                                            HStack(spacing: 2) {
                                                ForEach(1...5, id: \.self) { star in
                                                    Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                                        .foregroundStyle(AppTheme.Colors.accent)
                                                        .font(.caption)
                                                }
                                            }
                                            Text(String(format: "%.1f", rating))
                                                .font(AppTheme.Typography.caption1)
                                                .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                                        }
                                    }

                                    if let website = activity.website, !website.isEmpty {
                                        Link(destination: URL(string: website) ?? URL(string: "https://google.com")!) {
                                            Label("Open Website", systemImage: "globe")
                                        }
                                    }

                                    if let phone = activity.phoneNumber, !phone.isEmpty {
                                        Link(destination: URL(string: "tel:\(phone)") ?? URL(string: "tel:")!) {
                                            Label(phone, systemImage: "phone.fill")
                                        }
                                    }
                                }
                            }

                            Spacer().frame(height: AppTheme.Spacing.sm)
                        }
                        .padding(.vertical, AppTheme.Spacing.lg)
                    }

                    ActionButtonGroup(
                        primaryTitle: "Save Activity",
                        primaryAction: {
                            guard isFormValid else { return }
                            saveActivity()
                        },
                        secondaryTitle: "Discard Changes",
                        secondaryAction: { dismiss() }
                    )
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
