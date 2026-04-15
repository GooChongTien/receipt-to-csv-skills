#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${RECEIPT_TO_CSV_PROJECT_ROOT:-}"

if [[ -z "$PROJECT_ROOT" ]]; then
    if [[ -d "$PWD/web-app" ]]; then
        PROJECT_ROOT="$PWD"
    else
        echo "Could not locate the ReceiptToCSV project root." >&2
        echo "Run this from the ReceiptToCSV project root or set RECEIPT_TO_CSV_PROJECT_ROOT." >&2
        exit 1
    fi
fi

PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"
WEB_APP_DIR="$PROJECT_ROOT/web-app"
PUBLIC_DIR="$WEB_APP_DIR/public"
API_PORT="${RECEIPT_TO_CSV_API_PORT:-8787}"
WEB_PORT="${RECEIPT_TO_CSV_WEB_PORT:-5173}"
APP_URL="http://127.0.0.1:${WEB_PORT}/app?mode=skill"
BACKEND_LOG="${TMPDIR:-/tmp}/receipttocsv-skill-backend.log"
FRONTEND_LOG="${TMPDIR:-/tmp}/receipttocsv-skill-frontend.log"
SESSION_FILE="${RECEIPT_TO_CSV_SESSION_FILE:-}"
PUBLIC_SESSION_FILE="$PUBLIC_DIR/preloaded-session.json"

if [[ ! -d "$WEB_APP_DIR" ]]; then
    echo "Expected web-app directory at $WEB_APP_DIR" >&2
    exit 1
fi

is_listening() {
    lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

kill_listener() {
    local port="$1"
    local pids
    pids="$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)"
    if [[ -n "$pids" ]]; then
        kill $pids >/dev/null 2>&1 || true
        sleep 1
    fi
}

escape_for_osascript() {
    local value="$1"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '%s' "$value"
}

launch_in_terminal() {
    local command="$1"
    local escaped
    escaped="$(escape_for_osascript "$command")"
    osascript <<EOF >/dev/null
tell application "Terminal"
    activate
    do script "$escaped"
end tell
EOF
}

wait_for_url() {
    local url="$1"
    for _ in $(seq 1 60); do
        if curl -fsS "$url" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    return 1
}

if [[ ! -d "$WEB_APP_DIR/node_modules/openai" ]]; then
    npm --prefix "$WEB_APP_DIR" install --no-audit --no-fund >/dev/null
fi

if [[ -n "$SESSION_FILE" ]]; then
    mkdir -p "$PUBLIC_DIR"
    cp "$SESSION_FILE" "$PUBLIC_SESSION_FILE"
else
    rm -f "$PUBLIC_SESSION_FILE"
fi

if [[ -n "$SESSION_FILE" ]]; then
    kill_listener "$API_PORT"
    kill_listener "$WEB_PORT"
fi

if ! is_listening "$API_PORT"; then
    if command -v osascript >/dev/null 2>&1; then
        launch_in_terminal "cd \"$PROJECT_ROOT\" && env RECEIPT_TO_CSV_API_PORT=\"$API_PORT\" RECEIPT_TO_CSV_SESSION_FILE=\"$SESSION_FILE\" node \"$WEB_APP_DIR/scripts/local_skill_server.mjs\" | tee \"$BACKEND_LOG\""
    else
        nohup env RECEIPT_TO_CSV_API_PORT="$API_PORT" RECEIPT_TO_CSV_SESSION_FILE="$SESSION_FILE" \
            node "$WEB_APP_DIR/scripts/local_skill_server.mjs" \
            >"$BACKEND_LOG" 2>&1 &
    fi
fi

if ! is_listening "$WEB_PORT"; then
    if command -v osascript >/dev/null 2>&1; then
        launch_in_terminal "cd \"$PROJECT_ROOT\" && env RECEIPT_TO_CSV_API_PORT=\"$API_PORT\" RECEIPT_TO_CSV_OPEN_BROWSER=0 npm --prefix \"$WEB_APP_DIR\" run dev -- --host 127.0.0.1 --port \"$WEB_PORT\" | tee \"$FRONTEND_LOG\""
    else
        nohup env RECEIPT_TO_CSV_API_PORT="$API_PORT" RECEIPT_TO_CSV_OPEN_BROWSER=0 \
            npm --prefix "$WEB_APP_DIR" run dev -- --host 127.0.0.1 --port "$WEB_PORT" \
            >"$FRONTEND_LOG" 2>&1 &
    fi
fi

wait_for_url "http://127.0.0.1:${API_PORT}/api/health"
wait_for_url "http://127.0.0.1:${WEB_PORT}/"

if command -v open >/dev/null 2>&1; then
    open "$APP_URL"
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$APP_URL"
fi

echo "ReceiptToCSV local skill app is ready:"
echo "  UI: $APP_URL"
echo "  API: http://127.0.0.1:${API_PORT}/api/health"
echo "  Backend log: $BACKEND_LOG"
echo "  Frontend log: $FRONTEND_LOG"
