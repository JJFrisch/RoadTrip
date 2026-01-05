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
    
    let categoryColors: [String: Color] = [
        "Gas": .orange,
        "Food": .green,
        "Lodging": .blue,
        "Attractions": .purple,
        "Shopping": .pink,
        "Other": .gray
    ]
    
    func calculateSpentByCategory(for trip: Trip) -> [String: Double] {
        var spending: [String: Double] = [:]
        
        for day in trip.safeDays {
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
        return min(calculateTotalSpent(for: trip) / budget, 1.5) // Allow showing over 100%
    }
    
    func isOverBudget(for trip: Trip) -> Bool {
        guard let budget = trip.totalBudget else { return false }
        return calculateTotalSpent(for: trip) > budget
    }
    
    func remainingBudget(for trip: Trip) -> Double {
        guard let budget = trip.totalBudget else { return 0 }
        return budget - calculateTotalSpent(for: trip)
    }
    
    func categoryProgress(for trip: Trip, category: String) -> Double {
        guard let categoryBudget = trip.budgetCategories[category], categoryBudget > 0 else { return 0 }
        let spent = calculateSpentByCategory(for: trip)[category] ?? 0
        return min(spent / categoryBudget, 1.5)
    }
    
    func dailyAverage(for trip: Trip) -> Double {
        let dayCount = max(trip.safeDays.count, 1)
        return calculateTotalSpent(for: trip) / Double(dayCount)
    }
    
    func projectedTotal(for trip: Trip) -> Double {
        let completedDays = trip.safeDays.filter { $0.date < Date() }.count
        guard completedDays > 0 else { return calculateTotalSpent(for: trip) }
        let totalDays = trip.safeDays.count
        let dailyRate = calculateTotalSpent(for: trip) / Double(completedDays)
        return dailyRate * Double(totalDays)
    }
    
    func getBudgetStatus(for trip: Trip) -> BudgetStatus {
        guard trip.totalBudget != nil else { return .noBudget }
        let progress = budgetProgress(for: trip)
        
        if progress > 1.0 { return .overBudget }
        if progress > 0.9 { return .nearLimit }
        if progress > 0.75 { return .caution }
        return .onTrack
    }
    
    func getInsights(for trip: Trip) -> [BudgetInsight] {
        var insights: [BudgetInsight] = []
        let spending = calculateSpentByCategory(for: trip)
        let total = calculateTotalSpent(for: trip)
        
        // Find highest spending category
        if let (topCategory, topAmount) = spending.max(by: { $0.value < $1.value }) {
            let percentage = total > 0 ? (topAmount / total * 100) : 0
            insights.append(BudgetInsight(
                icon: "chart.pie.fill",
                title: "Top Spending",
                message: "\(topCategory) is your biggest expense at \(Int(percentage))% of total",
                type: .info
            ))
        }
        
        // Check if over budget
        if isOverBudget(for: trip) {
            let overBy = abs(remainingBudget(for: trip))
            insights.append(BudgetInsight(
                icon: "exclamationmark.triangle.fill",
                title: "Over Budget",
                message: "You've exceeded your budget by $\(String(format: "%.2f", overBy))",
                type: .warning
            ))
        }
        
        // Projected spending
        let projected = projectedTotal(for: trip)
        if let budget = trip.totalBudget, projected > budget * 1.1 {
            insights.append(BudgetInsight(
                icon: "chart.line.uptrend.xyaxis",
                title: "Spending Trend",
                message: "At current rate, you'll spend $\(String(format: "%.0f", projected)) (projected)",
                type: .caution
            ))
        }
        
        // Daily average insight
        let avg = dailyAverage(for: trip)
        if avg > 0 {
            insights.append(BudgetInsight(
                icon: "calendar",
                title: "Daily Average",
                message: "You're spending about $\(String(format: "%.0f", avg)) per day",
                type: .info
            ))
        }
        
        return insights
    }
}

enum BudgetStatus {
    case noBudget, onTrack, caution, nearLimit, overBudget
    
    var color: Color {
        switch self {
        case .noBudget: return .gray
        case .onTrack: return .green
        case .caution: return .yellow
        case .nearLimit: return .orange
        case .overBudget: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .noBudget: return "questionmark.circle"
        case .onTrack: return "checkmark.circle.fill"
        case .caution: return "exclamationmark.circle"
        case .nearLimit: return "exclamationmark.triangle"
        case .overBudget: return "xmark.circle.fill"
        }
    }
    
