# Implementation status

This repository started with the Flutter counter template. The current client is a substantial first implementation. The critical local API workflow was validated on 3 November 2026; production distribution still requires the release items below.

## Connected flows

- Authentication and registration, secure token storage, token refresh, sign out.
- Organization switching and membership role updates.
- Property selection/creation, room listing/filtering/creation/details, tenant creation/details/edit.
- Tenant passbook dues, charge creation, manual payment recording with a stable idempotency key per form, expenses, leads, announcements, complaints and bank payout onboarding.
- Dashboard metrics with validated month selection, reports CSV viewing/copying, receipt viewing/copying, entity activity history, and deep route paths.
- Lead editing, property staff creation/editing, complaint status management and announcement history.
- Tenant joining forms generated from authoritative tenant data with platform download/share support.
- Live local validation covers registration, refresh-token rotation, property/room/bed creation, tenant onboarding, dues, partial payment allocation, idempotency conflict handling, receipt retrieval, expenses, leads, complaint resolution, announcements, CSV reports and dashboard metrics.
- A live concurrent allocation check returned one 201 and one 409 for the same bed. Property-local date handling was also verified across the UTC/Asia-Kolkata boundary.

## Remaining release work

- Repeat the validated workflow against a dedicated staging environment before release; the current run used the local development database.
- Offset paginated lists currently show the first page. Infinite scrolling and server search should be added for high volume lists before a large rollout. Rooms are returned as an unpaginated property list by the backend.
- Several screens still use repositories directly from widget state. Move asynchronous coordination into dedicated feature ViewModels and repository interfaces to complete the requested MVVM boundaries.
- Add persistent attachment uploads to the backend. Images can currently be selected and shared locally.
- Receipt details are shared as text; CSV reports are materialized as files and handed to the platform save/share sheet. WhatsApp images also use the platform share sheet, which cannot force the target app.
- Expand server-backed statistics and filter variants where the backend currently exposes only aggregate dashboard metrics.
- Add larger test suites, staging contract tests, integration tests, accessibility audits, crash monitoring, app signing, and an actual production API URL.

No production readiness claim should be made until these items are complete and verified with the running backend.
