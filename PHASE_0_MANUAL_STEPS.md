# Phase 0 - Manual Steps Required

## ⚠️ IMPORTANT: Xcode Configuration Needed

Phase 0 automated tasks have been completed successfully, but there is **one manual step** that requires Xcode intervention to fix a build error.

## Issue: Duplicate RouteActivityAttributes.swift

**Current State:**
- File exists in two locations:
  - `AudioCityPOC/AudioCityPOC/LiveActivity/RouteActivityAttributes.swift` (original)
  - `AudioCityPOC/RouteActivityWidget/RouteActivityAttributes.swift` (duplicate)

**Build Error:**
```
error: Multiple commands produce 'RouteActivityAttributes.stringsdata'
```

**Root Cause:**
The Widget Extension target references the duplicate file in its own folder, but both files are being compiled, causing a conflict.

## Solution: Configure Target Membership in Xcode

Follow these steps to fix the issue:

### Step 1: Open Xcode
```bash
open AudioCityPOC/AudioCityPOC.xcodeproj
```

### Step 2: Select the Correct File
In the Project Navigator (left sidebar):
1. Navigate to `AudioCityPOC` → `AudioCityPOC` → `LiveActivity` → `RouteActivityAttributes.swift`
2. Click on the file to select it

### Step 3: Configure Target Membership
In the File Inspector (right sidebar):
1. Find the **"Target Membership"** section
2. Ensure BOTH targets are checked:
   - ✅ **AudioCityPOC** (main app)
   - ✅ **RouteActivityWidgetExtension** (widget)

### Step 4: Delete the Duplicate File
In the Project Navigator:
1. Navigate to `AudioCityPOC` → `RouteActivityWidget` → `RouteActivityAttributes.swift`
2. **Right-click** on the file
3. Select **"Delete"**
4. In the dialog, choose **"Move to Trash"** (not just "Remove Reference")

### Step 5: Verify Build
1. Select the **"AudioCityPOC"** scheme (NOT the Widget Extension)
2. Press **⌘+B** to build
3. Verify: **BUILD SUCCEEDED**

### Step 6: Commit the Change
```bash
# Stage the Xcode project changes
git add AudioCityPOC/AudioCityPOC.xcodeproj/project.pbxproj

# Commit
git commit -m "fix: Configure proper target membership for RouteActivityAttributes.swift

- Share LiveActivity/RouteActivityAttributes.swift with Widget Extension
- Remove duplicate file from RouteActivityWidget folder
- Fixes 'Multiple commands produce' build error

Manual step completed as part of Phase 0 cleanup."

# Push changes
git push origin feature/design-system-v2
```

## Verification

After completing these steps, verify:
- [ ] Project builds successfully (⌘+B)
- [ ] Only ONE RouteActivityAttributes.swift exists (in LiveActivity/)
- [ ] Widget Extension still compiles
- [ ] No "Multiple commands produce" error

## Why This Couldn't Be Automated

Xcode's target membership configuration is stored in the binary `.xcodeproj/project.pbxproj` file in a complex format. Modifying it programmatically without the proper Xcode tooling risks corrupting the project file.

The safest approach is to use Xcode's UI to make these changes.

---

## What Has Been Completed Automatically

✅ **Security:**
- GoogleService-Info.plist removed from git tracking
- Comprehensive .gitignore created
- SECURITY.md policy added
- Credentials backed up to Desktop

✅ **Cleanup:**
- 12.5 MB snapshots folder removed (6 PNG files)
- GoogleService-Info.plist.template created for new developers

✅ **Documentation:**
- README.md updated with setup instructions
- ROADMAP.md created (26-week development plan)
- FASE_0_CHECKLIST.md created (detailed task list)
- SECURITY.md created (security policy)

## Next Steps After Fixing

Once the build succeeds:
1. **Push changes** to remote repository
2. **(CRITICAL) Rotate Firebase credentials** - Follow instructions in FASE_0_CHECKLIST.md section 2
3. **Begin Phase 1** - Technical Refactoring (logging, dependency injection, code cleanup)

---

**Last Updated:** December 20, 2024
**Status:** Awaiting manual Xcode configuration
