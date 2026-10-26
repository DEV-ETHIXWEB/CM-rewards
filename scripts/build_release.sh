#!/usr/bin/env bash
# Builds release artifacts with Dart obfuscation. Symbols needed to read
# crash stack traces are kept in build/symbols (keep them, don't ship them).
#
#   scripts/build_release.sh apk          # Android APK for sideloading/testing
#   scripts/build_release.sh appbundle    # Android App Bundle for Google Play
#   scripts/build_release.sh ipa          # iOS archive (needs Apple signing)
#
# Set DEMO=true to keep the demo shortcuts (any-code sign-in, simulated scan).
set -euo pipefail
cd "$(dirname "$0")/.."

target="${1:-apk}"
demo="${DEMO:-false}"

# Google Play rejects bundles signed with the debug key, which Gradle falls
# back to when android/key.properties is missing.
if [[ "$target" == "appbundle" && ! -f android/key.properties ]]; then
  echo "android/key.properties is missing; create it before building for Google Play." >&2
  exit 1
fi

flutter pub get
flutter analyze
flutter test

flutter build "$target" --release \
  --obfuscate \
  --split-debug-info=build/symbols \
  --dart-define=CM_DEMO="$demo"
