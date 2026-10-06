# Project notes

These notes cover scope, demo use, deployment, and workflow for the public
repository. The root [README](../README.md) is the main overview.

## Scope of this repository

This repository is a sanitized copy of the Nytr codebase. It contains:

- the backend, the iOS client, the SQL migrations, and the test suites;
- synthetic fixtures only (see `tests/fixtures/stacks/FIXTURES_MANIFEST.md`).

It does not contain owner health records, credentials, deployment identifiers,
institutional dining pages, or a scheduled live-ingestion workflow.

## Product requirements

- Published menu and nutrition values keep their provenance. Nytr never guesses them.
- Deterministic Python code owns arithmetic, targets, feasibility, trends, and coaching.
- A plan is a recommendation. Only an explicit owner action creates a consumption record.
- HealthKit owns body mass and high-level workout observations on iOS.
- Hevy, when connected, adds exercise and set detail. It cannot change HealthKit facts.
- Optional AI explains a minimized deterministic snapshot. It is never authoritative.
- User-owned records require authenticated access and row-level security.
- Incomplete, stale, or unsupported evidence fails closed.

Out of scope: autonomous goal changes, clinical claims, multi-campus operation,
background training classification, and a general agent or microservice framework.

Starting calories use the bounded deterministic policy in
[BODY_GOALS.md](BODY_GOALS.md). The result is an estimate until the owner
approves it.

## Dining integration boundary

The adapter in `backend/src/nutrition_agent/infrastructure/stacks_source/` accepts
a provider's menu and nutrition responses, validates selection echoes and
provenance, and quarantines malformed or incomplete data. Ingestion is disabled by
default (`STACKS_INGESTION_MODE=blocked`). Any live ingestion must be an explicit,
authorized, bounded operation against a provider whose terms permit it. See
[STACKS_DISCOVERY.md](STACKS_DISCOVERY.md).

## Synthetic demo

1. Install the backend and run the tests (see the README "Local setup").
2. Run the Swift typecheck harness: `ios/Harness/run_harness.sh` (macOS only).
3. Use the synthetic dining fixtures to show parsing, provenance, uncertainty,
   and fail-closed behavior.

## Deployment

This repository is not a production deployment. It contains variable names and
safe defaults only (`.env.example`). A real deployment must apply the migrations
in order, enable RLS, pass the backend health check (`GET /healthz`), and pass an
authenticated smoke test before an iOS build ships. Keep secrets in the
platform's secret store.

## Development workflow

1. Read the relevant design and safety notes.
2. Inspect the existing domain and adapter boundaries.
3. Implement only the requested scope with typed, deterministic code.
4. Add regression tests for non-trivial behavior.
5. Run the gates that CI runs: `ruff check`, `ruff format --check`, `mypy`, `pytest`.
6. Review the complete diff.

CI (`.github/workflows/ci.yml`) runs those gates on every push to `main` and on
every pull request, with a Postgres service for the integration tests.
