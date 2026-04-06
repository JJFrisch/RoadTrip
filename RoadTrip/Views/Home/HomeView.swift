// Views/Home/HomeView.swift
import SwiftUI
import SwiftData


struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    // AuthService disabled; account button shows generic icon
    @StateObject private var tripsViewModel = TripsViewModel()
    @StateObject private var searchManager = TripSearchManager()
    @StateObject private var onboardingManager = OnboardingManager.shared

    @State private var showingNewTripSheet = false
    @State private var tripToDelete: Trip?
    @State private var tripToEdit: Trip?
    @State private var showingSampleTripAlert = false
    @State private var showingAccount = false
    @State private var showingOnboarding = false
    @State private var showingTutorial = false
    @State private var showingFilters = false

    var filteredTrips: [Trip] {
        searchManager.filterAndSort(tripsViewModel.trips)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.97, blue: 0.96)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("My Trips")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                
                                Text("Plan your next adventure")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "airplane.departure")
                                .font(.system(size: 24))
                                .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.0))
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.29, green: 0.62, blue: 0.85),
                                Color(red: 0.20, green: 0.52, blue: 0.75)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    
                    // Search and content
                    ZStack {
                        if tripsViewModel.trips.isEmpty {
                            emptyStateView
                        } else {
                            tripListView
                        }
                    }
                    .searchable(text: $searchManager.searchText, prompt: "Search trips...")
                    .background(Color(red: 0.98, green: 0.97, blue: 0.96))
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingAccount = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title3)
                            .foregroundStyle(Color(red: 0.29, green: 0.62, blue: 0.85))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showingFilters = true
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title3)
                                .foregroundStyle(Color(red: 0.29, green: 0.62, blue: 0.85))
                                .symbolVariant(searchManager.sortOption != .dateNewest ? .fill : .none)
                        }

                        Button {
                            showingNewTripSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.29, green: 0.62, blue: 0.85),
                                            Color(red: 1.0, green: 0.78, blue: 0.0)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                }
            }
            .onAppear {
                tripsViewModel.configure(with: modelContext)
                tripsViewModel.loadTrips()
                Task {
                    await tripsViewModel.syncTripsIfNeeded()
                }
                if onboardingManager.shouldShowOnboarding {
                    showingOnboarding = true
                }
            }
            .sheet(isPresented: $showingNewTripSheet, onDismiss: {
                tripsViewModel.loadTrips()
            }) {
                NewTripView()
            }
            .sheet(isPresented: $showingAccount) {
                AccountView()
            }
            
            .sheet(item: $tripToEdit) { trip in
                EditTripView(trip: trip)
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
                            colors: [
                                Color(red: 0.29, green: 0.62, blue: 0.85).opacity(0.15),
                                Color(red: 1.0, green: 0.78, blue: 0.0).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 180, height: 180)

                    Image(systemName: "car.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(LinearGradient(
                            colors: [
                                Color(red: 0.29, green: 0.62, blue: 0.85),
                                Color(red: 1.0, green: 0.78, blue: 0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))

                    Image(systemName: "road.lanes")
                        .font(.system(size: 30))
                        .foregroundStyle(Color(red: 0.29, green: 0.62, blue: 0.85).opacity(0.4))
                        .offset(x: 50, y: 50)

                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.0))
                        .offset(x: -60, y: -40)
                }
                .padding(.top, 40)

                VStack(spacing: 12) {
                    Text("No Trips Yet")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))

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
                            .background(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.29, green: 0.62, blue: 0.85),
                                    Color(red: 0.20, green: 0.52, blue: 0.75)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button {
                        showingTutorial = true
                    } label: {
                        Label("Quick Tutorial", systemImage: "book.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 1.0, green: 0.78, blue: 0.0).opacity(0.15))
                            .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.0))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(red: 1.0, green: 0.78, blue: 0.0).opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 32)

                VStack(alignment: .leading, spacing: 16) {
                    Text("What you can do")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    FeatureRow(icon: "calendar.badge.clock", title: "Plan Activities", description: "Schedule attractions, meals, and hotels")
                    FeatureRow(icon: "map.fill", title: "Visualize Routes", description: "See your entire trip on an interactive map")
                    FeatureRow(icon: "dollarsign.circle.fill", title: "Track Budget", description: "Monitor expenses by category")
                    FeatureRow(icon: "bell.badge.fill", title: "Get Reminders", description: "Never miss an activity with notifications")
                }
                .padding()
                .background(Color(red: 0.98, green: 0.97, blue: 0.96))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
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
        tripsViewModel.deleteTrip(trip)
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
                .foregroundStyle(Color(red: 0.29, green: 0.62, blue: 0.85))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

// Trip Card Component
struct TripCardView: View {
    let trip: Trip
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with gradient background
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        
                        Text("\(trip.numberOfNights) night\(trip.numberOfNights == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Image(systemName: trip.coverImage ?? "car.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.0))
                }
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.29, green: 0.62, blue: 0.85),
                        Color(red: 0.20, green: 0.52, blue: 0.75)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Content section
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(trip.startDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("End")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(trip.endDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                    }
                }
                
                Divider()
                    .overlay(Color(red: 0.29, green: 0.62, blue: 0.85).opacity(0.2))
                
                if trip.totalDistance > 0 {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.0))
                                
                                Text("Distance")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(String(format: "%.0f mi", trip.totalDistance))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                    .foregroundStyle(Color(red: 0.29, green: 0.62, blue: 0.85))
                                
                                Text("Days")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text("\(trip.days.count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: Color(red: 0.29, green: 0.62, blue: 0.85).opacity(isHovered ? 0.3 : 0.12),
            radius: isHovered ? 12 : 8,
            x: 0,
            y: isHovered ? 8 : 4
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
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
