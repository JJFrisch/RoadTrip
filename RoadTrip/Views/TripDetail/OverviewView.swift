// Views/TripDetail/OverviewView.swift
import SwiftUI
import SwiftData

struct OverviewView: View {
    @Environment(\.modelContext) private var modelContext
    let trip: Trip
    @State private var showingAddDay = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack(spacing: 0) {
                headerCell("Day", width: 50)
                headerCell("Start", width: nil)
                headerCell("End", width: nil)
                headerCell("Distance", width: 80)
                headerCell("Hotel", width: 100)
            }
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Data Rows
            if trip.days.isEmpty {
                emptyDaysView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(trip.days.sorted(by: { $0.dayNumber < $1.dayNumber })) { day in
                            dayRow(day)
                            Divider()
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddDay = true
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddDay) {
            AddDayView(trip: trip)
        }
    }
    
    private func headerCell(_ title: String, width: CGFloat?) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .frame(maxWidth: width == nil ? .infinity : width, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
    }
    
    private func dayRow(_ day: TripDay) -> some View {
        HStack(spacing: 0) {
            dataCell("\(day.dayNumber)", width: 50)
            dataCell(day.startLocation, width: nil)
            dataCell(day.endLocation, width: nil)
            dataCell("\(Int(day.distance)) mi", width: 80)
            dataCell(day.hotelName ?? "-", width: 100)
        }
        .frame(height: 44)
        .contextMenu {
            Button(role: .destructive) {
                deleteDay(day)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func dataCell(_ text: String, width: CGFloat?) -> some View {
        Text(text)
            .font(.subheadline)
            .lineLimit(1)
            .frame(maxWidth: width == nil ? .infinity : width, alignment: .leading)
            .padding(.horizontal, 8)
    }
    
    private var emptyDaysView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            Text("No days added yet")
                .foregroundStyle(.secondary)
            Button("Add First Day") {
                showingAddDay = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func deleteDay(_ day: TripDay) {
        modelContext.delete(day)
    }
}

// Simple Add Day Form
struct AddDayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let trip: Trip
    
    @State private var startLocation = ""
    @State private var endLocation = ""
    @State private var hotelName = ""
    @State private var distance: Double = 0
    @State private var drivingTime: Double = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Locations") {
                    TextField("Start Location", text: $startLocation)
                        .textInputAutocapitalization(.words)
                    TextField("End Location", text: $endLocation)
                        .textInputAutocapitalization(.words)
                }
                
                Section("Route Details") {
                    HStack {
                        Text("Distance (miles)")
                        Spacer()
                        TextField("0", value: $distance, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Driving Time (hours)")
                        Spacer()
                        TextField("0", value: $drivingTime, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                
                Section("Accommodation") {
                    TextField("Hotel (optional)", text: $hotelName)
                }
            }
            .navigationTitle("Add Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addDay()
                    }
                    .disabled(startLocation.isEmpty || endLocation.isEmpty)
                }
            }
        }
    }
    
    private func addDay() {
        let dayNumber = trip.days.count + 1
        let date = Calendar.current.date(byAdding: .day, value: dayNumber - 1, to: trip.startDate) ?? trip.startDate
        
        let newDay = TripDay(dayNumber: dayNumber, date: date, startLocation: startLocation, endLocation: endLocation)
        newDay.hotelName = hotelName.isEmpty ? nil : hotelName
        newDay.distance = distance
        newDay.drivingTime = drivingTime
        trip.days.append(newDay)
        
        dismiss()
    }
}
