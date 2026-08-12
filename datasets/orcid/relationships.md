# ORCID (Dimensions BQ) — Relationships & UNNEST Cheat Sheet

There is only **one physical table per snapshot** (default: `summaries_2025`), so "relationships"
here means: (a) how to UNNEST the nested arrays, and (b) how to bridge to
other datasets (OpenAlex, Crossref, ROR).

## UNNEST recipe (memorize)

```sql
FROM `ds-open-datasets.orcid.summaries_2025`,
     UNNEST(activities.<KIND>.groups) AS grp,
     UNNEST(grp.records)              AS r
```

`<KIND>` ∈ `educations | employments | fundings | works | memberships | qualifications | services | research_resources`

**Two exceptions** (schema quirks upstream):

| kind | UNNEST path |
|---|---|
| `peer_reviews` | `UNNEST(activities.peer_reviews.groups) g, UNNEST(g.groups) gg, UNNEST(gg.records) r` |
| `invited_positions` | `UNNEST(activities.invited_positions.records) r0, UNNEST(r0.records) r` |

**Person-level arrays**:

```sql
UNNEST(person.emails.emails)         AS email
UNNEST(person.addresses.addresses)   AS address
UNNEST(person.keywords.keywords)     AS kw
UNNEST(person.researcher_urls.urls)  AS url
UNNEST(person.external_identifiers.identifiers) AS id
```

## Organization disambiguation

Every `.organization.disambiguated_organization` has:

- `.identifier` — the id value in its native registry
- `.source` — one of `ROR | RINGGOLD | FUNDREF | GRID | NULL`

**Coverage** (verified for employments recorded on ORCID, calibrated on 2024):
`ROR ~228,862 · NULL ~30,104 · RINGGOLD ~2,865 · FUNDREF ~1,904 · GRID ~576`
(2025 snapshot shows the same distribution shape at higher volume; not re-tallied.)

**Preference rule**: use ROR when available; fall back to RINGGOLD (Web of
Science ecosystem) or GRID (mostly deprecated) with a note.

## Bridge to OpenAlex

`ds-open-datasets.orcid.summaries_2025.orcid_identifier.path`   ↔   `cwts-leiden.openalex_2025aug.author.orcid`

**Format caveat**: ORCID stores the 16-char path (`0000-0002-1825-0097`).
OpenAlex may store either the path or the full URL
(`https://orcid.org/0000-0002-1825-0097`). Normalize before joining.

```sql
-- Normalize both sides to bare 16-char path before joining
WITH orcid_flat AS (
  SELECT
    orcid_identifier.path AS orcid_path,
    r.role_title,
    r.organization.name AS org_name,
    r.organization.disambiguated_organization.identifier AS ror_id,
    SAFE_CAST(r.start_date.year AS INT64) AS start_year,
    SAFE_CAST(r.end_date.year AS INT64)   AS end_year
  FROM `ds-open-datasets.orcid.summaries_2025`,
       UNNEST(activities.employments.groups) AS g,
       UNNEST(g.records) AS r
),
oa_authors AS (
  SELECT
    author_id,
    author,
    REGEXP_EXTRACT(orcid, r'([\dX]{4}-[\dX]{4}-[\dX]{4}-[\dX]{4})') AS orcid_path
  FROM `cwts-leiden.openalex_2025aug.author`
  WHERE orcid IS NOT NULL
)
SELECT oa.author_id, oa.author, of.role_title, of.org_name, of.ror_id, of.start_year, of.end_year
FROM oa_authors AS oa
JOIN orcid_flat AS of USING (orcid_path)
LIMIT 100;
```

## Bridge to Crossref / OpenAlex works

`activities.works.groups.external_ids.identifiers` carries DOIs, PMIDs,
EIDs (Scopus), WoS IDs, arXiv IDs, PMCIDs, ISBNs, handles.

For DOIs:

```sql
UNNEST(activities.works.groups) AS wg,
UNNEST(wg.external_ids.identifiers) AS id
WHERE id.type = 'doi'
```

Cardinality on ORCID 2024 (illustrative; 2025 higher): DOI 77.8 M · EID
40.1 M · WoS UID 13.1 M · PMID 8.3 M · arXiv 2.1 M · PMC 2.5 M · handle
1.5 M · ISBN 1.05 M.
