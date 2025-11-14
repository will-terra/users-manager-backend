# Users Manager — Backend

## Important: create a `.env` file

Before running the backend, create a `.env` file based on the provided example. Rename or copy `backend/.env.example` to `backend/.env` and update any values as needed (secrets, database URL, etc.). Example:

```bash
cd backend
cp .env.example .env
```

This repository also includes a `frontend/.env.example` — do the same for the frontend when running it locally.

This document explains how to run the Rails backend for the Users Manager app in development and inside Docker, how background jobs work, and where to find configuration and tests.

Contents

- Quick overview
- Prerequisites
- Local setup (without Docker)
- Run with Docker (recommended)
- Background jobs
- ActiveStorage / uploads
- Tests and linters
- Configuration & environment variables
- Troubleshooting

## Quick overview

---

The backend is a Rails API application that provides JSON endpoints consumed by the React frontend. Key features:

- Authentication with Devise + devise-jwt (JWT issued at sign in/up and revoked on sign out).
- Authorization with Pundit (admin vs user access control).
- ActiveStorage for avatar uploads (local disk in development).
- Background jobs for imports and image processing (see `bin/jobs`).
- Realtime updates via ActionCable channels (admin stats, import progress).

## Prerequisites

---

- Ruby 3.x (the project is compatible with the latest stable Ruby 3.x series used when it was developed)
- Bundler
- PostgreSQL (or the Docker Compose setup can provide Postgres)
- Node & Yarn/PNPM are required only if you want to compile frontend assets from the backend app (this repo uses a separate frontend app)

## Local setup (without Docker)

---

1. Install dependencies and setup the database:

```bash
cd backend
bundle install
bundle exec rails db:create db:migrate db:seed
```

2. Start the Rails server (default port used by the repo is 3001):

```bash
bundle exec rails s -p 3001
```

3. Start background job worker(s) to process imports and avatar processing:

```bash
# the repository includes `bin/jobs` for running jobs (it uses the configured queue adapter)
bin/jobs start
```

## Background jobs

---

- Background jobs are required to process imported spreadsheets, download remote files (spreadsheet or avatar images), and to process image variants.
- Use the provided runner `bin/jobs` in development. When running via Docker, make sure the jobs service (configured in `docker-compose.yml`) is up.

## ActiveStorage / uploads

---

- Development uses local disk storage for ActiveStorage (see `config/storage.yml`). For production, configure an object store (S3 or similar) and set the appropriate ENV vars.
- Uploaded avatars are attached to the user via `has_one_attached :avatar` and are processed by the `avatar_processing_job` after attach.

## Tests and linters

---

Run the backend test suite (RSpec):

```bash
cd backend
bundle exec rspec
```

RuboCop is available for style checks if configured in the repo. Run:

```bash
bundle exec rubocop
```

## Troubleshooting

---

- If the frontend cannot authenticate, confirm the frontend is sending the `Authorization: Bearer <token>` header returned by the sign in/up endpoints.
- If imports do not start, ensure the job worker is running and has access to the storage where files are attached.
- If ActiveStorage fails in Docker, check volume permissions and ensure the storage path exists and is writable.

## Useful endpoints

---

- POST `/api/v1/sign_up` — create an account (first user becomes admin)
- POST `/api/v1/sign_in` — sign in (returns JWT and redirect path)
- GET `/api/v1/users` — admin-only user listing
- POST `/api/v1/user_imports` — upload or provide a remote URL to create a `UserImport`
