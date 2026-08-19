# bigquery-skill

A **platform-agnostic Agent Skill** for writing, reviewing, and executing
Google BigQuery Standard SQL, with a pluggable **dataset adapter** system so
you can add support for new datasets (OpenAlex, ORCID, Crossref, custom
project datasets, …) without touching the core skill.

Works with any agent runtime that reads local `SKILL.md` files — verified
targets: **Cursor**, **Claude Code**, **Codex CLI**. Any other SKILL.md-
compatible platform should work too by placing the folder in the
platform's skills directory.

Private repository — internal use by the author and authorized collaborators.

## Supported datasets

| name | status | source |
|---|---|---|
| `openalex` | ready | CWTS Leiden mirror (`cwts-leiden.openalex_2025aug`; only `institution_type` on `openalex_2024aug`) |
| `orcid` | ready | Dimensions on BQ. Default: `ds-open-datasets.orcid.summaries_2025` (25 M rows, 122 GB); also `summaries_2024` (Dimensions-documented, 21 M) and `summaries_2023`. Schema verified against live table (identical across snapshots) |

See `datasets/INDEX.md` for the machine-readable registry.

## Install

### One command (auto-detects agent platforms on your machine)

```powershell
# Windows PowerShell — from inside the cloned repo
.\install.ps1
```

```bash
# macOS / Linux
./install.sh
```

The installer looks for these directories and installs into each that exists:

| Platform | Target directory |
|---|---|
| Cursor | `~/.cursor/skills/bigquery/` |
| Claude Code | `~/.claude/skills/bigquery/` |
| Codex CLI | `~/.codex/skills/bigquery/` |

It prefers **symlink** so `git pull` in the repo updates every installed
copy at once. Falls back to copy if symlink is not permitted (Windows
without Developer Mode).

### Manual install (single platform)

```bash
git clone <this-repo-url> ~/.cursor/skills/bigquery         # Cursor
git clone <this-repo-url> ~/.claude/skills/bigquery         # Claude Code
git clone <this-repo-url> ~/.codex/skills/bigquery          # Codex CLI
```

### Project-scoped install (checked in with a project repo)

Copy or add-as-submodule the folder to `<your-project>/.cursor/skills/bigquery/`
(or `.claude/skills/bigquery/`, etc.) and commit it. Every collaborator gets
it automatically when they clone your project.

## Prerequisites

```bash
pip install -r requirements.txt
gcloud auth application-default login
gcloud config set project <your-billing-project>
```

`<your-billing-project>` is a GCP project you own (BigQuery API enabled)
that will be charged for scanned bytes. You still query *other people's*
public datasets (e.g. `cwts-leiden.openalex_*`, `ds-open-datasets.orcid.*`);
the billing project is separate from the data project. Dimensions gives
each account a **1 TB/month free tier** on their open datasets.

## Quick usage (from an agent chat)

> "Using the bigquery skill, get me the full employment history for ORCID
> 0000-0002-1825-0097 with ROR-disambiguated organizations."
>
> (defaults to `ds-open-datasets.orcid.summaries_2025`)

The agent will:

1. Look up `orcid` in `datasets/INDEX.md`
2. Read `datasets/orcid/README.md` (top-level structure, gotchas)
3. Read `datasets/orcid/relationships.md` (UNNEST recipe)
4. Draft SQL following `reference/sql-conventions.md`
5. Dry-run via `scripts/run_query.py` to show scan cost
6. Ask you before executing anything expensive

## Add a new dataset

```bash
python scripts/scaffold_dataset.py mydataset
# edit datasets/mydataset/{README.md,dictionary.csv,relationships.md,examples.sql}
# add a row to datasets/INDEX.md
```

The core `SKILL.md` doesn't need to change.

## Repository layout

```
bigquery-skill/
├── SKILL.md                     # main skill instructions (platform-agnostic)
├── reference/                   # generic BQ how-to (auth, SQL, cost safety)
├── datasets/
│   ├── INDEX.md                 # registry
│   └── <name>/                  # one folder per dataset adapter
│       ├── README.md
│       ├── dictionary.csv
│       ├── relationships.md
│       ├── examples.sql
│       └── assets/              # optional (schema.json, ER svg, ...)
├── scripts/
│   ├── run_query.py             # dry-run → confirm → execute, with byte cap
│   ├── list_datasets.py
│   └── scaffold_dataset.py
├── install.ps1 / install.sh     # multi-platform installer
├── requirements.txt
└── .env.example
```

## License

Private — internal use only. Do not redistribute.
