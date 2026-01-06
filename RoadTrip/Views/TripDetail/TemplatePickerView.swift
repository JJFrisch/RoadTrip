// Views/TripDetail/TemplatePickerView.swift
import SwiftUI
import SwiftData

struct TemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let kindsOfActivities: [ActivityTemplate]
    let onSelect: (ActivityTemplate) -> Void
    
    @State private var showingNewTemplate = false
    
    var sortedKindsOfActivities: [ActivityTemplate] {
        // Sort by use count (most popular first), then by last used
        let items = kindsOfActivities
        return items.sorted { first, second in
            if first.usageCount != second.usageCount {
                return first.usageCount > second.usageCount
            }
            let firstLastUsed = first.lastUsed ?? first.createdAt
            let secondLastUsed = second.lastUsed ?? second.createdAt
            return firstLastUsed > secondLastUsed
        }
    }
    
    var commonKindsOfActivities: [ActivityTemplate] {
        ActivityTemplate.commonTemplates()
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !kindsOfActivities.isEmpty {
                    Section("Your Kinds of Activities") {
                        ForEach(sortedKindsOfActivities) { kind in
                            Button {
                                onSelect(kind)
                                dismiss()
                            } label: {
                                TemplateRow(template: kind)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    modelContext.delete(kind)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                Section("Common Kinds of Activities") {
                    ForEach(commonKindsOfActivities) { kind in
                        Button {
                            // Save to user kinds if used
                            let newKind = ActivityTemplate(
                                name: kind.name,
                                location: kind.location,
                                category: kind.category,
                                defaultDuration: kind.defaultDuration
                            )
                            newKind.notes = kind.notes
                            newKind.estimatedCost = kind.estimatedCost
                            newKind.costCategory = kind.costCategory
                            modelContext.insert(newKind)
                            onSelect(newKind)
                            dismiss()
                        } label: {
                            TemplateRow(template: kind)
                        }
                    }
                }
            }
            .navigationTitle("Kinds of Activities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewTemplate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewTemplate) {
                NewTemplateView()
            }
        }
    }
}

struct TemplateRow: View {
    let template: ActivityTemplate
    
    var categoryColor: Color {
        switch template.category {
        case "Food": return .orange
        case "Attraction": return .blue
        case "Hotel": return .purple
        default: return .gray
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Label(template.category, systemImage: categoryIcon)
                        .font(.caption)
                        .foregroundStyle(categoryColor)

                    let duration = template.defaultDuration
                    if duration > 0 {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text("\(Int(duration * 60))m")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if template.usageCount > 0 {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text("Used \(template.usageCount)×")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
    
    var categoryIcon: String {
        switch template.category {
        case "Food": return "fork.knife"
        case "Attraction": return "star.fill"
        case "Hotel": return "bed.double.fill"
        default: return "mappin"
        }
    }
}

struct NewTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var category = "Attraction"
    @State private var duration: Double = 1.0
    @State private var notes = ""
    
    let categories = ["Food", "Attraction", "Hotel", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Kind Details") {
                    TextField("Kind Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    Stepper("Duration: \(Int(duration * 60)) min", value: $duration, in: 0.25...8, step: 0.25)
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("New Kind")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let template = ActivityTemplate(
                            name: name,
                            category: category,
                            defaultDuration: duration
                        )
                        template.notes = notes.isEmpty ? nil : notes
                        modelContext.insert(template)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
