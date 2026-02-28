# Receipt To CSV Skills

Codex skills for turning receipt folders into structured reimbursement outputs:
- `report.csv`
- `report.docx`
- `attachments/`

## Pain Points

Teams handling receipts usually hit the same issues:
- Mixed file types (`jpg`, `png`, `pdf`) scattered in folders
- Manual data entry into spreadsheets (slow and error-prone)
- No consistent filename standard for supporting documents
- Currency mismatch between receipt currency and reimbursement currency
- Weak audit trail when proofs are not embedded in reports

## What This Solves

This skill package provides a repeatable CLI workflow to:
- Process receipt payloads into standardized CSV + DOCX outputs
- Copy and rename attachments deterministically
- Convert receipt amounts into a home currency (for reimbursement)
- Embed image proofs in DOCX, including PDF pages rendered as images when possible

## Included Skill

- `receipt-to-csv/`
  - `SKILL.md`: workflow for Codex usage
  - `REFERENCE.md`: script contract + payload schema
  - `EXAMPLES.md`: payload and output examples
  - `scripts/receipt_to_csv.py`: formatter/export script

## Want a Web UI Instead?

If you prefer a browser workflow, use the hosted app:

- [https://receipts-to-csv.vercel.app](https://receipts-to-csv.vercel.app)
