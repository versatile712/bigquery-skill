# BigQuery Standard SQL Conventions

## Non-negotiable rules

1. **Standard SQL only.** Never Legacy. Always fully qualify:
   `` `project.dataset.table` `` with backticks.
2. **No `SELECT *`** on any table with > 20 columns or > 100 MB. Enumerate
   columns explicitly.
3. **CTEs over nested subqueries** for anything past 2 joins.
4. **JOIN keys come from the dataset's `relationships.md`.** If missing, add
   it there before writing the query.
5. **Composite keys**: many bibliometric tables use `(work_id, *_seq)` — ask
   the dictionary before assuming a single-column key.

## Query template

```sql
-- dataset: openalex_2025aug (institution tables: 2024aug)
-- purpose: <one line>
-- dry-run bytes: <fill after dry-run>

WITH base AS (
  SELECT work_id, pub_year
  FROM `cwts-leiden.openalex_2025aug.work`
  WHERE pub_year BETWEEN 2018 AND 2022
),
enriched AS (
  SELECT b.work_id, b.pub_year, wa.author_seq, a.author_id, a.author
  FROM base AS b
  JOIN `cwts-leiden.openalex_2025aug.work_author` AS wa USING (work_id)
  JOIN `cwts-leiden.openalex_2025aug.author`      AS a  USING (author_id)
)
SELECT * FROM enriched
LIMIT 1000;
```

## Common traps

- **Array vs repeated field**: OpenAlex on Leiden BQ is *pre-flattened* into
  child tables (e.g. `work_author`) — don't try to `UNNEST` fields that
  aren't ARRAYs.
- **Partition pruning**: filter on `pub_year` (or the partitioning column
  listed in the dataset README) as early as possible; do it *inside* the
  CTE, not on the final SELECT.
- **Broadcast joins**: BigQuery decides join order, but if one side is
  small, filter it first inside a CTE — it becomes a hash-broadcast candidate.
- **Regexp on huge tables** = full scan. Prefill a small candidate set first.
- **String equality on IDs**: OpenAlex work IDs are strings like
  `W2741809807`. Type mismatches produce silent zero rows in some joins.
