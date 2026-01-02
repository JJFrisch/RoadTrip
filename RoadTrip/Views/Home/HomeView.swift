// Views/Home/HomeView.swift
import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @State private var showingNewTripSheet = false
    @State private var tripToDelete: Trip?
    
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
                            tripToDelete = trip
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
