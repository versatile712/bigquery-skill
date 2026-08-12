#!/usr/bin/env python3
"""Run a BigQuery Standard SQL query with dry-run first and a hard byte cap.

Usage:
    python scripts/run_query.py <file.sql>                  # dry-run only
    python scripts/run_query.py <file.sql> --execute        # dry-run + prompt + execute
    python scripts/run_query.py <file.sql> --execute --yes  # skip confirmation
    python scripts/run_query.py <file.sql> --execute --max-gb 500

Requires:
    pip install google-cloud-bigquery google-cloud-bigquery-storage pandas pyarrow
    gcloud auth application-default login
    gcloud config set project <billing-project>
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

try:
    from google.cloud import bigquery
except ImportError:
    sys.stderr.write(
        "google-cloud-bigquery not installed. Run:\n"
        "  pip install -r requirements.txt\n"
    )
    sys.exit(2)


PRICE_PER_TB_USD = 6.25  # BigQuery on-demand, as of 2025
DEFAULT_MAX_GB = 50.0


def load_sql(path: Path) -> str:
    if not path.exists():
        sys.stderr.write(f"SQL file not found: {path}\n")
        sys.exit(2)
    return path.read_text(encoding="utf-8")


def dry_run(client: bigquery.Client, sql: str) -> int:
    """Return total_bytes_processed."""
    job_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
    job = client.query(sql, job_config=job_config)
    return int(job.total_bytes_processed or 0)


def format_bytes(n: int) -> str:
    if n < 1024**3:
        return f"{n / 1024**2:.1f} MB"
    if n < 1024**4:
        return f"{n / 1024**3:.2f} GB"
    return f"{n / 1024**4:.3f} TB"


def estimate_cost_usd(bytes_processed: int) -> float:
    return (bytes_processed / 1024**4) * PRICE_PER_TB_USD


def execute(client: bigquery.Client, sql: str, max_bytes: int, out_csv: Path | None) -> None:
    job_config = bigquery.QueryJobConfig(
        maximum_bytes_billed=max_bytes,
        use_query_cache=True,
    )
    job = client.query(sql, job_config=job_config)
    df = job.result().to_dataframe(create_bqstorage_client=False)
    print(f"Rows returned: {len(df):,}")
    print(f"Bytes billed:  {format_bytes(job.total_bytes_billed or 0)}")
    if out_csv:
        out_csv.parent.mkdir(parents=True, exist_ok=True)
        df.to_csv(out_csv, index=False)
        print(f"Written to:    {out_csv}")
    else:
        with_head = df.head(20)
        print(with_head.to_string(index=False))


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("sql_file", type=Path, help="Path to a .sql file")
    p.add_argument("--execute", action="store_true", help="Actually run the query after dry-run")
    p.add_argument("--yes", "-y", action="store_true", help="Skip confirmation prompt")
    p.add_argument("--max-gb", type=float, default=DEFAULT_MAX_GB,
                   help=f"Hard MAXIMUM_BYTES_BILLED cap in GB (default {DEFAULT_MAX_GB})")
    p.add_argument("--project", default=os.environ.get("GOOGLE_CLOUD_PROJECT"),
                   help="Billing project (default: env GOOGLE_CLOUD_PROJECT or gcloud config)")
    p.add_argument("--out", type=Path, default=None, help="Write results to CSV")
    args = p.parse_args()

    sql = load_sql(args.sql_file)
    client = bigquery.Client(project=args.project)

    print(f"Billing project: {client.project}")
    print("Dry-running...")
    bytes_processed = dry_run(client, sql)
    cost = estimate_cost_usd(bytes_processed)
    print(f"  Estimated scan: {format_bytes(bytes_processed)}")
    print(f"  Estimated cost: ${cost:.4f}  (at ${PRICE_PER_TB_USD}/TB)")

    if not args.execute:
        print("Dry-run only. Add --execute to run for real.")
        return 0

    max_bytes = int(args.max_gb * (1024**3))
    print(f"  Guardrail cap:  {format_bytes(max_bytes)}")

    if bytes_processed > max_bytes:
        sys.stderr.write(
            f"REFUSED: estimated scan ({format_bytes(bytes_processed)}) exceeds "
            f"cap ({format_bytes(max_bytes)}). Re-run with --max-gb <higher>.\n"
        )
        return 3

    if not args.yes:
        try:
            ans = input("Proceed? (y/N) ").strip().lower()
        except EOFError:
            ans = ""
        if ans != "y":
            print("Aborted.")
            return 0

    print("Executing...")
    execute(client, sql, max_bytes, args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
