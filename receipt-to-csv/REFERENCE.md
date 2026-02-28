# Script Contract

Script path: `scripts/receipt_to_csv.py`

## Purpose

Create output artifacts from an agent-generated structured payload and source receipt files:
- `report.csv`
- `report.docx`
- `attachments/` with copied + renamed files
- reimbursement currency/amount converted to home currency

## Runtime Behavior

1. If no positional folder argument is provided, prompt:
   `Which folder path should I scan for receipts (images and PDFs)?`
2. Read structured JSON payload from `--payload-file` or `--payload-json`.
3. Resolve each payload row to a source file using `source_path` (or filename fallback when unique).
4. Create an output subfolder under the scanned folder.
5. Copy files into `attachments/` with standardized names.
6. Compute reimbursement currency/amount in home currency:
   - use payload `reimb_amount` if provided
   - otherwise convert from `receipt_currency` + `receipt_amount` into home currency
   - use payload `fx_rate_to_home` when provided, otherwise fetch rate from FX API
7. Export CSV and DOCX from the payload-mapped rows.

The script does not perform OCR or model extraction.
PDF page rendering backend order: `pymupdf` -> `pdftoppm` -> `qlmanage`.

## CLI Usage

```bash
python3 scripts/receipt_to_csv.py "<folder-path>" \
  --payload-file "/tmp/receipt_payload.json" \
  --home-currency SGD
```

Optional flags:

```bash
python3 scripts/receipt_to_csv.py "<folder-path>" \
  --payload-file "/tmp/receipt_payload.json" \
  --home-currency SGD \
  --max-pdf-pages 8 \
  --output-subfolder my_claim_run
```

Or inline payload:

```bash
python3 scripts/receipt_to_csv.py "<folder-path>" \
  --payload-json '{"rows":[{"source_path":"IMG_0001.jpg","receipt_date":"2026-02-15","merchant":"Acme Cafe","description":"Food & Beverage","receipt_currency":"MYR","receipt_amount":12.5}]}' \
  --home-currency SGD
```

## Payload Schema

Top level:

```json
{
  "rows": []
}
```

`rows` can also be a plain JSON array.

Each row supports:
- `source_path` (recommended): absolute path or path relative to the scanned folder
- `original_filename` (fallback lookup when unique in folder tree)
- `new_name` (optional custom attachment output name; extension preserved from source)
- `receipt_date` or `receiptDate`
- `merchant`
- `description`
- `receipt_currency` or `receiptCurrency`
- `receipt_amount` or `receiptAmount`
- `reimb_currency` or `reimbCurrency`
- `reimb_amount` or `reimbAmount`
- `fx_rate_to_home` or `fxRateToHome` (optional explicit FX rate override)
- `remark`
- `category` (default `RECEIPT`)
- `status` (`OK`, `NEEDS_REVIEW`, `FAILED`; auto-derived if missing)

The script will skip rows when source files cannot be resolved.

## Dependencies

Install dependencies before running:

```bash
python3 -m pip install python-docx pillow requests pymupdf
```

Notes:
- `python-docx` is required.
- `pillow` is optional but recommended for better WebP/HEIC/HEIF image embedding in DOCX.
- `requests` is required for automatic FX lookup when no explicit FX rate is supplied.
- For PDF-as-image in DOCX, any one of these works: `pymupdf` (Python), `pdftoppm` (Poppler CLI), or `qlmanage` (macOS).
- If none of the PDF rendering backends are available, script still runs and inserts placeholder lines for PDFs.

## Output Naming

- Attachments are renamed deterministically with row index + core fields.
- Duplicate names are de-duplicated with suffixes (`_01`, `_02`, ...).
- Output subfolder defaults to `receipt_to_csv_output_YYYYMMDD_HHMMSS`.
- DOCX PDF previews embed up to `--max-pdf-pages` pages per PDF (`0` means all pages).
