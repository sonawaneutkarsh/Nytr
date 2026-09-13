# Dining integration boundary

Nytr was originally built around one real dining environment: **Penn State
Harrisburg — Stacks Market**. That is the use case the planner, evidence model,
and freshness rules were designed against.

Nytr is an independent student project and is not affiliated with or endorsed by
The Pennsylvania State University.

## What is and is not in this repository

The adapter is provider-neutral at its core, and this public mirror includes **no**
institutional dining HTML, menus, images, item identifiers, or scraped page dumps.
Parser tests run against fabricated HTML in `tests/fixtures/stacks/`; see that
directory's manifest. Ingestion is disabled by default
(`STACKS_INGESTION_MODE=blocked`).

So the documentation describes the real environment while every fixture and test
value in the repository is synthetic.

## Integration rules

An institutional provider may be integrated only after its terms, access method,
rate limits, retention expectations, and attribution requirements are reviewed.
Beyond that:

- Provider availability is evidence that an item was *offered*, never proof that
  it was eaten.
- Published nutrition and estimated nutrition are tracked as distinct states;
  estimates never silently become authoritative values.
- Every menu observation carries its snapshot identity, fetch time, and parser
  version, so a recommendation can always be traced to the evidence behind it.
- Stale or unparseable pages fail closed rather than degrading into partial
  guesses.

## Generalizing beyond one location

Support for additional Penn State dining locations is the priority direction for
the project. The intended shape is to carry location and provider identity
through the ingestion, normalization, and planning layers so further locations
reuse the same evidence rules, provenance model, and planner rather than being
special-cased. Determinism and fail-closed behaviour have to survive the fact
that menu shapes and publishing habits differ between locations.
