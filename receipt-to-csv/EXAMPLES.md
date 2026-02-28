# ReceiptToCSV Output Template

Use this mapping as the default output contract.

## Example Payload (Agent -> Script)

```json
{
  "rows": [
    {
      "source_path": "IMG_4831.jpg",
      "receipt_date": "2026-02-15",
      "merchant": "Acme Cafe",
      "description": "Food & Beverage",
      "receipt_currency": "MYR",
      "receipt_amount": 12.5,
      "reimb_currency": "SGD",
      "fx_rate_to_home": 0.302,
      "remark": "",
      "category": "RECEIPT",
      "status": "OK"
    },
    {
      "source_path": "subdir/receipt-0002.pdf",
      "receipt_date": "2026-02-16",
      "merchant": "OfficeMart",
      "description": "Office Supplies",
      "receipt_currency": "IDR",
      "receipt_amount": 151300,
      "reimb_currency": "SGD",
      "status": "NEEDS_REVIEW"
    }
  ]
}
```

Home currency behavior:
- Run script with `--home-currency SGD`.
- If `reimb_amount` is missing, script computes reimbursement amount in SGD.
- If `fx_rate_to_home` is provided, that rate is used directly.

## Folder Structure

```text
<scanned-folder>/
  receipt_to_csv_output_YYYYMMDD_HHMMSS/
    report.csv
    report.docx
    attachments/
      001_2026-02-15_Acme_Cafe_12.50_MYR.jpg
      002_2026-02-16_OfficeMart_84.00_SGD.pdf
```

## CSV Template

Required header order:

```csv
No,Original Filename,New Name,Receipt Date,Merchant,Description,Rcpt Ccy,Rcpt Amt,Reimb Ccy,Reimb Amt,Remark,Category,Status
```

Example row:

```csv
1,IMG_4831.jpg,001_2026-02-15_Acme_Cafe_12.50_MYR.jpg,2026-02-15,Acme Cafe,Food & Beverage,MYR,12.50,SGD,3.78,FX rate MYR->SGD: 0.302000,RECEIPT,OK
```

## DOCX Template

Section order:
1. Title block:
   - `ReceiptToCSV Report`
   - generation timestamp
2. Summary table columns:
   - `No`
   - `Receipt Date`
   - `Filename`
   - `Merchant / Description`
   - `Reimb Ccy`
   - `Reimb Amt`
3. `Attachments` section:
   - numbered list of attachment filenames
   - image previews for image attachments when available
   - PDF files rendered page-by-page as images (when `pymupdf` is available)
   - placeholder text only if PDF rendering is unavailable
