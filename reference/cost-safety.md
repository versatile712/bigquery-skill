# Cost Safety

BigQuery on-demand pricing: **$6.25 per TB scanned** (as of 2025). One
careless query on OpenAlex `work` can scan hundreds of GB.

## Mandatory checks

1. **Dry-run every non-trivial query.**
   `scripts/run_query.py <file>` does this by default.

2. **Set a hard cap** via `MAXIMUM_BYTES_BILLED`. The runner defaults to
   **50 GB** (~$0.31). Raise explicitly with `--max-gb`:

   ```bash
   python scripts/run_query.py queries/big.sql --execute --max-gb 500
   ```

3. **Confirm with the user** before executing anything estimated to scan
   more than a few GB. Print:

   ```
   Estimated: 87.3 GB scanned  ≈ $0.55  (at $6.25/TB)
   Guardrail: 100 GB
   Proceed? (y/N)
   ```

## Reduction techniques (in order of impact)

| Technique | Typical savings |
|---|---|
| Select only needed columns (BQ is columnar) | 5×–50× |
| Filter on partitioning/clustering column *early* | 10×–100× |
| Materialize an intermediate table for repeated queries | ∞ after first run |
| `LIMIT` does *not* reduce scanned bytes — filter instead | — |

## Dry-run in Python

```python
from google.cloud import bigquery

client = bigquery.Client()
job = client.query(sql, job_config=bigquery.QueryJobConfig(dry_run=True, use_query_cache=False))
print(f"{job.total_bytes_processed / 1e9:.2f} GB will be scanned")
```
