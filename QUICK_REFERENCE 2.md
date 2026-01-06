# Quick Reference - New Features

## 🔍 Search & Filter

### Search Trips
```swift
// In HomeView, search bar appears automatically
// Type in search bar to filter by:
// - Trip name
// - Trip description  
// - Locations (start/end)
```

### Sort Trips
```swift
// Tap filter icon (≡) in toolbar
// Choose from:
TripSearchManager.SortOption.dateNewest
TripSearchManager.SortOption.dateOldest
TripSearchManager.SortOption.nameAZ
TripSearchManager.SortOption.nameZA
TripSearchManager.SortOption.durationLongest
TripSearchManager.SortOption.durationShortest
```

### Filter Trips
```swift
// In filter sheet:
TripSearchManager.SharedFilter.all
TripSearchManager.SharedFilter.sharedOnly
TripSearchManager.SharedFilter.privateOnly
```

---

## ☁️ Cloud Sync

### Sync a Trip
```swift
Task {
    try await CloudSyncService.shared.syncTrip(trip)
    // Shows success toast automatically
}
```

### Check iCloud Status
```swift
let isAvailable = CloudSyncService.shared.isAvailable
let status = CloudSyncService.shared.accountStatus
```

### Share Trip
```swift
let shareCode = try await CloudSyncService.shared.shareTrip(
    trip,
    with: "friend@email.com"
)
// Returns: "ABC12XYZ" (8-character code)
```

### Join Shared Trip
```swift
let record = try await CloudSyncService.shared.joinTrip(
    withCode: "ABC12XYZ"
)
```

---

## 🔔 Notifications

### Toast Notifications
```swift
// Success (green checkmark, 3 seconds)
ToastManager.shared.show("Trip saved!", type: .success)

// Warning (orange triangle, 4 seconds)
ToastManager.shared.show("Network slow", type: .warning)

// Error (red X, 5 seconds)
ToastManager.shared.show("Sync failed", type: .error)

// Info (blue i, 3 seconds)
ToastManager.shared.show("Tip: Tap to edit", type: .info)

// Custom duration
ToastManager.shared.show("Message", type: .info, duration: 10.0)
```

### Error Dialogs
```swift
// Critical error (blocks UI)
ErrorDialogManager.shared.showCriticalError(
    title: "Sync Failed",
    message: "Could not connect to iCloud. Check your internet connection.",
    onRetry: {
        Task { try await syncAgain() }
    }
)

// Custom dialog with actions
ErrorDialogManager.shared.show(
    title: "Delete Trip?",
    message: "This action cannot be undone.",
    severity: .warning,
    primaryAction: .init(
        title: "Delete",
        role: .destructive,
        handler: { deleteTrip() }
    ),
    secondaryAction: .init(
        title: "Cancel",
        role: .cancel,
        handler: { }
    )
)
```

---

## 📋 Empty States

### Generic Empty State
```swift
EmptyStateView(
    icon: "tray",
    title: "No Items",
    message: "Get started by adding your first item",
    actionTitle: "Add Item",
    action: { showAddSheet = true }
)
```

### No Activities
```swift
NoActivitiesView(
    onAddActivity: { showAddActivity = true },
    onImportActivities: { showImport = true }
)
```

### No Search Results
```swift
NoSearchResultsView(
    searchText: searchManager.searchText,
    onClear: { searchManager.searchText = "" }
)
```

### Offline State
```swift
OfflineEmptyStateView(
    featureName: "Hotel Search",
    onRetry: { Task { await searchAgain() } }
)
```

### Loading State
```swift
LoadingEmptyStateView(message: "Loading hotels...")
```

---

## 🎓 Onboarding

### Check if Should Show
```swift
if OnboardingManager.shared.shouldShowOnboarding {
    showingOnboarding = true
}
```

### Manual Display
```swift
.sheet(isPresented: $showingOnboarding) {
    OnboardingView {
        // Optional completion handler
        print("Onboarding complete")
    }
}
```

### Show Tutorial
```swift
.sheet(isPresented: $showingTutorial) {
    QuickTutorialView()
}
```

### Create Sample Trip
```swift
// From HomeView
createComprehensiveSampleTrip()
// Creates 7-day Pacific Coast Highway trip
```

---

## 🎨 Activity Filtering

### Create Filter Manager
```swift
@StateObject var filterManager = ActivityFilterManager()
```

### Filter Activities
```swift
let filtered = filterManager.filter(activities)
```

### Change Category
```swift
filterManager.selectedCategory = .food  // Food only
filterManager.selectedCategory = .all   // Show all
```

### Change Sort
```swift
filterManager.sortBy = .time   // By scheduled time
filterManager.sortBy = .name   // Alphabetical
filterManager.sortBy = .cost   // By estimated cost
filterManager.sortBy = .order  // Default order
```

### Filter by Completion
```swift
filterManager.showCompletedOnly = true
filterManager.showIncompleteOnly = true
```

### Show Filter Sheet
```swift
.sheet(isPresented: $showingFilter) {
    ActivityFilterSheet(filterManager: filterManager)
}
```

---

## 🛠️ View Modifiers

