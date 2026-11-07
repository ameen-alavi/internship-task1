# EduSphere Institutional Workflow Platform

A responsive Flutter application for institutional workflow requests and enquiries. The UI currently uses mock, in-memory repositories; backend API integration is pending.

## Run locally

Requires a Flutter SDK compatible with the version used by the project.

```sh
flutter pub get
flutter run -d chrome
```

To run the tests and create a production web build:

```sh
flutter test
flutter build web --release
```

The web build is written to `build/web/`.

## Demo accounts

Both demo accounts use the password `EduSphere123!`:

- Requester: `user@edusphere.com`
- Approver: `kr.sharma@edusphere.com`

The demo credentials and role behavior are implemented by `MockAuthRepository`; replace this with the agreed backend authentication contract before production use.

## Architecture

The app separates screens, state, domain data, and data access:

```text
lib/
  core/          Shared routing, theme, constants, responsive helpers and widgets
  data/
    mock/        Demo users and mock initial data
    models/      Request, enquiry, user and notification models
    repositories/ Repository interfaces and mock implementations
  features/      Auth, dashboard, workflows, enquiries, approvals, notifications, profile
  providers/     ChangeNotifier state for auth, workflows, enquiries and notifications
test/            Repository, provider, screen and widget tests
web/             Flutter web entry point and PWA assets
```

`main.dart` constructs repositories and providers and injects them into the widget tree. Screens call providers; providers coordinate state and repository calls. The repository interfaces are the intended seam for replacing local behavior with backend clients.

## Current limitations

- Workflow requests, enquiries, notifications, demo registration and settings are local mock behavior; data is not persisted across restarts.
- No HTTP client, production authentication, backend endpoints, or server-side authorization has been integrated. API routes and payloads need agreement with the backend developer.
- Approval and enquiry behavior can be exercised with the two demo roles, but this does not replace server-side access control.
- The app has no hosted demo configured by default. A web build must be served from a static web host.
