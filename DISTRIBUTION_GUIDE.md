# RoadTrip App Distribution Guide

This guide explains how to package and distribute your RoadTrip app to other users without requiring them to have Xcode.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Distribution Options](#distribution-options)
3. [TestFlight (Recommended)](#testflight-recommended)
4. [Direct File Sharing](#direct-file-sharing)
5. [Build Instructions for Users](#build-instructions-for-users)
6. [Troubleshooting](#troubleshooting)

---

## Quick Start

**Fastest way to get your app to others:**

```bash
# Build for release
xcodebuild -scheme RoadTrip -configuration Release -derivedDataPath ./build

# App will be at: ./build/Release-iphoneos/RoadTrip.app
# Share this with users
```

---

## Distribution Options

### Option 1: TestFlight (✅ Recommended)
- **Best for:** Friends, family, beta testers
- **Users need:** Just TestFlight app (free on App Store) and an Apple ID
- **Your cost:** $99/year Apple Developer account
- **Setup time:** 5-10 minutes
- **Pros:** Automatic updates, works over the air, easy to manage
- **Cons:** Requires developer account

### Option 2: Share .app File
- **Best for:** Single user or small group testing
- **Users need:** Xcode or Apple Configurator 2
- **Your cost:** Free
- **Setup time:** 2 minutes
- **Pros:** Direct file sharing, no accounts needed
- **Cons:** Users need Xcode, manual installation

### Option 3: Create .ipa File (Advanced)
- **Best for:** Enterprise distribution or app store submission
- **Users need:** Apple Configurator 2 or custom MDM
- **Your cost:** $99-299/year developer account
- **Setup time:** 10-15 minutes
- **Pros:** Professional package format
- **Cons:** More complex setup

### Option 4: GitHub Release
- **Best for:** Open source / developer community
- **Users need:** GitHub account and Xcode
- **Your cost:** Free
- **Setup time:** 5 minutes
- **Pros:** Version control, community feedback
- **Cons:** Users still need Xcode

---

## TestFlight (Recommended)

### Prerequisites
- Apple Developer Account ($99/year) - [Sign up here](https://developer.apple.com/enroll/)
- App Store Connect access

### Step 1: Archive Your App

In Xcode:
1. Select **Product** → **Scheme** → **RoadTrip**
2. Select **Product** → **Destination** → **Any iOS Device (arm64)**
3. Select **Product** → **Archive**
4. Wait for build to complete
5. Xcode automatically opens the Organizer window

### Step 2: Upload to App Store Connect

In the Organizer window:
1. Select your latest build
2. Click **Distribute App**
3. Choose **App Store Connect**
4. Select **Upload**
5. Keep all default settings
6. Agree to terms and upload

**⏱️ Wait 5-15 minutes for processing**

### Step 3: Create TestFlight Link

In App Store Connect (on web):
1. Go to your app
2. Click **TestFlight** tab
3. Click **+ Add Group**
4. Name it (e.g., "Friends & Family")
5. Click **Create**
6. Click **+ Add Testers**
7. Enter email addresses of people you want to test

### Step 4: Share with Users

Users will receive an email with:
- Link to install TestFlight
- Link to join your beta
- Instructions to download your app

**That's it!** Users install TestFlight (free) and can immediately run your app.

#### Updating the App
When you want to send an update:
```bash
xcodebuild -scheme RoadTrip -configuration Release archive
# Upload new archive to App Store Connect following Step 2
```
Users will automatically receive the update notification in TestFlight.

---

## Direct File Sharing

### Method 1: Share the .app File

Build the app:
```bash
xcodebuild -scheme RoadTrip -configuration Release -derivedDataPath ./build
```

Your app is at:
```
./build/Release-iphoneos/RoadTrip.app
```

**Recipient Steps:**
1. Download the .app file
2. Open Xcode
3. Go to **Window** → **Devices and Simulators**
4. Connect iPhone
5. Select iPhone in the left panel
6. Click **+** (plus button) in the "Installed Apps" section
7. Select the RoadTrip.app file
8. Wait for installation to complete

### Method 2: Share via GitHub Releases

1. Commit your code to GitHub
2. Create a new Release:
   ```bash
   git tag -a v1.0.0 -m "Initial Release"
   git push origin v1.0.0
   ```
3. Go to GitHub → Releases
4. Create release notes
5. Upload the .app file as a binary
6. Share the release link

---

## Build Instructions for Users

If users want to build the app themselves from source:

### Prerequisites
1. Xcode (free, 10+ GB)
   - Download from App Store or [developer.apple.com](https://developer.apple.com/download/)
2. Apple Developer Account ($99/year for device deployment)
3. Verified Apple ID on their computer

### Step-by-Step Build

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd RoadTrip
   ```

2. **Open in Xcode:**
   ```bash
   open RoadTrip.xcodeproj
   ```

3. **Configure signing:**
   - Select **RoadTrip** project in left panel
   - Select **RoadTrip** target
   - Go to **Signing & Capabilities** tab
   - Ensure **Automatically manage signing** is checked
   - Select their Apple ID from Team dropdown

4. **Connect iPhone:**
   - Plug iPhone into Mac via USB
   - Trust the computer on the phone

5. **Select device:**
   - Top of Xcode window: Select "RoadTrip" → Your iPhone name

6. **Build and run:**
   - Press **Cmd + R** or click Play button
   - Wait for build (2-5 minutes)
   - App launches on phone automatically

### Troubleshooting User Builds

**Error: "Could not locate device"**
- Try unplugging USB and plugging back in
- Restart Xcode

**Error: "Failed to prepare device for development"**
- Open Settings > General > VPN & Device Management on phone
- Tap the Apple ID profile
- Select Trust

**Error: "Command line tools not found"**
- Open Terminal and run:
  ```bash
  xcode-select --install
  ```

**App disappears after restarting phone**
- This is normal for development builds
- User must rebuild to reinstall
- Explain they'd need a real developer account to make it permanent

---

## Creating an .ipa File (Advanced)

If you need to distribute a more professional package:

### Step 1: Create Export Options

Create a file named `ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

Replace `YOUR_TEAM_ID` with your Apple ID's Team ID.

### Step 2: Build Archive

```bash
xcodebuild -scheme RoadTrip -configuration Release \
  -archivePath ./build/RoadTrip.xcarchive archive
```

### Step 3: Export to .ipa

```bash
xcodebuild -exportArchive \
  -archivePath ./build/RoadTrip.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ./build/Release
```

This creates:
```
./build/Release/RoadTrip.ipa
```

### Step 4: Distribute .ipa

Users can install with:
- **Apple Configurator 2** (Mac App Store, free)
  1. Connect iPhone
  2. Drag .ipa file onto Configurator
  3. Click Install

---

## Recommended Workflow

### For Testing with Small Group (Recommended)
1. **Use TestFlight**
2. Invite testers via email
3. They get automatic updates
4. You get crash reports

### For Open Source / Community
1. **Use GitHub Releases**
2. Build .app file
3. Upload to releases page
4. Users can download and follow "Build Instructions"

### For Close Friends / Quick Share
1. **Build .app file**
2. Upload to Google Drive or Dropbox
3. Share link
4. They use Apple Configurator 2 to install

---

## Helpful Commands

### Build for Device
```bash
xcodebuild -scheme RoadTrip -configuration Release \
  -derivedDataPath ./build
```

### Build for Simulator
```bash
xcodebuild -scheme RoadTrip -configuration Release \
  -derivedDataPath ./build \
  -sdk iphonesimulator
```

### Clean Build
```bash
xcodebuild clean -scheme RoadTrip -derivedDataPath ./build
```

### List Available Schemes
```bash
xcodebuild -list -project RoadTrip.xcodeproj
```

---

## Troubleshooting

### "Code Signing Error"
**Solution:** 
1. Product → Scheme → Edit Scheme
2. Build → Code Signing Identity → Automatic

### "App crashes immediately on launch"
1. Check Console.app for error messages
2. Run in Xcode with device connected to see full logs
3. Enable Debug settings in Info.plist if needed

### "API calls not working for recipients"
Ensure:
1. RapidAPI key is set in `Config.swift`
2. Network requests work on your device
3. Users have internet connection
4. Booking.com API is still available

### "Offline features not working"
This is expected. Offline mode requires:
1. Maps downloaded before going offline
2. Previous search results cached
3. Mock data available

### "Installation takes forever"
1. Reduce app size by removing unused assets
2. Check internet connection speed
3. iPhone storage should be > 2GB free
4. Try restarting both devices

---

## Security & Privacy

### Before Distribution

1. **Remove debug keys:**
   - Change `Config.rapidAPIKey` in build scheme
   - Or use environment variables

2. **Privacy Policy:**
   - Required for App Store
   - Add in Settings bundle

3. **Data Privacy:**
   - App Store submission requires data usage disclosure
   - TestFlight doesn't require this

### For Testers

Tell them:
- "This is a beta/development build"
- "Data may be lost during updates"
- "Please report crashes and bugs"
- "Don't share with others without permission"

---

## Summary

| Method | Cost | Setup Time | Best For | Users Need |
|--------|------|-----------|----------|-----------|
| **TestFlight** | $99/yr | 10 min | Beta testing | Apple ID + TestFlight |
| **.app File** | Free | 2 min | Small group | Xcode or Configurator |
| **.ipa File** | $99/yr | 15 min | Enterprise | Configurator or MDM |
| **GitHub** | Free | 5 min | Open source | Xcode + Git |
| **User Build** | Free | 10 min | Developers | Xcode + setup |

**Recommendation:** Use **TestFlight** for the best user experience with automatic updates and crash reports.

---

## Next Steps

1. Choose a distribution method above
2. Follow the corresponding instructions
3. Test with a friend first
4. Document any issues in TROUBLESHOOTING_GUIDE.md

Questions? Check the troubleshooting section above or review Apple's [official distribution guide](https://help.apple.com/xcode/mac/current/#/dev754d3d58d).
