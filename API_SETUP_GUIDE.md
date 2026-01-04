# API Integration Setup Guide

## Overview
This guide will help you set up Google Places API and Mapbox for the RoadTrip app.

## 1. Google Places API Setup

### Get Your API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - **Places API (New)**
   - **Geocoding API** (for address to coordinates)
4. Create credentials:
   - Click "Credentials" in the left sidebar
   - Click "Create Credentials" → "API Key"
   - Copy your API key

### Secure Your API Key
**Important:** Never commit API keys to version control!

**Option 1: Info.plist (Recommended)**

**First Time Setup:**
1. Copy `Info.plist.template` to `RoadTrip/Info.plist`
   ```bash
   cp Info.plist.template RoadTrip/Info.plist
   ```
2. Open `RoadTrip/Info.plist` in Xcode or a text editor
3. Replace `YOUR_GOOGLE_PLACES_API_KEY_HERE` with your actual API key
4. **Note:** `Info.plist` is already in `.gitignore` and won't be committed to GitHub

**Setting Up on Another Machine (e.g., Your Mac):**
1. Pull the latest code from GitHub
2. Copy the template file:
   ```bash
   cp Info.plist.template RoadTrip/Info.plist
   ```
3. Open `RoadTrip/Info.plist` and add your API key
4. Build and run the project

**Option 2: Environment Variable**
1. In Xcode, go to Product → Scheme → Edit Scheme
2. Select "Run" → "Arguments"
3. Add Environment Variable:
   - Name: `GOOGLE_PLACES_API_KEY`
   - Value: Your API key

**Option 3: Config.swift (Development Only)**
1. Open `RoadTrip/Config.swift`
2. Replace `YOUR_API_KEY_HERE` with your key
3. **Never commit this file!**

### Restrict Your API Key (Security)
1. In Google Cloud Console, click on your API key
2. **Important:** This app currently calls the **Places API (New)** HTTP v1 endpoints via `URLSession` (see `RoadTrip/Services/GooglePlacesService.swift`).
   - If you set **Application restrictions → iOS apps**, Google will expect the native iOS key verification fields used by the SDK, and your Web Service requests may be denied.
3. Recommended restrictions for this implementation:
   - **Application restrictions:** *None* (or use a backend/proxy if you want to lock by IP)
   - **API restrictions:** *Restrict key* to **Places API (New)** and **Geocoding API**

### Free Tier Limits
- **Places Nearby Search**: $17/1000 requests (first $200/month free)
- **Place Details**: $17/1000 requests
- **Geocoding**: $5/1000 requests
- **Free monthly credit**: $200 (~11,000 searches)

### Cost Optimization Tips
1. **Cache results** - Already implemented in `LocationCache`
2. **Use fields parameter** - Only request needed data
3. **Implement pagination** - Don't load all results at once
4. **Set usage quotas** - In Google Cloud Console

## 2. Mapbox Setup

