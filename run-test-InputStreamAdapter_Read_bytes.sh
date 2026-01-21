#!/bin/bash

# Script to run the InputStreamAdapter_Read_bytes test
# This test requires an Android device or emulator to be connected
#
# NOTE: The NUnit Android test runner doesn't support filtering by individual
# test name from the command line. This script runs all tests in the test APK.
# To run specific tests, you would need to modify the test runner or use categories.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set up Android SDK environment
ANDROID_SDK_DIR="$HOME/src/maui-android-native/android-sdk"
if [ -d "$ANDROID_SDK_DIR" ]; then
    export ANDROID_HOME="$ANDROID_SDK_DIR"
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
    export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH"
fi

CONFIGURATION="${CONFIGURATION:-Release}"

echo "=== Running Mono.Android.NET-Tests ==="
echo "Configuration: $CONFIGURATION"
echo ""

# Check for connected device/emulator
if ! adb devices | grep -q "device$"; then
    echo "Error: No Android device or emulator connected."
    echo "Please connect a device or start an emulator and try again."
    exit 1
fi

# Find APK - check multiple locations
APK_PATH=""
for path in \
    "$SCRIPT_DIR/bin/Test${CONFIGURATION}/net10.0-android/Mono.Android.NET_Tests-Signed.apk" \
    "$SCRIPT_DIR/bin/Test${CONFIGURATION}/Mono.Android.NET_Tests-Signed.apk" \
    "$SCRIPT_DIR/bin/TestDebug/net10.0-android/Mono.Android.NET_Tests-Signed.apk" \
    "$SCRIPT_DIR/bin/TestRelease/net10.0-android/Mono.Android.NET_Tests-Signed.apk"; do
    if [ -f "$path" ]; then
        APK_PATH="$path"
        break
    fi
done

if [ -z "$APK_PATH" ]; then
    echo "Error: No pre-built APK found. Please build the test project first with:"
    echo "  make prepare && make all"
    echo "  ./dotnet-local.sh build tests/Mono.Android-Tests/Mono.Android-Tests/Mono.Android.NET-Tests.csproj"
    exit 1
fi

echo "Using APK: $APK_PATH"
echo ""

echo "=== Installing APK ==="
adb install -r "$APK_PATH"

echo ""
echo "=== Running tests ==="
adb shell am instrument -w \
    Mono.Android.NET_Tests/xamarin.android.runtimetests.NUnitInstrumentation

echo ""
echo "=== Test completed ==="
