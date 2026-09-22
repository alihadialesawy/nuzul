#!/bin/sh
set -e

# يثبّت Flutter تلقائيًا على بيئة بناء Xcode Cloud (ما فيها Flutter بشكل افتراضي)
git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter" --depth 1
export PATH="$PATH:$HOME/flutter/bin"

flutter --version
flutter precache --ios

# يرجع لجذر المشروع (CI_WORKSPACE متغيّر بيئة يوفره Xcode Cloud تلقائيًا،
# ويشاور على جذر المستودع نفسه) ويجهّز ملفات Flutter المطلوبة (من ضمنها
# ephemeral/Packages/FlutterGeneratedPluginSwiftPackage اللي كان ناقص)
cd "$CI_WORKSPACE"
flutter pub get

# يثبّت مكتبات CocoaPods (Stripe وغيرها)
cd ios
pod install
