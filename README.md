# SwipeClean

Production-ready scaffold for SwipeClean with:
- **Backend**: .NET 8 Web API, Clean Architecture, EF Core, PostgreSQL, JWT + refresh tokens, SMTP email confirmation, Docker.
- **Mobile**: Flutter app with auth flow, secure token storage, dio refresh interceptor, photo swipe workflow.

## Repository layout

```text
SwipeClean/
  backend/
  mobile/
```

## Backend setup

1. Configure environment variables from `.env.example`.
2. Run locally (from `SwipeClean/backend`):
   - `dotnet build`
   - `dotnet ef migrations add Initial --project src/SwipeClean.Infrastructure --startup-project src/SwipeClean.API`
   - `dotnet run --project src/SwipeClean.API`
3. Run dockerized stack:
   - `docker compose up --build`

## Mobile setup

1. In `SwipeClean/mobile` set `.env` with `API_BASE_URL`.
2. Run:
   - `flutter pub get`
   - `flutter analyze`
   - `flutter run`

## Production build instructions

### Backend deployment
- Build container image from `SwipeClean/backend/Dockerfile`.
- Set production environment variables:
  - `ConnectionStrings__DefaultConnection`
  - `Jwt__Issuer`, `Jwt__Audience`, `Jwt__SecretKey`
  - SMTP values (`Smtp__Host`, `Smtp__Port`, `Smtp__Username`, `Smtp__Password`, `Smtp__FromEmail`, `Smtp__FromName`, `Smtp__UseStartTls`)
- Deploy API and PostgreSQL in your orchestrator (Kubernetes, ECS, Docker Swarm).

### Android build
- `flutter build apk --release`
- or `flutter build appbundle --release` for Play Store.

### iOS build
- `flutter build ios --release`
- Open generated Xcode workspace, configure signing, archive, and distribute.
