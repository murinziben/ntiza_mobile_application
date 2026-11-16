# NTIZA — agricultural equipment & expert marketplace for Rwanda

NTIZA lets Rwandan farmers **find and book tractors, harvesters, pumps and other equipment**,
**consult agricultural experts**, **pay with Mobile Money** and **take short training courses**.
Equipment owners, experts and booking agents have their own dashboards, and an admin approves partners.

Built with **Flutter (Material 3)**, **Riverpod** for state management, **go_router**, and
**Firebase** (Authentication + Cloud Firestore). Runs on Android and iOS only (mobile app).

| | |
|---|---|
| Firebase project | `ntiza-e9af2` |
| State management | Riverpod 2 (`Notifier`, `StreamProvider`, `StateProvider`) |
| Architecture | Clean Architecture: `presentation` → `domain` ← `data` |
| Database | Cloud Firestore (see [`docs/ERD.md`](docs/ERD.md)) |
| Auth methods | E-mail + password (with e-mail verification and password reset) **and** Google |

## Screenshots

Screenshots are stored in [`docs/screenshots`](docs/screenshots). Add yours after running the app:

| Welcome | Marketplace | Booking | Owner dashboard | Admin |
|---|---|---|---|---|
| ![welcome](docs/screenshots/welcome.png) | ![market](docs/screenshots/marketplace.png) | ![booking](docs/screenshots/booking.png) | ![owner](docs/screenshots/owner.png) | ![admin](docs/screenshots/admin.png) |

## Features

| Role | What they can do |
|---|---|
| **Visitor** | Browse equipment, experts and courses; open the equipment detail page |
| **Farmer** | Register, verify e-mail, book equipment or an expert (calendar, duration, price summary), pay by MTN MoMo / Airtel Money (demo), track bookings, cancel / delete history, report a problem, receive notifications |
| **Equipment owner** | Add, edit, delete equipment; change status (Available / Booked / Maintenance); accept, decline and complete requests; earnings chart from real bookings |
| **Expert** | Set weekly availability and fee, accept or decline consultation requests, see earnings |
| **Booking agent** | Manage a list of farmers (add / edit / delete), book equipment on their behalf, see commission |
| **Admin** | Approve or reject partner applications, suspend / reactivate / delete users, resolve disputes, load demo data |
| **Everyone** | Settings: text size, notifications on/off, preferred district (saved with SharedPreferences), edit profile |

### Requirements checklist (course rubric)

| Requirement | Where |
|---|---|
| Advanced state management, no `setState` | Riverpod controllers in `lib/presentation/controllers`, providers in `lib/presentation/providers` |
| Clean Architecture | `lib/domain` (entities, repository interfaces, use cases), `lib/data` (Firebase), `lib/presentation` (screens, widgets, providers) |
| ERD + Firestore | [`docs/ERD.md`](docs/ERD.md), mappers in `lib/data/mappers/firestore_mappers.dart` |
| CRUD | Equipment, bookings, notifications, agent clients, disputes, profile, expert availability |
| Two auth methods | E-mail/password + Google; registration, login, logout, password reset, e-mail verification, session kept across restarts |
| Security rules | [`firestore.rules`](firestore.rules), indexes in [`firestore.indexes.json`](firestore.indexes.json) |
| SharedPreferences (≥ 3) | text size, notifications, preferred district, remembered e-mail, onboarding seen |
| Tests | `test/` — unit, widget and controller tests (`flutter test --coverage`) |

## Project structure

```
lib/
├── main.dart, app.dart            # entry point, MaterialApp.router
├── core/                          # theme, router (with role guards), formatters, errors
├── domain/                        # pure Dart — no Flutter, no Firebase
│   ├── entities/                  #   Equipment, Booking, AppUser, Expert, ...
│   ├── repositories/              #   abstract interfaces
│   ├── usecases/                  #   auth, booking, catalog, agent rules + pricing
│   └── validators.dart            #   input validation
├── data/                          # Firebase implementations of the interfaces
│   ├── mappers/                   #   Firestore map <-> entity
│   └── repositories/              #   Auth, Firestore, SharedPreferences
└── presentation/
    ├── controllers/               #   Riverpod Notifiers (ActionResult pattern)
    ├── providers/                 #   dependency injection + live Firestore streams
    ├── screens/                   #   public, auth, farmer, owner, agent, expert, admin, common
    └── widgets/                   #   reusable UI (cards, buttons, fields, chips)
test/                              # unit, widget and controller tests with in-memory fakes
docs/                              # ERD, report material, demo script
```

