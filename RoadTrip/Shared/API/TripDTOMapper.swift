//
//  TripDTOMapper.swift
//  RoadTrip
//
//  Created by GitHub Copilot.
//

import Foundation

extension Trip {
    func asDTO(sync: SyncMetadataDTO = .initial) -> TripDTO {
        TripDTO(
            id: id,
            name: name,
            tripDescription: tripDescription,
            startDate: startDate,
            endDate: endDate,
            coverImage: coverImage,
            createdAt: createdAt,
            totalBudget: totalBudget,
            spentAmount: spentAmount,
            budgetCategories: budgetCategories,
            ownerId: ownerId,
            ownerEmail: ownerEmail,
            days: days
                .sorted { $0.dayNumber < $1.dayNumber }
                .map { $0.asDTO(sync: sync) },
            sync: sync
        )
    }
}

extension TripDay {
    func asDTO(sync: SyncMetadataDTO = .initial) -> TripDayDTO {
        TripDayDTO(
            id: id,
            dayNumber: dayNumber,
            date: date,
            startLocation: startLocation,
            endLocation: endLocation,
            distance: distance,
            drivingTime: drivingTime,
            hotelName: hotelName,
            activities: activities
                .sorted { $0.order < $1.order }
                .map { $0.asDTO(sync: sync) },
            sync: sync
        )
    }
}

extension Activity {
    func asDTO(sync: SyncMetadataDTO = .initial) -> ActivityDTO {
        ActivityDTO(
            id: id,
            name: name,
            location: location,
            scheduledTime: scheduledTime,
            duration: duration,
            category: category,
            notes: notes,
            isCompleted: isCompleted,
            order: order,
            checkInTime: checkInTime,
            checkOutTime: checkOutTime,
            hotelConfirmation: hotelConfirmation,
            hotelPhoneNumber: hotelPhoneNumber,
            hotelWebsite: hotelWebsite,
            estimatedCost: estimatedCost,
            costCategory: costCategory,
            latitude: latitude,
            longitude: longitude,
            placeId: placeId,
            sourceType: sourceType,
            importedAt: importedAt,
            rating: rating,
            photoURL: photoURL,
            website: website,
            phoneNumber: phoneNumber,
            openingHours: openingHours,
            photos: photos,
            photoThumbnails: photoThumbnails,
            isMultiDay: isMultiDay,
            endDate: endDate,
            spansDays: spansDays,
            actualStartTime: nil,
            actualEndTime: nil,
            sync: sync
        )
    }
}
