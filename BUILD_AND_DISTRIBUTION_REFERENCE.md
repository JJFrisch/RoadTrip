# Quick Reference: Build & Distribution Commands

## Build Commands

### Build for Device (Release)
```bash
xcodebuild -scheme RoadTrip -configuration Release -derivedDataPath ./build
```
**Output:** `./build/Release-iphoneos/RoadTrip.app`

### Build for Simulator
```bash
xcodebuild -scheme RoadTrip -configuration Release -derivedDataPath ./build -sdk iphonesimulator
```

### Clean Build
```bash
xcodebuild clean -scheme RoadTrip -derivedDataPath ./build
xcodebuild -scheme RoadTrip -configuration Release -derivedDataPath ./build
```

### Archive for App Store
In Xcode:
1. Product → Destination → Any iOS Device (arm64)
2. Product → Archive
3. Organizer opens automatically
4. Click Distribute App → App Store Connect

---

## Distribution Methods at a Glance

### TestFlight (Recommended) ⭐
```
Prerequisites: Apple Developer Account ($99/year)
Time: 10 minutes
Users get: Automatic updates, crash reports

Steps:
1. Archive app in Xcode (Product → Archive)
2. Upload to App Store Connect
3. Create TestFlight group
4. Invite testers by email
5. Users install TestFlight app and download your app
```

### Share .app File
```
Prerequisites: None (free)
Time: 2 minutes
Users get: Direct app file

Steps:
1. Build: xcodebuild -scheme RoadTrip -configuration Release -derivedDataPath ./build
2. Share: ./build/Release-iphoneos/RoadTrip.app
3. Users: Open in Xcode or Apple Configurator 2
4. Users: Connect iPhone and install
```

### Create .ipa File
```
Prerequisites: ExportOptions.plist (provided in guide)
Time: 5 minutes

Steps:
1. xcodebuild -scheme RoadTrip -configuration Release -archivePath ./build/RoadTrip.xcarchive archive
2. xcodebuild -exportArchive -archivePath ./build/RoadTrip.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath ./build/Release
3. Share: ./build/Release/RoadTrip.ipa
```

### GitHub Release
```
Prerequisites: GitHub account, git
Time: 5 minutes

Steps:
1. Build .app file (see Build Commands above)
2. git tag -a v1.0.0 -m "Initial Release"
3. git push origin v1.0.0
4. GitHub → Releases → Create Release
5. Upload RoadTrip.app as binary
6. Share release link
```

### Build Instructions for Users
```
Prerequisites: Xcode, Apple ID
Time: 10 minutes for user

User Steps:
1. git clone <repo>
2. open RoadTrip.xcodeproj
3. Select their device in Xcode
4. Product → Run (or press Cmd+R)
```

---

## Recommended Workflow

### Development → Testing → Release

