#!/usr/bin/env bash
# Builds release artifacts with Dart obfuscation. Symbols needed to read
# crash stack traces are kept in build/symbols (keep them, don't ship them).
#
#   scripts/build_release.sh apk          # Android APK for sideloading/testing
#   scripts/build_release.sh appbundle    # Android App Bundle for Google Play
#   scripts/build_release.sh ipa          # iOS archive (needs Apple signing)
#
# Environment:
#   CM_API_URL     CM Rewards server, https://... (required unless DEMO=true)
#   DEMO=true      Demo build: sample member, simulated sign-in and scans
#   CM_SENTRY_DSN  Sentry DSN; crash reporting is off without it
#   CM_ENV         Crash report environment (default: production, or demo)
#   SENTRY_AUTH_TOKEN, SENTRY_ORG, SENTRY_PROJECT
#                  With sentry-cli installed, uploads build/symbols so
#                  obfuscated crash reports are readable.
set -euo pipefail
cd "$(dirname "$0")/.."

target="${1:-apk}"
demo="${DEMO:-false}"
api="${CM_API_URL:-}"

# A real build without a server can't sign anyone in; refuse to make one.
if [[ "$demo" != "true" ]]; then
  if [[ -z "$api" ]]; then
    echo "Set CM_API_URL to the CM Rewards server (or DEMO=true for a demo build)." >&2
    exit 1
  fi
  if [[ "$api" != https://* ]]; then
    echo "CM_API_URL must start with https://" >&2
    exit 1
  fi
fi

# Google Play rejects bundles signed with the debug key, which Gradle falls
# back to when android/key.properties is missing.
if [[ "$target" == "appbundle" && ! -f android/key.properties ]]; then
  echo "android/key.properties is missing; create it before building for Google Play." >&2
  exit 1
fi

flutter pub get
flutter analyze
flutter test

defines=(--dart-define=CM_DEMO="$demo")
[[ -n "$api" ]] && defines+=(--dart-define=CM_API_URL="$api")
[[ -n "${CM_SENTRY_DSN:-}" ]] && defines+=(--dart-define=CM_SENTRY_DSN="$CM_SENTRY_DSN")
[[ -n "${CM_ENV:-}" ]] && defines+=(--dart-define=CM_ENV="$CM_ENV")

flutter build "$target" --release \
  --obfuscate \
  --split-debug-info=build/symbols \
  "${defines[@]}"

if [[ -n "${SENTRY_AUTH_TOKEN:-}" ]]; then
  if command -v sentry-cli >/dev/null; then
    sentry-cli debug-files upload --include-sources build/symbols
  else
    echo "SENTRY_AUTH_TOKEN is set but sentry-cli isn't installed; symbols not uploaded." >&2
  fi
fi
