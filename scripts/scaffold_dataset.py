#!/usr/bin/env python3
"""Scaffold a new dataset adapter under datasets/<name>/.

Usage:
    python scripts/scaffold_dataset.py <name>
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


TEMPLATES = {
    "README.md": """# {name}

## Project & datasets

| BQ project | Dataset | Use for |
|---|---|---|
| `<project>` | `<dataset>` | describe |

## Primary entities

- entity_a
- entity_b

## Gotchas

- ...

## Field dictionary

See `dictionary.csv`.

## Relationships

See `relationships.md`.

## Canonical examples

See `examples.sql`.
""",
    "dictionary.csv": "table,column,type,description,notes\n",
    "relationships.md": """# {name} — Table Relationships

| from | column(s) | to | to column | notes |
|---|---|---|---|---|
| ... | ... | ... | ... | ... |
""",
    "examples.sql": """-- {name} — canonical query patterns

-- 1. TODO
SELECT 1;
""",
}


def main() -> int:
    if len(sys.argv) != 2:
        sys.stderr.write("Usage: scaffold_dataset.py <name>\n")
        return 2
    name = sys.argv[1].strip().lower()
    if not re.match(r"^[a-z][a-z0-9_-]{0,62}$", name):
        sys.stderr.write(
            "Name must be lowercase, start with a letter, and contain only [a-z0-9_-].\n"
        )
        return 2

    root = Path(__file__).resolve().parent.parent
    target = root / "datasets" / name
    if target.exists():
        sys.stderr.write(f"Already exists: {target}\n")
        return 1
    target.mkdir(parents=True, exist_ok=False)

    for filename, tmpl in TEMPLATES.items():
        (target / filename).write_text(tmpl.format(name=name), encoding="utf-8")

    print(f"Created {target} with 4 files.")
    print("Next: fill in the templates, then add a row to datasets/INDEX.md.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