```
┌─────────────────────────────────────────────────────────────┐
│ 1. DEVELOPMENT (Local)                                      │
├─────────────────────────────────────────────────────────────┤
│ - Make changes in Xcode                                     │
│ - Test on simulator or personal device                      │
│ - Build: xcodebuild -scheme RoadTrip ...                    │
│ - Commit: git commit -m "Feature: ..."                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. BETA TESTING (TestFlight)                                │
├─────────────────────────────────────────────────────────────┤
│ - Push to GitHub main branch                                │
│ - Archive in Xcode (Product → Archive)                      │
│ - Upload to App Store Connect                               │
│ - Create TestFlight group                                   │
│ - Invite testers (3-20 people)                              │
│ - Monitor crash reports                                     │
│ - Iterate on feedback                                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. RELEASE (App Store or Direct)                            │
├─────────────────────────────────────────────────────────────┤
│ Option A: App Store Connect                                 │
│ - Submit from TestFlight build                              │
│ - Fill in screenshots and description                       │
│ - Wait 24-48 hours for review                               │
│ - Launch when approved                                      │
│                                                             │
│ Option B: GitHub Release                                    │
│ - Create version tag (v1.0.0)                               │
│ - Create GitHub release                                     │
│ - Upload .app or .ipa file                                  │
│ - Share link                                                │
│                                                             │
│ Option C: Direct Share                                      │
│ - Build .app file                                           │
│ - Share via Drive/Dropbox                                   │
│ - Users install via Xcode                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## Troubleshooting Commands

### Check if Xcode is set up correctly
```bash
xcode-select --print-path
# Should show: /Applications/Xcode.app/Contents/Developer
```

### List available schemes
```bash
xcodebuild -list -project RoadTrip.xcodeproj
```

### List available configurations
```bash
xcodebuild -scheme RoadTrip -showBuildSettings | grep CONFIGURATION
```

### Check code signing
```bash
xcodebuild -scheme RoadTrip -showBuildSettings | grep "CODE_SIGN"
```

### View build log details
```bash
xcodebuild -scheme RoadTrip -configuration Release -verbose
```

---

## Pre-Distribution Checklist

Before sharing the app with users:

### Code
- [ ] All features tested on actual device
- [ ] No console errors when running
- [ ] Error handling implemented (use ErrorRecovery.swift)
- [ ] Fallback data shows instead of crashes

### Configuration
- [ ] RapidAPI key set in Config.swift (or empty for mock data)
- [ ] App version updated in Info.plist
- [ ] Build number incremented
- [ ] Privacy Policy written (if going to App Store)

### Testing
- [ ] Tested offline (airplane mode on)
- [ ] Tested on minimum iOS version (iOS 17+)
- [ ] Tested with low storage (< 100 MB free)
- [ ] Tested with slow network (3G simulator)

### Documentation
- [ ] README.md explains features
- [ ] Setup instructions clear
- [ ] Known limitations documented
- [ ] Troubleshooting guide provided

### Build
- [ ] Clean build succeeds
- [ ] No warnings about code signing
- [ ] App size reasonable (< 500 MB)
- [ ] All assets included (maps, icons, etc.)

---

## File Locations After Build

```
RoadTrip/
├── build/
│   ├── Release-iphoneos/
│   │   └── RoadTrip.app              ← Share this (.app file)
│   └── RoadTrip.xcarchive/          ← For App Store submission
│
# After export:
├── Release/
│   └── RoadTrip.ipa                  ← Professional package format
```

---

## App Store Connect Checklist

If submitting to App Store:

1. **Metadata**
   - [ ] App name
   - [ ] Subtitle
   - [ ] Description (750 characters)
   - [ ] Category
   - [ ] Keywords

2. **Content Ratings**
   - [ ] Rate violence, alcohol, gambling, etc.
   - [ ] Apple will generate age rating

3. **Screenshots**
   - [ ] 5-7 screenshots per device size
   - [ ] Show main features
   - [ ] Include text overlays

4. **Privacy**
   - [ ] List what data you collect
   - [ ] Add Privacy Policy URL
   - [ ] Explain why you need permissions

5. **Release Notes**
   - [ ] What's new in this version
   - [ ] Bug fixes and improvements

6. **Build**
   - [ ] Select TestFlight build to submit
   - [ ] Ensure build matches version number

---

## Sharing the Build

### For .app File
```bash
# Create zip for sharing
cd ./build/Release-iphoneos
zip -r RoadTrip.app.zip RoadTrip.app

# Share via:
# - Google Drive: upload RoadTrip.app.zip
# - Dropbox: upload RoadTrip.app.zip
# - Email: RoadTrip.app.zip (if < 25 MB)
# - AirDrop: RoadTrip.app
```

### For .ipa File
```bash
# Share via:
# - TestFlight link (recommended)
# - GitHub Release (with binary)
# - Google Drive / Dropbox
# - Email (if < 25 MB)
```

### For GitHub Release
```bash
# Create tag
git tag -a v1.0.0 -m "Initial release"
git push origin v1.0.0

# Go to GitHub → Releases → Create Release
# Upload RoadTrip.app as binary asset
```

---

## Recovery from Build Failures

### "Code Signing Error"
```swift
// In Xcode
Product → Scheme → Edit Scheme → Build → Code Signing Identity
// Set to: Automatic (or your team ID)
```

### "Module not found"
```bash
# Try cleaning and rebuilding
xcodebuild clean -scheme RoadTrip
xcodebuild -scheme RoadTrip -configuration Release
```

### "Provisioning Profile Error"
```
1. Xcode → Preferences → Accounts
2. Add your Apple ID
3. Click Download Manual Profiles
4. Try building again
```

### "Device not available"
```bash
# Disconnect and reconnect USB
# Try: killall -9 usbmuxd
# Restart Xcode
```

---

## Summary

| Method | Time | Cost | Best For |
|--------|------|------|----------|
| **TestFlight** | 10 min | $99/yr | Beta testing |
| **.app File** | 2 min | Free | Quick testing |
| **.ipa File** | 5 min | $99/yr | Enterprise |
| **GitHub** | 5 min | Free | Open source |
| **User Build** | 10 min | Free | Developers |

**Recommended:** Use TestFlight for best user experience with automatic updates.

For questions, see:
- DISTRIBUTION_GUIDE.md (detailed instructions)
- RESILIENCE_GUIDE.md (error handling)
