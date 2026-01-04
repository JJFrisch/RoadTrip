# RoadTrip Hotel & Car Rental Testing Guide

## Overview
This guide will help you test the new hotel and car rental search features that were recently implemented.

## Prerequisites
- RapidAPI key configured in `Config.swift` (already done: `876258fbf6mshab8de6e5cbf66edp188ec4jsnfb9851109a0a`)
- Active internet connection for API calls
- Location services enabled (optional, for geocoding)

## Feature 1: Hotel Search

### Test Case 1: Basic Hotel Search
1. **Navigate**: Open app → Select a trip → Choose a day → Tap schedule → Tap "Browse Hotels" button
2. **Setup Search**:
   - Location: "New York"
   - Check-in: Today
   - Check-out: Tomorrow
   - Guests: 2
3. **Execute**: Tap "Search Hotels"
4. **Verify**:
   - ✅ Console shows: `📍 Search coordinates: 40.xxx, -74.xxx`
   - ✅ Console shows: `✅ Found destination ID for new york`
   - ✅ Results appear with hotel cards
   - ✅ Each card shows: hotel name, rating, price, image (or placeholder)
   - ✅ Source badge shows "Booking.com"

### Test Case 2: Geocoding Error Handling
1. **Navigate**: Same as Test Case 1
2. **Setup Search**: 
   - Location: "asdfasdfasdf" (invalid city name)
3. **Execute**: Tap "Search Hotels"
4. **Verify**:
   - ✅ Alert appears: "Unable to find location 'asdfasdfasdf'..."
   - ✅ Console shows: `❌ Geocoding error`
   - ✅ Search still proceeds with fallback
   - ✅ Mock results appear

### Test Case 3: Hotel Filters
1. **Navigate**: Hotel search screen
2. **Apply Filters**:
   - Tap filter icon
   - Set price range: $100-$300
   - Set min rating: 8.0
   - Enable: WiFi, Parking, Breakfast
3. **Execute**: Tap "Apply" → Search
4. **Verify**:
   - ✅ Filter badge appears on filter button
   - ✅ Results respect filters (when API returns real data)
   - ✅ Clear filters removes all constraints

### Test Case 4: Hotel Detail View
1. **Navigate**: From search results, tap a hotel card
2. **Verify**:
   - ✅ Image carousel shows (with loading state → image or placeholder)
   - ✅ Hotel name, rating, stars displayed
   - ✅ Address and map location shown
   - ✅ Amenities listed with icons
   - ✅ Room details visible
   - ✅ Price breakdown shown
   - ✅ "Add to Trip" button present

### Test Case 5: Save Hotel to Trip
1. **Navigate**: Hotel detail view
2. **Execute**: Tap "Add to Trip"
3. **Verify**:
   - ✅ Confirmation alert appears
   - ✅ Activity created in trip day's schedule
   - ✅ Activity shows: hotel name, location, times, price
   - ✅ Activity icon is "bed.double.fill"

## Feature 2: Car Rental Search

### Test Case 6: Basic Car Search
1. **Navigate**: Trip detail → Menu (⋯) → "Browse Car Rentals"
2. **Setup Search**:
   - Pick-up: "Los Angeles"
   - Drop-off: "San Diego"
   - Pick-up date/time: Tomorrow 10:00 AM
   - Drop-off date/time: 3 days later 10:00 AM
   - Driver age: 30
3. **Execute**: Tap "Search Rentals"
4. **Verify**:
   - ✅ Console shows: `📍 Pick-up: 34.xxx, -118.xxx`
   - ✅ Console shows: `📍 Drop-off: 32.xxx, -117.xxx`
   - ✅ Results show car rental cards
   - ✅ Each card shows: car name, company, type, features, price
   - ✅ Images load (or show car icon placeholder)

### Test Case 7: Car Rental Filters
1. **Navigate**: Car rental search screen
2. **Apply Filters**:
   - Car type: "SUV"
   - Transmission: "Automatic"
   - Min seats: 5
   - Enable: Air conditioning, GPS, Unlimited mileage
3. **Execute**: Tap "Apply" → Search
4. **Verify**:
   - ✅ Filter badge shows on filter button
   - ✅ Results match filter criteria (when API returns real data)

