#!/bin/bash

# Exit on error
set -e

# Directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "Building and running CLI demo..."
swift run