#!/usr/bin/env bash
set -euo pipefail

# Update the logi-options-offline cask with a new SHA256 hash.
# Downloads the installer, computes the hash, and updates both
# the cask file and metadata file.
#
# Usage: update-logi-cask.sh [metadata_json]
#
# If metadata_json is provided (from check-logi-update.sh), it will be used
# to update the metadata file. Otherwise, fresh headers will be fetched.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DOWNLOAD_URL="https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer_offline.zip"
CASK_FILE="$REPO_ROOT/Casks/offline-logi-options+.rb"
METADATA_FILE="$REPO_ROOT/.github/offline-logi-options+-metadata.json"

download_and_hash() {
    local tmpfile
    tmpfile=$(mktemp)
    trap "rm -f '$tmpfile'" EXIT

    echo "Downloading installer..." >&2
    curl -fSL -o "$tmpfile" "$DOWNLOAD_URL"

    echo "Computing SHA256..." >&2
    sha256sum "$tmpfile" | cut -d' ' -f1
}

fetch_metadata() {
    local headers
    headers=$(curl -sI "$DOWNLOAD_URL" 2>/dev/null)

    local etag last_modified content_length
    etag=$(echo "$headers" | grep -i "^etag:" | tail -1 | sed 's/etag: *//i' | tr -d '\r"')
    last_modified=$(echo "$headers" | grep -i "^last-modified:" | tail -1 | sed 's/last-modified: *//i' | tr -d '\r')
    content_length=$(echo "$headers" | grep -i "^content-length:" | tail -1 | sed 's/content-length: *//i' | tr -d '\r')

    cat <<EOF
{
  "etag": "$etag",
  "last_modified": "$last_modified",
  "content_length": "$content_length"
}
EOF
}

update_cask() {
    local new_hash="$1"
    sed -i "s/sha256 \"[a-f0-9]\{64\}\"/sha256 \"$new_hash\"/" "$CASK_FILE"
    echo "Updated cask SHA256 to: $new_hash" >&2
}

update_metadata() {
    local metadata_json="$1"
    local new_hash="$2"

    local etag last_modified content_length
    etag=$(echo "$metadata_json" | jq -r '.etag')
    last_modified=$(echo "$metadata_json" | jq -r '.last_modified')
    content_length=$(echo "$metadata_json" | jq -r '.content_length')

    cat > "$METADATA_FILE" <<EOF
{
  "etag": "$etag",
  "last_modified": "$last_modified",
  "content_length": "$content_length",
  "sha256": "$new_hash",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    echo "Updated metadata file" >&2
}

main() {
    local metadata_json="${1:-}"

    if [[ -z "$metadata_json" ]]; then
        echo "Fetching current metadata..." >&2
        metadata_json=$(fetch_metadata)
    fi

    local new_hash
    new_hash=$(download_and_hash)

    update_cask "$new_hash"
    update_metadata "$metadata_json" "$new_hash"

    echo "$new_hash"
}

main "$@"
