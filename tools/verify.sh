#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test test_driver
flutter analyze
flutter test
