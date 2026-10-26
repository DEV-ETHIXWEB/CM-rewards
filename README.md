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
| Debug, or `--dart-define=CM_DEMO=true` | Simulated codes | Sample member "Akash" |
| `--dart-define=CM_API_URL=https://...` | Real texts through the server ([docs/backend-api.md](docs/backend-api.md)) | Starts blank |
| Release with neither | Refused: "Sign-in isn't available yet" | Starts blank |

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
DEMO=true scripts/build_release.sh apk                        # demo APK for sales and testing
CM_API_URL=https://api.example.com scripts/build_release.sh ipa        # App Store
CM_API_URL=https://api.example.com scripts/build_release.sh appbundle  # Google Play
```

The script runs the analyzer and tests first, refuses a non-demo build
without an HTTPS `CM_API_URL`, and builds obfuscated with symbols in
`build/symbols`. Other settings, all optional:

| Variable | Effect |
| --- | --- |
| `CM_SENTRY_DSN` | Turns on crash reporting (Sentry). |
| `CM_ENV` | Crash report environment; defaults to `production` (or `demo`). |
| `SENTRY_AUTH_TOKEN`, `SENTRY_ORG`, `SENTRY_PROJECT` | With `sentry-cli` installed, uploads `build/symbols` so obfuscated crashes are readable. |

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
5. Export compliance: the app's HTTPS uses standard TLS built into the Flutter
   engine, not Apple's. Apple treats that as "an industry standard algorithm,
   not provided within the Apple operating system", which needs a French
   encryption declaration only for distribution in France. For a US-only
   release, add `ITSAppUsesNonExemptEncryption` = `NO` to
   `ios/Runner/Info.plist`; otherwise answer the questions in App Store
   Connect and upload the declaration.

### Android

Release signing reads `android/key.properties` (git-ignored):

```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

Without it, APKs are signed with the debug key (fine for your own phone) and
the script refuses to build an App Bundle.

Bump `version:` in `pubspec.yaml` for each release.

## Before going live

Done in the app: real sign-in client, account deletion through the server,
crash reporting, privacy manifest, no sample data or fake payments outside
demo builds. Still needed, see [docs/backend-api.md](docs/backend-api.md):

- The server's sign-in and account-deletion endpoints.
- Server-owned points, rewards and transactions (now kept on the device), and
  a signed, scannable member QR code (now drawn, not scannable).
- Order Ahead orders reaching stores, card and Apple Pay payments, and wallet
  passes.
- Real stores, menu, offers, fuel prices and hours (`lib/data/catalog.dart` is
  sample content with fictional 555 phone numbers).
- The store map (a drawn illustration; a maps SDK would replace it) and push
  notifications.
- Real Privacy Policy and Terms URLs (Account → Privacy & terms currently opens
  the home page).
