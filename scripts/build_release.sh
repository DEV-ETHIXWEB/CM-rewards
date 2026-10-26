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
#   CM_PRIVACY_URL, CM_TERMS_URL
#                  Published privacy policy and terms, https://... (required
#                  unless DEMO=true; App Store and Google Play need them)
#   CM_SENTRY_DSN  Sentry DSN; crash reporting is off without it
#   CM_ENV         Crash report environment (default: production, or demo)
#   SENTRY_AUTH_TOKEN, SENTRY_ORG, SENTRY_PROJECT
#                  Uploads debug symbols and the obfuscation map to Sentry
#                  (sentry_dart_plugin) so obfuscated crashes are readable.
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
  for name in CM_PRIVACY_URL CM_TERMS_URL; do
    if [[ "${!name:-}" != https://* ]]; then
      echo "Set $name to the published page, https://... (both stores require it)." >&2
      exit 1
    fi
  done
  if [[ "$target" == "apk" && ! -f android/key.properties ]]; then
    echo "Warning: android/key.properties is missing; this APK is signed with the debug key." >&2
  fi
fi

if [[ -n "${SENTRY_AUTH_TOKEN:-}" && ( -z "${SENTRY_ORG:-}" || -z "${SENTRY_PROJECT:-}" ) ]]; then
  echo "SENTRY_AUTH_TOKEN is set; also set SENTRY_ORG and SENTRY_PROJECT." >&2
  exit 1
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
[[ -n "${CM_PRIVACY_URL:-}" ]] && defines+=(--dart-define=CM_PRIVACY_URL="$CM_PRIVACY_URL")
[[ -n "${CM_TERMS_URL:-}" ]] && defines+=(--dart-define=CM_TERMS_URL="$CM_TERMS_URL")
[[ -n "${CM_SENTRY_DSN:-}" ]] && defines+=(--dart-define=CM_SENTRY_DSN="$CM_SENTRY_DSN")
[[ -n "${CM_ENV:-}" ]] && defines+=(--dart-define=CM_ENV="$CM_ENV")

# The obfuscation map turns obfuscated names back into real ones in Sentry.
mkdir -p build/app
flutter build "$target" --release \
  --obfuscate \
  --split-debug-info=build/symbols \
  --extra-gen-snapshot-options=--save-obfuscation-map=build/app/obfuscation.map.json \
  "${defines[@]}"

# Settings are in the `sentry:` section of pubspec.yaml.
if [[ -n "${SENTRY_AUTH_TOKEN:-}" ]]; then
  dart run sentry_dart_plugin
fi
