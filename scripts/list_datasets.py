#!/usr/bin/env python3
"""Print the dataset registry from datasets/INDEX.md.

Usage:
    python scripts/list_datasets.py
"""

from __future__ import annotations

import sys
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    index = root / "datasets" / "INDEX.md"
    if not index.exists():
        sys.stderr.write(f"Not found: {index}\n")
        return 2
    print(index.read_text(encoding="utf-8"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
