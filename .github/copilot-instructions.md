# Copilot Instructions for RoadTrip

## Project Overview
- **RoadTrip** is an iOS trip planning app using SwiftUI and SwiftData, following MVVM architecture.
- Major features: multi-day trip planning, activity management, interactive maps (MapKit), route calculation, and persistent storage.
- Key directories: `Models/` (data models), `ViewModels/` (state/business logic), `Views/` (SwiftUI screens), `Services/` (external APIs, utilities), `Theme/` (design system), `Utilities/` (helpers, error handling).

## Architecture & Patterns
- **MVVM**: Models are pure data, ViewModels handle logic/state, Views are SwiftUI components.
- **SwiftData**: All models (`Trip`, `TripDay`, `Activity`, etc.) use `@Model` for persistence. Data changes sync instantly.
- **Theming**: Use `AppTheme.swift` for all colors, fonts, and spacing. Do not hardcode UI constants.
- **Navigation**: Views are grouped by feature (e.g., `TripDetail/`, `Home/`). Use feature folders for new screens.
- **Services**: All API and external integrations (e.g., MapKit, Google Places, PDF export) are in `Services/`.
- **Error Handling**: Use `AppError.swift` and `ErrorDialogView.swift` for user-facing errors.

## Developer Workflows
- **Build**: Open `RoadTrip.xcodeproj` in Xcode 15+, select a device/simulator, press `Cmd+R`.
- **Unit Tests**: Press `Cmd+U` in Xcode to run all tests. Tests are in `RoadTripTests/` and `RoadTripUITests/`.
- **UI Tests**: Use `RoadTripUITests/` for end-to-end flows (trip creation, editing, deletion, navigation).
- **Data Persistence Tests**: Validate SwiftData operations in `RoadTripTests/DataPersistenceTests.swift`.

## Project Conventions
- **Naming**: Use descriptive names for models, view models, and views (e.g., `TripDetailViewModel`, `EditActivityView`).
- **File Organization**: Place new features in their respective folders. Keep views under 300 lines.
- **Animations**: Use `AnimationModifiers.swift` for reusable transitions.
- **Loading/Empty/Error States**: Use `LoadingView.swift` and `EmptyStateViews.swift`.
- **Responsive Design**: Use helpers in `Utilities/ResponsiveLayout.swift`.
- **Testing**: Write tests for all new features and edge cases.

## Integration Points
- **MapKit**: Used for all mapping and route calculations (`Views/TripMapView.swift`, `Services/RouteOptimizationService.swift`).
- **Google Places**: Integrated via `Services/GooglePlacesService.swift` for location search.
- **PDF Export**: Use `Services/PDFExportService.swift` for trip export features.
- **Cloud Sync**: (If enabled) handled by `Services/CloudSyncService.swift`.

## Examples
- To add a new activity type, update `Models/Activity.swift`, `Views/EditActivityView.swift`, and `Theme/AppTheme.swift` for color.
- For new API integrations, create a service in `Services/`, inject via view models, and handle errors with `AppError.swift`.

## References
- See `README.md` for usage, architecture, and testing details.
- See `Theme/AppTheme.swift` for design system.
- See `Utilities/` for reusable helpers and error handling.

---

**If unsure about a pattern, check the closest existing feature folder for examples.**
