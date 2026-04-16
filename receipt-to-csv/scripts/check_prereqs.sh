#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-review}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
WEB_APP_DIR="$ROOT_DIR/web-app"

errors=()
warnings=()

add_error() {
    errors+=("$1")
}

add_warning() {
    warnings+=("$1")
}

require_command() {
    local cmd="$1"
    local message="$2"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        add_error "$message"
    fi
}

python_import_check() {
    local module="$1"
    local message="$2"
    if ! python3 -c "import ${module}" >/dev/null 2>&1; then
        add_error "$message"
    fi
}

python_optional_import_check() {
    local module="$1"
    local message="$2"
    if ! python3 -c "import ${module}" >/dev/null 2>&1; then
        add_warning "$message"
    fi
}

check_common() {
    require_command "python3" "Missing \`python3\`. Install Python 3 to use the receipt-to-csv skill."
}

check_review() {
    check_common

    require_command "node" "Missing \`node\`. Review mode needs Node.js to run the local ReceiptToCSV app."
    require_command "npm" "Missing \`npm\`. Review mode uses npm to install/start the local ReceiptToCSV app."
    require_command "curl" "Missing \`curl\`. Review mode uses curl for local health checks."
    require_command "lsof" "Missing \`lsof\`. Review mode uses lsof to manage local app ports."

    if [[ ! -d "$WEB_APP_DIR" ]]; then
        add_error "Missing \`web-app/\` at $WEB_APP_DIR. Review mode needs a full ReceiptToCSV project checkout."
        return
    fi

    if [[ ! -f "$WEB_APP_DIR/package.json" ]]; then
        add_error "Missing \`$WEB_APP_DIR/package.json\`. Review mode cannot start the local app without the web app package."
    fi

    if [[ ! -f "$WEB_APP_DIR/scripts/local_skill_server.mjs" ]]; then
        add_error "Missing \`$WEB_APP_DIR/scripts/local_skill_server.mjs\`. Review mode backend launcher is not available."
    fi

    if ! command -v open >/dev/null 2>&1 && ! command -v xdg-open >/dev/null 2>&1; then
        add_warning "No browser opener found (\`open\` or \`xdg-open\`). The app can still start, but you may need to open the URL manually."
    fi

    if ! command -v osascript >/dev/null 2>&1; then
        add_warning "Missing \`osascript\`. The launcher will use a background process instead of opening new Terminal tabs."
    fi
}

check_cli() {
    check_common

    python_import_check "docx" "Missing Python package \`python-docx\`. Install it with \`python3 -m pip install python-docx\`."
    python_import_check "requests" "Missing Python package \`requests\`. Install it with \`python3 -m pip install requests\`."
    python_optional_import_check "PIL" "Python package \`pillow\` is not installed. Image embedding quality in DOCX may be reduced."
    python_optional_import_check "fitz" "Python package \`pymupdf\` is not installed. PDF preview rendering in DOCX will rely on CLI/system fallbacks."

    if ! command -v pdftoppm >/dev/null 2>&1 && ! command -v qlmanage >/dev/null 2>&1; then
        add_warning "Neither \`pdftoppm\` nor \`qlmanage\` is available. PDF previews in DOCX may fall back to placeholder text."
    fi
}

case "$MODE" in
    review)
        check_review
        ;;
    cli)
        check_cli
        ;;
    *)
        add_error "Unknown mode \`$MODE\`. Use \`review\` or \`cli\`."
        ;;
esac

if (( ${#warnings[@]} > 0 )); then
    printf 'Warnings:\n' >&2
    for warning in "${warnings[@]}"; do
        printf '  - %s\n' "$warning" >&2
    done
fi

if (( ${#errors[@]} > 0 )); then
    printf 'ReceiptToCSV prerequisite check failed for mode `%s`:\n' "$MODE" >&2
    for error in "${errors[@]}"; do
        printf '  - %s\n' "$error" >&2
    done
    exit 1
fi

printf 'ReceiptToCSV prerequisite check passed for mode `%s`.\n' "$MODE"
