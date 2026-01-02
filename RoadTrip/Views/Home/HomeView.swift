// Views/Home/HomeView.swift
import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @State private var showingNewTripSheet = false
    
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
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            Text("No Trips Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start planning your next adventure")
                .foregroundStyle(.secondary)
            
            Button {
                showingNewTripSheet = true
            } label: {
                Label("Create Trip", systemImage: "plus")
                    .font(.headline)
                    .padding()
                    .background(.blue.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top)
        }
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
                            deleteTrip(trip)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func deleteTrip(_ trip: Trip) {
        modelContext.delete(trip)
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
                    
                    Text("\(trip.numberOfNights) nights")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: trip.coverImage ?? "car.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue.gradient)
            }
            
            Divider()
            
            HStack {
                Label("\(trip.startDate.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                Spacer()
                Label("\(Int(trip.totalDistance)) mi", systemImage: "location.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}

// Simple New Trip Form
struct NewTripView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var tripName = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 3) // 3 days later
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    TextField("Trip Name", text: $tripName)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
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
                    .disabled(tripName.isEmpty)
                }
            }
        }
    }
    
    private func createTrip() {
        let newTrip = Trip(name: tripName, startDate: startDate, endDate: endDate)
        modelContext.insert(newTrip)
        dismiss()
    }
}
