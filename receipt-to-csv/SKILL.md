---
name: receipt-to-csv
description: Convert receipt folders into `CSV` + `DOCX` + copied `attachments/` using a two-stage flow where Codex performs extraction and passes a structured JSON payload to a formatter script. Use when users ask for batch receipt processing by folder path in Codex terminal.
---

# Receipt To CSV

Use this skill to batch-process receipt files from a local folder into a structured output bundle with home-currency reimbursement conversion.

## Workflow

1. Confirm scope:
- Use this skill strictly for CLI/batch path-based processing.

2. Ask for source folder if missing:
- If the user did not provide a source path, ask exactly one question:
  `Which folder path should I scan for receipts (images and PDFs)?`

3. Discover files and extract outside script:
- Collect supported receipt files (`.jpg`, `.jpeg`, `.png`, `.webp`, `.heic`, `.heif`, `.pdf`) under the folder.
- Extract receipt fields using Codex agent workflow (vision/PDF understanding).
- Build a structured JSON payload with receipt currency + amount from extraction (schema in [REFERENCE.md](REFERENCE.md), examples in [EXAMPLES.md](EXAMPLES.md)).

4. Run the bundled script with payload:
```bash
python3 scripts/receipt_to_csv.py "<folder-path>" --payload-file "/tmp/receipt_payload.json" --home-currency "SGD"
```

5. Verify output bundle:
- Script must create one subfolder under the scanned path.
- Subfolder must contain:
  - `report.csv`
  - `report.docx`
  - `attachments/` (copied files with standardized names)

6. Report results succinctly:
- Include output folder path.
- Include number of processed files.
- Mention any skipped/failed files.

## Output Contract

- CSV schema and sample mapping are defined in [EXAMPLES.md](EXAMPLES.md).
- Script behavior, options, and dependency details are defined in [REFERENCE.md](REFERENCE.md).
- Favor deterministic output names for repeatability.
- If extraction confidence is weak, set row `status` to `NEEDS_REVIEW` in payload.
- Reimbursement fields are normalized to the configured home currency.

## Notes

- Never delete or overwrite source receipts.
- The script does formatting/export only; it does not call Gemini/OCR itself.
- DOCX attachment section embeds images directly and tries to render PDF pages as images for supporting proof.
