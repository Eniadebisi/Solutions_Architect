# world-cup — Project Brief (App Repo)

> Pass this to Claude Code to scaffold `world-cup-app` from scratch.

---

## 1. Overview

world-cup is a containerized Python API that fetches football World Cup scores and upcoming fixtures on demand. The app is stateless — it reads env vars for all configuration, connects to a PostgreSQL RDS instance over a private VPC, and exposes a minimal REST API consumed by a single-page HTML frontend.

**Two repos, separate concerns:**
- `world-cup-app` — application code only (this brief)
- `world-cup-infra` — all IaC (Terraform, CDK, Helm, ArgoCD manifests)

The app has zero AWS imports. Where env vars come from (`.env` locally, K8s Secret in prod via External Secrets Operator) is the infra layer's concern.

---

## 2. Repo Structure

```
world-cup-app/
├── src/
│   ├── api/
│   │   ├── main.py
│   │   ├── routes/
│   │   │   ├── scores.py
│   │   │   └── fixtures.py
│   │   └── deps.py
│   ├── fetcher/
│   │   ├── client.py
│   │   └── models.py
│   ├── db/
│   │   ├── session.py
│   │   ├── models.py
│   │   └── crud.py
│   └── config.py
├── static/
│   └── index.html
├── tests/
│   ├── test_routes.py
│   └── test_fetcher.py
├── Dockerfile
├── pyproject.toml
├── .env.example
└── .gitlab-ci.yml
```

---

## 3. Technology Stack

| Layer | Choice |
|---|---|
| Language | Python 3.12 |
| Web framework | FastAPI |
| ORM | SQLAlchemy 2 (async) |
| DB driver | asyncpg |
| HTTP client | httpx (async) |
| Validation | Pydantic v2 |
| Config | pydantic-settings (BaseSettings) |
| Logging | structlog (JSON output) |
| Test runner | pytest + pytest-asyncio |
| Container | Docker (`python:3.12-slim`) |

---

## 4. Configuration (`config.py`)

All settings via pydantic-settings `BaseSettings`. No hardcoded values anywhere.

**Required env vars:**

| Var | Description |
|---|---|
| `DB_HOST` | RDS hostname |
| `DB_PORT` | Default `5432` |
| `DB_NAME` | Database name |
| `DB_USER` | Database username |
| `DB_PASSWORD` | Database password |
| `FOOTBALL_API_KEY` | External football API key |
| `FOOTBALL_API_URL` | External football API base URL |
| `LOG_LEVEL` | Default `info` |

Provide `.env.example` with all keys listed, no real values. pydantic-settings loads `.env` automatically in local dev.

---

## 5. API Endpoints

| Endpoint | Behaviour |
|---|---|
| `GET /health` | Liveness probe. Returns `{"status": "ok"}` |
| `GET /scores/latest` | Returns most recent scores from DB. No external call. |
| `GET /scores/fetch` | Live pull from football API → upsert to DB → return results |
| `GET /fixtures/next` | Returns next upcoming match from DB |
| `GET /` | Serves `static/index.html` |

`/scores/fetch` is what the frontend button calls. The infra-side CronJob will also call this endpoint on its schedule — same code path.

---

## 6. Database Models

### `scores` table
- `id` — UUID primary key
- `home_team` — string
- `away_team` — string
- `home_score` — integer
- `away_score` — integer
- `match_date` — datetime
- `competition` — string
- `fetched_at` — datetime (set server-side on upsert)

### `fixtures` table
- `id` — UUID primary key
- `home_team` — string
- `away_team` — string
- `kickoff_time` — datetime
- `venue` — string
- `competition` — string
- `fetched_at` — datetime

Use Alembic for migrations. Initial migration auto-generated from ORM models.

---

## 7. Fetcher (`fetcher/client.py`)

Standalone async module — no FastAPI imports. Takes config as arguments so it can be called from routes or a standalone script.

Must:
- Call the football API using `httpx.AsyncClient`
- Parse response into Pydantic models defined in `fetcher/models.py`
- Return typed Python objects — no raw dicts passed around
- Raise a descriptive exception on API errors (non-2xx, timeout, parse failure)