### Test Case 8: Car Rental Detail View
1. **Navigate**: From search results, tap a car card
2. **Verify**:
   - ✅ Car image shows (or car icon placeholder)
   - ✅ Car name, company, type displayed
   - ✅ Rating and review count shown
   - ✅ Specs grid: passengers, doors, transmission, fuel
   - ✅ Features list with icons (AC, GPS, unlimited mileage, etc.)
   - ✅ Rental period summary
   - ✅ Price breakdown (daily + total)
   - ✅ Insurance options listed
   - ✅ Pickup/dropoff details
   - ✅ "Add to Trip" button present

### Test Case 9: Save Car Rental to Trip
1. **Navigate**: Car rental detail view
2. **Execute**: Tap "Add to Trip"
3. **Verify**:
   - ✅ Confirmation alert appears
   - ✅ Activity created on pickup date
   - ✅ Activity shows: car name, company, times, price
   - ✅ Activity icon is "car.fill"
   - ✅ Activity notes include rental details

## Feature 3: Geocoding & Location Services

### Test Case 10: Multiple City Formats
Test these location strings to verify geocoding and destination ID lookup:

| Input | Expected Coordinates | Expected Dest ID |
|-------|---------------------|------------------|
| "New York" | ~40.7128, -74.0060 | 20088325 |
| "New York, NY" | ~40.7128, -74.0060 | 20088325 |
| "NYC" | ~40.7128, -74.0060 | (fallback) |
| "Los Angeles" | ~34.0522, -118.2437 | 20033173 |
| "LA" | ~34.0522, -118.2437 | (fallback) |
| "San Francisco" | ~37.7749, -122.4194 | -553173 |
| "SF" | ~37.7749, -122.4194 | (fallback) |
| "Chicago" | ~41.8781, -87.6298 | 20033173 |
| "Miami" | ~25.7617, -80.1918 | 20023181 |
| "Seattle" | ~47.6062, -122.3321 | 20069211 |

**Execute**: For each city:
1. Enter in hotel search location field
2. Tap search
3. Check console logs

**Verify**:
- ✅ Geocoding succeeds with reasonable coordinates
- ✅ Destination ID matches or uses fallback
- ✅ Search proceeds without errors

### Test Case 11: Geocoding Cache
1. **Execute**:
   - Search "New York" in hotels
   - Wait for results
   - Change dates and search "New York" again
2. **Verify**:
   - ✅ Second search is faster (cached coordinates)
   - ✅ Console shows cache hit (if logging added)

## Feature 4: Image Loading

### Test Case 12: Async Image Loading
1. **Navigate**: Any hotel or car search results
2. **Observe**: Image loading states
3. **Verify**:
   - ✅ Initial state shows progress indicator (spinner)
   - ✅ Success state shows loaded image
   - ✅ Failure state shows icon placeholder (photo/car icon)
   - ✅ No images crash or freeze the UI
   - ✅ Scrolling remains smooth during image loads

## Feature 5: Error Handling

### Test Case 13: Network Errors
1. **Setup**: Disable WiFi/cellular data
2. **Execute**: Search for hotels or cars
3. **Verify**:
   - ✅ Mock data appears (fallback behavior)
   - ✅ No crashes
   - ✅ User can still browse mock results

### Test Case 14: API Errors
1. **Setup**: Temporarily change API key in Config.swift to invalid value
2. **Execute**: Search for hotels
3. **Verify**:
   - ✅ Console shows API error
   - ✅ Mock data appears
   - ✅ App remains functional

## Console Log Cheatsheet

### Expected Logs (Success):
```
📍 Search coordinates: 37.7749, -122.4194
✅ Found destination ID for san francisco: -553173
🌍 Searching Booking.com with dest_id: -553173
```

### Expected Logs (Geocoding Error):
```
❌ Geocoding error: The operation couldn't be completed...
⚠️ No destination ID found for xyz, using default
🌍 Searching Booking.com with dest_id: -553173
```

### Expected Logs (Destination ID Fallback):
```
📍 Search coordinates: 40.7128, -74.0060
⚠️ No destination ID found for new york city, using default
✅ Partial match found for new york city: new york -> 20088325
```

## Known Issues & Limitations

1. **Mock Data**: If API keys are invalid or network fails, mock data appears. Real data requires valid RapidAPI subscription.

