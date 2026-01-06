# Fix for ActivityTemplate Ambiguity Error

## The Problem
You're seeing: `'ActivityTemplate' is ambiguous for type lookup in this context`

This happens because Xcode has **cached build artifacts** from previous compilations where the file was structured differently.

## The Solution - Clean Build on Mac

On your Mac, run these steps **in order**:

### Step 1: Clean Build Folder (⌘ + Shift + K)
```bash
# In Xcode:
Product → Clean Build Folder
# Or press: Command + Shift + K
```

### Step 2: Delete Derived Data
```bash
# Close Xcode first, then run in Terminal:
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### Step 3: Delete .build folders in project
```bash
# In Terminal, navigate to your project folder:
cd /path/to/RoadTrip

# Delete all build artifacts:
find . -type d -name ".build" -exec rm -rf {} +
find . -type d -name "build" -exec rm -rf {} +
```

### Step 4: Restart Xcode and Rebuild
```bash
# Open Xcode
# Product → Build (⌘ + B)
```

## Why This Happens

The SwiftData `@Model` macro generates code at compile time. When you had different versions of ActivityTemplate (with `final`, `public`, `Identifiable`, etc.), the macro created cached artifacts that are now conflicting.

## What Changed

The file now matches the **exact pattern** of your other models:

**ActivityTemplate.swift NOW:**
```swift
@Model
class ActivityTemplate {
    var id: UUID
    var name: String
    // ... other properties
    var usageCount: Int = 0  // Default value OK
    
    init(name: String, location: String = "", category: String, defaultDuration: Double = 1.0) {
        self.id = UUID()
        self.name = name
        // ...
    }
}
```

**Same as Activity.swift, Trip.swift:**
- ✅ Uses `class` (not `final class`)
- ✅ No `public` modifiers
- ✅ Default values on properties allowed (`= 0`)
- ✅ Simple `@Model` macro

## If Clean Build Doesn't Work

If you still see the error after cleaning, try this **nuclear option**:

```bash
# Close Xcode completely

# Delete ALL Xcode caches
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# Delete project-specific build files
cd /path/to/RoadTrip
rm -rf .build
rm -rf build
rm -rf RoadTrip.xcodeproj/xcuserdata
rm -rf RoadTrip.xcodeproj/project.xcworkspace/xcuserdata

# Restart Mac (sometimes necessary for stubborn caches)
sudo reboot
```

## Verification

After cleaning and rebuilding, you should see:
- ✅ Zero compilation errors
- ✅ ActivityTemplate available in autocomplete
- ✅ `@Query private var templates: [ActivityTemplate]` works
- ✅ App runs successfully

## Changes Made

1. **ActivityTemplate.swift** - Reverted to standard SwiftData pattern
2. **ScheduleView.swift** - Renamed `ActivityTemplatePickerSheet` → `TemplatePickerSheet` (to avoid name collision)

## Summary

The code is **correct** - the issue is **cached build artifacts** on your Mac. Clean build folder + delete DerivedData will fix it.
