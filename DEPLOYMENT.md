# HeartAnalysis — Deployment Guide

This guide covers running, building, and releasing the HeartAnalysis Flutter app across Android, iOS, Web, and Desktop. It also includes signing, store submission basics, and troubleshooting.

## 1) Prerequisites

- **Flutter SDK**: Install Flutter (stable). Verify with `flutter --version`.
- **Dart**: Bundled with Flutter.
- **Java/JDK**: Install Temurin/OpenJDK 17 (recommended). Verify with `java -version`.
- **Android**: Android Studio + SDK Platform Tools. Accept licenses: `flutter doctor --android-licenses`.
- **iOS (macOS only)**: Xcode + CocoaPods (`sudo gem install cocoapods`).
- **Web**: Chrome or any modern browser.
- **Windows Desktop**: Visual Studio with Desktop development with C++ workload.

Check your environment with `flutter doctor -v` and resolve any issues.

## 2) Project Setup

- **Install dependencies**: `flutter pub get`
- **Run analyzer (optional)**: `flutter analyze`
- **Run tests (optional)**: `flutter test`

## 3) Running in Debug

- **Generic**: `flutter run`
- **Android device/emulator**: `flutter run -d android`
- **iOS simulator**: `flutter run -d ios`
- **Web (Chrome)**: `flutter run -d chrome`

Tip: Use VS Code launch config `heartanalysis` (includes `--fast-start`).

## 4) App IDs and Versioning

- **Android App ID**: Edit `android/app/build.gradle.kts: defaultConfig.applicationId` (e.g., `com.yourcompany.heartanalysis`).
- **iOS Bundle ID**: Set in Xcode: Targets > Runner > Signing & Capabilities (e.g., `com.yourcompany.heartanalysis`).
- **Version**: Update `pubspec.yaml: version: 1.0.0+1` (format `x.y.z+build`), then rebuild.

## 5) Android Release Build

### A) Generate a Keystore (one time)

```
keytool -genkey -v -keystore ~/keystores/heartanalysis.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias heartanalysis
```

### B) Create `android/key.properties`

```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=heartanalysis
storeFile=/absolute/path/to/heartanalysis.jks
```

### C) Configure Signing (KTS)

In `android/app/build.gradle.kts`, add signing config and use it for `release`:

```kts
android {
    // ...
    signingConfigs {
        create("release") {
            val props = java.util.Properties()
            val file = rootProject.file("key.properties")
            if (file.exists()) props.load(java.io.FileInputStream(file))
            storeFile = props["storeFile"]?.let { file(it as String) }
            storePassword = props["storePassword"] as String?
            keyAlias = props["keyAlias"] as String?
            keyPassword = props["keyPassword"] as String?
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false // or true with ProGuard/R8 rules
        }
    }
}
```

### D) Build Artifacts

- **APK**: `flutter build apk --release`
- **App Bundle (Play Store)**: `flutter build appbundle --release`
  - Output: `build/app/outputs/bundle/release/app-release.aab`

### E) Upload to Play Console

- Create an app in Google Play Console.
- Upload the `.aab`, provide store listing, content rating, and privacy policy.

## 6) iOS Release Build (macOS)

### A) Setup Signing

- Open `ios/Runner.xcworkspace` in Xcode.
- Set a unique Bundle Identifier.
- In Signing & Capabilities, select your team and enable automatic signing.

### B) Build IPA

- From CLI: `flutter build ipa --release`
- Or in Xcode: Product > Archive, then Distribute via Organizer.

Submit using Xcode Organizer or Transporter to App Store Connect, then complete app metadata and submit for review.

## 7) Web Deploy

### A) Build

```
flutter build web --release
```

Output in `build/web/` can be hosted on any static host:

- **Firebase Hosting**:
  - `npm install -g firebase-tools`
  - `firebase login`
  - `firebase init hosting` (public directory: `build/web`, single-page app: `y`)
  - `firebase deploy`
- **Netlify**: Drag `build/web` into app.netlify.com or use CLI (`netlify deploy --prod`).
- **GitHub Pages**: Serve `build/web` via `gh-pages` branch.

## 8) Windows (Desktop)

- Enable desktop: `flutter config --enable-windows-desktop`
- Build: `flutter build windows --release`
- Output: `build/windows/runner/Release/` (EXE + DLLs). Consider code signing before distribution.

## 9) macOS/Linux (optional)

- macOS: `flutter config --enable-macos-desktop` then `flutter build macos --release`
- Linux: `flutter config --enable-linux-desktop` then `flutter build linux --release`

## 10) Environment & Secrets

- Do not commit `key.properties` or keystore files.
- Prefer CI/CD secret stores (GitHub Actions/Bitrise/Codemagic) for signing creds.

## 11) Performance Modes

- **Profile**: `flutter run --profile` (near‑release performance + observatory).
- **Release**: `flutter run --release` (no debugging, smallest size).
- VS Code configs include `profile` and `release` modes.

## 12) CI/CD (GitHub Actions — Android AAB example)

```yaml
name: build-android-aab
on: [push, workflow_dispatch]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - name: Decode Keystore
        run: |
          echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > android/heartanalysis.jks
      - name: Create key.properties
        run: |
          cat > android/key.properties <<EOF
          storePassword=$STORE_PASSWORD
          keyPassword=$KEY_PASSWORD
          keyAlias=$KEY_ALIAS
          storeFile=heartanalysis.jks
          EOF
      - run: flutter build appbundle --release
      - uses: actions/upload-artifact@v4
        with:
          name: app-release-aab
          path: build/app/outputs/bundle/release/app-release.aab
```

## 13) Troubleshooting

- **Android licenses**: Run `flutter doctor --android-licenses` and accept.
- **JDK mismatch**: Use JDK 17 (`java -version`).
- **CocoaPods issues**: `sudo gem install cocoapods && cd ios && pod repo update && pod install`.
- **Play Store Signing**: If using Play App Signing, keep local keystore safe; Play will manage final signing.
- **Slow builds**: This project enables Gradle parallel/caching in `android/gradle.properties`. Run `flutter clean` once after upgrading Flutter/AGP.

## 14) Useful Paths

- Android app gradle: `android/app/build.gradle.kts:1`
- Gradle properties: `android/gradle.properties:1`
- Launch configs: `.vscode/launch.json:1`
- Pubspec: `pubspec.yaml:1`

---

For help automating store uploads or adding code signing to CI, open an issue or request a CI config tailored to your environment.

