# BigQuery Execution Cheat Sheet

## Authentication (one-time per machine)

```bash
gcloud auth application-default login
gcloud config set project <your-billing-project>
```

Confirm:

```bash
gcloud auth application-default print-access-token > $null  # should succeed silently
bq ls -p  # list projects you have access to
```

Note: the *billing project* (where the query is billed) is not the same as
the *data project* (e.g. `cwts-leiden`). You query someone else's public
dataset but pay from your own project.

## Two execution paths

### A. `scripts/run_query.py` (recommended, this skill's default)

- Wraps the Python client with dry-run first, cost printout, then optional execute
- Always sets `MAXIMUM_BYTES_BILLED` guardrail
- Prints results as CSV or Arrow-backed DataFrame

```bash
python scripts/run_query.py queries/example.sql               # dry-run only
python scripts/run_query.py queries/example.sql --execute     # after ack
python scripts/run_query.py queries/example.sql --execute --max-gb 50
```

### B. `bq` CLI (ad-hoc, one-liners)

```bash
bq query --use_legacy_sql=false --dry_run "SELECT ... FROM \`cwts-leiden.openalex_2025aug.work\` LIMIT 10"
bq query --use_legacy_sql=false --maximum_bytes_billed=53687091200 "SELECT ..."   # 50 GB cap
```

## Common failure modes

| Symptom | Cause | Fix |
|---|---|---|
| `403 Access Denied: BigQuery BigQuery: Permission denied` on dry-run | Billing project not set or lacks `bigquery.jobs.create` | `gcloud config set project <p>`; ensure user has `roles/bigquery.jobUser` |
| `Dataset not found` | Wrong dataset version (e.g. `institution_type` queried on 2025aug when the adapter pins 2024aug) | Check the dataset's `README.md` version rule |
| `Query exceeded limit for bytes billed` | Guardrail triggered | Raise `--max-gb` after understanding cost, or narrow the query |
