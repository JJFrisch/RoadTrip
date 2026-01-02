// Views/TripDetail/TripDetailView.swift
//  Created by Jake Frischmann on 1/1/26.

import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @State private var selectedTab = 0
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Tab Picker
            Picker("View", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Activities").tag(1)
                Text("Schedule").tag(2)
                Text("Route").tag(3)
                Text("Map").tag(4)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Tab Content
            TabView(selection: $selectedTab) {
                OverviewView(trip: trip)
                    .tag(0)
                
                ActivitiesView(trip: trip)
                    .tag(1)
                
                ScheduleView(trip: trip)
                    .tag(2)
                
                RouteInfoView(trip: trip)
                    .tag(3)
                
                TripMapView(trip: trip)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Image(systemName: "pencil.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTripView(trip: trip)
        }
    }
}
