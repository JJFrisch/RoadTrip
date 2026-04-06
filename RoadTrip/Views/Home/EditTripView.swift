// Views/Home/EditTripView.swift
// Refactored for UX Polish: Custom form sections, polished components, consistent design system
import SwiftUI

struct EditTripView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    let trip: Trip
    
    @State private var tripName: String = ""
    @State private var tripDescription: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var coverImage: String = ""
    @State private var showingDaysWarning = false
    
    private let iconSuggestions = ["car.fill", "airplane", "bicycle", "figure.hiking", "tent.fill", "beach.umbrella.fill", "mountain.2.fill", "building.2.fill"]
    
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
    
    var daysWillBeRemoved: Bool {
        newDayCount < currentDayCount
    }
    
    var removedDaysHaveData: Bool {
        guard daysWillBeRemoved else { return false }
        let daysToRemove = trip.days.sorted(by: { $0.dayNumber < $1.dayNumber }).suffix(currentDayCount - newDayCount)
        return daysToRemove.contains { !$0.activities.isEmpty || !$0.startLocation.isEmpty || !$0.endLocation.isEmpty }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Polished header
                    ScreenHeader("Edit Trip", subtitle: "Update trip details")
                    
                    // Form content
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            // Trip Details Section
                            FormSection("Trip Details", subtitle: "Name and description of your trip") {
                                VStack(spacing: AppTheme.Spacing.md) {
                                    FormField(
                                        label: "Trip Name",
                                        placeholder: "e.g., Summer Road Trip",
                                        text: $tripName,
                                        isValid: !tripName.trimmingCharacters(in: .whitespaces).isEmpty
                                    )
                                    
                                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                        Text("Description (Optional)")
                                            .font(AppTheme.Typography.footnote)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
                                        
                                        TextEditor(text: $tripDescription)
                                            .font(AppTheme.Typography.body)
                                            .frame(minHeight: 80)
                                            .padding(AppTheme.Spacing.sm)
                                            .background(AppTheme.Colors.background)
                                            .cornerRadius(AppTheme.CornerRadius.medium)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                                    .stroke(AppTheme.Colors.divider, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            
                            // Dates Section
                            FormSection("Trip Dates", subtitle: "Set your travel dates") {
                                VStack(spacing: AppTheme.Spacing.md) {
                                    // Start Date
                                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                        Text("Start Date")
                                            .font(AppTheme.Typography.footnote)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
                                        
                                        DatePicker("", selection: $startDate, displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    // End Date
                                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                        Text("End Date")
                                            .font(AppTheme.Typography.footnote)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
                                        
                                        DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    
                                    // Duration Summary
                                    HStack(spacing: AppTheme.Spacing.md) {
                                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                            Text("Duration")
                                                .font(AppTheme.Typography.caption1)
                                                .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                                            Text("\(newDayCount) day\(newDayCount == 1 ? "" : "s")")
                                                .font(AppTheme.Typography.headline)
                                                .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
                                        }
                                        
                                        Spacer()
                                        
                                        if newDayCount > 1 {
                                            VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                                                Text("Nights")
                                                    .font(AppTheme.Typography.caption1)
                                                    .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                                                Text("\(newDayCount - 1)")
                                                    .font(AppTheme.Typography.headline)
                                                    .foregroundStyle(AppTheme.Colors.primary)
                                            }
                                        }
                                    }
                                    .padding(AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.background)
                                    .cornerRadius(AppTheme.CornerRadius.medium)
                                    
                                    // Days Change Warning
                                    if daysWillChange {
                                        HStack(spacing: AppTheme.Spacing.md) {
                                            Image(systemName: newDayCount > currentDayCount ? "plus.circle.fill" : "minus.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(newDayCount > currentDayCount ? .green : AppTheme.Colors.warning)
                                            
                                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                                if newDayCount > currentDayCount {
                                                    Text("\(newDayCount - currentDayCount) day\(newDayCount - currentDayCount == 1 ? "" : "s") will be added")
                                                        .font(AppTheme.Typography.callout)
                                                        .foregroundStyle(.green)
                                                } else {
                                                    Text("\(currentDayCount - newDayCount) day\(currentDayCount - newDayCount == 1 ? "" : "s") will be removed")
                                                        .font(AppTheme.Typography.callout)
                                                        .foregroundStyle(AppTheme.Colors.warning)
                                                    
                                                    if removedDaysHaveData {
                                                        Text("Activities will be moved to the last day")
                                                            .font(AppTheme.Typography.caption2)
                                                            .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                                                    }
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(AppTheme.Spacing.md)
                                        .background(newDayCount > currentDayCount ? Color.green.opacity(0.1) : AppTheme.Colors.warning.opacity(0.1))
                                        .cornerRadius(AppTheme.CornerRadius.medium)
                                    }
                                    
                                    // Validation Error
                                    if endDate < startDate {
                                        Label("End date must be after start date", systemImage: "exclamationmark.circle.fill")
                                            .font(AppTheme.Typography.callout)
                                            .foregroundStyle(AppTheme.Colors.danger)
                                    }
                                }
                            }
                            
                            // Appearance Section
                            FormSection("Trip Icon", subtitle: "Choose a visual identifier") {
                                VStack(spacing: AppTheme.Spacing.md) {
                                    // Icon preview (if set)
                                    if !coverImage.isEmpty {
                                        HStack {
                                            Spacer()
                                            VStack(spacing: AppTheme.Spacing.sm) {
                                                Image(systemName: coverImage)
                                                    .font(.system(size: 44))
                                                    .foregroundStyle(AppTheme.Colors.primary)
                                                Text("Preview")
                                                    .font(AppTheme.Typography.caption2)
                                                    .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, AppTheme.Spacing.md)
                                    }
                                    
                                    // Icon suggestions grid
                                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                        Text("Suggested Icons")
                                            .font(AppTheme.Typography.caption1)
                                            .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                                        
                                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: AppTheme.Spacing.md) {
                                            ForEach(iconSuggestions, id: \.self) { icon in
                                                Button {
                                                    withAnimation(.easeInOut(duration: AppTheme.Animation.fast)) {
                                                        coverImage = icon
                                                    }
                                                } label: {
                                                    Image(systemName: icon)
                                                        .font(.system(size: 22))
                                                        .frame(height: 48)
                                                        .frame(maxWidth: .infinity)
                                                        .foregroundStyle(coverImage == icon ? .white : AppTheme.Colors.primary)
                                                        .background(coverImage == icon ? AppTheme.Colors.primary : AppTheme.Colors.primary.opacity(0.1))
                                                        .cornerRadius(AppTheme.CornerRadius.medium)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Spacing for bottom content
                            Spacer().frame(height: AppTheme.Spacing.md)
                        }
                        .padding(.vertical, AppTheme.Spacing.lg)
                    }
                    
                    // Action buttons at bottom
                    ActionButtonGroup(
                        primaryTitle: "Save Changes",
                        primaryAction: {
                            if daysWillBeRemoved && removedDaysHaveData {
                                showingDaysWarning = true
                            } else {
                                saveChanges()
                            }
                        },
                        secondaryTitle: "Cancel",
                        secondaryAction: { dismiss() }
                    )
                }
            }
            .onAppear {
                tripName = trip.name
                tripDescription = trip.tripDescription ?? ""
                startDate = trip.startDate
                endDate = trip.endDate
                coverImage = trip.coverImage ?? ""
            }
                .overlay(
                    ConfirmationSheet(
                        isPresented: $showingDaysWarning,
                        title: "Adjust Trip Days?",
                        message: "Reducing the trip from \(currentDayCount) to \(newDayCount) days will move activities from removed days to Day \(newDayCount).",
                        actionTitle: "Continue",
                        actionStyle: .primary,
                        onConfirm: { saveChanges() }
                    )
                )
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
