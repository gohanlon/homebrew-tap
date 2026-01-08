#!/usr/bin/env bash
set -euo pipefail

# Update the offline-logi-options+ cask.
# Downloads the installer, computes the hash, extracts the version,
# and updates both the cask file and metadata file.
#
# Usage: update-logi-cask.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DOWNLOAD_URL="https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer_offline.zip"
CASK_FILE="$REPO_ROOT/Casks/offline-logi-options+.rb"
METADATA_FILE="$REPO_ROOT/.github/offline-logi-options+-metadata.json"

download_and_extract_info() {
    local tmpfile
    tmpfile=$(mktemp)
    trap "rm -f '$tmpfile'" EXIT

    echo "Downloading installer..." >&2
    curl -fSL -o "$tmpfile" "$DOWNLOAD_URL"

    echo "Computing SHA256..." >&2
    local sha256
    sha256=$(sha256sum "$tmpfile" | cut -d' ' -f1)

    echo "Extracting version from Info.plist..." >&2
    local plist_path="logioptionsplus_installer_offline.app/Contents/Info.plist"
    local version
    version=$(unzip -p "$tmpfile" "$plist_path" | grep -A1 CFBundleVersion | grep string | sed 's/.*<string>\(.*\)<\/string>.*/\1/')

    if [[ -z "$version" ]]; then
        echo "Failed to extract version from Info.plist" >&2
        exit 1
    fi

    echo "$sha256 $version"
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
    local new_version="$2"
    sed -i "s/sha256 \"[a-f0-9]\{64\}\"/sha256 \"$new_hash\"/" "$CASK_FILE"
    sed -i "s/version \"[0-9.]*\"/version \"$new_version\"/" "$CASK_FILE"
    echo "Updated cask to version $new_version with SHA256 $new_hash" >&2
}

update_metadata() {
    local metadata_json="$1"
    local new_hash="$2"
    local new_version="$3"

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
  "version": "$new_version",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    echo "Updated metadata file" >&2
}

main() {
    echo "Fetching current metadata..." >&2
    local metadata_json
    metadata_json=$(fetch_metadata)

    local info new_hash new_version
    info=$(download_and_extract_info)
    new_hash=$(echo "$info" | cut -d' ' -f1)
    new_version=$(echo "$info" | cut -d' ' -f2)

    update_cask "$new_hash" "$new_version"
    update_metadata "$metadata_json" "$new_hash" "$new_version"

    # Output hash and version for the workflow
    echo "$new_hash $new_version"
}

main "$@"
