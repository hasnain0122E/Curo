# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CURO is an AI-powered Flutter healthcare app for Pakistan, connecting users to low-cost healthcare services nearby. Backend is Firebase; AI features use the Gemini API (`google_generative_ai`).

## Common Commands

```bash
# Install / update dependencies
flutter pub get
flutter pub upgrade

# Run the app
flutter run                    # default connected device
flutter run -d <device-id>    # specific device

# Tests
flutter test                   # all tests
flutter test test/path/to_test.dart  # single test file

# Linting & formatting
flutter analyze                # static analysis (flutter_lints)
dart format lib/               # format all Dart code

# Build
flutter build apk              # Android APK
flutter build appbundle        # Android App Bundle
flutter build ios              # iOS
flutter build web              # Web

# Clean
flutter clean && flutter pub get
```

## Architecture

The project follows clean architecture with a feature-first structure:

```
lib/
├── core/                   # Shared design system — do not put business logic here
│   ├── constants/          # app_colors.dart, app_dimensions.dart, app_text_styles.dart
│   ├── theme/              # app_theme.dart (Material 3)
│   └── widgets/            # Reusable UI components (see Design System below)
├── data/                   # Data layer
│   ├── models/             # Dart data models
│   ├── repositories/       # Abstractions over services
│   └── services/           # Firebase, Gemini API, shared_preferences
├── features/               # Feature modules: auth, home, labs, medicines, profile, reports
│   └── <feature>/          # Each feature has its own screens, widgets, and providers
├── providers/              # Global Riverpod providers (barrel: providers/providers.dart)
└── main.dart
```

**State management**: Riverpod (`flutter_riverpod`). Use `ConsumerWidget` / `ConsumerStatefulWidget` in UI. Providers live in `lib/providers/` (global) or inside the relevant feature folder.

**Routing**: Go Router. Route definitions should be centralized (not yet implemented — create in `lib/core/router/` or `lib/app_router.dart`).

**Barrel pattern**: Each package directory has a `.dart` file re-exporting its public API (e.g., `import 'package:curo/core/widgets/widgets.dart'`). Maintain these when adding new files.

## Design System

All design tokens are in `lib/core/constants/`. Do not hardcode values in widgets.

| Token type | File | Example usage |
|---|---|---|
| Colors | `app_colors.dart` | `AppColors.primary` (`#36BDF2`), `AppColors.background` (`#F5F9FF`) |
| Spacing | `app_dimensions.dart` | `AppDimensions.s16` (16px), suffix: `s4`…`s48` |
| Border radius | `app_dimensions.dart` | `AppDimensions.r12`, suffix: `r4`…`r24` |
| Shadows | `app_dimensions.dart` | `AppDimensions.shadowSmall`…`shadowXLarge` |
| Typography | `app_text_styles.dart` | `AppTextStyles.h1`, `AppTextStyles.bodyMedium` |

**Font**: Plus Jakarta Sans (via `google_fonts`).

**Reusable widgets** (`lib/core/widgets/`):
- `CuroButton` — use the `CuroButtonVariant` enum (`primary`, `secondary`, `text`)
- `CuroInputField` — handles validation, prefix/suffix icons, password visibility toggle
- `CuroCard` / `LabResultCard` — standard and highlighted card variants
- `CuroAppBar` — standard header with optional back button and actions
- `CuroBottomNavBar` — 5-tab nav: Home, Labs, Reports, Medicines, Profile
- `StatusChip` — status badges via `StatusChipType` enum (`success`, `warning`, `danger`, `medipoints`)

## Firebase Setup (required for local dev)

- Place `google-services.json` in `android/app/`
- Place `GoogleService-Info.plist` in `ios/Runner/`
- Services in use: Auth, Firestore, Storage, Messaging

## Key Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` / `riverpod` | State management |
| `go_router` | Declarative routing |
| `firebase_*` | Auth, Firestore, Storage, Messaging |
| `google_generative_ai` | Gemini AI integration |
| `google_maps_flutter` | Maps for nearby healthcare |
| `image_picker` / `file_picker` | Camera & file access |
| `cached_network_image` | Network image caching |
| `flutter_svg` | SVG rendering |
| `intl` | Date/number formatting |
| `shared_preferences` | Local key-value storage |