### Get Your Access Token
1. Go to [Mapbox Account](https://account.mapbox.com/)
2. Sign up for a free account
3. Go to [Access Tokens](https://account.mapbox.com/access-tokens/)
4. Copy your default public token OR create a new one

### Add Token to Project

**Option 1: Info.plist (Recommended)**

Add to your `RoadTrip/Info.plist` file (not the template):
```xml
<key>MAPBOX_ACCESS_TOKEN</key>
<string>pk.YOUR_TOKEN_HERE</string>
```

**Option 2: Config.swift**
Replace `YOUR_MAPBOX_TOKEN_HERE` in `Config.swift` (also in `.gitignore`)

### Install Mapbox SDK (When Ready for Production)

The current implementation is a placeholder. To enable real offline maps:

**Via Swift Package Manager:**
1. In Xcode: File → Add Package Dependencies
2. Enter: `https://github.com/mapbox/mapbox-maps-ios.git`
3. Version: 11.0.0 or later
4. Uncomment the Mapbox code in `MapboxOfflineManager.swift`

**Via CocoaPods:**
```ruby
pod 'MapboxMaps', '~> 11.0'
```

### Free Tier Limits
- **25,000 map loads/month** - Free
- **Offline tile downloads** - Included in free tier
- **Storage** - Unlimited offline tiles on device

### Mapbox Features
- Street maps, satellite, terrain, outdoors styles
- Offline tile packs for entire regions
- Turn-by-turn navigation (optional add-on)
- Custom map styling

## 3. Testing Your Setup

### Test Google Places API
1. Run the app
2. Navigate to any day
3. Tap "Import Activities" → "Nearby POIs"
4. If configured correctly, you'll see real places

### Test Offline Maps
1. Go to any trip
2. Tap the menu (•••) → "Offline Maps"
3. Enter a region name and tap "Download"
4. Note: Real downloads require Mapbox SDK (currently placeholder)

### Check Configuration
Run this in your app to verify:
```swift
print("Google Places API Key valid:", Config.hasValidGooglePlacesKey)
print("Mapbox Token valid:", Config.hasValidMapboxToken)
```

## 4. Error Handling

The app now includes comprehensive error handling:

- **Network check before API calls**
- **Retry logic** with exponential backoff
- **User-friendly error messages**
- **Cellular data warnings** for large downloads

## 5. Migration Notes

### Activity Model Changes
New fields added to `Activity`:
- `latitude`, `longitude` - GPS coordinates
- `placeId` - Google Places ID
- `sourceType` - Import source ("google", "tripadvisor", "manual")
- `importedAt` - When imported
- `rating`, `photoURL`, `website`, `phoneNumber` - Additional details

**SwiftData will automatically migrate existing data** - old activities will have `nil` for new fields.

## 6. Privacy & App Store

### Required Info.plist Keys
Add these for App Store submission:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to find nearby attractions and optimize your trip route.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Allow location access to download offline maps and provide turn-by-turn directions.</string>
```

### Privacy Manifest
If using Google Places API, add to `PrivacyInfo.xcprivacy`:
- Reason for network access: "Third-party API integration"
- Data collected: Location data (user consented)

## 7. Production Checklist

Before releasing to App Store:

- [ ] API keys moved to secure location (not in code)
- [ ] `.gitignore` includes `Info.plist` or use `.xcconfig`
- [ ] API key restrictions enabled (iOS bundle ID)
- [ ] Usage quotas set in Google Cloud Console
- [ ] Privacy manifest and location permissions configured
- [ ] Error handling tested (airplane mode, invalid keys)
- [ ] Offline mode tested thoroughly
- [ ] Cost monitoring enabled in Google Cloud Console

## 8. Troubleshooting

### "Invalid API Key" Error
- Check that key is correctly copied
- Verify key is not restricted to wrong bundle ID
- Ensure Places API is enabled in Google Cloud Console

### "No Results" for Nearby Search
- Check device has location permissions
- Verify coordinates are valid
- Try increasing search radius
- Check Google Cloud Console for API errors

### Mapbox Downloads Not Working
- Verify token starts with `pk.`
- Check network connection
- Ensure storage space available
- Look for errors in console logs

### Import Returns Empty Results
- Check API key validity: `Config.hasValidGooglePlacesKey`
- Verify network connection
- Try different search location/radius
- Check API quota in Google Cloud Console

## 9. Alternative Options

### Free Alternatives
1. **OpenStreetMap** - Free, open-source map data
   - Nominatim API for geocoding
   - No API key required, but rate-limited
   
2. **Apple MapKit** - Already integrated
   - Free for basic features
   - Limited POI data compared to Google

### Cost Comparison
| Service | Free Tier | Paid Pricing |
|---------|-----------|--------------|
| Google Places | $200/month credit | $5-17/1000 requests |
| Mapbox | 25k loads/month | $0.25/1000 beyond |
| Apple MapKit | Unlimited | Free |

## 10. Next Steps

After setup:
1. Test import with real data
2. Download sample offline map region
3. Monitor API usage in dashboards
4. Implement caching optimizations
5. Add analytics for popular features

## Support

- Google Places API: https://developers.google.com/maps/documentation/places
- Mapbox Documentation: https://docs.mapbox.com/
- Report issues: Create GitHub issue in this repository
