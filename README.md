# CM Rewards

The Center Market loyalty app: earn points at every visit, redeem rewards, order
hot food ahead, check fuel prices and find a store. Built with Flutter for iOS
and Android, phones and tablets.

## Run it

```sh
flutter pub get
flutter run                 # pick a simulator or device
```

Tap **Explore in Demo Mode** on the sign-in screen to skip the phone number
step. In the demo, any 6-digit code works (`000000` shows the wrong-code
error), and the member pass has a "simulate a scan" button.

The app runs in one of three modes, decided at build time:

| Build | Sign-in | Member data |
| --- | --- | --- |
| Debug, or `--dart-define=CM_DEMO=true` | Simulated codes | Sample member "Akash" (no phone number, member CM 4821 093 517) |
| `--dart-define=CM_API_URL=https://...` | Real texts through the server ([docs/backend-api.md](docs/backend-api.md)) | Starts blank |
| Release with neither | Refused: "Sign-in isn't available yet" | Starts blank |

Demo builds say so: a DEMO tag on Home and "Demo build, sample data" at the
foot of Account. The bundled stores are samples (`sampleCatalog` in
`lib/data/catalog.dart`), so they list no phone numbers and Directions searches
Maps for Center Market in the store's city rather than a street address.

To try the real sign-in against a local server:
`flutter run --dart-define=CM_API_URL=http://127.0.0.1:8080` (plain HTTP is
allowed only for this machine).

## Points economy

| | |
| --- | --- |
| Earning | 10 points per \$1 (Regular 1.25×, Insider 1.5×) |
| Rewards | from 500 points (1L cool drink) up to 4,000 |
| Tiers (lifetime points) | Neighbor 0 · Regular 2,500 · Insider 6,000 |
| Referral | 50 points each, after the friend's first purchase |
| First Order Ahead | +250 points |

Values live in `lib/data/catalog.dart` (rewards, challenges),
`lib/data/models.dart` (tiers) and `RewardsState` (earn rate, bonuses).

## Project layout

```
lib/
  main.dart            entry point: orientation, saved state, runApp
  app.dart             MaterialApp, light and dark themes, text-scale cap
  core/
    theme.dart         brand colors (from the logo), CMColors tokens, type
    responsive.dart    breakpoints, ContentWidth, text-aware heights
    format.dart        numbers, money, phone, dates
  data/
    models.dart        Deal, Reward, Tier, Store, MenuItem, Order, ...
    catalog.dart       demo content: offers, rewards, stores, menu
  state/
    rewards_state.dart the app's single ChangeNotifier, plus persistence
  widgets/             shared UI: buttons, panels, brand motifs, codes
  screens/             one file per area: home, order, rewards, stores, ...
```

State lives in one `RewardsState`, reached through `RewardsScope.of(context)`
(rebuilds on change) or `RewardsScope.read(context)` (in callbacks).

## Design system

- **Colors** come from the logo: burgundy `#7C1335` and kelly green
  `#168A3B`. Use the semantic tokens in `context.cm` (`primary`, `positive`,
  `surface`, `muted`, ...) rather than raw colors, so dark mode keeps working.
- **Type**: Zilla Slab for display headings (echoes the wordmark), Plus
  Jakarta Sans for everything else. Both are bundled in `assets/fonts/`.
- **Motifs**: the logo's swooshes (`OrbitArcs`) and its four dots
  (`MarketDots`, the loading indicator).
- **Icons**: the app's own icon family, drawn in code in
  `lib/widgets/cm_icons.dart` (24-unit grid, 1.8 rounded stroke). Use
  `CMIcon(CMGlyph.x)`; it behaves like `Icon`. To review the whole set, run
  `flutter test test/tools/icon_sheet_test.dart --dart-define=OUT=icons.png`.
- **Screens**: to review every screen and sheet as PNGs without a device, run
  `flutter test test/tools/screens_test.dart --dart-define=OUT=shots
  --dart-define=DEVICE=ipad_pro_land` (also `se1`, `iphone`, `fold_open`,
  `ipad_mini`, `ipad_air`, `ipad_air_land`; add `THEME=dark` or `SCALE=2`).
  Layout errors are printed next to the screen that caused them.
