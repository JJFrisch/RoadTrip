//
//  RoadTripApp.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/1/26.
//

// App/RoadTripperApp.swift
import SwiftUI
import SwiftData

@main
struct RoadTripperApp: App {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Trip.self,
            TripDay.self,
            Activity.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.none) // Supports both light and dark mode
        }
        .modelContainer(sharedModelContainer)
    }
}
