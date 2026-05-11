# Status - Social Capital

A status-based messaging app where social capital determines access. Currently geofenced to NYC.

## How It Works

**Status is a resource.** You get 5 points per week. Give them to people you respect. Buy more if you want.

- **Message down** — if you have more status than someone, you can DM them
- **Message up through chains** — give status to someone connected to who you want to reach (transitive intros, 1 hop)
- **Broadcast daily** — one ephemeral broadcast per day, reaches everyone who gave you status + their network. Disappears in 24 hours
- **Leaderboard** — ranked by incoming status weighted by giver's status (log2 scaling). Rolling window
- **Decay** — all status transactions expire after 90 days to keep the graph alive

## Features

- **Auth** — email/password via Firebase Auth
- **Status economy** — give, receive, weekly refill, paid top-ups, 90-day decay, transitive messaging
- **Real-time messaging** — Firestore listeners, conversation management
- **E2E encryption** — P256 ephemeral keys per message with forward secrecy, double encryption (sender + recipient copies), AES-GCM
- **Ephemeral broadcasts** — 1/day, 24h expiry, audience based on status graph
- **Leaderboard** — weighted scoring, podium for top 3, scope picker (weekly/monthly/all time)
- **Discovery** — user search (Firestore prefix matching), suggested users
- **Block/mute** — block with reason, report (costs status), enforced in messaging + broadcasts
- **Push notifications** — Firebase Cloud Functions trigger on new messages, broadcasts, and status received
- **Profile photos** — Firebase Storage upload, avatar display everywhere
- **StoreKit 2** — 3 consumable point packs ($0.99 / $2.99 / $7.99)
- **Onboarding** — 4-page tutorial + first-status flow after signup
- **Geofence** — NYC only (CoreLocation bounding box check)
- **Deep links** — `status://profile/{userId}`, `status://give/{userId}`
- **App icon** — black/white up-arrow

## Tech Stack

- **iOS 17+** — SwiftUI with `@Observable` (not ObservableObject)
- **Swift 5.9** — strict concurrency, `@MainActor` services
- **Firebase** — Auth, Firestore, Storage, Messaging, Cloud Functions
- **CryptoKit** — P256 ECDH, AES-GCM, HKDF for E2E encryption
- **StoreKit 2** — async/await IAP
- **XCodeGen** — `project.yml` generates `.xcodeproj`

## Architecture

```
Status/
  App/              — StatusApp entry point, RootView (auth/location gate)
  Models/           — User, Message, Conversation, Broadcast, StatusTransaction, Block, LeaderboardEntry
  Services/         — AuthService, StatusEngine, MessageService, BroadcastService,
                      LeaderboardService, BlockService, CryptoService, NotificationService,
                      StorageService, StoreService, LocationGate, FirestoreService
  Features/
    Auth/           — AuthView, OnboardingView, FirstStatusView, LocationGateView
    Feed/           — FeedView, ComposeBroadcastView, BroadcastCard
    Messages/       — ConversationsView, ChatView, MessageBubble
    Leaderboard/    — LeaderboardView, PodiumView, LeaderboardRow
    Profile/        — ProfileView, EditProfileView, StoreView, StatusHistoryView
    StatusGiving/   — GiveStatusView, UserSearchView
    Shared/         — AvatarView
  Navigation/       — MainTabView, DeepLinkHandler
  Resources/        — Status.storekit
functions/          — Cloud Functions (onNewMessage, onNewBroadcast, onStatusGiven)
```

**Patterns:**
- `@Observable` + Environment DI (no frameworks)
- NavigationStack per tab
- `@preconcurrency import` for Firebase modules
- Lazy Firestore initialization (`@ObservationIgnored` backing store)
- AsyncThrowingStream for real-time Firestore listeners
- Feature-based folder structure

## Security

- **Firestore rules** — users own their documents, participants-only conversations, sender-only transactions
- **Storage rules** — owner-only avatar uploads, 5MB limit, image-only
- **E2E encryption** — messages encrypted client-side with ephemeral keys, plaintext never stored server-side
- **Forward secrecy** — fresh P256 key pair per message, ephemeral private key discarded after encryption
- **Double encryption** — each message encrypted for both recipient and sender (standard Signal/iMessage approach)
- **Keychain** — identity private keys stored in iOS Keychain, never leave the device

## Testing

**181 tests total:**
- 143 unit tests across 19 suites (Swift Testing framework)
- 38 UI tests across 8 suites (XCUITest)

Covers: status economy rules, messaging paths, transitive chains, block enforcement, broadcast audience, forward secrecy proof, deep link parsing, location gate, all models, all services, onboarding flow, auth flow, all main app screens.

## Setup

### Prerequisites
- Xcode 16+
- [XCodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Firebase CLI (`npm install -g firebase-tools`)
- Node.js 20+ (for Cloud Functions)

### Build
```bash
xcodegen generate
open Status.xcodeproj
# Set StoreKit Configuration in scheme: Product > Scheme > Edit Scheme > Run > Options > Status.storekit
# Cmd+R to run
```

### Firebase
```bash
firebase login
firebase deploy --only firestore:rules    # Security rules
firebase deploy --only firestore:indexes  # Composite indexes
firebase deploy --only storage            # Storage rules
firebase deploy --only functions          # Cloud Functions (requires Blaze plan)
```

### Firebase Console Setup
1. **Auth** — enable Email/Password sign-in
2. **Firestore** — created automatically
3. **Storage** — enable in console, rules deployed via CLI
4. **Cloud Messaging** — upload APNs key (.p8) in project settings

### App Store Connect
- Bundle ID: `com.statusapp.Status`
- 3 consumable IAPs: `com.statusapp.points.5/15/50`
- APNs key uploaded to Firebase

### Tests
```bash
# Unit tests
xcodebuild -project Status.xcodeproj -scheme Status \
  -destination 'platform=iOS Simulator,name=iPhone 16' test

# UI tests only
xcodebuild -project Status.xcodeproj -scheme Status \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:StatusUITests test
```

## Encryption

Messages use E2E encryption with forward secrecy:

1. **Signup** — P256 identity key pair generated, public key published to Firestore, private key stored in Keychain
2. **Send** — fresh ephemeral P256 key pair → ECDH with recipient's public key → HKDF → AES-GCM encrypt. Ephemeral private key discarded. Message encrypted separately for both recipient and sender
3. **Receive** — recipient's identity private key + sender's ephemeral public key → same ECDH shared secret → AES-GCM decrypt
4. **Forward secrecy** — each message uses a unique ephemeral key. Compromising the identity key cannot decrypt past messages

Future: full Signal Protocol via [libsignal](https://github.com/signalapp/libsignal) ([Issue #1](https://github.com/khalildh/status-app/issues/1))

## Status Economy

| Rule | Details |
|------|---------|
| Weekly refill | 5 points, checked on profile load |
| Paid top-ups | 5 ($0.99), 15 ($2.99), 50 ($7.99) |
| Decay | 90-day rolling window on all transactions |
| Messaging down | Higher status → can DM lower |
| Transitive messaging | You → intermediary → target (1 hop) |
| Broadcast audience | People who gave you status + transitive |
| Leaderboard weight | `log2(giver_status + 1)` — diminishing returns |
| Block penalty | Report costs target -10 weighted status |
| Self-send prevention | Cannot give status to yourself |
