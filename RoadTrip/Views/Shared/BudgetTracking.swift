//
//  BudgetTracking.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import Foundation
import SwiftUI
import Charts
import SwiftData

// MARK: - Budget Manager
class BudgetManager: ObservableObject {
    static let shared = BudgetManager()
    
    let categories = ["Gas", "Food", "Lodging", "Attractions", "Shopping", "Other"]
    
    func calculateSpentByCategory(for trip: Trip) -> [String: Double] {
        var spending: [String: Double] = [:]
        
        for day in trip.days {
            for activity in day.activities {
                if let cost = activity.estimatedCost, let category = activity.costCategory {
                    spending[category, default: 0] += cost
                }
            }
        }
        
        return spending
    }
    
    func calculateTotalSpent(for trip: Trip) -> Double {
        calculateSpentByCategory(for: trip).values.reduce(0, +)
    }
    
    func budgetProgress(for trip: Trip) -> Double {
        guard let budget = trip.totalBudget, budget > 0 else { return 0 }
        return min(calculateTotalSpent(for: trip) / budget, 1.0)
    }
    
    func isOverBudget(for trip: Trip) -> Bool {
        guard let budget = trip.totalBudget else { return false }
        return calculateTotalSpent(for: trip) > budget
    }
    
    func remainingBudget(for trip: Trip) -> Double {
        guard let budget = trip.totalBudget else { return 0 }
        return budget - calculateTotalSpent(for: trip)
    }
}

// MARK: - Budget Summary View
struct BudgetSummaryView: View {
    @Bindable var trip: Trip
    @State private var showingBudgetEditor = false
    @StateObject private var budgetManager = BudgetManager.shared
    
    var spendingByCategory: [String: Double] {
        budgetManager.calculateSpentByCategory(for: trip)
    }
    
    var totalSpent: Double {
        budgetManager.calculateTotalSpent(for: trip)
    }
    
