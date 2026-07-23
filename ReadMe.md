# PastViewer

<p align="center">
  <img src="landing/assets/app-icon.png" width="160" alt="PastViewer logo"/>
</p>

<p align="center">
  <strong>A pocket time machine for the places around you.</strong>
</p>

<p align="center">
  Explore geotagged historical photos on a live map, filter them by year, and recreate the same view with your camera.
</p>

<p align="center">
  <a href="https://apps.apple.com/rs/app/pastviewer/id6761183383">
    <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Download on the App Store" height="56"/>
  </a>
  <a href="https://play.google.com/store/apps/details?id=org.qtproject.PastViewer">
    <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Get it on Google Play" height="66"/>
  </a>
</p>

<p align="center">
  <a href="#experience">Experience</a> ·
  <a href="#screenshots">Screenshots</a> ·
  <a href="#features">Features</a> ·
  <a href="#developer-setup">Developer Setup</a>
</p>

## Experience

PastViewer turns a walk through a city into a visual archive. Open the map, follow your current position, and discover historical photos from the streets, squares, and buildings nearby.

When a photo catches your eye, open it full screen, inspect the details, then switch into camera mode to line up the past with the present and share the result.

## Screenshots

<p align="center">
  <img src="landing/assets/simulator-01.png" width="260" alt="PastViewer map screen"/>
  <img src="landing/assets/simulator-05.png" width="260" alt="PastViewer photo details screen"/>
</p>

## Features

| Discover | Compare | Tune |
| --- | --- | --- |
| Browse historical photos on an interactive map. | Pinch, pan, and study full-size historical photos before recreating the view. | Filter by timeline, nearby items, and current map area. |
| Follow your location, recenter instantly, and explore clustered markers. | Use camera mode to capture a present-day match and share it from the app. | Replay onboarding tips and reload map items without restarting the app. |

## Built For

- Curious walkers who want to see what stood here before.
- Travelers looking for historical context without leaving the map.
- Local historians and photographers recreating archival viewpoints.
- Mobile-first exploration across Android, iOS, and desktop builds.

The app currently includes translations for English, German, Spanish, French, Italian, Japanese, Korean, Portuguese, Russian, Serbian, and Simplified Chinese.

## Developer Setup

### Requirements

- CMake 3.28 or later
- Ninja
- Conan 2
- C++20-compatible compiler
- Felgo SDK with matching macOS host, iOS, and Android kits from the same installation
- Stadia Maps API key (optional — map tiles need `OSM_API_KEY`)
- Sentry DSN (optional)

For macOS, install the Xcode Command Line Tools. For iOS, install the latest Xcode supported by your macOS version, launch it once to finish installing components, and verify the selected developer directory:

```bash
xcode-select --print-path
xcodebuild -version
```

The repository targets iOS 16 or later. Keep the Felgo macOS host kit and iOS target kit at the same Qt/Felgo version; do not mix them with a standalone Qt installation. The iOS device and simulator use separate Conan profiles and build directories.

For Android builds, install Android SDK API 33+, an ARM64 Android system image, Android NDK 29, and JDK 17. The checked-in Android Conan profile currently points to NDK `29.0.14206865`; update that path and the matching VS Code task if the SDK is installed elsewhere.

### Configure Keys (optional)

```text
-DOSM_API_KEY=your-stadiamaps-api-key
-DSENTRY_DSN=your-sentry-dsn
-DAPP_REVERSED_DOMAIN=com.example.myapp
```

`APP_REVERSED_DOMAIN` is the app bundle identifier used on all platforms (for example `com.example.myapp`). CMake sets `PRODUCT_IDENTIFIER` and the Apple plist values from it.

