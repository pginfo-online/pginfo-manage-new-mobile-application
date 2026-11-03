# Release verification

Verification performed on 3 November 2026 against the local API and its
configured PostgreSQL database.

## Automated gates

- Backend formatting, TypeScript type checking, linting, Nest production build,
  and all 75 Vitest tests passed.
- Flutter formatting and static analysis passed.
- All 9 Flutter unit, widget, accessibility, and API-contract tests passed.
- Prisma reports all 5 migrations applied and the database schema up to date.
- Liveness and database readiness probes returned `ok`; readiness tolerates a
  bounded five-second hosted-database cold start.
- Android release compilation completed successfully.

Local verification artifact:

- Path: `build/app/outputs/flutter-apk/app-release.apk`
- Size: 57,902,680 bytes
- SHA-256: `5BE98A9149CBAE4809FB21668A29D5519C4752E8CE630EBCFC8080D9B5C7ED17`

This artifact was compiled with the non-routable verification URL
`https://example.invalid/api/v1`. It proves release compilation only and must
not be distributed. The production workflow injects the real HTTPS API URL,
Sentry DSN, and Android upload-keystore secrets to produce the signed,
obfuscated AAB.

## Live contract checks

The local API passed authenticated registration, property creation and
readback, property-owner persistence, lead statistics, and server-side search
plus pagination for rooms, dues, payments, and expenses. The wider connected
workflow also covers room/bed inventory, tenant onboarding, dues, partial
collection allocation, receipt retrieval, expense, lead, complaint,
announcement, report, dashboard, refresh-token, and concurrent-bed-allocation
flows.

File upload validation accepts the allowed JPEG content and returns HTTP 503 at
the storage boundary because the local Cloudinary values are placeholders. This
is the intended fail-closed behavior; no fake or local-only production URL is
created.

## Environment-owned validation

Device integration execution is configured in CI with an Android emulator. A
local emulator was not available on this workstation, and Windows Flutter
integration execution requires Developer Mode for plugin symlinks. Staging and
store distribution additionally require the environment secrets documented in
`implementation-status.md`.
