# EduSphere Institutional Workflow Platform

A responsive Flutter application for institutional workflow requests and enquiries. The application is maintained in the [`feature/frontend-ui`](https://github.com/ameen-alavi/internship-task1/tree/feature/frontend-ui) branch, while this branch contains the project overview and setup guide.

**Live web demo:** [https://ameen-alavi.github.io/internship-task1/](https://ameen-alavi.github.io/internship-task1/)

## Run locally

Check out the application branch, then run the commands from the Flutter project directory:

```sh
git checkout feature/frontend-ui
cd frontend
flutter pub get
flutter run -d chrome
```

To run the tests and create a production web build:

```sh
flutter test
flutter build web --release --base-href "/internship-task1/"
```

The web build is written to `frontend/build/web/`.

## Demo accounts

Both demo accounts use the password `EduSphere123!`:

- Requester: `user@edusphere.com`
- Approver: `kr.sharma@edusphere.com`

These credentials and role behavior are implemented by the mock authentication repository. 

## Architecture

The app separates screens, state, domain data, and data access:

```text
frontend/lib/
  core/          Shared routing, theme, constants, responsive helpers and widgets
  data/
    mock/        Demo users and mock initial data
    models/      Request, enquiry, user and notification models
    repositories/ Repository interfaces and mock implementations
  features/      Auth, dashboard, workflows, enquiries, approvals, notifications, profile
  providers/     ChangeNotifier state for auth, workflows, enquiries and notifications
frontend/test/   Repository, provider, screen and widget tests
frontend/web/    Flutter web entry point and PWA assets
```

`main.dart` constructs repositories and providers and injects them into the widget tree. Screens call providers; providers coordinate state and repository calls. The repository interfaces are the intended seam for replacing local behavior with backend clients.

## Current limitations

- Requests, enquiries, notifications, demo registration, and settings use mock/local behavior; production backend integration is pending.
- No production authentication, backend endpoints, or server-side authorization has been integrated. API routes and payloads need agreement with the backend developer.
- Approval and enquiry behavior can be exercised with the two demo roles, but this does not replace server-side access control.
