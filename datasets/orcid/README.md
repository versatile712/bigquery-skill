# ORCID Public Data (via Dimensions on BigQuery)

Verified against live BigQuery on 2026-08-12 by `nsfcopenalex` billing
project. Default table switched to `summaries_2025` after confirming
schema parity with `summaries_2024`.

## Source

Dimensions publishes ORCID Public Data File as a **single wide table with
deeply nested STRUCT / REPEATED fields** — one row per ORCID iD, everything
else nested inside. This means:

- **No traditional JOINs** — you `UNNEST` REPEATED arrays instead
- **All data in one table** — but that table is 100+ GB, so filter early
- **Free tier**: 1 TB scan/month per Google account (Dimensions open dataset policy)

Source ref: <https://docs.dimensions.ai/bigquery/open-datasets.html#orcid-dataset>
Sample queries: <https://bigquery-lab.dimensions.ai/tutorials/09-orcid/>

## Tables

| Table | Type | Size | Rows | Notes |
|---|---|---|---|---|
| `ds-open-datasets.orcid.summaries_2025` | CLONE | 122 GB | 25,048,058 | **Default** — latest snapshot |
| `ds-open-datasets.orcid.summaries_2024` | BASE TABLE | 103 GB | 21,071,103 | Feb 2025 release (Dimensions docs still cite this as the "official" open dataset) |
| `ds-open-datasets.orcid.summaries_2023` | CLONE | 84 GB | 17,731,671 | Historical |

Schema of `summaries_2025` is **identical to `summaries_2024`** (verified
2026-08-12: 868 field paths, zero adds/removes). Pick 2024 only if you
need reproducibility against the officially documented release; otherwise
prefer 2025 for coverage.

License: **CC0** (ORCID Public Data File). Update cadence: yearly.

## Top-level structure

```
orcid_identifier          # primary key — .path is the 16-char ORCID iD
preferences               # locale
history                   # created / modified / deactivated dates, verified email
person                    # name, other_names, biography, urls, emails, addresses, keywords, external_identifiers
activities                # educations, employments, fundings, peer_reviews, works,
                          # invited_positions, memberships, qualifications, services, research_resources
```

## The universal UNNEST pattern

Almost every "activity" list follows this shape:

```sql
FROM `ds-open-datasets.orcid.summaries_2025`,
     UNNEST(activities.<KIND>.groups) AS grp,
     UNNEST(grp.records)              AS record
```

Where `<KIND>` is one of `educations | employments | fundings | works | memberships |
qualifications | services | research_resources`.

**Two exceptions** (schema inconsistency in upstream ORCID XML):

- `activities.peer_reviews.groups.groups.records` — one extra `.groups` level
- `activities.invited_positions.records.records` — uses `records.records`, not `groups.records`

## Field dictionary

See `dictionary.csv` (top ~80 useful paths — the full 892-path schema is in `assets/schema.json`).

## Relationships

See `relationships.md`.

## Canonical examples

See `examples.sql`.

## Gotchas (verified against real data)

1. **Dates are STRING**, not INT or DATE.
   Cast with `SAFE_CAST(record.start_date.year AS INT64)`.
2. **`orcid_identifier.path`** is the 16-char iD (e.g. `0000-0002-1825-0097`) — not the URL.
   OpenAlex's `author.orcid` may store the full URL `https://orcid.org/...`; when bridging, strip prefix or use `ENDS_WITH`.
3. **Organization disambiguation `source` values**: `ROR`, `RINGGOLD`, `FUNDREF`, `GRID`, or NULL.
   For 2024 employments: ROR covers ~228k, RINGGOLD ~3k, FUNDREF ~2k, GRID ~0.6k, NULL ~30k.
4. **`SELECT *` on any `summaries_YYYY` table** ≈ **$0.75+ per query** (2025 is 122 GB). Never do it.
5. **Empty vs null**: `activities.employments.groups` can be empty array `[]` for accounts with no employments — `UNNEST` yields zero rows, so use `LEFT JOIN UNNEST(...)` if you need to keep the ORCID row.

## Cost calibration (dry-run measurements)

| Query pattern | Bytes scanned |
|---|---|
| `SELECT COUNT(*) WHERE history.deactivation_date IS NULL` | ~0 GB (metadata only) |
| Full UNNEST of `activities.employments` for all ORCIDs | ~40–60 GB |
| Filtered to a single ORCID iD | < 100 MB after clustering hits |

Numbers > 5 GB should trigger user confirmation (see `../../reference/cost-safety.md`).
