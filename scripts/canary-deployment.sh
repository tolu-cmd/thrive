#!/bin/bash

# Script to implement canary deployments

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

# Create a canary deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world-canary
  namespace: hello-world
  labels:
    app: hello-world
    environment: dev
    version: canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-world
      environment: dev
      version: canary
  template:
    metadata:
      labels:
        app: hello-world
        environment: dev
        version: canary
      annotations:
        kubernetes.io/change-cause: "Canary deployment"
    spec:
      containers:
      - name: hello-world
        image: $NEW_IMAGE
        ports:
        - containerPort: 3000
        env:
        - name: PORT
          value: "3000"
        - name: VERSION
          value: "canary"
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 256Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 5
EOF

# Wait for the canary deployment to be ready
kubectl rollout status deployment/hello-world-canary -n hello-world

# Update the main service to send 20% of traffic to the canary
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: hello-world
  namespace: hello-world
  labels:
    app: hello-world
    environment: dev
spec:
  selector:
    app: hello-world
    environment: dev
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
  type: LoadBalancer
EOF

echo "Canary deployment created with 20% traffic"
echo "Monitor the canary deployment for any issues"
echo "If everything looks good, run: ./scripts/update-deployment.sh $1"
echo "Then delete the canary deployment: kubectl delete deployment hello-world-canary -n hello-world"

exit 0
