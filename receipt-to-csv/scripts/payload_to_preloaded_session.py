#!/usr/bin/env python3
"""Wrap a receipt payload into a preloaded UI session file."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def load_payload(payload_file: Path) -> dict[str, Any]:
    payload = json.loads(payload_file.read_text(encoding="utf-8"))
    if isinstance(payload, list):
        return {"rows": payload}
    if isinstance(payload, dict):
        return payload
    raise ValueError("Payload must be a JSON object or array.")


def absolutize_source_paths(source_folder: Path, payload: dict[str, Any]) -> dict[str, Any]:
    rows = payload.get("rows")
    if not isinstance(rows, list):
        raise ValueError("Payload must contain a 'rows' array.")

    normalized_rows: list[dict[str, Any]] = []
    for index, row in enumerate(rows, start=1):
        if not isinstance(row, dict):
            raise ValueError(f"Row {index} is not an object.")

        source_path = row.get("source_path") or row.get("sourcePath")
        if source_path:
            candidate = Path(str(source_path))
            if not candidate.is_absolute():
                candidate = (source_folder / candidate).resolve()
            row = {
                **row,
                "source_path": str(candidate),
            }

        normalized_rows.append(row)

    return {
        "sourceFolder": str(source_folder.resolve()),
        "sessionTitle": payload.get("sessionTitle"),
        "rows": normalized_rows,
        "skippedFiles": payload.get("skippedFiles", []),
        "failedFiles": payload.get("failedFiles", []),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_folder", help="Folder containing the source receipts.")
    parser.add_argument("--payload-file", required=True, help="Path to the extracted payload JSON.")
    parser.add_argument("--output-file", required=True, help="Path to write the preloaded session JSON.")
    parser.add_argument("--session-title", help="Optional session title override.")
    args = parser.parse_args()

    source_folder = Path(args.source_folder).expanduser().resolve()
    payload_file = Path(args.payload_file).expanduser().resolve()
    output_file = Path(args.output_file).expanduser().resolve()

    payload = load_payload(payload_file)
    session = absolutize_source_paths(source_folder, payload)
    if args.session_title:
        session["sessionTitle"] = args.session_title
    elif not session.get("sessionTitle"):
        session["sessionTitle"] = source_folder.name

    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_text(json.dumps(session, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
