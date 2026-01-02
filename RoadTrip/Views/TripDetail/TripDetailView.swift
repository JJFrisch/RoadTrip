// Views/TripDetail/TripDetailView.swift
//  Created by Jake Frischmann on 1/1/26.

import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Tab Picker
            Picker("View", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Activities").tag(1)
                Text("Schedule").tag(2)
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
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
