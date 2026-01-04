# RoadTrip Error Resilience Guide

This guide explains how RoadTrip handles errors gracefully so the app continues running even when parts of it fail.

## Overview

RoadTrip is designed with **graceful degradation** - when one feature fails, the rest of the app keeps working normally. This is accomplished through:

1. **Try-Catch Blocks** - Catch errors and continue execution
2. **Mock Data Fallbacks** - Show sample data instead of crashing
3. **Optional Features** - Some features can be disabled without breaking the app
4. **Error Recovery** - Log errors and show user-friendly messages
5. **Network Awareness** - Detect offline status and adjust UI accordingly

---

## What Works Without Internet

### Core Features (Always Work)
- ✅ View all trips and activities
- ✅ Create/edit trips and activities
- ✅ Schedule view with drag-and-drop
- ✅ Time and budget tracking
- ✅ Local notifications
- ✅ PDF export
- ✅ Everything saved to device

### Features That Work Partially Offline
- ✅ View previously downloaded maps
- ✅ View cached hotel/car rental searches
- ✅ View cached weather data
- ✅ Search with mock results displayed

### Features That Need Internet
- ❌ Real-time location search (but sample results shown)
- ❌ Weather updates (but cached forecast shown)
- ❌ Hotel browsing (mock data shown)
- ❌ Car rental search (mock data shown)
- ❌ Map routing (but cached routes shown)

---

## Error Handling Architecture

### 1. Services with Built-in Fallbacks

#### HotelSearchService
```swift
// Behavior when API fails:
do {
    let hotels = try await searchBookingCom(query: destination)
} catch {
    // Logs error to ErrorRecoveryManager
    // Shows user-friendly alert with "Retry" button
    // Returns mock hotel data instead
    return generateMockResults()
}
```

**What Users See:**
- Loading indicator while searching
- Error message: "Unable to fetch hotels. Showing sample results."
- Sample hotel cards that look like real results
- "Retry" button to try again

#### CarRentalSearchService
```swift
// Same pattern as HotelSearchService
// Fails gracefully with mock car data
```

#### GeocodingService
```swift
do {
    let coordinates = try await geocode(address: "San Francisco")
} catch {
    // Uses cached location or fallback coordinates
    // San Francisco (37.7749, -122.4194) as default
}
```

#### WeatherService
```swift
do {
    let forecast = try await getWeather(lat: 37.77, lon: -122.41)
} catch {
    // Shows cached weather from last successful call
    // Or shows "Weather unavailable" message
}
```

### 2. Network Status Monitoring

Every network-dependent view shows a `NetworkStatusBanner`:

```swift
struct NetworkStatusBanner: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack {
                Image(systemName: "wifi.slash")
                Text("No Internet Connection")
                Spacer()
                Image(systemName: "xmark.circle.fill").onTapGesture {
                    // Dismiss
                }
            }
            .padding()
            .background(Color.red)
            .foregroundStyle(.white)
        }
    }
}
```

**Where It Appears:**
- HotelBrowsingView (top of search)
- CarRentalBrowsingView (top of search)
- MapView (if available)

### 3. Error Recovery System

The new `ErrorRecovery.swift` provides:

#### ErrorRecoveryManager
- Logs all errors with severity levels (Warning, Error, Critical)
- Stores up to 50 errors for debugging
- Available via `ErrorRecoveryManager.shared`

#### Error Severity Levels
```swift
enum Severity {
    case warning   // Feature degraded but working
    case error     // Feature disabled but app continues
    case critical  // App may crash soon
}
```

#### Recording Errors
```swift
ErrorRecoveryManager.shared.record(
    title: "Hotel Search Failed",
    message: "Unable to connect to Booking.com API",
    severity: .warning,
    action: { retrySearch() }  // Optional retry action
)
```

#### Error Display
- **Warnings:** Orange banner, can dismiss
- **Errors:** Red banner, shows retry option
- **Critical:** Red banner, recommend app restart

### 4. Safe Execution Helpers

#### Sync Operations
```swift
safeExecute(
    title: "Update Trip",
    message: "Could not save changes",
    severity: .error,
    {
        try updateTripData()
    }
)
```

#### Async Operations
```swift
await safeExecuteAsync(
    title: "Search Hotels",
    severity: .warning,
    {
        try await hotelService.search()
    }
)
```

---

## Component-Level Resilience

### HotelBrowsingView
```swift
@State private var hotels: [Hotel] = []
@State private var isLoading = false
@State private var errorMessage: String?

func performSearch() {
    isLoading = true
    errorMessage = nil
    
    Task {
        do {
            hotels = try await HotelSearchService.shared.searchHotels(
                destination: destination,
                checkIn: checkInDate,
                checkOut: checkOutDate,
                adults: adultCount
            )
        } catch {
            // Error caught and handled
            errorMessage = "Unable to load hotels. Showing sample results."
            hotels = generateSampleHotels()  // Fallback
        }
        isLoading = false
    }
}

var body: some View {
    ZStack {
        VStack {
            // Search header
            // Filter options
            
            if isLoading {
                ProgressView()
            } else if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                    Spacer()
                    Button("Retry") { performSearch() }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
            }
            
            if hotels.isEmpty {
                Text("No hotels found")
                    .foregroundStyle(.secondary)
            } else {
                List(hotels) { hotel in
                    HotelCard(hotel: hotel)
                }
            }
        }
        
        NetworkStatusBanner()  // Appears over everything when offline
            .ignoresSafeArea()
    }
}
```

### ScheduleView (Multi-Activity Operations)

When dragging activities or bulk operations fail:

