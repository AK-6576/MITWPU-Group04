<p align="center">
  <img src="ANSD_APP/Assets.xcassets/AppIcon.appiconset/AppLogo.png" alt="SyncWave Logo" width="120" height="120" style="border-radius: 24px;" />
</p>

<h1 align="center">SyncWave</h1>

<p align="center">
  <b>Real-Time Speech Captioning & Speaker Identification for iOS</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2017%2B-blue?logo=apple" alt="Platform" />
  <img src="https://img.shields.io/badge/Language-Swift%205-orange?logo=swift" alt="Swift" />
  <img src="https://img.shields.io/badge/UI-UIKit%20%2B%20Storyboard-lightgrey" alt="UIKit" />
  <img src="https://img.shields.io/badge/ML-CoreML%20(VL1004)-green?logo=apple" alt="CoreML" />
  <img src="https://img.shields.io/badge/Backend-Firebase-yellow?logo=firebase" alt="Firebase" />
  <img src="https://img.shields.io/badge/AI-Apple%20Intelligence-purple?logo=apple" alt="FoundationModels" />
</p>

---

## 📖 About

**SyncWave** is a native iOS application designed to provide real-time speech-to-text captioning with **on-device AI speaker diarization**. It identifies *who* is speaking in real time using a CoreML voice embedding model (**VL1004**), displays color-coded captions per speaker, and leverages **Apple Intelligence (FoundationModels)** to generate post-session summaries, notes, and per-participant analyses — all processed on-device.

Built as a capstone project by **MIT-WPU Group 4**, SyncWave is aimed at improving accessibility for individuals with hearing impairments (ANSD — Auditory Neuropathy Spectrum Disorder) and anyone who benefits from live captioning in conversations.

---

## ✨ Key Features

### 🎙️ Real-Time Speech Captioning
- Live speech-to-text using Apple's **Speech** framework (`SFSpeechRecognizer`).
- Chat-style UI with color-coded bubbles — **blue** for the enrolled user, **grey** for other speakers.
- Automatic speaker change detection with smooth bubble transitions.

### 🧠 On-Device Speaker Diarization
- Uses a custom **CoreML model (VL1004)** to extract 96,000-sample voice embeddings at 16kHz.
- Cosine similarity matching against stored speaker profiles (threshold: `0.62`).
- **Adaptive learning** — speaker profiles improve over time via rolling average updates.
- **Time Machine** — retroactive correction engine that re-classifies historical segments when a speaker is renamed.

### 🔐 Voice Calibration & Enrollment
- Three-sentence guided voice calibration during onboarding with a 3-2-1 countdown.
- Real-time audio visualizer during recording.
- Cross-sentence voice verification ensures consistency.
- Persistent voice profile storage via **SwiftData** (`VoiceProfileManager`).

### 👥 Group Conversations
- **Create sessions** — generate a unique room code and invite participants via native iOS sharing.
- **Join sessions** — enter a room code to connect to an existing conversation.
- Real-time message syncing powered by **Firebase Realtime Database**.
- Shared transcription visible to all participants in the room.

### ⚡ Quick Actions
- Schedule recurring conversations by category (**Office**, **Family**, **Friends**).
- Dashboard shows the top 3 upcoming actions with queue-like behavior.
- **Local notifications** with pre-session reminders.
- Swipe-to-delete and edit actions on the home screen.
- Firebase sync for cross-device presence tracking and live status indicators.

### 📝 AI-Powered Summaries
- Post-session summary screen with **Apple Intelligence** (`FoundationModels`).
- Auto-generated **notes** (action items, key takeaways, mentioned dates).
- **Per-participant summaries** written in third person.
- Editable notes card for manual additions.
- **PDF export** and share via `UIActivityViewController`.

### 💾 Persistent Data & History
- **SwiftData** for local persistence of conversations, messages, participants, and voice profiles.
- **View Conversations** screen with full chat history replay.
- Context-menu deletion with confirmation alerts.
- Data synced to personal Firebase folder for backup.

### 👤 User Profiles
- Account creation and login via **Firebase Authentication**.
- Customizable profile with name and photo (stored in `UserDefaults`).
- Dynamic greeting on the home screen.

---

## 🏗️ Architecture

