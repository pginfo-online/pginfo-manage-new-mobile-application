# PgInfo mobile

Flutter client for the PgInfo NestJS API. The app provides five persistent navigation tabs and backend connected property, room, tenant, money, people, and analytics workflows.

## Run

```sh
flutter pub get
dart run build_runner build
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

Use a reachable HTTPS API URL on real devices. `10.0.2.2` resolves to the development host from the Android emulator. Start the backend, PostgreSQL, and Redis as described in `../backend/README.md`.

## Verify

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.example/api/v1
```

See [architecture](docs/architecture.md) for API assumptions, security decisions, and current gaps.
