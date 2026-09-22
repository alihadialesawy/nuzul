#!/bin/sh
# Xcode Cloud post-clone hook for FLYNOOM (Flutter)
# Installs Flutter, generates iOS ephemeral files, installs CocoaPods if needed.

set -e
set -x

echo "=== FLYNOOM ci_post_clone: start ==="
echo "CI_PRIMARY_REPOSITORY_PATH = $CI_PRIMARY_REPOSITORY_PATH"

# 1) Go to the repository root (where pubspec.yaml lives)
cd "$CI_PRIMARY_REPOSITORY_PATH"
ls -la

if [ ! -f "pubspec.yaml" ]; then
  echo "ERROR: pubspec.yaml not found in $(pwd)"
  exit 1
fi

# 2) Install Flutter (stable)
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter --version
flutter config --no-analytics

# 3) iOS artifacts + dependencies
flutter precache --ios
flutter pub get

# 4) Generate Generated.xcconfig + ephemeral Swift package (no code signing here)
flutter build ios --config-only --release --no-codesign

# 5) CocoaPods only if the project still uses a Podfile
cd ios
if [ -f "Podfile" ]; then
  echo "=== Podfile found: installing CocoaPods ==="
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
  pod install
else
  echo "=== No Podfile: Swift Package Manager only, skipping pod install ==="
fi

echo "=== FLYNOOM ci_post_clone: done ==="
exit 0
