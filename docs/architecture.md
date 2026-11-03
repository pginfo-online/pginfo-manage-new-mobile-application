# PgInfo mobile architecture

The NestJS backend is authoritative for organization membership, inventory, tenant records, charges, payments and dashboard aggregates. Money is sent and received in integer paise. The client never calculates a payment's final state from a submitted request; lists and dashboard data are refreshed after a successful mutation.

`lib/core/network` owns Dio configuration, bearer token injection, one refresh attempt, request IDs and Problem Details errors. Tokens are stored in platform secure storage. Configure the server with `--dart-define=API_BASE_URL=https://your-host/api/v1`; the default `10.0.2.2` is only for an Android emulator talking to a local server.

`lib/app/di` owns Riverpod dependencies and selected property state. Selection changes invalidate property scoped room, resident and dashboard providers. The five bottom tabs use `StatefulShellRoute.indexedStack`, so each tab keeps its own route stack. Related detail sections use `TabBarView` for swipe navigation.

`lib/shared/models` contains immutable Freezed and JSON models for the stable property, room and resident response fields. The repository maps API responses and exposes feature data to screens. Financial mutations pass a client generated idempotency key, disable submission while pending, and never auto retry. Razorpay confirmation remains a server responsibility.

## Current backend gaps

The reporting module exposes organization-scoped, paginated audit history for supported entities. Tenant joining forms are generated from authoritative resident data and can be downloaded or shared through the operating system. Images can be selected locally and passed to the platform share sheet, but the backend has no persistent media upload endpoint. Report CSV is materialized as a file for the platform save/share sheet; receipt data can be shared as text. There is no generic bank payee API; the Bank screen uses payout owner onboarding, whose required fields differ from a general payee form.

## Validation and release

Run `flutter pub get`, `dart run build_runner build`, `dart format lib test`, `flutter analyze`, and `flutter test`. CI also builds a release APK. The critical API workflow was exercised against the local backend on 3 November 2026, including refresh rotation and payment idempotency. Before distribution, set the production API URL, configure Android/iOS signing, repeat the workflows against staging, and complete mobile privacy/security review.
