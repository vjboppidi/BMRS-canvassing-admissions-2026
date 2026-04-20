# BMRS Admissions — Web Dashboard

React + Vite + TypeScript management console for the BMRS admissions team.

## Features

- **Login** — JWT auth against the backend (`POST /auth/login`). Session persists in `localStorage`; on reload it is validated against `/auth/me`.
- **Leads** — filterable table across all teachers (admin) or the signed-in teacher's own leads (teacher). Filters: teacher, class, status, location, date range, free-text search. One-click CSV export (Excel-compatible, UTF-8 BOM).
- **Analytics** (admin) — Leads per teacher with conversion rate, leads per class, 30-day timeseries. Charts render with Recharts.
- **Highlights** — View the school highlights shown to parents through the mobile app. Admins can add or remove entries.

## Tech

- [Vite](https://vitejs.dev/) + React 18 + TypeScript
- [@tanstack/react-query](https://tanstack.com/query/latest) for data fetching
- [react-router-dom](https://reactrouter.com/) for routing
- [recharts](https://recharts.org/) for charts
- [axios](https://axios-http.com/) for HTTP
- [date-fns](https://date-fns.org/) for date formatting

## Getting started

```bash
cd web
npm install
npm run dev   # http://localhost:5173
```

The dev server expects the backend at `http://localhost:4000`. Override with
`VITE_API_BASE_URL` in `web/.env` if your backend lives elsewhere.

## Scripts

| Script | Purpose |
| ------ | ------- |
| `npm run dev` | Vite dev server with HMR |
| `npm run build` | Production build (TypeScript project build + Vite bundle) |
| `npm run typecheck` | `tsc --noEmit` on app config |
| `npm run lint` | ESLint (flat config) |
| `npm run preview` | Serve the production bundle locally |

## Default credentials

Seeded on the backend via `npx prisma db seed`:

| Role    | Email                 | Password     |
| ------- | --------------------- | ------------ |
| Admin   | admin@bmrs.local      | admin12345   |
| Teacher | teacher@bmrs.local    | teacher12345 |
