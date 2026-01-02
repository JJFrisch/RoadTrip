# RoadTrip

A comprehensive iOS trip planning application built with SwiftUI and SwiftData. Plan multi-day road trips, organize activities by day, view interactive maps, and calculate driving routes with real-time estimates.

## Features

- **Trip Planning**: Create and manage multi-day road trips with custom dates and descriptions
- **Interactive Maps**: View trip locations on interactive maps powered by MapKit
- **Route Calculation**: Automatic driving route calculations with distance and time estimates
- **Activity Management**: Organize activities by category (Food, Attractions, Hotels, Other) with scheduling and notes
- **Day-by-Day Schedule**: Visual timeline view of activities for each trip day
- **Data Persistence**: All trips and activities automatically saved with SwiftData
- **Responsive Design**: Optimized layouts for iPhone, iPad, and different screen sizes
- **Loading States**: Smooth loading indicators and error handling throughout the app
- **Animations**: Polished transitions and interactive animations for better UX

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later
- An Apple device or simulator with location services

## Installation

### Clone the Repository

```shell
git clone https://github.com/yourusername/RoadTrip.git
cd RoadTrip
```

### Open in Xcode

```bash
open RoadTrip.xcodeproj
```

Or open `RoadTrip.xcodeproj` directly in Xcode.

### Build and Run

1. Select your target device or simulator (iPhone 14+ recommended)
2. Press `Cmd + R` to build and run the app
3. The app will launch on your selected device

## Project Structure

```
RoadTrip/
├── App/
│   └── RoadTripApp.swift           # Main app entry point
├── Models/
│   ├── Trip.swift                  # Trip data model
│   ├── TripDay.swift               # Daily trip segment model
│   └── Activity.swift              # Activity data model
├── ViewModels/
│   ├── TripsViewModel.swift        # Home screen view model
│   └── TripDetailViewModel.swift   # Trip detail view model
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift          # Trip list view
│   │   └── EditTripView.swift      # Trip creation/editing form
│   └── TripDetail/
│       ├── TripDetailView.swift    # Main trip detail container
│       ├── OverviewView.swift      # Trip overview cards
│       ├── ActivitiesView.swift    # Activity list and management
│       ├── ScheduleView.swift      # Timeline view
│       ├── RouteInfoView.swift     # Route calculations
│       ├── TripMapView.swift       # Trip locations map
│       ├── ActivitiesMapView.swift # Activities on map
│       └── EditActivityView.swift  # Activity creation/editing
├── Theme/
│   └── AppTheme.swift              # Design system and theming
├── Utilities/
│   ├── AnimationModifiers.swift    # Reusable animation transitions
│   ├── LoadingView.swift           # Loading/error/empty states
│   └── ResponsiveLayout.swift      # Responsive design utilities
└── Assets/
    └── AccentColor.colorset        # App accent colors
```

## Usage Examples

### Creating a Trip

1. Tap the **"Add Trip"** button on the home screen
2. Enter trip name, description, and select start/end dates
3. Tap **"Save"** - trip days are automatically generated
4. Trip appears in your trip list

### Adding Activities to a Day

1. Navigate to a trip detail
2. Tap the **"Activities"** tab
3. Tap the **"+"** button to add a new activity
4. Fill in activity details:
   - **Name**: Activity name (e.g., "Lunch at Joe's")
   - **Location**: Where the activity takes place
   - **Category**: Food, Attraction, Hotel, or Other
   - **Scheduled Time**: What time to do it
   - **Duration**: How long it lasts (in hours)
   - **Notes**: Any additional details
5. Tap **"Save"**

### Viewing the Map

1. In trip detail, tap the **"Map"** tab
2. View all activities as markers on the map
3. Tap a marker to see activity details
4. Swipe down to dismiss details

### Checking Your Route

1. In trip detail, tap the **"Route"** tab
2. View all day routes with:
   - **Distance**: Total driving distance for each day
   - **Time**: Estimated driving time
   - **Locations**: Start and end points for each day
3. The app calculates optimal routes using MapKit

### Scheduling Your Days

1. In trip detail, tap the **"Schedule"** tab
2. View timeline of activities for each day
3. Activities are color-coded by category
4. See scheduled times and durations at a glance

### Editing a Trip

1. On the trip card, tap the **"Edit"** button
2. Update trip name, description, or dates
3. Tap **"Save"** to apply changes

### Deleting a Trip

1. Swipe left on a trip card (or tap menu button)
2. Tap **"Delete"**
3. Confirm deletion in the alert

## Architecture

### MVVM Pattern

The app follows Model-View-ViewModel architecture:

- **Models**: `Trip`, `TripDay`, `Activity` - SwiftData @Model entities
- **ViewModels**: `TripsViewModel`, `TripDetailViewModel` - Manage app state and business logic
- **Views**: SwiftUI views organized by screen and feature

### Data Persistence

The app uses **SwiftData** for persistent storage:

- All trips, days, and activities automatically save to device storage
- Changes sync instantly to the persistent store
- Data persists between app sessions

### Theme System

Centralized design system in `AppTheme.swift` provides:

- **Colors**: Primary, secondary, accent, backgrounds
- **Typography**: Different text sizes and weights
- **Spacing**: Consistent padding and margins
- **Shadows**: Depth and elevation
- **Corner Radius**: Rounded corners for consistency
- **Animation Durations**: Smooth, consistent animations

## Testing

### Running Unit Tests

1. Open the project in Xcode
2. Press `Cmd + U` to run all tests
3. View results in the Test Navigator

**Test Coverage:**

- Model creation and properties (60+ tests)
- Data calculations (distance, duration, dates)
- Validation and edge cases
- Performance benchmarks

### Running UI Tests

UI tests verify complete user flows:

- Home screen display and empty states
- Trip creation and validation
- Navigation between screens and tabs
- Editing trips and activities
- Deleting data with confirmations
- Performance metrics

### Data Persistence Tests

Tests verify SwiftData operations:

- Saving and retrieving trips
- Updating trip information
- Creating and managing activities
- Cascade deletion
- Data integrity across app sessions

## Performance

The app is optimized for smooth performance:

- Efficient MapKit rendering with lazy loading
- Optimized list views with `.onAppear` timing
- Minimal re-renders with proper state management
- Pagination for large activity lists
- Responsive animations at 60 FPS

## Known Limitations

- Route calculations require network access for MapKit
- Maps require location services enabled
- Very large trips (100+ activities) may have slower map rendering
- Some features require iOS 17.0+

## Future Enhancements

- [ ] Export trips to PDF or share with others
- [ ] Offline map caching
- [ ] Collaborative trip planning
- [ ] Weather integration for each day
- [ ] Cost tracking and budgeting
- [ ] Photo integration and gallery
- [ ] Real-time traffic data
- [ ] Voice-guided navigation integration
- [ ] Social sharing features
- [ ] Siri shortcuts support

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Swift style guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Write tests for new features
- Keep views under 300 lines when possible

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, feature requests, or questions:

- Open an issue on GitHub
- Check existing issues for similar problems
- Provide detailed steps to reproduce issues

## Acknowledgments

- Built with SwiftUI and SwiftData
- Maps powered by MapKit
- Inspired by trip planning best practices
- Thanks to the Swift community
