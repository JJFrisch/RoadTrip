//
//  ScheduleView.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/1/26.
//

// Views/TripDetail/ScheduleView.swift
import SwiftUI

struct ScheduleView: View {
    let trip: Trip
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(trip.days.sorted(by: { $0.dayNumber < $1.dayNumber })) { day in
                    DayScheduleSection(day: day)
                }
            }
            .padding()
        }
    }
}

struct DayScheduleSection: View {
    let day: TripDay
    
    var sortedActivities: [Activity] {
        day.activities.sorted { a, b in
            guard let timeA = a.scheduledTime, let timeB = b.scheduledTime else {
                return a.scheduledTime != nil
            }
            return timeA < timeB
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(day.dayNumber)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(day.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.bottom, 8)
            
            // Timeline
            if sortedActivities.isEmpty {
                Text("No scheduled activities")
                    .foregroundStyle(.secondary)
                    .italic()
                    .padding(.vertical)
            } else {
                ForEach(sortedActivities) { activity in
                    TimelineItemView(activity: activity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct TimelineItemView: View {
    let activity: Activity
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time column
            VStack(spacing: 2) {
                if let time = activity.scheduledTime {
                    Text(time.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .fontWeight(.semibold)
                } else {
                    Text("--:--")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 50, alignment: .trailing)
            .foregroundStyle(.secondary)
            
            // Timeline dot and line
            VStack(alignment: .center, spacing: 0) {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    }
            }
            
            // Activity details
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(activity.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(activity.category)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(categoryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.1))
                        .cornerRadius(4)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(categoryColor.opacity(0.6))
                    
                    Text(activity.location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let duration = activity.duration {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(.orange.opacity(0.6))
                        
                        Text("\(Int(duration * 60)) minutes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var categoryColor: Color {
        switch activity.category {
        case "Food": return .orange
        case "Attraction": return .blue
        case "Hotel": return .purple
        default: return .gray
        }
    }
}
