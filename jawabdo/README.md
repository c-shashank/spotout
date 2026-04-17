# Jawab Do — *Jawab Do GHMC ko* 🔥

A social-first civic issue reporting and escalation app for Hyderabad citizens.

Built with Flutter (iOS + Android), Firebase Auth, and Supabase.

---

## Quick Start

### Prerequisites

- Flutter SDK ≥ 3.2.0
- Dart SDK ≥ 3.2.0
- A Firebase project (for Auth + FCM)
- A Supabase project

### 1. Clone & install

```bash
git clone https://github.com/your-org/jawabdo
cd jawabdo
flutter pub get
```

### 2. Configure Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Phone Authentication** and **Email/Password Authentication**
3. Enable **Firebase Cloud Messaging**
4. Download `google-services.json` → place in `android/app/`
5. Download `GoogleService-Info.plist` → place in `ios/Runner/`

### 3. Configure Supabase

1. Create a Supabase project at [app.supabase.com](https://app.supabase.com)
2. Run the migrations:
   ```bash
   # Using Supabase CLI
   supabase db push
   # Or manually: copy-paste supabase/migrations/001_initial_schema.sql then 002_seed.sql into the SQL editor
   ```
3. Enable **Storage** and create a bucket called `media` (set to public)
4. Deploy the escalation engine Edge Function:
   ```bash
   supabase functions deploy escalation-engine --project-ref your-project-ref
   ```
5. Set up pg_cron (schedule the Edge Function every 6 hours — see `ESCALATION_LOGIC.md`)

### 4. Set environment variables

```bash
cp .env.example .env
# Fill in all values in .env
```

The app reads these via `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Or set them in your CI/CD environment.

### 5. Add Google Maps API Key

**Android** — in `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="YOUR_ANDROID_MAPS_KEY"/>
```

**iOS** — in `ios/Runner/AppDelegate.swift`:
```swift
GMSServices.provideAPIKey("YOUR_IOS_MAPS_KEY")
```

### 6. Run

```bash
flutter run
```

---

## Project Structure

```
lib/
├── main.dart                    ← App entry point
├── app.dart                     ← MaterialApp + routing + auth gating
├── core/
│   ├── constants/               ← Colors, strings, ward list, categories
│   ├── theme/app_theme.dart     ← Source Code Pro ThemeData
│   ├── utils/                   ← Date, location, karma utilities
│   └── services/                ← Auth, DB, Storage, Notification, Location
├── models/                      ← Issue, Comment, Vote, User, AuthorityAction
├── features/
│   ├── auth/                    ← Phone OTP + Authority email login
│   ├── feed/                    ← Citizen feed + issue card
│   ├── post_issue/              ← 5-step issue reporting flow
│   ├── issue_detail/            ← Full issue view + comments
│   ├── map/                     ← Full-screen map with issue pins
│   ├── profile/                 ← Citizen profile + karma
│   ├── saved/                   ← Bookmarked issues
│   ├── notifications/           ← Activity feed
│   └── authority/               ← Authority dashboard (separate shell)
└── widgets/                     ← Shared: AppBar, SkeletonCard, EmptyState

functions/
└── escalation_engine/           ← Supabase Edge Function (TypeScript/Deno)

supabase/
└── migrations/
    ├── 001_initial_schema.sql   ← Full schema with PostGIS + RLS
    └── 002_seed.sql             ← 10 seed issues for Hyderabad
```

---

## Authority Access

Authority accounts are pre-created by admin. For testing:

| Email | Password | Role |
|---|---|---|
| `officer@ghmc.gov.in` | Set in Firebase Auth | `ward_authority` (Bowenpally) |
| `senior@ghmc.gov.in` | Set in Firebase Auth | `municipal_authority` |

See `AUTHORITY_ROLES.md` for complete documentation on roles and account creation.

---

## Escalation Engine

Issues automatically escalate through 4 tiers (Ward → Municipal → State → Media/NGO) based on upvotes, time, and comment activity.

See `ESCALATION_LOGIC.md` for full trigger rules, schedule, and implementation details.

---

## Design System

- **Font:** Source Code Pro (Google Fonts) — all text elements, no exceptions
- **Accent:** `#CC3300`
- **Background:** `#FFFFFF` (flat, no shadows)
- **Cards:** 0px border radius, 1px dividers only

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (iOS + Android) |
| State Management | flutter_bloc |
| Auth | Firebase Auth (Phone OTP + Email) |
| Database | Supabase (Postgres + PostGIS) |
| Storage | Supabase Storage |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| Maps | Google Maps Flutter |
| Escalation Engine | Supabase Edge Functions (TypeScript/Deno) |
| Charts | fl_chart |

See `STACK.md` for the full backend choice justification.

---

## Contributing

This is an MVP. File issues at `jawabdo.in/feedback` or via the in-app report button.
