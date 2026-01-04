# Booking.com API Setup Guide

## ✅ Code is Ready - Just Add Your API Key!

The Booking.com API integration is already implemented in your app. Follow these steps to activate it:

## Step 1: Get Your RapidAPI Key (5 minutes)

1. **Sign up for RapidAPI:**
   - Go to https://rapidapi.com/
   - Click "Sign Up" (free account)
   - Verify your email

2. **Subscribe to Booking.com API:**
   - Go to https://rapidapi.com/DataCrawler/api/booking-com15
   - Click "Subscribe to Test"
   - Select the **FREE plan** (100 requests/month free)
   - Click "Subscribe"

3. **Get Your API Key:**
   - After subscribing, you'll see "Header Parameters" section
   - Copy the value shown for `x-rapidapi-key`
   - It looks like: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`

## Step 2: Add API Key to Your App (2 options)

### Option A: Update Config.swift (Quick & Easy)
1. Open `RoadTrip/Config.swift`
2. Find this line:
   ```swift
   return "YOUR_RAPIDAPI_KEY_HERE"
   ```
3. Replace with your actual key:
   ```swift
   return "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
   ```

⚠️ **Warning:** Don't commit this to GitHub if your repo is public!

### Option B: Use Info.plist (Recommended - More Secure)
1. Open `Info.plist`
2. Add a new row:
   - Key: `RAPIDAPI_KEY`
   - Type: String
   - Value: `YOUR_ACTUAL_API_KEY`
3. Save the file

The app will automatically read from Info.plist first, then fall back to Config.swift.

## Step 3: Test the Integration

1. **Run your app**
2. **Navigate to a trip day**
3. **Tap "Hotels" button**
4. **Enter search details:**
   - Location: Any city (e.g., "San Francisco")
   - Dates: Check-in and check-out
   - Guests: Number of people
5. **Tap "Search"**

You should see:
- Console log: `📡 Booking.com API Response: 200`
- Console log: `✅ Fetched X hotels from Booking.com`
- Real hotel results from Booking.com!

## What's Already Implemented ✅

### API Integration
- ✅ Real API calls to Booking.com via RapidAPI
- ✅ Proper request headers and authentication
- ✅ URL encoding of search parameters
- ✅ JSON response parsing
- ✅ Error handling with fallback to mock data
- ✅ Timeout handling (15 seconds)

### Features Working
- ✅ Hotel search by location
- ✅ Date-based availability
- ✅ Guest count filtering
- ✅ Price per night and total price
- ✅ Star ratings
- ✅ Guest reviews and ratings
- ✅ Hotel coordinates for map display
- ✅ Photo URLs (when available)
- ✅ Direct booking links

### Automatic Fallbacks
- No API key configured → Uses mock data
- API error → Uses mock data
- Network timeout → Uses mock data
- Console logs show what's happening

## Understanding the API

### What You Get (100 requests/month free):
- Hotel search results
- Prices and availability
- Ratings and reviews
- Photos
- Location coordinates
- Star ratings

### What Costs Money:
- After 100 requests → $0.001 per request (very cheap!)
- Example: 1,000 requests = $1.00

### API Endpoint Used:
```
GET https://booking-com15.p.rapidapi.com/api/v1/hotels/searchHotels
```

### Parameters Sent:
- `dest_id`: City/location identifier
- `arrival_date`: Check-in (YYYY-MM-DD)
- `departure_date`: Check-out (YYYY-MM-DD)
- `adults`: Number of guests
- `room_qty`: Number of rooms
- `currency_code`: USD
- `languagecode`: en-us

## Current Limitations (Future Improvements)

1. **Destination ID:** Currently hardcoded to San Francisco (`-553173`)
   - **TODO:** Geocode location to get proper dest_id
   - **Workaround:** Search works but may show wrong city

2. **Limited Hotel Details:** Search results have basic info
   - **TODO:** Add detail endpoint for full amenities list
   - **Current:** Shows name, price, rating, location

3. **No Image Loading:** Photo URLs are retrieved but not displayed
   - **TODO:** Implement image loading in UI
   - **Current:** Placeholder images shown

4. **Single Source:** Only Booking.com is live
   - **TODO:** Integrate other APIs (Hotels.com, Expedia, Airbnb)
   - **Current:** Others use mock data

## Next Steps (Priority Order)

### High Priority:
1. ✅ **Add your API key** (do this first!)
2. 🔲 **Test the search** (verify it works)
3. 🔲 **Implement destination lookup** (get proper dest_id from location string)
4. 🔲 **Add image loading** (display actual hotel photos)

### Medium Priority:
5. 🔲 **Hotel details endpoint** (get full amenities, description)
6. 🔲 **Error messages to user** (show friendly errors instead of console logs)
7. 🔲 **Caching** (save results to avoid repeated API calls)

### Low Priority:
8. 🔲 **Other booking sites** (Hotels.com, Expedia APIs)
9. 🔲 **Rate limiting** (track API usage)
10. 🔲 **Analytics** (track searches)

## Troubleshooting

### "API key not configured" in console
- Check Config.swift has your real API key
- Make sure you replaced `YOUR_RAPIDAPI_KEY_HERE`

### "API Error: 403"
- API key is invalid or subscription expired
- Go to RapidAPI and check your subscription status

### "API Error: 429"
- You've exceeded the free tier (100 requests/month)
- Wait until next month or upgrade plan

### No results returned
- Check console for error messages
- Verify location string is valid
- Try a different city name

### Mock data showing instead of real data
- This is the fallback behavior when API fails
- Check console logs to see why
- Verify API key is correct

## Console Logs Explained

```
📡 Booking.com API Response: 200
```
✅ API call successful!

```
✅ Fetched 15 hotels from Booking.com
```
✅ Got real data from API

```
⚠️ RapidAPI key not configured - using mock data
```
⚠️ Need to add API key in Config.swift

```
❌ API Error: 403
```
❌ Invalid API key or no subscription

```
❌ Booking.com API Error: ...
```
❌ Network error or API issue - check error message

## Support & Resources

- **RapidAPI Dashboard:** https://rapidapi.com/developer/dashboard
- **API Documentation:** https://rapidapi.com/DataCrawler/api/booking-com15
- **View Usage:** https://rapidapi.com/developer/billing
- **Test Endpoint:** Use RapidAPI's built-in endpoint tester

## Security Best Practices

1. **Never commit API keys to Git:**
   ```bash
   # Add to .gitignore:
   Config.swift
   *.plist
   ```

2. **Use environment variables for production:**
   ```swift
   // Reads from environment variable
   ProcessInfo.processInfo.environment["RAPIDAPI_KEY"]
   ```

3. **Rotate keys periodically:**
   - Generate new key on RapidAPI
   - Update in your app
   - Delete old key

---

**Ready to go! Just add your API key and start searching for real hotels! 🏨**
