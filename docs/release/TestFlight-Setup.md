# TestFlight Beta Setup

This guide sets up RoadTrip for internal and external TestFlight testing.

## 1. One-time App Store Connect setup

1. Create the app record in App Store Connect.
2. Confirm bundle identifier matches `RoadTrip/Info.plist`.
3. Enable Automatic Signing in Xcode for the `RoadTrip` target.
4. Add all intended internal testers in Users and Access.
5. Create at least one external tester group (for public beta users).
6. In App Privacy and App Information, fill all required metadata.

## 2. API key setup for CI/automation

1. Open App Store Connect -> Users and Access -> Integrations -> App Store Connect API.
2. Create a key with `Developer` or `App Manager` permissions.
3. Save:
- Key ID
- Issuer ID
- `.p8` private key file

## 3. Build and upload from terminal

Run:

```bash
chmod +x scripts/testflight_beta_upload.sh
ASC_API_KEY_ID=YOUR_KEY_ID \
ASC_API_ISSUER_ID=YOUR_ISSUER_ID \
ASC_API_PRIVATE_KEY_PATH=/absolute/path/AuthKey_XXXXXX.p8 \
./scripts/testflight_beta_upload.sh 1.0.0 1
```

Arguments are:
- `1.0.0`: marketing version (`CFBundleShortVersionString`)
- `1`: build number (`CFBundleVersion`)

The script will:
1. Update app version/build in `RoadTrip/Info.plist`
2. Archive the app
3. Export an App Store IPA
4. Upload to App Store Connect

## 4. Finalize in TestFlight

1. Wait for processing to finish (usually 5-20 minutes).
2. Open the build in TestFlight and complete compliance prompts.
3. Add release notes (`What to Test`).
4. Assign the build to:
- Internal group for immediate smoke testing
- External group for beta rollout
5. Submit for Beta App Review (required for external testers).

## 5. Beta quality gate before rollout

Before assigning to external users, verify:
- Unit tests pass: `xcodebuild test -project RoadTrip.xcodeproj -scheme RoadTrip -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RoadTripTests`
- UI smoke tests pass on iPhone and iPad: `RoadTripUIFlowTests`
- No blocking crashes on cold launch, trip creation, and trip detail tabs

## 6. Recommended release cadence

1. Internal testers first (same day).
2. External 10-20% cohort for 24 hours.
3. Full external cohort if crash-free and no critical regressions.
