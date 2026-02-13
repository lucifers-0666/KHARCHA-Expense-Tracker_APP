# KHARCHA Development Guide

Complete guide for setting up your local development environment for KHARCHA.

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [System Requirements](#system-requirements)
- [Environment Setup](#environment-setup)
- [Firebase Setup](#firebase-setup)
- [Running the App](#running-the-app)
- [Development Workflow](#development-workflow)
- [Debugging](#debugging)
- [Common Issues](#common-issues)

---

## 🚀 Quick Start

```bash
# Clone repository
git clone https://github.com/lucifers-0666/KHARCHA-Expense-Tracker_APP.git
cd KHARCHA-Expense-Tracker_APP

# Install dependencies
flutter pub get

# Configure Firebase
flutterfire configure

# Run the app
flutter run
```

---

## 💻 System Requirements

### Minimum Requirements
- **Flutter SDK:** 3.10.7 or higher
- **Dart SDK:** 3.0 or higher
- **Java JDK:** 11 or higher (for Android)
- **Android SDK:** API 21+ (for Android development)
- **Xcode:** 13.0+ (for iOS development on macOS)

### Recommended Development Tools
- **IDE:** VS Code or Android Studio
- **Git:** Latest version
- **Node.js:** Latest LTS (for Firebase CLI)
- **Docker:** Optional (for Firebase Emulator)

### Storage Requirements
- **Flutter SDK:** ~2-3 GB
- **Android SDK:** ~20-30 GB
- **Xcode:** ~50+ GB (macOS only)
- **Project:** ~500 MB

---

## 🔧 Environment Setup

### 1. Install Flutter

**Windows:**
```bash
# Download Flutter from https://flutter.dev/docs/get-started/install/windows
# Extract to C:\Flutter or your preferred location
# Add to PATH: C:\Flutter\bin

flutter doctor -v
```

**macOS:**
```bash
brew install flutter

# Add to PATH (if needed)
echo 'export PATH="$PATH:/Users/username/flutter/bin"' >> ~/.zshrc

flutter doctor -v
```

**Linux:**
```bash
# Download from https://flutter.dev/docs/get-started/install/linux
# Extract to ~/flutter

echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

flutter doctor -v
```

### 2. Install IDE Extensions

**VS Code:**
```bash
code --install-extension Dart-Code.flutter
code --install-extension Dart-Code.dart-code
```

**Android Studio:**
- Install Flutter plugin: Settings → Plugins → Search "Flutter"
- Install Dart plugin: Settings → Plugins → Search "Dart"

### 3. Verify Installation

```bash
flutter doctor

# Output should show:
# ✓ Flutter (Channel stable)
# ✓ Android toolchain
# ✓ iOS toolchain (if on macOS)
# ✓ VS Code or Android Studio
# ✓ Android Emulator or iOS Simulator
```

---

## 🔥 Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add Project"
3. Name: `KHARCHA`
4. Enable Google Analytics (optional)

### 2. Enable Services

**Authentication:**
- Go to **Authentication** → **Sign-in Method**
- Enable **Email/Password**
- Enable **Google** (optional)

**Firestore Database:**
- Go to **Firestore Database** → **Create Database**
- Select region: `us-central1` or closest to you
- Start in **Test Mode** (we'll secure later)

**Cloud Storage:**
- Go to **Storage** → **Create Bucket**
- Accept defaults

### 3. Configure Flutter App

```bash
# From project root
flutterfire configure

# Choose options:
# ✓ Platforms: Android, iOS, Web
# ✓ Use Firestore: Yes
# ✓ Use Storage: Yes
# ✓ Use Auth: Yes
```

### 4. Update Security Rules

**Firestore Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /expenses/{expenseId} {
      allow read, write: if request.auth != null && 
                            request.auth.uid == resource.data.userId;
    }
    match /budgets/{budgetId} {
      allow read, write: if request.auth != null && 
                            request.auth.uid == resource.data.userId;
    }
  }
}
```

---

## ▶️ Running the App

### Run on Android

```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run with specific package
flutter run --target=lib/main.dart

# Run in release mode
flutter run --release
```

### Run on iOS

```bash
# iOS requires macOS
flutter run -d iPhone

# Specify simulator
flutter run -d 00008110-000C3224400D

# Run in release mode
flutter run --release -d iPad
```

### Run on Web

```bash
flutter run -d chrome

# Run on specific port
flutter run -d chrome --web-port=5000
```

### Keyboard Shortcuts During Run

| Shortcut | Action |
|----------|--------|
| `r` | Hot reload |
| `R` | Hot restart |
| `h` | Show help |
| `q` | Quit |
| `w` | Toggle widget inspector |
| `p` | Toggle performance overlay |
| `i` | Toggle iOS simulator |
| `o` | Toggle Navigator observer logging |

---

## 🔄 Development Workflow

### Feature Development

1. **Create feature branch**
   ```bash
   git checkout -b feature/expense-ocr-scanning
   ```

2. **Install any new packages**
   ```bash
   flutter pub add package_name
   ```

3. **Write code**
   - Create models in `lib/models/`
   - Create services in `lib/services/`
   - Create screens in `lib/screens/`
   - Create widgets in `lib/widgets/`

4. **Format code**
   ```bash
   dart format lib/
   ```

5. **Run analysis**
   ```bash
   flutter analyze
   ```

6. **Write tests**
   ```bash
   flutter test test/
   ```

7. **Run the app**
   ```bash
   flutter run
   ```

8. **Commit changes**
   ```bash
   git add .
   git commit -m "feat(expense): add OCR scanning"
   ```

### Hot Reload Workflow

During development, use hot reload for fast iteration:

```bash
flutter run
# Make changes to code
# Press 'r' to hot reload
# See changes instantly
```

**Note:** Hot reload doesn't work for:
- Changes to main.dart
- Platform channel changes
- Dependency changes
- Main function changes

Use **hot restart** (`R`) or restart (`flutter run`) for those.

---

## 🐛 Debugging

### Enable Debug Logging

```dart
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  print('Debug message: $variable');
}
```

### Use DevTools

```bash
# Start the app
flutter run

# In another terminal
flutter pub global activate devtools
devtools

# Open browser to http://localhost:9100
```

### Debugging Firebase

```dart
// Enable Firebase debug logging
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Enable debug logging
  if (kDebugMode) {
    // Firebase logs available in console
  }
  
  runApp(MyApp());
}
```

### Debugging Firestore

1. Use [Firebase Console](https://console.firebase.google.com) to inspect data
2. Check Firestore rules in Rules tab
3. Use Data tab to manually add/edit test documents
4. Monitor usage in Usage tab

### Common Debug Commands

```bash
# Clear build cache
flutter clean

# Get all packages
flutter pub get

# Upgrade packages
flutter pub upgrade

# Analyze code
flutter analyze

# Run tests with verbose output
flutter test -v

# Profile app performance
flutter run --profile

# Build debug APK
flutter build apk --debug
```

---

## ❓ Common Issues

### Issue: "Flutter not found"
**Solution:**
```bash
# Add Flutter to PATH
export PATH=$PATH:~/flutter/bin

# Verify
flutter --version
```

### Issue: "Firebase configuration not found"
**Solution:**
```bash
flutterfire configure
# Ensure google-services.json is in android/app/
# Ensure GoogleService-Info.plist is in ios/Runner/
```

### Issue: "Error: Unable to load asset"
**Solution:**
- Check `pubspec.yaml` for correct asset paths
- Run `flutter pub get`
- Rebuild: `flutter clean && flutter run`

### Issue: "Gradle build failed"
**Solution:**
```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

### Issue: "CocoaPods dependency error" (iOS)
**Solution:**
```bash
flutter clean
cd ios
rm Podfile.lock
pod repo update
cd ..
flutter run
```

### Issue: "Hot reload not working"
**Solution:**
- Use hot restart (`R`)
- Restart the app (`flutter run`)
- Check for syntax errors (`flutter analyze`)

### Issue: "App crashes on startup"
**Solution:**
1. Check Firebase configuration
2. Check logcat: `flutter logs`
3. Run with verbose: `flutter run -v`
4. Check Crashlytics in Firebase Console

---

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Flutter Guide](https://firebase.flutter.dev)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [DevTools Documentation](https://flutter.dev/docs/development/tools/devtools)
- [Flutter Testing Guide](https://flutter.dev/docs/testing)

---

## 💬 Need Help?

- Check [CONTRIBUTING.md](CONTRIBUTING.md)
- Check [README.md](README.md)
- Create an issue on [GitHub](https://github.com/lucifers-0666/KHARCHA-Expense-Tracker_APP/issues)
- Start a [Discussion](https://github.com/lucifers-0666/KHARCHA-Expense-Tracker_APP/discussions)

---

<div align="center">

**Happy Coding!** 🚀

Made with ❤️ by the KHARCHA Team

</div>
