# BMRS admissions — mobile (Flutter)

Teacher-facing app for canvassing: offline-first lead capture, follow-up reminders with local notifications, and a marketing "School Highlights" tab.

## Run

```bash
cd mobile
flutter pub get
flutter run                   # on the running emulator/device
# Or point at a remote API:
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

The backend base URL defaults to:
- `http://10.0.2.2:4000` on Android emulator (host loopback)
- `http://localhost:4000` on iOS simulator / desktop / web

Override with `--dart-define=API_BASE_URL=...` as shown above.

## Architecture

```
lib/
├── main.dart                 — bootstraps SharedPreferences, SQLite, notifications, ProviderScope
├── app.dart                  — MaterialApp + session-aware routing (LoginScreen / HomeScreen)
├── providers.dart            — Riverpod providers wiring up the DI graph
├── core/
│   ├── config.dart           — runtime config (API base URL)
│   ├── auth_store.dart       — JWT + user profile in SharedPreferences
│   ├── api_client.dart       — Dio client that injects the Bearer token
│   ├── connectivity.dart     — connectivity_plus wrapper
│   └── notifications.dart    — flutter_local_notifications wrapper (FCM stubbed)
├── data/
│   ├── models.dart           — Lead, Reminder, Highlight, SyncStatus
│   ├── local_db.dart         — SQLite schema (leads, reminders)
│   ├── leads_repo.dart       — CRUD + sync-status bookkeeping
│   └── reminders_repo.dart
├── sync/
│   └── sync_engine.dart      — periodic + on-reconnect drain of pending writes
└── features/
    ├── auth/login_screen.dart
    ├── home/home_screen.dart — bottom-nav scaffold with sync-status icon
    ├── leads/leads_list_screen.dart
    ├── leads/lead_form_screen.dart
    ├── reminders/reminder_dialog.dart
    ├── reminders/reminders_screen.dart
    └── highlights/highlights_screen.dart
```

## Offline-first contract

Every write goes to SQLite first with `sync_status='pending'`. The
[`SyncEngine`](lib/sync/sync_engine.dart) runs every 2 minutes **and** whenever
`connectivity_plus` reports a flip back to online. It drains pending writes
with:

- **Leads** — bulk via `POST /leads/sync`. Each row's `sync_status` is set to
  `synced` on confirmation or `failed` on error (with a short reason saved as
  `last_sync_error`).
- **Reminders** — individual `POST /reminders` per pending row.

Each row carries `updatedAt` (client clock). The server does
last-write-wins conflict resolution: if `client.updatedAt <= server.updatedAt`
it keeps the server copy and responds with `conflict: true`.

The teacher dashboard shows Synced / Pending / Failed badges per lead. Failed
rows expose a "Retry" button that triggers a sync sweep; pull-to-refresh on
the list does the same.

## Notifications

Local notifications are scheduled through `flutter_local_notifications` when
the teacher creates a reminder — they fire even without connectivity. Push
(FCM / SNS) is intentionally stubbed for this first pass; the reminder log is
still synced to the backend so a later server-side push pipeline can take over.