2. **Image URLs**: Some hotels/cars may not have image URLs in API response, showing placeholders instead.

3. **Geocoding Accuracy**: CLGeocoder may not find very specific or misspelled locations. App falls back gracefully.

4. **Destination ID Coverage**: ~50 US cities have explicit destination IDs. Others use API search or default to San Francisco.

5. **API Rate Limits**: Free RapidAPI tier has request limits. Excessive testing may hit these limits.

## Feature 6: Dynamic Destination ID Lookup

### Test Case 15: Dynamic Destination Search
1. **Navigate**: Hotel search
2. **Setup Search**:
   - Location: "Boulder, Colorado" (not in local database)
3. **Execute**: Search for hotels
4. **Verify**:
   - ✅ Console shows: `⚠️ No local destination ID found for boulder, colorado`
   - ✅ Console shows: `🔍 Searching Booking.com for destination: Boulder, Colorado`
   - ✅ Console shows: `✅ Found destination via API: Boulder -> [dest_id]`
   - ✅ Search proceeds with correct destination

### Test Case 16: Destination ID Caching
1. **Execute**:
   - Search "Boulder, Colorado" (triggers API lookup)
   - Search "Boulder, Colorado" again
2. **Verify**:
   - ✅ Second search is faster
   - ✅ Console shows: `✅ Found cached destination ID for boulder, colorado`

## Feature 7: Network Status & Error UI

### Test Case 17: Network Status Banner
1. **Setup**: Enable airplane mode or disable WiFi
2. **Navigate**: Open hotel or car rental search
3. **Verify**:
   - ✅ Red banner appears: "No Internet Connection"
   - ✅ Banner shows: "Showing cached or sample data"
   - ✅ Banner can be dismissed with X button
   - ✅ Banner reappears when network status changes

### Test Case 18: Error UI with Retry
1. **Setup**: Disable network (airplane mode)
2. **Execute**: Search for hotels
3. **Verify**:
   - ✅ Error state shows with orange warning icon
   - ✅ "Retry Search" button is displayed
   - ✅ "Use Sample Data" button is displayed
   - ✅ Tapping Retry re-executes search
   - ✅ Tapping Sample Data loads mock results

### Test Case 19: Empty Results Retry
1. **Execute**: Search for hotels in an obscure location
2. **Verify**:
   - ✅ "No Hotels Found" message displays
   - ✅ "Try Again" button is present
   - ✅ Tapping Try Again re-executes search

### Test Case 20: Error Alert with Retry
1. **Setup**: Cause a geocoding error (invalid location)
2. **Verify**:
   - ✅ Alert dialog appears with error message
   - ✅ "Retry" button is available in alert
   - ✅ "OK" button dismisses without retry
   - ✅ Tapping Retry attempts search again

## Tips for Best Testing Results

- **Use Real City Names**: "Los Angeles" works better than "LA"
- **Check Console**: Most debugging info is in Xcode console with emoji indicators
- **Test on Device**: Geocoding works best on real devices vs simulator
- **Allow Time**: First searches take longer (no cache)
- **Valid Dates**: Use future dates for realistic results
- **Test Network**: Toggle airplane mode to test offline behavior

## Success Criteria

All features working correctly when:
- ✅ Hotel search returns results for major US cities
- ✅ Car rental search shows available vehicles
- ✅ Filters and sorting work as expected
- ✅ Activities save to trip schedule correctly
- ✅ Geocoding finds coordinates for city names
- ✅ Dynamic destination ID lookup works for unknown cities
- ✅ Images load or show appropriate placeholders
- ✅ Errors display user-friendly alerts with retry options
- ✅ Network status banner shows when offline
- ✅ Console logs help debugging without overwhelming output

## Automated Testing Notes

While this is a manual testing guide, key areas for unit tests:
- `GeocodingService.geocode()` - coordinate lookup
- `BookingDestinationService.getDestinationId()` - city matching
- `BookingDestinationService.searchDestination()` - API destination search
- `HotelSearchService.searchHotels()` - API integration
- `CarRentalSearchService.searchCarRentals()` - API integration
- `NetworkMonitor.isConnected` - network status detection
- Filter logic in both services

## Report Issues

When reporting issues, include:
1. Test case number
2. Steps to reproduce
3. Expected vs actual behavior
4. Console log output
5. Screenshots (if UI issue)