Omit the optional CMake options when they are not needed. The app still builds without them, but map tiles require `OSM_API_KEY` and crash reporting requires `SENTRY_DSN`. Create a Stadia Maps key at [stadiamaps.com](https://stadiamaps.com/) and use a private or environment-specific Sentry project.

### macOS Build

Use Felgo's `qt-cmake` wrapper and an out-of-source build directory. It selects the matching Felgo/Qt installation and avoids hard-coding a separate `CMAKE_PREFIX_PATH`.

```bash
conan install . \
  --output-folder=build-macos-release \
  --build=missing \
  -s:h=build_type=Release \
  -s:h=compiler.cppstd=20

path/to/Felgo/Felgo/macos/bin/qt-cmake --fresh \
  -S . \
  -B build-macos-release \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build-macos-release --parallel
open build-macos-release/bin/PastViewer.app
```

Add the optional key options to the `qt-cmake` command when required. For a Debug build, use a separate directory such as `build-macos-debug` and set both Conan and CMake to `Debug`.

Before distributing the app to another Mac, create a self-contained bundle with the `macdeployqt` from the same Felgo installation:

```bash
path/to/Felgo/Felgo/bin/macdeployqt \
  build-macos-release/bin/PastViewer.app \
  -qmldir=qml
```

### iOS Device and App Store Build

The device build uses the Xcode generator, the repository's `profiles/ios-device` Conan profile, and manual signing. Replace `YOUR_TEAM_ID`, `APP_REVERSED_DOMAIN`, and the provisioning-profile name directly in the commands below. The existing `PastViewer_AppStore_profile` must belong to the selected team and match `APP_REVERSED_DOMAIN`.

An App Store provisioning profile is intended for archive/export, not direct installation on a test device. For physical-device debugging, use an Apple Development identity and a development profile containing that device. The simulator workflow below remains unsigned and needs no profile.

```bash
conan install . \
  --profile:host=profiles/ios-device \
  --profile:build=default \
  --output-folder=build-ios-felgo-device \
  --build=missing \
  -s:h=build_type=Release \
  -s:h=compiler.cppstd=20

path/to/Felgo/Felgo/ios/bin/qt-cmake --fresh \
  -S . \
  -B build-ios-felgo-device \
  -G Xcode \
  -DQT_HOST_PATH="path/to/Felgo/Felgo/macos" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
  -DAPPLE_TEAM_ID="YOUR_TEAM_ID" \
  -DAPP_REVERSED_DOMAIN="com.example.myapp" \
  -DAPPLE_PROVISION_PROFILE_NAME="PastViewer_AppStore_profile"

cmake --build build-ios-felgo-device \
  --config Release \
  --target PastViewer \
  -- -allowProvisioningUpdates
```

To produce the App Store archive and IPA, use the generated Xcode project and the export-options plist generated during CMake configuration:

```bash
xcodebuild archive \
  -project build-ios-felgo-device/PastViewer.xcodeproj \
  -scheme PastViewer \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath build-ios-felgo-device/PastViewer.xcarchive \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID"

xcodebuild -exportArchive \
  -archivePath build-ios-felgo-device/PastViewer.xcarchive \
  -exportPath build-ios-felgo-device/ipa-export \
  -exportOptionsPlist build-ios-felgo-device/ExportOptions-app-store.plist \
  -allowProvisioningUpdates
```

The IPA is written to `build-ios-felgo-device/ipa-export`. Use a fresh archive/export path when repeating the export, or run the VS Code task, which cleans those paths first.

### iOS Simulator Build and Run

Simulator builds do not need a provisioning profile or code signing. This repository's Felgo iOS dependencies require an x86_64 simulator build, so Apple Silicon Macs need Rosetta and an x86_64-capable iOS Simulator runtime. With Xcode 26 or later, install the universal iOS platform component if the Rosetta run destinations are missing:

```bash
xcodebuild -downloadPlatform iOS -architectureVariant universal
```

Use the dedicated simulator profile and build directory:

```bash
conan install . \
  --profile:host=profiles/ios-simulator \
  --profile:build=default \
  --output-folder=build-ios-felgo-simulator \
  --build=missing \
  -s:h=build_type=Release \
  -s:h=compiler.cppstd=20

path/to/Felgo/Felgo/ios/bin/qt-cmake --fresh \
  -S . \
  -B build-ios-felgo-simulator \
  -G Xcode \
  -DQT_HOST_PATH="path/to/Felgo/Felgo/macos" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES=x86_64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
  -DAPP_REVERSED_DOMAIN="com.example.myapp"

cmake --build build-ios-felgo-simulator \
  --config Release \
  --target PastViewer \
  -- -sdk iphonesimulator -arch x86_64 CODE_SIGNING_ALLOWED=NO
```

```bash
xcrun simctl list devices available

xcrun simctl boot "YOUR_SIMULATOR_UDID" 2>/dev/null || true
open -a Simulator
xcrun simctl bootstatus "YOUR_SIMULATOR_UDID" -b
xcrun simctl install \
  "YOUR_SIMULATOR_UDID" \
  build-ios-felgo-simulator/bin/Release/PastViewer.app
xcrun simctl launch \
  "YOUR_SIMULATOR_UDID" \
  "com.example.myapp"
```

Keep device and simulator outputs separate. Reusing a CMake build directory across `iphoneos` and `iphonesimulator` commonly leaves incompatible cached architectures and frameworks.

### Android Emulator Build and Run

Use the Felgo Android ARM64 kit together with the macOS host kit from the same Felgo installation. Felgo already links and deploys its matching `libssl_3.so` and `libcrypto_3.so`, so this build does not require the `ext/android_openssl` checkout or a custom Qt build.

```bash
conan install . \
  --profile:host=profiles/android-release \
  --profile:build=default \
  --output-folder=build-android-felgo-emulator \
  --build=missing \
  -s:h=build_type=Release \
  -s:h=compiler.cppstd=20

path/to/Felgo/Felgo/android_arm64_v8a/bin/qt-cmake --fresh \
  -S . \
  -B build-android-felgo-emulator \
  -G Ninja \
  -DQT_HOST_PATH="path/to/Felgo/Felgo/macos" \
  -DCMAKE_PREFIX_PATH="path/to/4felgo/build-android-felgo-emulator" \
  -Dglog_DIR="path/to/4felgo/build-android-felgo-emulator" \
  -Dgflags_DIR="path/to/4felgo/build-android-felgo-emulator" \
  -DCMAKE_BUILD_TYPE=Release \
  -DANDROID_SDK_ROOT="path/to/Android/sdk" \
  -DANDROID_NDK_ROOT="path/to/Android/sdk/ndk/29.0.14206865" \
  -DANDROID_PLATFORM=android-33 \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON \
  -DANDROID_GRADLE_WRAPPER_VERSION=8.10.2 \
  -DAPP_REVERSED_DOMAIN=com.example.myapp

cmake --build build-android-felgo-emulator --target PastViewer --parallel
cmake --build build-android-felgo-emulator --target apk --parallel
```

Add the optional `OSM_API_KEY` and `SENTRY_DSN` options to `qt-cmake` when needed. The APK target writes an unsigned Release package to:

```text
build-android-felgo-emulator/android-build/build/outputs/apk/release/android-build-release-unsigned.apk
```

For emulator testing, sign that package with the standard Android debug key, then start an ARM64 AVD and install it:

```bash
path/to/Android/sdk/build-tools/36.0.0/apksigner sign \
  --ks "path/to/home/.android/debug.keystore" \
  --ks-key-alias androiddebugkey \
  --ks-pass pass:android \
  --key-pass pass:android \
  --v4-signing-enabled false \
  --out path/to/4felgo/build-android-felgo-emulator/android-build/build/outputs/apk/release/android-build-release-signed.apk \
  path/to/4felgo/build-android-felgo-emulator/android-build/build/outputs/apk/release/android-build-release-unsigned.apk

path/to/Android/sdk/emulator/emulator -avd YOUR_ARM64_AVD

path/to/Android/sdk/platform-tools/adb -e wait-for-device
path/to/Android/sdk/platform-tools/adb -e install -r \
  path/to/4felgo/build-android-felgo-emulator/android-build/build/outputs/apk/release/android-build-release-signed.apk
path/to/Android/sdk/platform-tools/adb -e shell am start -W -n \
  org.qtproject.PastViewer/org.qtproject.qt.android.bindings.QtActivity
```

The debug key is only for local emulator installation; sign release artifacts with the production keystore before distribution.
