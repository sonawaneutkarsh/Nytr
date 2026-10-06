# Public architecture decisions

- PostgreSQL is the durable system of record; user-owned tables use RLS.
- HealthKit body mass remains authoritative for factual weight.
- Goal direction and calorie/protein targets are explicit owner-approved data.
- Body profile height is explicit owner data; waist evidence is timestamped,
  owner-entered, append-only, and never a body-fat or calorie authority.
- Starting calories use the bounded deterministic policy documented in
  `docs/BODY_GOALS.md`; the result is an estimate until explicitly approved.
- Deterministic calculations own nutrition, trends, eligibility, and coaching.
- AI is optional, privacy-minimized, structured, and explanatory. The app uses
  on-device Apple Foundation Models; a server-side Gemini adapter exists but is
  disabled by default. AI cannot write facts or targets.
- Public fixtures are synthetic and no live provider scheduler is distributed.
