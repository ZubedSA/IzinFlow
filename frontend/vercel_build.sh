#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Get dependencies
./flutter/bin/flutter pub get

# Build web
./flutter/bin/flutter build web --release
