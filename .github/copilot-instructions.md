# Copilot Instructions for RoadTrip

## Project Overview
**RoadTrip** is an iOS trip planning app built with SwiftUI and SwiftData (MVVM architecture). Core features: multi-day trip planning, activity management with drag-reorder scheduling, interactive maps (MapKit), route optimization, budget tracking, hotel/car rental browsing, and offline map support.

**Key directories:** `Models/` (SwiftData entities), `ViewModels/` (business logic), `Views/` (feature-organized SwiftUI), `Services/` (external APIs, routing), `Theme/` (centralized design system), `Utilities/` (helpers, error handling, animations).

## Architecture & Patterns

### Data Layer (SwiftData)
- **Models**: `Trip`, `TripDay`, `Activity`, `ActivityTemplate`, `Hotel`, `CarRental` use `@Model` macro
- **Persistence**: Automatic sync via SwiftData; `ModelContainer` configured in `RoadTripApp.swift`
- **Migration**: DEBUG mode auto-resets DB on schema conflicts; production crashes with diagnostic message
- **Relationships**: Cascade deletes (`@Relationship(deleteRule: .cascade)`) for Trip→TripDay→Activity hierarchy

### MVVM Pattern
- **Models**: Pure data (SwiftData `@Model` classes)
- **ViewModels**: `TripsViewModel`, `TripDetailViewModel` manage state + async operations (e.g., activity imports from Google Places)
- **Views**: Feature-grouped (e.g., `Views/TripDetail/`, `Views/Home/`) using `@Bindable`, `@State`, `@StateObject`

### Theming & Design
- **Single source of truth**: `AppTheme.swift` defines colors (dark mode adaptive), typography, spacing, corner radii, shadows
- **NO hardcoded UI values**: Use `AppTheme.Colors.primary`, `AppTheme.Spacing.md`, etc.
- **Reusable modifiers**: `.cardStyle()`, `.primaryButton()`, `PrimaryButtonStyle`, `SecondaryButtonStyle`

### Error Handling & User Feedback
- **Centralized errors**: `AppError` enum (in `Utilities/AppError.swift`) for all domain errors (network, API, validation)
- **Toast notifications**: `ToastManager.shared.show(message, type: .success/.error/.warning/.info)` with auto-queuing
- **Error dialogs**: `ErrorDialogManager.shared.show(title:, message:, severity:)` for critical/blocking errors
- **View modifiers**: Wrap root views with `.withToast()` and `.withErrorDialog()` (see `RoadTripApp.swift`)

### Activity System
- **Categories**: `Food`, `Attraction`, `Hotel`, `Other`
- **Hotel activities**: Special `order = -1000` sorts them to top; includes `checkInTime`, `checkOutTime`, `hotelConfirmation` fields
- **Checked vs unchecked**: `isCompleted` flag determines if activity appears in schedule/budget calculations
- **Budget tracking**: Only `isCompleted` activities count toward `estimatedTotalCost` and `budgetByCategory`
- **Drag-reorder**: Managed via `order` property; hotel activities stay at top unless manually reordered

### Schedule View Features
- **Travel indicators**: Show distance/drive time only when **next** activity is checked (`isCompleted`)
- **Proportional heights**: Drive-time blocks scale by `hourHeight * (travelTime / 3600)` 
- **Arrival times**: Displayed next to drive-time indicators (calculated from activity end + travel duration)
- **Drag-to-update times**: `DragGesture` on timeline updates `scheduledTime` based on vertical offset

## Developer Workflows

### Build & Run
```bash
open RoadTrip.xcodeproj  # Xcode 15+
# Cmd+R to build/run on simulator or device
```

### Testing
```bash
# Unit tests (Cmd+U)
# Tests in RoadTripTests/: ModelTests, DataPersistenceTests
# UI tests in RoadTripUITests/: TripCreation, Editing, Navigation flows
```

### Debug Tips
- **SwiftData issues**: Check `RoadTripApp.swift` schema; DEBUG mode auto-resets DB
- **API errors**: Use `Config.swift` for API keys; check `NetworkMonitor.shared.isConnected` before API calls
- **Route calculations**: `RouteOptimizationService` and MapKit `MKDirections` require network

## Project Conventions

### Naming & Organization
- **Descriptive names**: `TripDetailViewModel`, `EditActivityView`, `ActivityImporter`
- **Feature folders**: Group related views (e.g., `Views/TripDetail/` contains `TripDetailView`, `ActivitiesView`, `ScheduleView`, etc.)
- **View size limits**: Keep views under 300 lines; extract subviews/components

### Code Patterns
- **Async operations**: Use `async/await` in services; wrap in `Task {}` from views
- **Loading states**: Use `LoadingView.swift`, `EmptyStateViews.swift` for consistent UX
- **Animations**: Leverage `AnimationModifiers.swift` for reusable transitions (`.fadeInOut()`, `.scaleEffect()`)
- **Responsive design**: Use helpers in `Utilities/ResponsiveLayout.swift` for iPad/iPhone layouts

### External Integrations
- **Google Places API**: `GooglePlacesService.shared` for location search/details (requires API key in `Config.swift`)
- **MapKit**: All mapping (routes, markers) via native MapKit; `TripMapView`, `ActivitiesMapView`
- **Geocoding**: `GeocodingService` wraps `CLGeocoder` for address→coordinates
- **Offline maps**: `MapboxOfflineManager` (used in `TripMapView` for offline support)
- **PDF Export**: `PDFExportService` for trip itinerary export

### Disabled/Future Features
- **Cloud sync**: `CloudSyncService` placeholder (not implemented)
- **Collaboration**: `ActivityComment`, `UserAccount`, `AuthService`, `TripSharingService` exist but disabled via `#if false` in `CollaborationFeatures.swift`
- **Weather integration**: `WeatherService` generates mock data (real API integration pending)

## Common Tasks Examples

### Add a new activity category
1. Update `categories` arrays in `EditActivityView.swift`, `AddActivityView.swift`, `ScheduleView.swift`
2. Add color mapping in `AppTheme.swift` (e.g., `.hotelColor`)
3. Update category icon logic in `ActivityRowView`, `EnhancedActivityBlock`

### Integrate a new API
1. Create service in `Services/` (e.g., `NewAPIService.swift`) with `@MainActor` for UI updates
2. Define error cases in `AppError.swift`
3. Inject via ViewModel (e.g., `TripDetailViewModel.fetchFromNewAPI()`)
4. Handle errors with `ErrorDialogManager.shared.show()` or `ToastManager.shared.show()`

### Add a new Trip property
1. Update `Trip.swift` SwiftData model (may require DB reset in DEBUG)
2. Add UI in `EditTripView.swift` and `TripDetailView.swift`
3. Update `TripDetailViewModel` if computation needed

## References
- **Architecture overview**: `README.md`
- **Design system**: `Theme/AppTheme.swift`
- **Error handling patterns**: `Utilities/AppError.swift`, `Utilities/ErrorDialogView.swift`
- **Activity import flows**: `Utilities/ActivityImporter.swift`, `Services/GooglePlacesService.swift`

---
**When in doubt**: Check nearest feature folder (e.g., `Views/TripDetail/`) for existing patterns and conventions.
