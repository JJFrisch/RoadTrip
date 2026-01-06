//
//  OnboardingView.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import SwiftUI
import SwiftData

// MARK: - Onboarding Manager
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("onboardingVersion") var onboardingVersion = 0
    
    private init() {}
    
    static let currentVersion = 1
    
    var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding || onboardingVersion < OnboardingManager.currentVersion
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        onboardingVersion = OnboardingManager.currentVersion
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    let onComplete: () -> Void
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "car.fill",
            title: "Welcome to RoadTrip",
            description: "Plan unforgettable journeys with ease.\nOrganize activities, track routes,\nand collaborate with travel companions.",
            color: .blue
        ),
        OnboardingPage(
            icon: "calendar.badge.plus",
            title: "Plan Your Days",
            description: "Create multi-day trips and add activities.\nSchedule attractions, meals, and hotels\nwith smart time suggestions.",
            color: .orange
        ),
        OnboardingPage(
            icon: "square.and.arrow.down.on.square",
            title: "Import Activities",
            description: "Discover nearby places automatically\nor import from your favorite sites.\nSave time with bulk imports.",
            color: .green
        ),
        OnboardingPage(
            icon: "map.fill",
            title: "Visualize Your Route",
            description: "See all your stops on an interactive map.\nCalculate driving times and distances.\nDownload maps for offline use.",
            color: .purple
        ),
        OnboardingPage(
            icon: "person.2.fill",
            title: "Collaborate & Share",
            description: "Share trips with friends and family.\nSync across devices with iCloud.\nPlan together in real-time.",
            color: .pink
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Page Indicator
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 40)
            
            // Content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Bottom Buttons
            HStack(spacing: 16) {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        OnboardingManager.shared.completeOnboarding()
                        onComplete()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [page.color.opacity(0.2), page.color.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                
                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(page.color.gradient)
            }
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Quick Tutorial View
struct QuickTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    
    private let steps: [TutorialStep] = [
        TutorialStep(
            title: "Create a Trip",
            description: "Tap the + button to create your first trip. Add a name and select your travel dates.",
            icon: "plus.circle.fill",
            color: .blue
        ),
        TutorialStep(
            title: "Add Activities",
            description: "For each day, add activities manually or import nearby places automatically.",
            icon: "calendar.badge.plus",
            color: .orange
        ),
        TutorialStep(
            title: "Set Times & Costs",
            description: "Schedule when activities happen and track estimated costs for budgeting.",
            icon: "clock.fill",
            color: .green
        ),
        TutorialStep(
            title: "View on Map",
            description: "See all your activities on an interactive map with routes and distances.",
            icon: "map.fill",
            color: .purple
        )
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Progress
                ProgressView(value: Double(currentStep + 1), total: Double(steps.count))
                    .padding(.horizontal)
                
                // Current Step
                TutorialStepView(step: steps[currentStep])
                
                Spacer()
                
                // Navigation
                HStack {
                    if currentStep > 0 {
                        Button("Previous") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    if currentStep < steps.count - 1 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .padding()
            .navigationTitle("Quick Tutorial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TutorialStep {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct TutorialStepView: View {
    let step: TutorialStep
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(step.color.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Image(systemName: step.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(step.color.gradient)
            }
            
            VStack(spacing: 12) {
                Text(step.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(step.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
        }
    }
}

// MARK: - Sample Trip Creator
extension HomeView {
    func createComprehensiveSampleTrip() {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: 7, to: Date())!
        let endDate = calendar.date(byAdding: .day, value: 6, to: startDate)!
        
        let trip = Trip(name: "Pacific Coast Highway Adventure", startDate: startDate, endDate: endDate)
        trip.tripDescription = "Explore the stunning California coastline from San Francisco to San Diego"
        trip.coverImage = "car.fill"
        
        let days = trip.days.sorted(by: { $0.dayNumber < $1.dayNumber })
        
        // Day 1: San Francisco
        if days.count > 0 {
            setupDay1(days[0], startDate: startDate, calendar: calendar)
        }
        
        // Day 2: SF to Monterey
        if days.count > 1 {
            setupDay2(days[1], startDate: startDate, calendar: calendar)
        }
        
        // Day 3: Monterey to Big Sur
        if days.count > 2 {
            setupDay3(days[2], startDate: startDate, calendar: calendar)
        }
        
        // Day 4: Big Sur to San Luis Obispo
        if days.count > 3 {
            setupDay4(days[3], startDate: startDate, calendar: calendar)
        }
        
        // Day 5: SLO to Santa Barbara
        if days.count > 4 {
            setupDay5(days[4], startDate: startDate, calendar: calendar)
        }
        
        // Day 6: Santa Barbara to LA
        if days.count > 5 {
            setupDay6(days[5], startDate: startDate, calendar: calendar)
        }
        
        // Day 7: LA to San Diego
        if days.count > 6 {
            setupDay7(days[6], startDate: startDate, calendar: calendar)
        }
        
        modelContext.insert(trip)
        ToastManager.shared.show("Sample trip created!", type: .success)
    }
    
    private func setupDay1(_ day: TripDay, startDate: Date, calendar: Calendar) {
        day.startLocation = "San Francisco Airport"
        day.endLocation = "Downtown San Francisco"
        day.distance = 15
        day.drivingTime = 0.5
        
        addActivity(to: day, name: "Pick up rental car", location: "SFO Airport", category: "Other", hour: 10, minute: 0, duration: 0.5, cost: 250, costCat: "Other", date: startDate, calendar: calendar, order: 0)
        addActivity(to: day, name: "Golden Gate Bridge", location: "Golden Gate Bridge, SF", category: "Attraction", hour: 12, minute: 0, duration: 2, cost: 0, costCat: "Attractions", date: startDate, calendar: calendar, order: 1)
        addActivity(to: day, name: "Fisherman's Wharf Lunch", location: "Fisherman's Wharf", category: "Food", hour: 14, minute: 30, duration: 1.5, cost: 60, costCat: "Food", date: startDate, calendar: calendar, order: 2)
        addActivity(to: day, name: "Hotel Check-in", location: "Union Square Hotel", category: "Hotel", hour: 18, minute: 0, duration: 0.5, cost: 200, costCat: "Lodging", date: startDate, calendar: calendar, order: 3)
    }
    
    private func setupDay2(_ day: TripDay, startDate: Date, calendar: Calendar) {
        day.startLocation = "San Francisco"
        day.endLocation = "Monterey"
        day.distance = 120
        day.drivingTime = 2.5
        
        let dayDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        addActivity(to: day, name: "Drive to Monterey", location: "Highway 1", category: "Other", hour: 9, minute: 0, duration: 2.5, cost: 30, costCat: "Gas", date: dayDate, calendar: calendar, order: 0)
        addActivity(to: day, name: "Monterey Bay Aquarium", location: "886 Cannery Row", category: "Attraction", hour: 12, minute: 0, duration: 3, cost: 55, costCat: "Attractions", date: dayDate, calendar: calendar, order: 1)
        addActivity(to: day, name: "Cannery Row Dinner", location: "Cannery Row", category: "Food", hour: 18, minute: 0, duration: 1.5, cost: 75, costCat: "Food", date: dayDate, calendar: calendar, order: 2)
    }
    
    private func setupDay3(_ day: TripDay, startDate: Date, calendar: Calendar) {
        day.startLocation = "Monterey"
        day.endLocation = "Big Sur"
        day.distance = 45
        day.drivingTime = 1.5
        
        let dayDate = calendar.date(byAdding: .day, value: 2, to: startDate)!
        addActivity(to: day, name: "Bixby Bridge Photo Stop", location: "Bixby Bridge", category: "Attraction", hour: 11, minute: 0, duration: 0.5, cost: 0, costCat: "Attractions", date: dayDate, calendar: calendar, order: 0)
        addActivity(to: day, name: "McWay Falls Hike", location: "Julia Pfeiffer Burns SP", category: "Attraction", hour: 13, minute: 0, duration: 1.5, cost: 10, costCat: "Attractions", date: dayDate, calendar: calendar, order: 1)
        addActivity(to: day, name: "Nepenthe Restaurant", location: "48510 Highway 1", category: "Food", hour: 17, minute: 0, duration: 2, cost: 90, costCat: "Food", date: dayDate, calendar: calendar, order: 2)
    }
    
    private func setupDay4(_ day: TripDay, startDate: Date, calendar: Calendar) {
        day.startLocation = "Big Sur"
        day.endLocation = "San Luis Obispo"
        day.distance = 95
        day.drivingTime = 2
    }
    
    private func setupDay5(_ day: TripDay, startDate: Date, calendar: Calendar) {
        day.startLocation = "San Luis Obispo"
        day.endLocation = "Santa Barbara"
        day.distance = 100
        day.drivingTime = 2
    }
    
    private func setupDay6(_ day: TripDay, startDate: Date, calendar: Calendar) {
        day.startLocation = "Santa Barbara"
        day.endLocation = "Los Angeles"
        day.distance = 95
        day.drivingTime = 2
    }
    
    private func setupDay7(_ day: TripDay, startDate: Date, calendar: Calendar) {
        day.startLocation = "Los Angeles"
        day.endLocation = "San Diego"
        day.distance = 120
        day.drivingTime = 2.5
    }
    
    private func addActivity(to day: TripDay, name: String, location: String, category: String, hour: Int, minute: Int, duration: Double, cost: Double, costCat: String, date: Date, calendar: Calendar, order: Int) {
        let activity = Activity(name: name, location: location, category: category)
        activity.scheduledTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)
        activity.duration = duration
        activity.estimatedCost = cost
        activity.costCategory = costCat
        activity.order = order
        day.activities.append(activity)
    }
}
