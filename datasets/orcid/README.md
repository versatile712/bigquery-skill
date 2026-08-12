# ORCID (scaffold — not yet in BigQuery)

Status: **scaffold**. ORCID Public Data File is not on BigQuery by default;
current workflow parses the annual dump locally to Parquet, then optionally
loads to BigQuery under the user's own project.

## Source

- ORCID Public Data File (annual): https://orcid.figshare.com/
- Format: multi-part `tar.gz`, one XML per record, ORCID schema 3.0
- Sharded by iD suffix (last 3 chars → directory)
- Contains **public** records only

## Target BigQuery layout (proposed)

Once loaded, use `<your-project>.orcid_<yyyymm>.*`.

| table | rows (order of) | primary key |
|---|---|---|
| person | 20M | `orcid` |
| employment | 40M | `(orcid, put_code)` |
| education  | 30M | `(orcid, put_code)` |
| external_identifier | 30M | `(orcid, put_code)` |

## Bridging to OpenAlex

`openalex.author.orcid` → `orcid.person.orcid`. Cardinality: an OpenAlex
`author_id` can be split across multiple ORCID iDs (disambiguation errors);
one ORCID iD is normally a single person but self-registration mistakes
happen. Handle m:n, not 1:1.

## TODO (fill when data is loaded)

- [ ] Freeze release version (e.g. `orcid_2025_summary`)
- [ ] Load parquet → BigQuery via `bq load` or Storage Write API
- [ ] Populate `dictionary.csv` with real column types
- [ ] Populate `relationships.md` with ROR org identifiers on employment
- [ ] Add 3–5 canonical examples in `examples.sql`
