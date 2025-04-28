#!/bin/bash

# Script to update the deployment with a new image tag

# Check if the image tag is specified
if [ -z "$1" ]; then
  echo "Usage: $0 <image-tag>"
  exit 1
fi

# Get the current image
CURRENT_IMAGE=$(kubectl get deployment hello-world -n hello-world -o jsonpath='{.spec.template.spec.containers[0].image}')
echo "Current image: $CURRENT_IMAGE"

# Extract the repository from the current image
REPOSITORY=$(echo $CURRENT_IMAGE | cut -d':' -f1)
echo "Repository: $REPOSITORY"

# Set the new image
NEW_IMAGE="$REPOSITORY:$1"
echo "New image: $NEW_IMAGE"

# Update the deployment
kubectl set image deployment/hello-world -n hello-world hello-world=$NEW_IMAGE

# Verify the update
kubectl rollout status deployment/hello-world -n hello-world

# Check if the update was successful
if [ $? -eq 0 ]; then
  echo "Update successful!"
else
  echo "Update failed!"
  exit 1
fi

exit 0