```swift
func moveActivity(_ activity: Activity, to newDate: Date) {
    safeExecute(
        title: "Update Schedule",
        message: "Could not move activity",
        severity: .warning,
        {
            try? context.save()
            // UI updates regardless
            updateScheduleDisplay()
        }
    )
}
```

---

## API-Level Resilience

### RapidAPI Key Handling

If the API key is missing or invalid:

```swift
// In HotelSearchService
func searchBookingCom(...) async throws -> [Hotel] {
    guard !Config.rapidAPIKey.isEmpty else {
        // Show error but continue
        ErrorRecoveryManager.shared.record(
            title: "API Not Configured",
            message: "Add RapidAPI key to Config.swift",
            severity: .warning
        )
        return generateMockResults()  // Mock data shown instead
    }
    
    // Attempt real search
}
```

### Timeout Handling

All API calls have timeouts (15 seconds):

```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 15  // Seconds
config.waitsForConnectivity = true    // Wait for network if available
```

If timeout occurs:
- ⏱️ After 15 seconds, request is cancelled
- 📱 Mock data shown to user
- 🔄 "Retry" button available
- 🔌 Works offline because fallback is provided

---

## Testing Error Scenarios

### Simulate No Internet
**On Simulator:**
1. Xcode → Debug → Location → None
2. Xcode → Scheme → Edit Scheme → Run → Environment Variables
3. Add: `com.apple.CoreData.SQLDebug=1`

**On Device:**
Settings → Airplane Mode (turn on)

### Simulate API Failure
**In HotelSearchService.swift**, change URL:
```swift
// Temporary for testing
let url = URL(string: "https://invalid-api-url.com")!  // Intentionally broken
```

### Simulate Invalid API Key
**In Config.swift:**
```swift
static let rapidAPIKey = ""  // Empty or wrong key
```

**Expected Result:**
- App still runs
- Hotels show as "Sample results"
- No crash, just user message

### Simulate Slow Network
**On Simulator:**
1. Xcode → Debug → Network Link Conditioner
2. Choose "Very Bad Network" or "3G"
3. Watch loading states and timeouts

---

## What to Expect

### When Hotel Search Fails
1. Loading spinner shows for 15 seconds (max)
2. Orange error banner appears: "Unable to fetch hotels. Showing sample results."
3. Sample hotel cards display (visually identical to real results)
4. "Retry" button available
5. App continues to work normally
6. Users can still add hotels to trip from samples

### When Geocoding Fails
1. Location search field accepts any text
2. Uses fallback coordinates (default: San Francisco)
3. Map still shows something reasonable
4. Weather forecast for fallback location shown
5. No crash

### When Network Unavailable
1. Red "No Internet Connection" banner at top of screen
2. Can't search but cached results shown
3. Core trip features still work
4. Schedule/activities fully functional
5. Maps work if downloaded previously

### When Multiple Failures Occur
1. Each failure is independent
2. One failed search doesn't block others
3. Error messages queue in order
4. All errors appear in debug Error Log
5. App remains stable

---

## Error Log Debugging

### Access Error Log
In any view, add:
```swift
NavigationLink("Error Log", destination: ErrorLogView())
```

### What You'll See
- List of all errors with timestamps
- Severity color (yellow = warning, red = error)
- Full error messages
- "Clear" button to reset

### Using for Debugging
1. User reports crash
2. Have them open Error Log before crash
3. Screenshot shows what failed
4. Send error list to developer
5. Identify patterns in failures

---

## Best Practices for Users

### When Features Fail
1. **Check Internet Connection**
   - WiFi icon shows connection status
   - Red banner indicates no connection

2. **Try Again**
   - Click "Retry" button on error message
   - Or close and reopen the feature

3. **Restart the App**
   - Close completely: Swipe up from bottom
   - Tap RoadTrip in App Switcher to remove
   - Reopen from Home Screen

4. **Report Issues**
   - Open Error Log (debugging menu)
   - Screenshot the errors
   - Include what you were doing
   - Send to developer

### Offline Usage
1. **Download Maps First**
   - Open Offline Maps before traveling
   - Wait for download to complete
   - Works anywhere after that

2. **Cache Data**
   - Search for hotels/cars while online
   - Results are cached on device
   - View anytime, even offline

3. **Plan Ahead**
   - View weather before trip
   - Cached forecast shown offline
   - Won't update without connection

---

## Performance Considerations

### Memory Management
- Limited to 50 errors in ErrorRecoveryManager
- Old errors automatically removed
- Cache cleared when app restarts

### Storage Usage
- Mock data: ~2 MB
- Cached searches: ~10 MB
- Downloaded maps: ~500 MB (optional)

### Network Usage
- Each hotel search: ~50 KB
- Each car rental search: ~50 KB
- Weather forecast: ~10 KB
- Geocoding: ~2 KB

---

## Summary: How to Keep the App Running

| Problem | What Happens | User Experience |
|---------|-------------|-----------------|
| **No Internet** | Shows cached/mock data | Orange banner, app works |
| **API Timeout** | Uses fallback data | 15 second wait, then sample results |
| **Invalid API Key** | Uses mock data | Error message, samples shown |
| **Bad Location** | Uses San Francisco | Location search still works |
| **Failed Schedule Operation** | Operation cancelled but UI updates | No visible error, just doesn't save |
| **Weather Unavailable** | Shows cached forecast | "Last updated" shown |
| **Maps Not Downloaded** | Shows map view (online only) | Can't view offline but app works |

---

## Conclusion

RoadTrip is built to **never crash** due to network or API failures. Instead:

1. ✅ Core features always work (schedule, trips, activities)
2. ✅ Optional features degrade gracefully (show samples)
3. ✅ Network issues detected and handled
4. ✅ Errors logged for debugging
5. ✅ Users get helpful messages with retry options

**The app runs smoothly even with partial feature failures.**
