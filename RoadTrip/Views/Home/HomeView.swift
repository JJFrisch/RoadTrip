// Views/Home/HomeView.swift
import SwiftUI
import SwiftData


struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @State private var showingNewTripSheet = false
    @State private var tripToDelete: Trip?
    @State private var showingSampleTripAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if trips.isEmpty {
                    emptyStateView
                } else {
                    tripListView
                }
            }
            .navigationTitle("My Trips")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewTripSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingNewTripSheet) {
                NewTripView()
            }
            .alert("Delete Trip", isPresented: .constant(tripToDelete != nil), presenting: tripToDelete) { trip in
                Button(role: .destructive) {
                    deleteTrip(trip)
                    tripToDelete = nil
                } label: {
                    Text("Delete")
                }
                Button(role: .cancel) {
                    tripToDelete = nil
                } label: {
                    Text("Cancel")
                }
            } message: { trip in
                Text("Are you sure you want to delete \"\(trip.name)\"? This action cannot be undone.")
            }
            .alert("Create Sample Trip", isPresented: $showingSampleTripAlert) {
                Button("Create") {
                    createSampleTrip()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will create a sample California Coast road trip to help you explore the app's features.")
            }
        }
    }
    
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Illustration
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 180, height: 180)
                    
                    Image(systemName: "car.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    // Road decoration
                    Image(systemName: "road.lanes")
                        .font(.system(size: 30))
                        .foregroundStyle(.blue.opacity(0.5))
                        .offset(x: 50, y: 50)
                    
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.red)
                        .offset(x: -60, y: -40)
                }
                .padding(.top, 40)
                
                VStack(spacing: 12) {
                    Text("No Trips Yet")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Start planning your next adventure!\nCreate a trip to organize your itinerary,\ntrack activities, and navigate with ease.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                VStack(spacing: 16) {
                    Button {
                        showingNewTripSheet = true
                    } label: {
                        Label("Create Your First Trip", systemImage: "plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    Button {
                        showingSampleTripAlert = true
                    } label: {
                        Label("Explore Sample Trip", systemImage: "sparkles")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 32)
                
                // Features overview
                VStack(alignment: .leading, spacing: 16) {
                    Text("What you can do")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    FeatureRow(icon: "calendar.badge.clock", title: "Plan Activities", description: "Schedule attractions, meals, and hotels")
                    FeatureRow(icon: "map.fill", title: "Visualize Routes", description: "See your entire trip on an interactive map")
                    FeatureRow(icon: "dollarsign.circle.fill", title: "Track Budget", description: "Monitor expenses by category")
                    FeatureRow(icon: "bell.badge.fill", title: "Get Reminders", description: "Never miss an activity with notifications")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
            .constrainedContentWidth()
        }
    }
    
    private func createSampleTrip() {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: 7, to: Date())!
        let endDate = calendar.date(byAdding: .day, value: 4, to: startDate)!
        
        let trip = Trip(name: "California Coast Adventure", startDate: startDate, endDate: endDate)
        trip.coverImage = "car.fill"
        
        // Configure days with sample data
        let days = trip.days.sorted(by: { $0.dayNumber < $1.dayNumber })
        
        if days.count > 0 {
            days[0].startLocation = "San Francisco, CA"
            days[0].endLocation = "Monterey, CA"
            days[0].distance = 120
            days[0].drivingTime = 2.5
            
            // Add sample activities
            let activity1 = Activity(name: "Golden Gate Bridge", location: "Golden Gate Bridge, San Francisco", category: "Attraction")
            activity1.scheduledTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: startDate)
            activity1.duration = 1.5
            activity1.estimatedCost = 0
            activity1.costCategory = "Attractions"
            activity1.order = 0
            days[0].activities.append(activity1)
            
            let activity2 = Activity(name: "Fisherman's Wharf Lunch", location: "Fisherman's Wharf, San Francisco", category: "Food")
            activity2.scheduledTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: startDate)
            activity2.duration = 1.0
            activity2.estimatedCost = 45
            activity2.costCategory = "Food"
            activity2.order = 1
            days[0].activities.append(activity2)
        }
        
        if days.count > 1 {
            days[1].startLocation = "Monterey, CA"
            days[1].endLocation = "Big Sur, CA"
            days[1].distance = 45
            days[1].drivingTime = 1.5
            
            let activity3 = Activity(name: "Monterey Bay Aquarium", location: "886 Cannery Row, Monterey", category: "Attraction")
            activity3.scheduledTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 1, to: startDate)!)
            activity3.duration = 3.0
            activity3.estimatedCost = 55
            activity3.costCategory = "Attractions"
            activity3.order = 0
            days[1].activities.append(activity3)
        }
        
        if days.count > 2 {
            days[2].startLocation = "Big Sur, CA"
            days[2].endLocation = "San Luis Obispo, CA"
            days[2].distance = 95
            days[2].drivingTime = 2.0
        }
        
        modelContext.insert(trip)
    }
    
    private var tripListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(trips) { trip in
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        TripCardView(trip: trip)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            tripToDelete = trip
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
            .constrainedContentWidth()
        }
    }
    
    private func deleteTrip(_ trip: Trip) {
        modelContext.delete(trip)
    }
}

// MARK: - Feature Row for Empty State
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// Trip Card Component
struct TripCardView: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    Text("\(trip.numberOfNights) night\(trip.numberOfNights == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: trip.coverImage ?? "car.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue.gradient)
            }
            
            Divider()
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(trip.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("End")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(trip.endDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            
            if trip.totalDistance > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                    
                    Text(String(format: "%.0f miles", trip.totalDistance))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    
                    Text("\(trip.days.count) day\(trip.days.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// Simple New Trip Form
struct NewTripView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var tripName = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 3) // 3 days later
    @State private var showValidationError = false
    @State private var validationError = ""
    
    var isFormValid: Bool {
        !tripName.trimmingCharacters(in: .whitespaces).isEmpty && endDate >= startDate
    }
    
    var validationErrorMessage: String? {
        if tripName.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Trip name cannot be empty"
        }
        if endDate < startDate {
            return "End date must be after or equal to start date"
        }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    TextField("Trip Name", text: $tripName)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                if let error = validationErrorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTrip()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func createTrip() {
        let newTrip = Trip(name: tripName.trimmingCharacters(in: .whitespaces), startDate: startDate, endDate: endDate)
        modelContext.insert(newTrip)
        dismiss()
    }
}