    var body: some View {
        List {
            // Overall Budget Section
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Budget")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let budget = trip.totalBudget {
                            Text("$\(budget, specifier: "%.2f")")
                                .font(.title2)
                                .fontWeight(.bold)
                        } else {
                            Button("Set Budget") {
                                showingBudgetEditor = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("Spent")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("$\(totalSpent, specifier: "%.2f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(budgetManager.isOverBudget(for: trip) ? .red : .primary)
                    }
                }
                .padding(.vertical, 8)
                
                if let budget = trip.totalBudget {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Progress")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(budgetManager.budgetProgress(for: trip) * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        ProgressView(value: budgetManager.budgetProgress(for: trip))
                            .tint(budgetManager.isOverBudget(for: trip) ? .red : .green)
                        
                        Text(budgetManager.isOverBudget(for: trip) 
                             ? "Over budget by $\(abs(budgetManager.remainingBudget(for: trip)), specifier: "%.2f")"
                             : "Remaining: $\(budgetManager.remainingBudget(for: trip), specifier: "%.2f")")
                            .font(.caption)
                            .foregroundStyle(budgetManager.isOverBudget(for: trip) ? .red : .green)
                    }
                }
            } header: {
                HStack {
                    Text("Overview")
                    Spacer()
                    Button {
                        showingBudgetEditor = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
            
            // Spending by Category Chart
            if !spendingByCategory.isEmpty {
                Section("Spending Breakdown") {
                    Chart {
                        ForEach(Array(spendingByCategory.sorted(by: { $0.value > $1.value })), id: \.key) { category, amount in
                            BarMark(
                                x: .value("Amount", amount),
                                y: .value("Category", category)
                            )
                            .foregroundStyle(by: .value("Category", category))
                            .annotation(position: .trailing) {
                                Text("$\(amount, specifier: "%.0f")")
                                    .font(.caption)
                            }
                        }
                    }
                    .frame(height: 250)
                    .chartLegend(.hidden)
                    
                    // Category Details
                    ForEach(Array(spendingByCategory.sorted(by: { $0.value > $1.value })), id: \.key) { category, amount in
                        HStack {
                            categoryIcon(for: category)
                            Text(category)
                            Spacer()
                            Text("$\(amount, specifier: "%.2f")")
                                .fontWeight(.medium)
                            
                            if let categoryBudget = trip.budgetCategories[category] {
                                Text("/ $\(categoryBudget, specifier: "%.0f")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            
            // Daily Spending
            Section("Daily Spending") {
                Chart {
                    ForEach(trip.days.sorted(by: { $0.dayNumber < $1.dayNumber })) { day in
                        let daySpending = day.activities.compactMap { $0.estimatedCost }.reduce(0, +)
                        
                        LineMark(
                            x: .value("Day", "Day \(day.dayNumber)"),
                            y: .value("Spent", daySpending)
                        )
                        .foregroundStyle(.blue)
                        .symbol(.circle)
                        
                        PointMark(
                            x: .value("Day", "Day \(day.dayNumber)"),
                            y: .value("Spent", daySpending)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text("$\(amount, specifier: "%.0f")")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Budget")
        .sheet(isPresented: $showingBudgetEditor) {
            BudgetEditorView(trip: trip)
        }
    }
    
    @ViewBuilder
    func categoryIcon(for category: String) -> some View {
        Image(systemName: {
            switch category {
            case "Gas": return "fuelpump.fill"
            case "Food": return "fork.knife"
            case "Lodging": return "bed.double.fill"
            case "Attractions": return "ticket.fill"
            case "Shopping": return "bag.fill"
            default: return "dollarsign.circle.fill"
            }
        }())
        .foregroundStyle(.blue)
    }
}

// MARK: - Budget Editor
struct BudgetEditorView: View {
    @Bindable var trip: Trip
    @Environment(\.dismiss) private var dismiss
    
    @State private var totalBudget: String
    @State private var categoryBudgets: [String: String] = [:]
    
    let categories = BudgetManager.shared.categories
    
    init(trip: Trip) {
        self.trip = trip
        _totalBudget = State(initialValue: trip.totalBudget != nil ? String(format: "%.2f", trip.totalBudget!) : "")
        
        var initial: [String: String] = [:]
        for category in BudgetManager.shared.categories {
            if let budget = trip.budgetCategories[category] {
                initial[category] = String(format: "%.2f", budget)
            } else {
                initial[category] = ""
            }
        }
        _categoryBudgets = State(initialValue: initial)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Total Budget") {
                    HStack {
                        Text("$")
                        TextField("0.00", text: $totalBudget)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Category Budgets") {
                    ForEach(categories, id: \.self) { category in
                        HStack {
                            Image(systemName: iconForCategory(category))
                            Text(category)
                            Spacer()
                            Text("$")
                            TextField("0.00", text: Binding(
                                get: { categoryBudgets[category] ?? "" },
                                set: { categoryBudgets[category] = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                        }
                    }
                }
                
                Section {
                    Button("Quick Split Evenly") {
                        guard let total = Double(totalBudget), total > 0 else { return }
                        let perCategory = total / Double(categories.count)
                        for category in categories {
                            categoryBudgets[category] = String(format: "%.2f", perCategory)
                        }
                    }
                }
            }
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBudget()
                        dismiss()
                    }
                }
            }
        }
    }
    
    func saveBudget() {
        trip.totalBudget = Double(totalBudget)
        
        var newCategoryBudgets: [String: Double] = [:]
        for (category, value) in categoryBudgets {
            if let amount = Double(value), amount > 0 {
                newCategoryBudgets[category] = amount
            }
        }
        trip.budgetCategories = newCategoryBudgets
    }
    
    func iconForCategory(_ category: String) -> String {
        switch category {
        case "Gas": return "fuelpump.fill"
        case "Food": return "fork.knife"
        case "Lodging": return "bed.double.fill"
        case "Attractions": return "ticket.fill"
        case "Shopping": return "bag.fill"
        default: return "dollarsign.circle.fill"
        }
    }
}
