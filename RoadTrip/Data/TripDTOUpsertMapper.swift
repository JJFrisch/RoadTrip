//
//  TripDTOUpsertMapper.swift
//  RoadTrip
//
//  Created by GitHub Copilot.
//

import Foundation
import SwiftData

@MainActor
enum TripDTOUpsertMapper {
    static func upsertTrips(_ dtos: [TripDTO], in modelContext: ModelContext) throws -> [Trip] {
        let existingTrips = try modelContext.fetch(FetchDescriptor<Trip>())
        var tripByID: [UUID: Trip] = [:]
        for trip in existingTrips {
            tripByID[trip.id] = trip
        }

        var synced: [Trip] = []
        for dto in dtos {
            let trip = upsertTrip(dto, existingTrip: tripByID[dto.id], in: modelContext)
            synced.append(trip)
            tripByID[trip.id] = trip
        }

        try modelContext.save()
        return synced.sorted { $0.createdAt > $1.createdAt }
    }

    static func upsertTrip(_ dto: TripDTO, in modelContext: ModelContext) throws -> Trip {
        let existingTrips = try modelContext.fetch(FetchDescriptor<Trip>())
        let existing = existingTrips.first(where: { $0.id == dto.id })
        let trip = upsertTrip(dto, existingTrip: existing, in: modelContext)
        try modelContext.save()
        return trip
    }

    @discardableResult
    private static func upsertTrip(_ dto: TripDTO, existingTrip: Trip?, in modelContext: ModelContext) -> Trip {
        let trip: Trip
        if let existingTrip {
            trip = existingTrip
        } else {
            let created = Trip(name: dto.name, startDate: dto.startDate, endDate: dto.endDate)
            created.id = dto.id
            created.days.removeAll()
            modelContext.insert(created)
            trip = created
        }

        trip.id = dto.id
        trip.name = dto.name
        trip.tripDescription = dto.tripDescription
        trip.startDate = dto.startDate
        trip.endDate = dto.endDate
        trip.coverImage = dto.coverImage
        trip.createdAt = dto.createdAt
        trip.totalBudget = dto.totalBudget
        trip.spentAmount = dto.spentAmount
        trip.budgetCategories = dto.budgetCategories
        trip.ownerId = dto.ownerId
        trip.ownerEmail = dto.ownerEmail

        var existingDaysById: [UUID: TripDay] = [:]
        for day in trip.days {
            existingDaysById[day.id] = day
        }

        var syncedDays: [TripDay] = []
        for dayDTO in dto.days.sorted(by: { $0.dayNumber < $1.dayNumber }) {
            let day: TripDay
            if let existingDay = existingDaysById[dayDTO.id] {
                day = existingDay
            } else {
                let createdDay = TripDay(
                    dayNumber: dayDTO.dayNumber,
                    date: dayDTO.date,
                    startLocation: dayDTO.startLocation,
                    endLocation: dayDTO.endLocation,
                    distance: dayDTO.distance,
                    drivingTime: dayDTO.drivingTime,
                    activities: []
                )
                createdDay.id = dayDTO.id
                day = createdDay
            }

            day.id = dayDTO.id
            day.dayNumber = dayDTO.dayNumber
            day.date = dayDTO.date
            day.startLocation = dayDTO.startLocation
            day.endLocation = dayDTO.endLocation
            day.distance = dayDTO.distance
            day.drivingTime = dayDTO.drivingTime
            day.hotelName = dayDTO.hotelName

            var existingActivitiesById: [UUID: Activity] = [:]
            for activity in day.activities {
                existingActivitiesById[activity.id] = activity
            }

            var syncedActivities: [Activity] = []
            for activityDTO in dayDTO.activities.sorted(by: { $0.order < $1.order }) {
                let activity: Activity
                if let existingActivity = existingActivitiesById[activityDTO.id] {
                    activity = existingActivity
                } else {
                    let createdActivity = Activity(
                        name: activityDTO.name,
                        location: activityDTO.location,
                        category: activityDTO.category
                    )
                    createdActivity.id = activityDTO.id
                    activity = createdActivity
                }

                activity.id = activityDTO.id
                activity.name = activityDTO.name
                activity.location = activityDTO.location
                activity.scheduledTime = activityDTO.scheduledTime
                activity.duration = activityDTO.duration
                activity.category = activityDTO.category
                activity.notes = activityDTO.notes
                activity.isCompleted = activityDTO.isCompleted
                activity.order = activityDTO.order
                activity.checkInTime = activityDTO.checkInTime
                activity.checkOutTime = activityDTO.checkOutTime
                activity.hotelConfirmation = activityDTO.hotelConfirmation
                activity.hotelPhoneNumber = activityDTO.hotelPhoneNumber
                activity.hotelWebsite = activityDTO.hotelWebsite
                activity.estimatedCost = activityDTO.estimatedCost
                activity.costCategory = activityDTO.costCategory
                activity.latitude = activityDTO.latitude
                activity.longitude = activityDTO.longitude
                activity.placeId = activityDTO.placeId
                activity.sourceType = activityDTO.sourceType
                activity.importedAt = activityDTO.importedAt
                activity.rating = activityDTO.rating
                activity.photoURL = activityDTO.photoURL
                activity.website = activityDTO.website
                activity.phoneNumber = activityDTO.phoneNumber
                activity.openingHours = activityDTO.openingHours
                activity.photos = activityDTO.photos
                activity.photoThumbnails = activityDTO.photoThumbnails
                activity.isMultiDay = activityDTO.isMultiDay
                activity.endDate = activityDTO.endDate
                activity.spansDays = max(1, activityDTO.spansDays)

                syncedActivities.append(activity)
            }

            day.activities = syncedActivities
            syncedDays.append(day)
        }

        trip.days = syncedDays
        return trip
    }
}