- **Motion and shape**: use `Motion.fast/medium/slow` with `Motion.standard`,
  `Motion.emphasized` or `Motion.spring`, and `Radii.sm/md/lg/xl`, instead of
  one-off durations and radii.

## Device support

| Window width | Layout |
| --- | --- |
| under 360pt (iPhone SE 1st gen, folded Galaxy Z Fold) | compact phone |
| 360 to 839pt (phones, iPad portrait, unfolded foldables) | floating bottom bar, content capped at 680pt |
| 840pt and up (iPad landscape, iPad Pro) | side navigation rail; tab pages widen to 1120pt: two-column Home, paired menu and store lists, side-by-side tiers |

- Breakpoints follow the **window**, not the device, so iPad Split View and
  foldables get the layout that fits.
- Phones are locked to portrait. Tablets rotate freely, which iPad
  multitasking requires.
- Large accessibility text is honored up to 1.5×
  (`Breakpoints.maxTextScale`). Fixed-height carousels grow with the text
  through `context.textHeight(...)`.
- Light and dark mode, with a System / Light / Dark switch in Account.
- iOS 15+ (iPhone and iPad). Android 8.0+ (API 26, required by Sentry), with
  edge-to-edge and predictive back enabled.

## Tests

```sh
flutter test                                       # everything below
flutter test test/device_matrix_test.dart          # layout on 10 devices
flutter test integration_test -d <simulator-id> --dart-define=TOUR_THEME=dark   # every screen, for screenshots
flutter test integration_test/auth_network_test.dart -d <device-id>          # sign-in over the platform's HTTPS stack
```

- `widget_test.dart`: the main flows (sign-in, scanning, redeeming, Order
  Ahead, stores, account).
- `device_matrix_test.dart`: walks every major screen on 10 screen sizes,
  from a 320pt iPhone SE to a 13" iPad Pro, at normal and 2× text, in light
  and dark. Any overflow fails the test. It loads the real fonts so text is
  measured at true width.
- `migration_test.dart`: data saved by older versions still loads, and saved
  state (wallet, orders, settings) round-trips.
- `regression_test.dart`: bugs found in QA, kept fixed.
- `auth_test.dart`: the server sign-in client, and real-build behavior: no
  server means no sign-in, real members start blank, deletion waits for the
  server, crash reports carry no member details.

**When you add a screen**, add it to the tour in `device_matrix_test.dart`.

## Saved data and migrations

Member data is saved as JSON in encrypted storage (`flutter_secure_storage`:
iOS Keychain, Android Keystore-backed AES-GCM) under `cm_rewards_state`,
stamped with `RewardsState.schemaVersion`. Older plain-preference data (1.x and
2.0 previews) is migrated on first launch and the plain copy is deleted.
Schema 3 doubled balances when earning moved from 5 to 10 points per dollar.
Redeemed reward codes and active orders are saved, so they survive the app
being closed.

When you change the saved shape:

1. Read new fields with a fallback (`json['x'] as int? ?? default`) so older
   saves still load.
2. If the change can't be read compatibly, bump `schemaVersion` and add a step
   to `_restore`.
3. Add a case to `test/migration_test.dart`.

## Security

What the app does on the device:

- Member data encrypted at rest; excluded from Android cloud backup and
  device transfer (`allowBackup=false`, `data_extraction_rules.xml`).
- No plain HTTP (`usesCleartextTraffic=false`; iOS App Transport Security on).
- Release builds are obfuscated (`scripts/build_release.sh`).
- Sign-in fails closed: release builds verify codes with the server and
  refuse sign-in when none is configured. Real US number check, 5 wrong codes
  lock for 60 seconds, resends capped at 3. The session token lives in the
  same encrypted store.
- Crash reports (Sentry) carry no user, IP address, screenshot or view
  hierarchy.
- iOS network traffic uses Apple's URLSession and its TLS; Android uses Dart's.
- Double-tap protection on every button, so nothing is redeemed or ordered
  twice.
- Input validation and limits on names, emails and gifts (no gifting to
  yourself, 50 to 5,000 points).

What only a server can do: an app on someone's phone can always be modified,
so **points, rewards and codes must be issued and checked by the backend**.
The app should only display what the server says. In particular, the server
must own balances, verify OTP codes with rate limits, sign the rotating member
QR code, and make each reward code single-use.

