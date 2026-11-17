# PgInfo mobile

Flutter client for the PgInfo NestJS API. The app provides five persistent navigation tabs and backend connected property, room, tenant, money, people, and analytics workflows.

## Run

```sh
flutter pub get
dart run build_runner build
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

`10.0.2.2` resolves to the development host from the Android emulator. For a physical Android device on the same Wi-Fi, use your computer's LAN IP instead, for example `http://192.168.1.44:3000/api/v1`. HTTP is permitted only in Android debug builds; release builds require HTTPS. Start the backend, PostgreSQL, and Redis as described in `../backend/README.md`.



hh hdc uhuhuhu hgg  hnhy6 iina 99 8u  innsac7sac  hscs
] sdcnsc
\ jdjsdy7ew mjjewijd 
nscscns 
ncsdjcds u  jjduc ds
hfhscbds 
jfndsnsdy  je8e jj8 jjd jjdcyds jjjy ujjy nidjsh   jjuu  j


  dcwi ddi n win    8hhuuhsd uuuud nnndncds nnndcd hhe 



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
