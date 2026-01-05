// Views/Home/HomeView.swift
import SwiftUI
import SwiftData


struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @StateObject private var authService = AuthService.shared
    @StateObject private var searchManager = TripSearchManager()
    @StateObject private var onboardingManager = OnboardingManager.shared

    @State private var showingNewTripSheet = false
    @State private var tripToDelete: Trip?
    @State private var tripToEdit: Trip?
    @State private var tripToShare: Trip?
    @State private var showingSampleTripAlert = false
    @State private var showingAccount = false
    @State private var showingJoinTrip = false
    @State private var showingOnboarding = false
    @State private var showingTutorial = false
    @State private var showingFilters = false

    var filteredTrips: [Trip] {
        searchManager.filterAndSort(Array(trips))
    }

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
            .searchable(text: $searchManager.searchText, prompt: "Search trips...")
            .onAppear {
                if onboardingManager.shouldShowOnboarding {
                    showingOnboarding = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingAccount = true
                    } label: {
                        if authService.isLoggedIn, let user = authService.currentUser {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 32, height: 32)
                                Text(user.displayName.prefix(1).uppercased())
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                        } else {
                            Image(systemName: "person.circle")
                                .font(.title3)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showingFilters = true
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title3)
                                .symbolVariant(searchManager.sortOption != .dateNewest || searchManager.filterByShared != .all ? .fill : .none)
                        }

                        Button {
                            showingJoinTrip = true
                        } label: {
                            Image(systemName: "person.badge.plus")
                                .font(.title3)
                        }

                        Button {
                            showingNewTripSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewTripSheet) {
                NewTripView()
            }
            .sheet(isPresented: $showingAccount) {
                AccountView()
            }
            .sheet(isPresented: $showingJoinTrip) {
                JoinTripView()
            }
            .sheet(item: $tripToEdit) { trip in
                EditTripView(trip: trip)
            }
            .sheet(item: $tripToShare) { trip in
                TripSharingView(trip: trip)
            }
            .alert("Delete Trip", isPresented: .constant(tripToDelete != nil), presenting: tripToDelete) { trip in
                Button(role: .destructive) {
                    deleteTrip(trip)
                    tripToDelete = nil
                } label: {
                    Text("Delete")
                }
            }
            .alert("Create Sample Trip", isPresented: $showingSampleTripAlert) {
                Button("Create") {
                    createComprehensiveSampleTrip(modelContext: modelContext)
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will create a sample California Coast road trip to help you explore the app's features.")
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView {
                    // Optional: show tutorial after onboarding
                }
            }
            .sheet(isPresented: $showingTutorial) {
                QuickTutorialView()
            }
            .sheet(isPresented: $showingFilters) {
                FilterSortSheet(searchManager: searchManager)
            }
            .withToast()
            .withErrorDialog()
        }
    }
    
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 32) {
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

                    Button {
                        showingTutorial = true
                    } label: {
                        Label("Quick Tutorial", systemImage: "book.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.purple.opacity(0.1))
                            .foregroundStyle(.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 32)

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

    private var tripListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if filteredTrips.isEmpty && !searchManager.searchText.isEmpty {
                    NoSearchResultsView(searchText: searchManager.searchText) {
                        searchManager.searchText = ""
                    }
                    .padding(.top, 100)
                }

                ForEach(filteredTrips) { trip in
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        TripCardView(trip: trip)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            tripToEdit = trip
                        } label: {
                            Label("Edit Trip", systemImage: "pencil")
                        }

                        Button {
                            tripToShare = trip
                        } label: {
                            Label("Share Trip", systemImage: "square.and.arrow.up")
                        }

                        Divider()

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
                    HStack(spacing: 6) {
                        Text(trip.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        
                        if trip.isShared {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    
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
                    
                    Text("\(trip.safeDays.count) day\(trip.safeDays.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            
            // Show collaborators indicator
            if trip.isShared && !trip.sharedWith.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text("\(trip.sharedWith.count + 1) collaborator\(trip.sharedWith.count == 0 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
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
    @State private var tripDescription = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 3) // 3 days later
    @State private var coverImage = ""
    
    var isFormValid: Bool {
        !tripName.trimmingCharacters(in: .whitespaces).isEmpty && endDate >= startDate
    }
    
    var newDayCount: Int {
        max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day! + 1)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    TextField("Trip Name", text: $tripName)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $tripDescription)
                            .frame(minHeight: 60)
                    }
                }
                
                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    
                    // Days preview
                    HStack {
                        Label("Duration", systemImage: "calendar")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(newDayCount) day\(newDayCount == 1 ? "" : "s")")
                            .fontWeight(.medium)
                        if newDayCount > 1 {
                            Text("(\(newDayCount - 1) night\(newDayCount - 1 == 1 ? "" : "s"))")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Dates")
                } footer: {
                    if endDate < startDate {
                        Text("End date must be after or equal to start date")
                            .foregroundStyle(.red)
                    }
                }
                
                Section("Appearance") {
                    HStack {
                        Text("Cover Icon")
                        Spacer()
                        TextField("SF Symbol name", text: $coverImage)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.never)
                    }
                    
                    if !coverImage.isEmpty {
                        HStack {
                            Spacer()
                            Image(systemName: coverImage)
                                .font(.system(size: 50))
                                .foregroundStyle(.blue.gradient)
                                .symbolRenderingMode(.hierarchical)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Icon suggestions
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(["car.fill", "airplane", "bicycle", "figure.hiking", "tent.fill", "beach.umbrella.fill", "mountain.2.fill", "building.2.fill"], id: \.self) { icon in
                                Button {
                                    coverImage = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundStyle(coverImage == icon ? .white : .blue)
                                        .frame(width: 44, height: 44)
                                        .background(coverImage == icon ? Color.blue : Color.blue.opacity(0.1))
                                        .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
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
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func createTrip() {
        let newTrip = Trip(name: tripName.trimmingCharacters(in: .whitespaces), startDate: startDate, endDate: endDate)
        newTrip.tripDescription = tripDescription.trimmingCharacters(in: .whitespaces).isEmpty ? nil : tripDescription
        newTrip.coverImage = coverImage.isEmpty ? nil : coverImage
        modelContext.insert(newTrip)
        dismiss()
    }
}
