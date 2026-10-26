# CM Rewards server API

What the app expects from the CM Rewards server. The client is
`lib/data/auth_api.dart`; the server's base URL is set at build time with
`--dart-define=CM_API_URL=https://...` and must be HTTPS.

## Status

| Area | App side | Server needed |
| --- | --- | --- |
| Phone sign-in (text a code, verify it) | Done: `HttpAuthApi` | **Yes**: endpoints below |
| Sign out | Done | Optional: `POST v1/auth/logout` |
| Account deletion (App Store 5.1.1(v)) | Done: waits for the server | **Yes**: `DELETE v1/account` |
| Points, rewards, purchase history | Kept on the device | Not built yet: needs POS integration |
| Order Ahead | Menu and bag work; checkout is disabled outside demo builds, since stores can't receive orders yet | Not built yet |
| Card and Apple Pay payments | Hidden outside demo builds | Not built yet: needs a payment processor |
| Apple Wallet / Google Wallet pass | Hidden outside demo builds | Not built yet: passes must be signed server-side |
| Stores, menu, offers, rewards catalog | Bundled sample content in `lib/data/catalog.dart` | Real content needed |
| Notifications, challenge progress | Sample ones show only in demo builds | Push service and challenge tracking |

Until the "not built yet" rows exist, a real build can sign members in but
their points never change and they can't order ahead. Ship demo builds
(`DEMO=true`) for sales and testing until then.

## Conventions

- JSON bodies, `Content-Type: application/json`, UTF-8.
- Phone numbers in E.164: `+15035550123`. The app only accepts US numbers.
- Authenticated calls send `Authorization: Bearer <token>`.
- Rate limits answer `429`; the app tells the member to wait.
- Rate limits and lockouts must be enforced here. The app's own limits
  (5 tries, 3 resends, 60-second lockout) only keep honest members informed.

## Endpoints

### `POST v1/auth/code`

Texts a 6-digit code.

```json
{ "phone": "+15035550123" }
```

| Status | Meaning |
| --- | --- |
| `2xx` | Code sent. Body ignored. |
| `400` with `{"error": "invalid_phone"}` | Not a textable number. |
| `429` | Too many codes for this number or device. |

### `POST v1/auth/verify`

```json
{ "phone": "+15035550123", "code": "123456" }
```

| Status | Meaning |
| --- | --- |
| `200` with `{"token": "..."}` | Signed in. The app keeps the token in the Keychain / Android Keystore. |
| `400`, `401` or `403` | Wrong or expired code. Optional `{"attemptsLeft": 3}` is shown to the member. |
| `429` | Locked out for now. |

A `200` without a non-empty `token` is treated as a server error.

### `POST v1/auth/logout` (authenticated)

Revokes the token. Best effort: the app signs out locally whatever the answer.

### `DELETE v1/account` (authenticated)

Permanently deletes the member and their data. Answer `2xx` only once the
deletion is done or irrevocably scheduled; on any other answer the app keeps
the account and asks the member to try again.

## Privacy

The app sends the phone number for sign-in. `ios/Runner/PrivacyInfo.xcprivacy`
and the App Store privacy answers declare it as collected, linked to the
member, and used for app functionality only. When points or orders start
syncing, add Purchase History (and Name, if sent) to both.
