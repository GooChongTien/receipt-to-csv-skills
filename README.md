# Receipt To CSV Skills

Codex skills for turning receipt folders into structured reimbursement outputs and, when desired, handing the results into a local review UI before export.

Outputs:
- `report.csv`
- `report.docx`
- `attachments/`

## Modes

This skill package supports two working modes:

- Review mode: the active host model scans a receipt folder, builds a payload, converts it into a preloaded session, and opens the local `ReceiptToCSV` app directly on the review/export workspace.
- CLI batch mode: the active host model scans a receipt folder and generates the output bundle directly without opening the UI.

Default behavior:
- If the user asks to scan or review receipts, prefer review mode.
- Use CLI batch mode only when the user explicitly asks to skip the UI and generate final files directly.

Host-model expectation:
- In Codex, this should use the active GPT/Codex session.
- In Claude Code, this should use the active Claude session.
- In Gemini CLI, this should use the active Gemini session.
- The browser app is only the review/export surface in review mode; it is not the intended extraction engine.

## What This Solves

- Mixed file types (`jpg`, `png`, `pdf`) scattered in folders
- Manual spreadsheet entry that is slow and error-prone
- Inconsistent attachment naming across claim submissions
- Need for a review step before final export
- Need for deterministic CSV + DOCX + copied attachments when no review UI is wanted

## Included Files

- `receipt-to-csv/SKILL.md`: Codex workflow instructions
- `receipt-to-csv/REFERENCE.md`: script contract and payload schema
- `receipt-to-csv/EXAMPLES.md`: payload and output examples
- `receipt-to-csv/scripts/receipt_to_csv.py`: formatter/export script
- `receipt-to-csv/scripts/payload_to_preloaded_session.py`: converts a scan payload into a UI session file
- `receipt-to-csv/scripts/open_local_app.sh`: launches the local review UI against a preloaded session

## Review Flow

The intended review flow is:

1. The active host model scans a folder and writes `/tmp/receipt_payload.json`
2. Convert that payload into a preloaded session:

```bash
python3 receipt-to-csv/scripts/payload_to_preloaded_session.py "<folder-path>" \
  --payload-file "/tmp/receipt_payload.json" \
  --output-file "/tmp/receipt_preloaded_session.json"
```

3. Launch the local app with that session:

```bash
RECEIPT_TO_CSV_SESSION_FILE="/tmp/receipt_preloaded_session.json" \
bash receipt-to-csv/scripts/open_local_app.sh
```

When the session contains rows, the local app should land directly on the workspace for review/export.

Review payload rules:
- set `extraction_label` to the host label or model family such as `Codex`, `Claude Code`, or `Gemini CLI`
- normalize reimbursement currency/amount to the configured home currency
- keep `NEEDS_REVIEW` when extraction confidence is weak or FX conversion cannot be resolved cleanly
- avoid OCR-fallback wording in remarks unless OCR was actually used

Prerequisite checks:
- run `bash receipt-to-csv/scripts/check_prereqs.sh review` before launching the local review app
- run `bash receipt-to-csv/scripts/check_prereqs.sh cli` before running the formatter directly
- the check fails early with install guidance when required tools such as `node`, `npm`, `python3`, or required Python packages are missing

## Important Dependency

This repo packages the skill and helper scripts. The review UI itself lives in the main `ReceiptToCSV` project and expects access to its `web-app/` folder.

The launcher script will work when one of these is true:
- you run it from the `ReceiptToCSV` project root
- you set `RECEIPT_TO_CSV_PROJECT_ROOT` to a checkout of the `ReceiptToCSV` project

## Hosted App

If you only want the browser product instead of the Codex skill workflow:

- [https://receipts-to-csv.vercel.app](https://receipts-to-csv.vercel.app)
