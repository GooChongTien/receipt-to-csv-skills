---
name: receipt-to-csv
description: Convert receipt folders into `CSV` + `DOCX` + copied `attachments/` using a two-stage flow where Codex performs extraction and passes a structured JSON payload to a formatter script. Use when users ask for batch receipt processing by folder path in Codex terminal.
---

# Receipt To CSV

Use this skill in one of two modes:

- review mode: the user gives a folder path, Codex scans receipts, then the local app opens directly on the review/export workspace
- CLI batch mode: the user gives a folder path and wants deterministic export without the review UI

Default behavior:

- If the user asks to "scan receipts", "review receipts", or otherwise wants to inspect/edit results in the UI, prefer review mode by default.
- Use CLI batch mode only when the user explicitly asks for direct output files without the review UI.

## Workflow

1. Confirm scope:
- If the user wants UI review after scan, use review mode.
- Treat review mode as the normal/default path for folder-based receipt scanning.
- In review mode, the extraction engine is the active host model session itself. Do not route review-mode extraction through Gemini API, local OCR, Apple Vision OCR, or the local app backend.
- The skill should describe the result as scanned by the host model, not a browser-side extractor.
- If the host environment exposes the active model name, you may mention that exact model in the result.
- In review mode, the skill performs extraction itself from the folder path, writes a payload JSON, converts that payload into a preloaded session file, then launches:
  `RECEIPT_TO_CSV_SESSION_FILE="/tmp/receipt_preloaded_session.json" bash receipt-to-csv/scripts/open_local_app.sh`
- The local app must open `http://127.0.0.1:5173/app?mode=skill` and land directly in the workspace when the preloaded session contains rows.
- In this flow, the browser app does not do receipt extraction itself.
- In this flow, the skill does the scan first and the app acts only as the review/export surface.
- Use CLI mode only when the user explicitly wants final files generated without the review UI.

2. Ask for source folder if missing:
- If the user did not provide a source path, ask exactly one question:
  `Which folder path should I scan for receipts (images and PDFs)?`

3. Discover files and extract outside script:
- Collect supported receipt files (`.jpg`, `.jpeg`, `.png`, `.webp`, `.heic`, `.heif`, `.pdf`) under the folder.
- Extract receipt fields using the active host agent workflow (vision/PDF understanding).
- Build a structured JSON payload with receipt currency + amount from extraction (schema in [REFERENCE.md](REFERENCE.md), examples in [EXAMPLES.md](EXAMPLES.md)).
- In review mode payloads, set `extraction_source` to the host-model scan flow for rows produced by the agent workflow.
- In review mode payloads, set `extraction_label` to the active host agent label or model family that performed the scan, for example `Codex`, `Claude Code`, or `Gemini CLI`.
- Do not include OCR-fallback wording in remarks unless OCR was actually used.

4. Continue based on mode:
For review mode, wrap the payload into a preloaded session file first:

```bash
python3 receipt-to-csv/scripts/payload_to_preloaded_session.py "<folder-path>" \
  --payload-file "/tmp/receipt_payload.json" \
  --output-file "/tmp/receipt_preloaded_session.json"
```

Then launch the app with that session:

```bash
RECEIPT_TO_CSV_SESSION_FILE="/tmp/receipt_preloaded_session.json" \
bash receipt-to-csv/scripts/open_local_app.sh
```

For CLI batch mode, run the bundled script:

```bash
python3 receipt-to-csv/scripts/receipt_to_csv.py "<folder-path>" \
  --payload-file "/tmp/receipt_payload.json" \
  --home-currency "SGD"
```

5. Verify output bundle for CLI mode:
- Script must create one subfolder under the scanned path.
- Subfolder must contain:
  - `report.csv`
  - `report.docx`
  - `attachments/` (copied files with standardized names)

6. Report results succinctly:
- Include output folder path.
- Include number of processed files.
- Mention any skipped/failed files.
- In review mode, include the local app URL and mention any rows marked `NEEDS_REVIEW`.

## Output Contract

- CSV schema and sample mapping are defined in [EXAMPLES.md](EXAMPLES.md).
- Script behavior, options, and dependency details are defined in [REFERENCE.md](REFERENCE.md).
- Favor deterministic output names for repeatability.
- If extraction confidence is weak, set row `status` to `NEEDS_REVIEW` in payload.
- Reimbursement fields are normalized to the configured home currency.
- Rows should remain `NEEDS_REVIEW` when any key extracted field is uncertain or when reimbursement FX conversion to the home currency cannot be resolved cleanly.

## Notes

- Never delete or overwrite source receipts.
- The CLI script does formatting/export only; it does not call Gemini/OCR itself.
- Review mode uses the local app as a review/export surface for a skill-generated payload.
- Review mode should preload session data before the app renders, so the user lands on the workspace rather than an intermediate loading flow.
- The browser app can preload a session from `RECEIPT_TO_CSV_SESSION_FILE` and show previews for the original receipt files.
- The local app backend and any browser-side Gemini/Tesseract/OCR paths are not the intended extraction engine for review mode.
- `receipt-to-csv/scripts/open_local_app.sh` expects access to a `ReceiptToCSV` project checkout containing `web-app/`. Run it from that project root or set `RECEIPT_TO_CSV_PROJECT_ROOT`.
- DOCX attachment section embeds images directly and tries to render PDF pages as images for supporting proof.
