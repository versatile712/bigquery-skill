---
name: bigquery
description: >-
  Write, review, and execute Google BigQuery Standard SQL against registered
  public/private datasets (OpenAlex on CWTS Leiden, ORCID via Dimensions,
  and any custom datasets registered via the adapter contract). Handles
  gcloud authentication, dry-run cost estimation, and dataset-specific
  schema/relationship knowledge via a pluggable `datasets/<name>/` registry.
  Use when the user mentions BigQuery, `bq` CLI, `SELECT ... FROM
  \`project.dataset.table\``, dry-run, MAXIMUM_BYTES_BILLED, or any dataset
  listed in datasets/INDEX.md (openalex, orcid, ...).
---

# BigQuery Skill

Agent skill for Google BigQuery. Platform-agnostic: works with any agent
runtime that reads local SKILL.md files (Cursor, Claude Code, Codex CLI,
and other compatible platforms).

## Workflow

1. **Identify the dataset**
   Match the user's request against `datasets/INDEX.md`. Every entry there
   points to a `datasets/<name>/` folder that is authoritative for schema,
   version rules, and quirks.

2. **Load dataset context (progressive)**
   - Always read `datasets/<name>/README.md` first (project ID, version
     caveats, top-level structure, gotchas).
   - Read `datasets/<name>/dictionary.csv` when you need to confirm exact
     column names, types, or semantics.
   - Read `datasets/<name>/relationships.md` before writing any JOIN or
     UNNEST-heavy query.
   - Skim `datasets/<name>/examples.sql` for canonical query patterns.

3. **Draft SQL**
   Follow `reference/sql-conventions.md`. Always fully qualify
   `` `project.dataset.table` ``. Prefer CTEs. Never `SELECT *` on wide tables.

4. **Dry-run before executing**
   Every non-trivial query gets a dry-run first. Use
   `scripts/run_query.py <file.sql>` (no `--execute`) to estimate bytes
   scanned and cost. See `reference/cost-safety.md`.

5. **Execute**
   Only add `--execute` after the user acknowledges the estimated cost, or
   when the estimate is trivially small (< a few GB scanned). Auth via
   `gcloud auth application-default login` — see `reference/bq-execution.md`.

6. **Persist**
   Save reusable SQL to `queries/<dataset>_<purpose>.sql` in the user's
   project. Include a header comment with dataset version, dry-run bytes,
   and last-run timestamp.

## Dataset adapter contract

Every folder under `datasets/<name>/` must contain:

| File | Purpose |
|---|---|
| `README.md` | Human + agent brief: project ID, dataset version rules, top-level structure, known gotchas |
| `dictionary.csv` | Machine-readable field dictionary. Columns: `table,column,type,description,notes` |
| `relationships.md` | JOIN keys / UNNEST recipes, plus bridges to other datasets |
| `examples.sql` | 5–8 canonical query patterns |

Optional: `assets/` for large binaries (ER SVG, full schema JSON) that the
agent should not read wholesale.

Scaffold a new adapter:

```bash
python scripts/scaffold_dataset.py <name>
```

Then update `datasets/INDEX.md`.

## Registered datasets

See `datasets/INDEX.md` for the machine-readable registry. Currently:

- `openalex` — CWTS Leiden mirror
- `orcid` — Dimensions on BQ (`ds-open-datasets.orcid`)

## Reference

- `reference/bq-execution.md` — gcloud auth, `bq` CLI vs Python client
- `reference/sql-conventions.md` — Standard SQL rules and common traps
- `reference/cost-safety.md` — dry-run, MAXIMUM_BYTES_BILLED, partition pruning

## Anti-patterns

- Writing SQL without reading `datasets/<name>/relationships.md` first
- Executing without a dry-run when scanning > 1 GB
- `SELECT *` on any wide table (OpenAlex `work`, ORCID `summaries_YYYY`)
- Hardcoding dataset versions when the adapter's `README.md` specifies
  per-table rules (e.g. OpenAlex `institution_type` → 2024aug)