**Data flow:** a screen calls a controller (`ref.read(bookingControllerProvider.notifier)`),
the controller calls a use case in the domain layer (validation and business rules), the use case
calls a repository *interface*, and the Firebase implementation in `data` talks to Firestore.
Screens *watch* stream providers, so every change in Firestore appears instantly without a refresh.

## Team plan and Git workflow

We are five members. Nobody pushes to `main` directly (except the first setup by the leader).
Everybody works on **their own branch**, opens a **pull request (PR)**, and **another member reviews it**
before it is merged.

### Who owns what

| # | Member (GitHub) | Area | Layers they own | Presents in the demo video |
|---|---|---|---|---|
| **1** | **Leader** (`murinziben`) | Project setup, shared UI, state wiring, navigation | `core/`, `domain/entities`, `domain/repositories`, mappers, providers, `widgets/ui.dart`, router, `main.dart` | Architecture, Riverpod state, navigation, rotation |
| **2** | **ISHAMI Irené** (`ishami-i`) | Authentication, settings, notifications | auth use cases + repository + controller, auth screens, settings / edit profile / notifications screens | Register → verify → logout → login, Google sign-in, password reset, SharedPreferences |
| **3** | **Kabera Nshuti Samuel** (`KaberaSamuel`) | Farmer booking and payment | booking use cases, pricing, booking repository + controller, farmer screens | Book equipment, pay, cancel / delete booking (CRUD shown in Firebase Console) |
| **4** | **Maellene** (`Maellene`) | Public catalog and equipment owner | catalog use cases + repository + controller, public screens, owner screens, ERD | Marketplace, equipment add / edit / delete, ERD ↔ Firestore |
| **5** | **Ridaa** (`Ridaa11`) | Admin, booking agent, expert, security | admin / agent use cases + repository + controller, admin / agent / expert screens, `firestore.rules`, indexes, seed tool | Admin approvals, agent clients, security rules |

### Branches of each member

Create each branch only when its round starts (from an up-to-date `main`). The files for each branch are
listed in the rounds below.

| Member | Round 1 | Round 2 | Round 3 | Round 4 | Round 5 |
|---|---|---|---|---|---|
| **Leader** | `feature/core-domain` (Round 0, before the others) | `feature/state-wiring` | `feature/providers-barrel` (last) | reviews PRs | `feature/app-integration` |
| **Irené** | `feature/auth-data` | reviews | `feature/auth-controller` | `feature/auth-screens` | reviews |
| **Samuel** | `feature/booking-data` | reviews | `feature/booking-controller` | `feature/farmer-screens` | reviews |
| **Maellene** | `feature/catalog-data` | reviews | `feature/catalog-controller` | `feature/public-owner-screens` (first) | reviews |
| **Ridaa** | `feature/admin-data` | reviews | `feature/admin-controller` | `feature/admin-agent-expert-screens` | reviews |

In Round 6 everyone uses `fix/...` branches for their own screens (for example `fix/login-landscape-overflow`).

### What goes on `main` first (project setup only)

The leader pushes only the empty project setup to `main`, once. There is **no app code** in it:

```
.gitignore  .metadata  analysis_options.yaml  pubspec.yaml  pubspec.lock  README.md
android/                      # includes android/app/google-services.json
ios/
assets/
```

Everything else, including all of `lib/`, reaches `main` through branches and pull requests.
Never commit `build/`, `.dart_tool/`, `coverage/`, `tools/node_modules/` or `tools/serviceAccountKey.json`.

The app itself starts only after Round 5, when `main.dart` and the router arrive.

### Rounds — the order in which code reaches `main`

The layers depend on each other (screens need controllers, controllers need repositories), so we merge
from the bottom up. Inside a round the PRs can be merged in any order, unless a note says otherwise.
**Finish a round before starting the next one**, and always run `git pull origin main` before you create
a new branch.

#### Round 0 — shared core and domain (Leader)

Every feature needs these files, so this PR must be merged **before anybody starts Round 1**.

