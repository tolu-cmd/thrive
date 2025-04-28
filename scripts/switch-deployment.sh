#!/bin/bash

# Script to switch between blue and green deployments

# Check if the current version is specified
if [ -z "$1" ]; then
  echo "Usage: $0 <blue|green>"
  exit 1
fi

# Validate the input
if [ "$1" != "blue" ] && [ "$1" != "green" ]; then
  echo "Error: Version must be either 'blue' or 'green'"
  exit 1
fi

# Get the current version
CURRENT_VERSION=$(kubectl get service hello-world -n hello-world -o jsonpath='{.spec.selector.version}')
echo "Current version: $CURRENT_VERSION"

# Switch to the new version
NEW_VERSION=$1
echo "Switching to version: $NEW_VERSION"

# Update the service selector
kubectl patch service hello-world -n hello-world -p "{\"spec\":{\"selector\":{\"version\":\"$NEW_VERSION\"}}}"

echo "Service updated to point to $NEW_VERSION deployment"

# Verify the switch
NEW_CURRENT_VERSION=$(kubectl get service hello-world -n hello-world -o jsonpath='{.spec.selector.version}')
echo "New current version: $NEW_CURRENT_VERSION"

# Check if the switch was successful
if [ "$NEW_CURRENT_VERSION" == "$NEW_VERSION" ]; then
  echo "Switch successful!"
else
  echo "Switch failed!"
  exit 1
fi

exit 0