## Release builds

```sh
DEMO=true scripts/build_release.sh apk     # demo APK for sales and testing

export CM_API_URL=https://<your server>
export CM_PRIVACY_URL=https://<published privacy policy>
export CM_TERMS_URL=https://<published terms of use>
scripts/build_release.sh appbundle         # Google Play
scripts/build_release.sh ipa               # App Store
```

The script runs the analyzer and tests first, then builds obfuscated, with
symbols in `build/symbols` and the obfuscation map in
`build/app/obfuscation.map.json` (keep both; never ship them). Non-demo
builds are refused without HTTPS `CM_API_URL`, `CM_PRIVACY_URL` and
`CM_TERMS_URL`: there's no sign-in without the server, and both stores
require a privacy policy for apps with accounts. Optional:

| Variable | Effect |
| --- | --- |
| `CM_SENTRY_DSN` | Turns on crash reporting (Sentry). A bad DSN never stops the app from starting. |
| `CM_ENV` | Crash report environment; defaults to `production` (or `demo`). |
| `SENTRY_AUTH_TOKEN`, `SENTRY_ORG`, `SENTRY_PROJECT` | After the build, `sentry_dart_plugin` uploads the debug symbols, dSYMs and obfuscation map so crash reports show real names (settings: `sentry:` in `pubspec.yaml`). |

### iOS

1. Open `ios/Runner.xcworkspace` in Xcode, select the Runner target, and under
   Signing & Capabilities pick your team (bundle ID
   `com.centermarkets.centerMarketsRewards`; change it there if you use another).
2. Create the app in App Store Connect with the same bundle ID.
3. `CM_API_URL=... CM_SENTRY_DSN=... scripts/build_release.sh ipa`, then
   upload `build/ios/ipa/*.ipa` with Transporter or `xcrun altool`.
4. In App Store Connect, App Privacy: answer to match
   `ios/Runner/PrivacyInfo.xcprivacy`: Phone Number (linked, app
   functionality) and Crash Data and Other Diagnostic Data (not linked, app
   functionality, only if Sentry is on). No tracking.
5. Export compliance is declared in `ios/Runner/Info.plist`
   (`ITSAppUsesNonExemptEncryption` = `NO`): on iOS every encrypted
   connection goes through Apple's URLSession (the server client through
   `cupertino_http`, Sentry through its native SDK) and member data through
   the Keychain, so the app's encryption is "limited to that within the Apple
   operating system", which Apple exempts from documentation in every country,
   France included. If you add a library that brings its own cryptography or
   makes HTTPS calls with Dart's `HttpClient` on iOS, revisit this.
   `integration_test/auth_network_test.dart` checks the URLSession path on a
   device.

### Android

Release signing reads `android/key.properties` (git-ignored). Copy
`android/key.properties.example`, which also has the `keytool` command for
creating an upload keystore. Enroll the app in Play App Signing; Google keeps
the app signing key and you upload with this key.

Without it, APKs are signed with the debug key (fine for your own phone) and
the script refuses to build an App Bundle. The app targets API 36 and needs
Android 8.0 (API 26) or later.

Bump `version:` in `pubspec.yaml` for each release.

## Before going live

Done in the app: real sign-in client, account deletion through the server,
crash reporting, privacy manifest, no sample data or fake payments outside
demo builds. Still needed, see [docs/backend-api.md](docs/backend-api.md):

- The server's sign-in and account-deletion endpoints.
- Server-owned points, rewards and transactions (now kept on the device). The
  member pass already shows a real, scannable QR code and Code 128 barcode of
  the member number (`test/codes_scan_test.dart` decodes them); a rotating,
  server-signed code would stop screenshots being reused.
- Order Ahead orders reaching stores, card and Apple Pay payments, and wallet
  passes.
- Real stores, menu, offers, fuel prices and hours (`lib/data/catalog.dart` is
  sample content with fictional 555 phone numbers).
- The store map (a drawn illustration; a maps SDK would replace it) and push
  notifications.
- Published Privacy Policy and Terms of use pages. centermarkets.com has
  neither yet; until the build sets `CM_PRIVACY_URL` and `CM_TERMS_URL`, the
  app shows no legal links rather than a wrong page.