| Member | Branch | Files |
|---|---|---|
| Leader | `feature/core-domain` | `lib/firebase_options.dart`<br>`lib/core/errors/`, `lib/core/theme/`, `lib/core/utils/`<br>`lib/domain/constants.dart`, `lib/domain/validators.dart`<br>`lib/domain/entities/`<br>`lib/domain/repositories/` (the abstract interfaces = the contract between members)<br>`lib/data/mappers/`<br>`lib/data/repositories/firebase_errors.dart`<br>`test/core/formatters_test.dart`, `test/helpers/fakes.dart`<br>`design/` (Figma exports), `docs/` (except the ERD files, Maellene adds them) |

#### Round 1 — domain and data (Irené, Samuel, Maellene, Ridaa)

| Member | Branch | Files |
|---|---|---|
| Irené | `feature/auth-data` | `lib/domain/usecases/auth_usecases.dart`<br>`lib/data/repositories/firebase_auth_repository.dart`<br>`lib/data/repositories/prefs_settings_repository.dart`<br>`lib/data/repositories/firestore_notification_repository.dart`<br>`test/domain/validators_test.dart`<br>`test/data/settings_repository_test.dart` |
| Samuel | `feature/booking-data` | `lib/domain/usecases/pricing.dart`<br>`lib/domain/usecases/booking_usecases.dart`<br>`lib/data/repositories/firestore_booking_repository.dart`<br>`test/domain/pricing_test.dart` |
| Maellene | `feature/catalog-data` | `lib/domain/usecases/catalog_usecases.dart`<br>`lib/data/repositories/firestore_catalog_repository.dart`<br>`test/data/mappers_test.dart`<br>`docs/ERD.md`, `docs/erd.mmd`, `docs/erd.png` |
| Ridaa | `feature/admin-data` | `lib/domain/usecases/agent_usecases.dart`<br>`lib/data/sample_data.dart`<br>`lib/data/repositories/firestore_admin_repository.dart`<br>`firebase.json`, `firestore.rules`, `firestore.indexes.json`<br>`tools/README.md`, `tools/package.json`, `tools/package-lock.json`, `tools/seed.js` |

#### Round 2 — state wiring (Leader)

| Member | Branch | Files |
|---|---|---|
| Leader | `feature/state-wiring` | `lib/presentation/providers/dependencies.dart`<br>`lib/presentation/providers/data_providers.dart`<br>`lib/presentation/controllers/action_notifier.dart`<br>`lib/presentation/controllers/settings_controller.dart`<br>`lib/presentation/widgets/ui.dart` |

#### Round 3 — controllers (Irené, Samuel, Maellene, Ridaa, then the Leader)

| Member | Branch | Files |
|---|---|---|
| Irené | `feature/auth-controller` | `lib/presentation/controllers/auth_controller.dart` |
| Samuel | `feature/booking-controller` | `lib/presentation/controllers/booking_controller.dart` |
| Maellene | `feature/catalog-controller` | `lib/presentation/controllers/catalog_controller.dart` |
| Ridaa | `feature/admin-controller` | `lib/presentation/controllers/admin_controller.dart` |
| Leader | `feature/providers-barrel` | `lib/presentation/providers/providers.dart` — **merge last**, after the four controllers |

#### Round 4 — screens (Maellene merges first)

Other screens reuse `public_shell.dart`, `public/widgets.dart`, `role_widgets.dart` and
`provider_helpers.dart`, so **Maellene's PR must be merged before the other three**.

| Member | Branch | Files |
|---|---|---|
| Maellene (first) | `feature/public-owner-screens` | `lib/presentation/screens/public/` (8 files)<br>`lib/presentation/screens/common/role_widgets.dart`<br>`lib/presentation/screens/owner/` (2 files) |
| Irené | `feature/auth-screens` | `lib/presentation/screens/auth/` (7 files)<br>`lib/presentation/screens/common/settings_screen.dart`<br>`lib/presentation/screens/common/edit_profile_screen.dart`<br>`lib/presentation/screens/common/notifications_screen.dart`<br>`test/presentation/widgets_test.dart` |
| Samuel | `feature/farmer-screens` | `lib/presentation/screens/farmer/` (10 files)<br>`test/domain/usecases_test.dart` |
| Ridaa | `feature/admin-agent-expert-screens` | `lib/presentation/screens/admin/`<br>`lib/presentation/screens/agent/`<br>`lib/presentation/screens/expert/`<br>`test/presentation/controllers_test.dart` |

#### Round 5 — integration (Leader)

| Member | Branch | Files |
|---|---|---|
| Leader | `feature/app-integration` | `lib/core/router/app_router.dart`<br>`lib/app.dart`<br>`lib/main.dart`<br>`test/core/router_redirect_test.dart` |

