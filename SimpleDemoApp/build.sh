#!/bin/bash

# Exit on error
set -e

# Directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Building TapDetection library..."
cd "$ROOT_DIR"
swift build

echo "Building demo app..."
cd "$SCRIPT_DIR"

# Compile with explicit module import
swiftc -o TapDetectionDemo \
    Sources/main.swift \
    -I "$ROOT_DIR/.build/debug" \
    -L "$ROOT_DIR/.build/debug" \
    -module-name SimpleDemoApp \
    -import-module TapDetection \
    -lTapDetection \
    -framework AppKit \
    -framework Combine \
    -framework Foundation

echo "Build completed successfully."
echo "Run the demo with: ./TapDetectionDemo"