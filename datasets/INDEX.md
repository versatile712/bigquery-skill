# Registered Datasets

Agents: read this table first to route a query to the right adapter folder.
Users: add a row when contributing a new dataset adapter.

| name | folder | bq_project.dataset (default) | version notes | primary entities | status |
|---|---|---|---|---|---|
| openalex | `datasets/openalex/` | `cwts-leiden.openalex_2025aug` | Tables whose name contains `institution` MUST use `cwts-leiden.openalex_2024aug` | work, author, institution, concept, citation | ready |
| orcid    | `datasets/orcid/`    | `ds-open-datasets.orcid.summaries_2025` | Default is the latest snapshot. Also available: `summaries_2024` (Dimensions-documented release, 103 GB), `summaries_2023` (84 GB). Schema identical across all three. Single wide table, nested STRUCT/REPEATED; UNNEST-heavy | orcid_identifier, history, person, activities (employments, educations, works, ...) | ready |

## Adding a new dataset

1. `python scripts/scaffold_dataset.py <name>`
2. Fill in `datasets/<name>/README.md`, `dictionary.csv`, `relationships.md`, `examples.sql`
3. Append a row above
4. Bump the top-level README's "Supported datasets" section

## Verifying a dataset adapter

Before marking a dataset `ready`, confirm the schema against the live table:

```python
from google.cloud import bigquery
c = bigquery.Client(project="<your-billing-project>")
t = c.get_table("<project>.<dataset>.<table>")
for f in t.schema:
    print(f.name, f.field_type, f.mode)
```

Verified adapters were probed on:

- `openalex` — trusted from CWTS Leiden documentation (not re-probed each release)
- `orcid` — probed 2026-08-12 via `ds-open-datasets.orcid.INFORMATION_SCHEMA` and `Table.schema`
