---
name: bigquery
description: >-
  Write, review, and execute Google BigQuery Standard SQL against registered
  public/private datasets (e.g. OpenAlex on CWTS Leiden, ORCID). Handles
  authentication via gcloud, dry-run cost estimation, safe execution, and
  dataset-specific field/relationship knowledge via a pluggable adapter
  registry. Use when the user mentions BigQuery, bq CLI, `SELECT ... FROM
  \`project.dataset.table\``, dry-run, MAXIMUM_BYTES_BILLED, or any dataset
  listed in datasets/INDEX.md (OpenAlex, ORCID, etc.).
---

# BigQuery Skill

A generic BigQuery execution + review assistant with a pluggable dataset
adapter system. Add new datasets by dropping a folder under `datasets/`.

## Workflow

1. **Identify the dataset**
   Match the user's request against `datasets/INDEX.md`. If a dataset entry
   exists, treat its folder as the source of truth for schema, versions, and
   quirks.

2. **Load dataset context (progressive)**
   - Always read `datasets/<name>/README.md` first (project ID, version
     caveats, primary entities).
   - Read `datasets/<name>/dictionary.csv` when you need to confirm exact
     column names, types, or semantics.
   - Read `datasets/<name>/relationships.md` before writing any JOIN.
   - Skim `datasets/<name>/examples.sql` for canonical query patterns.

3. **Draft SQL**
   Follow `reference/sql-conventions.md`. Always fully qualify
   `project.dataset.table`. Prefer CTEs. Never `SELECT *` on wide tables.

4. **Dry-run before executing**
   Every non-trivial query gets a dry-run first. Use
   `scripts/run_query.py <file.sql>` (no `--execute`) to estimate bytes
   scanned and cost. See `reference/cost-safety.md` for thresholds and
   `MAXIMUM_BYTES_BILLED` usage.

5. **Execute**
   Only add `--execute` after the user acknowledges the estimated cost, or
   when the estimate is trivially small (< a few GB scanned). Authentication
   uses `gcloud auth application-default login` — see
   `reference/bq-execution.md`.

6. **Persist**
   Save reusable SQL to `queries/<dataset>_<purpose>.sql` in the user's
   project. Include a header comment with dataset version, dry-run bytes,
   and last-run timestamp.

## Dataset adapter contract

Every folder under `datasets/<name>/` must contain:

| File | Purpose |
|---|---|
| `README.md` | Human + agent brief: project ID, dataset version rules, primary entities, known gotchas |
| `dictionary.csv` | Machine-readable field dictionary. Columns: `table,column,type,description,notes` |
| `relationships.md` | JOIN keys and ER hints, prioritized for SQL generation |
| `examples.sql` | 3–8 canonical query patterns |

Optional: `assets/` for large binaries (ER SVG, docs) that the agent should
not read wholesale.

To scaffold a new dataset:

```bash
python scripts/scaffold_dataset.py <name>
```

Then update `datasets/INDEX.md`.

## Registered datasets

See `datasets/INDEX.md` for the current registry.

## Reference

- `reference/bq-execution.md` — gcloud auth, `bq` CLI vs Python client
- `reference/sql-conventions.md` — Standard SQL rules and common traps
- `reference/cost-safety.md` — dry-run, MAXIMUM_BYTES_BILLED, partition pruning

## Anti-patterns

- Writing SQL without reading `datasets/<name>/relationships.md` first
- Executing without a dry-run when scanning > 1 GB
- Hardcoding `project.dataset` values that vary by dataset version — always
  cite the version rule from the dataset's `README.md`
