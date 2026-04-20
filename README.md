# BMRS Canvassing Admissions 2026

Cross-platform admissions canvassing platform for BMRS:

- **Backend** (`/backend`) — Node.js + Express + Prisma + PostgreSQL + JWT auth
- **Mobile** (`/mobile`) — Flutter (Android/iOS) offline-first lead capture with local SQLite, sync engine, reminders, school highlights
- **Web** (`/web`) — React + Vite + TypeScript management dashboard with filters, analytics (Recharts), and CSV export

## Architecture at a glance

```
                   ┌──────────────────────────────────────┐
                   │          Postgres (Docker)           │
                   └──────────────────────────────────────┘
                                     ▲
                                     │ Prisma
                   ┌──────────────────────────────────────┐
                   │   Backend API (Express, JWT, Zod)    │
                   │   /auth · /leads · /reminders ·       │
                   │   /school-highlights · /admin/*       │
                   └──────────────────────────────────────┘
                       ▲                             ▲
                       │ axios + JWT                 │ dio + JWT + SQLite queue
                ┌──────┴──────┐              ┌───────┴────────┐
                │  Web (React) │              │ Mobile (Flutter)│
                │  management  │              │  offline-first  │
                └──────────────┘              └────────────────┘
```

Offline-first contract (mobile):

1. All writes land in SQLite first with a client-generated UUID and `updatedAt`.
2. A sync engine (periodic + on-reconnect) drains pending rows via `POST /leads/sync` (bulk) and `POST /reminders` (per-row).
3. Backend applies last-write-wins: if client `updatedAt > server.updatedAt`, overwrite; otherwise keep server copy and flag a conflict.
4. Reminders schedule local notifications immediately, so they fire even when offline, and sync to the server for cross-device visibility once back online.

## Quick start

```bash
# 1. Postgres
docker compose up -d

# 2. Backend (port 4000)
cd backend
cp .env.example .env
npm install
npx prisma migrate dev
npx prisma db seed
npm run dev

# 3. Web (port 5173)
cd ../web
npm install
npm run dev

# 4. Mobile
cd ../mobile
flutter pub get
flutter run   # choose device/emulator
```

### Seeded accounts

| Role    | Email                 | Password     |
| ------- | --------------------- | ------------ |
| Admin   | admin@bmrs.local      | admin12345   |
| Teacher | teacher@bmrs.local    | teacher12345 |

## Repository layout

```
.
├── backend/          Express API + Prisma schema + Jest tests
├── mobile/           Flutter app (offline-first)
├── web/              React dashboard
├── docker-compose.yml   Postgres 16 for local dev
└── .github/workflows/ci.yml   Lint, typecheck, test for all three packages
```

## Roadmap

This MVP runs on JWT auth and local notifications. Planned follow-ups:

- AWS Cognito for user pools + SSO
- AWS SNS / FCM for cross-device push
- AWS Amplify (or similar) for hosting
- Excel (.xlsx) export alongside CSV
- Teacher onboarding flow (admin can invite by email/SMS)