```
ANSD_APP/
├── AppDelegate.swift              # App entry, Firebase + SwiftData init
├── SceneDelegate.swift            # Scene lifecycle management
├── Info.plist                     # App configuration
├── GoogleService-Info.plist       # Firebase configuration
│
├── Onboarding/                    # Welcome, Login, Sign Up, Voice Calibration
│   ├── Models/
│   │   ├── VoiceProfile.swift         # SwiftData model for voice embeddings
│   │   └── VoiceProfileManager.swift  # CRUD for voice profiles
│   └── Views/
│       ├── WelcomeViewController.swift
│       ├── CreateAccountViewController.swift
│       ├── LoginAccountViewController.swift
│       └── VoiceCalibrationViewController.swift
│
├── Home Screen/                   # Main dashboard
│   ├── Models/                        # Cell models, sign-up data
│   └── Views/
│       ├── HomeViewController.swift       # Dashboard with Quick Actions + History
│       ├── GreetingViewCell.swift          # Personalized greeting header
│       ├── ProfileTableViewController.swift
│       └── SignUpViewController.swift
│
├── Quick Captions/                # Core captioning engine
│   ├── Models/                        # Chat, participant data models
│   └── Views/
│       ├── QuickCaptioningViewController.swift  # Live captioning + diarization
│       ├── AudioDiarizer.swift                  # CoreML-based speaker ID engine
│       ├── SummaryViewController.swift          # AI summary + PDF export
│       └── TextCleanupManager.swift             # Post-processing transcript cleanup
│
├── Quick Actions/                 # Scheduled conversation actions
│   ├── Data/
│   │   ├── QuickActionsData.swift         # Repository (UserDefaults-backed)
│   │   ├── NotificationManager.swift      # Local notification scheduling
│   │   └── Utils.swift                    # Shared utilities
│   ├── Models/                            # Routine, session, participant models
│   └── Views/                             # Action CRUD, join, summary screens
│
├── Group - New/                   # Create group conversation
│   ├── Managers/
│   │   └── FirebaseManager.swift      # Singleton: Auth, RTDB, presence
│   ├── Models/                        # Chat, participant, cell models
│   └── Views./
│       ├── GroupNewViewController.swift
│       ├── GroupNewSummaryViewController.swift
│       └── ParticipantSelectionViewController.swift
│
├── Group - Join/                  # Join existing conversation
│   ├── Models/                        # Session, chat, participant models
│   └── Views/
│       ├── GroupJoinViewController.swift
│       ├── GroupJoinSummaryViewController.swift
│       └── SessionSelectionViewController.swift
│
├── View Conversations/            # Conversation history browser
│   ├── Data/
│   │   └── DataManager.swift          # SwiftData CRUD operations
│   ├── Models/                        # Conversation, Message, Participant models
│   └── Views/
│       ├── QuickActionsViewController.swift
│       └── ChatHistoryViewController.swift
│
└── Assets.xcassets/               # App icons, images, color sets

VL1004.mlpackage/                  # CoreML voice embedding model
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Language** | Swift 5 |
| **UI Framework** | UIKit + Storyboards |
| **Persistence** | SwiftData (`ModelContainer`, `ModelContext`) |
| **Authentication** | Firebase Auth |
| **Real-Time Sync** | Firebase Realtime Database |
| **Speech-to-Text** | Apple Speech Framework (`SFSpeechRecognizer`) |
| **Speaker ID** | CoreML (`VL1004.mlpackage`) + Accelerate (vDSP) |
| **AI Summaries** | Apple Intelligence (`FoundationModels`) |
| **Notifications** | UserNotifications framework |
| **Location** | CoreLocation + MapKit (reverse geocoding) |
| **PDF Export** | UIGraphicsPDFRenderer |
| **Dependency Mgmt** | Swift Package Manager |

---

## 📋 Requirements

- **Xcode** 16.0+
- **iOS** 17.0+ deployment target
- **macOS** Sonoma 14.0+ (for building)
- **Apple Developer Account** (for on-device testing with microphone/speech)
- **Firebase Project** with Realtime Database and Authentication enabled
- A device with **Apple Intelligence** support (iPhone 15 Pro or later) for AI summaries

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/SyncWave-ANSD.git
cd SyncWave-ANSD
```

### 2. Open in Xcode

```bash
open ANSD_APP.xcodeproj
```

> Swift Package Manager dependencies (Firebase iOS SDK) will resolve automatically on first open.

### 3. Configure Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Authentication** (Email/Password provider).
3. Enable **Realtime Database** and set appropriate security rules.
4. Download `GoogleService-Info.plist` and replace the existing file in `ANSD_APP/`.

### 4. Build & Run

1. Select a physical iOS device (microphone access required).
2. Set your **Bundle Identifier** and **Signing Team** in Xcode.
3. Build and run (`⌘R`).

> **Note:** The simulator does not support microphone input or CoreML Neural Engine acceleration. Always test on a real device.

---

## 📱 App Flow

```
Welcome Screen
     │
     ├──→ Create Account ──→ Voice Calibration ──→ Home Dashboard
     │
     └──→ Login ─────────────────────────────────→ Home Dashboard
                                                        │
                                    ┌───────────────────┼───────────────────┐
                                    │                   │                   │
                              Quick Captions     Group Sessions      Quick Actions
                                    │                   │                   │
                              Live Captioning    Create / Join       Schedule + Join
                              + Diarization      Room Code Sync      Category-based
                                    │                   │                   │
                              AI Summary         Session Summary     Action Summary
                              + PDF Export       + Participant View   + Status Tracking
                                    │                   │                   │
                                    └───────────────────┼───────────────────┘
                                                        │
                                                 View Conversations
                                                 (History + Replay)
```

---

## 🧪 CoreML Model — VL1004

The **VL1004** model is a voice embedding extractor used for real-time speaker diarization:

| Property | Value |
|---|---|
| **Input** | 1 × 96,000 Float32 audio samples (6s at 16kHz) |
| **Output** | Voice embedding vector (high-dimensional) |
| **Compute Units** | All (CPU + GPU + Neural Engine) |
| **Use Case** | Speaker identification via cosine similarity |

The diarization pipeline:
1. Audio is captured at the device's native sample rate.
2. Converted to 16kHz mono via `AVAudioConverter`.
3. Sliding window of 96k samples (with 16k stride) fed to `VL1004`.
4. Extracted embeddings are normalized and compared against stored profiles.
5. Matches above the `0.62` similarity threshold are assigned; otherwise, a new speaker is created.

---

## 👥 Team

**MIT-WPU Group 4** — Built as part of the ANSD accessibility initiative.

| Contributor | Role |
|---|---|
| Anshul Kumaria | Lead Developer — Speech Engine, Diarization, UI/UX Design |
| Omkar Varpe | Lead Developer - App Architecture, Model Implementation, UI/UX Design |
| Daiwiik Harihar | Lead Developer - Home Screen, Database Implementation, UI/UX Design |
| Dhiraj Bodake | Lead Developer - Voice Calibration, Onboarding Flow, UI/UX Design |

---

## 📄 License

This project is developed for academic purposes at **MIT-WPU**. All rights reserved © 2025 MIT-WPU Group 4.

---

<p align="center">
  <i>SyncWave — Hear every voice, see every word.</i>
</p>
