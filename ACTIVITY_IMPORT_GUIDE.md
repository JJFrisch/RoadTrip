# Activity Import & Smart Features - Usage Guide

## Overview

The RoadTrip app now includes powerful features for importing activities, smart time suggestions, offline mode support, and map thumbnails.

## Activity Import

### Import from URL (TripAdvisor / Google Maps)

1. Navigate to any day's activities (via ActivitiesView or DayDetailScheduleView)
2. Tap **"Import Activities"** button
3. Choose **"From URL"** mode
4. Paste a URL from:
   - TripAdvisor attraction lists or search results
   - Google Maps saved lists or search pages
5. Tap **"Import"** to fetch places
6. Preview imported activities with details (name, location, category, duration)
7. Select/deselect activities using checkboxes
8. Tap **"Add Selected"** to bulk-add to your day

**Note:** URL-based import uses HTML parsing heuristics and is best-effort. For production use, integrate official APIs (Google Places API, TripAdvisor Partner API).

### Import Nearby POIs

1. Open the import sheet
2. Choose **"Nearby POIs"** mode
3. Adjust search radius (500m - 10,000m)
4. Tap **"Search Nearby"** to find attractions near the day's end location
5. Uses Apple MapKit local search for points of interest
6. Preview and select places to add
7. Tap **"Add Selected"**

## Smart Time Suggestions

When adding a new activity with "Set Time" enabled:

- Toggle **"Use Smart Suggestion"** on
- The app automatically suggests a start time based on:
  - Previous activity's end time + travel time
  - Meal windows:
    - Breakfast: 7-9 AM
    - Lunch: 12-2 PM
    - Dinner: 6-8 PM
  - Activity category and typical duration

The suggester intelligently schedules meals during appropriate hours and spaces out attractions.

## Map Thumbnails

Each day card in the Overview tab now shows a small map preview:

- Automatically geocodes the day's end location
- Renders a thumbnail using MapKit snapshotter
- Fast preview without opening full map view
- Tapping the card still opens the full day details

## Offline Mode

### Location Search Cache

- All location searches are automatically cached locally
- Reuses previously searched locations when offline
- Cache managed via `LocationSearchCache.shared`

### Offline Map Regions (Placeholder)

- `OfflineMapManager` tracks downloaded map regions
- Currently stores metadata only
- For true offline tiles, integrate Mapbox or HERE SDK

### Sync Manager

- Queue operations when offline
- Sync later when internet returns
- Access via `SyncManager.shared`

## Day Copy Feature

To duplicate a complete day:

```swift
let viewModel = TripDetailViewModel()
viewModel.copyDay(existingDay, to: newDate, into: trip)
```

This creates a deep copy of all activities, locations, and settings for multi-city trips or repeating itineraries.

## Implementation Files

### Utilities

- `SmartTimeSuggester.swift` - Time suggestion logic
- `ActivityImporter.swift` - Import from URLs and nearby search
- `LocationSearchCache.swift` - Offline search cache
- `OfflineMapManager.swift` - Map region tracking
- `SyncManager.swift` - Offline operation queue
- `DayCopier.swift` - Day duplication logic
- `MapThumbnailRenderer.swift` - Map snapshot generation

### Views

- `ActivityImportSheet.swift` - Import UI with URL and nearby modes
- `MapThumbnailView.swift` - SwiftUI thumbnail component

### View Models

- `TripDetailViewModel.swift` - Exposes import, suggest, and copy APIs

### Updated Views

- `ActivitiesView.swift` - Added import button
- `DayDetailScheduleView.swift` - Added import button
- `OverviewView.swift` - Shows map thumbnails

## Future Enhancements

1. **API Integration**: Replace HTML parsing with official APIs
2. **Offline Tile Download**: Integrate third-party map SDK for true offline maps
3. **Coordinate Fields**: Add lat/lon fields to Activity model
4. **Background Sync**: Implement automatic sync when network returns
5. **Unit Tests**: Add comprehensive tests for importer parsing logic

## Example Usage

```swift
// Import activities from URL
let viewModel = TripDetailViewModel()
try await viewModel.importActivities(
    from: URL(string: "https://www.tripadvisor.com/...")!,
    into: day,
    modelContext: modelContext
)

// Get smart time suggestion
let suggestedTime = viewModel.suggestStart(
    previousEnd: lastActivity.scheduledTime,
    driveTime: 1800, // 30 minutes in seconds
    activityCategory: "Food",
    typicalDurationHours: 1.5
)

// Copy a day
viewModel.copyDay(day1, to: nextWeekDate, into: trip)
```
