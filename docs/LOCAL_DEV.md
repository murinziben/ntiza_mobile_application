# Local development with Firebase emulators + Mailpit

No access to the real `ntiza-e9af2` project is needed. Needs Java, Node and Docker.

1. Mailpit (inbox at http://localhost:8025):
   `docker run --rm -p 8025:8025 -p 1025:1025 axllent/mailpit`
2. Emulators (UI at http://localhost:4000):
   `npx firebase-tools emulators:start --project ntiza-e9af2`
3. Forward verification / reset links to Mailpit:
   `node tool/emulator/mail_bridge.mjs`
4. Seed users and equipment (`farmer`, `farmer2-4`, `owner`, `owner2`, `expert`, `agent`, `admin` @ntiza.test, password `Password123!`; each owner gets 3 machines; safe to re-run):
   `node tool/emulator/seed_users.mjs`
5. Run the app (Waydroid host is 192.168.240.1; Android emulator 10.0.2.2):
   `flutter run -d <device> --dart-define=USE_EMULATOR=true --dart-define=EMULATOR_HOST=192.168.240.1`

Links in Mailpit point at `localhost:9099`: open them in your computer's browser, not on the device.
Google sign-in does not work against the emulator; use e-mail and password.
