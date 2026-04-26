# 001 — Camera-First Upload

## Overview
Add a camera capture flow so users can attach a short visual reference (photo) to a recorded session. The camera opens directly — no photo-library picker — to keep the flow fast and focused.

## Technology Stack
- **Language:** Swift 5.9+
- **UI:** SwiftUI
- **Camera:** AVFoundation (UIViewControllerRepresentable wrapping UIImagePickerController)
- **Storage:** FileManager (JPEG to app documents)
- **Build:** XcodeGen (`project.yml`)
- **CI/CD:** Codemagic → Diawi (Ad-hoc)

## Architecture

```
MotionInsights/
├── Camera/
│   ├── CameraCaptureView.swift      # SwiftUI wrapper around UIImagePickerController
│   └── PhotoReviewSheet.swift       # Review / retake / confirm
├── Models.swift                     # Added `photoFilename: String?` to Session
├── Storage.swift                    # Added image save/load/delete helpers
├── SensorManager.swift              # Added `attachPhoto(_:to:)` method
├── SessionDetailView.swift          # Shows attached photo + attach button
├── SessionsView.swift               # Photo indicator pill on SessionCard
└── LiveView.swift                   # "Attach photo" button after session save
```

## Data Model Changes

```swift
// In Session struct:
var photoFilename: String?  // relative path in Documents/session-photos/

// In Storage:
func savePhoto(_ image: UIImage, sessionId: String) -> String?
func loadPhoto(filename: String) -> UIImage?
func deletePhoto(filename: String)
func updateSession(_ updated: Session) -> [Session]

// In SensorManager:
func attachPhoto(_ image: UIImage, to sessionId: String)
```

## User Flow
1. User finishes a recording → "Session saved" banner appears
2. Banner includes an **"Attach photo"** button with camera icon
3. Tapping opens full-screen camera (`.fullScreenCover`)
4. User captures → review screen (retake / use photo)
5. Photo saved to `Documents/session-photos/{sessionId}.jpg`
6. Session model updated with filename
7. Photo shown in `SessionDetailView` header
8. Photo indicator pill shown on `SessionCard` in sessions list

## Implementation Steps

### Phase 1: Camera Capture
- [x] Create `CameraCaptureView` (UIViewControllerRepresentable + UIImagePickerController with `.camera` source)
- [x] Create `PhotoReviewSheet` with retake/confirm actions
- [x] Add camera permission handling (already in Info.plist)

### Phase 2: Storage Integration
- [x] Add `savePhoto` / `loadPhoto` / `deletePhoto` to `Storage`
- [x] Add `photoFilename` to `Session` model
- [x] Update `deleteSession` to also delete the photo file
- [x] Add `updateSession` method for attaching photo after initial save

### Phase 3: UI Integration
- [x] Add "Attach photo" button in `LiveView` post-save banner
- [x] Show photo in `SessionDetailView`
- [x] Add "Attach photo" button in `SessionDetailView` when no photo
- [x] Show photo indicator pill in `SessionCard`

### Phase 4: Polish
- [x] Haptic feedback on capture (in PhotoReviewSheet confirm)
- [x] Smooth transitions (camera open/close via fullScreenCover + sheet)
- [x] Handle camera unavailable (Simulator fallback to photo library)
- [x] Compress JPEG to ~80% quality to save space

## Permissions (already configured)
- `NSCameraUsageDescription` ✅
- `NSPhotoLibraryAddUsageDescription` ✅

## Shell Commands
```bash
# Generate Xcode project after changes
cd /home/b7lo/s/swift-app && xcodegen generate

# Build (on macOS with Xcode)
xcodebuild -project MotionInsights.xcodeproj -scheme MotionInsights -sdk iphonesimulator build
```

## Notes
- Camera is **direct capture only** — no photo library picker to keep flow minimal
- Photos stored locally in app sandbox, not in UserDefaults (too large)
- Max photo size: compress to fit under ~500KB via 0.8 JPEG quality
- Simulator automatically falls back to photo library since camera is unavailable
