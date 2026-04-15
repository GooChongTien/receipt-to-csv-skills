# Receipt To CSV Skills

Codex skills for turning receipt folders into structured reimbursement outputs and, when desired, handing the results into a local review UI before export.

Outputs:
- `report.csv`
- `report.docx`
- `attachments/`

## Modes

This skill package supports two working modes:

- Review mode: Codex scans a receipt folder, builds a payload, converts it into a preloaded session, and opens the local `ReceiptToCSV` app directly on the review/export workspace.
- CLI batch mode: Codex scans a receipt folder and generates the output bundle directly without opening the UI.

Default behavior:
- If the user asks to scan or review receipts, prefer review mode.
- Use CLI batch mode only when the user explicitly asks to skip the UI and generate final files directly.

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

1. Codex scans a folder and writes `/tmp/receipt_payload.json`
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

## Important Dependency

This repo packages the skill and helper scripts. The review UI itself lives in the main `ReceiptToCSV` project and expects access to its `web-app/` folder.

The launcher script will work when one of these is true:
- you run it from the `ReceiptToCSV` project root
- you set `RECEIPT_TO_CSV_PROJECT_ROOT` to a checkout of the `ReceiptToCSV` project

## Hosted App

If you only want the browser product instead of the Codex skill workflow:

- [https://receipts-to-csv.vercel.app](https://receipts-to-csv.vercel.app)
