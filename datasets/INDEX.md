# Registered Datasets

Agents: read this table first to route a query to the right adapter folder.
Users: add a row when contributing a new dataset adapter.

| name | folder | bq_project.dataset (default) | version notes | primary entities | status |
|---|---|---|---|---|---|
| openalex | `datasets/openalex/` | `cwts-leiden.openalex_2025aug` | Tables whose name contains `institution` MUST use `cwts-leiden.openalex_2024aug` | work, author, institution, concept, citation | ready |
| orcid    | `datasets/orcid/`    | *(TBD — not yet in BigQuery; local parquet for now)* | ORCID Public Data File dump; schema 3.0 | person, employment, education | scaffold |

## Adding a new dataset

1. `python scripts/scaffold_dataset.py <name>`
2. Fill in `datasets/<name>/README.md`, `dictionary.csv`, `relationships.md`, `examples.sql`
3. Append a row above
4. Bump the top-level README's "Supported datasets" section
