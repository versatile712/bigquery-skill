# OpenAlex on CWTS Leiden BigQuery

## Project & datasets

| BQ project | Dataset | Use for |
|---|---|---|
| `cwts-leiden` | `openalex_2025aug` | **Default** — all tables *except* those below |
| `cwts-leiden` | `openalex_2024aug` | **Any table whose name contains `institution`** (i.e. `institution`, `work_affiliation_institution`, `author_institution`, `author_last_known_institution`, `institution_type`, plus lookup tables `country`, `city` when joined via institution) |

**Version rule** (memorize): *"institution → 2024aug, everything else → 2025aug."*
This is because CWTS did not re-publish the institution family in the 2025aug refresh.

## Primary entities

- `work` — publications; partitioned/clustered by `pub_year`
- `author` — disambiguated authors
- `institution` — ROR-aligned organizations (**2024aug only**)
- `concept` — OpenAlex concept hierarchy (deprecated upstream in favor of Topics, but still available on Leiden)
- `citation` — citing → cited pairs

## Link tables (pre-flattened, no UNNEST needed)

- `work_author (work_id, author_seq, author_id, author_position_id)`
- `work_affiliation (work_id, affiliation_seq, ...)`
- `work_affiliation_institution (work_id, affiliation_seq, institution_id)` **[2024aug]**
- `work_concept (work_id, concept_seq, concept_id, score)`
- `author_institution (author_id, institution_seq, institution_id)` **[2024aug]**
- `author_last_known_institution (author_id, last_known_institution_id)` **[2024aug]**

## Field dictionary

See `dictionary.csv` (columns: `table,column,type,description,notes`).

## Relationships

See `relationships.md`.

## Canonical examples

See `examples.sql`.

## Gotchas

- **Mixed-dataset JOINs are the norm.** A "publications by institution" query
  will hit both `openalex_2025aug.work` and `openalex_2024aug.work_affiliation_institution`.
- **`work.pub_year`** is the partition-pruning column. Always filter on it
  first when possible.
- **`concept`** is deprecated upstream but Leiden has not removed it. New
  work should prefer whatever Topic replacement Leiden ships next; check
  the CSV dictionary for a `topic` table before assuming its absence.
- **Author disambiguation is imperfect.** Do not trust a single `author_id`
  as a person — use ORCID via `author.orcid` when available.