### Add Toast Support
```swift
// In RoadTripApp.swift (already added globally)
HomeView()
    .withToast()
```

### Add Error Dialog Support
```swift
// In RoadTripApp.swift (already added globally)
HomeView()
    .withErrorDialog()
```

### Both Together
```swift
HomeView()
    .withToast()
    .withErrorDialog()
```

---

## 📊 Error Log

### Access Error Log
```swift
// Navigate to:
Account → Support → Error Log

// Programmatically:
NavigationLink {
    ErrorLogView()
} label: {
    Label("Error Log", systemImage: "exclamationmark.triangle")
}
```

### Record Custom Error
```swift
ErrorRecoveryManager.shared.record(
    title: "Import Failed",
    message: "Could not parse activities from URL",
    severity: .warning,
    action: { retryImport() }
)
```

### Clear Errors
```swift
ErrorRecoveryManager.shared.clearErrors()
```

---

## 🎯 Common Patterns

### Search + Filter + Sort
```swift
struct MyView: View {
    @StateObject var searchManager = TripSearchManager()
    @Query private var trips: [Trip]
    
    var filteredTrips: [Trip] {
        searchManager.filterAndSort(Array(trips))
    }
    
    var body: some View {
        List(filteredTrips) { trip in
            TripRow(trip: trip)
        }
        .searchable(text: $searchManager.searchText)
        .toolbar {
            Button { showingFilters = true } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterSortSheet(searchManager: searchManager)
        }
    }
}
```

### Async Operation with Error Handling
```swift
func saveTrip() {
    Task {
        do {
            try await CloudSyncService.shared.syncTrip(trip)
            ToastManager.shared.show("Trip synced!", type: .success)
        } catch {
            ErrorDialogManager.shared.showCriticalError(
                title: "Sync Failed",
                message: error.localizedDescription,
                onRetry: { saveTrip() }
            )
        }
    }
}
```

### Empty State with Search
```swift
var body: some View {
    if filteredTrips.isEmpty {
        if searchManager.searchText.isEmpty {
            EmptyStateView(
                icon: "car.fill",
                title: "No Trips",
                message: "Create your first trip",
                actionTitle: "Add Trip",
                action: { showAddTrip = true }
            )
        } else {
            NoSearchResultsView(
                searchText: searchManager.searchText,
                onClear: { searchManager.searchText = "" }
            )
        }
    } else {
        List(filteredTrips) { trip in
            TripRow(trip: trip)
        }
    }
}
```

---

## ⚙️ Configuration

### Enable iCloud (Required for Sync)
1. Xcode → Project → Signing & Capabilities
2. Click "+ Capability"
3. Add "iCloud"
4. Check "CloudKit"
5. Add container: `iCloud.com.roadtrip.app`

### AppStorage Keys Used
```swift
@AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
@AppStorage("onboardingVersion") var onboardingVersion = 0
```

### Singleton Managers
```swift
ToastManager.shared
ErrorDialogManager.shared
ErrorRecoveryManager.shared
CloudSyncService.shared
OnboardingManager.shared
```

---

## 🧪 Testing

### Test Toast Notifications
```swift
Button("Test Toast") {
    ToastManager.shared.show("Test message", type: .success)
}
```

### Test Error Dialog
```swift
Button("Test Dialog") {
    ErrorDialogManager.shared.show(
        title: "Test",
        message: "This is a test error",
        severity: .error
    )
}
```

### Test Onboarding
```swift
// Reset onboarding
OnboardingManager.shared.hasCompletedOnboarding = false
// Restart app to see onboarding
```

### Test Empty States
```swift
// Delete all trips to see empty state
// Search for gibberish to see no results
```

---

## 📱 UI Components

### Toast Notification
- Appears at top of screen
- Auto-dismisses after duration
- Swipe up to dismiss early
- Shows one at a time (queued)
- Color-coded by type

### Error Dialog
- Modal overlay (dims background)
- Can't tap outside to dismiss (for critical)
- Custom actions with roles
- Color-coded icon
- Smooth animations

### Filter Sheet
- Modal bottom sheet
- Radio button selection
- Instant preview
- Reset to defaults
- Auto-saves preferences

### Empty State
- Centered content
- Icon with gradient background
- Title and description
- Optional action button
- Consistent styling

---

## 🎨 Color Coding

### Toast Types
- 🟢 Success: Green checkmark
- 🟠 Warning: Orange triangle
- 🔴 Error: Red X
- 🔵 Info: Blue info circle

### Error Severity
- 🔵 Info: Blue
- 🟠 Warning: Orange
- 🔴 Error: Red
- 🟣 Critical: Purple

---

## 💡 Tips

1. **Search is instant** - No submit button needed
2. **Filters persist** - Settings saved until reset
3. **Toasts queue** - Multiple toasts show one by one
4. **Errors auto-log** - All errors recorded automatically
5. **Onboarding once** - Only shows on first launch per version
6. **Sample trip** - Great for testing all features
7. **Error log** - Check Account → Error Log for debugging
8. **Cloud requires iCloud** - Must enable in Xcode + sign in on device

---

**All features are production-ready and tested!** 🚀
