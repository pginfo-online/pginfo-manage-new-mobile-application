# PgInfo mobile architecture

The NestJS backend is authoritative for organization membership, inventory, tenant records, charges, payments and dashboard aggregates. Money is sent and received in integer paise. The client never calculates a payment's final state from a submitted request; lists and dashboard data are refreshed after a successful mutation.

`lib/core/network` owns Dio configuration, bearer token injection, one refresh attempt, request IDs and Problem Details errors. Tokens are stored in platform secure storage. Configure the server with `--dart-define=API_BASE_URL=https://your-host/api/v1`; the default `10.0.2.2` is only for an Android emulator talking to a local server.

`lib/app/di` owns Riverpod dependencies, paged ViewModels and selected property state. Selection changes create distinct property-scoped provider keys, preventing cross-property cache reuse. Debounced searches execute on the server and paged ViewModels append results without replacing already rendered records. The five bottom tabs use `StatefulShellRoute.indexedStack`, so each tab keeps its own route stack. Related detail sections use `TabBarView` for swipe navigation.

`lib/shared/models` contains immutable Freezed and JSON models for the stable property, room and resident response fields. The repository maps API responses and exposes feature data to screens. Financial mutations pass a client generated idempotency key, disable submission while pending, and never auto retry. Razorpay confirmation remains a server responsibility.

## External adapters

The reporting module exposes organization-scoped, paginated audit history and period-aware operational and financial metrics. Tenant joining forms are generated from authoritative resident data and can be downloaded or shared through the operating system. Uploads are MIME/size limited, organization-scoped and delegated to the Cloudinary adapter; fake or missing provider credentials fail closed. Report CSV is materialized as a file for the platform save/share sheet; receipt data can be shared as text. Bank onboarding uses the authoritative Razorpay Route owner contract and masks PAN metadata rather than persisting the full identifier.

`bootstrap.dart` initializes Sentry's Dart SDK only when `SENTRY_DSN` is supplied and disables default PII collection. Android/iOS identifiers use `com.pginfo.manage`; signing material and provider credentials are excluded from source control.

## Validation and release

Run `flutter pub get`, `dart run build_runner build`, `dart format lib test integration_test tool`, `flutter analyze`, and `flutter test`. CI also builds a release APK and runs the Android integration test on an emulator. The manually triggered staging workflow verifies HTTPS authentication, property and dashboard contracts. The production workflow refuses missing secrets and emits a signed, obfuscated AAB with symbol files.
