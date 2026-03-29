# 🌿 CO₂ Footprint Tracker

A mobile application built with **Flutter** and **Firebase** that empowers users to log, track, and reduce their personal carbon footprint. The app combines activity tracking, AI-powered recommendations, a community feed, gamification, and a rewards system to keep users engaged in their sustainability journey.

---

## 📖 Background

With growing awareness of climate change, individuals play a crucial role in reducing carbon emissions. However, most people have no easy way to understand how their daily choices — transport, food, energy — contribute to their carbon footprint.

**CO₂ Footprint Tracker** was built to bridge this gap: making carbon awareness approachable, social, and rewarding through a modern mobile experience.

---

## 🚀 Features

### 🏠 Home Dashboard
- Dynamic greeting with real-time **Today's CO₂** footprint
- Compact streak counter and points display alongside the profile avatar
- Context-aware "Streak at Risk" warning banner when a daily log hasn't been submitted

### 📊 Activity Logging
- Log transport, food, and energy consumption activities
- Automatic CO₂ calculation based on activity type and emission factors
- Mapbox integration for route-based distance calculation for transport activities

### 🤖 AI Features
- **AI Food Recognition**: Capture food photos for automatic nutritional analysis
- **AI Suggestions**: Personalised low-carbon recommendations powered by external AI APIs

### 🏆 Gamification
- Points awarded for every logged activity
- **Dynamic Day Streak** — calculated client-side in real-time (resets if a day is missed, even without a server-side cron job)
- Badge system with automatic unlocking on milestone achievements

### 🎁 Rewards & Vouchers
- Browse available vouchers redeemable with earned points
- Atomic Firestore transaction ensures points are deducted and voucher issued simultaneously, preventing race conditions
- "My Vouchers" screen with copyable voucher codes

### 👥 Community
- Public social feed for sharing eco-activities and achievements
- Create, edit, and comment on community posts
- Public profile pages with shareable stats

### 🥇 Leaderboard
- Community ranking board sorted by total CO₂ saved and points

### 👤 Profile & Settings
- Full profile editing: display name, bio, avatar
- Eco-lifestyle details (Diet, Home Type, Transport, Country, Household Size) — editable post-registration
- Privacy controls for sharing rank and activity details
- Public profile view showing Eco Lifestyle section

### 🔐 Authentication
- Email & Password Registration (2-step wizard)
- Google Sign-In
- Password reset via email

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (Dart) |
| **State Management** | Riverpod (`flutter_riverpod`) |
| **Backend / Database** | Firebase Firestore |
| **Authentication** | Firebase Auth (Email + Google) |
| **File Storage** | Firebase Storage |
| **Maps & Routes** | Mapbox (`flutter_map`) |
| **AI Recommendations** | Google Gemini API |
| **Food Recognition** | Google Gemini Vision API |
| **Nutrition Data** | USDA FoodData Central API |
| **Fonts** | Google Fonts (`inter`, `roboto_mono`) |
| **Navigation** | `curved_navigation_bar` |
| **Image Handling** | `image_picker` |
| **Sharing** | `share_plus` |
| **Relative Timestamps** | `timeago` |
| **Environment Config** | `flutter_dotenv` |

---

## 🧪 Testing

| Type | Coverage | Files |
|---|---|---|
| Unit Tests | Domain logic | `test/models/user_model_test.dart` |
| Provider Tests | Auth credential mocking | `test/providers/auth_controller_test.dart` |
| Service Tests | Firestore transaction validation | `test/services/voucher_service_test.dart` |
| Widget Tests | UI rendering & form validation | `test/widgets/` |
| Integration Tests | Full app boot test | `integration_test/app_test.dart` |

### Run Tests

```bash
# Run all unit and widget tests
flutter test

# Generate LCOV code coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Test dependencies:** `mocktail`, `fake_cloud_firestore`, `integration_test` (Flutter SDK)

---

## 🏗️ Project Architecture

```
lib/
├── config/          # Mapbox & environment config
├── models/          # Data classes (UserModel, Voucher, Activity, etc.)
├── providers/       # Riverpod state management
├── screens/         # UI screens by feature
│   ├── auth/        # Login & multi-step Signup
│   ├── home/        # Dashboard
│   ├── activity/    # Activity logging
│   ├── community/   # Social feed
│   ├── gamification/# Badges & streaks
│   ├── rewards/     # Voucher redemption
│   └── ...
├── services/        # Firebase, AI, Mapbox service abstractions
└── widgets/         # Shared reusable components
```

---

## ⚙️ Setup

### Prerequisites
- Flutter SDK `^3.11.0`
- Firebase project with Firestore, Auth, and Storage enabled
- Mapbox account and API token

### Installation

```bash
git clone https://github.com/your-username/co2-footprint-tracker.git
cd co2-footprint-tracker/co2_footprint_tracker

# Install dependencies
flutter pub get

# Add your secrets — create a .env file in the project root
touch .env

# Required .env variables:
# MAPBOX_ACCESS_TOKEN=pk.ey...        (from mapbox.com)
# GEMINI_API_KEY=AIza...              (from aistudio.google.com)
# USDA_API_KEY=...                    (from fdc.nal.usda.gov/api-key)

# Run the app
flutter run
```

### Firebase Setup
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** (Email/Password + Google)
3. Enable **Firestore** and **Storage**
4. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) into the respective platform folders
5. Run `flutterfire configure` if using the FlutterFire CLI

---

## 📄 License

This project is for educational purposes. All rights reserved © 2026.