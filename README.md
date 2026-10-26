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
error), and the member pass has a "simulate a scan" button. Demo shortcuts are
on in debug builds and off in release builds unless built with
`--dart-define=CM_DEMO=true`.

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
- iOS 15+ (iPhone and iPad). Android follows Flutter's default `minSdk`, with
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
- Sign-in: real US number check, 5 wrong codes lock for 60 seconds, resends
  capped at 3.
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
scripts/build_release.sh apk         # Android APK (DEMO=true to keep demo shortcuts)
scripts/build_release.sh appbundle   # Google Play
scripts/build_release.sh ipa         # App Store (needs an Apple Developer account)
```

Android release signing reads `android/key.properties` (git-ignored):

```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

Without it, release builds are signed with the debug key, which is fine for
testing on your own phone but not for Google Play.

## Before going live

The app is fully interactive, but these parts are simulated and need a backend:

- Phone sign-in (OTP), Apple and Google sign-in
- Points, rewards and transactions (now kept on the device)
- Order Ahead payments and order status
- Fuel prices, store hours and busy times
- The member QR code and barcode (drawn, not scannable)
- The store map (a drawn illustration; a maps SDK would replace it)
- Push notifications
- Crash reporting: hook Sentry or Crashlytics into `ErrorReporting.report`
- Real Privacy Policy and Terms URLs (Account → Privacy & terms)

Also set a real release signing config in `android/app/build.gradle.kts`, and
bump `version:` in `pubspec.yaml` for each release (Account reads it from
the platform).
