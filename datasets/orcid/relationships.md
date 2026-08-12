# ORCID — Table Relationships (proposed)

Fill in once data is loaded and columns are verified.

| from | column(s) | to | to column | notes |
|---|---|---|---|---|
| employment | orcid | person | orcid | m:1 |
| education  | orcid | person | orcid | m:1 |
| employment | ror_id | (external) ROR | id | prefer over `grid_id` |

## Bridge to OpenAlex

```sql
-- placeholder pattern; adjust project names once ORCID is loaded
SELECT a.author_id, a.author, p.given_names, p.family_name
FROM `cwts-leiden.openalex_2025aug.author` AS a
JOIN `<your-project>.orcid_<yyyymm>.person` AS p
  ON a.orcid = p.orcid;
```
