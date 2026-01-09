#!/bin/bash

# Simple script to run the flatpak cargo generator
# Usage: ./gen-sources.sh [Cargo.lock] [output.json]

CARGO_LOCK=${1:-Cargo.lock}
OUTPUT=${2:-cargo-sources.json}
GENERATOR="flatpak-builder-tools/cargo/flatpak-cargo-generator.py"

if [ ! -f "$GENERATOR" ]; then
    echo "Error: Generator not found at $GENERATOR"
    echo "Make sure submodules are initialized: git submodule update --init --recursive"
    exit 1
fi

if [ ! -f "$CARGO_LOCK" ]; then
    echo "Error: $CARGO_LOCK not found."
    exit 1
fi

echo "Generating $OUTPUT from $CARGO_LOCK..."
python3 "$GENERATOR" "$CARGO_LOCK" -o "$OUTPUT"
exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo "Successfully generated $OUTPUT"
else
    echo "Error: Generator failed with exit code $exit_code"
fi

exit $exit_code
