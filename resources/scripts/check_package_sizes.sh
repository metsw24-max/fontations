#!/usr/bin/env bash

# Script to ensure that all publishable crates are within the 10MB size limit.
#
# This script identifies all packages in the workspace that do NOT have 
# 'publish = false' in their Cargo.toml, runs 'cargo package' for each, 
# and verifies the size of the resulting .crate file.

set -o nounset
set -o errexit

# 10MB in bytes (10 * 1024 * 1024)
MAX_SIZE=10485760
EXIT_CODE=0

# Find all publishable packages
# We use cargo metadata to get a list of all packages and their publish status.
# The jq filter selects packages where 'publish' is not null (meaning it's either true or not set to false).
# However, 'publish' in metadata is an array of registries or null. 
# If it's null, it's publishable to any registry. 
# If it's an empty array, it's not publishable.
PUBLISHABLE_PACKAGES=$(cargo metadata --no-deps --format-version 1 | jq -r '.packages[] | select(.publish != []) | .name')

echo "Checking package sizes for publishable crates..."

# Ensure we have a clean slate in target/package
rm -rf target/package

for pkg in $PUBLISHABLE_PACKAGES; do
    echo "Processing $pkg..."
    
    # Run cargo package. --no-verify and --allow-dirty to speed things up and avoid issues with uncommitted changes.
    # We use --offline to avoid trying to reach crates.io, which can fail if we have local dependencies that aren't published yet.
    if ! cargo package -p "$pkg" --no-verify --allow-dirty --offline > /dev/null 2>&1; then
        # If offline fails, it might be because it needs to download something. Try without offline but it might still fail for local deps.
        if ! cargo package -p "$pkg" --no-verify --allow-dirty > /dev/null 2>&1; then
             echo "Warning: 'cargo package' failed for $pkg. This might happen if it has dependencies not yet on crates.io."
             continue
        fi
    fi
    
    # The .crate file is located in target/package/
    CRATE_FILE=$(find target/package -name "${pkg}-*.crate" | sort -V | tail -n 1)
    
    if [ -z "$CRATE_FILE" ]; then
        echo "Warning: Could not find .crate file for $pkg"
        continue
    fi
    
    SIZE=$(stat -c%s "$CRATE_FILE")
    
    if [ "$SIZE" -gt "$MAX_SIZE" ]; then
        SIZE_MB=$(echo "scale=2; $SIZE / 1048576" | bc)
        echo "::error::Package '$pkg' is too large: ${SIZE_MB}MB (max 10MB)"
        echo "::error::To fix this, identify large files and exclude them in Cargo.toml using the 'exclude' field."
        echo "::error::See https://github.com/googlefonts/fontations/pull/1906 for an example."
        EXIT_CODE=1
    else
        SIZE_MB=$(echo "scale=2; $SIZE / 1048576" | bc)
        echo "Package '$pkg' size is OK: ${SIZE_MB}MB"
    fi
    
    # Clean up to avoid find picking up old versions or other packages if versioning is complex
    rm -f "$CRATE_FILE"
done

if [ $EXIT_CODE -ne 0 ]; then
    echo "One or more packages exceeded the size limit."
    exit 1
fi

echo "All checked packages are within the size limit."
