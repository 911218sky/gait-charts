# Gait Charts Dashboard

A Flutter-based dashboard for gait recognition and analysis, developed by National Yang Ming Chiao Tung University (NYCU). Visualize and analyze walking patterns with interactive charts, heatmaps, and real-time metrics.

## Features

- 🚶 **Gait Analysis**: Trajectory playback, frequency analysis, speed heatmaps
- 👥 **User Management**: Create and manage user profiles and sessions
- 📊 **Multiple Views**: FFT analysis, swing info, Y-height difference, per-lap offset
- 💾 **Data Extraction**: Process ROS bag files for gait data
- 🔐 **Admin Portal**: Secure authentication and user management
- 📱 **Cross-Platform**: Windows, macOS, Linux, Web, Android

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.10.0 or higher)
- For Windows: Visual Studio 2022 with C++ workload
- For macOS: Xcode + CocoaPods
- For Android: Android Studio + JDK 11+

## Quick Start

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Run the App

```bash
# Desktop
flutter run -d windows  # or macos, linux

# Web
flutter run -d chrome

# Android
flutter run -d <device-id>
```

## Build for Production

### Web

```bash
flutter build web --release
```

Or use the script:

```powershell
.\scripts\build_tools\build_web.ps1
```

Output: `build/web/`

### Windows (MSIX Installer)

```powershell
.\scripts\build_tools\build_win.ps1
```

Output: `build_tools\out\msix\gait_charts.msix`

### Android (APK)

```bash
flutter build apk --release --split-per-abi
```

Or use the script:

```powershell
.\scripts\build_tools\build_apk.ps1
```

Output: `build\app\outputs\flutter-apk\`

### macOS

```bash
flutter build macos --release
```

### Linux

```bash
flutter build linux --release
```

## Project Structure

```
lib/
├── app/              # App configuration and theme
├── core/             # Shared utilities, network, storage
├── features/         # Feature modules
│   ├── admin/        # Admin authentication
│   ├── apk/          # APK downloads
│   └── dashboard/    # Main gait analysis dashboard
└── main.dart         # Entry point
```

Each feature follows Clean Architecture:
- `data/` - API services and repositories
- `domain/` - Models and business logic
- `presentation/` - UI (providers, views, widgets)

## Configuration

Default backend URL is configured in `lib/core/config/app_config.dart`:

```dart
const defaultAppConfig = AppConfig(
  baseUrl: 'https://nycu-realsense-pose.sky1218.com/v1/',
);
```

To use a different backend, modify this file or use the in-app settings panel.

## Testing

```bash
flutter test
```

## Scripts

Useful PowerShell scripts in `scripts/`:

```powershell
# Update dependencies
.\scripts\env\update_deps.ps1

# Clean build artifacts
.\scripts\env\clean_env.ps1

# Build all platforms
.\scripts\build_tools\build.ps1

# Create release and git tag
.\scripts\release\release.ps1 1.0.10

# Manually trigger GitHub Actions: rebuild & replace latest release assets (default)
.\scripts\release\trigger_build.ps1

# Manually trigger build and replace assets for a specific release tag
.\scripts\release\trigger_build.ps1 -ReleaseTag v1.0.10

# Build only (no release)
.\scripts\release\trigger_build.ps1 -BuildOnly

# Build only (web only) - faster
.\scripts\release\trigger_build.ps1 -BuildOnly -WebOnly

# Build only (android only)
.\scripts\release\trigger_build.ps1 -BuildOnly -AndroidOnly

# Build only (windows only)
.\scripts\release\trigger_build.ps1 -BuildOnly -WindowsOnly
```

## CI/CD

### Method 1: Automatic Release (Recommended)

Use the release script to bump version, create tag, and trigger builds:

```powershell
.\scripts\release\release.ps1 1.0.10
```

### Method 2: Manual Tag Push

```bash
git tag v1.0.10
git push origin v1.0.10
```

### Method 3: Manual Workflow Trigger

Trigger builds manually without creating a new tag (requires [GitHub CLI](https://cli.github.com/)):

```powershell
# Build only (no release)
.\scripts\release\trigger_build.ps1 -BuildOnly

# Rebuild & replace latest release assets
.\scripts\release\trigger_build.ps1

# Rebuild & replace assets for a specific release tag
.\scripts\release\trigger_build.ps1 -ReleaseTag v1.0.10
```

This will:
1. Pull latest code from remote
2. Clean old build artifacts
3. Trigger GitHub Actions workflow

GitHub Actions will build all platforms and create a release with artifacts (if tag provided).

## Tech Stack

- **Flutter** & **Dart**
- **Riverpod** - State management
- **Dio** - HTTP client
- **fl_chart** - Data visualization
- **Material Design 3** - Dark theme UI

---

For more details, see the inline code documentation.