After this PR the app runs on a phone or emulator: `flutter run`.

#### Round 6 — test, fix, document (everyone)

Each member runs the app, tests **their own** screens on a small and a large phone and in landscape,
fixes what is wrong on a `fix/...` branch, and adds screenshots of their screens to `docs/screenshots/`.
Before the final submission: `dart format .`, `flutter analyze` (0 issues), `flutter test --coverage`.

### How to do one round (every member, every time)

```bash
git checkout main
git pull origin main
git checkout -b feature/auth-data          # your branch name from the table

# add or edit your files, then:
dart format .
flutter analyze
flutter test

git add .
git commit -m "Add auth use cases with input validation"
git push -u origin feature/auth-data
```

Then on GitHub: **Compare & pull request** → describe what you added and how to test it → ask another
member to review. Merge only after one approval. **Do not delete your branch after the merge** — the
graders want to see a branch for every member.

### Rules for everyone

1. **Use your own GitHub account.** Run this once so your commits count for you:
   `git config user.name "Your Name"` and `git config user.email "the e-mail of your GitHub account"`.
2. **Several small commits, not one big one.** One idea per commit, with a clear message
   (`Add password reset screen`, `Fix overflow on marketplace in landscape`). Not `update` or `changes`.
3. **Spread the work over the days we have.** A dump on the last night loses marks.
4. **Review for real.** Read the code, run it, and leave at least one useful comment before approving.
   Each member should review at least two PRs from other members.
5. **Understand your part.** You will explain your code in the demo video and in the live presentation,
   so read every file you push, and change or improve it where needed.
6. **Only touch your own files.** If you need a change in somebody else's file, ask them or open a
   separate small PR, so we avoid merge conflicts.
7. **No `setState` for app state**, no secrets in the repository, and no web / desktop builds.

More detail (commit statistics for the report, repository settings): [`docs/GIT_WORKFLOW.md`](docs/GIT_WORKFLOW.md).

## Setup

### 1. Prerequisites
* Flutter 3.24 or newer (tested with 3.47) and an Android emulator or a physical phone
* A Firebase project (already configured: `lib/firebase_options.dart` and `android/app/google-services.json`)

### 2. Firebase console (one time)
1. **Authentication → Sign-in method:** enable **Email/Password** and **Google**
   (set a project support e-mail for Google).
2. **Project settings → Your apps → Android:** add your debug **SHA-1 and SHA-256**
   (`cd android && ./gradlew signingReport`), then download `google-services.json` again.
3. **Firestore Database → Create database** (production mode).
4. **Rules:** paste [`firestore.rules`](firestore.rules) and publish — or `firebase deploy --only firestore:rules`.
5. **Indexes:** `firebase deploy --only firestore:indexes` (the queries sort by `createdAt`).
   If you skip this, the first query logs a link that creates the missing index with one click.
6. **Create the admin:** register a normal account in the app, open **Firestore → users → (your uid)**
   and set `role` = `admin`, `status` = `active`. Log in again, then **More → Load demo data**.

### 3. Run
```bash
flutter pub get
flutter run                 # pick the emulator or the connected phone — not Chrome or desktop
flutter build apk --release # release APK in build/app/outputs/flutter-apk/
```

### 4. Quality checks
```bash
dart format .
flutter analyze
flutter test --coverage      # coverage report: coverage/lcov.info
```

## Security rules in one minute
* Everything is denied unless a rule allows it.
* A user reads and edits only **their own** profile (`name`, `phone`, `district`); roles and approval
  status can never be self-assigned; nobody can create an admin.
* Bookings are visible only to the farmer, the provider, the booking agent and admins; each side may
  change only the fields it is meant to (provider → `status`; farmer → `paidVia` or cancel while pending).
* Equipment is public to read; only an **approved owner** can create it and only for themselves.
* Notifications, agent clients and disputes are private to their owner / admin.

## Known limitations
* Mobile Money payment is **simulated** (a 2-second approval, then the booking is marked paid). A real
  charge needs a Cloud Function and MTN / Airtel merchant credentials.
* Equipment photos are chosen from the machine type; there is no image upload (Firebase Storage) yet.
* Push notifications (FCM) are not wired — notifications appear inside the app.
* The booking counter and notification writes happen on the client; before launch they should move to
  Cloud Functions.
* Dark theme and Kinyarwanda translations are future work.
