#!/usr/bin/env bash
set -euo pipefail

# Check if the Logitech Options+ offline installer has changed.
# Uses HTTP headers to detect changes without downloading the full file.
#
# Exit codes:
#   0 - Changes detected
#   1 - No changes detected
#   2 - Error (missing metadata file, network error, etc.)
#
# When changes are detected, outputs new metadata as JSON to stdout.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DOWNLOAD_URL="https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer_offline.zip"
METADATA_FILE="$REPO_ROOT/.github/offline-logi-options+-metadata.json"

fetch_headers() {
    curl -sI "$DOWNLOAD_URL" 2>/dev/null
}

extract_header() {
    local headers="$1"
    local header_name="$2"
    echo "$headers" | grep -i "^${header_name}:" | tail -1 | sed "s/${header_name}: *//i" | tr -d '\r"'
}

main() {
    if [[ ! -f "$METADATA_FILE" ]]; then
        echo "Metadata file not found: $METADATA_FILE" >&2
        exit 2
    fi

    local headers
    headers=$(fetch_headers)

    if [[ -z "$headers" ]]; then
        echo "Failed to fetch headers from $DOWNLOAD_URL" >&2
        exit 2
    fi

    local etag last_modified content_length
    etag=$(extract_header "$headers" "etag")
    last_modified=$(extract_header "$headers" "last-modified")
    content_length=$(extract_header "$headers" "content-length")

    local stored_etag stored_last_modified stored_content_length
    stored_etag=$(jq -r '.etag // ""' "$METADATA_FILE")
    stored_last_modified=$(jq -r '.last_modified // ""' "$METADATA_FILE")
    stored_content_length=$(jq -r '.content_length // ""' "$METADATA_FILE")

    # No changes if ETag matches
    if [[ "$etag" == "$stored_etag" ]]; then
        exit 1
    fi

    # No changes if both Last-Modified and Content-Length match
    if [[ "$last_modified" == "$stored_last_modified" && "$content_length" == "$stored_content_length" ]]; then
        exit 1
    fi

    # Changes detected - output new metadata
    cat <<EOF
{
  "etag": "$etag",
  "last_modified": "$last_modified",
  "content_length": "$content_length"
}
EOF
    exit 0
}

main "$@"
