# GetUp 💪

> AI-powered workout coach for iPhone. Real-time posture feedback, rep counting, and form scoring — 100% on-device using Apple Vision.

![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5-teal)
![License](https://img.shields.io/badge/License-MIT-green)
![Privacy](https://img.shields.io/badge/Data-On--Device%20Only-brightgreen)

---

## What is GetUp?

GetUp uses your iPhone camera and Apple's on-device Vision framework to watch your body in real time while you exercise. It counts your reps, scores your form, and gives you instant feedback — without sending a single frame to the cloud.

**No account. No subscription. No internet required.**

---

## Features

| Category | Details |
|---|---|
| 🏋️ Strength | Bicep Curl, Shoulder Press, Squat, Lateral Raise, Jumping Jacks |
| 🧘 Yoga | Warrior I & II, Tree Pose, Downward Dog, Chair Pose |
| 💃 Dance | 10 animated dance moves with Canvas figure demos |
| 📷 Camera | Portrait & landscape mode, pinch-to-zoom (up to 8×), front/back flip |
| ✅ Form feedback | Live posture scoring with green glow when form is correct |
| 🔢 Rep counting | Angle-threshold state machine — counts sets automatically |
| ⏱ Rest timer | Live countdown between sets, auto-resumes |
| 🎵 Music | 9 procedurally generated genres (3 per category), no audio files needed |
| 📊 Analytics | Weekly workout chart, form trend, exercise breakdown |
| 🔒 Privacy | Zero network requests, zero data collection, local SwiftData storage |

---

## Screenshots

> Add your screenshots to `docs/screenshots/` and update these paths.

| Setup | Workout | Analytics |
|---|---|---|
| ![Setup](docs/screenshots/setup.png) | ![Workout](docs/screenshots/workout.png) | ![Analytics](docs/screenshots/analytics.png) |

---

## Architecture

```
GetUp/
├── GetUpApp.swift                  ← @main entry point + AppDelegate
├── AppDelegate.swift               ← Orientation lock support
├── RootView.swift                  ← Tab bar / navigation root
│
├── Models/
│   └── WorkoutModels.swift         ← SwiftData: WorkoutSession, ExerciseSet
│
├── ViewModels/
│   └── WorkoutViewModel.swift      ← Central brain: camera → pose → rep counting
│
├── Services/
│   ├── CameraManager.swift         ← AVCaptureSession, frame delivery, zoom
│   ├── PoseDetector.swift          ← Apple Vision VNDetectHumanBodyPoseRequest
│   ├── RepCounter.swift            ← Angle state machine, set/rest management
│   └── AudioManager.swift          ← Procedural music via AVAudioEngine
│
├── Views/
│   ├── ExerciseSetupView.swift     ← Exercise picker, sets/reps config
│   ├── ActiveWorkoutView.swift     ← Live camera + skeleton + rep counter
│   ├── CameraPreviewView.swift     ← AVCaptureVideoPreviewLayer (orientation-aware)
│   ├── ExerciseDemoView.swift      ← Animated Canvas figure demos
│   └── SettingsView.swift          ← Analytics dashboard + preferences
│
├── Utils/
│   ├── ExerciseLibrary.swift       ← All exercise definitions + posture rules
│   ├── AppOrientationHelper.swift  ← Landscape unlock for workout screen
│   └── ScreenManager.swift         ← Prevent screen sleep during workouts
│
└── README.md                       ← You are here
```

---

## How It Works

### Pose Detection Pipeline

```
iPhone Camera
     │  CVPixelBuffer (60fps)
     ▼
CameraManager.onFrame
     │
     ▼
PoseDetector (Vision framework)
     │  VNHumanBodyPoseObservation
     │  17 body joints, normalized 0–1 coords
     ▼
WorkoutViewModel.handlePoseResult
     │  JointMath.angle(from:vertex:to:)
     │  ExerciseLibrary.analyse(joints)
     ▼
RepCounter.feedAngle
     │  State machine: .start → .midMovement → .peak → .start
     ▼
UI: rep count, form score, glow effect
```

### Rep Counting State Machine

Each exercise maps to a primary joint angle (e.g. elbow angle for bicep curl). The `RepCounter` uses two thresholds:

```
startAngleThreshold  (e.g. 150°) — arm fully extended
peakAngleThreshold   (e.g.  40°) — arm fully contracted

State:  .start → movement below start → .midMovement → angle hits peak → .peak → returns to start → .start
                                                           ↑ rep counted here
```

### Procedural Audio

All workout music is synthesised at runtime using `AVAudioEngine` — no `.mp3` or `.caf` files anywhere in the bundle.

```swift
// Kick drum synthesis (Power Beats, 130 BPM)
let freq = 60.0 * exp(-t * 30.0) + 40.0   // pitch sweep 60Hz → 40Hz
let env  = exp(-t * 18.0)                   // exponential decay
let sample = sin(2π × freq × t) × env
```

Nine genres across three categories:

| Strength | Yoga | Dance |
|---|---|---|
| 🥁 Power Beats | 🎵 Calm Flow | 🎧 Dance Groove |
| 🎤 Hip-Hop | 🔔 Tibetan Bowls | 💃 Latin Beat |
| 🎸 Rock Drive | 🌿 Nature Drone | ⚡ EDM Pulse |

---

## Getting Started

### Requirements

- Xcode 15+
- iOS 17.0+ device (Vision pose detection requires a real device — simulator not supported)
- Swift 5.9+

### Installation

```bash
git clone https://github.com/yourusername/GetUp.git
cd GetUp
open GetUp.xcodeproj
```

1. Select your development team in **Signing & Capabilities**
2. Choose a real iOS device as the build target
3. Build and run (`⌘R`)

### Permissions

The app requires these entries in `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>GetUp uses the camera to analyse your exercise form in real time. No video is recorded or stored.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Required by AVAudioSession for workout music playback.</string>
```

---

## Adding New Exercises

1. Open `ExerciseLibrary.swift`
2. Add a new `ExerciseDefinition` to `ExerciseLibrary.all`
3. Implement the `analyse(joints:)` function returning `(PostureFeedback, repCompleted: Bool)`
4. Add the animated figure to `ExerciseDemoView.swift`
5. Wire up the primary angle in `WorkoutViewModel.feedPrimaryAngle`

---

## Privacy

GetUp is designed to be the most privacy-respecting fitness app possible:

- **Camera frames are never saved.** Each frame is processed in memory and immediately discarded.
- **No network requests.** Zero. There is no backend, no analytics SDK, no crash reporter.
- **No account required.** Your data belongs to you and lives only on your device.
- **SwiftData storage is encrypted** by iOS and lives in your app's private sandbox.
- **Deleting the app permanently removes all data.**

App Store Privacy Label: **Data Not Collected**

---

## Contributing

Pull requests welcome. Areas that would benefit most:

- More exercises (deadlift, push-up, lunge)
- Improved pose accuracy for fast movements
- watchOS companion app
- Accessibility: VoiceOver rep announcements

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

*Built with SwiftUI, Vision, AVFoundation, Swift Charts, and AVAudioEngine.*
*No third-party dependencies.*
