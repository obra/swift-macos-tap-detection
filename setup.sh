#!/bin/bash

# Make the script exit on any errors
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "Setting up TapDetection project..."

# Make sure Swift Package Manager has built the package
echo "Building Swift Package..."
swift build

echo "Setup completed successfully!"
echo ""
echo "To use the TapDetection library in your project:"
echo "1. Open the project in Xcode:"
echo "   open ."
echo "2. To try the demo app, open Demo/TapDetectionDemo/TapDetectionDemo.xcodeproj"
echo "3. Run the demo app (Command+R)"
echo ""
echo "Note: The first time you run the demo app, you'll need to grant accessibility permissions"
echo "      in System Preferences > Security & Privacy > Privacy > Accessibility"