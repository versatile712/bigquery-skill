# cursor-skill-bigquery

A **Cursor Agent Skill** for writing, reviewing, and executing Google BigQuery
Standard SQL, with a pluggable **dataset adapter** system so you can add
support for new datasets (OpenAlex, ORCID, Crossref, custom project datasets, …)
without touching the core skill.

Private repository — internal use by the author and collaborators.

## Supported datasets

| name | status | notes |
|---|---|---|
| `openalex` | ready | CWTS Leiden mirror (`cwts-leiden.openalex_2025aug`, institution tables on `openalex_2024aug`) |
| `orcid`    | scaffold | ORCID Public Data File; planned load path from parquet → BQ |

See `datasets/INDEX.md` for the machine-readable registry.

## Install (for a Cursor user)

### Option A — personal skill (available in every project)

Windows PowerShell:

```powershell
git clone <this-repo-url> "$env:USERPROFILE\.cursor\skills\bigquery"
```

macOS / Linux:

```bash
git clone <this-repo-url> ~/.cursor/skills/bigquery
```

Or run the bundled installer after cloning anywhere:

```powershell
.\install.ps1        # Windows
```

```bash
./install.sh         # macOS / Linux
```

### Option B — project skill (checked in with a repo)

Copy the entire folder to `<your-project>/.cursor/skills/bigquery/` and
commit it. Every collaborator gets it automatically.

## Prerequisites

```bash
pip install -r requirements.txt
gcloud auth application-default login
gcloud config set project <your-billing-project>
```

`<your-billing-project>` is a project you own (with the BigQuery API enabled)
that will be charged for the scanned bytes. You still query *other people's*
public data (e.g. `cwts-leiden.openalex_2025aug`); the billing project is
separate from the data project.

## Quick usage (from an agent chat)

> "Using the bigquery skill, get me the number of OpenAlex works per pub_year
> for authors affiliated with Nanjing University between 2018 and 2022."

The agent will:

1. Look up `openalex` in `datasets/INDEX.md`
2. Read `datasets/openalex/README.md`, `relationships.md`, and relevant
   `dictionary.csv` rows
3. Draft SQL following `reference/sql-conventions.md`
4. Dry-run via `scripts/run_query.py` to estimate scan bytes and cost
5. Ask you before executing anything expensive

## Add a new dataset

```bash
python scripts/scaffold_dataset.py mydataset
# edit datasets/mydataset/{README.md,dictionary.csv,relationships.md,examples.sql}
# add a row to datasets/INDEX.md
```

That's it — the core `SKILL.md` doesn't need to change.

## Repository layout

```
cursor-skill-bigquery/
├── SKILL.md                     # main skill instructions
├── reference/                   # generic BQ how-to (auth, SQL, cost safety)
├── datasets/
│   ├── INDEX.md                 # registry
│   └── <name>/                  # one folder per dataset adapter
├── scripts/
│   ├── run_query.py             # dry-run → confirm → execute, with byte cap
│   ├── list_datasets.py
│   └── scaffold_dataset.py
├── install.ps1 / install.sh     # symlink/copy to ~/.cursor/skills/bigquery
├── requirements.txt
└── .env.example
```

## License

Private — internal use only. Do not redistribute.