Suggested free API: [api-football.com](https://www.api-football.com/) (free tier, 100 req/day). API key injected via config.

---

## 8. Frontend (`static/index.html`)

Single HTML file. No framework, no build step, no npm. Served by FastAPI via `StaticFiles`.

Must include:
- A button labeled **Fetch Latest Scores**
- A section that displays returned scores after fetch
- A section showing the next upcoming fixture
- Loading and error states (spinner or text while waiting, error message on failure)
- Plain CSS only — no frameworks

On button click: call `GET /scores/fetch`. On success, also call `GET /fixtures/next` to refresh that section.

---

## 9. Dockerfile

Base image: `python:3.12-slim`. Multi-stage not required yet.

Requirements:
- Create a non-root user and run the app as that user
- Copy only what is needed — no test files, no `.env`
- Entrypoint: `uvicorn`
- Expose port `8000`
- Pin the base image to a specific digest or tag

No embedded secrets. Image must start cleanly with only env vars set.

---

## 10. `pyproject.toml`

Use `pyproject.toml` for all dependency management. No `requirements.txt`.

**Runtime dependencies:**
- `fastapi`
- `uvicorn[standard]`
- `sqlalchemy[asyncio]`
- `asyncpg`
- `httpx`
- `pydantic-settings`
- `structlog`
- `alembic`

**Dev/test dependencies:**
- `pytest`
- `pytest-asyncio`
- `httpx` (also used as async test client for FastAPI)

---

## 11. Logging

Use `structlog` configured for JSON output. Every log entry must include:
- `timestamp`
- `level`
- `event` (human-readable message)
- `service` — hardcoded to `world-cup-api`

Log at `INFO` on every fetch (scores returned, duration). Log at `ERROR` on any external API failure with status code and message. Never log DB passwords or API keys.

---

## 12. Tests

### `tests/test_routes.py`
- `GET /health` returns 200
- `GET /scores/latest` returns 200 and expected shape (mock the DB call)
- `GET /scores/fetch` calls fetcher and upserts (mock httpx and DB)

### `tests/test_fetcher.py`
- Fetcher parses a valid API response into the correct Pydantic models
- Fetcher raises on a non-2xx response

Use pytest fixtures for the FastAPI test client. Use `httpx.AsyncClient` for async route tests.

---

## 13. GitLab CI (`.gitlab-ci.yml`)

Scaffold only — pipeline does not need to be fully functional yet.

**Stages and job stubs:**

| Stage | Job |
|---|---|
| `lint` | Run `ruff` |
| `test` | Run `pytest` with a Postgres service container |
| `sast` | Placeholder (Snyk + SonarQube wired in later) |
| `build` | `docker build` tagged with `$CI_COMMIT_SHORT_SHA` |
| `scan` | Placeholder (Snyk container scan wired in later) |
| `push` | `docker push` stub — no real registry yet |

The `test` job must define a `services:` block with `postgres:15` and pass `DB_*` env vars matching the app config.

---

## 14. Constraints

Do **not**:
- Add any AWS SDK imports (`boto3`, `botocore`) to app code
- Hardcode any credentials, URLs, or API keys
- Add a frontend framework or build toolchain
- Create `docker-compose.yml` — local dev uses `.env` and a separately run Postgres container
- Add Kubernetes manifests — those live in `world-cup-infra`
- Add any file not listed in the repo structure above

The app must work locally with only: a running Postgres instance, a valid `.env` file, and `uvicorn`. No other dependencies.

---

## 15. Local Dev Setup (for reference)

```bash
# Start a local Postgres
docker run -d \
  --name world-cup-pg \
  -e POSTGRES_DB=world-cup \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgres:15

# Copy and fill env
cp .env.example .env

# Install and run
pip install -e ".[dev]"
uvicorn src.api.main:app --reload
```

---

## 16. Kickoff Prompt for Claude Code

Paste this to start:

```
Scaffold world-cup-app exactly as described in this brief. Start with the repo
structure, pyproject.toml, and config.py. Do not build anything not listed. Ask
me before adding any dependency not in section 10. Work through sections in order:
structure → config → DB models → fetcher → routes → frontend → Dockerfile → CI
stub → tests. Confirm the shape of each layer before moving to the next.
```
