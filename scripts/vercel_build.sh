#!/usr/bin/env bash
# Builds the web demo on Vercel (vercel.json runs this). Vercel's build image
# has no Flutter, so the pinned SDK is cloned into .flutter-sdk; a machine that
# already has `flutter` on PATH uses its own.
#
# Environment:
#   CM_DEMO=false  Real build instead of the demo; then also set CM_API_URL,
#                  CM_PRIVACY_URL and CM_TERMS_URL (see scripts/build_release.sh)
#   FLUTTER_VERSION  SDK tag to install (default below)
set -euo pipefail
cd "$(dirname "$0")/.."

version="${FLUTTER_VERSION:-3.47.8}"

if ! command -v flutter >/dev/null; then
  # Flutter unpacks the Dart SDK with unzip, which the build image may lack.
  if ! command -v unzip >/dev/null && command -v dnf >/dev/null; then
    dnf install -y unzip >/dev/null
  fi
  if [[ ! -x .flutter-sdk/bin/flutter ]]; then
    git clone --depth 1 --branch "$version" https://github.com/flutter/flutter.git .flutter-sdk
  fi
  export PATH="$PWD/.flutter-sdk/bin:$PATH"
  flutter config --no-analytics >/dev/null
fi

flutter --version
flutter pub get

defines=(--dart-define=CM_DEMO="${CM_DEMO:-true}")
for name in CM_API_URL CM_PRIVACY_URL CM_TERMS_URL CM_SENTRY_DSN CM_ENV; do
  [[ -n "${!name:-}" ]] && defines+=(--dart-define="$name=${!name}")
done

flutter build web --release "${defines[@]}"
