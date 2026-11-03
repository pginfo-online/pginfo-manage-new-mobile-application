# PgInfo mobile

Flutter client for the PgInfo NestJS API. The app provides five persistent navigation tabs and backend connected property, room, tenant, money, people, and analytics workflows.

## Run

```sh
flutter pub get
dart run build_runner build
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

Use a reachable HTTPS API URL on real devices. `10.0.2.2` resolves to the development host from the Android emulator. Start the backend, PostgreSQL, and Redis as described in `../backend/README.md`.

Crash reporting is opt-in through `--dart-define=SENTRY_DSN=...` and `--dart-define=APP_ENVIRONMENT=staging|production`. Production Android signing reads `android/key.properties`; copy `android/key.properties.example` locally or use the secret-driven release workflow. Never commit signing material or provider credentials.

## Verify

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.example/api/v1
```

See [architecture](docs/architecture.md) for API assumptions and security
decisions, [implementation status](docs/implementation-status.md) for the
environment handoff, and [release verification](docs/verification.md) for the
latest test evidence and artifact checksum.
