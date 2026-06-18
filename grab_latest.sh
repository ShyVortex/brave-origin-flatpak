#!/usr/bin/env sh
set -eu

MANIFEST_FILE="io.github.shyvortex.BraveOrigin.yaml"
METADATA_FILE="io.github.shyvortex.BraveOrigin.metainfo.xml"
REPO_URL="https://github.com/brave/brave-browser/releases/download"

if [ -f "fetch.config.yml" ]; then
    ALLOW_PRERELEASE=$(grep 'allow-prerelease:' fetch.config.yml | head -1 | awk '{print $2}')
else
    ALLOW_PRERELEASE="false"
fi

if [ "$ALLOW_PRERELEASE" = "true" ]; then
    FILTER="true"
else
    FILTER=".name | contains(\"Release\")"
fi

printf "   Fetching releases from GitHub...\n"
RELEASES_JSON=$(curl -s https://api.github.com/repos/brave/brave-browser/releases |
    jq -c "[.[] | select(.tag_name != null and ($FILTER))] | sort_by(.created_at) | last")
LATEST_VERSION=$(printf "%s" "$RELEASES_JSON" | jq -r '.tag_name')
IS_PRERELEASE=$(printf "%s" "$RELEASES_JSON" | jq -r '.prerelease')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
    printf "   Error: Failed to fetch valid version tag from GitHub.\n"
    exit 1
fi

# Extract version from current brave-origin URL
CURRENT_VERSION=$(grep -o 'brave-origin-[0-9][0-9.]*' "$MANIFEST_FILE" | head -1 | sed 's/brave-origin-//')
CURRENT_DATE=$(date '+%Y-%m-%d')

# Remove leading 'v' from version if it exists for comparison
STRIPPED_CURRENT=$(echo "$CURRENT_VERSION" | sed 's/^v//')
STRIPPED_LATEST=$(echo "$LATEST_VERSION" | sed 's/^v//')

if [ "$STRIPPED_CURRENT" = "$STRIPPED_LATEST" ]; then
    printf "   Manifest is already up to date (%s).\n" "$CURRENT_VERSION"
    # We exit successfully; the workflow will see no git diff and stop.
    exit 0
fi

# Verify download URLs and download binaries to compute SHA256 before modifying any files
printf "   Downloading binaries to compute SHA256...\n"

DL_X86="$REPO_URL/$LATEST_VERSION/brave-origin-$STRIPPED_LATEST-linux-amd64.zip"
TMP_X86=$(mktemp)
if ! curl --fail -L -s -o "$TMP_X86" "$DL_X86"; then
    printf "   Error: Download URL for x86_64 does not exist: %s\n   Skipping update.\n" "$DL_X86"
    rm -f "$TMP_X86"
    exit 0
fi

DL_ARM="$REPO_URL/$LATEST_VERSION/brave-origin-$STRIPPED_LATEST-linux-arm64.zip"
TMP_ARM=$(mktemp)
if ! curl --fail -L -s -o "$TMP_ARM" "$DL_ARM"; then
    printf "   Error: Download URL for arm64 does not exist: %s\n   Skipping update.\n" "$DL_ARM"
    rm -f "$TMP_X86" "$TMP_ARM"
    exit 0
fi

NEW_SHA256_X86=$(sha256sum "$TMP_X86" | awk '{print $1}')
NEW_SHA256_ARM=$(sha256sum "$TMP_ARM" | awk '{print $1}')
rm -f "$TMP_X86" "$TMP_ARM"

if [ -z "$NEW_SHA256_X86" ] || [ -z "$NEW_SHA256_ARM" ]; then
    printf "   Failed to compute SHA256 checksums.\n"
    exit 1
fi

printf "   Updating manifest from %s -> %s\n" "$CURRENT_VERSION" "$LATEST_VERSION"

# Update Manifest Files
# First replace the vX.Y.Z tag version in the URLs
sed "s|releases/download/v${STRIPPED_CURRENT}|releases/download/v${STRIPPED_LATEST}|g" "$MANIFEST_FILE" > "_" && mv "_" "$MANIFEST_FILE"
# Then replace the raw version (without v) in the filename/checksum/etc.
sed "s|brave-origin-${STRIPPED_CURRENT}-linux-amd64|brave-origin-${STRIPPED_LATEST}-linux-amd64|g" "$MANIFEST_FILE" > "_" && mv "_" "$MANIFEST_FILE"
sed "s|brave-origin-${STRIPPED_CURRENT}-linux-arm64|brave-origin-${STRIPPED_LATEST}-linux-arm64|g" "$MANIFEST_FILE" > "_" && mv "_" "$MANIFEST_FILE"

sed "s|version=\"${STRIPPED_CURRENT}\"|version=\"${STRIPPED_LATEST}\"|g" "$METADATA_FILE" > "_" && mv "_" "$METADATA_FILE"
sed "s|date=\"[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\"|date=\"${CURRENT_DATE}\"|g" "$METADATA_FILE" > "_" && mv "_" "$METADATA_FILE"

# Update the version tracker
printf "version: %s\nprerelease: %s\n" "$LATEST_VERSION" "$IS_PRERELEASE" > version.txt

printf "   New x86_64 SHA256: %s\n   New aarch64 SHA256: %s\n" "$NEW_SHA256_X86" "$NEW_SHA256_ARM"

# This finds the URL line for each architecture, moves to the next line (n), and replaces the hash.
sed "/linux-amd64\.zip/{n;s/sha256: [a-f0-9]*/sha256: $NEW_SHA256_X86/;}" "$MANIFEST_FILE" > "_" && mv "_" "$MANIFEST_FILE"
sed "/linux-arm64\.zip/{n;s/sha256: [a-f0-9]*/sha256: $NEW_SHA256_ARM/;}" "$MANIFEST_FILE" > "_" && mv "_" "$MANIFEST_FILE"

printf "   Manifest updated successfully.\n"

printf "   Done.\n"

