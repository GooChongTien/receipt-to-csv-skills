# ReceiptToCSV Checklist

- [ ] Ask the user for the folder path to scan if not provided.
- [ ] Confirm home currency (for example `SGD`) for reimbursement conversion.
- [ ] Verify dependencies are installed (`python-docx`, `requests`; PDF rendering via `pymupdf` or `pdftoppm`/`qlmanage`; `pillow` recommended).
- [ ] Scan supported files under the folder and extract fields outside the script.
- [ ] Build a structured JSON payload (`rows` array with `source_path`, `receipt_currency`, `receipt_amount`, and extracted fields).
- [ ] Run `scripts/receipt_to_csv.py` with `--payload-file` (or `--payload-json`) and `--home-currency`.
- [ ] Review the script output and verify the `csv`, `docx`, and `attachments/` were generated correctly.
- [ ] Present the summary of processed files back to the user.
