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
            Activity.self,
            ActivityTemplate.self
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
            #if DEBUG
            // In development, reset the database if migration fails
            print("⚠️ Migration failed in DEBUG mode, resetting database: \(error)")
            
            if let storeURL = modelConfiguration.url {
                try? FileManager.default.removeItem(at: storeURL)
                try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent().appendingPathComponent("default.store-shm"))
                try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent().appendingPathComponent("default.store-wal"))
            }
            
            do {
                return try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
            } catch {
                fatalError("Could not create ModelContainer even after reset: \(error)")
            }
            #else
            // In production, crash with detailed error for user support
            fatalError("Could not create ModelContainer. Migration failed: \(error)")
            #endif
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