    var message: String {
        switch self {
        case .noBudget: return "No budget set"
        case .onTrack: return "On Track"
        case .caution: return "Watch Spending"
        case .nearLimit: return "Near Limit"
        case .overBudget: return "Over Budget"
        }
    }
}

struct BudgetInsight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let message: String
    let type: InsightType
    
    enum InsightType {
        case info, caution, warning
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .caution: return .orange
            case .warning: return .red
            }
        }
    }
}

// MARK: - Enhanced Budget Summary View
struct BudgetSummaryView: View {
    @Bindable var trip: Trip
    @State private var showingBudgetEditor = false
    @State private var showingQuickExpense = false
    @State private var selectedCategory: String? = nil
    @State private var showingCategoryDetail = false
    @State private var animateCharts = false
    @State private var selectedTab = 0
    @StateObject private var budgetManager = BudgetManager.shared
    
    var spendingByCategory: [String: Double] {
        budgetManager.calculateSpentByCategory(for: trip)
    }
    
    var totalSpent: Double {
        budgetManager.calculateTotalSpent(for: trip)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero Budget Card
                BudgetHeroCard(trip: trip, budgetManager: budgetManager)
                    .padding(.horizontal)
                
                // Quick Actions
                QuickActionsBar(
                    showingBudgetEditor: $showingBudgetEditor,
                    showingQuickExpense: $showingQuickExpense
                )
                .padding(.horizontal)
                
                // Tab Selector
                Picker("View", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Categories").tag(1)
                    Text("Timeline").tag(2)
                    Text("Insights").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        overviewTab
                    case 1:
                        categoriesTab
                    case 2:
                        timelineTab
                    case 3:
                        insightsTab
                    default:
                        overviewTab
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            }
            .padding(.vertical)
        }
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingBudgetEditor = true
                    } label: {
                        Label("Edit Budget", systemImage: "pencil")
                    }
                    
                    Button {
                        showingQuickExpense = true
                    } label: {
                        Label("Add Expense", systemImage: "plus.circle")
                    }
                    
                    Divider()
                    
                    ShareLink(item: generateBudgetReport()) {
                        Label("Share Report", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingBudgetEditor) {
            BudgetEditorView(trip: trip)
        }
        .sheet(isPresented: $showingQuickExpense) {
            QuickExpenseView(trip: trip)
        }
        .sheet(isPresented: $showingCategoryDetail) {
            if let category = selectedCategory {
                CategoryDetailView(trip: trip, category: category)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                animateCharts = true
            }
        }
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        VStack(spacing: 20) {
            // Spending Pie Chart
            if !spendingByCategory.isEmpty {
                InteractivePieChart(
                    spending: spendingByCategory,
                    selectedCategory: $selectedCategory,
                    onCategoryTap: {
                        showingCategoryDetail = true
                    }
                )
                .padding(.horizontal)
            }
            
            // Budget vs Actual Comparison
            if trip.totalBudget != nil {
                BudgetComparisonCard(trip: trip, budgetManager: budgetManager)
                    .padding(.horizontal)
            }
            
            // Recent Expenses
            RecentExpensesCard(trip: trip)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Categories Tab
    private var categoriesTab: some View {
        VStack(spacing: 16) {
            ForEach(budgetManager.categories, id: \.self) { category in
                CategoryProgressCard(
                    trip: trip,
                    category: category,
                    budgetManager: budgetManager,
                    onTap: {
                        selectedCategory = category
                        showingCategoryDetail = true
                    }
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Timeline Tab
    private var timelineTab: some View {
        VStack(spacing: 20) {
            // Daily Spending Chart
            DailySpendingChart(trip: trip, animate: animateCharts)
                .padding(.horizontal)
            
            // Cumulative Spending Chart
            CumulativeSpendingChart(trip: trip, animate: animateCharts)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Insights Tab
    private var insightsTab: some View {
        VStack(spacing: 16) {
            let insights = budgetManager.getInsights(for: trip)
            
            if insights.isEmpty {
                ContentUnavailableView(
                    "No Insights Yet",
                    systemImage: "lightbulb",
                    description: Text("Add more expenses to see spending insights")
                )
                .padding(.top, 40)
            } else {
                ForEach(insights) { insight in
                    InsightCard(insight: insight)
                }
            }
            
            // Spending Tips
            SpendingTipsCard()
        }
        .padding(.horizontal)
    }
    
    private func generateBudgetReport() -> String {
        var report = "Budget Report: \(trip.name)\n"
        report += "=====================================\n\n"
        
        if let budget = trip.totalBudget {
            report += "Total Budget: $\(String(format: "%.2f", budget))\n"
        }
        report += "Total Spent: $\(String(format: "%.2f", totalSpent))\n"
        
        if let budget = trip.totalBudget {
            let remaining = budget - totalSpent
            report += "Remaining: $\(String(format: "%.2f", remaining))\n"
        }
        
        report += "\nSpending by Category:\n"
        for (category, amount) in spendingByCategory.sorted(by: { $0.value > $1.value }) {
            report += "  • \(category): $\(String(format: "%.2f", amount))\n"
        }
        
        return report
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

// MARK: - Budget Hero Card
struct BudgetHeroCard: View {
    let trip: Trip
    @ObservedObject var budgetManager: BudgetManager
    @State private var animateGauge = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Status Badge
            HStack {
                let status = budgetManager.getBudgetStatus(for: trip)
                Image(systemName: status.icon)
                    .foregroundStyle(status.color)
                Text(status.message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(status.color)
                Spacer()
            }
            
            HStack(alignment: .top, spacing: 24) {
                // Gauge
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: animateGauge ? min(budgetManager.budgetProgress(for: trip), 1.0) : 0)
                        .stroke(
                            gaugeGradient,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: animateGauge)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(min(budgetManager.budgetProgress(for: trip) * 100, 150)))%")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("used")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Stats
                VStack(alignment: .leading, spacing: 12) {
                    StatRow(
                        label: "Budget",
                        value: trip.totalBudget != nil ? "$\(String(format: "%.0f", trip.totalBudget!))" : "Not set",
                        color: .primary
                    )
                    
                    StatRow(
                        label: "Spent",
                        value: "$\(String(format: "%.2f", budgetManager.calculateTotalSpent(for: trip)))",
                        color: budgetManager.isOverBudget(for: trip) ? .red : .primary
                    )
                    
                    StatRow(
                        label: "Remaining",
                        value: "$\(String(format: "%.2f", max(budgetManager.remainingBudget(for: trip), 0)))",
                        color: budgetManager.remainingBudget(for: trip) < 0 ? .red : .green
                    )
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animateGauge = true
            }
        }
    }
    
    private var gaugeGradient: AngularGradient {
        let progress = budgetManager.budgetProgress(for: trip)
        let colors: [Color] = progress > 1.0 ? [.red, .red] :
                              progress > 0.75 ? [.green, .yellow, .orange] :
                              [.green, .green]
        return AngularGradient(colors: colors, center: .center, startAngle: .degrees(-90), endAngle: .degrees(270))
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Quick Actions Bar
struct QuickActionsBar: View {
    @Binding var showingBudgetEditor: Bool
    @Binding var showingQuickExpense: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "plus.circle.fill",
                label: "Add Expense",
                color: .blue
            ) {
                showingQuickExpense = true
            }
            
            QuickActionButton(
                icon: "slider.horizontal.3",
                label: "Edit Budget",
                color: .orange
            ) {
                showingBudgetEditor = true
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(label)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Interactive Pie Chart
struct InteractivePieChart: View {
    let spending: [String: Double]
    @Binding var selectedCategory: String?
    let onCategoryTap: () -> Void
    @State private var animateChart = false
    
    private let budgetManager = BudgetManager.shared
    
    var sortedSpending: [(String, Double)] {
        spending.sorted { $0.value > $1.value }
    }
    
    var total: Double {
        spending.values.reduce(0, +)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Breakdown")
                .font(.headline)
            
            HStack(spacing: 24) {
                // Pie Chart
                ZStack {
                    ForEach(Array(sortedSpending.enumerated()), id: \.element.0) { index, item in
                        let (category, _) = item
                        let startAngle = startAngle(for: index)
                        let endAngle = endAngle(for: index)
                        
                        PieSlice(
                            startAngle: startAngle,
                            endAngle: animateChart ? endAngle : startAngle,
                            isSelected: selectedCategory == category
                        )
                        .fill(budgetManager.categoryColors[category] ?? .gray)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                if selectedCategory == category {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category
                                    onCategoryTap()
                                }
                            }
                        }
                    }
                    
                    // Center info
                    VStack(spacing: 2) {
                        if let selected = selectedCategory, let amount = spending[selected] {
                            Text(selected)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("$\(String(format: "%.0f", amount))")
                                .font(.title3)
                                .fontWeight(.bold)
                        } else {
                            Text("Total")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("$\(String(format: "%.0f", total))")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }
                }
                .frame(width: 150, height: 150)
                
                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(sortedSpending.prefix(5), id: \.0) { category, amount in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(budgetManager.categoryColors[category] ?? .gray)
                                .frame(width: 10, height: 10)
                            
                            Text(category)
                                .font(.caption)
                                .foregroundStyle(selectedCategory == category ? .primary : .secondary)
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.0f", amount))")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = category
                                onCategoryTap()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateChart = true
            }
        }
    }
    
    private func startAngle(for index: Int) -> Angle {
        let total = spending.values.reduce(0, +)
        var angle: Double = -90
        for i in 0..<index {
            let amount = sortedSpending[i].1
            angle += (amount / total) * 360
        }
        return .degrees(angle)
    }
    
    private func endAngle(for index: Int) -> Angle {
        let total = spending.values.reduce(0, +)
        var angle: Double = -90
        for i in 0...index {
            let amount = sortedSpending[i].1
            angle += (amount / total) * 360
        }
        return .degrees(angle)
    }
}

struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var isSelected: Bool
    
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.degrees, endAngle.degrees) }
        set {
            startAngle = .degrees(newValue.first)
            endAngle = .degrees(newValue.second)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * (isSelected ? 1.05 : 0.9)
        let innerRadius = radius * 0.5
        
        var path = Path()
        path.move(to: CGPoint(
            x: center.x + innerRadius * cos(CGFloat(startAngle.radians)),
            y: center.y + innerRadius * sin(CGFloat(startAngle.radians))
        ))
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Budget Comparison Card
struct BudgetComparisonCard: View {
    let trip: Trip
    @ObservedObject var budgetManager: BudgetManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget vs Actual")
                .font(.headline)
            
            Chart {
                if let budget = trip.totalBudget {
                    BarMark(
                        x: .value("Type", "Budget"),
                        y: .value("Amount", budget)
                    )
                    .foregroundStyle(.blue.opacity(0.6))
                    .cornerRadius(8)
                }
                
                BarMark(
                    x: .value("Type", "Actual"),
                    y: .value("Amount", budgetManager.calculateTotalSpent(for: trip))
                )
                .foregroundStyle(budgetManager.isOverBudget(for: trip) ? .red : .green)
                .cornerRadius(8)
                
                // Projected
                let projected = budgetManager.projectedTotal(for: trip)
                if projected > budgetManager.calculateTotalSpent(for: trip) {
                    BarMark(
                        x: .value("Type", "Projected"),
                        y: .value("Amount", projected)
                    )
                    .foregroundStyle(.orange.opacity(0.6))
                    .cornerRadius(8)
                }
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("$\(Int(amount))")
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Category Progress Card
struct CategoryProgressCard: View {
    let trip: Trip
    let category: String
    @ObservedObject var budgetManager: BudgetManager
    let onTap: () -> Void
    
    private var spent: Double {
        budgetManager.calculateSpentByCategory(for: trip)[category] ?? 0
    }
    
    private var budget: Double? {
        trip.budgetCategories[category]
    }
    
    private var progress: Double {
        budgetManager.categoryProgress(for: trip, category: category)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill((budgetManager.categoryColors[category] ?? .gray).opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: iconForCategory(category))
                        .font(.title3)
                        .foregroundStyle(budgetManager.categoryColors[category] ?? .gray)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(category)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let budget = budget {
                        Text("$\(String(format: "%.0f", spent)) / $\(String(format: "%.0f", budget))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("$\(String(format: "%.0f", spent))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Progress Ring
                if budget != nil {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                            .frame(width: 44, height: 44)
                        
                        Circle()
                            .trim(from: 0, to: min(progress, 1.0))
                            .stroke(
                                progress > 1.0 ? Color.red :
                                progress > 0.75 ? Color.orange : Color.green,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(min(progress * 100, 150)))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
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

// MARK: - Charts
struct DailySpendingChart: View {
    let trip: Trip
    let animate: Bool
    
    var dailySpending: [(day: Int, amount: Double)] {
        trip.safeDays.sorted(by: { $0.dayNumber < $1.dayNumber }).map { day in
            let amount = day.activities.compactMap { $0.estimatedCost }.reduce(0, +)
            return (day.dayNumber, amount)
        }
    }
    
    var averageDaily: Double {
        let total = dailySpending.map { $0.amount }.reduce(0, +)
        return total / Double(max(dailySpending.count, 1))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Daily Spending")
                    .font(.headline)
                Spacer()
                Text("Avg: $\(String(format: "%.0f", averageDaily))/day")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Chart {
                ForEach(dailySpending, id: \.day) { item in
                    BarMark(
                        x: .value("Day", "Day \(item.day)"),
                        y: .value("Spent", animate ? item.amount : 0)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                }
                
                // Average line
                RuleMark(y: .value("Average", averageDaily))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Average")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("$\(Int(amount))")
                                .font(.caption2)
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.8), value: animate)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

struct CumulativeSpendingChart: View {
    let trip: Trip
    let animate: Bool
    
    var cumulativeSpending: [(day: Int, amount: Double)] {
        var cumulative: Double = 0
        return trip.safeDays.sorted(by: { $0.dayNumber < $1.dayNumber }).map { day in
            let dayAmount = day.activities.compactMap { $0.estimatedCost }.reduce(0, +)
            cumulative += dayAmount
            return (day.dayNumber, cumulative)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Cumulative Spending")
                    .font(.headline)
                Spacer()
                if let budget = trip.totalBudget {
                    Text("Budget: $\(String(format: "%.0f", budget))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Chart {
                ForEach(cumulativeSpending, id: \.day) { item in
                    LineMark(
                        x: .value("Day", "Day \(item.day)"),
                        y: .value("Total", animate ? item.amount : 0)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Day", "Day \(item.day)"),
                        y: .value("Total", animate ? item.amount : 0)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                
                // Budget line
                if let budget = trip.totalBudget {
                    RuleMark(y: .value("Budget", budget))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Budget")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text("$\(Int(amount))")
                                .font(.caption2)
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.8), value: animate)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

struct RecentExpensesCard: View {
    let trip: Trip
    
    var recentExpenses: [(activity: Activity, dayNumber: Int)] {
        var expenses: [(Activity, Int)] = []
        for day in trip.safeDays {
            for activity in day.activities where activity.estimatedCost != nil {
                expenses.append((activity, day.dayNumber))
            }
        }
        return expenses.sorted { ($0.0.scheduledTime ?? Date.distantPast) > ($1.0.scheduledTime ?? Date.distantPast) }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Expenses")
                .font(.headline)
            
            if recentExpenses.isEmpty {
                Text("No expenses recorded yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(recentExpenses, id: \.activity.id) { item in
                    HStack {
                        Image(systemName: iconForCategory(item.activity.costCategory ?? "Other"))
                            .foregroundStyle(colorForCategory(item.activity.costCategory ?? "Other"))
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.activity.name)
                                .font(.subheadline)
                                .lineLimit(1)
                            Text("Day \(item.dayNumber)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if let cost = item.activity.estimatedCost {
                            Text("$\(String(format: "%.2f", cost))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if item.activity.id != recentExpenses.last?.activity.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
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
    
    func colorForCategory(_ category: String) -> Color {
        BudgetManager.shared.categoryColors[category] ?? .gray
    }
}

struct InsightCard: View {
    let insight: BudgetInsight
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: insight.icon)
                .font(.title2)
                .foregroundStyle(insight.type.color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(insight.type.color.opacity(0.1))
        )
    }
}

struct SpendingTipsCard: View {
    let tips = [
        "💡 Set daily spending limits to stay on track",
        "🎫 Look for combo tickets at attractions",
        "🍽️ Try local markets for affordable meals",
        "⛽ Use gas station apps for discounts",
        "🏨 Book accommodations with free cancellation"
    ]
    
    @State private var currentTipIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("💰 Budget Tips")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation {
                        currentTipIndex = (currentTipIndex + 1) % tips.count
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
            }
            
            Text(tips[currentTipIndex])
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
                .id(currentTipIndex)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.yellow.opacity(0.1))
        )
    }
}

// MARK: - Quick Expense View
struct QuickExpenseView: View {
    @Bindable var trip: Trip
    @Environment(\.dismiss) private var dismiss
    
    @State private var expenseName = ""
    @State private var expenseAmount = ""
    @State private var selectedCategory = "Other"
    @State private var selectedDayId: UUID?
    @State private var notes = ""
    
    let categories = BudgetManager.shared.categories
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Expense Details") {
                    TextField("What did you spend on?", text: $expenseName)
                    
                    HStack {
                        Text("$")
                        TextField("0.00", text: $expenseAmount)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Category") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Day") {
                    Picker("Select Day", selection: $selectedDayId) {
                        Text("Select a day").tag(nil as UUID?)
                        ForEach(trip.safeDays.sorted { $0.dayNumber < $1.dayNumber }) { day in
                            Text("Day \(day.dayNumber)").tag(day.id as UUID?)
                        }
                    }
                }
                
                Section("Notes (Optional)") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addExpense()
                        dismiss()
                    }
                    .disabled(expenseName.isEmpty || expenseAmount.isEmpty || selectedDayId == nil)
                }
            }
            .onAppear {
                // Default to today's day or first day
                let today = Date()
                selectedDayId = trip.safeDays.first { Calendar.current.isDate($0.date, inSameDayAs: today) }?.id
                    ?? trip.safeDays.sorted { $0.dayNumber < $1.dayNumber }.first?.id
            }
        }
    }
    
    private func addExpense() {
        guard let dayId = selectedDayId,
              let day = trip.safeDays.first(where: { $0.id == dayId }),
              let amount = Double(expenseAmount) else { return }
        
        let activity = Activity(name: expenseName, location: "", category: "Other")
        activity.estimatedCost = amount
        activity.costCategory = selectedCategory
        activity.notes = notes.isEmpty ? nil : notes
        activity.scheduledTime = Date()
        activity.order = day.activities.count
        
        day.activities.append(activity)
    }
}

struct CategoryChip: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconForCategory(category))
                    .font(.caption)
                Text(category)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? (BudgetManager.shared.categoryColors[category] ?? .gray) : Color.gray.opacity(0.2))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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

// MARK: - Category Detail View
struct CategoryDetailView: View {
    let trip: Trip
    let category: String
    @Environment(\.dismiss) private var dismiss
    
    private let budgetManager = BudgetManager.shared
    
    var categoryExpenses: [(activity: Activity, dayNumber: Int)] {
        var expenses: [(Activity, Int)] = []
        for day in trip.safeDays {
            for activity in day.activities where activity.costCategory == category {
                expenses.append((activity, day.dayNumber))
            }
        }
        return expenses.sorted { $0.1 < $1.1 }
    }
    
    var totalSpent: Double {
        categoryExpenses.compactMap { $0.activity.estimatedCost }.reduce(0, +)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Summary Section
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Spent")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("$\(String(format: "%.2f", totalSpent))")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        if let budget = trip.budgetCategories[category] {
                            VStack(alignment: .trailing) {
                                Text("Budget")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("$\(String(format: "%.2f", budget))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if let budget = trip.budgetCategories[category] {
                        let progress = totalSpent / budget
                        ProgressView(value: min(progress, 1.0))
                            .tint(progress > 1.0 ? .red : progress > 0.75 ? .orange : .green)
                    }
                }
                
                // Expenses List
                Section("Expenses") {
                    if categoryExpenses.isEmpty {
                        Text("No expenses in this category")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(categoryExpenses, id: \.activity.id) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.activity.name)
                                        .font(.subheadline)
                                    Text("Day \(item.dayNumber)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if let cost = item.activity.estimatedCost {
                                    Text("$\(String(format: "%.2f", cost))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(category)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}


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
