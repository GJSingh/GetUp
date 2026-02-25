# 🏋️ FitCoach AI

> Real-time workout posture monitoring for iPhone — powered by Apple's on-device Vision framework.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform: iOS 17+](https://img.shields.io/badge/Platform-iOS%2017%2B-blue.svg)]()
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)]()
[![Privacy: On-Device](https://img.shields.io/badge/Privacy-On--Device%20Only-brightgreen.svg)]()

---

## What It Does

FitCoach AI uses your iPhone camera to watch your workout in real time and gives you instant posture feedback. It detects 19 body joints, calculates joint angles, and tells you whether your form is good or how to correct it — all without sending any data anywhere.

**Features:**
- 📷 Live camera feed with skeleton overlay (joints + bones drawn on your body)
- 🎯 Posture analysis per exercise — "Keep your back straight", "Curl higher", etc.
- 🔢 Rep counter with customisable sets and reps per exercise
- ⏱️ Rest timer between sets with skip option
- 📊 Workout history stored locally on your device
- 🔒 100% private — zero network requests, no account required
- 🌙 Dark mode UI

**Supported Exercises:**
| Exercise | Muscle Groups | Key Joint |
|----------|--------------|-----------|
| 💪 Bicep Curl | Biceps, Forearms | Elbow flexion |
| 🏋️ Shoulder Press | Shoulders, Triceps | Elbow + shoulder elevation |
| ✈️ Lateral Raise | Side Delts | Shoulder abduction |
| 🦵 Dumbbell Squat | Quads, Glutes, Hamstrings | Knee flexion |
| 🔱 Tricep Extension | Triceps | Elbow extension overhead |

---

## Privacy

This app is designed with privacy as a first principle:

| What | Detail |
|------|--------|
| **Camera** | Frames processed in memory only. Never written to disk. |
| **Pose Data** | Joint coordinates (just numbers) used for angle calculation, then discarded. |
| **Network** | Zero network requests. Verified: the app has no internet permission. |
| **Storage** | SwiftData in iOS encrypted app sandbox. Deleted when you uninstall. |
| **Analytics** | None. No SDKs. No tracking. |
| **App Store Label** | "Data Not Collected" |

---

## Requirements

- Mac with macOS 13 Ventura or later
- Xcode 15 or later (free from Mac App Store)
- iPhone with iOS 17.0 or later
- Free Apple Developer account (for running on your own device)

---

## Build & Run

```bash
# Clone the repo
git clone https://github.com/gjsingh1/GetUp.git
cd GetUp

# Open in Xcode
open GetUp.xcodeproj
```

1. In Xcode, go to **Settings > Accounts** and add your Apple ID
2. Select your iPhone as the run target (or use the simulator for UI testing — camera won't work in simulator)
3. Press **⌘R** to build and run
4. Trust the developer certificate on your iPhone: **Settings > General > VPN & Device Management**

No external dependencies. No package manager needed. Everything is built into iOS.

---

## Project Structure

```
GetUp/
├── GetUpApp.swift          # App entry point, SwiftData container
├── Models/
│   ├── WorkoutModels.swift      # SwiftData models (WorkoutSession, ExerciseSet)
│   └── ExerciseLibrary.swift    # Exercise definitions + posture analysis logic
├── Services/
│   ├── CameraManager.swift      # AVFoundation camera session
│   ├── PoseDetector.swift       # Vision framework wrapper
│   └── RepCounter.swift         # Rep detection state machine
├── ViewModels/
│   └── WorkoutViewModel.swift   # Orchestrates camera → pose → feedback → storage
├── Views/
│   ├── RootView.swift           # Navigation (TabView)
│   ├── ExerciseSetupView.swift  # Exercise picker + config screen
│   ├── CountdownView.swift      # 3-2-1 countdown
│   ├── CameraPreviewView.swift  # AVCaptureVideoPreviewLayer + skeleton overlay
│   ├── ActiveWorkoutView.swift  # Main workout screen (camera + feedback panel)
│   ├── WorkoutCompleteView.swift # Session summary
│   ├── HistoryView.swift        # Past workouts list
│   └── SettingsView.swift       # Privacy info + preferences
├── Utils/
│   └── Extensions.swift         # Color(hex:), date formatting, etc.
└── Resources/
    └── Info.plist               # Camera permission strings
```

---

## Adding a New Exercise

1. Open `Models/ExerciseLibrary.swift`
2. Add a new analyser function in `ExerciseAnalysers`
3. Add a new `ExerciseDefinition` in `ExerciseLibrary` referencing your analyser
4. Add it to `ExerciseLibrary.all`

The key to each exercise is the `analyse` closure which:
- Receives a dictionary of `VNHumanBodyPoseObservation.JointName → VNRecognizedPoint`
- Returns a `PostureFeedback` struct
- Rep detection happens automatically via `RepCounter` using the angle fed in `WorkoutViewModel.feedPrimaryAngle()`

---

## How Pose Detection Works

1. `CameraManager` streams `CVPixelBuffer` frames at ~30fps
2. `PoseDetector` runs `VNDetectHumanBodyPoseRequest` on each frame
3. Vision returns up to 19 joint positions (normalised 0–1 coordinates) with confidence scores
4. Low-confidence joints (< 0.3) are ignored
5. `ExerciseAnalysers` calculates joint angles using the dot-product formula
6. Angles are compared against exercise-specific thresholds to produce feedback
7. `RepCounter` watches the primary angle over time to detect completed reps

---

## Contributing

Pull requests are welcome! If you want to:
- Add a new exercise — see "Adding a New Exercise" above
- Improve posture thresholds — edit `ExerciseAnalysers` in `ExerciseLibrary.swift`
- Fix a bug — open an issue first to discuss

Please ensure any contribution maintains the privacy principles: no network requests, no data collection.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

You're free to use, modify, and distribute this code including commercially, as long as you include the original copyright notice.

---

## Acknowledgements

- [Apple Vision Framework](https://developer.apple.com/documentation/vision) — on-device pose detection
- [SwiftUI](https://developer.apple.com/documentation/swiftui) — UI framework
- [SwiftData](https://developer.apple.com/documentation/swiftdata) — local encrypted storage
