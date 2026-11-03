# Implementation status

This repository started with the Flutter counter template. The current client and supporting backend contracts implement the requested operational workflows. The critical local API workflow was validated on 3 November 2026; production distribution requires environment-owned credentials listed below.

## Connected flows

- Authentication and registration, secure token storage, token refresh, sign out.
- Organization switching and membership role updates.
- Property selection/creation, room listing/filtering/creation/details, tenant creation/details/edit.
- Tenant passbook dues, charge creation, manual payment recording with a stable idempotency key per form, expenses, leads, announcements, complaints and bank payout onboarding.
- Dashboard metrics with validated month selection, reports CSV viewing/copying, receipt viewing/copying, entity activity history, and deep route paths.
- Lead editing, property staff creation/editing, complaint status management and announcement history.
- Tenant joining forms generated from authoritative tenant data with platform download/share support.
- Debounced server search and reusable Riverpod pagination for rooms, tenants, leads, staff, dues, collections and expenses.
- Persistent payment-proof, expense-receipt and tenant-document upload flows through a guarded Cloudinary adapter. The adapter fails closed when provider credentials are absent.
- Expanded tenant personal, rental, parent and document sections, plus complete create/edit forms.
- Sentry-compatible Dart crash reporting, custom deep links, production application identifiers and secret-driven Android signing/release automation.
- Live local validation covers registration, refresh-token rotation, property/room/bed creation, tenant onboarding, dues, partial payment allocation, idempotency conflict handling, receipt retrieval, expenses, leads, complaint resolution, announcements, CSV reports and dashboard metrics.
- A live concurrent allocation check returned one 201 and one 409 for the same bed. Property-local date handling was also verified across the UTC/Asia-Kolkata boundary.

## Environment handoff required for distribution

- Configure `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY` and `CLOUDINARY_API_SECRET`; uploads deliberately return 503 while placeholder or missing credentials are present.
- Configure the GitHub `staging` environment secrets and run the **Staging contract** workflow against the real HTTPS staging service.
- Configure the GitHub `production` environment API URL, Sentry DSN and Android upload-keystore secrets, then run **Mobile production release** to produce the signed, obfuscated AAB and symbols.
- Configure the corresponding Apple team, certificates and App Store provisioning profile when an iOS build is distributed.

These are credentials and external environments, not unfinished code paths; they cannot be safely committed to the repository.
