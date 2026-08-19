# OpenAlex on CWTS Leiden BigQuery

## Project & datasets

| BQ project | Dataset | Use for |
|---|---|---|
| `cwts-leiden` | `openalex_2025aug` | **Default** — all tables except `institution_type` |
| `cwts-leiden` | `openalex_2024aug` | **`institution_type` only** |

**Version rule** (memorize): *"only `institution_type` → 2024aug; everything else → 2025aug."*
`institution`, `work_affiliation_institution`, `author_institution`, `author_last_known_institution`, `country`, and `city` all live in `openalex_2025aug` and should be queried there.

## Primary entities

- `work` — publications; partitioned/clustered by `pub_year`
- `author` — disambiguated authors
- `institution` — ROR-aligned organizations
- `concept` — OpenAlex concept hierarchy (deprecated upstream in favor of Topics, but still available on Leiden)
- `citation` — citing → cited pairs

## Link tables (pre-flattened, no UNNEST needed)

- `work_author (work_id, author_seq, author_id, author_position_id)`
- `work_affiliation (work_id, affiliation_seq, ...)`
- `work_affiliation_institution (work_id, affiliation_seq, institution_id)`
- `work_concept (work_id, concept_seq, concept_id, score)`
- `author_institution (author_id, institution_seq, institution_id)`
- `author_last_known_institution (author_id, last_known_institution_id)`

## Field dictionary

See `dictionary.csv` (columns: `table,column,type,description,notes`).

## Relationships

See `relationships.md`.

## Canonical examples

See `examples.sql`.

## Gotchas

- **Mixed-dataset JOINs are rare.** Only needed when attaching `institution_type`
  (2024aug) to an institution row from 2025aug. A "publications by institution"
  query can stay entirely on `openalex_2025aug`.
- **`work.pub_year`** is the partition-pruning column. Always filter on it
  first when possible.
- **`concept`** is deprecated upstream but Leiden has not removed it. New
  work should prefer whatever Topic replacement Leiden ships next; check
  the CSV dictionary for a `topic` table before assuming its absence.
- **Author disambiguation is imperfect.** Do not trust a single `author_id`
  as a person — use ORCID via `author.orcid` when available.
