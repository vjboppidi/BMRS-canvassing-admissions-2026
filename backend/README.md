# BMRS admissions — backend

Node.js + Express + TypeScript + Prisma + PostgreSQL.

## Run locally

```bash
# From repo root, start Postgres
docker compose up -d db

# Install + generate Prisma client
cd backend
cp .env.example .env
npm install
npx prisma migrate dev --name init
npx prisma db seed

# Start dev server
npm run dev
```

Default server: <http://localhost:4000>

### Seeded accounts

| Email               | Password       | Role    |
|---------------------|----------------|---------|
| `admin@bmrs.local`  | `admin12345`   | ADMIN   |
| `teacher@bmrs.local`| `teacher12345` | TEACHER |

## Tests

```bash
npm run lint
npm run typecheck
npm test
```

API integration tests that touch the DB are intentionally omitted from
`npm test` — those require a real Postgres and are expected to run in CI
with a Postgres service container.

## Environment variables

See [`.env.example`](./.env.example).
