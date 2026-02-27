# GetUp — AI-Powered Workout Coach for iOS

<div align="center">

![GetUp App](https://img.shields.io/badge/Platform-iOS%2017%2B-blue?style=for-the-badge&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=for-the-badge&logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-purple?style=for-the-badge)

**Real-time AI posture monitoring · Animated exercise demos · Background workout music**

</div>

---

## What is GetUp?

GetUp is an iOS fitness app that uses your phone's camera and Apple's Vision framework to monitor your body posture in real time while you exercise. It counts reps automatically, alerts you to form mistakes, and guides you through strength training, yoga, and dance workouts — all on-device with no cloud required.

---

## Screenshots

### Exercise Setup & Demo Sheet

| Exercise Picker | Detail Demo Sheet | Active Workout |
|:-:|:-:|:-:|
| ![Exercise picker with Strength/Yoga/Dance categories](docs/setup_view.png) | ![Animated demo with step-by-step instructions](docs/demo_sheet.png) | ![Live camera feed with pose overlay](docs/active_workout.png) |
| Choose from 25 exercises across 3 categories | Watch an animated figure demo with full tutorial | Live camera with skeleton overlay & rep counter |

### Project Structure (Xcode)

<img src="docs/xcode_project.png" width="320" alt="Xcode project navigator showing all Swift files"/>

---

## Features

### 🏋️ Strength Training (5 exercises)
- **Bicep Curl** — animated dumbbell curl with elbow lock detection
- **Shoulder Press** — overhead press with full-extension check
- **Lateral Raise** — shoulder-height alignment guide
- **Squat** — parallel depth marker with knee tracking
- **Tricep Extension** — elbow-fixed overhead extension

### 🧘 Yoga (5 poses)
- **Warrior I & II** — knee angle and arm alignment checks
- **Tree Pose** — balance sway monitoring
- **Downward Dog** — hip height guidance
- **Chair Pose** — depth and hold duration timer
- All yoga poses animate with a **gentle breathing pulse** (3.5s cycle)

### 💃 Dance (10 moves)
- **Zumba Hip Shake, Bhangra Arm Pump, Salsa Side Step, Arm Wave, Jumping Jacks, Body Roll, Giddha Hands, Latin Hip Sway, Chest Pop, Full Body Groove**
- Timer-based moves (you set the duration)
- Fast-cycle animations (0.8–1.2s) showing the exact groove

### 🎵 Workout Music
- **Programmatic audio** — no external MP3 files needed
- Three distinct styles generated via `AVAudioEngine`:
  - 🥁 **Power Beats** (130 BPM) — kick-snare pattern for strength
  - 🎵 **Calm Flow** (60 BPM) — ambient chord drone for yoga
  - 🎧 **Dance Groove** (128 BPM) — four-on-the-floor with synth bass for dance
- Volume slider, play/pause from the demo sheet or setup screen
- Auto-starts matching music when you tap Start Workout

### 📱 Smart UI
- **Animated exercise figures** drawn entirely with SwiftUI Canvas (zero images)
- **`TimelineView(.animation)`** drives all animations — renders on frame 1, no blank-first-load
- **Sticky Start button** using `.safeAreaInset(edge: .bottom)` — never hidden by nav bars
- **Info ⓘ button** on every exercise card opens a detail sheet with animated demo + step-by-step tutorial
- **Workout history** stored locally with SwiftData
- **Session summary** with score, rep count, and duration

---

## Architecture

```
GetUp/
├── GetUpApp.swift              # App entry, SwiftData container setup
├── RootView.swift              # Navigation root
├── WorkoutModels.swift         # SwiftData models: WorkoutSession, ExerciseSet
├── WorkoutViewModel.swift      # Central state machine (setup → countdown → active → complete)
│
├── Views/
│   ├── ExerciseSetupView.swift # Category picker, exercise cards, config steppers, sticky start
│   ├── ExerciseDemoView.swift  # 20 animated Canvas figures + ExerciseDetailSheet
│   ├── ActiveWorkoutView.swift # Camera feed + skeleton overlay + rep counter
│   ├── CountdownView.swift     # 3-2-1 countdown before workout starts
│   ├── WorkoutCompleteView.swift
│   ├── HistoryView.swift
│   └── SettingsView.swift
│
├── Camera/
│   ├── CameraManager.swift     # AVCaptureSession management
│   └── CameraPreviewView.swift # UIViewRepresentable camera preview
│
├── ML/
│   └── PoseDetector.swift      # Vision VNDetectHumanBodyPoseRequest + rep counting logic
│
├── Audio/
│   └── AudioManager.swift      # AVAudioEngine programmatic music (no external files)
│
└── ExerciseLibrary.swift       # All 25 exercise definitions with metadata
```

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| UI Framework | SwiftUI 5 |
| Animations | `TimelineView(.animation)` + `Canvas` |
| Pose Detection | Apple Vision (`VNDetectHumanBodyPoseRequest`) |
| Camera | AVFoundation (`AVCaptureSession`) |
| Audio | AVFoundation (`AVAudioEngine`) |
| Persistence | SwiftData |
| Minimum iOS | iOS 17.0 |
| Language | Swift 5.9 |

---

## Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ device or simulator
- Physical device recommended for camera-based pose detection

### Installation

```bash
# 1. Clone the repo
git clone https://github.com/yourusername/GetUp.git
cd GetUp

# 2. Open in Xcode
open GetUp.xcodeproj

# 3. Select your target device and run (⌘R)
```

No external dependencies — the project uses only Apple frameworks.

### Permissions Required

Add these keys to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>GetUp uses your camera to monitor your exercise form in real time.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Required by AVCaptureSession for camera access.</string>
```

---

## How It Works

### Pose Detection Pipeline

```
Camera Frame
    ↓
AVCaptureSession (30fps)
    ↓
VNDetectHumanBodyPoseRequest (Vision)
    ↓
17 body landmarks (wrist, elbow, shoulder, hip, knee, ankle…)
    ↓
PoseDetector: joint angle calculations
    ↓
RepCounter: threshold crossing → rep count++
    ↓
SwiftUI overlay: skeleton lines + feedback text
```

### Rep Counting Logic

Each exercise defines two angle thresholds — `topAngle` and `bottomAngle`. When the tracked joint angle crosses from above `topAngle` down through `bottomAngle` and back, that's one rep. Yoga poses instead use a hold timer that starts when the pose angle is within range.

### Audio Generation

Music is synthesized at runtime using `AVAudioEngine`:

```swift
// Kick drum: frequency-swept sine with exponential decay
let freq = 60.0 * exp(-t * 30.0) + 40.0
let env  = exp(-t * 18.0)
sample   = sin(2π × freq × t) × env

// Snare: white noise + 200Hz tone, gated with decay
sample = (sin(2π × 200 × t) × 0.3 + noise × 0.7) × exp(-t × 20)

// Bass: sawtooth wave at root note frequency  
let saw = (2.0 × fmod(t × freq, 1.0)) - 1.0
sample  = saw × exp(-t × 4.0)
```

Patterns are written into `AVAudioPCMBuffer`s and scheduled with `.loops` — zero CPU overhead once running.

---

## Contributing

Pull requests are welcome! Some areas to contribute:

- **More exercises** — add to `ExerciseLibrary.swift` and create a Canvas figure in `ExerciseDemoView.swift`
- **Better pose accuracy** — improve angle calculations in `PoseDetector.swift`
- **Music styles** — add new patterns in `AudioManager.swift`
- **Accessibility** — VoiceOver support for exercise instructions

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

<div align="center">
Made with SwiftUI · Powered by Apple Vision · No subscriptions · No cloud
</div>
