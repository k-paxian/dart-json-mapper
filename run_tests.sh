#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

echo "----------------------------------------------------"
echo "Targeting perf-test directory for testing."
echo "----------------------------------------------------"

cd /app/perf-test

echo "Getting dependencies for perf-test..."
dart pub get

echo "Running tests for perf-test using 'dart run build_runner test'..."
dart run build_runner test --delete-conflicting-outputs

echo "----------------------------------------------------"
echo "Test execution finished for perf-test."
echo "----------------------------------------------------"
exit 0
