// Services/PDFExportService.swift
import Foundation
import UIKit
import PDFKit

class PDFExportService {
    static let shared = PDFExportService()
    
    private init() {}
    
    func generateTripPDF(trip: Trip) -> Data? {
        let pageWidth: CGFloat = 612 // Letter size
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - (margin * 2)
        
        let pdfMetaData = [
            kCGPDFContextCreator: "RoadTrip App",
            kCGPDFContextTitle: trip.name
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )
        
        let data = renderer.pdfData { context in
            var yPosition: CGFloat = margin
            
            // Helper to check if we need a new page
            func checkNewPage(needed: CGFloat) {
                if yPosition + needed > pageHeight - margin {
                    context.beginPage()
                    yPosition = margin
                }
            }
            
            // Start first page
            context.beginPage()
            
            // MARK: - Title
            let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            
            let titleString = trip.name
            titleString.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            // MARK: - Trip Summary
            let subtitleFont = UIFont.systemFont(ofSize: 14, weight: .regular)
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: subtitleFont,
                .foregroundColor: UIColor.darkGray
            ]
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            
            let dateRange = "\(dateFormatter.string(from: trip.startDate)) - \(dateFormatter.string(from: trip.endDate))"
            dateRange.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: subtitleAttributes)
            yPosition += 20
            
            let summary = "\(trip.days.count) days • \(Int(trip.totalDistance)) miles"
            summary.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: subtitleAttributes)
            yPosition += 15
            
            // Budget estimate if available
            let estimatedBudget = trip.estimatedTotalCost
            if estimatedBudget > 0 {
                let budgetStr = String(format: "Estimated Budget: $%.2f", estimatedBudget)
                budgetStr.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: subtitleAttributes)
                yPosition += 15
            }
            
            yPosition += 20
            
            // MARK: - Divider
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: margin, y: yPosition))
            dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
            UIColor.lightGray.setStroke()
            dividerPath.lineWidth = 1
            dividerPath.stroke()
            yPosition += 20
            
            // MARK: - Days
            let headingFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
            let headingAttributes: [NSAttributedString.Key: Any] = [
                .font: headingFont,
                .foregroundColor: UIColor.black
            ]
            
            let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: UIColor.darkGray
            ]
            
            let activityFont = UIFont.systemFont(ofSize: 11, weight: .regular)
            let activityAttributes: [NSAttributedString.Key: Any] = [
                .font: activityFont,
                .foregroundColor: UIColor.black
            ]
            
            let sortedDays = trip.days.sorted { $0.dayNumber < $1.dayNumber }
            
            for day in sortedDays {
                // Check if we need a new page (estimate day block height)
                let estimatedHeight: CGFloat = 100 + CGFloat(day.activities.count * 45)
                checkNewPage(needed: min(estimatedHeight, 200))
                
                // Day header
                let dayTitle = "Day \(day.dayNumber) - \(dateFormatter.string(from: day.date))"
                dayTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headingAttributes)
                yPosition += 25
                
                // Route info
                if !day.startLocation.isEmpty && !day.endLocation.isEmpty {
                    let routeInfo = "📍 \(day.startLocation) → \(day.endLocation)"
                    routeInfo.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 18
                }
                
                // Distance and time
                if day.distance > 0 {
                    let hours = Int(day.drivingTime)
                    let minutes = Int((day.drivingTime - Double(hours)) * 60)
                    let timeStr = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
                    let distanceInfo = "🚗 \(Int(day.distance)) miles • \(timeStr) drive"
                    distanceInfo.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 18
                }
                
                // Hotel
                if let hotel = day.hotel?.name ?? day.hotelName, !hotel.isEmpty {
                    let hotelInfo = "🏨 \(hotel)"
                    hotelInfo.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 18
                }
                
                // Activities
                let sortedActivities = day.activities.filter { $0.isCompleted }.sorted { a, b in
                    guard let timeA = a.scheduledTime, let timeB = b.scheduledTime else {
                        return a.scheduledTime != nil
                    }
                    return timeA < timeB
                }
                
                if !sortedActivities.isEmpty {
                    yPosition += 5
                    
                    for activity in sortedActivities {
                        checkNewPage(needed: 45)
                        
                        // Activity box
                        let boxRect = CGRect(x: margin + 10, y: yPosition, width: contentWidth - 20, height: 40)
                        let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 6)
                        UIColor.systemGray6.setFill()
                        boxPath.fill()
                        
                        // Time
                        var activityText = ""
                        if let time = activity.scheduledTime {
                            let timeFormatter = DateFormatter()
                            timeFormatter.timeStyle = .short
                            activityText = timeFormatter.string(from: time) + " - "
                        }
                        
                        // Name and location
                        activityText += "\(activity.name)"
                        activityText.draw(at: CGPoint(x: margin + 18, y: yPosition + 6), withAttributes: activityAttributes)
                        
                        let locationText = "📍 \(activity.location)"
                        let locationAttributes: [NSAttributedString.Key: Any] = [
                            .font: UIFont.systemFont(ofSize: 10),
                            .foregroundColor: UIColor.gray
                        ]
                        locationText.draw(at: CGPoint(x: margin + 18, y: yPosition + 22), withAttributes: locationAttributes)
                        
                        // Cost if available
                        if let cost = activity.estimatedCost, cost > 0 {
                            let costText = String(format: "$%.0f", cost)
                            let costAttributes: [NSAttributedString.Key: Any] = [
                                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                                .foregroundColor: UIColor.systemGreen
                            ]
                            let costSize = costText.size(withAttributes: costAttributes)
                            costText.draw(at: CGPoint(x: pageWidth - margin - 20 - costSize.width, y: yPosition + 12), withAttributes: costAttributes)
                        }
                        
                        yPosition += 48
                    }
                }
                
                yPosition += 15
                
                // Day divider
                let dayDividerPath = UIBezierPath()
                dayDividerPath.move(to: CGPoint(x: margin, y: yPosition))
                dayDividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
                UIColor.lightGray.withAlphaComponent(0.5).setStroke()
                dayDividerPath.lineWidth = 0.5
                dayDividerPath.stroke()
                yPosition += 15
            }
            
            // MARK: - Budget Summary (if any)
            let budgetBreakdown = trip.budgetBreakdown
            if !budgetBreakdown.isEmpty {
                checkNewPage(needed: 120)
                
                yPosition += 10
                "Budget Summary".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headingAttributes)
                yPosition += 30
                
                for item in budgetBreakdown {
                    let categoryIcon: String
                    switch item.category {
                    case "Gas": categoryIcon = "⛽️"
                    case "Food": categoryIcon = "🍽️"
                    case "Lodging": categoryIcon = "🏨"
                    case "Attractions": categoryIcon = "🎢"
                    default: categoryIcon = "💰"
                    }
                    
                    let budgetLine = String(format: "%@ %@: $%.2f", categoryIcon, item.category, item.amount)
                    budgetLine.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 20
                }
                
                yPosition += 10
                let totalLine = String(format: "Total: $%.2f", trip.estimatedTotalCost)
                let totalAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                    .foregroundColor: UIColor.black
                ]
                totalLine.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: totalAttributes)
            }
            
            // MARK: - Footer
            checkNewPage(needed: 50)
            yPosition = pageHeight - margin - 20
            
            let footerText = "Generated by RoadTrip App • \(dateFormatter.string(from: Date()))"
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.lightGray
            ]
            let footerSize = footerText.size(withAttributes: footerAttributes)
            footerText.draw(at: CGPoint(x: (pageWidth - footerSize.width) / 2, y: yPosition), withAttributes: footerAttributes)
        }
        
        return data
    }
}
