#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
# Pass a booted simulator or connected Android device id as the first argument.
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 DEVICE_ID"
  flutter devices
  exit 1
fi
flutter drive --driver=test_driver/screenshots.dart --target=integration_test/app_test.dart -d "$1"
